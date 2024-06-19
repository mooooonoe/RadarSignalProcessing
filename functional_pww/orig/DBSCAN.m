%% DBSCAN
function [clusterGrid, idx_db_doppler, corepts] = DBSCAN(eps, MinPts, NSample, NChirp, detected_points_2D, db_doppler_mti)

[row_2d, col_2d] = find(detected_points_2D ~= 0);
sz_data = size(row_2d);
size_data = sz_data(1);
data = zeros(size_data, 2);
cnt = 1;
for idx_cl = 1:size_data
      data(cnt, 1) = col_2d(idx_cl);
      data(cnt, 2) = row_2d(idx_cl);
      cnt = cnt + 1;
end

[idx, corepts] = dbscan(data, eps, MinPts);
clusterGrid = zeros(NSample, NChirp);

for i = 1:size_data
    % idx랑 corepts 번갈아가며 보는 중
    clusterGrid(data(i,2), data(i,1)) = idx(i);
end

% negative value  length(data)는 data의 차원 중 가장 큰 차원의 크기 반환
for i = 1:size(data,1)
    if clusterGrid(data(i,2), data(i,1)) <0
        clusterGrid(data(i,2), data(i,1)) = 0;
    end
end

%% RagneDoppler Map idx imagesc
% 아직 안씀
idx_db_doppler = zeros(NSample, NChirp);

for i = 1:NSample
    for j = 1:NChirp
        if clusterGrid(i,j) == 0 
            idx_db_doppler(i,j) = db_doppler_mti(i,j);
        else
            idx_db_doppler(i,j) = clusterGrid(i,j);
        end

    end
end
