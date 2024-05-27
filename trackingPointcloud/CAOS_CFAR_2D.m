%% 2D CA-OS CFAR Algorithm
function [detected_points_2D, scale_factor_CA, scale_factor_OS] = CAOS_CFAR_2D(window_sz, no_tcell, no_gcell, rangeProfileData_mti, ...
    sz_r, sz_c, Nt, Ng, db_doppler_mti)

%1D 
% 여기서 rangeProfileData를 rangeProfileData_mti로 바꿈
cfarData_mti = squeeze(abs(rangeProfileData_mti));


% CA preallocation
th_CA = zeros(size(cfarData_mti));                        %%%%% th 를 os 랑 ca 구분해줌 % th = zeros(size(cfarData_mti));        
scale_factor_CA = 0.001;

% OS % preallocation
th_OS = zeros(size(cfarData_mti));
scale_factor_OS = 0.001;
arr_sz = window_sz-no_gcell-1;


    % CA CFAR
    %detected_number_CA = 0;                              %%%%% deteced_number_1D 를 os 랑 ca 구분해줌

    
    %%%%% while 문 조건 시작 위해서는 처음에 작은 factor 로 cfar 알고리즘 돌리고 while 문 진행해야 함..

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
            th_CA(cutIdx) = (mean)*scale_factor_CA;
        end
    end
    detected_points_CA = find(cfarData_mti > th_CA);
    detected_number_CA = size(detected_points_CA);
                                                       
                                                         
% object number가 detected points보다 작거나 같아질 때 까지 반복 
while(detected_number_CA(1) > length(cfarData_mti)/3) %%%%% object num 없이 진행 % while(detected_number_1D(1) > length(object_number)
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
            th_CA(cutIdx) = (mean)*scale_factor_CA;
        end
    end
    detected_points_CA = find(cfarData_mti > th_CA);
    %%%%  while 문 조건 탈출 비교 위해 detected points의 개수를 센다.
    detected_number_CA = size(detected_points_CA);
    % scale factor를 계속 늘려줌
    scale_factor_CA = scale_factor_CA + 0.3;                
end
    
    %OS CFAR
    %detected_number_OS = 0;                        %%%%% deteced_number_1D 를 os 랑 ca 구분해줌
    
    %%%%% while 문 조건 시작 위해서는 처음에 작은 factor 로 cfar 알고리즘 돌리고 while 문 진행해야 함..
    for cutIdx = 1:size(cfarData_mti,1)
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
                    arr(1,cnt) = input(num2str(cutIdx+no_gcell+j));
                    cnt = cnt + 1;
                end
            end
            sorted_arr = sort(arr);
            id = ceil(3*cnt/4);
            th_OS(cutIdx) = sorted_arr(id)*factor_OS;
        end
    end
    
    detected_points_OS = find(cfarData_mti > th_OS);
    %%%% while 문 조건 탈출 비교 위해 detected points의 개수를 센다.
    detected_number_OS = size(detected_points_OS);

% object number가 detected points보다 작거나 같아질 때 까지 반복 
while(detected_number_OS(1) > length(cfarData_mti)/3) %%%%% object num 없이 진행 % while(detected_number_1D(1) > length(object_number)
    % 첫번째 sample index부터 마지막 index까지 test
    for cutIdx = 1:size(cfarData_mti,1)
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
    
    detected_points_OS = find(cfarData_mti > th_OS);
    %%%% while 문 조건 탈출 비교 위해 detected points의 개수를 센다.
    detected_number_OS = size(detected_points_OS);
    % scale factor를 계속 늘려줌
    scale_factor_OS = scale_factor_OS + 0.3;                
end

%2D CFAR
% pre allocation
arr = zeros(1, Nt);
detected_points_2D = zeros(size(db_doppler_mti,1),size(db_doppler_mti,2));

th = zeros(size(cfarData_mti));        
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
            value_OS = sorted_arr(id)*scale_factor_OS;          %%%%% 1D CFAR 에서 결정된 scale_factor_OS 사용 
            
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
            value_CA = mean*scale_factor_CA;                %%%%% 1D CFAR 에서 결정된 scale_factor_CA 사용 

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