%% MTI filter
function [radarCubeData_mti, rangeProfileData_mti, channelData_mti] = MTI_filter(NChirp, NChan, NSample, ...
    chirpsIdx, chanIdx, radarCubeData_demo)

% range FFT 된 data에 대해 MTI filter 
% range에 대해 fft된 data를 chirp끼리 비교

% preallocation
radarCubeData_mti = zeros(NChirp,NChan,NSample);

% first chirp 는 비교대상이 없으므로 원래 data와 같음.
radarCubeData_mti(1,:,:) = radarCubeData_demo(1,:,:);

% single delay line canceller
for chirpidx = 1:NChirp-1
radarCubeData_mti(chirpidx+1,:,:) = radarCubeData_demo(chirpidx,:,:)-radarCubeData_demo(chirpidx+1,:,:);
end

% double delay line canceller
radarCubeData_mti2 = zeros(128,4,256);
radarCubeData_mti2(1,:,:) = radarCubeData_mti(1,:,:);
for chirpidx = 1:127
radarCubeData_mti2(chirpidx+1,:,:) = radarCubeData_mti(chirpidx,:,:)-radarCubeData_mti(chirpidx+1,:,:);
end

rangeProfileData_mti = radarCubeData_mti(chirpsIdx, chanIdx , :);
channelData_mti = abs(rangeProfileData_mti(:));
