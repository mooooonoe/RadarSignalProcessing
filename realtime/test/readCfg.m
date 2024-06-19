% MATLAB script to read configuration and set global variables
clc; clear; close all;
global CFG_PARAMS;
global numOfChirps_buf;
global numLoops_buf;
global numAdcSamples_buf;
global profileIdx_buf;
global SigImgNumSlices_buf;
global RxSatNumSlices_buf;
global chanIdx_buf;

global lvdsCfg_headerEn_buf;
global lvdsCfg_dataFmt_buf;
global lvdsCfg_userBufEn_buf;

global Raw_file_numSubframes;
global Raw_file_subframeIdx_buf;
global Raw_file_sessionFlag;

global ADC_file_numSubframes;
global ADC_file_subframeIdx_buf;
global ADC_file_sessionFlag;

global CC9_file_numSubframes;
global CC9_file_subframeIdx_buf;
global CC9_file_sessionFlag;

CFG_PARAMS = struct();
numOfChirps_buf = [];
numLoops_buf = [];
numAdcSamples_buf = [];
profileIdx_buf = [];
SigImgNumSlices_buf = [];
RxSatNumSlices_buf = [];
chanIdx_buf = [];

lvdsCfg_headerEn_buf = [];
lvdsCfg_dataFmt_buf = [];
lvdsCfg_userBufEn_buf = [];

Raw_file_numSubframes = 0;
Raw_file_subframeIdx_buf = [];
Raw_file_sessionFlag = '';

ADC_file_numSubframes = 0;
ADC_file_subframeIdx_buf = [];
ADC_file_sessionFlag = '';

CC9_file_numSubframes = 0;
CC9_file_subframeIdx_buf = [];
CC9_file_sessionFlag = '';

NOT_APPLY = -1;
TC_PASS   =  0;
TC_FAIL   =  1;


fileID = fopen('xwr16xx.cfg', 'r');

while ~feof(fileID)
    line = fgetl(fileID);
    disp([line]);
    List = strsplit(line);
    
    if contains(line, 'channelCfg')
        CFG_PARAMS.rxAntMask = str2double(List{2});
    end
    if contains(line, 'adcCfg')
        CFG_PARAMS.dataSize = str2double(List{2});
        CFG_PARAMS.dataType = str2double(List{3});
    end
    if contains(line, 'adcbufCfg')
        CFG_PARAMS.chirpMode = str2double(List{6});
    end
    if contains(line, 'Platform')
        if contains(line, '14')
            CFG_PARAMS.platform = '14';
        elseif contains(line, '16')
            CFG_PARAMS.platform = '16';
        elseif contains(line, '18')
            CFG_PARAMS.platform = '18';
        elseif contains(line, '64')
            CFG_PARAMS.platform = '64';
        elseif contains(line, '68')
            CFG_PARAMS.platform = '68';
        end
    end
    if contains(line, 'profileCfg')
        profileIdx_buf = [profileIdx_buf, str2double(List{2})];
        numAdcSamples_buf = [numAdcSamples_buf, str2double(List{11})];
    end
    if contains(line, 'frameCfg')
        CFG_PARAMS.chirpStartIdx = str2double(List{2});
        CFG_PARAMS.chirpEndIdx = str2double(List{3});
        numOfChirps_buf = [numOfChirps_buf, CFG_PARAMS.chirpEndIdx - CFG_PARAMS.chirpStartIdx + 1];
        numLoops_buf = [numLoops_buf, str2double(List{4})];
        CFG_PARAMS.numSubframes = 1;
    end
    if contains(line, 'advFrameCfg')
        CFG_PARAMS.numSubframes = str2double(List{2});
    end
    if contains(line, 'subFrameCfg')
        numOfChirps_buf = [numOfChirps_buf, str2double(List{5})];
        numLoops_buf = [numLoops_buf, str2double(List{6})];
    end
    if contains(line, 'lvdsStreamCfg')
        lvdsCfg_headerEn_buf = [lvdsCfg_headerEn_buf, str2double(List{3})];
        lvdsCfg_dataFmt_buf = [lvdsCfg_dataFmt_buf, str2double(List{4})];
        lvdsCfg_userBufEn_buf = [lvdsCfg_userBufEn_buf, str2double(List{5})];
    end
    if contains(line, 'CQSigImgMonitor')
        SigImgNumSlices_buf = [SigImgNumSlices_buf, str2double(List{3})];
    end
    if contains(line, 'CQRxSatMonitor')
        RxSatNumSlices_buf = [RxSatNumSlices_buf, str2double(List{5})];
    end
