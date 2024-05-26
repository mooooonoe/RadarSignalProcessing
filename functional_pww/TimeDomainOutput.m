%% Time domain output
function [currChDataQ, currChDataI, t] = TimeDomainOutput(NSample, sampling_time, chirpsIdx, chanIdx, frameComplex)

currChDataQ = real(frameComplex(chirpsIdx,chanIdx,:));
currChDataI = imag(frameComplex(chirpsIdx,chanIdx,:));

t=linspace(0,sampling_time,NSample);