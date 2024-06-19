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

% Infinite loop to continuously read data
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
        
        % Process rawData as needed...
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

% Clear the serial port object
clear s;
