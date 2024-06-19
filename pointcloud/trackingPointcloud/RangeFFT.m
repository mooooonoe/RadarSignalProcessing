%% FFT Range Profile
function [rangeProfileData, radarCubeData_cell, channelData, rangeBin] = RangeFFT(NChirp, NChan, NSample, Nframe, ...
    chirpsIdx, chanIdx, numrangeBins, range_resolution, frame_number, frameComplex_cell)
% pre allocation
radarCubeData_cell = cell(1,Nframe);
radarCubeData_demo = zeros(NChirp, NChan, NSample);
win = rectwin(NSample);
for frames = 1:Nframe
 % Range FFT
  for chirpIdx = 1:128
    for chIdx = 1:4
        frameData1(1,:) = frameComplex_cell{frames}(chirpIdx, chIdx, :);
        frameData2 = fft(frameData1 .* win', NSample);
        radarCubeData_demo(chirpIdx, chIdx, :) = frameData2(1,:);
    end
  end
  radarCubeData_cell{frames} = radarCubeData_demo;
end

rangeProfileData = radarCubeData_cell{frame_number}(chirpsIdx, chanIdx , :);
% linear mode
channelData = abs(rangeProfileData(:));

% Range Bin
% rangeBin = linspace(0, Params.numRangeBins * Params.RFParams.rangeResolutionsInMeters, Params.numRangeBins);
rangeBin = linspace(0,(numrangeBins-1) *range_resolution, numrangeBins);


