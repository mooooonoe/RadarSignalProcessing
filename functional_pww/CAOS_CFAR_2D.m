%% 2D CA-OS CFAR Algorithm
function [detected_points_2D] = CAOS_CFAR_2D(sz_r, sz_c, Nt, Ng, scale_factor_2D, db_doppler)

% pre allocation
arr = zeros(1, Nt);
detected_points_2D = zeros(256,128);

% 2D CFAR processing
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
            % OS-CFAR
            for i = (Nt/2):-1:1
                if (cutCIdx-i > 0)
                    arr(1, (Nt/2)-i+1) = db_doppler(cutCIdx-i,cutRIdx);
                end
            end

            for j = 1:(Nt/2)
                if ((cutCIdx+Ng+j) <= 256)
                    arr(1, (Nt/2)+j) = db_doppler(cutCIdx+Ng+j,cutRIdx);
                end
            end
            sorted_arr = sort(arr);
            size_arr = size(sorted_arr);
            id = ceil(3*(size_arr(2))/4);
            value_OS = sorted_arr(id)*scale_factor_2D;
        
            % CA-CFAR
            sum = 0;
            cnt_CA = 0;
            for i = (Nt/2):-1:1
                if (cutRIdx-i > 0)
                    sum = sum + db_doppler(cutCIdx, cutRIdx-i);
                    cnt_CA = cnt_CA+1;
                end
            end
            for j = 1:(Nt/2)
                if ((cutRIdx+Ng+j) <= 128)
                sum = sum + db_doppler(cutCIdx, cutRIdx+Ng+j);
                cnt_CA = cnt_CA+1;
                end
            end
            mean = sum/cnt_CA;
            value_CA = mean*scale_factor_2D;


        if value_CA > value_OS
            th(cutCIdx, cutRIdx) = value_CA;
        else
            th(cutCIdx, cutRIdx) = value_OS;
        end
    end 
end

% detecting points
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
        cut = db_doppler(cutCIdx, cutRIdx);
        compare = th(cutCIdx, cutRIdx);
        if(cut > compare)
            detected_points_2D(cutCIdx, cutRIdx) = 1;
        end
        if(cut <= compare)
            detected_points_2D(cutCIdx, cutRIdx) = 0;
        end
    end
end
