%%  k-means Clustering
function [detected_points_clustering] = Clustering(NSample,NChirp, k, detected_points_2D)

[row_2d, col_2d] = find(detected_points_2D ~= 0);
sz_data = size(row_2d);
size_data = sz_data(1);
data = zeros(size_data, 2);
cnt = 1;

% detect된 target의 data들을 만들어줌. target이 있는 부분은 1, target이 없는 부분은 0  
for idx_cl = 1:size_data
      data(cnt, 1) = col_2d(idx_cl);
      data(cnt, 2) = row_2d(idx_cl);
      cnt = cnt + 1;
end

% k-means Clustering
[idx, centers] = kmeans(data, k);

% detected_points에 clustering 진행한 결과인 idx 대입
detected_points_clustering = zeros(NSample,NChirp);
for cl_idx = 1:size_data
detected_points_clustering(data(cl_idx,2),data(cl_idx,1)) = idx(cl_idx);
end
