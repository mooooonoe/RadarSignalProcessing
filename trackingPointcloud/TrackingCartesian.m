clear; clc; %close all;
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_adc_raw_data.mat");
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_radarCube.mat");

%% parameters

% Number of Frame
NoFrameStart = 40;
NoFrameEnd = 128;

% MTI parameter
MTIfiltering = 1;

% Range Azimuth FFT parameter
minRangeBinKeep = 0; rightRangeBinDiscard = 1; log_plot = 1; STATIC_ONLY = 0; angleFFTSize = 256;
ratio = 0.5; DopplerCorrection = 0; d = 1;
% 1D CA-CFAR parameter
window_sz = 33;          % total window size
no_tcell = 24;           % # of training window
no_gcell = 8;            % # of guard window
scale_factor_1D = 2;  % threshold scale factor
object_number = 2;

% Range Azimuth Map 2D CA-CFAR parameter
scale_factor_2D = 1.24;
scale_factor_2D_static = 1.085;
scale_factor_2D_ram = 1.07;

Nt = 24;                 % # of training window
Ng = 8;                  % # of guard window
Nt_static = 48;          % # of training window
Ng_static = 64;          % # of guard window

% DBSCAN
eps = 2.5;
MinPts = 6; 
eps_static = 2.5;
MinPts_static = 5; 

%% Radar cfg
chirpsIdx=50;chanIdx=1; Rx = 4; Tx = 1;


numrangeBins=256;NChirp=128;NChan=4;NSample=256;Nframe = 256;c = 3e8;pri=76.51e-6;prf=1/pri;
start_frequency = 77e9;wavelength = c / start_frequency;slope = 32.7337;samples_per_chirp = 256;
chirps_per_frame = 128;sampling_rate = 5e9;bandwidth = 1.6760e9;range_resolution = c/(2*bandwidth);
velocity_resolution =wavelength/(2*pri*NChirp);sampling_time = NSample/sampling_rate;
max_vel = wavelength/(4*pri);max_range = sampling_rate*c/(2*slope);
frame_periodicity = 4e-2;

%% func
detected_cart_points(:,:) = zeros(NSample+1, NSample);
HistoryCartMap = zeros(Nframe, 2);
detected_points(:,:) = zeros(NSample+1, NSample);
HistoryMap = zeros(Nframe, 2);
cnt = 1;

frame_number = 120;
    
[frameComplex_cell] = ReshapeData(NChirp, NChan, NSample, Nframe, adcRawData);
[currChDataQ, currChDataI, t] = TimeDomainOutput(NSample, sampling_time, chirpsIdx, chanIdx, frame_number, frameComplex_cell);
[rangeProfileData, radarCubeData_cell, channelData, rangeBin] = RangeFFT(NChirp, NChan, NSample, Nframe, ...
    chirpsIdx, chanIdx, numrangeBins, range_resolution, frame_number, frameComplex_cell);
[radarCubeData_mti_cell, rangeProfileData_mti, channelData_mti] = MTI_filter(NChirp, NChan, NSample, Nframe, ...
    chirpsIdx, chanIdx, frame_number, radarCubeData_cell);
[max_row, max_col, maxValue, velocityAxis, doppler_cell, doppler_mti_cell, db_doppler, db_doppler_mti] = RangeDopplerFFT(NChirp, ...
    NChan, NSample, Nframe, chanIdx, max_vel, velocity_resolution, frame_number, radarCubeData_cell, radarCubeData_mti_cell);
[y_axis, x_axis, angleBin, angleFFT_output, angleFFT_output_mti, ram_output, ram_output_mti, mag_data, mag_data_mti] = RangeAzimuthFFT(range_resolution, ...
    d, minRangeBinKeep, rightRangeBinDiscard, angleFFTSize, frame_number, doppler_cell, doppler_mti_cell);

%% Angle FFT
% input: doppler이랑 range_profile이랑 차이가 없는 것 같음.
% AngData_mti : Range Angle Doppler tensor
[AngData, AngData_mti, ram_output2, ram_output2_mti] = AngleFFT(NChirp, ...
    NChan, NSample, angleFFTSize, frame_number, radarCubeData_cell, radarCubeData_mti_cell);
% Angle Cropping
num_crop = 3;
max_value = 1e+04;
Angdata_crop = AngData_mti(:, :, num_crop + 1:NSample - num_crop);
[Angdata_crop] = Normalize(Angdata_crop, max_value);

%% CFAR
% MTI
% [detected_points_2D, scale_factor_CA, scale_factor_OS] = CAOS_CFAR_2D(window_sz, no_tcell, no_gcell, rangeProfileData_mti, ...
%     NSample, NChirp, Nt, Ng, db_doppler_mti);

[detected_points_2D] = CFAR(frame_number, numrangeBins, rangeProfileData_mti, db_doppler_mti);
% not MTI
%[detected_points_2D_static] = CFAR_static(frame_number, numrangeBins, rangeProfileData, db_doppler);

% DBSCAN
 % MTI
%[clusterGrid] = DBSCAN(eps, MinPts, NSample, NChirp, detected_points_2D, db_doppler_mti);
 % not MTI
