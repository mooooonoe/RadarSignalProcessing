NChirp = 128; NChan = 4; Nsample = 256;

radarCubeData_demo = zeros(NChirp, NChan, Nsample);
win = rectwin(Nsample);
hwin = hann(Nsample);
hawin = hamming(Nsample);

plot(win, 'r')
hold on
plot(hwin, 'b')
plot(hawin)