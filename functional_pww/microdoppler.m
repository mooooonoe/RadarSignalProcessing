%% Micro doppler
function [time_axis,micro_doppler] = microdoppler(NChirp, NChan, Nframe, RangeBinIdx, radarCube)

% pre allocation
micro_doppler = zeros(NChirp,NChan,Nframe);
frame_data = zeros(NChirp,NChan,Nframe);

% time axis
% max_time = pri * NChan * NChirp * Nframe;  %frame period = 39.17ms
max_time = 0.04 * Nframe;  %frame period = 40ms
time_axis = linspace(0,max_time,Nframe);

% 거리를 RangeBinIdx로 설정하고 3d data (slow time, channels, frames)로 생성
for frames = 1:Nframe
frame_data(:,:,frames) = squeeze(radarCube.data{frames}(:,:,RangeBinIdx));
end

% micro_doppler = permute(micro_doppler,[3 2 1]);
for chIdx = 1:NChan
  micro_doppler(:,chIdx,:) = fftshift(fft(squeeze(frame_data(:,chIdx,:)).*hann(NChirp),NChirp),1);
end
