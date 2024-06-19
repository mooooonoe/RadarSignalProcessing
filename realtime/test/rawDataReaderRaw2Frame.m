clc; clear; close all;

% Define parameters
comPort = 'COM13'; % data port
baudRate = 115200; 
frameSizeBytes = 256; % Define the size of one frame in bytes

% Initialize serial port
s = serialport(comPort, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

% Buffer to hold incoming data
dataBuffer = zeros(1, frameSizeBytes, 'uint8'); 

disp('Reading data from serial port...');

while true
    try
        % Read data from the serial port
        dataBuffer = read(s, frameSizeBytes, 'uint8');
        
        % Convert buffer to single precision complex numbers
        rawData = typecast(dataBuffer, 'uint16');
        rawData = single(rawData);
        
        % Display the received data in hexadecimal format
        dataHex = dec2hex(dataBuffer);
        for i = 1:frameSizeBytes
            fprintf('%s ', dataHex(i, :));
        end
        fprintf('\n');
        
        % Process rawData to generate complex data
        frameData = dp_generateFrameData(rawData);
        
        % Further processing of frameData as needed...

    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

% Clear the serial port object
clear s;

% Define dp_generateFrameData function
function [frameData] = dp_generateFrameData(rawData)
    global Params
    global dataSet
    
    % Example parameter initialization for demonstration purposes
    Params.numLane = 2;
    Params.adcDataParams.iqSwap = 0;
    Params.NChirp = 128;
    Params.NChan = 4;
    Params.NSample = 256;
    Params.chInterleave = 1;

    if(Params.numLane == 2)
        % Convert 2 lane LVDS data to one matrix 
        frameData = dp_reshape2LaneLVDS(rawData);       
    elseif (Params.numLane == 4)
        % Convert 4 lane LVDS data to one matrix 
        frameData = dp_reshape4LaneLVDS(rawData);    
    else
        fprintf("%d LVDS lane is not supported ", Params.numLane);              
    end
    
    % Checking iqSwap setting
    if(Params.adcDataParams.iqSwap == 1)
        % Data is in ReIm format, convert to ImRe format to be used in radarCube 
        frameData(:,[1,2]) = frameData(:,[2,1]);
    end
    
    % Convert data to complex: column 1 - Imag, 2 - Real
    frameCplx = frameData(:,1) + 1i*frameData(:,2);  
    
    % Initialize frameComplex
    frameComplex = single(zeros(Params.NChirp, Params.NChan, Params.NSample));
    
    % Change interleave data to non-interleave 
    if(Params.chInterleave == 1)
        % Non-interleave data
        temp = reshape(frameCplx, [Params.NSample * Params.NChan, Params.NChirp]).'; 
        for chirp = 1:Params.NChirp                            
            frameComplex(chirp,:,:) = reshape(temp(chirp,:), [Params.NSample, Params.NChan]).';
        end 
    else
        % Interleave data
        temp = reshape(frameCplx, [Params.NSample * Params.NChan, Params.NChirp]).'; 
        for chirp = 1:Params.NChirp                            
            frameComplex(chirp,:,:) = reshape(temp(chirp,:), [Params.NChan, Params.NSample]);
        end 
    end
    
    % Save raw data
    dataSet.rawFrameData = frameComplex;
end

% Define dummy dp_reshape2LaneLVDS and dp_reshape4LaneLVDS for demonstration
function frameData = dp_reshape2LaneLVDS(rawData)
    % Dummy reshaping function for 2 lane LVDS data
    frameData = reshape(rawData, [], 2);
end

function frameData = dp_reshape4LaneLVDS(rawData)
    % Dummy reshaping function for 4 lane LVDS data
    frameData = reshape(rawData, [], 4);
end
