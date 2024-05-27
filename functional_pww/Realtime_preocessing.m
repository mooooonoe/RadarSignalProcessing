%% 실시간 신호처리

% cliCfg: 내가 cfg file에 저장한 값
% supported_cfgs: 필요한 cfg 값

%% GET User Inputs & Setup Options
% close all;
delete(instrfind);
SETUP_VIA_GUI = 1;
ANTENNA_TYPE = 1; %Hardcoded b/c only ISK/BOOST style currently supported.
if(SETUP_VIA_GUI)
    hApp = setup_tm();
    
else 
    % Manual/programmatic entry
    REAL_TIME_MODE = 0; %1 for from device 0 for playback from dat file
    ENABLE_RECORD = 0;
    datFile.path = 'C:\Users\dnjsd\radar_signal_processing_config';
    datFile.name = 'tm_demo_uart_stream.txt';
    logFile.path = 'C:\Users\dnjsd\radar_signal_processing_config';
    logFile.name = ['tm_demo_log_' datestr(now,'mmddyy_HHMM') '.dat'];
    offset.height = 2;
    offset.az = 0;
    offset.el = -20;
    comPort.cfg = 4;
    comPort.data = 5;
    comPort.status = 0;
    
    lanes.enable = 0;
end

offset.az = offset.az*-1; %flipping since transformations assume CCW is + direction

