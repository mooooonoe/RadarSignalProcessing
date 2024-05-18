function [clusterGrid, R, C] = DBSCAN(velocityAxis, rangeBin, detected_points)
    [row_2d, col_2d] = find(detected_points ~= 0);
    sz_data = size(row_2d);
    size_data = sz_data(1);
    data = zeros(size_data, 2);
    cnt = 1;
    
    for idx_cl = 1:size_data
          data(cnt, 1) = col_2d(idx_cl);
          data(cnt, 2) = row_2d(idx_cl);
          cnt = cnt + 1;
    end
    
    eps = 2;
    MinPts = 10;

    [idx, ~] = dbscan(data, eps, MinPts);
    
    clusterGrid = zeros(length(rangeBin), length(velocityAxis));
    
    for i = 1:length(data)
        clusterGrid(data(i,2), data(i,1)) = idx(i);
    end
    
    %% negative value 
    for i = 1:length(data)
        if clusterGrid(data(i,2), data(i,1)) <0
            clusterGrid(data(i,2), data(i,1)) = 0;
        end
    end

    %% Finde Center of Each cluster
    [row_core, col_core] = find(clusterGrid == 1); % index = 1 인 부분

        
    if isempty(row_core) || isempty(col_core)
        R = 0;
        C = 0;
    else
        centroid_row = mean(row_core);
        centroid_col = mean(col_core);
    
        row_core_idx = round(centroid_row);
        col_core_idx = round(centroid_col);
        R = velocityAxis(row_core_idx);
        C = rangeBin(col_core_idx);
    end
end