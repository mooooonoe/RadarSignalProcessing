clc;
%close all;

% periodogram 주기도 파워 스펙트럼 밀도 추정값

n = 0:319;                           %샘플수 320개
x = cos(pi/4*n)+randn(size(n));
[pxx, w] = periodogram(x);
plot(w, 10*log10(pxx));

%% hamming woindow
n  = 0:319;
x = cos(pi/4*n)+randn(size(n));
periodogram(x, hamming(length(x)));

%% 신호 길이와 동일한 DFT 길이
%가산성 N(0,1) 백색 잡음과 함께
%기본적으로 길이가 320/2+1인 단측 주기도가 반환
n = 0:319;
x = cos(pi/4*n)+randn(size(n));
nfft = length(x);                   %신호의 길이 320
periodogram(x,[],nfft);             %이산 푸리에 변환(DFT)에 포함된 nfft개 점을 사용


%% PSD
Fs = 32e3;                                  %  시간 단위당 주파수 영역에서의 에너지를 계산
t = 0:1/Fs:2.96;
x = cos(2*pi*t*1.24e3)+ cos(2*pi*t*10e3)+ randn(size(t));
nfft = 2^nextpow2(length(x));
Pxx = abs(fft(x, nfft)).^2/length(x)/Fs;    % 주파수 영역에서의 신호의 에너지

Hpsd = dspdata.psd(Pxx(1:length(Pxx)/2), 'Fs', Fs);
plot(Hpsd)

%% 상대흑점수
load sunspot.dat
relNums = sunspot(:, 2);
[pxx, f] = periodogram(relNums, [], [], 1);

plot(f, 10*log10(pxx));
xlabel('cycles/year');
ylabel('db/(cycles/year)');
title('periodogram of relative sunsplot num data')

%% 주어진 정규화 주파수 집합에서의 주기도
n = 0:319;
x = cos(pi/4*n)+0.5*sin(pi/2*n)+randn(size(n));
[pxx, w] = periodogram(x, [], [pi/4 pi/2]);
pxx

[pxx1,w1] = periodogram(x);
plot(w1/pi,pxx1,w/pi,2*pxx,'o');
legend('pxx1', '2*pxx');
xlabel('\omega / \pi');

%% 정현파 전력 추정값
fs = 1000;
t = 0:1/fs:1-1/fs;
x = 1.8*cos(2*pi*100*t);    % 정현파 생성
[pxx,f] = periodogram(x, hamming(length(x)), length(x), fs, 'power');   % f 주파수 벡터
[pwrest, idx] = max(pxx);
fprintf('The maximum power occurs at %3.1f Hz\n',f(idx))    % f(dix)

fprintf('The power estimate is %2.2f\n',pwrest) % pwrest

%% 다중 채널 신호의 주기도 PSD 추정값
N = 1024;
n = 0:N-1;
w = pi./[2;3;4];
x = cos(w*n)' + randn(length(n), 3);

periodogram(x);

%% 수정된 주기도 계산
N = 1024;
x = 2*cos(2*pi/5*(0:N-1)') + randn(N,1);
periodogram(x,hann(N));
[pxMex, fMex] = periodogram_data(x, hann(N));
hold on;
plot(fMex/pi,pow2db(pxMex), ':', 'color', [0 0 0.5]);
hold off
grid on
legend('periodogram', 'MEX function')


function [pxx,f] = periodogram_data(inputData,window)
%#codegen
nfft = length(inputData);
[pxx,f] = periodogram(inputData,window,nfft);
end


