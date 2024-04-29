%% 2D MTI filter
% pre allocation
DopData1_mti = cell(1, Nframe);
DopData_mti = cell(1, Nframe);
doppler_mti = cell(1, Nframe);
win_dop = hann(NChirp);

aradarCubeData_mti = cell(1,Nframe);

% 1D FFT된 데이터를 chirp MTI
for framesize = 1:Nframe
    aradarCubeData_mti{framesize}(1,:,:) = radarCube.data{framesize}(1,:,:);
    for chirpidx = 1:NChirp-1
    aradarCubeData_mti{framesize}(chirpidx+1,:,:) = radarCube.data{framesize}(chirpidx,:,:)-radarCube.data{framesize}(chirpidx+1,:,:);
    end
end

% range doppelr FFT
for framesize = 1:Nframe
 for rangebin_size = 1:NSample
    for chIdx = 1:NChan
        DopData1_mti{framesize} = squeeze(aradarCubeData_mti{framesize}(:, chIdx, rangebin_size));
        DopData_mti{framesize} = fftshift(fft(DopData1_mti{framesize} .* win_dop, NChirp));
        doppler_mti{framesize}(:, chIdx, rangebin_size) = DopData_mti{framesize};
    end
 end
end

% 2D FFT된 데이터를 frame MTI
mti_doppler = cell(1, Nframe);
mti_doppler{1} = doppler_mti{1};
for frameIdx = 1:Nframe-1
    mti_doppler{frameIdx+1}(:,:,:) = doppler_mti{frameIdx+1}(:,:,:) - doppler_mti{frameIdx}(:,:,:);
end

% Data Cube를 plot하기 위해 2D data와 power로 표현
doppler1_mti =  mti_doppler{frame_number}(:,chanIdx,:);
doppler1_128x256_mti = squeeze(doppler1_mti);
db_doppler_mti = 10*log10(abs(doppler1_128x256_mti'));

nexttile;
imagesc(velocityAxis,rangeBin,db_doppler_mti);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('Range-Doppler Map (MTI)');
colorbar;
axis xy