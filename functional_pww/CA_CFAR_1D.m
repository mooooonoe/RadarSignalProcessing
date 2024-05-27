%% 1D CA-CFAR
function [detected_points_1D, cfarData_mti, th, scale_factor_1D] = CA_CFAR_1D(window_sz, ...
    object_number, scale_factor_1D, no_tcell, no_gcell, rangeProfileData_mti)

% 여기서 rangeProfileData를 rangeProfileData_mti로 바꿈
cfarData_mti = squeeze(abs(rangeProfileData_mti));

% preallocation
th = zeros(size(cfarData_mti));

detected_number_1D = 50;
% object number가 detected points보다 작거나 같아질 때 까지 반복 
while(detected_number_1D(1) > object_number)
% 첫번째 sample index부터 마지막 index까지 test
for cutIdx = 1:size(cfarData_mti,1)
    for windowIdx = 1:window_sz 
        sum = 0;
        cnt = 0;
         % 우측 training cell의 sum 구하기
        for i= (no_tcell/2):-1:1
            if(cutIdx-i >0)
                sum = sum + cfarData_mti(cutIdx-i);
                cnt = cnt+1;
            end
        end
        % 좌측 training cell의 sum 구하기
        for j=1:(no_tcell/2)
            if((cutIdx+no_gcell+j) <= 256)
                sum = sum + cfarData_mti(cutIdx+no_gcell+j);
                cnt = cnt + 1;
            end
        end
        % 좌,우측 training cell의 평균
        mean = sum/cnt;
        th(cutIdx) = (mean)*scale_factor_1D;
    end
end
detected_points_1D = find(cfarData_mti > th);
% 설정한 object num과 비교하기 위해 detected points의 개수를 센다.
detected_number_1D = size(detected_points_1D);
% scale factor를 계속 늘려줌
scale_factor_1D = scale_factor_1D + 0.3;
end
