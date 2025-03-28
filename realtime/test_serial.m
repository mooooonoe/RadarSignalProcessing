clc; clear; close all;

comPort = 'COM13'; % data port
baudRate = 115200; 

s = serialport(comPort, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

bufferSize = 16; 
frameCount = 0;
adcRawData.data = {}; % 초기화

disp('Reading data from serial port...');

while true
    try
        dataBuffer = read(s, bufferSize, 'uint8');
        
        % 데이터를 행렬로 변환하여 저장
        frameCount = frameCount + 1;
        adcRawData.data{frameCount} = dataBuffer;
        
        dataHex = dec2hex(dataBuffer);
        
        fprintf('Received Data (Hex): ');
        for i = 1:bufferSize
            fprintf('%s ', dataHex(i, :));
        end
        
        disp(adcRawData.data{frameCount});
        fprintf('\n');
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

clear s;
