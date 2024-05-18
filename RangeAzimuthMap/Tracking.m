clear; clc; %close all;
load("Z:\AWR1843\0_u_DopplerMapData\walk\walk_adc_raw_data.mat");
load("Z:\AWR1843\0_u_DopplerMapData\walk\walk_radarCube.mat");


%% parameters

% Number of Frame
NoFrameStart = 33;
NoFrameEnd = 34;

% MTI parameter
MTIfiltering = 1;

% Range Azimuth FFT parameter
minRangeBinKeep = 0; rightRangeBinDiscard = 1; log_plot = 1; STATIC_ONLY = 0; angleFFTSize = 256;
ratio = 0.5; DopplerCorrection = 0; d = 1;

%% Radar cfg
chirpsIdx=50;chanIdx=1;

numrangeBins=256;NChirp=128;NChan=4;NSample=256;Nframe = 256;c = 3e8;pri=76.51e-6;prf=1/pri;
start_frequency = 77e9;wavelength = c / start_frequency;slope = 32.7337;samples_per_chirp = 256;
chirps_per_frame = 128;sampling_rate = 5e9;bandwidth = 1.6760e9;range_resolution = c/(2*bandwidth);
velocity_resolution =wavelength/(2*pri*NChirp);sampling_time = NSample/sampling_rate;
max_vel = wavelength/(4*pri);max_range = sampling_rate*c/(2*slope);
frame_periodicity = 4e-2;

%% func
detected_points(:,:) = zeros(NSample+1, NSample);
HistoryMap = zeros(Nframe, 2);
cnt = 1;

figure; 

for frame_n = NoFrameStart:1:NoFrameEnd-1
    tiledlayout(1, 2);
    
    [frameComplex] = RESHAPE(NChirp, NChan, NSample, frame_n, adcRawData);
    [currChDataQ, currChDataI, t] = FT_TIME(NSample, sampling_time, chirpsIdx, chanIdx, frameComplex);
    [rangeProfileData, radarCubeData_demo, channelData, rangeBin] = FT_RANGE(NChirp, NChan, NSample, ...
        chirpsIdx, chanIdx, numrangeBins, range_resolution, frameComplex);
    [radarCubeData_mti, rangeProfileData_mti, channelData_mti] = MTI_filter(NChirp, NChan, NSample, ...
        chirpsIdx, chanIdx, radarCubeData_demo);
    [max_row, max_col, maxValue, velocityAxis, doppler, doppler_mti, db_doppler] = FFT_DOPPLER(NChirp, NChan, NSample, ...
        chanIdx, max_vel, velocity_resolution, MTIfiltering, radarCubeData_demo, radarCubeData_mti);
    [y_axis, x_axis, mag_data_static, mag_data_dynamic] = FFT_AZIMUTH(range_resolution, ...
        d, minRangeBinKeep, rightRangeBinDiscard, angleFFTSize, doppler);
    [detected_points_2D] = CFAR(frame_n, numrangeBins, rangeProfileData_mti, db_doppler);
    [detected_points_each] = CFAR(frame_n, numrangeBins, rangeProfileData_mti, mag_data_dynamic);
    if isempty(detected_points_each)
        clusterGrid = zeros(size(x_axis));
    else
        [clusterGrid, R, C] = DBSCAN(y_axis, x_axis, detected_points_each);
    end

    HistoryMap(frame_n, 1) = R;
    HistoryMap(frame_n, 2) = C;
    detected_points(:,:,cnt) = clusterGrid;

    cnt = cnt+1; 

    nexttile;
    if STATIC_ONLY == 1
        if log_plot
            surf(y_axis, x_axis, (mag_data_static).^0.4,'EdgeColor','none');
        else
            surf(y_axis, x_axis, abs(mag_data_static),'EdgeColor','none');
        end
    else
        if log_plot
            surf(y_axis, x_axis, (mag_data_dynamic).^0.4,'EdgeColor','none');
        else
            surf(y_axis, x_axis, abs(mag_data_dynamic),'EdgeColor','none');
        end
    end
    view(2);
    colorbar;
    title('Range Azimuth');
    xlabel('meters');
    ylabel('meters');

    % nexttile;
    % surf(y_axis, x_axis, abs(detected_points_each),'EdgeColor','none');
    % view(2);
    % colorbar;
    % title('Range Azimuth');
    % xlabel('meters');
    % ylabel('meters');

    [objOut] = peakGrouping(detected_points_2D, db_doppler);
    
    
    drawnow;
end



%% PLOTFRAMEDATA(y_axis, x_axis, cnt, detected_points, HistoryMap);


function [objOut] = peakGrouping(detected_points_2D, db_doppler)

% 2D CFAR에서 detecting된 target의 Range, Doppler 인덱스 구하기
% detected_points_2D row: range, column: doppler
[row_2d, col_2d] = find(detected_points_2D ~= 0);

% preallocation
cellPower = zeros(size(row_2d));
objOut = [];

% detecting된 target의 cell power 구하기
for i = 1:size(row_2d)
    cellPower(i) = db_doppler(row_2d(i), col_2d(i));
end
% 입력 detMat 구하기 
% 해당 코드에서 1행이 Doppler이고 2행이 Range이기 때문에 col, row 위치 바꿔서 저장
detMat = [col_2d'; row_2d'; cellPower'];
numDetectedObjects = size(detMat,2);

% detMat을 cellPower가 큰 순서부터 내림차순으로 정리
[~, order] = sort(detMat(3,:), 'descend');
detMat = detMat(:,order);

for ni = 1:numDetectedObjects
    detectedObjFlag = 1;
    rangeIdx = detMat(2,ni);
    dopplerIdx = detMat(1,ni);
    peakVal = detMat(3,ni);
    kernel = zeros(3,3);
    
    %% fill the middle column of the kernel
    % CUT라고 보면 됨. 검출할 객체
    kernel(2,2) = peakVal;
    
    % kernel을 만드는 과정
    % detMat에서 range,doppler 인덱스가 1씩 차이나는 것들을 모은다.
    % 설명은 캡스톤 진행사항 word에있음
    
    % fill the middle column of the kernel
    need_index = find(detMat(1,:) == dopplerIdx & detMat(2,:) == rangeIdx+1);
    if ~isempty(need_index)
        kernel(1,2) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx & detMat(2,:) == rangeIdx-1);
    if ~isempty(need_index)
        kernel(3,2) = detMat(3,need_index(1));
    end

    % fill the left column of the kernel
    need_index = find(detMat(1,:) == dopplerIdx-1 & detMat(2,:) == rangeIdx+1);
    if ~isempty(need_index)
        kernel(1,1) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx-1 & detMat(2,:) == rangeIdx);
    if ~isempty(need_index)
        kernel(2,1) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx-1 & detMat(2,:) == rangeIdx-1);
    if ~isempty(need_index)
        kernel(3,1) = detMat(3,need_index(1));
    end
    
    % Fill the right column of the kernel
    need_index = find(detMat(1,:) == dopplerIdx+1 & detMat(2,:) == rangeIdx+1);
    if ~isempty(need_index)
        kernel(1,3) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx+1 & detMat(2,:) == rangeIdx);
    if ~isempty(need_index)
        kernel(2,3) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx+1 & detMat(2,:) == rangeIdx-1);
    if ~isempty(need_index)
        kernel(3,3) = detMat(3,need_index(1));
    end
    
    % Compare the detected object to its neighbors.Detected object is
    % at index [2,2]
    if kernel(2,2) ~= max(max(kernel))
        detectedObjFlag = 0;
    end
    
    if detectedObjFlag == 1
        objOut = [objOut, detMat(:,ni)];
    end
end


end