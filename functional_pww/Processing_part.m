clear;
clc;
close all;
% load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_radarCube.mat");
load("X:\Personals\Subin_Moon\Radar\0_data\cycle_moving_adc_raw_data.mat");

%% parameters
chirpsIdx=20;
chanIdx=1;
%frame_number=120;

numrangeBins=256;
NChirp=128;
NChan=4;
NSample=256;
Rx = 4;
Tx = 1;
Nframe = 256;                        % 프레임 수
c = 3e8;                             % 빛의 속도 (미터/초)
pri=76.51e-6;                        %ramp end tiem + idle time
prf=1/pri;
start_frequency = 77e9;              % 시작 주파수 (Hz)
wavelength = c / start_frequency;    % 파장(lambda)
slope = 32.7337;                     % 슬로프 (MHz/s)
samples_per_chirp = 256;             % 하나의 칩에서의 샘플 수
chirps_per_frame = 128;              % 프레임 당 chirps 수
sampling_rate = 5e9;                 % 샘플링 속도 (Hz)
% 대역폭 = sampling time*frequency slope (sampling time = samples / sample rate)
bandwidth = 1.6760e9;                % 대역폭 (Hz)
%거리 해상도 = c/(2*bandwidth)
range_resolution = c/(2*bandwidth);                    % 거리 해상도 (m)
%속도 해상도 = wavelength/(2*pri*Nchirp)
velocity_resolution =wavelength/(2*pri*NChirp);        % 속도 해상도 (m/s)
sampling_time = NSample/sampling_rate;                 % 샘플링 타임 (s)
max_vel = wavelength/(4*pri);                          % 최대 속도
max_range = (NSample-1)*range_resolution;              % 최대 거리

% 전체 걸린 시간 frame periodicity : 40ms -> 40ms*256 = 10.24s
frame_periodicity = 4e-2;

% MTI parameter(이때 chirpsIdx가 1보다 커야 함.)
MTIfiltering = 1;

% Range Azimuth FFT parameter
minRangeBinKeep = 0;
rightRangeBinDiscard = 1;
log_plot = 0;
angleFFTSize = 256;
ratio = 0.5;
DopplerCorrection = 0;
d = 1;

% 1D CA-CFAR parameter
window_sz = 33;          % total window size
no_tcell = 24;           % # of training window
no_gcell = 8;            % # of guard window
scale_factor_1D = 2;  % threshold scale factor
object_number = 2;

% CAOS_CFAR_2D parameter
Nt = 24;                 % # of training window
Ng = 8;                  % # of guard window
scale_factor_2D = 1.15;  % threshold scale factor 1.25

Nt_static = 48;          % # of training window
Ng_static = 64;          % # of guard window
scale_factor_2D_static = 1.01; % threshold scale factor 1.25

% FindPeakValue parameter
minPeakHeight = 10;
peak_th = 0.6;

% Clustering parameter
dbscan_mode = 1;
  % k-means
   k = 2;
  % DBSCAN
   eps = 2.5;
   MinPts = 10; 
   eps_static = 2.5;
   MinPts_static = 5; 

% microdoppler parameter
RangeBinIdx = 22;

% Range Azimuth Map 2D CA-CFAR parameter
scale_factor_2D_ram = 1.08;

