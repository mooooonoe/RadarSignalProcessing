clc; clear; close all;

comPort = 'COM13'; % data port
baudRate = 921600; 

s = serialport(comPort, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

bufferSize = 16; 
frameCount = 0;
adcRawData.data = {}; % 초기화

disp('Reading data from serial port...');
dataOneFrame = [];
going = true;
cnt = 0;

% 파일 열기
fileID = fopen('adcRawData.txt', 'w');

while going
    try
        cnt = cnt+1;
        dataBuffer = read(s, bufferSize, 'uint8');
        dataOneFrame = [dataOneFrame; dataBuffer];
        % 데이터를 행렬로 변환하여 저장
        frameCount = frameCount + 1;
        adcRawData.data{frameCount} = dataBuffer;
        
        dataHex = dec2hex(dataBuffer);

        fprintf('Received Data (Hex): ');
        for i = 1:bufferSize
            fprintf('%s ', dataHex(i, :));
            % 파일에 데이터 쓰기
            fprintf(fileID, '%s ', dataHex(i, :));
        end
        fprintf(fileID, '\n');
        
        disp(adcRawData.data{frameCount});
        fprintf('\n');
        disp(cnt);
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
    if length(dataOneFrame(:,1)) == 32768
        going = false;
    else
        going = true;
    end
end

% 파일 닫기
fclose(fileID);

clear s;
