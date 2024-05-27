%% Range Azimuth FFT
function [y_axis, x_axis, angleBin, angleFFT_output, angleFFT_output_mti, ram_output, ram_output_mti, mag_data, mag_data_mti] = RangeAzimuthFFT(range_resolution, ...
    d, minRangeBinKeep, rightRangeBinDiscard, angleFFTSize, frame_number, doppler_cell, doppler_mti_cell)

% matlab example - plot_range_azimuth_2D

% 3d cube data를 Range, Doppler, channel순으로 permute (not MTI, MTI)
radar_data_pre_3dfft = permute(doppler_cell{frame_number},[3,1,2]);
radar_data_pre_3dfft_mti = permute(doppler_mti_cell{frame_number},[3,1,2]);

dopplerFFTSize = size(radar_data_pre_3dfft,2);
rangeFFTSize = size(radar_data_pre_3dfft,1);

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


% fft(X,n,dim)은 차원 dim을 따라 푸리에 변환을 반환
% 각각 행, 열에 대해 fft한 데이터를 세번째 차원에 반복해서 저장
% 똑같은 256x128 데이터가 256개 생김
% Azimuth FFT (not MTI, MTI)
radar_data_angle_range = fft(radar_data_pre_3dfft, angleFFTSize, 3);
radar_data_angle_range_mti = fft(radar_data_pre_3dfft_mti, angleFFTSize, 3);
n_angle_fft_size = size(radar_data_angle_range,3);
n_range_fft_size = size(radar_data_angle_range,1);

%% RAM plot을 위한 데이터
radar_data_angle_range_mti_shift = fftshift(fftshift(radar_data_angle_range_mti),1);
radar_data_angle_range_shift = fftshift(fftshift(radar_data_angle_range),1);

% angleBin 구하기
w = linspace(-1,1,256); % angle_grid
angleBin = asin(w)*180/pi; % [-1,1]->[-pi/2,pi/2]

%% RAM -> Cartesian Plane
% dynamic range-azimuth heatmap을 구하기 위해
% 데이터의 평균 power를 구하고 뺀값을 비교하며 구분
DopplerPower = sum(mean((abs(radar_data_pre_3dfft(:,:,:))),3),1);
% 여기선 64,65,66이 DC가 존재하는 구간으로 생각
DopplerPower_noDC = DopplerPower([1: dopplerFFTSize/2-1 dopplerFFTSize/2+3:end]);
[peakVal,peakInd] = max(DopplerPower_noDC);
threshold = peakVal*ratio;
indSel = find(DopplerPower_noDC >threshold);
for ii = 1:length(indSel)
    if indSel(ii) > dopplerFFTSize/2-1
        indSel(ii) = indSel(ii) + 3;
    end
end
% dynamic과 static 데이터 구분
% 여기서 각 Doppler 차원을 따라 데이터의 합을 진행 256x256데이터로 바뀜
radar_data_angle_range_dynamic = squeeze(sum(abs(radar_data_angle_range(:,indSel,:)),2));
radar_data_angle_range_Static = squeeze(sum(abs(radar_data_angle_range(:,dopplerFFTSize/2+1,:)),2));

indices_1D = (minRangeBinKeep:n_range_fft_size-rightRangeBinDiscard);

% generate range/angleFFT for zeroDoppler and non-zero Doppler respectively
radar_data_angle_range_dynamic = fftshift(radar_data_angle_range_dynamic,2);
radar_data_angle_range_Static = fftshift(radar_data_angle_range_Static,2);

% 반원 형태로 나타내야 하기 때문에 x축과 y축의 idx가 sinusoidal 해야한다.
sine_theta = -2*((-n_angle_fft_size/2:n_angle_fft_size/2)/n_angle_fft_size)/d;
cos_theta = sqrt(1-sine_theta.^2);

[R_mat, sine_theta_mat] = meshgrid(indices_1D*range_resolution,sine_theta);
[~, cos_theta_mat] = meshgrid(indices_1D,cos_theta);

x_axis = R_mat.*cos_theta_mat;
y_axis = R_mat.*sine_theta_mat;

% plot하기 위해 각 데이터의 크기를 구한다.
% [1:end 1]은 인덱스가 1에서부터 끝까지인 범위에 1을 추가 -> 배열의 마지막 요소를 처음에 추가
% 따라서 처음 데이터와 마지막 데이터가 같음.
mag_data_dynamic = squeeze(abs(radar_data_angle_range_dynamic(indices_1D+1,[1:end 1])));
mag_data_static = squeeze(abs(radar_data_angle_range_Static(indices_1D+1,[1:end 1])));

% transpose를 통해 x축과 y축 조정
mag_data_dynamic = mag_data_dynamic';
mag_data_static = mag_data_static';
mag_data_dynamic = flipud(mag_data_dynamic);
mag_data_static = flipud(mag_data_static);

% MTIfiltering에 따라 다른 값 출력
% MTI
    mag_data_mti = mag_data_dynamic;
    ram_output_mti = squeeze(sum(abs(radar_data_angle_range_mti_shift(:,:,:)),2));
    angleFFT_output_mti = radar_data_angle_range_mti;
% not MTI
    mag_data = mag_data_static;
    ram_output = squeeze(sum(abs(radar_data_angle_range_shift(:,:,:)),2));
    angleFFT_output = radar_data_angle_range;
