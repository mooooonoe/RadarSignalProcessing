clear;
%% Radar connect
tiradar = mmWaveRadar("TI AWR1843BOOST",ConfigPort = "COM10", DataPort = "COM9");

%% config file 
installDir = matlabshared.supportpkg.getSupportPackageRoot;
tiradarCfgFileDir = fullfile(installDir,'toolbox','target', 'supportpackages', 'timmwaveradar', 'configfiles');
tiradar.ConfigFile = fullfile(tiradarCfgFileDir, 'xwr18xx_BestRangeResolution_UpdateRate_10.cfg');

%% Azimuth 
tiradar.AzimuthLimits = [-60 60];
tiradar.DetectionCoordinates = "Sensor rectangular";

% Create figure and other graphic objects to view the detections and range profile
fig = figure('Name','Radar Data', 'WindowState','maximized','NumberTitle','off');
tiledlayout(fig,2,2);

% Create handle to scatter plot and initialize its properties for plotting detections
ax1 = nexttile;
scatterPlotHandle = scatter(ax1,0,0,'filled','yellow');
ax1.Title.String = 'Scatter plot - Object position';
ax1.XLabel.String = 'x (m)';
ax1.YLabel.String = 'y (m)';
% Update the xlimits, ylimits and nPoints as per the scenario and Radar properties
% Y-axis limits for the scatter plot
yLimits = [0,tiradar.MaximumRange];
% X-axis limits for the scatter plot
xLimits = [-tiradar.MaximumRange/2,tiradar.MaximumRange/2];
% Number of tick marks in x and y axis in the scatter plot
nPoints = 10;
ylim(ax1,yLimits);
yticks(ax1,linspace(yLimits(1),yLimits(2),nPoints))
xlim(ax1,xLimits);
xticks(ax1,linspace(xLimits(1),xLimits(2),nPoints));
set(ax1,'color',[0.1 0.2 0.9]);
grid(ax1,'on')

% Create text handle to print the number of detections and time stamp
ax2 = nexttile([2,1]);
blnkspaces = blanks(1);
txt = ['Number of detected objects: ','Not available',newline newline,'Timestamp: ','Not available'];
textHandle = text(ax2,0.1,0.5,txt,'Color','black','FontSize',20);
axis(ax2,'off');

% Create plot handle and initialize properties for plotting range profile
ax3 = nexttile();
rangeProfilePlotHandle = plot(ax3,0,0,'blue');
ax3.Title.String = 'Range Profile for zero Doppler';
ax3.YLabel.String = 'Relative-power (dB)';
ax3.XLabel.String = 'Range (m)';
xLimits = [0,tiradar.MaximumRange];

yLimits = [0,250];
% Number of tick marks in x axis in the Range profile plot
nPoints = 30;
ylim(ax3,yLimits);
xlim(ax3,xLimits);
xticks(ax3,linspace(xLimits(1),xLimits(2),nPoints));

%% Read Radar Measurements (50s) 
% Read radar measurements in a loop and plot the measurements for for 50s (specified by stopTime)
ts = tic;
stopTime = 50;
while(toc(ts)<=stopTime)
    % Read detections and other measurements from TI mmWave Radar
    [objDetsRct,timestamp,meas,overrun] = tiradar();
    % Get the number of detections read
    numDets = numel(objDetsRct);
    % Print the timestamp and number of detections in plot
    txt = ['Number of detected objects: ', num2str(numDets),newline newline,'Timestamp: ',num2str(timestamp),'s'];
    textHandle.String = txt;
    % Detections will be empty if the output is not enabled or if no object is
    % detected. Use number of detections to check if detections are available
    if numDets ~= 0
        % Detections are reported as cell array of objects of type objectDetection
        % Extract  x-y position information from each objectDetection object
        xpos = zeros(1,numDets);
        ypos = zeros(1,numDets);
        for i = 1:numel(objDetsRct)
            xpos(i) = objDetsRct{i}.Measurement(1);
            ypos(i) = objDetsRct{i}.Measurement(2);
        end
        [scatterPlotHandle.XData,scatterPlotHandle.YData] = deal(ypos,xpos);
    end
    % Range profile will be empty if the log magnitude range output is not enabled
    % via guimonitor command in config File
    if ~isempty(meas.RangeProfile)
        [rangeProfilePlotHandle.XData,rangeProfilePlotHandle.YData] = deal(meas.RangeGrid,meas.RangeProfile);
    end
    drawnow limitrate;
end
clear tiradar;