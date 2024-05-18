%% PLOTVIDEODATA(y_axis, x_axis, cnt, detected_points, HistoryMap);

function PLOTVIDEODATA(y_axis, x_axis, cnt, detected_points, HistoryMap)
    figure('Position', [200, 200, 800, 400]); % figure 크기 조정
    
    ax1 = subplot(1,2,2);
    ax2 = subplot(1,2,1);
    
    initValue = 1;

    plotFilter(initValue, y_axis, x_axis, HistoryMap, ax2);

    % 영상 파일을 저장할 VideoWriter 생성
    video = VideoWriter('video_output.avi');
    open(video);

    for value = 1:cnt-1
        % plotValue 함수 호출 대신에 여기서 직접 플롯 작업 수행
        surf(ax1, y_axis, x_axis, detected_points(:,:,value), 'EdgeColor', 'none');
        view(ax1, 2);
        colormap(ax1, [linspace(1, 0, 64)', linspace(1, 0.4470, 64)', linspace(1, 0.7410, 64)']);
        caxis(ax1, [0, 1]);
        xlabel(ax1, 'meters (m)');
        ylabel(ax1, 'meters (m)');
        title(ax1, 'DBSCAN Clustering');
        xticks(ax1, 0:2:max(y_axis));
        yticks(ax1, 0:2:max(x_axis));
        if ~isempty(detected_points)
            colorbar(ax1);
        end
        axis(ax1, 'xy');

        % Kalman 필터링 결과 플롯
        plot(ax2, HistoryMap(value,2), HistoryMap(value,1), 'x', 'color' , [0 0.4470 0.7410],'MarkerSize', 4);
        xlabel(ax2, 'meters (m)');
        ylabel(ax2, 'meters (m)');
        title(ax2, 'Kalman Filtering');
        xlim(ax2, [-20, 20]);
        ylim(ax2, [-20, 20]);

        % 현재 figure를 캡처하여 영상에 추가
        frame = getframe(gcf);
        writeVideo(video, frame);
        
        % 0.1초 지연 추가
        pause(0.02);
    end

    % 영상 파일 닫기
    close(video);
end

function plotFilter(value, y_axis, x_axis, HistoryMap, ax2)
    plot(HistoryMap(value,2), HistoryMap(value,1), 'x', 'color' , [0 0.4470 0.7410],'MarkerSize', 4, 'Parent', ax2);
    xlabel(ax2, 'meters (m)');
    ylabel(ax2, 'meters (m)');
    title(ax2, 'Kalman Filtering');
    xlim(ax2, [-20, 20]);
    ylim(ax2, [-20, 20]);
end
