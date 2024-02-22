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

for i = 1:length(stemRange)
    if stemRange(i) ~= 0
        plot(rangeAxis(i), stemRange(i), 'go', 'MarkerSize', 10);
    end
end

xlabel('Range');
ylabel('Range FFT Output [dB]');
title('Range Profile with Peaks Highlighted');
legend('Range Profile', 'Peaks', 'target');

hold off;

figure;
stem(rangeAxis, stemRange);
xlabel('Range');
ylabel('Range FFT Output [dB]');
title('Range Profile with Target Peaks Highlighted');



for n = 1:256
    input(n)=(stemRange(n));
end

%% CFAR PARAMETER
input_sz = size(input);

no_tcell = 32;
no_gcell = 4;
window_sz= no_gcell + no_tcell + 1 ;
window = zeros(window_sz);
th = zeros(input_sz);
factor = 2;
beta = 0.1;

%% MTI filter
filtered_input = mti_filter(input, beta);

%% CA CFAR window
for cutIdx = 1:256
    cut = filtered_input(cutIdx);
    for windowIdx = 1:window_sz
    sum = 0;
    cnt = 0;
    for i = (no_tcell/2):-1:1
        if (cutIdx-i > 0)
            sum = sum + filtered_input(cutIdx-i);
            cnt = cnt+1;
        end
    end
    for j = 1:(no_tcell/2)
        if ((cutIdx+no_gcell+j) <= 256)
        sum = sum + filtered_input(cutIdx+no_gcell+j);
        cnt = cnt+1;
        end
    end
    mean = sum/cnt;
    th(cutIdx) = (mean)*factor;
    end
end


while true
    detected_points = find(filtered_input > th);
    [~, objectCnt] = size(detected_points);

    if objectCnt == objectNum
        break;
    end
    
    factor = factor + 0.1;

    for cutIdx = 1:256
        cut = filtered_input(cutIdx);
        for windowIdx = 1:window_sz
            sum = 0;
            cnt = 0;
            for i = (no_tcell/2):-1:1
                if (cutIdx-i > 0)
                    sum = sum + filtered_input(cutIdx-i);
                    cnt = cnt+1;
                end
            end
            for j = 1:(no_tcell/2)
                if ((cutIdx+no_gcell+j) <= 256)
                    sum = sum + filtered_input(cutIdx+no_gcell+j);
                    cnt = cnt+1;
                end
            end
            mean = sum/cnt;
            th(cutIdx) = (mean)*factor;
        end
    end
end

figure;
plot(rangeAxis, filtered_input, 'LineWidth', 0.5);
hold on;
plot(rangeAxis, th, 'r', 'LineWidth', 0.5);
legend('Range Profile', 'CFAR Threshold');

%% CA CFAR DETECTOR
detected_points = find(filtered_input > th);
[~, objectCnt] = size(detected_points);

plot(rangeAxis(detected_points), (filtered_input(detected_points)), 'go', 'MarkerSize', 8);
legend('Range Profile', 'CFAR Threshold', 'Detected Points');
xlabel('Range (m)');
ylabel('Power (dB)');
title(sprintf('CA CFAR Detection\nNumber of detections: %d scale factor: %f', objectCnt, single(factor)));

for i = 1:length(detected_points)
    text(rangeAxis(detected_points(i)), filtered_input(detected_points(i)), [num2str(rangeAxis(detected_points(i))), 'm'], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end

%% filter function
function filtered_input = mti_filter(rangeprofile, beta)
    len = length(rangeprofile);
    filtered_input = zeros(size(rangeprofile));
    for i = 2:len
        filtered_input(i) = beta * filtered_input(i-1) + (1 - beta) * rangeprofile(i);
    end
end


