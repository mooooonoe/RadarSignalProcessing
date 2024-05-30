%% 2D OS CFAR Algorithm
function [detected_points_2D_static] = OS_CFAR_2D_static(sz_r, sz_c, Nt, Ng, scale_factor_2D_static, db_doppler)
% pre allocation
arr = zeros(1, Nt);
detected_points_2D_static = zeros(size(db_doppler,1),size(db_doppler,2));
cutCIdx = sz_c/2 + 1;
% 2D CFAR processing
for cutRIdx = 1:sz_r
            % OS-CFAR range
            for i = (Nt/2):-1:1
                if (cutRIdx-i > 0)
                    arr(1, (Nt/2)-i+1) = db_doppler(cutRIdx-i,cutCIdx);
                end
            end
            for j = 1:(Nt/2)
                if ((cutRIdx+Ng+j) <= size(db_doppler,1))
                    arr(1, (Nt/2)+j) = db_doppler(cutRIdx+Ng+j,cutCIdx);
                end
            end
    sorted_arr = sort(arr);
    size_arr = size(sorted_arr);
    id = ceil(3*(size_arr(2))/4);
    value_OS = sorted_arr(id)*scale_factor_2D_static;

    th(cutRIdx, cutCIdx) = value_OS;
end

% detecting points
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
        % 속도가 0이 아닌 부분은 target이 아님.
        if cutCIdx ~= (sz_c/2 + 1)
            detected_points_2D_static(cutRIdx, cutCIdx) = 0;
        else
           cut = db_doppler(cutRIdx, cutCIdx);
           compare = th(cutRIdx, cutCIdx);
           if(cut > compare)
               detected_points_2D_static(cutRIdx, cutCIdx) = 1;
           end
           if(cut <= compare)
               detected_points_2D_static(cutRIdx, cutCIdx) = 0;
           end
        end
    end
end