%% MTI filter
function [radarCubeData_mti_cell, rangeProfileData_mti, channelData_mti] = MTI_filter(NChirp, NChan, NSample, Nframe,...
    chirpsIdx, chanIdx, frame_number,radarCubeData_cell)

radarCubeData_mti_cell = cell(1,Nframe);

% range FFT 된 data에 대해 MTI filter 
% range에 대해 fft된 data를 chirp끼리 비교

% preallocation
radarCubeData_mti = zeros(NChirp,NChan,NSample);

for frames = 1:Nframe
% first chirp 는 비교대상이 없으므로 원래 data와 같음.
radarCubeData_mti(1,:,:) = radarCubeData_cell{frames}(1,:,:);
  % single delay line canceller
  for chirpidx = 1:NChirp-1
  radarCubeData_mti(chirpidx+1,:,:) = radarCubeData_cell{frames}(chirpidx,:,:)-radarCubeData_cell{frames}(chirpidx+1,:,:);
  end
radarCubeData_mti_cell{frames} = radarCubeData_mti;
end

rangeProfileData_mti = radarCubeData_mti_cell{frame_number}(chirpsIdx, chanIdx , :);
% linear mode
channelData_mti = abs(rangeProfileData_mti(:));
