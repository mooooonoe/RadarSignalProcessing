% Range Time Map
function [range_time] = RangeTimeMap(NSample, NChan, Nframe, chirpsIdx, radarCubeData_mti_cell)

% pre allocation
range_time = zeros(Nframe,NChan,NSample);

% time axis
% max_time = pri * NChan * NChirp * Nframe;  %frame period = 39.17ms
% max_time = 0.04 * Nframe;  %frame period = 40ms
% time_axis = linspace(0,max_time,Nframe);

% 속도를 VelocityBinIdx로 설정하고 3d data (frames, channels, range)로 생성
% range FFT 된 데이터를 :를 통해 frame에 대해 accumulation해야 함
for frames = 1:Nframe
range_time(frames,:,:) = squeeze(radarCubeData_mti_cell{frames}(chirpsIdx,:,:));
end

