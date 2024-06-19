%% 2D CA-OS CFAR Algorithm
function [detected_points_2D] = CAOS_CFAR_2D(sz_r, sz_c, Nt, Ng, scale_factor_2D, db_doppler_mti)
% pre allocation
arr = zeros(1, Nt);
detected_points_2D = zeros(size(db_doppler_mti,1),size(db_doppler_mti,2));
% 2D CFAR processing
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
            % OS-CFAR range
            for i = (Nt/2):-1:1
                if (cutRIdx-i > 0)
                    arr(1, (Nt/2)-i+1) = db_doppler_mti(cutRIdx-i,cutCIdx);
                end
            end
            for j = 1:(Nt/2)
                if ((cutRIdx+Ng+j) <= size(db_doppler_mti,1))
                    arr(1, (Nt/2)+j) = db_doppler_mti(cutRIdx+Ng+j,cutCIdx);
                end
            end
            sorted_arr = sort(arr);
            size_arr = size(sorted_arr);
            id = ceil(3*(size_arr(2))/4);
            value_OS = sorted_arr(id)*scale_factor_2D;
            
            % CA-CFAR Doppler
            sum = 0;
            cnt_CA = 0;
            for i = (Nt/2):-1:1
                if (cutCIdx-i > 0)
                    sum = sum + db_doppler_mti(cutRIdx, cutCIdx-i);
                    cnt_CA = cnt_CA+1;
                end
            end
            for j = 1:(Nt/2)
                if ((cutCIdx+Ng+j) <= size(db_doppler_mti,2))
                   sum = sum + db_doppler_mti(cutRIdx, cutCIdx+Ng+j);
                   cnt_CA = cnt_CA+1;
                end
            end
            mean = sum/cnt_CA;
            value_CA = mean*scale_factor_2D;

        if value_CA > value_OS
            th(cutRIdx, cutCIdx) = value_CA;
        else
            th(cutRIdx, cutCIdx) = value_OS;
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