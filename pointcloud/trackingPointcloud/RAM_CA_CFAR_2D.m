%% 2D RAM CA-CFAR Algorithm
function [detected_points_2D] = RAM_CA_CFAR_2D(sz_r, sz_c, Nt, Ng, scale_factor_2D, ram_output2_mti)
% pre allocation
detected_points_2D = zeros(size(ram_output2_mti,1),size(ram_output2_mti,2));
% 2D CFAR processing
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
            % CA-CFAR range - no zero padding
            sum1 = 0;
            cnt_CA1 = 0;
            for i = (Nt/2):-1:1
                if (cutRIdx-i > 0)
                    sum1 = sum1 + ram_output2_mti(cutRIdx-i,cutCIdx);
                    cnt_CA1 = cnt_CA1+1;
                end
            end
            for j = 1:(Nt/2)
                if ((cutRIdx+Ng+j) <= size(ram_output2_mti,1))
                    sum1 = sum1 + ram_output2_mti(cutRIdx+Ng+j,cutCIdx);
                    cnt_CA1 = cnt_CA1+1;
                end
            end
            
            % CA-CFAR Angle - no zero padding
            sum2 = 0;
            cnt_CA2 = 0;
            for i = (Nt/2):-1:1
                if (cutCIdx-i > 0)
                    sum2 = sum2 + ram_output2_mti(cutRIdx, cutCIdx-i);
                    cnt_CA2 = cnt_CA2+1;
                end
            end
            for j = 1:(Nt/2)
                if ((cutCIdx+Ng+j) <= size(ram_output2_mti,2))
                    sum2 = sum2 + ram_output2_mti(cutRIdx, cutCIdx+Ng+j);
                    cnt_CA2 = cnt_CA2+1;
                end
            end
            mean = (sum1/cnt_CA1+sum2/cnt_CA2)/2;
            value_CA = mean*scale_factor_2D;
            th(cutRIdx, cutCIdx) = value_CA;
    end 
end
% detecting points
for cutRIdx = 1:sz_r
    for cutCIdx = 1:sz_c
        cut = ram_output2_mti(cutRIdx, cutCIdx);
        compare = th(cutRIdx, cutCIdx);
        if(cut > compare)
            detected_points_2D(cutRIdx, cutCIdx) = 1;
        end
        if(cut <= compare)
            detected_points_2D(cutRIdx, cutCIdx) = 0;
        end
    end
end
