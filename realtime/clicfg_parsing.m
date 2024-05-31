    close all;
    
    % Global parameters
    global Params;
    global dataSet;
    global EXIT_KEY_PRESSED
    EXIT_KEY_PRESSED = 0;
    cliCfgFileName = 'xwr16xx_profile.cfg';
    % Read configuration and setup files
    cliCfg = fileread(cliCfgFileName);
    Params = parseCliCfg(cliCfg);
% 
%     % Read bin file name
%     binFilePath = ''; % Add logic to set this path if needed
%     numBinFiles = 1; % Adjust as needed if you have multiple bin files
%     if( numBinFiles < 1)
%         error('Bin File is not available');
%     end  
%     Params.numBinFiles = numBinFiles;
% 
%     for idx=1:numBinFiles
%         binFileName{idx} = rawDataFileName; % Assuming rawDataFileName is the binary data file
%     end
% 
%     % Generate ADC data parameters
%     %adcDataParams = dp_generateADCDataParams(Params);
% 
%     % Generate radar cube parameters
%     %radarCubeParams = dp_generateRadarCubeParams(Params);
% 
%     % Generate RF parameters    
%     %Params.RFParams = dp_generateRFParams(Params, radarCubeParams, adcDataParams);  
%     Params.NSample = adcDataParams.numAdcSamples;
%     Params.NChirp = adcDataParams.numChirpsPerFrame;
%     Params.NChan = adcDataParams.numRxChan;
%     Params.NTxAnt = radarCubeParams.numTxChan;
%     Params.numRangeBins = radarCubeParams.numRangeBins;
%     Params.numDopplerBins = radarCubeParams.numDopplerChirps;   
%     Params.rangeWinType = 0;
% 
%     % Validate configuration 
%     validConf = dp_validateDataCaptureConf(Params);
%     if(validConf == false)
%         error("Configuraion from CLI file is not Valid");
%     end
% 
%     % Open raw data from file
%     Params.NFrame = 0;
%     for idx = 1:numBinFiles
%         [Params.fid_rawData(idx), errmsg] = fopen(binFileName{idx}, 'r');
%         if(Params.fid_rawData(idx) == -1)
%             fprintf("Can not open Bin file %s, - %s\n",binFileName{idx}, errmsg); 
%             error('Quit with error');
%         end   
% 
%         % Calculate number of Frames in bin File 
%         try
%             Params.NFramePerFile(idx) = dp_getNumberOfFrameFromBinFile(binFileName{idx});
%             Params.NFrame = Params.NFrame + Params.NFramePerFile(idx);
%         catch
%             if(Params.NFramePerFile(idx) == 0)
%                 error("Not enough data in binary file");
%             end
%         end
%     end
% 
%     % Export data
%     dp_exportData(rawDataFileName, radarCubeDataFileName);
% 
%     % Start example UI and update time domain/range Profile plots
%     if(debugPlot)
%         % Start up processing display page
%         ui.figHandle = initDisplayPage('mmWave Device'); % Update as needed
% 
%         % load and Plot the first frame
%         dp_updateFrameData(1);
%         ui_updateFramePlot();
% 
%         % Wait for UI interactions
%         while (~EXIT_KEY_PRESSED)
%             pause(0.01);
%         end
% 
%         close(ui.figHandle);
%     end
% 
%     %close and delete handles before exiting
%     for idx = 1: numBinFiles
%         fclose(Params.fid_rawData(idx)); 
%     end
%     close all;
% end

%% Parse CLI configuration file
function Params = parseCliCfg(cliCfg)
    lines = strsplit(cliCfg, '\n');
    Params = struct();
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        if startsWith(line, 'profileCfg')
            tokens = str2double(strsplit(line));
            Params.startFreq = tokens(3);
            Params.freqSlope = tokens(9);
            Params.numAdcSamples = tokens(11);
            Params.sampleRate = tokens(12) / 1000; % Convert to Msps
        elseif startsWith(line, 'frameCfg')
            tokens = str2double(strsplit(line));
            Params.numChirpsPerFrame = tokens(3) * tokens(2);
            Params.framePeriodicity = tokens(5);
        elseif startsWith(line, 'channelCfg')
            tokens = str2double(strsplit(line));
            Params.numTxChan = sum(dec2bin(tokens(2)) == '1');
            Params.numRxChan = sum(dec2bin(tokens(3)) == '1');
        end
    end
    
    % Additional derived parameters
    Params.numRangeBins = pow2(nextpow2(Params.numAdcSamples));
    Params.bandwidth = abs(Params.freqSlope * Params.numAdcSamples / Params.sampleRate);
    Params.rangeResolutionsInMeters = 3e8 * Params.sampleRate / (2 * Params.freqSlope * Params.numRangeBins * 1e6);
    Params.numDopplerBins = Params.numChirpsPerFrame / Params.numTxChan;
end

% Other functions remain the same, but updated to use Params directly
% (dp_generateADCDataParams, dp_generateRadarCubeParams, dp_generateRFParams, etc.)
