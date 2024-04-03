clear, clc, close all;
%% PORT

comUartPortNum = 10;
comDataPortNum = 9;
BUFFER_MAX_SIZE = 2^16;

if ~isempty(instrfind('Type','serial'))
    disp('Serial port(s) already open. Re-initializing...');
    delete(instrfind('Type','serial'));  % delete open serial ports.
end

%hControlSerialPort = configureControlPort(comUartPortNum);

    comPortString = ['COM' num2str(comUartPortNum)];
    hControlSerialPort = serial(comPortString,'BaudRate',921600);
    set(hControlSerialPort,'Terminator', '');
    set(hControlSerialPort,'InputBufferSize', BUFFER_MAX_SIZE);
    set(hControlSerialPort,'Timeout',10);
    set(hControlSerialPort,'ErrorFcn',@dispError);
    set(hControlSerialPort,'BytesAvailableFcnMode','byte');
    set(hControlSerialPort,'BytesAvailableFcnCount', BUFFER_MAX_SIZE+1);%BYTES_AVAILABLE_FCN_CNT);
    set(hControlSerialPort,'BytesAvailableFcn',@readUartCallbackFcn);
    fopen(hControlSerialPort);

%hDataSerialPort = configureDataPort(comDataPortNum, BUFFER_MAX_SIZE);
    
    comPortString = ['COM' num2str(comDataPortNum)];
    hDataSerialPort = serial(comPortString,'BaudRate',115200);
    set(hDataSerialPort,'Parity','none')
    set(hDataSerialPort,'Terminator','LF')
    fopen(hDataSerialPort);

%% PORT Update Handles
handles.DATACOM.hDataSerialPort = hDataSerialPort;
handles.UARTCOM.hControlSerialPort = hControlSerialPort;

%% CFG FILE OPEN

pathname = 'C:/Users/DCLAB/Documents/MATLAB/radar/realtime/';
filename = 'ods_default_config.cfg';

configurationFileName = [pathname filename];
handles.cfg.filename = configurationFileName;


if (filename ~= 0)
    cliCfg = cell(1,100);
    fid = fopen(filename, 'r');
    if fid == -1
        fprintf('File %s not found', filename);
        return;
    else
        fprintf('Opening configuration file %s ... \n', filename);
    end

    tline = fgetl(fid);
    k=1;
    while ischar(tline)
        cliCfg{k} = tline;
        tline = fgetl(fid);
        k = k + 1;
    end
    cliCfg = cliCfg(1:k-1);
    fclose(fid);

    [Params cliCfg] = parseCfg(cliCfg);

    % % Display chirp table
    % hTable = findobj('Tag', 'uitableChirp');
    % hTable = displayChirpParams(Params, hTable);

    handles.cfg.cliCfg = cliCfg;
    handles.params = Params;

    %guidata(hObject,handles)
end

%% cfg2Board
if (length(instrfind('Type','serial', 'Status','open'))>=2 && ~isempty(handles.UARTCOM.hControlSerialPort) && ~isempty(handles.DATACOM.hDataSerialPort))

    %load Cfg Params
    mmwDemoCliPrompt = char('mmwDemo:/>');

    %Send CLI configuration to board
    fprintf('Sending configuration from %s file to board ...\n', handles.cfg.filename);

    for k=1:length(handles.cfg.cliCfg)
        command = handles.cfg.cliCfg{k};
        fprintf(handles.UARTCOM.hControlSerialPort, command);
        fprintf('%s\n', command);
        echo = fgetl(handles.UARTCOM.hControlSerialPort); % Get an echo of a command
        done = fgetl(handles.UARTCOM.hControlSerialPort); % Get "Done"
        prompt = fread(handles.UARTCOM.hControlSerialPort, size(mmwDemoCliPrompt,2)); % Get the prompt back
    end
    %fclose(handles.UARTCOM.hControlSerialPort);
    %delete(hControlSerialPort);

    plots_OutputFcn(hObject,eventdata,guidata(hObject));
    uiresume(handles.figureViz);

else
    warndlg('Error: Can not start COM ports not connected. Please select and connect.');
end

