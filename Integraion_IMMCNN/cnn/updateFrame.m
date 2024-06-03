function updateFrame(estPos, result, x_radar_filtered, y_radar_filtered)
    
    
    figure();
    plot(estPos(1,:), estPos(2,:), '-m', 'LineWidth', 1.5);
    
    
    for value = 1: length(estPos)
        updatePlot(value, estPos, result, x_radar_filtered, y_radar_filtered);
        pause(0.003);
    end
    
    function updatePlot(value, estPos, result, x_radar_filtered, y_radar_filtered)
            plotestPos(value, estPos, result); 
            hold on;
            plotsensorVal(value, x_radar_filtered, y_radar_filtered);
            hold off;
            legend('IMM-filtered-tracking', 'Radar Sensor Value');
    
            drawnow;
    end
    
    
    function plotestPos(value, estPos, result)
        plot(estPos(1,value), estPos(2,value), '.b','MarkerSize', 10, 'LineWidth', 5);
        outputString = sprintf("object : %s \n(Score: %.1f%%)", result{1, value}, result{2, value});
        text(estPos(1,value), estPos(2,value), outputString, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center');
        xlim([-3, 3]);
        ylim([0, 12]);
    end
    
    function plotsensorVal(value, x_radar_filtered, y_radar_filtered)
        plot(x_radar_filtered(value), y_radar_filtered(value), '.r', 'MarkerSize', 10, 'LineWidth', 5);
        xlim([-3, 3]);
        ylim([0, 12]);
        xlabel('X (m)');
        ylabel('Y (m)');
        title('IMM Filtering');
    end
end