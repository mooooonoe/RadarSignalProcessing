clear;
clc;
close all;

load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");

% Parameters
chirpsIdx = 1;
chanIdx = 1;
frame_number = 100;
numrangeBins = 256;
NChirp = 128;
NChan = 4;
NSample = 256;
pri = 76.51e-6;                         % Ramp end time + idle time
prf = 1 / pri;
start_frequency = 77e9;                 % 시작 주파수 (Hz)
slope = 32.7337;                         % 슬로프 (MHz/s)
samples_per_chirp = 256;                 % 하나의 칩에서의 샘플 수
chirps_per_frame = 128;                  % 프레임 당 칩 수
sampling_rate = 5e9;                     % 샘플링 속도 (Hz)
bandwidth = 1.6760e9;                    % 대역폭 (Hz)
range_resolution = 0.0894;               % 거리 해상도 (m)
velocity_resolution = 0.1991;            % 속도 해상도 (m/s)
sampling_time = NSample / sampling_rate; % 샘플링 타임 (s)
c = 3e8;                                 % 빛의 속도 (미터/초)
wavelength = c / start_frequency;        % 파장(lambda)
max_vel = wavelength / (4 * pri);        % 최대 속도

% Time domain output
adc_raw_data1 = adcRawData.data{frame_number};
adc_raw_data = cast(adc_raw_data1, "double");
signed_adc_raw_data = adc_raw_data - 65536 * (adc_raw_data > 32767);
re_adc_raw_data4 = reshape(signed_adc_raw_data, [4, length(signed_adc_raw_data) / 4]);
rawDataI = reshape(re_adc_raw_data4(1:2, :), [], 1);
rawDataQ = reshape(re_adc_raw_data4(3:4, :), [], 1);
frameData = [rawDataI, rawDataQ];
frameCplx = frameData(:, 1) + 1i * frameData(:, 2);
frameComplex = single(zeros(NChirp, NChan, NSample));
temp = reshape(frameCplx, [NSample * NChan, NChirp]).';
for chirp = 1:NChirp
    frameComplex(chirp, :, :) = reshape(temp(chirp, :), [NSample, NChan]).';
end
rawFrameData = frameComplex;
currChDataQ = real(rawFrameData(chirpsIdx, chanIdx, :));
currChDataI = imag(rawFrameData(chirpsIdx, chanIdx, :));
t = linspace(0, sampling_time, NSample);

% Create tiled layouts
figure('Position', [300, 100, 1200, 400]);

% Tiled layout for Range Profile
tiledlayout(1, 2);
nexttile;

for chirpIdx = 1:128
    for chIdx = 1:4
        win = rectwin(256);
        frameData1(1, :) = frameComplex(chirpIdx, chIdx, :);
        frameData2 = fft(frameData1 .* win', 256);
        radarCubeData_demo(chirpIdx, chIdx, :) = frameData2(1, :);
    end
    rangeProfileData = radarCubeData_demo(chirpIdx, chanIdx, :);
    channelData = abs(rangeProfileData(:));
    rangeBin = linspace(0, numrangeBins * range_resolution, numrangeBins);
    plot(rangeBin, channelData)
    xlabel('Range (m)');
    ylabel('Range FFT output (dB)');
    title('Range Profile');
    grid on;
    drawnow;
end

% Tiled layout for Doppler FFT
tiledlayout(1, 2);
nexttile;

% Doppler FFT
N = length(adc_raw_data);
win_dop = hann(128);

for rangebin_size = 1:256
    for chIdx = 1:4
        win_dop = hann(128);
        DopData1 = squeeze(radarCubeData_demo(:, chIdx, rangebin_size));
        DopData = fftshift(fft(DopData1 .* win_dop, 128));
        doppler(:, chIdx, rangebin_size) = DopData;
    end
    
    % Range Doppler map
    doppler1 =  doppler(:,chanIdx,rangebin_size);
    data_128x256 = squeeze(doppler1);
    dwdwdww = 10*log10(abs(data_128x256'));

    % Plotting
    velocityAxis = -max_vel:velocity_resolution:max_vel;
    rangeBin1 = linspace(0, numrangeBins * range_resolution, numrangeBins * NChan);
    imagesc(velocityAxis, rangeBin1, dwdwdww);
    xlabel('Velocity (m/s)');
    ylabel('Range (m)');
    yticks(0:2:max(rangeBin1));
    title('Range-Doppler Map');
    colorbar;
    axis xy;
    drawnow;
end
