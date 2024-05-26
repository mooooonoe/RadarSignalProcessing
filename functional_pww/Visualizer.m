clear;
clc;
close all;
load('Z:\AWR1843\0_u_DopplerMapData\walk\walk_adc_raw_data.mat');
load('Z:\AWR1843\0_u_DopplerMapData\walk\walk_radarCube.mat');

%% parameters
chirpsIdx=50;
chanIdx=1;
frame_number=100;

numrangeBins=256;
NChirp=128;
NChan=4;
NSample=256;
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
range_resolution = c/(2*bandwidth);           % 거리 해상도 (m)
%속도 해상도 = wavelength/(2*pri*Nchirp)
velocity_resolution =wavelength/(2*pri*NChirp);        % 속도 해상도 (m/s)
sampling_time = NSample/sampling_rate; % 샘플링 타임 (s)
max_vel = wavelength/(4*pri);          % 최대 속도
max_range = sampling_rate*c/(2*slope); %최대 거리

% 전체 걸린 시간 frame periodicity : 40ms -> 40ms*256 = 10.24s
frame_periodicity = 4e-2;

% MTI parameter(이때 chirpsIdx가 1보다 커야 함.)
MTIfiltering = 1;

% Range Azimuth FFT parameter
minRangeBinKeep = 0;
rightRangeBinDiscard = 1;
log_plot = 1;
STATIC_ONLY = 0;
angleFFTSize = 256;
ratio = 0.5;
DopplerCorrection = 0;
d = 1;

% 1D CA-CFAR parameter
window_sz = 33;          % total window size
scale_factor_1D = 2.95;  % threshold scale factor
no_tcell = 24;           % # of training window
no_gcell = 8;            % # of guard window

% CAOS_CFAR_2D parameter
sz_r = 128;              % row size
sz_c = 256;              % column size
Nt = 24;                 % # of training window 
Ng = 8;                  % # of guard window
scale_factor_2D = 1.25;  % threshold scale factor

% FindPeakValue parameter
minPeakHeight = 10;
peak_th = 0.4;

% k-means Clustering parameter
k = 4;

% microdoppler parameter
RangeBinIdx = 30;

%% Reshape Data
[frameComplex] = ReshapeData(NChirp, NChan, NSample, frame_number, adcRawData);

%% Time domain output
[currChDataQ, currChDataI, t] = TimeDomainOutput(NSample, sampling_time, chirpsIdx, chanIdx, frameComplex);

% plot time domain
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
plot(t,currChDataI(:),t,currChDataQ(:))
xlabel('time (seconds)');                  
ylabel('ADC time domain output');        
title('Time Domain Output');
grid on;

%% FFT Range Profile
[rangeProfileData, radarCubeData_demo, channelData, rangeBin] = RangeFFT(NChirp, NChan, NSample, ...
    chirpsIdx, chanIdx, numrangeBins, range_resolution, frameComplex);

% MTI filter
[radarCubeData_mti, rangeProfileData_mti, channelData_mti] = MTI_filter(NChirp, NChan, NSample, ...
    chirpsIdx, chanIdx, radarCubeData_demo);

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

%% Range Doppler FFT
[max_row, max_col, maxValue, velocityAxis, doppler, doppler_mti, db_doppler] = RangeDopplerFFT(NChirp, NChan, NSample, ...
    chanIdx, max_vel, velocity_resolution, MTIfiltering, radarCubeData_demo, radarCubeData_mti);

% plot Range Doppler Map
nexttile;
imagesc(velocityAxis,rangeBin,db_doppler);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
if MTIfiltering
    title('Range-Doppler Map (MTI)');
else
    title('Range-Doppler Map (not MTI)');
end
colorbar;
axis xy

%% Range Azimuth FFT
[y_axis, x_axis, mag_data_static, mag_data_dynamic] = RangeAzimuthFFT(range_resolution, ...
    d, minRangeBinKeep, rightRangeBinDiscard, angleFFTSize, doppler);

% plot Range Azimuth FFT
    if STATIC_ONLY == 1
        if log_plot
            nexttile;
            surf(y_axis, x_axis, (mag_data_static).^0.4,'EdgeColor','none');
        else
            nexttile;
            surf(y_axis, x_axis, abs(mag_data_static),'EdgeColor','none');
        end
    else
        if log_plot
            nexttile;
            surf(y_axis, x_axis, (mag_data_dynamic).^0.4,'EdgeColor','none');
        else
            nexttile;
            surf(y_axis, x_axis, abs(mag_data_dynamic),'EdgeColor','none');
        end
    end
    
    view(2);
    colorbar;
    title('Range Azimuth');
    xlabel('meters');
    ylabel('meters');

%% Find Target
[peak_locs, peaks, target_Idx, target] = FindTarget(minPeakHeight, peak_th, channelData_mti);

% plot peaks and targets
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
plot(rangeBin, channelData_mti); 
hold on;
plot(rangeBin(peak_locs), peaks, 'ro');
hold on;
title('Find Target');
xlabel('Range (m)');
ylabel('Power (dB)');
% rangeBin 중에서 peak 중에서 target의 Index
plot(rangeBin(peak_locs(target_Idx)),target,'go','Markersize',8);

variance = var(channelData_mti);

%% 1D CA-CFAR
[detected_points_1D, cfarData_mti, th] = CA_CFAR_1D(window_sz, scale_factor_1D, no_tcell, no_gcell, rangeProfileData_mti);

% Range FFT data plot
nexttile;
plot(rangeBin, cfarData_mti, 'LineWidth', 0.5);
hold on;

% Threshold plot
plot(rangeBin, th, 'r', 'LineWidth', 0.5);
legend('Range Profile', 'CFAR threshold');
hold on;

% detected points plot
plot(rangeBin(detected_points_1D), (cfarData_mti(detected_points_1D)),'ro','MarkerSize', 8);
legend('Range Profile', 'CFAR Threshold', 'Detected Points');
xlabel('Range (m)');
ylabel('power (dB)');
title('CFAR Detection');

%% 2D CA-OS CFAR
[detected_points_2D] = CAOS_CFAR_2D(sz_r, sz_c, Nt, Ng, scale_factor_2D, db_doppler);

% plot 2D CAOS-CFAR
nexttile;
imagesc(velocityAxis,rangeBin,detected_points_2D);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('2D CFAR Target Detect');
colorbar;
axis xy

%% Clustering
[detected_points_clustering] = Clustering(NSample,NChirp, k, detected_points_2D);

% Plot Clustering
nexttile;
imagesc(velocityAxis,rangeBin,detected_points_clustering);
hold on;
xlabel('Velocity (m/s)');
ylabel('Range (m)');
title('Data Clustering');
axis xy
colorbar;
hold off;

%% Micro doppler
[time_axis,micro_doppler] = microdoppler(NChirp, NChan, Nframe, RangeBinIdx, radarCube);

% power of microdoppler
sdb = squeeze(10*log10((abs(micro_doppler(:,chanIdx,:)))));

% plot
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
imagesc(time_axis,velocityAxis,sdb);
xlabel('times (s)');
ylabel('Velocity (m/s)');
title('Micro Doppler');
colorbar;
axis xy

%% 2D MTI filter
% MTI_filter_2D에 만들어 놓음