%% read function 
function [P cliCfg] = parseCfg(cliCfg)
    global TOTAL_PAYLOAD_SIZE_BYTES
    global MAX_NUM_OBJECTS
    global OBJ_STRUCT_SIZE_BYTES
    %global platformType
    global STATS_SIZE_BYTES
    
        P=[];
        for k=1:length(cliCfg)
            C = strsplit(cliCfg{k});
            if strcmp(C{1},'channelCfg')
                P.channelCfg.txChannelEn = str2num(C{3});

                P.dataPath.numTxAzimAnt = 1;
                P.dataPath.numTxElevAnt = 1;

                P.channelCfg.rxChannelEn = str2num(C{2});
                P.dataPath.numRxAnt = bitand(bitshift(P.channelCfg.rxChannelEn,0),1) +...
                                      bitand(bitshift(P.channelCfg.rxChannelEn,-1),1) +...
                                      bitand(bitshift(P.channelCfg.rxChannelEn,-2),1) +...
                                      bitand(bitshift(P.channelCfg.rxChannelEn,-3),1);
                P.dataPath.numTxAnt = P.dataPath.numTxElevAnt + P.dataPath.numTxAzimAnt;
    
            elseif strcmp(C{1},'dataFmt')
            elseif strcmp(C{1},'profileCfg')
                P.profileCfg.startFreq = str2num(C{3});
                P.profileCfg.idleTime =  str2num(C{4});
                P.profileCfg.rampEndTime = str2num(C{6});
                P.profileCfg.freqSlopeConst = str2num(C{9});
                P.profileCfg.numAdcSamples = str2num(C{11});
                P.profileCfg.digOutSampleRate = str2num(C{12}); %uints: ksps
            elseif strcmp(C{1},'chirpCfg')
            elseif strcmp(C{1},'frameCfg')
                P.frameCfg.chirpStartIdx = str2num(C{2});
                P.frameCfg.chirpEndIdx = str2num(C{3});
                P.frameCfg.numLoops = str2num(C{4});
                P.frameCfg.numFrames = str2num(C{5});
                P.frameCfg.framePeriodicity = str2num(C{6});
            elseif strcmp(C{1},'guiMonitor')
                P.guiMonitor.detectedObjects = str2num(C{2});
                P.guiMonitor.clusters = str2num(C{3});
                P.guiMonitor.rangeAzimuthHeatMap = str2num(C{4});
                P.guiMonitor.rangeElevHeatMap = str2num(C{5});
            elseif strcmp(C{1},'dbscanCfg')
                P.dbScan.nAccFrames = str2num(C{2});
                P.dbScan.epsilon = str2num(C{3});
                P.dbScan.weight = str2num(C{4});
                P.dbScan.vFactor = str2num(C{5});
                P.dbScan.minPointsInCluster = str2num(C{6});
                P.dbScan.fixedPointScale = str2num(C{7});
            elseif strcmp(C{1},'cfarCfg')
                P.cfarCfg.detectMethod = str2num(C{2});
                P.cfarCfg.leftSkipBin = str2num(C{3});
                P.cfarCfg.closeInRangeBin = str2num(C{4});
                P.cfarCfg.searchWinSizeRange = str2num(C{5});
                P.cfarCfg.guardSizeRange = str2num(C{6});
                P.cfarCfg.searchWinSizeSpreading = str2num(C{7});
                P.cfarCfg.guardSizeSpreading = str2num(C{8});
                P.cfarCfg.rangeThresh = str2num(C{9});
                P.cfarCfg.fftSpreadingThresh = str2num(C{10});
                P.cfarCfg.noiseCalcType = str2num(C{11});
                P.cfarCfg.localPeakEnable = str2num(C{12});
                P.cfarCfg.peakAngleDiffThresh = str2num(C{13});
                P.cfarCfg.maxRangeForDetection = str2num(C{14}) * 0.1;
            end
        end
        P.dataPath.numChirpsPerFrame = (P.frameCfg.chirpEndIdx -...
                                                P.frameCfg.chirpStartIdx + 1) *...
                                                P.frameCfg.numLoops;
        P.dataPath.numDopplerBins = P.dataPath.numChirpsPerFrame / P.dataPath.numTxAnt;

        P.dataPath.rangeResolutionMeters = 3e8 * P.profileCfg.digOutSampleRate * 1e3 /...
                         (2 * P.profileCfg.freqSlopeConst * 1e12 * P.profileCfg.numAdcSamples);
        P.dataPath.numRangeBins = round(P.cfarCfg.maxRangeForDetection / P.dataPath.rangeResolutionMeters, 0);
        P.dataPath.rangeBinsPerMeter = P.dataPath.numRangeBins / P.cfarCfg.maxRangeForDetection;

        P.dataPath.rangeIdxToMeters = 3e8 * P.profileCfg.digOutSampleRate * 1e3 /...
                         (2 * P.profileCfg.freqSlopeConst * 1e12 * P.dataPath.numRangeBins);
        P.dataPath.dopplerResolutionMps = 3e8 / (2*P.profileCfg.startFreq*1e9 *...
                                            (P.profileCfg.idleTime + P.profileCfg.rampEndTime) *...
                                            1e-6 * P.dataPath.numDopplerBins * P.dataPath.numTxAnt);
        P.dataPath.maxRange = 300 * 0.9 * P.profileCfg.digOutSampleRate /(2 * P.profileCfg.freqSlopeConst * 1e3);
        P.dataPath.maxVelocity = 3e8 / (4*P.profileCfg.startFreq*1e9 *(P.profileCfg.idleTime + P.profileCfg.rampEndTime) * 1e-6 * P.dataPath.numTxAnt);

        %Calculate monitoring packet size
        tlSize = 8 %TL size 8 bytes
        TOTAL_PAYLOAD_SIZE_BYTES = 40; % size of header
        P.guiMonitor.numFigures = 1; %One figure for numerical parameers
        if P.guiMonitor.detectedObjects == 1 && P.guiMonitor.rangeAzimuthHeatMap == 1
            TOTAL_PAYLOAD_SIZE_BYTES = TOTAL_PAYLOAD_SIZE_BYTES +...
                OBJ_STRUCT_SIZE_BYTES*MAX_NUM_OBJECTS + tlSize;
            P.guiMonitor.numFigures = P.guiMonitor.numFigures + 1; %1 plots: X/Y plot
        end
        if P.guiMonitor.detectedObjects == 1 && P.guiMonitor.rangeElevHeatMap ~= 1
            TOTAL_PAYLOAD_SIZE_BYTES = TOTAL_PAYLOAD_SIZE_BYTES +...
                OBJ_STRUCT_SIZE_BYTES*MAX_NUM_OBJECTS + tlSize;
            P.guiMonitor.numFigures = P.guiMonitor.numFigures + 2; %2 plots: X/Y plot and Y/Doppler plot
        end
        if P.guiMonitor.clusters == 1
            TOTAL_PAYLOAD_SIZE_BYTES = TOTAL_PAYLOAD_SIZE_BYTES +...
                P.dataPath.numRangeBins * 2 + tlSize;
            P.guiMonitor.numFigures = P.guiMonitor.numFigures + 1;
        end
        if P.guiMonitor.rangeAzimuthHeatMap == 1
            TOTAL_PAYLOAD_SIZE_BYTES = TOTAL_PAYLOAD_SIZE_BYTES +...
                (P.dataPath.numTxAzimAnt * P.dataPath.numRxAnt) * P.dataPath.numRangeBins * 4 + tlSize;
            P.guiMonitor.numFigures = P.guiMonitor.numFigures + 1;
        end
        if P.guiMonitor.rangeElevHeatMap == 1
            TOTAL_PAYLOAD_SIZE_BYTES = TOTAL_PAYLOAD_SIZE_BYTES +...
                P.dataPath.numDopplerBins * P.dataPath.numRangeBins * 2 + tlSize;
            P.guiMonitor.numFigures = P.guiMonitor.numFigures + 1;
        end

        TOTAL_PAYLOAD_SIZE_BYTES = 32 * floor((TOTAL_PAYLOAD_SIZE_BYTES+31)/32);
        P.guiMonitor.numFigRow = 2;
        P.guiMonitor.numFigCol = ceil(P.guiMonitor.numFigures/P.guiMonitor.numFigRow);
        [P.dspFftScaleComp2D_lin, P.dspFftScaleComp2D_log] = dspFftScalCompDoppler(16, P.dataPath.numDopplerBins)
        [P.dspFftScaleComp1D_lin, P.dspFftScaleComp1D_log]  = dspFftScalCompRange(64, P.dataPath.numRangeBins)

        P.dspFftScaleCompAll_lin = P.dspFftScaleComp2D_lin * P.dspFftScaleComp1D_lin;
        P.dspFftScaleCompAll_log = P.dspFftScaleComp2D_log + P.dspFftScaleComp1D_log;
    
    return
end


function [sLin, sLog] = dspFftScalCompDoppler(fftMinSize, fftSize)
    sLin = fftMinSize/fftSize;
    sLog = 20*log10(sLin);
return
end

function [sLin, sLog] = dspFftScalCompRange(fftMinSize, fftSize)
    smin =  (2.^(ceil(log2(fftMinSize)./log2(4)-1)))  ./ (fftMinSize);
    sLin =  (2.^(ceil(log2(fftSize)./log2(4)-1)))  ./ (fftSize);
    sLin = sLin / smin;
    sLog = 20*log10(sLin);
return
end

