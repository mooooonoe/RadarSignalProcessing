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

for frame_n = NoFrameStart:1:NoFrameEnd-1
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

    HistoryMap(frame_n, 1) = R;
    HistoryMap(frame_n, 2) = C;
    detected_points(:,:,cnt) = clusterGrid;

    cnt = cnt+1; 
end

%% Kalman
Ns = length(HistoryMap(:,1));
[Xsaved, Zsaved] = KALMAN(Ns, HistoryMap);

%% Plot
PLOTFRAMEDATA(velocityAxis, rangeBin, cnt, detected_points, HistoryMap, Xsaved);


