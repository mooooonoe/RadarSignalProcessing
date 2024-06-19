% Initialize global variables
global CFG_PARAMS numOfChirps_buf numLoops_buf numAdcSamples_buf profileIdx_buf SigImgNumSlices_buf;
global RxSatNumSlices_buf chanIdx_buf lvdsCfg_headerEn_buf lvdsCfg_dataFmt_buf lvdsCfg_userBufEn_buf;
global Raw_file_numSubframes Raw_file_subframeIdx_buf Raw_file_sessionFlag;
global ADC_file_numSubframes ADC_file_subframeIdx_buf ADC_file_sessionFlag;
global CC9_file_numSubframes CC9_file_subframeIdx_buf CC9_file_sessionFlag;

% Constants
NOT_APPLY = -1;
TC_PASS = 0;
TC_FAIL = 1;

% Initialize variables
initialize_globals();

% Read configuration file
fileID = fopen('xwr16xx.cfg', 'r');
while ~feof(fileID)
    line = fgetl(fileID);
    disp(line);
    List = strsplit(line);
    parse_config_line(line, List);
end
fclose(fileID);

% Parse RX Antenna configuration
parse_rx_ant_config();

% Initialize LVDS configuration based on parsed values
initialize_lvds_config();

% Function to initialize global variables
function initialize_globals()
    global CFG_PARAMS numOfChirps_buf numLoops_buf numAdcSamples_buf profileIdx_buf SigImgNumSlices_buf;
    global RxSatNumSlices_buf chanIdx_buf lvdsCfg_headerEn_buf lvdsCfg_dataFmt_buf lvdsCfg_userBufEn_buf;
    global Raw_file_numSubframes Raw_file_subframeIdx_buf Raw_file_sessionFlag;
    global ADC_file_numSubframes ADC_file_subframeIdx_buf ADC_file_sessionFlag;
    global CC9_file_numSubframes CC9_file_subframeIdx_buf CC9_file_sessionFlag;

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
end

% Function to parse configuration lines
function parse_config_line(line, List)
    global CFG_PARAMS numOfChirps_buf numLoops_buf numAdcSamples_buf profileIdx_buf lvdsCfg_headerEn_buf;
    global lvdsCfg_dataFmt_buf lvdsCfg_userBufEn_buf SigImgNumSlices_buf RxSatNumSlices_buf;

    if contains(line, 'channelCfg')
        CFG_PARAMS.rxAntMask = str2double(List{2});
    elseif contains(line, 'adcCfg')
        CFG_PARAMS.dataSize = str2double(List{2});
        CFG_PARAMS.dataType = str2double(List{3});
    elseif contains(line, 'adcbufCfg')
        CFG_PARAMS.chirpMode = str2double(List{6});
    elseif contains(line, 'Platform')
        CFG_PARAMS.platform = parse_platform(List{2});
    elseif contains(line, 'profileCfg')
        profileIdx_buf = [profileIdx_buf, str2double(List{2})];
        numAdcSamples_buf = [numAdcSamples_buf, str2double(List{11})];
    elseif contains(line, 'frameCfg')
        CFG_PARAMS.chirpStartIdx = str2double(List{2});
        CFG_PARAMS.chirpEndIdx = str2double(List{3});
        numOfChirps_buf = [numOfChirps_buf, CFG_PARAMS.chirpEndIdx - CFG_PARAMS.chirpStartIdx + 1];
        numLoops_buf = [numLoops_buf, str2double(List{4})];
        CFG_PARAMS.numSubframes = 1;
    elseif contains(line, 'advFrameCfg')
        CFG_PARAMS.numSubframes = str2double(List{2});
    elseif contains(line, 'subFrameCfg')
        numOfChirps_buf = [numOfChirps_buf, str2double(List{5})];
        numLoops_buf = [numLoops_buf, str2double(List{6})];
    elseif contains(line, 'lvdsStreamCfg')
        lvdsCfg_headerEn_buf = [lvdsCfg_headerEn_buf, str2double(List{3})];
        lvdsCfg_dataFmt_buf = [lvdsCfg_dataFmt_buf, str2double(List{4})];
        lvdsCfg_userBufEn_buf = [lvdsCfg_userBufEn_buf, str2double(List{5})];
    elseif contains(line, 'CQSigImgMonitor')
        SigImgNumSlices_buf = [SigImgNumSlices_buf, str2double(List{3})];
    elseif contains(line, 'CQRxSatMonitor')
        RxSatNumSlices_buf = [RxSatNumSlices_buf, str2double(List{5})];
    end
end

% Function to parse platform
function platform = parse_platform(platform_str)
    switch platform_str
        case '14'
            platform = '14';
        case '16'
            platform = '16';
        case '18'
            platform = '18';
        case '64'
            platform = '64';
        case '68'
            platform = '68';
        otherwise
            error('Unknown platform');
    end
end

% Function to parse RX antenna configuration
function parse_rx_ant_config()
    global CFG_PARAMS chanIdx_buf;

    rxAntMask = CFG_PARAMS.rxAntMask;
    rxChanEn = bitget(rxAntMask, 1:4);
    chanIdx_buf = find(rxChanEn) - 1;
    CFG_PARAMS.numRxChan = numel(chanIdx_buf);
end

