clear;
clc;
close all;

load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");

objectNum = 2;
frame_number = 52;

% parameters
chirpsIdx = 1;
chanIdx = 1;
numrangeBins = 256;
NChirp = 128;
NChan = 4;
NSample = 256;
Nframe = 256; % 프레임 수
pri = 76.51e-6; % ramp end tiem + idle time
prf = 1 / pri;
start_frequency = 77e9; % 시작 주파수 (Hz)
slope = 32.7337; % 슬로프 (MHz/s)
samples_per_chirp = 256; % 하나의 칩에서의 샘플 수
chirps_per_frame = 128; % 프레임 당 chirps 수
sampling_rate = 5e9; % 샘플링 속도 (Hz)
% 대역폭 = sampling time*frequency slope (sampling time = samples / sample rate)
bandwidth = 1.6760e9; % 대역폭 (Hz)
% 거리 해상도 = c/(2*bandwidth)
range_resolution = 0.0894; % 거리 해상도 (m)
% 속도 해상도 = wavelength/(2*pri*Nchirp)
velocity_resolution = 0.1991; % 속도 해상도 (m/s)
sampling_time = NSample / sampling_rate; % 샘플링 타임 (s)
c = 3e8; % 빛의 속도 (미터/초)
wavelength = c / start_frequency; % 파장(lambda)
max_vel = wavelength / (4 * pri); % 최대 속도
max_range = sampling_rate * c / (2 * slope); % 최대 거리

% 전체 걸린 시간 frame periodicity : 40ms -> 40ms*256 = 10.24s

%% Time domain output

% adcRawData -> adc_raw_data1
adc_raw_data1 = adcRawData.data{frame_number};

% adc_raw_data1->uint type 이기때문에 double type으로 바꿔줘야 연산 가능
adc_raw_data = cast(adc_raw_data1, "double");

% unsigned => signed
signed_adc_raw_data = adc_raw_data - 65536 * (adc_raw_data > 32767);

% IIQQ data
re_adc_raw_data4 = reshape(signed_adc_raw_data, [4, length(signed_adc_raw_data) / 4]);
rawDataI = reshape(re_adc_raw_data4(1:2, :), [], 1);
rawDataQ = reshape(re_adc_raw_data4(3:4, :), [], 1);

frameData = [rawDataI, rawDataQ];
frameCplx = frameData(:, 1) + 1i * frameData(:, 2);
frameComplex = single(zeros(NChirp, NChan, NSample));

% IIQQ->IQ smaple->channel->chirp
temp = reshape(frameCplx, [NSample * NChan, NChirp]).';
for chirp = 1:NChirp
    frameComplex(chirp, :, :) = reshape(temp(chirp, :), [NSample, NChan]).';
end
rawFrameData = frameComplex;

currChDataQ = real(rawFrameData(chirpsIdx, chanIdx, :));
currChDataI = imag(rawFrameData(chirpsIdx, chanIdx, :));

% t=linspace(0,NSample-1,NSample);
t = linspace(0, sampling_time, NSample);

