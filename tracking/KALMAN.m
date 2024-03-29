function [Xsaved, Zsaved] = KALMAN(Ns, HistoryMap)
 
    dt = 1;
    t = 0:1:Ns-1;
    
    for k= 1:Ns
        if HistoryMap(k,2) ~= 0
            sensorVel = HistoryMap(k, 2);
            z = GetVel(sensorVel);
            initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
            [pos, vel] = IntKalman(initpos, z);

            Xsaved(k, :) = [pos vel];
            Zsaved(k) = z;
        
        else
            Nbacktab = 0;
    
            while HistoryMap(k-Nbacktab, 2) == 0
                Nbacktab = Nbacktab + 1;
                if k-Nbacktab < 1
                    break;
                end
            end

            if (Nbacktab <= 2) && (k - Nbacktab ~= 0)
                sensorVel = HistoryMap(k-Nbacktab, 2);
                initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
                [pos, vel] = IntKalman(initpos, z);                                                 %% 수정
                
                Xsaved(k,:) = [HistoryMap(k-Nbacktab, 1) HistoryMap(k-Nbacktab, 2)];
                Zsaved(k) = z;
            elseif Nbacktab > 2 
                sensorVel = HistoryMap(k, 2);
                initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
                [pos, vel] = IntKalman(initpos, z); 
                Xsaved(k,:) = [HistoryMap(k-Nbacktab, 1) HistoryMap(k-Nbacktab, 2)];
                Zsaved(k) = z;
            elseif k - Nbacktab <1 
                continue;
            else
                     
            end

        end
    end

    %% Function IntKalman
    
    
        
        

    %% Function GetVel

end

