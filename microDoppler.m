clear;
clc;
close all;
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");

objectNum = 2;

%parameters
chirpsIdx=1;
chanIdx=1;
frame_number=90;

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
nexttile;
plot(t,currChDataI(:),t,currChDataQ(:))
xlabel('time (seconds)');                  
ylabel('ADC time domain output');        
title('Time Domain Output');
grid on;

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
%-----------------------------------------------------------------------------------------------------------

N=length(adc_raw_data);
win_dop = hann(128);
% pre allocation
doppler = zeros(128,4,256);
for rangebin_size = 1:256
    for chIdx = 1:4
        win_dop = hann(128);
        DopData1 = squeeze(radarCubeData_mti(:, chIdx, rangebin_size)); %여기 radarCubeData_mti->radarCubeData_demo
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

% 속도,range 계산
velocityAxis = -max_vel:velocity_resolution:max_vel;

nexttile;
imagesc(velocityAxis,rangeBin,db_doppler);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('Range-Doppler Map');
colorbar;
axis xy

% %2DFFT surface
% nexttile;
% surf(velocityAxis, rangeBin, db_doppler);
% xlabel('Velocity (m/s)');
% ylabel('Range (m)');
% yticks(0:1:max(rangeBin));
% title('Range-Doppler Map');
% colorbar;
% axis xy

%% Range-Angle FFT

% matlab example - plot_range_azimuth_2D
%parameter
minRangeBinKeep = 0;
rightRangeBinDiscard = 1;
log_plot = 1;
STATIC_ONLY = 0;

radar_data_pre_3dfft = permute(doppler,[3,1,2]);
dopplerFFTSize = size(radar_data_pre_3dfft,2);
rangeFFTSize = size(radar_data_pre_3dfft,1);
angleFFTSize = 256;

% ratio used to decide engergy threshold used to pick non-zero Doppler bins
ratio = 0.5;
DopplerCorrection = 0;

%-------------------------------------------------------------------------------------------
% DopplerCorrection=0해당 if문은 실행x
if DopplerCorrection == 1
    % add Doppler correction before generating the heatmap
    % pre allocation
    radar_data_pre_3dfft_DopCor= zeros(256,128,4);
    for dopplerInd = 1: dopplerFFTSize
        deltaPhi = 2*pi*(dopplerInd-1-dopplerFFTSize/2)/( TDM_MIMO_numTX*dopplerFFTSize);
        sig_bin_org =squeeze(radar_data_pre_3dfft(:,dopplerInd,:));
        for i_TX = 1:TDM_MIMO_numTX
            RX_ID = (i_TX-1)*numRxAnt+1 : i_TX*numRxAnt;
            corVec = repmat(exp(-1j*(i_TX-1)*deltaPhi), rangeFFTSize, numRxAnt);
            radar_data_pre_3dfft_DopCor(:,dopplerInd, RX_ID)= sig_bin_org(:,RX_ID ).* corVec;
        end
    end
    
    radar_data_pre_3dfft = radar_data_pre_3dfft_DopCor;
end
%--------------------------------------------------------------------------------------------

% radar_data_pre_3dfft = radar_data_pre_3dfft(:,:,chanIdx);

% fft(X,n,dim) -> X가 행렬일 경우 각 열에 대한 n 포인트 fft를 수행한 다음 dim의 차원에 저장한다.
%이렇게 되면 radar_data_angle_range랑 radar_data_pre_3dfft랑 서로 같은데?
radar_data_angle_range = fft(radar_data_pre_3dfft, angleFFTSize, 3);
n_angle_fft_size = size(radar_data_angle_range,3);
n_range_fft_size = size(radar_data_angle_range,1);


%decide non-zerp doppler bins to be used for dynamic range-azimuth heatmap
DopplerPower = sum(mean((abs(radar_data_pre_3dfft(:,:,:))),3),1);
DopplerPower_noDC = DopplerPower([1: dopplerFFTSize/2-1 dopplerFFTSize/2+3:end]);
[peakVal,peakInd] = max(DopplerPower_noDC);
threshold = peakVal*ratio;
indSel = find(DopplerPower_noDC >threshold);
for ii = 1:length(indSel)
    if indSel(ii) > dopplerFFTSize/2-1
        indSel(ii) = indSel(ii) + 3;
    end
end

radar_data_angle_range_dynamic = squeeze(sum(abs(radar_data_angle_range(:,indSel,:)),2));
radar_data_angle_range_Static = squeeze(sum(abs(radar_data_angle_range(:,dopplerFFTSize/2+1,:)),2));


indices_1D = (minRangeBinKeep:n_range_fft_size-rightRangeBinDiscard);
max_range = (n_range_fft_size-1)*range_resolution;
max_range = max_range/2;
d = 1;

%generate range/angleFFT for zeroDoppler and non-zero Doppler respectively
radar_data_angle_range_dynamic = fftshift(radar_data_angle_range_dynamic,2);
radar_data_angle_range_Static = fftshift(radar_data_angle_range_Static,2);