end

fclose(fileID);

% Parse rxAnt config
rxAntMask = CFG_PARAMS.rxAntMask;

rxChanEn = [];
rxChanEn(1) = bitand(rxAntMask, 1);
rxChanEn(2) = bitand(bitshift(rxAntMask, -1), 1);
rxChanEn(3) = bitand(bitshift(rxAntMask, -2), 1);
rxChanEn(4) = bitand(bitshift(rxAntMask, -3), 1);

numRxChan = 0;
chanIdx_buf = [];
for chanIdx = 1:4
    if rxChanEn(chanIdx) == 1
        chanIdx_buf = [chanIdx_buf, chanIdx-1];
        numRxChan = numRxChan + 1;
    end
end
CFG_PARAMS.numRxChan = numRxChan;

% Initialize lvds config
Raw_file_numSubframes = 0;
Raw_file_subframeIdx_buf = [];
Raw_file_sessionFlag = '';

ADC_file_numSubframes = 0;
ADC_file_subframeIdx_buf = [];
ADC_file_sessionFlag = '';

CC9_file_numSubframes = 0;
CC9_file_subframeIdx_buf = [];
CC9_file_sessionFlag = '';

% Add this part to your existing MATLAB script

global CFG_PARAMS;
global lvdsCfg_headerEn_buf;
global lvdsCfg_dataFmt_buf;
global lvdsCfg_userBufEn_buf;
global Raw_file_numSubframes;
global Raw_file_subframeIdx_buf;
global Raw_file_sessionFlag;
global ADC_file_numSubframes;
global ADC_file_subframeIdx_buf;
global ADC_file_sessionFlag;
global CC9_file_numSubframes;
global CC9_file_subframeIdx_buf;
global CC9_file_sessionFlag;

CFG_PARAMS.datacard_dataLoggingMode = 'multi';
if lvdsCfg_headerEn_buf(1) == 0
    CFG_PARAMS.datacard_dataLoggingMode = 'raw';
end

if lvdsCfg_headerEn_buf(1) == 0
    if lvdsCfg_dataFmt_buf(1) == 1 && lvdsCfg_userBufEn_buf(1) == 0
        if strcmp(CFG_PARAMS.datacard_dataLoggingMode, 'raw')
            % Raw file
            Raw_file_numSubframes = Raw_file_numSubframes + 1;
            Raw_file_subframeIdx_buf = [Raw_file_subframeIdx_buf, 0];
            Raw_file_sessionFlag = 'HW';
        elseif strcmp(CFG_PARAMS.datacard_dataLoggingMode, 'multi')
            return_value = TC_FAIL;
            disp('Error: no header can not be in multi mode!');
        else
            return_value = TC_FAIL;
            disp('Error: Undefined CFG_PARAMS.datacard_dataLoggingMode!');
        end
    else
        return_value = TC_FAIL;
        disp('Error: Subframe 0 has a invalid lvdsStreamCfg');
    end
elseif lvdsCfg_headerEn_buf(1) == 1
    if lvdsCfg_dataFmt_buf(1) == 1 || lvdsCfg_dataFmt_buf(1) == 4 % 1:ADC 4:CP+ADC+CQ
        ADC_file_sessionFlag = 'HW';
        CC9_file_sessionFlag = 'SW';
        ADC_file_numSubframes = ADC_file_numSubframes + 1;
        ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, 0];
        if lvdsCfg_userBufEn_buf(1) == 1
            CC9_file_numSubframes = CC9_file_numSubframes + 1;
            CC9_file_subframeIdx_buf = [CC9_file_subframeIdx_buf, 0];
        end
    elseif lvdsCfg_dataFmt_buf(1) == 0 % no ADC no HW
        ADC_file_sessionFlag = 'SW';
        CC9_file_sessionFlag = 'HW';
        if lvdsCfg_userBufEn_buf(1) == 1
            ADC_file_numSubframes = ADC_file_numSubframes + 1;
            ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, 0];
        else
            return_value = TC_FAIL;
            disp('Error: subframe 0 has no HW and SW');
        end
    else
        disp('subframe 0 has a invalid dataFmt config');
    end
