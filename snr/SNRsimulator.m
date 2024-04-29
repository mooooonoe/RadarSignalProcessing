Fi = 2500;
Fs = 48e3;
N = 1024;
x = sin(2*pi*Fi/Fs*(1:N)) + 0.001*randn(1,N);

SNR = snr(x,Fs);