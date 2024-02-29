clear;
clc;
close all;
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");

%parameters
objectNum = 2;

chirpsIdx=1;
chanIdx=1;
frame_number=128;

numrangeBins=256;
NChirp=128;
NChan=4;
NSample=256;
Nframe = 256;                        % 프레임 수
pri=76.51e-6;                        %ramp end tiem + idle time
prf=1/pri;
start_frequency = 77e9;              % 시작 주파수 (Hz)
slope = 32.7337;                     % 슬로프 (MHz/s)
samples_per_chirp = 256;             % 하나의 칩에서의 샘플 수
chirps_per_frame = 128;              % 프레임 당 chirps 수
sampling_rate = 5e9;                 % 샘플링 속도 (Hz)
% 대역폭 = sampling time*frequency slope (sampling time = samples / sample rate)
bandwidth = 1.6760e9;                % 대역폭 (Hz)
%거리 해상도 = c/(2*bandwidth)
range_resolution = 0.0894;           % 거리 해상도 (m)
%속도 해상도 = wavelength/(2*pri*Nchirp)
velocity_resolution = 0.1991;        % 속도 해상도 (m/s)
sampling_time = NSample/sampling_rate; % 샘플링 타임 (s)
c = 3e8;                             % 빛의 속도 (미터/초)
wavelength = c / start_frequency;    % 파장(lambda)
max_vel = wavelength/(4*pri);        % 최대 속도
max_range = sampling_rate*c/(2*slope); %최대 거리

% 전체 걸린 시간 frame periodicity : 40ms -> 40ms*256 = 10.24s

%% Time domain output

% adcRawData -> adc_raw_data1
adc_raw_data1 = adcRawData.data{frame_number};

% adc_raw_data1->uint type 이기때문에 double type으로 바꿔줘야 연산 가능
adc_raw_data = cast(adc_raw_data1,"double");

% unsigned => signed
signed_adc_raw_data = adc_raw_data - 65536 * (adc_raw_data > 32767);

%IIQQ data 
re_adc_raw_data4=reshape(signed_adc_raw_data,[4,length(signed_adc_raw_data)/4]);
rawDataI = reshape(re_adc_raw_data4(1:2,:), [], 1);
rawDataQ = reshape(re_adc_raw_data4(3:4,:), [], 1);

frameData = [rawDataI, rawDataQ];
frameCplx = frameData(:,1) + 1i*frameData(:,2);
frameComplex = single(zeros(NChirp, NChan, NSample));

% IIQQ->IQ smaple->channel->chirp
temp = reshape(frameCplx, [NSample * NChan, NChirp]).';
for chirp=1:NChirp                            
    frameComplex(chirp,:,:) = reshape(temp(chirp,:), [NSample, NChan]).';
end 
rawFrameData = frameComplex;

currChDataQ = real(rawFrameData(chirpsIdx,chanIdx,:));
currChDataI = imag(rawFrameData(chirpsIdx,chanIdx,:));

% t=linspace(0,NSample-1,NSample);
t=linspace(0,sampling_time,NSample);

figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);


