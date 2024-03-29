function PLOTFRAMEDATA(velocityAxis, rangeBin, cnt, detected_points, HistoryMap, Xsaved)
    % Create figure and subplots
    fig = figure('Position', [200, 200, 800, 400]); 
    ax1 = subplot(1,2,2);
    ax2 = subplot(1,2,1);
    
    % Initial value for scrollbar
    initValue = 1;

    % Create scrollbar
    scrollbar = uicontrol('Style', 'slider', ...
                          'Min', 1, 'Max', cnt-1, ...
                          'Value', initValue, ...
                          'SliderStep', [1/(cnt-1), 1/(cnt-1)], ...
                          'Position', [740, 40, 20, 300], ...
                          'Callback', @scrollbarCallback);

    % Display current frame number
    strdisp = sprintf('Frame No: %d', initValue);
    textValue = uicontrol('Style', 'text', ...
                         'String', strdisp, ...
                         'Position', [710, 345, 90, 20]);

    % Create play button
    playButton = uicontrol('Style', 'pushbutton', 'String', 'Play', ...
                           'Position', [720, 370, 70, 30], ...
                           'Callback', @playCallback);
                       
    % Adjust data for plotting
    Xsaved(:,1) = Xsaved(:,1);
    Xsaved(:,2) = Xsaved(:,2);
    HistoryMap(:,1) = HistoryMap(:,1); 
    HistoryMap(:,2) = HistoryMap(:,2); 

    % Plot initial frames
    plotValue(initValue, velocityAxis, rangeBin, detected_points, ax1);
    plotFilter(initValue, velocityAxis, rangeBin, HistoryMap, Xsaved, ax2);

    % Callback function for scrollbar
    function scrollbarCallback(hObject, ~)
        value = round(get(hObject, 'Value'));
        updatePlot(value);
    end

    % Callback function for play button
    function playCallback(~, ~)
        for value = 1:cnt-1
            updatePlot(value);
            pause(0.001); 
        end
    end

    % Function to update plot based on frame number
    function updatePlot(value)
        strdisp = sprintf('Frame No: %d', value);
        set(textValue, 'String', strdisp); 
        plotValue(value, velocityAxis, rangeBin, detected_points, ax1); 
        plotFilter(value, velocityAxis, rangeBin, HistoryMap, Xsaved, ax2);
        drawnow; % Ensure plot is updated immediately
    end
end

% Plotting function for DBSCAN clustering
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

% Plotting function for Kalman filtering
function plotFilter(value, velocityAxis, rangeBin, HistoryMap, Xsaved, ax)
    plot(HistoryMap(value,2), HistoryMap(value,1), 'x', 'color' , [0 0.4470 0.7410],'MarkerSize', 8, 'Parent', ax);
    hold(ax, 'on');
    plot(Xsaved(value,2), Xsaved(value,1), 'x','MarkerSize', 8, 'Parent', ax);
    legend('Clustering Centroids', 'Kalman Filtered')
    hold(ax, 'off');
    xlim(ax, [min(velocityAxis), max(velocityAxis)]);
    ylim(ax, [min(-rangeBin), max(rangeBin)*3.5]);
    xlabel(ax, 'Velocity (m/s)');
    ylabel(ax, 'Range (m)');
    title(ax, 'Kalman Filtering');
    %ax.YTick = [];
end
