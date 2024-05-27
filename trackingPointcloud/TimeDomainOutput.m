%% Time domain output
function [currChDataQ, currChDataI, t] = TimeDomainOutput(NSample, sampling_time, chirpsIdx, chanIdx, frame_number, frameComplex_cell)

currChDataQ = real(frameComplex_cell{frame_number}(chirpsIdx,chanIdx,:));
currChDataI = imag(frameComplex_cell{frame_number}(chirpsIdx,chanIdx,:));

t=linspace(0,sampling_time,NSample);