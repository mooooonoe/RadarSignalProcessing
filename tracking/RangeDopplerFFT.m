%% Range Doppler FFT
function [max_row, max_col, maxValue, velocityAxis, doppler, doppler_mti, db_doppler] = RangeDopplerFFT(NChirp, NChan, NSample, ...
    chanIdx, max_vel, velocity_resolution, MTIfiltering, radarCubeData_demo, radarCubeData_mti)

% pre allocation
doppler = zeros(NChirp,NChan,NSample);
doppler_mti = zeros(NChirp,NChan,NSample);
win_dop = hann(NChirp);

% range doppelr FFT - not MTI filtered data
for rangebin_size = 1:NSample
    for chIdx = 1:NChan
        DopData1 = squeeze(radarCubeData_demo(:, chIdx, rangebin_size));  %여기 radarCubeData_mti->radarCubeData_demo
        DopData = fftshift(fft(DopData1 .* win_dop, NChirp));
        doppler(:, chIdx, rangebin_size) = DopData;
    end
end

% range doppelr FFT- MTI filtered data 
for rangebin_size = 1:NSample
    for chIdx = 1:NChan
        DopData1_mti = squeeze(radarCubeData_mti(:, chIdx, rangebin_size));
        DopData_mti = fftshift(fft(DopData1_mti .* win_dop, NChirp));
        doppler_mti(:, chIdx, rangebin_size) = DopData_mti;
    end
end

% power
if MTIfiltering
 doppler1 =  doppler_mti(:,chanIdx,:);
 doppler1_128x256 = squeeze(doppler1);
 db_doppler = 10*log10(abs(doppler1_128x256'));
else
 doppler1 =  doppler(:,chanIdx,:);
 doppler1_128x256 = squeeze(doppler1);
 db_doppler = 10*log10(abs(doppler1_128x256'));
end

%가장 큰 값의 인덱스
[maxValue, linearIndex] = max(db_doppler(:));
[max_row, max_col] = ind2sub(size(db_doppler), linearIndex);

% 속도,range 계산
velocityAxis = -max_vel:velocity_resolution:max_vel;
