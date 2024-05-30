%% Micro doppler
function [time_axis, micro_doppler_mti, micro_doppler] = microdoppler(NChirp, NChan, Nframe, RangeBinIdx, radarCubeData_mti_cell, radarCubeData_cell)

% pre allocation
micro_doppler = zeros(NChirp,NChan,Nframe);
micro_doppler_mti = zeros(NChirp,NChan,Nframe);
frame_data = zeros(NChirp,NChan,Nframe);
frame_data_mti = zeros(NChirp,NChan,Nframe);

% time axis
% max_time = pri * NChan * NChirp * Nframe;  %frame period = 39.17ms
max_time = 0.04 * Nframe;  %frame period = 40ms
time_axis = linspace(0,max_time,Nframe);

% 거리를 RangeBinIdx로 설정하고 3d data (slow time, channels, frames)로 생성
for frames = 1:Nframe
frame_data_mti(:,:,frames) = squeeze(radarCubeData_mti_cell{frames}(:,:,RangeBinIdx));
frame_data(:,:,frames) = squeeze(radarCubeData_cell{frames}(:,:,RangeBinIdx));
end

% micro_doppler = permute(micro_doppler,[3 2 1]);
% 시간 축이 존재하므로 frame이 accumulation돼야 함.
% 따라서 frame에 대해 반복하면 안되고 :를 통해 accumulation해야 함
for chIdx = 1:NChan
  micro_doppler_mti(:,chIdx,:) = fftshift(fft(squeeze(frame_data_mti(:,chIdx,:)).*hann(NChirp),NChirp),1);
  micro_doppler(:,chIdx,:) = fftshift(fft(squeeze(frame_data(:,chIdx,:)).*hann(NChirp),NChirp),1);
end