% [clusterGrid_static, idx_db_doppler_static, corepts_static] = DBSCAN(eps_static, MinPts_static, NSample, NChirp, detected_points_2D_static, db_doppler);


%% Range Azimuth Map 2D CA-CFAR
% Nt = 48;
% Ng = 48;
% [detected_points_2D_ram] = RAM_CA_CFAR_2D(NSample, angleFFTSize, Nt, Ng, scale_factor_2D_ram, 10*log10(ram_output2_mti));
% 
% %% Peak Grouping RDM - 움직이는 물체만 적용(고정된 물체도 적용해야 할 듯) clustergrid를 mti거치지 않은 데이터로
% % dynamic data
% [objOut_dynamic] = peakGrouping(clusterGrid, db_doppler);
% % static data
% [objOut_static] = peakGrouping(clusterGrid_static, db_doppler);
% 
% % Peak Grouping RAM - RAM에 대해서 하는 것은 딱히 필요없음
% [objOut_RAM] = peakGrouping(detected_points_2D_ram, ram_output2);
% 
% %% Angle estimation dets
% % RDM의 값을 넣었을 때는 Resel_agl이 제대로 나오지 않음
% % RAM값을 넣었을 때는 objOut과 objOut_RAM의 차원이 맞지 않아 point cloud에서 오류 발생
% % dynamic data
% [Resel_agl_dynamic, vel_ambg_list_dynamic, rng_excd_list_dynamic] = angle_estim_dets(objOut_dynamic, frame_number, ...
%        radarCubeData_mti_cell, NChirp, angleFFTSize, Rx, Tx, num_crop);
% % static data
% [Resel_agl_static, vel_ambg_list_static, rng_excd_list_static] = angle_estim_dets(objOut_static, frame_number, ...
%        radarCubeData_cell, NChirp, angleFFTSize, Rx, Tx, num_crop);
% 
% %% objOut의 데이터가 있는 경우와 없는 경우를 나눔
% if isempty(objOut_dynamic)
% % 타겟이 detecting되지 않았을 때 즉, objOut 데이터가 아무것도 없는 경우
%    % dynamic data
%     objOut_dynamic = nan(3,1);
%     save_det_data_dynamic = nan(1, 7);
%     target_x_dynamic = [];
%     target_y_dynamic = [];
%    % static data
%     objOut_static = nan(3,1);
%     save_det_static = nan(1, 7);
%     target_x_static = [];
%     target_y_static = [];
% 
% else 
% % deecting된 target이 있는 경우 
% %% detecting for point cloud
% % dynamic data
% Resel_agl_deg_dynamic = angleBin(1, Resel_agl_dynamic);
% Resel_vel_dynamic = velocityAxis(1, objOut_dynamic(1,:));
% Resel_rng_dynamic = rangeBin(1, objOut_dynamic(2,:));
% 
% save_det_data_dynamic = [objOut_dynamic(2,:)', objOut_dynamic(1,:)', Resel_agl_dynamic', objOut_dynamic(3,:)', ...
% Resel_rng_dynamic', Resel_vel_dynamic', Resel_agl_deg_dynamic'];
% 
% % static data
% Resel_agl_deg_static = angleBin(1, Resel_agl_static);
% Resel_vel_static = velocityAxis(1, objOut_static(1,:));
% Resel_rng_static = rangeBin(1, objOut_static(2,:));
% 
% save_det_data_static = [objOut_static(2,:)', objOut_static(1,:)', Resel_agl_static', objOut_static(3,:)', ...
% Resel_rng_static', Resel_vel_static', Resel_agl_deg_static'];
% 
% %% Detection & Angle estimation data
% % 중심축이 90도가 되도록 target angle 변환 
%   target_angle_deg_dynamic = 90 - Resel_agl_deg_dynamic;
%   target_angle_deg_static = 90 - Resel_agl_deg_static;
% % target x, y좌표 구하기
%   % dynamic
%   target_x_dynamic = Resel_rng_dynamic.*cosd(target_angle_deg_dynamic);
%   target_y_dynamic = Resel_rng_dynamic.*sind(target_angle_deg_dynamic);
%   % static
%   target_x_static = Resel_rng_static.*cosd(target_angle_deg_static);
%   target_y_static = Resel_rng_static.*sind(target_angle_deg_static);
% end
% % x, y축 범위 설정
% x_min = -max_range;
% x_max = max_range;
% y_min = 0;
% y_max = max_range;

    
    % %% range angle map
    % cart_data_dynamic = flipud((flipud(mag_data_dynamic))');
    % [detected_cart_points_each] = CFAR_CART(frame_number, numrangeBins, rangeProfileData_mti, cart_data_dynamic);
    % 
    % 
    % % if isempty(cart_data_dynamic)
    % %     clusterCartGrid = zeros(size(x_axis));
    % %     R = 0; % or any other default value
    % %     C = 0; % or any other default value
    % % else
    % %     [clusterCartGrid, R, C] = DBSCAN_CART(y_axis, x_axis, cart_data_dynamic);
    % % end
    % % 
    % % if (length(clusterCartGrid(1,:))==257)
    % %     mat(:,:) = clusterCartGrid(:,1:256);
    % % else
    % %     disp('pass')
    % % end
    % % 
    % % HistoryCartMap(frame_n, 1) = R;
    % % HistoryCartMap(frame_n, 2) = C;
    % % detected_cart_points(:,:,cnt) = mat;
    % 
    % %x_axis_cart = -abs(max(rangeBin)):abs(max(rangeBin));
    % x_axis_cart = -90.00 : 90.00;
    % yaxiscart = 0:abs(max(rangeBin)); 
    % y_axis_cart = flipud(yaxiscart');
    % nexttile;
    % imagesc(x_axis_cart, y_axis_cart, cart_data_dynamic);
    % set(gca, 'YDir', 'normal');
    % title('Range Angle'); xlabel('angle(degres)'); ylabel('meters(m)');
    % 
    % nexttile;
    % imagesc(x_axis_cart, y_axis_cart,detected_cart_points_each);
    % xlabel('Velocity (m/s)');
    % ylabel('Range (m)');
    % yticks(0:2:max(rangeBin));
    % title('Range Angle CFAR');xlabel('angle(degres)'); ylabel('meters(m)');
    % colorbar;
    % axis xy
    % 
    % %% range azimuth map 
    % 
    % [detected_points_each] = CFAR(frame_number, numrangeBins, rangeProfileData_mti, mag_data_dynamic);
    % if isempty(detected_points_each)
    %     clusterGrid = zeros(size(x_axis));
    % else
    %     [clusterGrid, R, C] = DBSCAN(y_axis, x_axis, detected_points_each);
    % end
    % 
    % HistoryMap(frame_number, 1) = R;
    % HistoryMap(frame_number, 2) = C;
    % detected_points(:,:,cnt) = clusterGrid;
    % 
    % cnt = cnt+1; 
    % 
    % nexttile;
    % if STATIC_ONLY == 1
    %     if log_plot
    %         surf(y_axis, x_axis, (mag_data_static).^0.4,'EdgeColor','none');
    %     else
    %         surf(y_axis, x_axis, abs(mag_data_static),'EdgeColor','none');
    %     end
    % else
    %     if log_plot
    %         surf(y_axis, x_axis, (mag_data_dynamic).^0.4,'EdgeColor','none');
    %     else
    %         surf(y_axis, x_axis, abs(mag_data_dynamic),'EdgeColor','none');
    %     end
    % end
    % view(2);
    % colorbar;
    % title('Range Azimuth');
    % xlabel('meters');
    % ylabel('meters');
    % 
    % nexttile;
    % surf(y_axis, x_axis, abs(detected_points_each),'EdgeColor','none');
    % view(2);
    % colorbar;
    % title('Range Azimuth');
    % xlabel('meters');
    % ylabel('meters');
    % 
    % drawnow;


%% PLOTFRAMEDATA(velocityAxis, rangeBin, cnt, detected_points, HistoryMap);


% Plot part
close all;
MTIfiltering = 1;
log_plot = 0;
dbscan_mode = 1;
%% Time domain output plot
% plot time domain
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
plot(t,currChDataI(:),t,currChDataQ(:))
xlabel('time (seconds)');                  
ylabel('ADC time domain output');        
title('Time Domain Output');
grid on;

%% FFT Range Profile plot
% plot range profile MTI or not MTI
nexttile;
if MTIfiltering
    % plot MTI filter range profile 
    plot(rangeBin,channelData_mti)
    xlabel('Range (m)');                  
    ylabel('Range FFT output (dB)');        
    title('Range Profile (MTI)');
    grid on;
else
    % plot not MTI filter range profile
    plot(rangeBin,channelData)
    xlabel('Range (m)');                  
    ylabel('Range FFT output (dB)');        
    title('Range Profile (not MTI)');
    grid on;
end

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

% nexttile;
% if MTIfiltering
%     imagesc(angleBin,rangeBin,ram_output2_mti)
%     title('Range Azimuth map MTI');
% else
%     imagesc(angleBin,rangeBin,ram_output2)
%     title('Range Azimuth map not MTI');
% end
% xlabel('Angle( \circ)')
% ylabel('Range(m)')
% yticks(0:2:max(rangeBin));
% colorbar;
% axis xy

nexttile;
imagesc(velocityAxis,rangeBin,detected_points_2D);
title('RDM 2D CFAR Target Detect (MTI)');
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
colorbar;
axis xy

% 
% %% Detection & Angle estimation Results plot
% figure('Position', [300,100, 1200, 800]);
% tiledlayout(2,2);
% nexttile;
% hold on;
% % dynamic target position plot
% plot(target_x_dynamic, target_y_dynamic, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
% hold on;
% % static target position plot
% plot(target_x_static, target_y_static, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
% % radar position plot
% hold on;
% plot(0, 0, '^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
% 
% % plot 범위 설정
% axis([x_min, x_max, y_min, y_max]);
% xlabel('X (m)');
% ylabel('Y (m)');
% title('Detection & Angle estimation Results');
% grid on;
% hold off;
% % yticks(0:2:max_range);
% % xticks(-max_range:2:max_range);

