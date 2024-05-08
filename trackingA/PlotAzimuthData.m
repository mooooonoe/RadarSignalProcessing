function PlotAzimuthData(y_axis, x_axis, cnt, detected_points, HistoryMap)
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

    plotValue(initValue, y_axis, x_axis, detected_points, ax1);
    plotFilter(initValue, y_axis, x_axis, HistoryMap, ax2);

    function scrollbarCallback(hObject, eventdata)
        value = round(get(hObject, 'Value'));
        updatePlot(value);
    end

    function updatePlot(value)
        strdisp = sprintf('Frame No: %d', value);
        set(textValue, 'String', strdisp); 
        plotValue(value, y_axis, x_axis, detected_points, ax1);
        plotFilter(value, y_axis, x_axis, HistoryMap, ax2);
        drawnow;
    end

end

function plotValue(value, y_axis, x_axis, detected_points, ax)
    
    colormap(flipud(gray));
    if ~isempty(detected_points)
        binary_points = detected_points(:,:,value);
        binary_points(binary_points > 0) = 1;
        surf(ax, y_axis, x_axis, binary_points,'EdgeColor','none');
        view(ax, 2);
        colormap(ax, [linspace(1, 0, 64)', linspace(1, 0.4470, 64)', linspace(1, 0.7410, 64)']);
        caxis(ax, [0, 1]);
    end
    xlabel(ax, 'meters (m)');
    ylabel(ax, 'meters (m)');
    title(ax, 'DBSCAN Clustering');
    xticks(ax, 0:2:max(y_axis));
    yticks(ax, 0:2:max(x_axis));
    
    if ~isempty(detected_points)
        colorbar(ax);
    end
    axis(ax, 'xy');
end

function plotFilter(value, y_axis, x_axis, HistoryMap, ax2)
    plot(HistoryMap(value,2), HistoryMap(value,1), 'x', 'color' , [0 0.4470 0.7410],'MarkerSize', 4, 'Parent', ax2);
    xlabel(ax2, 'meters (m)');
    ylabel(ax2, 'meters (m)');
    title(ax2, 'Kalman Filtering');
    xlim(ax2, [-20, 20]);
    ylim(ax2, [-20, 20]);
end