else
    return_value = TC_FAIL;
    disp('Error: Invalid lvdsCfg_headerEn_buf[0]');
end

% Rest of 3 subframes if advanced subframe case
for subframeIdx = 2:CFG_PARAMS.numSubframes
    if lvdsCfg_dataFmt_buf(subframeIdx) == 1 || lvdsCfg_dataFmt_buf(subframeIdx) == 4 % 1:ADC 4:CP+ADC+CQ
        if strcmp(ADC_file_sessionFlag, 'HW')
            ADC_file_numSubframes = ADC_file_numSubframes + 1;
            ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, subframeIdx-1];
        end
        if strcmp(CC9_file_sessionFlag, 'HW')
            CC9_file_numSubframes = CC9_file_numSubframes + 1;
            CC9_file_subframeIdx_buf = [CC9_file_subframeIdx_buf, subframeIdx-1];
        end
    end
    if lvdsCfg_userBufEn_buf(subframeIdx) == 1
        if strcmp(ADC_file_sessionFlag, 'SW')
            ADC_file_numSubframes = ADC_file_numSubframes + 1;
            ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, subframeIdx-1];
        end
        if strcmp(CC9_file_sessionFlag, 'SW')
            CC9_file_numSubframes = CC9_file_numSubframes + 1;
            CC9_file_subframeIdx_buf = [CC9_file_subframeIdx_buf, subframeIdx-1];
        end
    end
end

% disp(CFG_PARAMS);
% disp(numOfChirps_buf);
% disp(numLoops_buf);
% disp(numAdcSamples_buf);
% disp(profileIdx_buf);
% disp(SigImgNumSlices_buf);
% disp(RxSatNumSlices_buf);
% disp(chanIdx_buf);
% 
% disp(lvdsCfg_headerEn_buf);
% disp(lvdsCfg_dataFmt_buf);
% disp(lvdsCfg_userBufEn_buf);
% 
% disp(Raw_file_numSubframes);
% disp(Raw_file_subframeIdx_buf);
% disp(Raw_file_sessionFlag);
% 
% disp(ADC_file_numSubframes);
% disp(ADC_file_subframeIdx_buf);
% disp(ADC_file_sessionFlag);
% 
% disp(CC9_file_numSubframes);
% disp(CC9_file_subframeIdx_buf);
% disp(CC9_file_sessionFlag);


%% comPort connection
comPort = 'COM13'; % data port
baudRate = 115200; 