sine_theta = -2*((-n_angle_fft_size/2:n_angle_fft_size/2)/n_angle_fft_size)/d;
cos_theta = sqrt(1-sine_theta.^2);

[R_mat, sine_theta_mat] = meshgrid(indices_1D*range_resolution,sine_theta);
[~, cos_theta_mat] = meshgrid(indices_1D,cos_theta);

x_axis = R_mat.*cos_theta_mat;
y_axis = R_mat.*sine_theta_mat;
mag_data_dynamic = squeeze(abs(radar_data_angle_range_dynamic(indices_1D+1,[1:end 1])));
mag_data_static = squeeze(abs(radar_data_angle_range_Static(indices_1D+1,[1:end 1])));

% static + dynamic
%------------------------------------------------------------------------------
qwert = radar_data_angle_range_dynamic + radar_data_angle_range_Static;
qwert = squeeze(abs(qwert(indices_1D+1,[1:end 1])));
qwert = qwert';
qwert = flipud(qwert);
% 수정
radar_data_dynamic = squeeze(sum(abs(radar_data_angle_range(:,:,:)),2));
radar_data_dynamic = fftshift(radar_data_dynamic,2);
mag_data = squeeze(abs(radar_data_dynamic(indices_1D+1,[1:end 1])));
mag_data = mag_data';
mag_data = flipud(mag_data);
%-------------------------------------------------------------------------------

mag_data_dynamic = mag_data_dynamic';
mag_data_static = mag_data_static';
mag_data_dynamic = flipud(mag_data_dynamic);
mag_data_static = flipud(mag_data_static);

[max_val_mag, max_idx_mag] = max(mag_data_dynamic(:));
[max_row_mag, max_col_mag] = ind2sub(size(mag_data_dynamic), max_idx_mag);

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


%% 1D CA-CFAR
window_sz = 33;
% 여기서 rangeProfileData를 rangeProfileData_mti로 바꿈
cfarData_mti = squeeze(abs(rangeProfileData));
th = zeros(size(cfarData_mti));
no_tcell = 24;
no_gcell = 8;

% 첫번째 sample index부터 마지막 index까지 test
for cutIdx = 1:256
    % test할 cut를 data에서 선택
    cut = cfarData_mti(cutIdx);
    for windowIdx = 1:window_sz 
        sum = 0;
        cnt = 0;
         % 우측 training cell의 sum 구하기
        for i= (no_tcell/2):-1:1
            if(cutIdx-i >0)
                sum = sum + cfarData_mti(cutIdx-i);
                cnt = cnt+1;
            end
        end
        % 좌측 training cell의 sum 구하기
        for j=1:(no_tcell/2)
            if((cutIdx+no_gcell+j) <= 256)
                sum = sum + cfarData_mti(cutIdx+no_gcell+j);
                cnt = cnt + 1;
            end
        end
        % 좌,우측 training cell의 평균
        mean = sum/cnt;
        th(cutIdx) = (mean)*4;
    end
end



% Range FFT data plot
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
plot(rangeBin, cfarData_mti, 'LineWidth', 0.5);
hold on;
% Threshold plot
plot(rangeBin, th, 'r', 'LineWidth', 0.5);
legend('Range Profile', 'CFAR threshold');
hold on;
detected_points = find(cfarData_mti > th);
% detected points plot
plot(rangeBin(detected_points), (cfarData_mti(detected_points)),'ro','MarkerSize', 8);
legend('Range Profile', 'CFAR Threshold', 'Detected Points');
xlabel('Range');
ylabel('power');
title('CFAR Detection');



%% 2D CFAR input
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
factor = 4;
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
            value_OS = sorted_arr(id)*1.2;
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
            value_CA = mean*1.2;

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


%% Micro doppler
% pre allocation
frame_data = zeros(NChirp,NChan,Nframe);
sampleIdx = 90;

% 거리를 sampleIdx로 설정하고 3d data (slow time, channels, frames)로 생성
for frames = 1:256
frame_data(:,:,frames) = squeeze(radarCube.data{frames}(:,:,sampleIdx)); % radarCube.data/doppler3
end

% micro_doppler = permute(micro_doppler,[3 2 1]);
micro_doppler = zeros(128,4,256);
for chIdx = 1:4
  micro_doppler(:,chIdx,:) = fftshift(fft(squeeze(frame_data(:,chIdx,:)).*hann(128),128),1);
end

% time axis
% max_time = pri * NChan * NChirp * Nframe;  %frame period = 39.17ms
max_time = 0.04 * Nframe;  %frame period = 40ms
time_axis = linspace(0,max_time,Nframe);

% plot
nexttile;
sdb = squeeze(10*log10((abs(micro_doppler(:,1,:)))));
imagesc(time_axis,velocityAxis,sdb);
xlabel('times (s)');
ylabel('Velocity (m/s)');
title('Micro Doppler');
colorbar;
axis xy
