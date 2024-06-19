clc; clear; close all;

comPort = 'COM13'; % 데이터 포트
baudRate = 115200; 

s = serialport(comPort, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

bufferSize = 21; % 모든 필드를 포함하기 위한 버퍼 크기
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
        
        % 필드 추출 및 구조체 저장
        params.version = typecast(uint8(dataBuffer(1:2)), 'uint16');             % uint16_t version
        params.headerSize = typecast(uint8(dataBuffer(3:4)), 'uint16');          % uint16_t headerSize
        params.platform = dataBuffer(5);                                  % uint8_t platform
        params.interleavedMode = dataBuffer(6);                           % uint8_t interleavedMode
        params.dataSize = dataBuffer(7);                                  % uint8_t dataSize
        params.dataType = dataBuffer(8);                                  % uint8_t dataType
        params.rxChannelStatus = dataBuffer(9);                           % uint8_t rxChannelStatus
        params.dataFmt = dataBuffer(10);                                  % uint8_t dataFmt
        params.chirpMode = typecast(uint8(dataBuffer(11:12)), 'uint16');         % uint16_t chirpMode
        params.adcDataSize = typecast(uint8(dataBuffer(13:14)), 'uint16');       % uint16_t adcDataSize
        params.cpDataSize = typecast(uint8(dataBuffer(15:16)), 'uint16');        % uint16_t cpDataSize
        params.cqDataSize = typecast(uint8(dataBuffer(17:18)), 'uint16');        % uint16_t cqDataSize
        params.userBufSize = typecast(uint8(dataBuffer(19:20)), 'uint16');       % uint16_t userBufSize
        params.appExtensionHeader = dataBuffer(21);                       % uint8_t appExtensionHeader
        
        % 구조체 출력
        disp('Extracted Parameters:');
        disp(params);
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

clear s;