%% FFT Range Profile
% Range FFT
% pre allocation
radarCubeData_demo = zeros(128, 4, 256);
% for chirpIdx = 1:128
%     for chIdx = 1:4
%         win = rectwin(256);
%         frameData1(1, :) = frameComplex(chirpIdx, chIdx, :);
%         frameData2 = fft(frameData1 .* win', 256);
%         radarCubeData_demo(chirpIdx, chIdx, :) = frameData2(1, :);
%     end
% end

 for chirpIdx = 1:128
        win = rectwin(256);
        frameData1(1, :) = frameComplex(chirpIdx, 1, :);
        frameData2 = fft(frameData1 .* win', 256);
        radarCubeData_demo(chirpIdx, 1, :) = frameData2(1, :);

        win = rectwin(256);
        frameData1(1, :) = frameComplex(chirpIdx, 2, :);
        frameData2 = fft(frameData1 .* win', 256);
        radarCubeData_demo(chirpIdx, 2, :) = frameData2(1, :);

        win = rectwin(256);
        frameData1(1, :) = frameComplex(chirpIdx, 3, :);
        frameData2 = fft(frameData1 .* win', 256);
        radarCubeData_demo(chirpIdx, 3, :) = frameData2(1, :);

        win = rectwin(256);
        frameData1(1, :) = frameComplex(chirpIdx, 4, :);
        frameData2 = fft(frameData1 .* win', 256);
        radarCubeData_demo(chirpIdx, 4, :) = frameData2(1, :);

end

rangeProfileData = radarCubeData_demo(chirpsIdx, chanIdx, :);

% linear mode
channelData = abs(rangeProfileData(:));

% Range
rangeBin = linspace(0, numrangeBins * range_resolution, numrangeBins);

%% Doppler FFT

% MTI filter - range FFT 된 data에 대해
% single delay line canceller
% range에 대해 fft된 data를 chirp끼리 비교
radarCubeData_mti = zeros(128, 4, 256);
radarCubeData_mti(1, :, :) = radarCubeData_demo(1, :, :);
for chirpidx = 1:127
    radarCubeData_mti(chirpidx + 1, :, :) = radarCubeData_demo(chirpidx, :, :) - radarCubeData_demo(chirpidx + 1, :, :);
end

% double delay line canceller
radarCubeData_mti2 = zeros(128, 4, 256);
radarCubeData_mti2(1, :, :) = radarCubeData_mti(1, :, :);
for chirpidx = 1:127
    radarCubeData_mti2(chirpidx + 1, :, :) = radarCubeData_mti(chirpidx, :, :) - radarCubeData_mti(chirpidx + 1, :, :);
end

% MTI filter range profile plot
rangeProfileData_mti = radarCubeData_mti(chirpsIdx, chanIdx, :);
channelData_mti = abs(rangeProfileData_mti(:));

rangeplot = plot(rangeBin, channelData_mti);
xlabel('Range (m)');
ylabel('Range FFT output (dB)');
title('Range Profile (MTI)');
grid on;

% %% LMS
% filterLength = 32; % Length of the filter
% stepSize = 0.1; % Step size or learning rate
% 
% % Desired Output (You can adjust this based on your specific requirements)
% desiredOutput = zeros(size(channelData_mti));
% 
% % LMS Filter Initialization
% weights = zeros(filterLength, 1);
% 
% % Apply LMS Filter
% filteredOutput = zeros(size(channelData_mti));
% for n = filterLength:numel(channelData_mti)
%     x = channelData_mti(n:-1:n-filterLength+1);
%     filteredOutput(n) = weights' * x;
%     error = desiredOutput(n) - filteredOutput(n);
%     weights = weights + stepSize * error * x;
% end
% 
% % Plot the original channelData_mti and the filtered output
% figure;
% plot(rangeBin, channelData_mti, 'b', 'LineWidth', 1.5);
% hold on;
% plot(rangeBin, filteredOutput, 'r', 'LineWidth', 1.5);
% xlabel('Range (m)');
% ylabel('Amplitude');
% title('Original and Filtered Output using LMS Filter');
% legend('Original', 'Filtered');
% grid on;
% hold off;

% 고주파 제거를 위한 FFT
N = length(channelData_mti);
Y = fft(channelData_mti); % FFT 수행

% 고주파 제거
cut_off_freq = 50; % 고주파를 제거하기 위한 주파수 컷오프
Y(cut_off_freq+1:N-cut_off_freq) = 0; % 컷오프 주파수를 기준으로 고주파 부분을 제거

% 역 FFT 수행하여 시간 영역으로 돌아감
channelData_mti_filtered = ifft(Y);

% Range Profile 플롯
hold on;

freqcuttoffplot = plot(rangeBin, abs(channelData_mti_filtered), 'r', 'LineWidth', 1);

minPeakHeight = 10;
[peaks, peak_locs] = findpeaks(abs(channelData_mti_filtered), 'MinPeakHeight', minPeakHeight);
peakplot = plot(rangeBin(peak_locs), peaks, 'ro');

subtitle('high freq removed')
%legend('Range Profile', 'high freq removed');
legend('Range Profile', 'high freq removed', 'peak');
hold off;
