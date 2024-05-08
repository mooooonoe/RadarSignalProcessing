%% FFT Range Profile
function [rangeProfileData, radarCubeData_demo, channelData, rangeBin] = FT_RANGE(NChirp, NChan, NSample, ...
    chirpsIdx, chanIdx, numrangeBins, range_resolution, frameComplex)

% pre allocation
radarCubeData_demo = zeros(NChirp, NChan, NSample);
win = rectwin(NSample);

% Range FFT
for chirpIdx = 1:128
    for chIdx = 1:4
        frameData1(1,:) = frameComplex(chirpIdx, chIdx, :);
        frameData2 = fft(frameData1 .* win', NSample);
        radarCubeData_demo(chirpIdx, chIdx, :) = frameData2(1,:);
    end
end
rangeProfileData = radarCubeData_demo(chirpsIdx, chanIdx , :);

% Range Bin
% rangeBin = linspace(0, Params.numRangeBins * Params.RFParams.rangeResolutionsInMeters, Params.numRangeBins);
rangeBin = linspace(0,numrangeBins *range_resolution, numrangeBins);

% linear mode
channelData = abs(rangeProfileData(:));
