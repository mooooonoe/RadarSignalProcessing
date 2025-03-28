function PLOTFRAMEDATA(velocityAxis, rangeBin, cnt, detected_points, HistoryMap, Xsaved)
    figure('Position', [200, 200, 800, 400]); % figure 크기 조정
    
    ax1 = subplot(1,2,2);
    ax2 = subplot(1,2,1);
    
    initValue = 1;

    scrollbar = uicontrol('Style', 'slider', ...
                          'Min', 1, 'Max', cnt-1, ...
                          'Value', initValue, ...
                          'SliderStep', [1/(cnt-1), 1/(cnt-1)], ...
                          'Position', [740, 40, 20, 300], ... % slider 위치 조정
                          'Callback', @scrollbarCallback);

    strdisp = sprintf('Frame No: %d', initValue);

    textValue = uicontrol('Style', 'text', ...
                         'String', strdisp, ...
                         'Position', [700, 345, 100, 20]);

    plotValue(initValue, velocityAxis, rangeBin, detected_points, ax1);

    function scrollbarCallback(hObject, eventdata)
        value = round(get(hObject, 'Value'));
        strdisp = sprintf('Frame No: %d', value);
        set(textValue, 'String', strdisp); 
        plotValue(value, velocityAxis, rangeBin, detected_points, ax1); 
    end
    
    nonZeroIndices = any(Xsaved(:,[1 2]) ~= 0, 2);
    XsavedNonZero = Xsaved(nonZeroIndices, :);
    
    XsavedNonZero(:,1) = XsavedNonZero(:,1) -5 ; % 거리 축 조정: -15가 0이 되도록
    XsavedNonZero(:,2) = XsavedNonZero(:,2) - 5; % 속도 축 조정: 7이 0이 되도록
    HistoryMap(:,1) = HistoryMap(:,1) - 5; 
    HistoryMap(:,2) = HistoryMap(:,2) - 5; 

    plot(HistoryMap(:,2), HistoryMap(:,1), 'x', 'color' , [0 0.4470 0.7410],'MarkerSize', 4, 'Parent', ax2);
    hold(ax2, 'on');
    plot(XsavedNonZero(:,2), XsavedNonZero(:,1), 'Parent', ax2);
    legend('Clustering Centroids', 'Kalman Filtered')
    hold(ax2, 'off');
    xlim([min(velocityAxis), max(velocityAxis)]);
    ylim([min(-rangeBin), max(rangeBin)*3.5]);
    xlabel(ax2, 'Velocity (m/s)');
    ylabel(ax2, 'Range (m)');
    title(ax2, 'Kalman Filtering');

    ax2.YTick = [];
end

function plotValue(value, velocityAxis, rangeBin, detected_points, ax)
    
colormap(flipud(gray));
    if ~isempty(detected_points)
        binary_points = detected_points(:,:,value);
        binary_points(binary_points > 0) = 1;
        imagesc(ax, velocityAxis, rangeBin, binary_points);
        colormap(ax, [linspace(1, 0, 64)', linspace(1, 0.4470, 64)', linspace(1, 0.7410, 64)']);
        caxis(ax, [0, 1]);
    end
    xlabel(ax, 'Velocity (m/s)');
    ylabel(ax, 'Range (m)');
    title(ax, 'DBSCAN Clustering');
    
    yticks(ax, 0:2:max(rangeBin));
    
    if ~isempty(detected_points)
        colorbar(ax);
    end
    axis(ax, 'xy');
end