% Function to initialize LVDS configuration
function initialize_lvds_config()
    global CFG_PARAMS lvdsCfg_headerEn_buf lvdsCfg_dataFmt_buf lvdsCfg_userBufEn_buf;
    global Raw_file_numSubframes Raw_file_subframeIdx_buf Raw_file_sessionFlag;
    global ADC_file_numSubframes ADC_file_subframeIdx_buf ADC_file_sessionFlag;
    global CC9_file_numSubframes CC9_file_subframeIdx_buf CC9_file_sessionFlag;
    global TC_FAIL;

    CFG_PARAMS.datacard_dataLoggingMode = 'multi';
    if lvdsCfg_headerEn_buf(1) == 0
        CFG_PARAMS.datacard_dataLoggingMode = 'raw';
    end

    if lvdsCfg_headerEn_buf(1) == 0
        if lvdsCfg_dataFmt_buf(1) == 1 && lvdsCfg_userBufEn_buf(1) == 0
            handle_raw_file();
        else
            return_value = TC_FAIL;
            disp('Error: Subframe 0 has an invalid lvdsStreamCfg');
        end
    elseif lvdsCfg_headerEn_buf(1) == 1
        handle_header_enabled();
    else
        return_value = TC_FAIL;
        disp('Error: Invalid lvdsCfg_headerEn_buf[0]');
    end

    handle_advanced_subframes();
end

% Function to handle raw file configuration
function handle_raw_file()
    global Raw_file_numSubframes Raw_file_subframeIdx_buf Raw_file_sessionFlag;

    if strcmp(CFG_PARAMS.datacard_dataLoggingMode, 'raw')
        Raw_file_numSubframes = Raw_file_numSubframes + 1;
        Raw_file_subframeIdx_buf = [Raw_file_subframeIdx_buf, 0];
        Raw_file_sessionFlag = 'HW';
    else
        error('Error: no header cannot be in multi mode!');
    end
end

% Function to handle configuration when header is enabled
function handle_header_enabled()
    global lvdsCfg_dataFmt_buf lvdsCfg_userBufEn_buf ADC_file_sessionFlag CC9_file_sessionFlag;
    global ADC_file_numSubframes ADC_file_subframeIdx_buf CC9_file_numSubframes CC9_file_subframeIdx_buf;

    if lvdsCfg_dataFmt_buf(1) == 1 || lvdsCfg_dataFmt_buf(1) == 4
        ADC_file_sessionFlag = 'HW';
        CC9_file_sessionFlag = 'SW';
        ADC_file_numSubframes = ADC_file_numSubframes + 1;
        ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, 0];
        if lvdsCfg_userBufEn_buf(1) == 1
            CC9_file_numSubframes = CC9_file_numSubframes + 1;
            CC9_file_subframeIdx_buf = [CC9_file_subframeIdx_buf, 0];
        end
    elseif lvdsCfg_dataFmt_buf(1) == 0
        ADC_file_sessionFlag = 'SW';
        CC9_file_sessionFlag = 'HW';
        if lvdsCfg_userBufEn_buf(1) == 1
            ADC_file_numSubframes = ADC_file_numSubframes + 1;
            ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, 0];
        else
            error('Error: subframe 0 has no HW and SW');
        end
    else
        error('subframe 0 has an invalid dataFmt config');
    end
end

% Function to handle advanced subframes
function handle_advanced_subframes()
    global CFG_PARAMS lvdsCfg_dataFmt_buf lvdsCfg_userBufEn_buf ADC_file_sessionFlag CC9_file_sessionFlag;
    global ADC_file_numSubframes ADC_file_subframeIdx_buf CC9_file_numSubframes CC9_file_subframeIdx_buf;

    for subframeIdx = 2:CFG_PARAMS.numSubframes
        if lvdsCfg_dataFmt_buf(subframeIdx) == 1 || lvdsCfg_dataFmt_buf(subframeIdx) == 4
            if strcmp(ADC_file_sessionFlag, 'HW')
                ADC_file_numSubframes = ADC_file_numSubframes + 1;
                ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, subframeIdx - 1];
            end
            if strcmp(CC9_file_sessionFlag, 'HW')
                CC9_file_numSubframes = CC9_file_numSubframes + 1;
                CC9_file_subframeIdx_buf = [CC9_file_subframeIdx_buf, subframeIdx - 1];
            end
        end
        if lvdsCfg_userBufEn_buf(subframeIdx) == 1
            if strcmp(ADC_file_sessionFlag, 'SW')
                ADC_file_numSubframes = ADC_file_numSubframes + 1;
                ADC_file_subframeIdx_buf = [ADC_file_subframeIdx_buf, subframeIdx - 1];
            end
            if strcmp(CC9_file_sessionFlag, 'SW')
                CC9_file_numSubframes = CC9_file_numSubframes + 1;
                CC9_file_subframeIdx_buf = [CC9_file_subframeIdx_buf, subframeIdx - 1];
            end
        end
    end
end

% Assuming you have the variables capturedFileName, numSubframes, and subframeIdx_buf initialized
[return_value, all_frames_ADC_buffer, all_frames_CP_buffer, all_frames_CQ1_buffer, all_frames_CQ2_buffer] = parser_HW_file(capturedFileName, numSubframes, subframeIdx_buf);
