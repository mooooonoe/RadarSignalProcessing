clc; clear; close all;

comPort = 'COM13'; % 데이터 포트
baudRate = 115200;

s = serialport(comPort, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

bufferSize = 1024; % 버퍼 크기
dataBuffer = zeros(1, bufferSize, 'uint8');

% 두 개의 헤더 ID
headerID1 = [0x0C, 0xDA, 0x0A, 0xDC, 0x0C, 0xDA, 0x0A, 0xDC];
headerID2 = [0x09, 0xCC, 0x0C, 0xC9, 0x09, 0xCC, 0x0C, 0xC9];

disp('Reading data from serial port...');

while true
    try
        % 데이터 읽기
        dataBuffer = read(s, bufferSize, 'uint8');
        
        % 데이터 출력 (16진수 형식)
        dataHex = dec2hex(dataBuffer);
        for i = 1:bufferSize
            fprintf('%s ', dataHex(i, :));
        end
        fprintf('\n');
        
        % 헤더 ID 감지
        for i = 1:(bufferSize - length(headerID1) + 1)
            if all(dataBuffer(i:i + length(headerID1) - 1) == headerID1) || all(dataBuffer(i:i + length(headerID2) - 1) == headerID2)
                disp('hi header!');
                break;
            end
        end
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

clear s;
