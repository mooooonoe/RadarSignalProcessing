%% 2D CA-OS CFAR Algorithm
function [detected_points_2D] = RAM_OS_CFAR_2D(sz_r, sz_c, Nt, Ng, scale_factor_2D, db_doppler_mti)
% pre allocation
arr1 = zeros(1, Nt);
arr2 = zeros(1, Nt);
detected_points_2D = zeros(size(db_doppler_mti,1),size(db_doppler_mti,2));
% 2D CFAR processing
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
            % OS-CFAR range
            for i = (Nt/2):-1:1
                if (cutRIdx-i > 0)
                    arr1(1, (Nt/2)-i+1) = db_doppler_mti(cutRIdx-i,cutCIdx);
                end
            end
            for j = 1:(Nt/2)
                if ((cutRIdx+Ng+j) <= size(db_doppler_mti,1))
                    arr1(1, (Nt/2)+j) = db_doppler_mti(cutRIdx+Ng+j,cutCIdx);
                end
            end
            sorted_arr1 = sort(arr1);
            size_arr1 = size(sorted_arr1);
            id1 = ceil(3*(size_arr1(2))/4);
            value_OS1 = sorted_arr1(id1)*scale_factor_2D;
            
            % CA-CFAR Doppler
            for i = (Nt/2):-1:1
                if (cutCIdx-i > 0)
                    arr2(1, (Nt/2)-i+1) = db_doppler_mti(cutRIdx, cutCIdx-i);
                end
            end
            for j = 1:(Nt/2)
                if ((cutCIdx+Ng+j) <= size(db_doppler_mti,2))
                    arr2(1, (Nt/2)+j) = db_doppler_mti(cutRIdx, cutCIdx+Ng+j);
                end
            end
            sorted_arr2 = sort(arr2);
            size_arr2 = size(sorted_arr2);
            id2 = ceil(3*(size_arr2(2))/4);
            value_OS2 = sorted_arr2(id2)*scale_factor_2D;

        if value_OS1 > value_OS2
            th(cutRIdx, cutCIdx) = value_OS1;
        else
            th(cutRIdx, cutCIdx) = value_OS2;
        end
    end 
end

% detecting points
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
        cut = db_doppler_mti(cutRIdx, cutCIdx);
        compare = th(cutRIdx, cutCIdx);
        if(cut > compare)
            detected_points_2D(cutRIdx, cutCIdx) = 1;
        end
        if(cut <= compare)
            detected_points_2D(cutRIdx, cutCIdx) = 0;
        end
    end
end