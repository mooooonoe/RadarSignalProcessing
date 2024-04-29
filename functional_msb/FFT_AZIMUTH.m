%% Range Azimuth FFT
function [y_axis, x_axis, mag_data_static, mag_data_dynamic] = FFT_AZIMUTH(range_resolution, ...
    d, minRangeBinKeep, rightRangeBinDiscard, angleFFTSize, doppler)

% matlab example - plot_range_azimuth_2D


radar_data_pre_3dfft = permute(doppler,[3,1,2]);
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
