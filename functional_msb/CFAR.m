%% 2D CA-OS CFAR Algorithm
function [detected_points] = CFAR(frame_n, numrangeBins, rangeProfileData_mti, db_doppler)
input = zeros(size(rangeProfileData_mti));
    
    for n = 1:256
        input(n)=abs(rangeProfileData_mti(n));
    end
    
    %% CFAR PARAMETER
    input_sz = size(input);
    
    no_tcell = 20;
    no_gcell = 2;
    window_sz= no_gcell + no_tcell + 1 ;
   
    % CA INIT
    th_CA = zeros(input_sz);
    factor_CA = 0.001;
    
    % OS INIT
    th_OS = zeros(input_sz);
    factor_OS = 0.001;
    arr_sz = window_sz-no_gcell-1;
    
    % CA CFAR window
    for cutIdx = 1:256
        cut = input(cutIdx);
        for windowIdx = 1:window_sz
        sum = 0;
        cnt = 0;
        for i = (no_tcell/2):-1:1
            if (cutIdx-i > 0)
                sum = sum + input(cutIdx-i);
                cnt = cnt+1;
            end
        end
        for j = 1:(no_tcell/2)
            if ((cutIdx+no_gcell+j) <= 256)
            sum = sum + input(cutIdx+no_gcell+j);
            cnt = cnt+1;
            end
        end
        mean = sum/cnt;
        th_CA(cutIdx) = (mean)*factor_CA;
        end
    end


    while true
        detected_points_CA = find(input > th_CA);
        objectCnt_CA = length(detected_points_CA);

        if objectCnt_CA < (numrangeBins/3.5)
            break;
        end

        factor_CA = factor_CA + 0.01;

        for cutIdx = 1:256
            cut = input(cutIdx);
            for windowIdx = 1:window_sz
                sum = 0;
                cnt = 0;
                for i = (no_tcell/2):-1:1
                    if (cutIdx-i > 0)
                        sum = sum + input(cutIdx-i);
                        cnt = cnt+1;
                    end
                end
                for j = 1:(no_tcell/2)
                    if ((cutIdx+no_gcell+j) <= 256)
                        sum = sum + input(cutIdx+no_gcell+j);
                        cnt = cnt+1;
                    end
                end
                mean = sum/cnt;
                th_CA(cutIdx) = (mean)*factor_CA;
            end
        end
    end

    % CA CFAR DETECTOR
    detected_points_CA = find(input > th_CA);
    objectCnt_CA = length(detected_points_CA);

    % OS CFAR 
    for cutIdx = 1:256
        cut = input(cutIdx);
        arr = zeros(1,arr_sz);
        sorted_arr = zeros(1,arr_sz);
        cnt = 1;
        for windowIdx = 1:window_sz

            for i = (no_tcell/2):-1:1
                if (cutIdx-i > 0)
                    arr(1,cnt) = input(cutIdx-i);
                    cnt = cnt + 1;
                end
            end
            for j = 1:(no_tcell/2)
                if ((cutIdx+no_gcell+j) <= 256)
                    arr(1,cnt) = input(cutIdx+no_gcell+j);
                    cnt = cnt + 1;
                end
            end
            sorted_arr = sort(arr);
            id = ceil(3*cnt/4);
            th_OS(cutIdx) = sorted_arr(id)*factor_OS;
        end
    end


    while true
        detected_points_OS = find(input > th_OS);
        [objectCnt_OS, ~] = size(detected_points_OS);

        if objectCnt_OS < (numrangeBins/3.5)
            break;
        end

        factor_OS = factor_OS + 0.1;

        for cutIdx = 1:256
            cut = input(cutIdx);
            arr = zeros(1,arr_sz);
            sorted_arr = zeros(1,arr_sz);
            cnt = 1;
            for windowIdx = 1:window_sz

                for i = (no_tcell/2):-1:1
                    if (cutIdx-i > 0)
                        arr(1,cnt) = input(cutIdx-i);
                        cnt = cnt + 1;
                    end
                end
                for j = 1:(no_tcell/2)
                    if ((cutIdx+no_gcell+j) <= 256)
                        arr(1,cnt) = input(cutIdx+no_gcell+j);
                        cnt = cnt + 1;
                    end
                end
                sorted_arr = sort(arr);
                id = ceil(3*cnt/4);
                th_OS(cutIdx) = sorted_arr(id)*factor_OS;
            end
        end
    end

    % OS CFAR DETECTOR
    detected_points_OS = find(input > th_OS);
    [objectCnt_OS, ~] = size(detected_points_OS);


    disp([num2str(frame_n), 'frame OS_K=', num2str(factor_OS), ', CA_K=', num2str(factor_CA)]);

    %% 2D CFAR input
    sz_c = size(db_doppler,1);
    sz_r = size(db_doppler,2);

    for i = 1:sz_c
        for j = 1:sz_r
            inputOSCA(i , j) = db_doppler(i, j);
        end
    end

    %% CA CFAR PARAMETER
    input_sz = size(inputOSCA);

    Nt = 32;
    Ng = 4;
    window_sz= Ng + Nt + 1 ;
    window = zeros(window_sz);
    th = zeros(input_sz);
    factor = 4;
    beta = 0.1;

    %% 2D CA-OS CFAR Algorithm
    for cutRIdx = 1:sz_r
        for cutCIdx = 1:sz_c
            cut = inputOSCA(cutCIdx, cutRIdx);
            arr = zeros(1, window_sz);
            %cnt_OS = 1;
            for windowCIdx = 1:window_sz
                for i = (Nt/2):-1:1
                    if (windowCIdx-i > 0)
                        arr(1, windowCIdx-i) = inputOSCA(windowCIdx-i,cutRIdx);
                        %cnt_OS = cnt_OS+1;
                    end
                end
                for j = 1:(Nt/2)
                    if ((windowCIdx+Ng+j) <= 256)
                        arr(1, windowCIdx+Ng+j) = inputOSCA(windowCIdx+Ng+j,cutRIdx);
                        %cnt_OS = cnt_OS+1;
                    end
                end
                sorted_arr = sort(arr);
                size_arr = size(sorted_arr);
                id = ceil(3*(size_arr(2))/4);
                value_OS = sorted_arr(id)*factor_OS;
            end

            for windowRIdx = 1:window_sz
                sum = 0;
                cnt_CA = 0;
                for i = (Nt/2):-1:1
                    if (cutRIdx-i > 0)
                        sum = sum + inputOSCA(cutCIdx, cutRIdx-i);
                        cnt_CA = cnt_CA+1;
                    end
                end
                for j = 1:(Nt/2)
                    if ((cutRIdx+Ng+j) <= 128)
                    sum = sum + inputOSCA(cutCIdx, cutRIdx+Ng+j);
                    cnt_CA = cnt_CA+1;
                    end
                end
                mean = sum/cnt_CA;
                value_CA = mean*factor_CA;

            end

            if value_CA > value_OS
                th(cutCIdx, cutRIdx) = value_CA;
            else
                th(cutCIdx, cutRIdx) = value_OS;
            end
        end 
    end



    %% detect
    detected_points = zeros(input_sz);

    for cutRIdx = 1:sz_r
        for cutCIdx = 1:sz_c
            cut = inputOSCA(cutCIdx, cutRIdx);
            compare = th(cutCIdx, cutRIdx);
            if(cut > compare)
                detected_points(cutCIdx, cutRIdx) = cut;
            end
            if(cut <= compare)
                detected_points(cutCIdx, cutRIdx) = 0;
            end
        end
    end

