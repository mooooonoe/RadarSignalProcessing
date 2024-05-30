clc; clear; close all;

comPort = 'COM13'; % data port
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
        
        %fprintf('Received Data (Hex): ');
        for i = 1:bufferSize
            fprintf('%s ', dataHex(i, :));
        end
        fprintf('\n');
        
    catch ME
        disp('Error reading data or converting values.');
        disp(ME.message);
        break;
    end
end

clear s;
