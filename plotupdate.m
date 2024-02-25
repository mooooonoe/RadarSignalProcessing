% 예시를 위한 데이터 생성
x = linspace(0, 2*pi, 100);
y = sin(x);

% 초기 플롯
plotHandle = plot(x, y);
xlabel('X');
ylabel('Y');
title('Real-time Plot');

% 시뮬레이션을 위한 반복문
for i = 1:100
    % 데이터 업데이트 (여기서는 예시로 sin 함수를 사용)
    y = sin(x + i * 0.1);
    
    % 그래픽 객체 업데이트
    set(plotHandle, 'YData', y);
    
    % 그래픽 창 업데이트
    drawnow;
    
    % 잠시 일시 정지하여 시뮬레이션 속도를 조절할 수 있습니다.
    pause(0.1); % 0.1초마다 업데이트
end
