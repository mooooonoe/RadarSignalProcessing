clc;
close all;

load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");

newCube.data = struct('data', cell(1, 128));

for i = 1:128
    newCube.data(i).data = radarCube.data{i}(:, 1, :);
end

chirp = 1;
demoCubedata = newCube.data(1).data;
radarCube2DFFT = fft2(demoCubedata);
rangeAxis = linspace(0, 15, 256);

chirpIdx = 1;
fft_result = squeeze(radarCube2DFFT(chirpIdx, 1, :));

figure;
plot(rangeAxis, abs(fft_result)); 
hold on;

minPeakHeight = 10;
[peaks, peak_locs] = findpeaks(abs(fft_result), 'MinPeakHeight', minPeakHeight);
plot(rangeAxis(peak_locs), peaks, 'ro');

Th_peak = 0.5;

for i = 1:length(peaks)-1
    if peaks(i) > peaks(i+1)
        lower = peaks(i+1);
        higher = peaks(i);
    else
        lower = peaks(i);
        higher = peaks(i+1);
    end

    ratio = abs(lower) / abs(higher);
    if ratio < Th_peak
        tgPeak = higher;
    end

    plot(rangeAxis(peak_locs(i)), tgPeak, 'go');
end

hold off;

xlabel('Range');
ylabel('Range FFT Output [dB]');
title('Range Profile with Peaks Highlighted');
legend('Range Profile', 'Peaks', 'target');