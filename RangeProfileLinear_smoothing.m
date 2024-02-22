clear;
clc;
close all;
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");

%parameters
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
figure;
plot(rangeBin,channelData_mti)
xlabel('Range (m)');                  
ylabel('Range FFT output (dB)');        
title('Range Profile (MTI)');
grid on;

%% LPC 
x = (channelData_mti); 

order = 5;
a = lpc(x, order);  
est_x = filter([0 -a(4:end)], 1, x); % LPC estimate

hold on;
plot(rangeBin, est_x, 'r', 'LineWidth', 2);
hold off;


%% Sgolay filter
windowSize = 15;
polynomialOrder = 3;
smoothed_fft_result = sgolayfilt(channelData_mti, polynomialOrder, windowSize);

hold on; 
plot(rangeBin, smoothed_fft_result, 'g', 'LineWidth', 2); 
subtitle('with smoothing');
legend('Range Profile', 'LPC estimate', 'Sgolay filtered');

