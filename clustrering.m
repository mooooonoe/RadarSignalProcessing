clc;
close all;
clear;

% 예시 데이터 생성
data = [randn(100,2)*0.75+ones(100,2);
        randn(100,2)*0.5-ones(100,2)];

% k-means 알고리즘을 사용하여 데이터 클러스터링
k = 2; % 클러스터 개수
[idx, centers] = kmeans(data, k);

% 결과 시각화
figure;
gscatter(data(:,1), data(:,2), idx, 'rb', 'ox');
hold on;
plot(centers(:,1), centers(:,2), 'kx', 'MarkerSize', 15, 'LineWidth', 3);

% 각 클러스터의 중심에서 가장 먼 점을 찾아 원 그리기
for i = 1:k
    cluster_points = data(idx == i, :); % 클러스터 i에 속하는 점들
    cluster_center = centers(i, :); % 클러스터 i의 중심점
    distances = sqrt(sum((cluster_points - cluster_center).^2, 2)); % 중심에서의 거리 계산
    max_distance = max(distances); % 가장 먼 거리
    viscircles(cluster_center, max_distance, 'Color', 'k', 'LineStyle', '--'); % 원 그리기
end

legend('Cluster 1', 'Cluster 2', 'Centroids', 'Location', 'NW');
title 'k-means 클러스터링 결과';
hold off;



