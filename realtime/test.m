% 주어진 좌표 배열
arr = [5,1; 2,3; 6,2];

% 새로운 그래프 창을 엽니다.
figure;

% 좌표를 플롯합니다. ':' 연산자를 사용하여 모든 행을 선택하고, 각 열을 x와 y 좌표로 사용합니다.
plot(arr(:, 1), arr(:, 2), 'o');

% 축에 그리드를 추가합니다.
grid on;

% 축 이름을 설정합니다.
xlabel('X coordinate');
ylabel('Y coordinate');

% 그래프에 타이틀을 추가합니다.
title('Plot of points');