clc; clear; close all;

% Serial port configuration
comPort = 'COM13'; % data port
baudRate = 115200; 

s = serialport(comPort, baudRate);
configureTerminator(s, "LF");
s.Timeout = 10;

% Buffer size and data parameters
bufferSize = 16; 
dataBuffer = zeros(1, bufferSize, 'uint8'); 
frameIdx = 0;

% Global parameters for radar data processing
global Params;
global ui;
global dataSet;
global EXIT_KEY_PRESSED;
EXIT_KEY_PRESSED = 0;

% JSON configuration file paths (Modify these paths as per your setup)
setupJsonFileName = 'setup.json';
rawDataFileName = 'rawData.mat';
radarCubeDataFileName = 'radarCube.mat';
debugPlot = true;

% Read configuration and setup files
setupJSON = jsondecode(fileread(setupJsonFileName));

% Read mmwave JSON file
jsonMmwaveFileName = setupJSON.configUsed;
mmwaveJSON = jsondecode(fileread(jsonMmwaveFileName));

% Print parsed current system parameter
fprintf('mmwave Device: %s\n', setupJSON.mmWaveDevice);

% Generate ADC data parameters
adcDataParams = dp_generateADCDataParams(mmwaveJSON);

% Generate radar cube parameters
radarCubeParams = dp_generateRadarCubeParams(mmwaveJSON);

% Generate RF parameters    
Params.RFParams = dp_generateRFParams(mmwaveJSON, radarCubeParams, adcDataParams);  
Params.NSample = adcDataParams.numAdcSamples;
Params.NChirp = adcDataParams.numChirpsPerFrame;
Params.NChan = adcDataParams.numRxChan;
Params.NTxAnt = radarCubeParams.numTxChan;
Params.numRangeBins = radarCubeParams.numRangeBins;
Params.numDopplerBins = radarCubeParams.numDopplerChirps;   
Params.rangeWinType = 0;

% Validate configuration 
validConf = dp_validateDataCaptureConf(setupJSON, mmwaveJSON);
if(validConf == false)
    error("Configuration from JSON file is not valid");
end

% Prepare UI if debug plot is enabled
if(debugPlot)
    ui.figHandle = initDisplayPage(setupJSON.mmWaveDevice);
end

% Reading and processing data from the serial port in real-time
disp('Reading data from serial port...');
while true
    frameIdx = frameIdx + 1;
    try
        % Read data from serial port
        dataBuffer = read(s, bufferSize, 'uint8');
        
        % Convert data buffer to the expected format
        rawDataComplex = double(dataBuffer);
        
        % Process the frame data
        dp_updateFrameDataRealTime(rawDataComplex, frameIdx);
        
        if(debugPlot)
            ui_updateFramePlot();
        end
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
    
    % Exit condition for breaking the loop
    if(EXIT_KEY_PRESSED)
        break;
    end
end

% Clean up
clear s;
if(debugPlot)
    close(ui.figHandle);
end

% Functions
function dp_updateFrameDataRealTime(rawDataComplex, frameIdx)
    global Params
    global dataSet
    
    % Read in raw data in uint16
    dataSet.rawDataUint16 = uint16(rawDataComplex);

    % Time domain data y value adjustments
    timeDomainData = rawDataComplex - ( rawDataComplex >= 2^15 ) * 2^16;      

    % Reshape data based on capture configurations
    dp_generateFrameData(timeDomainData);

    % Perform rangeFFT
    dataSet.radarCubeData = processingChain_rangeFFT(Params.rangeWinType);
end

% Copy the remaining functions from the original script
% (dp_generateADCDataParams, dp_generateRadarCubeParams, dp_generateRFParams,
% dp_validateDataCaptureConf, dp_generateFrameData, processingChain_rangeFFT, etc.)

% Example function to generate ADC data parameters (include all the necessary functions here)
function [adcDataParams] = dp_generateADCDataParams(mmwaveJSON)
    global Params
    frameCfg = mmwaveJSON.mmWaveDevices.rfConfig.rlFrameCfg_t;
    
    adcDataParams.dataFmt = mmwaveJSON.mmWaveDevices.rfConfig.rlAdcOutCfg_t.fmt.b2AdcOutFmt;
    adcDataParams.iqSwap = mmwaveJSON.mmWaveDevices.rawDataCaptureConfig.rlDevDataFmtCfg_t.iqSwapSel;
    adcDataParams.chanInterleave = mmwaveJSON.mmWaveDevices.rawDataCaptureConfig.rlDevDataFmtCfg_t.chInterleave;
    adcDataParams.numChirpsPerFrame = frameCfg.numLoops  * (frameCfg.chirpEndIdx - frameCfg.chirpStartIdx + 1);
    adcDataParams.adcBits = mmwaveJSON.mmWaveDevices.rfConfig.rlAdcOutCfg_t.fmt.b2AdcBits;
    rxChanMask = sscanf(mmwaveJSON.mmWaveDevices.rfConfig.rlChanCfg_t.rxChannelEn, '0x%x');
   
    adcDataParams.numRxChan = dp_numberOfEnabledChan(rxChanMask);
    adcDataParams.numAdcSamples = mmwaveJSON.mmWaveDevices.rfConfig.rlProfiles.rlProfileCfg_t.numAdcSamples;
    
    dp_printADCDataParams(adcDataParams);
    
    % Calculate ADC data size
    if(adcDataParams.adcBits == 2)
        if (adcDataParams.dataFmt == 0)
            % real data, one sample is 16bits = 2 bytes
            gAdcOneSampleSize = 2; 
        elseif ((adcDataParams.dataFmt == 1) || (adcDataParams.dataFmt == 2))
            % complex data, one sample is 32bits = 4 bytes
            gAdcOneSampleSize = 4; 
        else
            fprintf('Error: unsupported ADC dataFmt');
        end
    else
        fprintf('Error: unsupported ADC bits (%d)', adcDataParams.adcBits);
    end    
    
    dataSizeOneChirp = gAdcOneSampleSize * adcDataParams.numAdcSamples * adcDataParams.numRxChan;
    Params.dataSizeOneFrame = dataSizeOneChirp * adcDataParams.numChirpsPerFrame;
    Params.dataSizeOneChirp = dataSizeOneChirp;
    
    Params.adcDataParams = adcDataParams;
end

function dp_printADCDataParams(adcDataParams)
    fprintf('Input ADC data parameters:\n');
    fprintf('    dataFmt: %d\n', adcDataParams.dataFmt);
    fprintf('    iqSwap: %d\n', adcDataParams.iqSwap);
    fprintf('    chanInterleave: %d\n', adcDataParams.chanInterleave);    
    fprintf('    numChirpsPerFrame: %d\n', adcDataParams.numChirpsPerFrame);
    fprintf('    adcBits: %d\n', adcDataParams.adcBits);
    fprintf('    numRxChan: %d\n', adcDataParams.numRxChan);   
    fprintf('    numAdcSamples: %d\n', adcDataParams.numAdcSamples);        
end

% Add other necessary functions here...

