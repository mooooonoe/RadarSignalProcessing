clear;
clc;
close all;
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");

%parameters
chirpsIdx=1;
chanIdx=1;
frame_number=30;

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
channelData = abs(rangeProfileData(:));
rangeBin = linspace(0,numrangeBins *range_resolution, numrangeBins);


% %% Doppler FFT
% radarCubeData_mti = zeros(128,4,256);
% radarCubeData_mti(1,:,:) = radarCubeData_demo(1,:,:);
% for chirpidx = 1:127
% radarCubeData_mti(chirpidx+1,:,:) = radarCubeData_demo(chirpidx,:,:)-radarCubeData_demo(chirpidx+1,:,:);
% end
% % double delay line canceller
% radarCubeData_mti2 = zeros(128,4,256);
% radarCubeData_mti2(1,:,:) = radarCubeData_mti(1,:,:);
% for chirpidx = 1:127
% radarCubeData_mti2(chirpidx+1,:,:) = radarCubeData_mti(chirpidx,:,:)-radarCubeData_mti(chirpidx+1,:,:);
% end
% 
% % MTI filter range profile plot
rangeProfileData_mti = radarCubeData_demo(chirpsIdx, chanIdx , :);
channelData_mti = abs(rangeProfileData_mti(:));
N=length(adc_raw_data);
win_dop = hann(128);

doppler = zeros(128,4,256);
for rangebin_size = 1:256
    for chIdx = 1:4
        win_dop = hann(128);
        DopData1 = squeeze(radarCubeData_demo(:, chIdx, rangebin_size)); %여기 radarCubeData_mti->radarCubeData_demo
        DopData = fftshift(fft(DopData1 .* win_dop, 128));
        doppler(:, chIdx, rangebin_size) = DopData;
    end
end      
%여기서 채널idx바꿀 수 있음.
doppler1 =  doppler(:,chanIdx,:);
doppler1_128x256 = squeeze(doppler1);
db_doppler = 10*log10(abs(doppler1_128x256'));

%가장 큰 값의 인덱스
[maxValue, linearIndex] = max(db_doppler(:));
[max_row, max_col] = ind2sub(size(db_doppler), linearIndex);

%% Range Doppler map
velocityAxis = -max_vel:velocity_resolution:max_vel;

figure('Position', [30, 10, 600, 300]);
tiledlayout(1,3);
nexttile;
imagesc(velocityAxis,rangeBin,db_doppler);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('Range-Doppler Map');
colorbar;
axis xy

%% CFAR input
sz_c = size(db_doppler,1);
sz_r = size(db_doppler,2);

for i = 1:sz_c
    for j = 1:sz_r
        input(i , j) = db_doppler(i, j);
    end
end
 
%% CA CFAR PARAMETER
input_sz = size(input);

Nt = 32;
Ng = 4;
window_sz= Ng + Nt + 1 ;
window = zeros(window_sz);
th = zeros(input_sz);
factor = 2;
beta = 0.1;

%% 2D CA-OS CFAR Algorithm

for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
        cut = input(cutCIdx, cutRIdx);
        arr = zeros(1, window_sz);
        %cnt_OS = 1;
        for windowCIdx = 1:window_sz
            for i = (Nt/2):-1:1
                if (windowCIdx-i > 0)
                    arr(1, windowCIdx-i) = input(windowCIdx-i,cutRIdx);
                    %cnt_OS = cnt_OS+1;
                end
            end
            for j = 1:(Nt/2)
                if ((windowCIdx+Ng+j) <= 256)
                    arr(1, windowCIdx+Ng+j) = input(windowCIdx+Ng+j,cutRIdx);
                    %cnt_OS = cnt_OS+1;
                end
            end
            sorted_arr = sort(arr);
            size_arr = size(sorted_arr);
            id = ceil(3*(size_arr(2))/4);
            value_OS = sorted_arr(id)*1.35;
        end

        for windowRIdx = 1:window_sz
            sum = 0;
            cnt_CA = 0;
            for i = (Nt/2):-1:1
                if (cutRIdx-i > 0)
                    sum = sum + input(cutCIdx, cutRIdx-i);
                    cnt_CA = cnt_CA+1;
                end
            end
            for j = 1:(Nt/2)
                if ((cutRIdx+Ng+j) <= 128)
                sum = sum + input(cutCIdx, cutRIdx+Ng+j);
                cnt_CA = cnt_CA+1;
                end

            end
            mean = sum/cnt_CA;
            value_CA = mean*1.0;

        end

        if value_CA > value_OS
            th(cutCIdx, cutRIdx) = value_CA;
        else
            th(cutCIdx, cutRIdx) = value_OS;
        end
    end 
end

%% detect
detected_points = zeros(input_sz);

for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
        cut = input(cutCIdx, cutRIdx);
        compare = th(cutCIdx, cutRIdx);
        if(cut > compare)
            detected_points(cutCIdx, cutRIdx) = cut;
        end
        if(cut <= compare)
            detected_points(cutCIdx, cutRIdx) = 0;
        end
    end
end

nexttile;
imagesc(velocityAxis,rangeBin,detected_points);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('2D CFAR Target Detect');
colorbar;
axis xy

nexttile;
surf(velocityAxis,rangeBin,detected_points);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('2D CFAR Target Detect');
colorbar;
axis xy
 