cnt = 0;
for frame_number = 1:256
    cnt = cnt + 1;
    %% Reshape Data
    [frameComplex_cell] = ReshapeData(NChirp, NChan, NSample, Nframe, adcRawData);
    
    %% Time domain output
    % frame마다 저장할 필요없음
    [currChDataQ, currChDataI, t] = TimeDomainOutput(NSample, sampling_time, chirpsIdx, chanIdx, frame_number, frameComplex_cell);
    
    %% FFT Range Profile
    [rangeProfileData, radarCubeData_cell, channelData, rangeBin] = RangeFFT(NChirp, NChan, NSample, Nframe, ...
        chirpsIdx, chanIdx, numrangeBins, range_resolution, frame_number, frameComplex_cell);
    
    % MTI filter
    [radarCubeData_mti_cell, rangeProfileData_mti, channelData_mti] = MTI_filter(NChirp, NChan, NSample, Nframe,...
        chirpsIdx, chanIdx, frame_number,radarCubeData_cell);
    
    %% Range Doppler FFT
    [max_row, max_col, maxValue, velocityAxis, doppler_cell, doppler_mti_cell, db_doppler, db_doppler_mti] = RangeDopplerFFT(NChirp, ...
        NChan, NSample, Nframe, chanIdx, max_vel, velocity_resolution, frame_number, radarCubeData_cell, radarCubeData_mti_cell);
    
    %% Range Azimuth FFT
    [y_axis, x_axis, angleBin, angleFFT_output, angleFFT_output_mti, ram_output, ram_output_mti, mag_data, mag_data_mti] = RangeAzimuthFFT(range_resolution, ...
        d, minRangeBinKeep, rightRangeBinDiscard, angleFFTSize, frame_number, doppler_cell, doppler_mti_cell);
    
    %% Find Target
    [peak_locs, peaks, target_Idx, target] = FindTarget(minPeakHeight, peak_th, channelData_mti);
    
    %% 1D CA-CFAR
    [detected_points_1D, cfarData_mti, th, scale_factor_1D] = CA_CFAR_1D(window_sz, ...
        object_number, scale_factor_1D, no_tcell, no_gcell, rangeProfileData_mti);
    
    %% 2D RDM CFAR
    % MTI
    [detected_points_2D] = CAOS_CFAR_2D(NSample, NChirp, Nt, Ng, scale_factor_2D, db_doppler_mti);
    % not MTI
    [detected_points_2D_static] = OS_CFAR_2D_static(NSample, NChirp, Nt_static, Ng_static, scale_factor_2D_static, db_doppler);
    
    %% Clustering
    % % K-means
    % [detected_points_clustering] = K_means(NSample,NChirp, k, detected_points_2D);
    % 
    % DBSCAN
     % MTI
    [clusterGrid, idx_db_doppler, corepts] = DBSCAN(eps, MinPts, NSample, NChirp, detected_points_2D, db_doppler_mti);
     % not MTI
    [clusterGrid_static, idx_db_doppler_static, corepts_static] = DBSCAN(eps_static, MinPts_static, NSample, NChirp, detected_points_2D_static, db_doppler);
    
    %% Micro doppler
    [time_axis, micro_doppler_mti, micro_doppler] = microdoppler(NChirp, NChan, Nframe, RangeBinIdx, radarCubeData_mti_cell, radarCubeData_cell);
    
    % power of microdoppler
    sdb = squeeze(10*log10((abs(micro_doppler(:,chanIdx,:)))));
    sdb_mti = squeeze(10*log10((abs(micro_doppler_mti(:,chanIdx,:)))));
    
    %% Range Time Map
    [range_time] = RangeTimeMap(NSample, NChan, Nframe, chirpsIdx, radarCubeData_mti_cell);
    
    % power of range_time
    sdb_rangetime = squeeze(10*log10((abs(range_time(:,chanIdx,:)))));
    
    %% Angle FFT 이게 더 사용 가능성 높을 듯
    % input: doppler이랑 range_profile이랑 차이가 없는 것 같음.
    % AngData_mti : Range Angle Doppler tensor
    [AngData, AngData_mti, ram_output2, ram_output2_mti] = AngleFFT(NChirp, ...
        NChan, NSample, angleFFTSize, frame_number, radarCubeData_cell, radarCubeData_mti_cell);
    % Angle Cropping
    num_crop = 3;
    max_value = 1e+04;
    Angdata_crop = AngData_mti(:, :, num_crop + 1:NSample - num_crop);
    [Angdata_crop] = Normalize(Angdata_crop, max_value);
    
    %% Range Azimuth Map 2D CA-CFAR
    Nt = 48;
    Ng = 48;
    [detected_points_2D_ram] = RAM_CA_CFAR_2D(NSample, angleFFTSize, Nt, Ng, scale_factor_2D_ram, 10*log10(ram_output2_mti));
    
    %% Peak Grouping RDM - 움직이는 물체만 적용(고정된 물체도 적용해야 할 듯) clustergrid를 mti거치지 않은 데이터로
    % dynamic data
    [objOut_dynamic] = peakGrouping(clusterGrid, db_doppler);
    % static data
    [objOut_static] = peakGrouping(clusterGrid_static, db_doppler);
    
    % Peak Grouping RAM - RAM에 대해서 하는 것은 딱히 필요없음
    [objOut_RAM] = peakGrouping(detected_points_2D_ram, ram_output2);
    
    %% Angle estimation dets
    % RDM의 값을 넣었을 때는 Resel_agl이 제대로 나오지 않음
    % RAM값을 넣었을 때는 objOut과 objOut_RAM의 차원이 맞지 않아 point cloud에서 오류 발생
    % dynamic data
    [Resel_agl_dynamic, vel_ambg_list_dynamic, rng_excd_list_dynamic] = angle_estim_dets(objOut_dynamic, frame_number, ...
           radarCubeData_mti_cell, NChirp, angleFFTSize, Rx, Tx, num_crop);
    % static data
    [Resel_agl_static, vel_ambg_list_static, rng_excd_list_static] = angle_estim_dets(objOut_static, frame_number, ...
           radarCubeData_cell, NChirp, angleFFTSize, Rx, Tx, num_crop);
    
    %% objOut의 데이터가 있는 경우와 없는 경우를 나눔
    if isempty(objOut_dynamic)
    % 타겟이 detecting되지 않았을 때 즉, objOut 데이터가 아무것도 없는 경우
       % dynamic data
        objOut_dynamic = nan(3,1);
        save_det_data_dynamic = nan(1, 7);
        target_x_dynamic = [];
        target_y_dynamic = [];
       % static data
        objOut_static = nan(3,1);
        save_det_static = nan(1, 7);
        target_x_static = [];
        target_y_static = [];
       
    else 
    % deecting된 target이 있는 경우 
    %% detecting for point cloud
    % Error Management:
    if isempty(objOut_dynamic) 
        continue;
    end
    
    % dynamic data
    Resel_agl_deg_dynamic = angleBin(1, Resel_agl_dynamic);
    Resel_vel_dynamic = velocityAxis(1, objOut_dynamic(1,:));
    Resel_rng_dynamic = rangeBin(1, objOut_dynamic(2,:));
    
    save_det_data_dynamic = [objOut_dynamic(2,:)', objOut_dynamic(1,:)', Resel_agl_dynamic', objOut_dynamic(3,:)', ...
    Resel_rng_dynamic', Resel_vel_dynamic', Resel_agl_deg_dynamic'];

    % Error Management:
    if isempty(objOut_static) 
        continue;
    end

    % static data
    Resel_agl_deg_static = angleBin(1, Resel_agl_static);
    Resel_vel_static = velocityAxis(1, objOut_static(1,:));
    Resel_rng_static = rangeBin(1, objOut_static(2,:));

    save_det_data_static = [objOut_static(2,:)', objOut_static(1,:)', Resel_agl_static', objOut_static(3,:)', ...
    Resel_rng_static', Resel_vel_static', Resel_agl_deg_static'];
    
    %% Detection & Angle estimation data
    % 중심축이 90도가 되도록 target angle 변환 
      target_angle_deg_dynamic = 90 - Resel_agl_deg_dynamic;
      target_angle_deg_static = 90 - Resel_agl_deg_static;
    % target x, y좌표 구하기
      % dynamic
      target_x_dynamic = Resel_rng_dynamic.*cosd(target_angle_deg_dynamic);
      target_y_dynamic = Resel_rng_dynamic.*sind(target_angle_deg_dynamic);
      % static
      target_x_static = Resel_rng_static.*cosd(target_angle_deg_static);
      target_y_static = Resel_rng_static.*sind(target_angle_deg_static);
    end
    % x, y축 범위 설정
    x_min = -max_range;
    x_max = max_range;
    y_min = 0;
    y_max = max_range;
    
    %% Plot part
    close all;
    MTIfiltering = 1;
    log_plot = 0;
    dbscan_mode = 1;
    
    %% 2D RDM CA-OS CFAR plot
    % plot 2D CAOS-CFAR
    figure('Position', [300,100, 1200, 800]);
    tiledlayout(2,2);
    
    
    %% Range Doppler FFT plot - RDM
    % plot Range Doppler Map
    nexttile;
    if MTIfiltering
        imagesc(velocityAxis,rangeBin,db_doppler_mti);
        title('Range-Doppler Map (MTI)');
    else
        imagesc(velocityAxis,rangeBin,db_doppler);
        title('Range-Doppler Map (not MTI)');
    end
    xlabel('Velocity (m/s)');
    ylabel('Range (m)');
    % yticks(0:2:max(rangeBin));
    colorbar;
    axis xy
    
    %% RDM CFAR
    nexttile;
    if MTIfiltering
        imagesc(velocityAxis,rangeBin,detected_points_2D);
        title('RDM 2D CFAR Target Detect (MTI)');
    else
        imagesc(velocityAxis,rangeBin,detected_points_2D_static);
        title('RDM 2D CFAR Target Detect (not MTI)');
    end
    xlabel('Velocity (m/s)');
    ylabel('Range (m)');
    yticks(0:2:max(rangeBin));
    colorbar;
    axis xy
    
    %% Clustering plot
    nexttile;
    % plot DBSCAN clustering
    if dbscan_mode
        if MTIfiltering
           imagesc(velocityAxis, rangeBin, clusterGrid);
           title('DBSCAN Clustering (MTI)');
        else
           imagesc(velocityAxis, rangeBin, clusterGrid_static);
           title('DBSCAN Clustering (not MTI)');
        end
    % Plot K-means Clustering
    else 
        imagesc(velocityAxis,rangeBin,detected_points_clustering);
        title('K-means Clustering');
    end
    xlabel('Velocity (m/s)');
    ylabel('Range (m)');
    yticks(0:2:max(rangeBin));
    axis xy
    colorbar;
    
    %% Detection & Angle estimation Results plot
    nexttile;
    hold on;
    % dynamic target position plot
    plot(target_x_dynamic, target_y_dynamic, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
    %hold on;
    % static target position plot
    %plot(target_x_static, target_y_static, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
    % radar position plot
    hold on;
    plot(0, 0, '^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
    
    % plot 범위 설정
    axis([x_min, x_max, y_min, y_max]);
    xlabel('X (m)');
    ylabel('Y (m)');
    title('Detection & Angle estimation Results');
    grid on;
    hold off;
    % yticks(0:2:max_range);
    % xticks(-max_range:2:max_range);
    
    drawnow;
    
    if isempty(target_x_dynamic)
        continue;
    end

    x_radar(:,cnt) = target_x_dynamic(1);
    y_radar(:,cnt) = target_y_dynamic(1);
    
end