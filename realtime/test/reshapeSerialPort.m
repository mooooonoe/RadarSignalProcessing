function rawDataReader(setupJsonFileName, rawDataFileName, radarCubeDataFileName, debugPlot)
    close all;
    
    % Global parameters
    global Params;
    global ui;
    global dataSet;
    global EXIT_KEY_PRESSED
    EXIT_KEY_PRESSED = 0;

    % Read configuration and setup files
    setupJSON = jsondecode(fileread(setupJsonFileName));

    % Read mmwave JSON file
    jsonMmwaveFileName = setupJSON.configUsed;
    mmwaveJSON = jsondecode(fileread(jsonMmwaveFileName));
    
    % Print parsed current system parameter
    fprintf('mmwave Device:%s\n', setupJSON.mmWaveDevice);
    
    % Read bin file name
    binFilePath = setupJSON.capturedFiles.fileBasePath;
    numBinFiles = length(setupJSON.capturedFiles.files);
    if( numBinFiles < 1)
        error('Bin File is not available');
    end  
    Params.numBinFiles = numBinFiles;
    
    for idx=1:numBinFiles
        binFileName{idx} = strcat(binFilePath, '\', setupJSON.capturedFiles.files(idx).processedFileName);
    end
    
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
        error("Configuraion from JSON file is not Valid");
    end
     
    % Open raw data from file
    Params.NFrame = 0;
    for idx = 1:numBinFiles
        [Params.fid_rawData(idx), errmsg] = fopen(binFileName{idx}, 'r');
        if(Params.fid_rawData(idx) == -1)
            fprintf("Can not open Bin file %s, - %s\n",binFileName{idx}, errmsg); 
            error('Quit with error');
        end   
    
        % Calculate number of Frames in bin File 
        try
            Params.NFramePerFile(idx) = dp_getNumberOfFrameFromBinFile(binFileName{idx});
            Params.NFrame = Params.NFrame + Params.NFramePerFile(idx);
        catch
            if(Params.NFramePerFile(idx) == 0)
                error("Not enough data in binary file");
            end
        end
    end
    
    % Export data
    dp_exportData(rawDataFileName, radarCubeDataFileName);
    
    % Start example UI and update time domain/range Profile plots
    if(debugPlot)
        % Start up processing display page
        ui.figHandle = initDisplayPage(setupJSON.mmWaveDevice);
    
        % load and Plot the first frame
        dp_updateFrameData(1);
        ui_updateFramePlot();
    
        % Wait for UI interactions
        while (~EXIT_KEY_PRESSED)
            pause(0.01);
        end
        
        close(ui.figHandle);
    end
    
    %close and delete handles before exiting
    for idx = 1: numBinFiles
        fclose(Params.fid_rawData(idx)); 
    end
    close all;
end


% ============================================================
% Configuration and Data File Parsing Functions
% ============================================================

%   -----------------------------------------------------------------------
%   Description:    This function loads one frame data and perform range
%   FFT
%   Input:          exportRawDataFile - file name to export raw data
%                   export1DFFTDataFile - file name to export 1D FFT data
%   Output:         mat files
%   -----------------------------------------------------------------------
function dp_exportData(rawDataFileName, radarCubeDataFileName)
    global dataSet
    global Params
    
    % Prepare data to be saved in mat-file
    if ((~strcmp(rawDataFileName, '')) || (~strcmp(rawDataFileName, '')))
        for frameIdx=1:Params.NFrame
            dp_updateFrameData(frameIdx);
            rawADCData{frameIdx} = dataSet.rawDataUint16;
            radarCubeData{frameIdx} = single(dataSet.radarCubeData);
        end
    end
    % Export raw ADC data
    if (~strcmp(rawDataFileName, ''))
        adcRawData.rfParams = Params.RFParams;
        adcRawData.data = rawADCData;
        adcRawData.dim.numFrames = Params.NFrame;
        adcRawData.dim.numChirpsPerFrame = Params.adcDataParams.numChirpsPerFrame;
        adcRawData.dim.numRxChan = Params.NChan;
        adcRawData.dim.numSamples = Params.NSample;
        
        % Save params and data to mat file        
        save (rawDataFileName, 'adcRawData', '-v7.3');
    end
    
    % Export rangeFFT data
    if (~strcmp(rawDataFileName, ''))
        radarCubeParams = Params.radarCubeParams;
        radarCube.rfParams = Params.RFParams;
        radarCube.data = radarCubeData;
        radarCube.dim.numFrames = Params.NFrame;
        radarCube.dim.numChirps = radarCubeParams.numTxChan * radarCubeParams.numDopplerChirps;
        radarCube.dim.numRxChan = radarCubeParams.numRxChan;
        radarCube.dim.numRangeBins = radarCubeParams.numRangeBins;
        radarCube.dim.iqSwap = radarCubeParams.iqSwap;
        
        % Save params and data to mat file
        save (radarCubeDataFileName,'radarCube', '-v7.3');
    end
end
%   -----------------------------------------------------------------------
%   Description:    This function loads one frame data and perform range
%   FFT
%   Input:          frameIdx - frame index
%   Output:         dataSet.rawFrameData(complex)
%                   dataSet.radarCubeData(complex)
%   -----------------------------------------------------------------------
function dp_updateFrameData(frameIdx)
    global Params
    global dataSet
    
    % Find binFin index
    currFrameIdx = 0;
    fidIdx = 0;
    for idx = 1: Params.numBinFiles
        if frameIdx <= (Params.NFramePerFile(idx) + currFrameIdx)
            fidIdx = idx;
            break;
        else
            currFrameIdx = currFrameIdx + Params.NFramePerFile(idx);
        end
    end
    
    if(fidIdx <= Params.numBinFiles)
        % Load raw data from bin file
        rawDataComplex = dp_loadOneFrameData(Params.fid_rawData(fidIdx), Params.dataSizeOneFrame, frameIdx - currFrameIdx);

        % Read in raw data in uint16
        dataSet.rawDataUint16 = uint16(rawDataComplex);

        % time domain data y value adjustments
        timeDomainData = rawDataComplex - ( rawDataComplex >=2.^15).* 2.^16;      

        % reshape data based on capture configurations
        dp_generateFrameData(timeDomainData);

        % Perform rangeFFT
        dataSet.radarCubeData = processingChain_rangeFFT(Params.rangeWinType);
    end
end
 

%   -----------------------------------------------------------------------
%   Description:    This function calcultes number of frames of data available
%                   in binary file
%   Input:          binFileName - binary file name
%   Output:         NFrame - number of Frames
%   -----------------------------------------------------------------------
function [NFrame] = dp_getNumberOfFrameFromBinFile(binFileName)
    global Params
    try 
        binFile = dir(binFileName);
        fileSize = binFile.bytes;
    catch
        error('Reading Bin file failed');
    end
    NFrame = floor(fileSize/Params.dataSizeOneFrame);
end

%   -----------------------------------------------------------------------
%   Description:    This function load one frame data from binary file
%   Input:          fid_rawData - fid for binary file
%                   dataSizeOneFrame - size of one frame data
%                   frameIdx - frame index
%   Output:         rawData - one frame of raw ADC data
%   -----------------------------------------------------------------------
function [rawData] = dp_loadOneFrameData(fid_rawData, dataSizeOneFrame, frameIdx)  
    % find the first byte of the frame
    fseek(fid_rawData, (frameIdx - 1)*dataSizeOneFrame, 'bof');
     
    try
        % Read in raw data in complex single
        rawData = fread(fid_rawData, dataSizeOneFrame/2, 'uint16=>single');
    catch
        error("error reading binary file");
    end
    if(dataSizeOneFrame ~= length(rawData)*2)
        fprintf("dp_loadOneFrameData, size = %d, expected = %d \n",length(rawData), dataSizeOneFrame); 
        error("read data from bin file, have wrong length");
    end
end
 
%   -----------------------------------------------------------------------
%   Description:    This function validates configuration from JSON files
%   Input:          setupJson - setup JSON configuration structure
%                   mmwaveJSON - mmwave JSON configuration structure
%   Output:         confValid - true if the configuration is valid
%   -----------------------------------------------------------------------
function [confValid] = dp_validateDataCaptureConf(setupJson, mmwaveJSON)
    global Params

    mmWaveDevice = setupJson.mmWaveDevice;
    
    % Supported platform list
    supportedPlatform = {'awr1642',... 
                         'iwr1642',...
                         'awr1243',...
                         'iwr1243',...                         
                         'awr1443',...
                         'iwr1443',...
                         'awr1843',...
                         'iwr1843',...
                         'iwr6843'};                  

    confValid = true;
    
    % Validate if the device is supported
    index = find(contains(supportedPlatform,mmWaveDevice));
    if(index == 0)
        fprintf("Platform not supported : %s \n", mmWaveDevice);
        confValid = false;  
    end
    
    % Validate the captureHardware
    if(setupJson.captureHardware ~= 'DCA1000')
        confValid = false;
        fprintf("Capture hardware is not supported : %s \n", setupJson.captureHardware);
    end   
      
    % Validate ADC_ONLY capture  
    if (mmwaveJSON.mmWaveDevices.rawDataCaptureConfig.rlDevDataPathCfg_t.transferFmtPkt0 ~= '0x1')
        confValid = false;
        fprintf("Capture data format is not supported : %s \n", mmwaveJSON.mmWaveDevices.rawDataCaptureConfig.rlDevDataPathCfg_t.transferFmtPkt0);        
    end
    
    % Validate the dataLoggingMode
    if(setupJson.DCA1000Config.dataLoggingMode  ~= 'raw')
        confValid = false;
        fprintf("Capture data logging mode is not supported : %s \n", setupJson.DCA1000Config.dataLoggingMode);        
    end
    
    % Validate the Capture configuration
    Params.numLane = dp_numberOfEnabledChan(sscanf(mmwaveJSON.mmWaveDevices.rawDataCaptureConfig.rlDevLaneEnable_t.laneEn, '0x%x'));
    Params.chInterleave = mmwaveJSON.mmWaveDevices.rawDataCaptureConfig.rlDevDataFmtCfg_t.chInterleave;
    if ((mmWaveDevice == 'awr1443') | (mmWaveDevice == 'iwr1443') | (mmWaveDevice == 'awr1243') | (mmWaveDevice == 'iwr1243'))
        if(Params.numLane ~= 4)
            fprintf(" %d LVDS Lane is not supported for device : %s ", Params.numLane, mmWaveDevice); 
            confValid = false;
        end
        
        if(Params.chInterleave ~= 0)
            fprintf(" Interleave mode %d is not supported for device : %s ", Params.chInterleave, mmWaveDevice); 
            confValid = false;
        end
    else
        if(Params.numLane ~= 2)
            fprintf(" %d LVDS Lane is not supported for device : %s ", Params.numLane, mmWaveDevice); 
            confValid = false;            
        end    
        if(Params.chInterleave ~= 1)
            fprintf(" Interleave mode %d is not supported for device : %s ", Params.chInterleave, mmWaveDevice); 
            confValid = false;            
        end
    end
end


%  -----------------------------------------------------------------------
%  Description:    This function reshape raw binary data based on capture
%                  configuration, generates data in cell of 
%                  [number of chirps, number of RX channels, number of ADC samples]
%  Input:          rawData - raw ADC data
%  Output:         frameData - reshaped ADC data
%  -----------------------------------------------------------------------
function [frameData] = dp_generateFrameData(rawData)
    global Params
    global dataSet
    
    if(Params.numLane == 2)
        % Convert 2 lane LVDS data to one matrix 
        frameData = dp_reshape2LaneLVDS(rawData);       
    elseif (Params.numLane == 4)
        % Convert 4 lane LVDS data to one matrix 
        frameData = dp_reshape4LaneLVDS(rawData);    
    else
        fprintf("%d LVDS lane is not supported ", Params.numLane);              
    end
    
    % checking iqSwap setting
    if(Params.adcDataParams.iqSwap == 1)
        % Data is in ReIm format, convert to ImRe format to be used in radarCube 
        frameData(:,[1,2]) = frameData(:,[2,1]);
    end
    
    % Convert data to complex: column 1 - Imag, 2 - Real
    frameCplx = frameData(:,1) + 1i*frameData(:,2);  
    
    % initialize frameComplex
    frameComplex = single(zeros(Params.NChirp, Params.NChan, Params.NSample));
    
    % Change Interleave data to non-interleave 
    if(Params.chInterleave == 1)
        % non-interleave data
        temp = reshape(frameCplx, [Params.NSample * Params.NChan, Params.NChirp]).'; 
        for chirp=1:Params.NChirp                            
            frameComplex(chirp,:,:) = reshape(temp(chirp,:), [Params.NSample, Params.NChan]).';
        end 
    else
        % interleave data
        temp = reshape(frameCplx, [Params.NSample * Params.NChan, Params.NChirp]).'; 
        for chirp=1:Params.NChirp                            
            frameComplex(chirp,:,:) = reshape(temp(chirp,:), [Params.NChan, Params.NSample]);
        end 
    end
    
    % Save raw data
    dataSet.rawFrameData = frameComplex;
end

%  -----------------------------------------------------------------------
%  Description:    This function counts number of enabled channels from 
%                  channel Mask.
%  Input:          chanMask
%  Output:         Number of channels
%  -----------------------------------------------------------------------
function [count] = dp_numberOfEnabledChan(chanMask)
    
    MAX_RXCHAN = 4;
    count = 0;
    for chan= 0:MAX_RXCHAN - 1
        bitVal = pow2(chan);
        if (bitand(chanMask,bitVal) == (bitVal))
            count = count + 1;
            chanMask = chanMask-bitVal;
            if(chanMask == 0) 
                break;
            end
        end
    end
end

%  -----------------------------------------------------------------------
%  Description:    This function generates ADC raw data Parameters
%  Input:          mmwaveJSON
%  Output:         adcDataParams
%  -----------------------------------------------------------------------
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
            % real data, one sample is 16bits=2bytes
            gAdcOneSampleSize = 2; 
        elseif ((adcDataParams.dataFmt == 1) || (adcDataParams.dataFmt == 2))
            % complex data, one sample is 32bits = 4 bytes
            gAdcOneSampleSize = 4; %2 bytes    
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

%  -----------------------------------------------------------------------
%  Description:    This function prints ADC raw data Parameters
%  Input:          adcDataParams
%  Output:         None
%  -----------------------------------------------------------------------
function [] = dp_printADCDataParams(adcDataParams)
    fprintf('Input ADC data parameters:\n');
    fprintf('    dataFmt:%d\n',adcDataParams.dataFmt);
    fprintf('    iqSwap:%d\n',adcDataParams.iqSwap);
    fprintf('    chanInterleave:%d\n',adcDataParams.chanInterleave);    
    fprintf('    numChirpsPerFrame:%d\n',adcDataParams.numChirpsPerFrame);
    fprintf('    adcBits:%d\n',adcDataParams.adcBits);
    fprintf('    numRxChan:%d\n',adcDataParams.numRxChan);   
    fprintf('    numAdcSamples:%d\n',adcDataParams.numAdcSamples);        
end

%  -----------------------------------------------------------------------
%  Description:    This function generates radar cube data Matrix Parameters
%  Input:          mmwaveJSON
%  Output:         radarCubeParams
%  -----------------------------------------------------------------------
function [radarCubeParams] = dp_generateRadarCubeParams(mmwaveJSON)
    global Params
    
    frameCfg = mmwaveJSON.mmWaveDevices.rfConfig.rlFrameCfg_t;
    
    radarCubeParams.iqSwap = mmwaveJSON.mmWaveDevices.rawDataCaptureConfig.rlDevDataFmtCfg_t.iqSwapSel;
    rxChanMask = sscanf(mmwaveJSON.mmWaveDevices.rfConfig.rlChanCfg_t.rxChannelEn, '0x%x');
    radarCubeParams.numRxChan = dp_numberOfEnabledChan(rxChanMask);
    radarCubeParams.numTxChan = frameCfg.chirpEndIdx - frameCfg.chirpStartIdx + 1;
    
    radarCubeParams.numRangeBins = pow2(nextpow2(mmwaveJSON.mmWaveDevices.rfConfig.rlProfiles.rlProfileCfg_t.numAdcSamples));
    radarCubeParams.numDopplerChirps = mmwaveJSON.mmWaveDevices.rfConfig.rlFrameCfg_t.numLoops;

    % 1D Range FFT output : cmplx16ImRe_t x[numChirps][numRX][numRangeBins] 
    radarCubeParams.radarCubeFmt = 1; %RADAR_CUBE_FORMAT_1;
    
    dp_printRadarCubeParams(radarCubeParams);
    Params.radarCubeParams = radarCubeParams;
end

%  -----------------------------------------------------------------------
%  Description:    This function prints radar cube data Matrix Parameters
%  Input:          mmwaveJSON
%  Output:         radarCubeParams
%  -----------------------------------------------------------------------
function [] = dp_printRadarCubeParams(radarCubeParams)
    fprintf('Radarcube parameters:\n');
    fprintf('    iqSwap:%d\n',radarCubeParams.iqSwap);
    fprintf('    radarCubeFmt:%d\n',radarCubeParams.radarCubeFmt);    
    fprintf('    numDopplerChirps:%d\n',radarCubeParams.numDopplerChirps);
    fprintf('    numRxChan:%d\n',radarCubeParams.numRxChan);   
    fprintf('    numTxChan:%d\n',radarCubeParams.numTxChan);   
    fprintf('    numRangeBins:%d\n',radarCubeParams.numRangeBins);        
end

%  -----------------------------------------------------------------------
%  Description:    This function generates mmWave Sensor RF parameters
%  Input:          mmwaveJSON, radarCubeParams, adcDataParams
%  Output:         None
%  -----------------------------------------------------------------------
function [RFParams] = dp_generateRFParams(mmwaveJSON, radarCubeParams, adcDataParams)
     
    C = 3e8;
    profileCfg = mmwaveJSON.mmWaveDevices.rfConfig.rlProfiles.rlProfileCfg_t;    

            
    RFParams.startFreq = profileCfg.startFreqConst_GHz;

    % Slope const (MHz/usec)
    RFParams.freqSlope = profileCfg.freqSlopeConst_MHz_usec; 

    % ADC sampling rate in Msps
    RFParams.sampleRate = profileCfg.digOutSampleRate / 1e3; 
    
    % Generate radarCube parameters
    RFParams.numRangeBins = pow2(nextpow2(adcDataParams.numAdcSamples)); 
    RFParams.numDopplerBins = radarCubeParams.numDopplerChirps;
    RFParams.bandwidth = abs(RFParams.freqSlope * profileCfg.numAdcSamples / profileCfg.digOutSampleRate);

    RFParams.rangeResolutionsInMeters = C * RFParams.sampleRate / (2 * RFParams.freqSlope * RFParams.numRangeBins * 1e6);
    RFParams.dopplerResolutionMps =  C  / (2*RFParams.startFreq * 1e9 *...
                                        (profileCfg.idleTimeConst_usec + profileCfg.rampEndTime_usec  ) *...
                                        1e-6 * radarCubeParams.numDopplerChirps * radarCubeParams.numTxChan);
    RFParams.framePeriodicity = mmwaveJSON.mmWaveDevices.rfConfig.rlFrameCfg_t.framePeriodicity_msec;
    
end
  
%  -----------------------------------------------------------------------
%  Description:    This function reshape raw data for 2 lane LVDS capture
%  Input:          rawData - raw ADC data from binary file
%  Output:         frameData
%  -----------------------------------------------------------------------
function [frameData] = dp_reshape2LaneLVDS(rawData)
    % Convert 2 lane LVDS data to one matrix 
    rawData4 = reshape(rawData, [4, length(rawData)/4]);
    rawDataI = reshape(rawData4(1:2,:), [], 1);
    rawDataQ = reshape(rawData4(3:4,:), [], 1);
    
    frameData = [rawDataI, rawDataQ];
end

%  -----------------------------------------------------------------------
%  Description:    This function reshape raw data for 4 lane LVDS capture
%  Input:          rawData - raw ADC data from binary file
%  Output:         frameData
%  -----------------------------------------------------------------------
function [frameData] = dp_reshape4LaneLVDS(rawData)
    % Convert 4 lane LVDS data to one matrix 
    rawData8 = reshape(rawData, [8, length(rawData)/8]);
    rawDataI = reshape(rawData8(1:4,:), [], 1);
    rawDataQ = reshape(rawData8(5:8,:), [], 1);
    
    frameData= [rawDataI, rawDataQ];
end