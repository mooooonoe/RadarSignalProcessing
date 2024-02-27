clear;
clc;
close all;

frame_number = 1; % 초기 frame_number 설정

% 그래픽 창과 플롯 핸들 초기화
figure;
rangeplot = plot(NaN, NaN);
hold on;
lpcplot = plot(NaN, NaN, 'r', 'LineWidth', 2);
sgplot = plot(NaN, NaN, 'g', 'LineWidth', 2);
peakplot = plot(NaN, NaN, 'ro');
hold off;
xlabel('Range (m)');
ylabel('Range FFT output (dB)');
title('Range Profile (MTI)');
grid on;
legend('Range Profile', 'LPC estimate', 'Sgolay filtered', 'sg peaks');

while frame_number <= 256
    % data update
    signal(frame_number, rangeplot, lpcplot, sgplot, peakplot);
    
    % window update
    drawnow;
    pause(0.1); 
    
    % frame_number value update
    frame_number = frame_number + 1;
end

