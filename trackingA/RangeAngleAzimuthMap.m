clear; clc; %close all;
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_adc_raw_data.mat");
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_radarCube.mat");

%% parameters

% Number of Frame
NoFrameStart = 10;
NoFrameEnd = 128;

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
detected_cart_points(:,:) = zeros(NSample+1, NSample);
HistoryCartMap = zeros(Nframe, 2);
detected_points(:,:) = zeros(NSample+1, NSample);
HistoryMap = zeros(Nframe, 2);
cnt = 1;

figure; 

for frame_n = NoFrameStart:1:NoFrameEnd-1
    tiledlayout(2, 2);
    
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
    
    %% range angle map
    cart_data_dynamic = flipud((flipud(mag_data_dynamic))');
    
    [detected_cart_points_each] = CFAR(frame_n, numrangeBins, rangeProfileData_mti, cart_data_dynamic);
    
    if isempty(detected_cart_points_each)
        clusterCartGrid = zeros(size(x_axis));
        R = 0; % or any other default value
        C = 0; % or any other default value
    else
        [clusterCartGrid, R, C] = DBSCAN(y_axis, x_axis, detected_cart_points_each);
    end
    

    if (length(clusterCartGrid(1,:))==257)
        mat(:,:) = clusterCartGrid(:,1:256);
    else
        disp('pass')
        mat = 0;
    end
    
    HistoryCartMap(frame_n, 1) = R;
    HistoryCartMap(frame_n, 2) = C;
    detected_cart_points(:,:,cnt) = mat;


    %x_axis_cart = -abs(max(rangeBin)):abs(max(rangeBin));
    x_axis_cart = -90.00 : 90.00;
    yaxiscart = 0:abs(max(rangeBin)); 
    y_axis_cart = flipud(yaxiscart');
    nexttile;
    imagesc(x_axis_cart, y_axis_cart, cart_data_dynamic);
    set(gca, 'YDir', 'normal');
    title('Range Angle'); xlabel('angle(degres)'); ylabel('meters(m)');

    nexttile;
    imagesc(x_axis_cart,y_axis_cart,detected_cart_points_each);
    xlabel('Velocity (m/s)');
    ylabel('Range (m)');
    yticks(0:2:max(rangeBin));
    title('Range Angle CFAR');xlabel('angle(degres)'); ylabel('meters(m)');
    colorbar;
    axis xy

    %% range azimuth map 

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

    nexttile;
    surf(y_axis, x_axis, abs(detected_points_each),'EdgeColor','none');
    view(2);
    colorbar;
    title('Range Azimuth');
    xlabel('meters');
    ylabel('meters');

    drawnow;
end

%% PlotAzimuthData(velocityAxis, rangeBin, cnt, clusterGrid, HistoryMap);