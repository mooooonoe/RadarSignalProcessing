%% Find Peak Value
function [peak_locs, peaks, target_Idx, target] = FindTarget(minPeakHeight, peak_th, channelData_mti)

% find peaks Idx and peak value
[peaks, peak_locs] = findpeaks(channelData_mti, 'MinPeakHeight', minPeakHeight);

% preallocation
target = zeros(size(peaks));

% peak 중에서 target 찾기
for iter = 1 : size(peaks)-1
    % iter index가 higher value 
    if (peaks(iter) >= peaks(iter+1)) 
        high_peak = peaks(iter);
        low_peak = peaks(iter+1);
        peak_ratio = low_peak/high_peak;
    if (peak_ratio < peak_th)
        target(iter) = high_peak;  % iter가 high peak이므로 target index는 iter
    end
    % iter+1 index가 higher value
    else
        high_peak = peaks(iter+1);
        low_peak = peaks(iter);
        peak_ratio = low_peak/high_peak;
    if (peak_ratio < peak_th)
        target(iter+1) = high_peak; % iter+1이 high peak이므로 target index는 iter+1
    end
    end
end

% target의 index 찾기
target_Idx = find(target ~= 0);
% 요소가 0인 index 다 제거
target = nonzeros(target);