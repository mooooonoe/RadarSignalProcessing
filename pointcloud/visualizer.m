clear; clc; close all;
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_adc_raw_data.mat");
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_radarCube.mat");

%% parameters

% Number of Frame
NoFrameStart = 1;
NoFrameEnd = 256;

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
detected_points(:,:) = zeros(NSample, NChirp+1);
HistoryMap = zeros(Nframe, 2);
cnt = 1;


frame_n = 120;

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
[detected_points_each] = CFAR(frame_n, numrangeBins, rangeProfileData_mti, db_doppler);
[clusterGrid, R, C] = DBSCAN(velocityAxis, rangeBin, detected_points_each);


%% Angle FFT 이게 더 사용 가능성 높을 듯
% input: doppler이랑 range_profile이랑 차이가 없는 것 같음.
% AngData_mti : Range Angle Doppler tensor
[AngData, AngData_mti, ram_output2, ram_output2_mti] = AngleFFT(NChirp, ...
    NChan, NSample, angleFFTSize, frame_n, 0, radarCubeData_mti);
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
[Resel_agl_dynamic, vel_ambg_list_dynamic, rng_excd_list_dynamic] = angle_estim_dets(objOut_dynamic, frame_n, ...
       radarCubeData_mti_cell, NChirp, angleFFTSize, Rx, Tx, num_crop);
% static data
[Resel_agl_static, vel_ambg_list_static, rng_excd_list_static] = angle_estim_dets(objOut_static, frame_n, ...
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
% dynamic data
Resel_agl_deg_dynamic = angleBin(1, Resel_agl_dynamic);
Resel_vel_dynamic = velocityAxis(1, objOut_dynamic(1,:));
Resel_rng_dynamic = rangeBin(1, objOut_dynamic(2,:));

save_det_data_dynamic = [objOut_dynamic(2,:)', objOut_dynamic(1,:)', Resel_agl_dynamic', objOut_dynamic(3,:)', ...
Resel_rng_dynamic', Resel_vel_dynamic', Resel_agl_deg_dynamic'];

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