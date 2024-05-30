% Range Time Map
function [doppler_time] = DopplerTimeMap(NChirp, NChan, Nframe, RangeBinIdx, doppler_mti_cell)

% pre allocation
doppler_time = zeros(NChirp,NChan,Nframe);

% time axis
% max_time = pri * NChan * NChirp * Nframe;  %frame period = 39.17ms
% max_time = 0.04 * Nframe;  %frame period = 40ms
% time_axis = linspace(0,max_time,Nframe);

% 속도를 VelocityBinIdx로 설정하고 3d data (frames, channels, range)로 생성
% range FFT 된 데이터를 :를 통해 frame에 대해 accumulation해야 함
for frames = 1:Nframe
doppler_time(:,:,frames) = squeeze(doppler_mti_cell{frames}(:,:,RangeBinIdx));
end

