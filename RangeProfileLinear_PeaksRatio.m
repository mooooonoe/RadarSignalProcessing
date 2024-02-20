clc;
close all;

load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_CUBE.mat");
load("\\223.194.32.78\Digital_Lab\Personals\Subin_Moon\Radar\0_MovingData\TwoMenRun\twomen_RAW.mat");
objectNum = 2;

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


Th_peak = 0.1;

while true
    peakCnt = 0;
    stemRange = zeros(size(rangeAxis));

    for i = 1:length(peaks)-1
        if peaks(i) > peaks(i+1)
            lower = peaks(i+1);
            higher = peaks(i);
            axis = peak_locs(i);
        else
            lower = peaks(i);
            higher = peaks(i+1);
            axis = peak_locs(i+1);
        end
    
        ratio = abs(lower) / abs(higher);
        if ratio < Th_peak
            tgPeak = higher;
            %plot(rangeAxis(axis), tgPeak, 'go');
            peakCnt = peakCnt+1;
            stemRange(axis) = tgPeak;            
        end
    end
    
    if peakCnt == objectNum
        break;
    end

    Th_peak = Th_peak - 0.01;
end

xlabel('Range');
ylabel('Range FFT Output [dB]');
title('Range Profile with Peaks Highlighted');
legend('Range Profile', 'Peaks', 'target');

for i = 1:length(stemRange)
    if stemRange(i) ~= 0
        plot(rangeAxis(i), stemRange(i), 'go', 'MarkerSize', 10);
    end
end
hold off;

figure;
stem(rangeAxis, stemRange);
xlabel('Range');
ylabel('Range FFT Output [dB]');
title('Range Profile with Target Peaks Highlighted');