s = serialport(comPort, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

bufferSize = 16; 
dataBuffer = zeros(1, bufferSize, 'uint8'); 

disp('Reading data from serial port...');

while true
    try
        dataBuffer = read(s, bufferSize, 'uint8');
        
        dataHex = dec2hex(dataBuffer);
        
        %fprintf('Received Data (Hex): ');
        for i = 1:bufferSize
            fprintf('%s ', dataHex(i, :));
        end
        fprintf('\n');


        numBytesCaptured = sprintf('%s ', dataHex);

        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

clear s;

% 
% 
% 
% numBytesCapturedFile = dir(capturedFileName).bytes;
% 
% all_frames_ADC_buffer = {};
% all_frames_CP_buffer = {};
% all_frames_CQ1_buffer = {};
% all_frames_CQ2_buffer = {};
% 
% chirpMode = CFG_PARAMS.chirpMode;
% numRxChan = CFG_PARAMS.numRxChan;
% 
% return_value = TC_PASS;
% frameIdx = 0;

% while true
%     disp(['****** HW session Frame ', num2str(frameIdx), ' ******']);
%     disp(['frameIdx = ', num2str(floor(frameIdx / numSubframes))]);
% 
%     subframeIdx = subframeIdx_buf(mod(frameIdx, numSubframes) + 1);
%     disp(['subframeIdx = ', num2str(subframeIdx)]);
% 
%     frame_ADC_buffer = {};
%     frame_CP_buffer = {};
%     frame_CQ1_buffer = {};
%     frame_CQ2_buffer = {};
% 
%     % Get current frame's parameters
%     numAdcSamples = numAdcSamples_buf(subframeIdx);
%     profileIdx = profileIdx_buf(subframeIdx);
%     numChirpPerFrame = numLoops_buf(subframeIdx) * numOfChirps_buf(subframeIdx);
% 
%     CFG_PARAMS.headerEn = lvdsCfg_headerEn_buf(subframeIdx);
%     CFG_PARAMS.dataFmt = lvdsCfg_dataFmt_buf(subframeIdx);
% 
%     if lvdsCfg_dataFmt_buf(subframeIdx) == 4
%         SigImgNumSlices = SigImgNumSlices_buf(subframeIdx);
%         RxSatNumSlices = RxSatNumSlices_buf(subframeIdx);
%     end
% 
%     for groupIdx = 1:(numChirpPerFrame / chirpMode)
%         if lvdsCfg_headerEn_buf(subframeIdx) == 1
%             get_hsi_header(fp);
%             return_value = return_value + verify_hsi_header_hw(numAdcSamples, ID);
%         end
% 
%         chirp_ADC_buffer = {};
%         chirp_CP_buffer = {};
%         chirp_CQ1_buffer = {};
%         chirp_CQ2_buffer = {};
% 
%         if lvdsCfg_dataFmt_buf(subframeIdx) == 1  % ADC data format
%             for idx = 1:(numRxChan * chirpMode)
%                 ADC_buffer = get_ADC(fp, numAdcSamples, CFG_PARAMS.dataSize);
%                 chirp_ADC_buffer{end+1} = ADC_buffer;
%             end
%         end
% 
%         if lvdsCfg_dataFmt_buf(subframeIdx) == 4  % CP+ADC+CQ data format
%             for chirpIdx = 1:chirpMode
%                 for chanIdx = 1:numRxChan
%                     [CP_verify_result, CP_buffer] = get_verify_CP(fp, (profileIdx * 4) + chanIdx_buf(chanIdx), (groupIdx - 1) * chirpMode + chirpIdx);
%                     return_value = return_value + CP_verify_result;
%                     chirp_CP_buffer{end+1} = CP_buffer;
%                 end
% 
%                 for idx = 1:(numRxChan * chirpMode)
%                     ADC_buffer = get_ADC(fp, numAdcSamples, CFG_PARAMS.dataSize);
%                     chirp_ADC_buffer{end+1} = ADC_buffer;
%                 end
% 
%                 [CQ_verify_result, CQ1_buffer, CQ2_buffer] = get_verify_CQ(fp, SigImgNumSlices, RxSatNumSlices);
%                 return_value = return_value + CQ_verify_result;
%                 chirp_CQ1_buffer{end+1} = CQ1_buffer;
%                 chirp_CQ2_buffer{end+1} = CQ2_buffer;
%             end
%         end
% 
%         frame_ADC_buffer{end+1} = chirp_ADC_buffer;
%         frame_CP_buffer{end+1} = chirp_CP_buffer;
%         frame_CQ1_buffer{end+1} = chirp_CQ1_buffer;
%         frame_CQ2_buffer{end+1} = chirp_CQ2_buffer;
%     end
% 
%     all_frames_ADC_buffer{end+1} = frame_ADC_buffer;
%     all_frames_CP_buffer{end+1} = frame_CP_buffer;
%     all_frames_CQ1_buffer{end+1} = frame_CQ1_buffer;
%     all_frames_CQ2_buffer{end+1} = frame_CQ2_buffer;
% 
%     pos = ftell(fp);
%     if frameIdx == 0
%         numBytesPerFrame = pos;
%     end
%     disp(['Frame ', num2str(frameIdx), ' end at file location: ', num2str(pos)]);
% 
%     if pos + numBytesPerFrame > numBytesCaptured
%         break;
%     end
% 
%     frameIdx = frameIdx + 1;
% end
% 
% fclose(fp);
% 
% disp([capturedFileName, ' contains ', num2str(numBytesCaptured), ' bytes. ', num2str(pos), ' bytes/', num2str(frameIdx), ' frames have been parsed.']);
% 
% if return_value == TC_PASS
%     disp('Captured file is correct!');
% else
%     return_value = TC_FAIL;
%     disp('Captured file has errors!');
% end