%% Set up file to record
if(ENABLE_RECORD && REAL_TIME_MODE)
    
    if(~isempty(logFile.path))
        % append slash if needed
        if(logFile.path(end)~='\' && logFile.path(end)~='/')
            logFile.path(end+1) = '\';
        end
        status = mkdir(logFile.path);
    else
        status = 1;
    end
    if(status)
        fid = fopen([logFile.path logFile.name],'w+');
    end
    if fid~= -1
        fprintf(['Opening ' logFile.name '. Ready to log data. \n']);
    else
        fprintf('Error with log file name or path. No logging. \n');
        ENABLE_RECORD = 0;
    end
else
    fid = -1;
    ENABLE_RECORD = 0;
end

%% Read Config

%config parameter
% cfgFile.path = 'C:\Users\dnjsd\radar_signal_processing_config\';
% cfgFile.name = '18xx_traffic_monitoring_70m_MIMO_3D.cfg'; % <-- 파일 이름에 .cfg 무조건 들어가야함.
try 
    [cliCfg] = demo_readCfgFile([cfgFile.path cfgFile.name]);
catch ME
    fprintf('Error: Could not open CFG file. Quitting.');
    if(ENABLE_RECORD)
        fclose(fid);
    end
    return;
end

%% Define supported CLI commands
% 내꺼 sdkVersion은 '03.05.00.04'
sdkVersion = '03.06.00.00'; %TODO read this from device
demoType = 'TM';
[supported_cfgs] = demo_defineCLICommands(sdkVersion,demoType);

%% parseCLICommands2Struct
[P] = demo_parseCLICommands2Struct(cliCfg, supported_cfgs);


%% calculateChirpParams
calc_P = demo_calculateChirpParams(P);

%% initDataPort & initCfgPort

% instrfind 연결 끊는거 delete(instrfind);

if(REAL_TIME_MODE)

[hCfgPort] = demo_initCfgPort(comPort.cfg);
[hDataPort] = demo_initDataPort(comPort.data);

 %Check Port Status
    if(comPort.status == 0) %Unknown status
        % 둘 다 데이터가 있을 때 실행
        if(hCfgPort ~= -1 && hDataPort ~=-1)
            % COM이 열린 상태일 때
            if(hDataPort.BytesAvailable)
                %TODO: remove warning when config reload w/o NRST is enabled
                comPort.status = -1;
                fprintf('Device appears to already be running. Will not be able to load a new configuration. To load a new config, press NRST on the EVM and try again.');    
            % 보통 여기 실행
            else       
                fprintf(hCfgPort, 'version');
                pause(0.5); % adding some delay to make sure bytes are received
                response = '';
            
                if(hCfgPort.BytesAvailable)
                    for i=1:5 % version command reports back 10 lines TODO: change if SDK changes response
                        hCfgPort.BytesAvailable; % 얼마씩 들어가는 지 확인용
                        rstr = fgets(hCfgPort);
                        response = join(response, rstr);
                    end
                    fprintf('Test successful: CFG Port Opened & Data Received');
                    comPort.status = 1;
                else
                    fprintf('Port opened but no response received. Check port # and SOP mode on EVM');
                    comPort.status = -2;
                    fclose(hDataPort);
                    fclose(hCfgPort);
                end
            end
        else
            comPort.status = -2;
            fprintf('Could not open ports. Check port # and that EVM is powered with correct SOP mode.');    
        end
     
   else %REPLAY MODE
    
    %Load Data file
    end
end

%% Set flags based on COM port status
global RUN_VIZ;
if(~REAL_TIME_MODE)
    RUN_VIZ = 1;
    LOAD_CFG = 0;
elseif(comPort.status == 1)
    LOAD_CFG = 1;
    RUN_VIZ = 1;
elseif(comPort.status == -1)
    LOAD_CFG = 0;
    RUN_VIZ = 1;
else
    RUN_VIZ = 0;
    LOAD_CFG = 0;
end
    

%% Load Config
if(LOAD_CFG) 
   load_Cfg = demo_loadCfg(hCfgPort, cliCfg);
end

% if(RUN_VIZ)
%% INIT Figure 밑에 더 존재하는데 uart 통신 부터 하고 진행
SHOW_PT_CLOUD = 1;
SHOW_TRACKED_OBJ = 1;
SHOW_STATS = 1;
SHOW_LANES = lanes.enable;

% 이름이 Traffic Monitoring Visualizer V2.0.1인 figure을 열고 닫을 때 진짜 나갈 건 지 물어봄.
hFig = figure('Name', 'Traffic Monitoring Visualizer V2.0.1','Color','white','CloseRequestFcn',@demo_plotfig_closereq);

% init plot axes
maxRange = max([calc_P.rangeMax_m]);
[hFig, hAx3D] = demo_init3DPlot_TM(hFig,[-maxRange maxRange],[0 maxRange], [0 offset.height]);



%% Pre-compute transformation matrix
rotMat_az = [cosd(offset.az) -sind(offset.az) 0; sind(offset.az) cosd(offset.az) 0; 0 0 1];
rotMat_el = [1 0 0; 0 cosd(offset.el) -sind(offset.el); 0 sind(offset.el) cosd(offset.el)];
transMat = rotMat_az*rotMat_el;


%% main - parse UART and update plots
% initial setup
if(REAL_TIME_MODE)
    bytesBuffer = zeros(1,hDataPort.InputBufferSize);
    bytesBufferLen = 0;
    isBufferFull = 0;
    READ_MODE = 'FIFO';
else
    % read in entire file 
    [bytesBuffer, bytesBufferLen, bytesAvailableFlag] = readDATFile2Buffer([datFile.path datFile.name], 'hex_dat');
    READ_MODE = 'ALL';
    [allFrames, bytesBuffer, bytesBufferLen, numFramesAvailable,validFrame] = parseBytes_TM(bytesBuffer, bytesBufferLen, READ_MODE);
    hFrameSlider.Max = numFramesAvailable;
    hFrameSlider.SliderStep = [1 10].*1/(hFrameSlider.Max-hFrameSlider.Min);
end


while (RUN_VIZ)    
    % get bytes from UART buffer or DATA file
    if(REAL_TIME_MODE)
        %                                                                        function (spDataHandle, bytesBuffer, bytesBufferLen, ENABLE_LOG, fid)
        [bytesBuffer, bytesBufferLen, isBufferFull, bytesAvailableFlag] = demo_readUARTtoBuffer(hDataPort, bytesBuffer, bytesBufferLen, ENABLE_RECORD, fid);
         % parse bytes to frame
        [newframe, bytesBuffer, bytesBufferLen, numFramesAvailable,validFrame] = demo_parseBytes_TM(bytesBuffer, bytesBufferLen, READ_MODE);
        frameIndex = 1;
    else
        frameIndex = round(hFrameSlider.Value);
        newframe = allFrames(frameIndex);
    end



 if(validFrame(frameIndex))
        statsString = {['Frame: ' num2str(newframe.header.frameNumber)], ['Num Frames in Buffer: ' num2str(numFramesAvailable)]}; %reinit stats string each new frame
        if(1)

            % set frame flags
            HAVE_VALID_PT_CLOUD = ~isempty(newframe.detObj) && newframe.detObj.numDetectedObj ~= 0;
            HAVE_VALID_TARGET_LIST = ~isempty(newframe.targets);
            
            if(SHOW_PT_CLOUD)            
                if(HAVE_VALID_PT_CLOUD)
                    % Pt cloud hasn't been transformed based on offset TODO: move transformation to device
                    rotatedPtCloud = transMat * [newframe.detObj.x; newframe.detObj.y; newframe.detObj.z;];
                    hPtCloud.XData = rotatedPtCloud(1,:);
                    hPtCloud.YData = rotatedPtCloud(2,:);
                    hPtCloud.ZData = rotatedPtCloud(3,:)+offset.height; 

                else
                    hPtCloud.XData = [];
                    hPtCloud.YData = [];
                    hPtCloud.ZData = [];
                end
            end

            if(SHOW_TRACKED_OBJ)
                if(HAVE_VALID_TARGET_LIST)
                    numTargets = numel(newframe.targets.tid);
                    if(numTargets > 0)
                        %Tracker coordinates have been transformed by
                        %azimuth rotation but not elevation.
                        %TODO: Add elevation rotation and height
                        %offset on device
                        rotatedTargets = rotMat_el * [newframe.targets.posX; newframe.targets.posY; newframe.targets.posZ;];
                        hTrackObj.XData = rotatedTargets(1,:);
                        hTrackObj.YData = rotatedTargets(2,:);
                        hTrackObj.ZData = rotatedTargets(3,:)+offset.height;
                        delete(hTrackObjLabel);
                        hTrackObjLabel = text(hAx3D,hTrackObj.XData,hTrackObj.YData,...
                            hTrackObj.ZData ,arrayfun(@(x) {num2str(x)}, newframe.targets.tid),...
                            'FontSize',10,'HorizontalAlignment','center','VerticalAlignment','middle');
                        
                    else
                        delete(hTrackObjLabel);
                        hTrackObjLabel = [];
                        hTrackObj.XData = [];
                        hTrackObj.YData = [];
                        hTrackObj.ZData = [];  
                    end
                else
                        delete(hTrackObjLabel);
                        hTrackObj.XData = [];
                        hTrackObj.YData = [];
                        hTrackObj.ZData = [];  
                end
            end

            if(SHOW_LANES)
                numInLane = zeros(1,lanes.numLanes);
                if(HAVE_VALID_TARGET_LIST)
                    % Check whether targets are in a lane
                    for i=1:lanes.numLanes
                        xMin = min(hLanes(i).XData);
                        xMax = max(hLanes(i).XData);
                        yMin = min(hLanes(i).YData);
                        yMax = max(hLanes(i).YData);
                        numInLane(i) = nnz((hTrackObj.XData >= xMin) & (hTrackObj.XData < xMax) & (hTrackObj.YData >= yMin) & (hTrackObj.YData < yMax));
                        
                    end                    
                end
                
                %Update count labels in plot
                for i=1:lanes.numLanes
                    hLaneLabels(i).String = num2str(numInLane(i));
                end     
            end
            
            if(SHOW_STATS)
               if(HAVE_VALID_PT_CLOUD)
                   statsString{end+1} = ['Pt Cloud: ' num2str(newframe.detObj.numDetectedObj)];
               else
                    statsString{end+1} = ['Pt Cloud: '];
               end
                              
               if(HAVE_VALID_TARGET_LIST)
                   statsString{end+1} = ['Num Tracked Obj: ' num2str(numTargets)];
               else
                   statsString{end+1} = ['Num Tracked Obj: '];
               end
               
               % update string
               hStats.String = statsString;
            end 
            

            
        end % have validFrame
        if(REAL_TIME_MODE)
            drawnow limitrate
        else
            drawnow
            if(RUN_VIZ && hPlayControl.Value == 2 && hFrameSlider.Value+1<=hFrameSlider.Max)
                hFrameSlider.Value = hFrameSlider.Value+1;
            end
        end
    else % have data in newFrame
    end


end



