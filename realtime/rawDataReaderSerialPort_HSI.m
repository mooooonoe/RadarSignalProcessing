clc; clear; close all;

comPort = 'COM13'; % 데이터 포트
baudRate = 115200; 

s = serialport(comPort, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

bufferSize = 16; 
dataBuffer = zeros(1, bufferSize, 'uint8'); 

disp('Reading data from serial port...');

while true
    try
        dataBuffer = read(s, bufferSize, 'uint8');
        
        dataHex = dec2hex(dataBuffer);
        
        % 데이터 출력 (16진수 형식)
        for i = 1:bufferSize
            fprintf('%s ', dataHex(i, :));
        end
        fprintf('\n');
        
        % dataSize 필드 추출
        % uint8_t dataSize는 6번째 필드로 가정 (오프셋 5)
        dataSize = dataBuffer(6);
        fprintf('Extracted dataSize: %d\n', dataSize);
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

clear s;
