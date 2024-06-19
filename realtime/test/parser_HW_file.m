function [return_value, all_frames_ADC_buffer, all_frames_CP_buffer, all_frames_CQ1_buffer, all_frames_CQ2_buffer] = parser_HW_file(capturedFileName, numSubframes, subframeIdx_buf)
    % Initialize global variables
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
    global TC_PASS;
    global TC_FAIL;

    disp(capturedFileName);
    disp(numSubframes);
    disp(subframeIdx_buf);
    
    if contains(capturedFileName, '0ADC')
        ID = 926064613602757340;
    elseif contains(capturedFileName, '0CC9')
        ID = 705953299182652617;
    else
        ID = 0;
    end
    
    fp = fopen(capturedFileName, 'rb');
    
    numBytesCapturedFile = dir(capturedFileName).bytes;

    all_frames_ADC_buffer = {};
    all_frames_CP_buffer = {};
    all_frames_CQ1_buffer = {};
    all_frames_CQ2_buffer = {};

    chirpMode = CFG_PARAMS.chirpMode;
    numRxChan = CFG_PARAMS.numRxChan;
    
    return_value = TC_PASS;
    frameIdx = 0;

    while true
        disp(['****** HW session Frame ', num2str(frameIdx), ' ******']);
        disp(['frameIdx = ', num2str(floor(frameIdx / numSubframes))]);

        subframeIdx = subframeIdx_buf(mod(frameIdx, numSubframes) + 1);
        disp(['subframeIdx = ', num2str(subframeIdx)]);

        frame_ADC_buffer = {};
        frame_CP_buffer = {};
        frame_CQ1_buffer = {};
        frame_CQ2_buffer = {};

        % Get current frame's parameters
        numAdcSamples = numAdcSamples_buf(subframeIdx);
        profileIdx = profileIdx_buf(subframeIdx);
        numChirpPerFrame = numLoops_buf(subframeIdx) * numOfChirps_buf(subframeIdx);

        CFG_PARAMS.headerEn = lvdsCfg_headerEn_buf(subframeIdx);
        CFG_PARAMS.dataFmt = lvdsCfg_dataFmt_buf(subframeIdx);

        if lvdsCfg_dataFmt_buf(subframeIdx) == 4
            SigImgNumSlices = SigImgNumSlices_buf(subframeIdx);
            RxSatNumSlices = RxSatNumSlices_buf(subframeIdx);
        end

        for groupIdx = 1:(numChirpPerFrame / chirpMode)
            if lvdsCfg_headerEn_buf(subframeIdx) == 1
                get_hsi_header(fp);
                return_value = return_value + verify_hsi_header_hw(numAdcSamples, ID);
            end
            
            chirp_ADC_buffer = {};
            chirp_CP_buffer = {};
            chirp_CQ1_buffer = {};
            chirp_CQ2_buffer = {};

            if lvdsCfg_dataFmt_buf(subframeIdx) == 1  % ADC data format
                for idx = 1:(numRxChan * chirpMode)
                    ADC_buffer = get_ADC(fp, numAdcSamples, CFG_PARAMS.dataSize);
                    chirp_ADC_buffer{end+1} = ADC_buffer;
                end
            end

            if lvdsCfg_dataFmt_buf(subframeIdx) == 4  % CP+ADC+CQ data format
                for chirpIdx = 1:chirpMode
                    for chanIdx = 1:numRxChan
                        [CP_verify_result, CP_buffer] = get_verify_CP(fp, (profileIdx * 4) + chanIdx_buf(chanIdx), (groupIdx - 1) * chirpMode + chirpIdx);
                        return_value = return_value + CP_verify_result;
                        chirp_CP_buffer{end+1} = CP_buffer;
                    end

                    for idx = 1:(numRxChan * chirpMode)
                        ADC_buffer = get_ADC(fp, numAdcSamples, CFG_PARAMS.dataSize);
                        chirp_ADC_buffer{end+1} = ADC_buffer;
                    end

                    [CQ_verify_result, CQ1_buffer, CQ2_buffer] = get_verify_CQ(fp, SigImgNumSlices, RxSatNumSlices);
                    return_value = return_value + CQ_verify_result;
                    chirp_CQ1_buffer{end+1} = CQ1_buffer;
                    chirp_CQ2_buffer{end+1} = CQ2_buffer;
                end
            end

            frame_ADC_buffer{end+1} = chirp_ADC_buffer;
            frame_CP_buffer{end+1} = chirp_CP_buffer;
            frame_CQ1_buffer{end+1} = chirp_CQ1_buffer;
            frame_CQ2_buffer{end+1} = chirp_CQ2_buffer;
        end

        all_frames_ADC_buffer{end+1} = frame_ADC_buffer;
        all_frames_CP_buffer{end+1} = frame_CP_buffer;
        all_frames_CQ1_buffer{end+1} = frame_CQ1_buffer;
        all_frames_CQ2_buffer{end+1} = frame_CQ2_buffer;

        pos = ftell(fp);
        if frameIdx == 0
            numBytesPerFrame = pos;
        end
        disp(['Frame ', num2str(frameIdx), ' end at file location: ', num2str(pos)]);

        if pos + numBytesPerFrame > numBytesCapturedFile
            break;
        end

        frameIdx = frameIdx + 1;
    end

    fclose(fp);

    disp([capturedFileName, ' contains ', num2str(numBytesCapturedFile), ' bytes. ', num2str(pos), ' bytes/', num2str(frameIdx), ' frames have been parsed.']);

    if return_value == TC_PASS
        disp('Captured file is correct!');
    else
        return_value = TC_FAIL;
        disp('Captured file has errors!');
    end
end

% Helper functions would be defined here, e.g., get_hsi_header, verify_hsi_header_hw, get_ADC, get_verify_CP, get_verify_CQ