%% FFT Range Profile
% Range FFT
% pre allocation
radarCubeData_demo = zeros(128,4,256);
for chirpIdx = 1:128
    for chIdx = 1:4
        win = rectwin(256);
        frameData1(1,:) = frameComplex(chirpIdx, chIdx, :);
        frameData2 = fft(frameData1 .* win', 256);
        radarCubeData_demo(chirpIdx, chIdx, :) = frameData2(1,:);
    end
end
rangeProfileData = radarCubeData_demo(chirpsIdx, chanIdx , :);

% linear mode
channelData = abs(rangeProfileData(:));

%Range
%rangeBin = linspace(0, Params.numRangeBins * Params.RFParams.rangeResolutionsInMeters, Params.numRangeBins);
rangeBin = linspace(0,numrangeBins *range_resolution, numrangeBins);

% % not MTI filter range profile plot
% nexttile;
% plot(rangeBin,channelData)
% xlabel('Range (m)');                  
% ylabel('Range FFT output (dB)');        
% title('Range Profile (not MTI)');
% grid on;

%% Doppler FFT

%-----------------------------------------------------------------------------------------------------------
% MTI filter - range FFT 된 data에 대해
% single delay line canceller
% range에 대해 fft된 data를 chirp끼리 비교
radarCubeData_mti = zeros(128,4,256);
radarCubeData_mti(1,:,:) = radarCubeData_demo(1,:,:);
for chirpidx = 1:127
radarCubeData_mti(chirpidx+1,:,:) = radarCubeData_demo(chirpidx,:,:)-radarCubeData_demo(chirpidx+1,:,:);
end
% double delay line canceller
radarCubeData_mti2 = zeros(128,4,256);
radarCubeData_mti2(1,:,:) = radarCubeData_mti(1,:,:);
for chirpidx = 1:127
radarCubeData_mti2(chirpidx+1,:,:) = radarCubeData_mti(chirpidx,:,:)-radarCubeData_mti(chirpidx+1,:,:);
end

% MTI filter range profile plot
rangeProfileData_mti = radarCubeData_mti(chirpsIdx, chanIdx , :);
channelData_mti = abs(rangeProfileData_mti(:));
nexttile;
plot(rangeBin,channelData_mti)
xlabel('Range (m)');                  
ylabel('Range FFT output (dB)');        
title('Range Profile (MTI)');
grid on;
hold on;



%% Range Profile Peak
minPeakHeight = 10;

two_d_input = zeros(128, 4, 256); % Peak를 저장할 배열 초기화

% for chirpIdx = 1:128
%     for chIdx = 1:4
%         fft_result = squeeze(abs(radarCubeData_mti(chirpIdx, chIdx, :))); % MTI 결과에서 절대값 취함
%         [peaks, peak_locs] = findpeaks(fft_result, 'MinPeakHeight', minPeakHeight); % Peak를 찾음
% 
%         % Peak를 찾아서 저장
%         two_d_input(chirpIdx, chIdx, peak_locs) = peaks;
%     end
% end

fft_result = squeeze(abs(radarCubeData_mti(chirpsIdx, chanIdx, :))); % MTI 결과에서 절대값 취함
[peaks, peak_locs] = findpeaks(fft_result, 'MinPeakHeight', minPeakHeight); % Peak를 찾음

plot(rangeBin(peak_locs), peaks, 'ro');


Th_peak = 0.5;

%while true
    peakCnt = 0;
    stemRange = zeros(size(rangeBin));

    for i = 1:length(peaks)-1
        if peaks(i) > peaks(i+1)
            lower = peaks(i+1);
            higher = peaks(i);
            locs = peak_locs(i);
        else
            lower = peaks(i);
            higher = peaks(i+1);
            locs = peak_locs(i+1);
        end
    
        ratio = abs(lower) / abs(higher);
        if ratio < Th_peak
            tgPeak = higher;
            %plot(rangeAxis(axis), tgPeak, 'go');
            peakCnt = peakCnt+1;
            stemRange(locs) = tgPeak;            
        end
    end
    % 
    % if peakCnt == objectNum
    %     break;
    % end
    % 
    % Th_peak = Th_peak - 0.01;
%end

for i = 1:length(stemRange)
    if stemRange(i) ~= 0
        plot(rangeBin(i), stemRange(i), 'go', 'MarkerSize', 10);
    end
end

% 여기서 green 점 을 

%% peak Doppler FFT
doppler = zeros(128, 4, 256); % Doppler FFT 결과를 저장할 배열 초기화

for rangebin_size = 1:256
    for chIdx = 1:4
        win_dop = hann(128);
        DopData1 = squeeze(two_d_input(:, chIdx, rangebin_size)); % Peak를 포함한 데이터 추출
        DopData = fftshift(fft(DopData1 .* win_dop, 128)); % FFT 수행
        doppler(:, chIdx, rangebin_size) = DopData; % 결과 저장
    end
end

%% Range Doppler map
doppler1 =  doppler(:, chanIdx, :); % 선택한 채널의 데이터 가져오기
doppler1_128x256 = squeeze(doppler1); % 필요한 차원 축소
db_doppler = 10*log10(abs(doppler1_128x256')); % dB로 변환

% 가장 큰 값의 인덱스 찾기
[maxValue, linearIndex] = max(db_doppler(:));
[max_row, max_col] = ind2sub(size(db_doppler), linearIndex);

%% Range Doppler map 플롯
velocityAxis = -max_vel:velocity_resolution:max_vel;

nexttile;
imagesc(velocityAxis, rangeBin, db_doppler);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('Range-Doppler Map');
colorbar;
axis xy;


%% Doppler FFT

N=length(adc_raw_data);
win_dop = hann(128);

for rangebin_size = 1:256
    for chIdx = 1:4
        win_dop = hann(128);
        DopData1 = squeeze(radarCubeData_mti(:, chIdx, rangebin_size));
        DopData = fftshift(fft(DopData1 .* win_dop, 128));
        doppler(:, chIdx, rangebin_size) = DopData;
    end
end      
%여기서 채널idx바꿀 수 있음.
doppler1 =  doppler(:,chanIdx,:);
data_128x256 = squeeze(doppler1);
dwdwdww=10*log10(abs(data_128x256'));

%가장 큰 값의 인덱스
[maxValue, linearIndex] = max(dwdwdww(:));
[max_row, max_col] = ind2sub(size(dwdwdww), linearIndex);

%% Range Doppler map

% 속도,range 계산
velocityAxis = -max_vel:velocity_resolution:max_vel;
rangeBin1 = linspace(0,numrangeBins *range_resolution, numrangeBins*NChan);

nexttile;
imagesc(velocityAxis,rangeBin,dwdwdww);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('Range-Doppler Map');
colorbar;
axis xy