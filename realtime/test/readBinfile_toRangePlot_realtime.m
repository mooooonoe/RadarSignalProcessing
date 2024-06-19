clc; clear; close all;

filename = 'tlv_value2.bin';

numADCSamples = 256; % number of ADC samples per chirp
numADCBits = 16; % number of ADC bits per sample
numRX = 4; % number of receivers
numLanes = 2; % do not change. number of lanes is always 2
isReal = 0; % set to 1 if real only data, 0 if complex data0

prevFileSize = 0;
figure();

try
    while true
        fileInfo = dir(filename);
        if isempty(fileInfo)
            disp('파일을 찾을 수 없습니다.');
            break;
        end
        currentFileSize = fileInfo.bytes;

        if currentFileSize > prevFileSize
            fileID = fopen(filename, 'rb');

            if fileID == -1
                error('파일을 열 수 없습니다.');
            end

            fseek(fileID, prevFileSize, 'bof');
            
            newDataSize = currentFileSize - prevFileSize;
            adcData = fread(fileID, newDataSize, 'int16');
            
            fprintf('파일에서 새로 읽은 데이터: ');
            fprintf('%d ', adcData);
            fprintf('\n');

            % Range Profile
            if numADCBits ~= 16
                l_max = 2^(numADCBits-1)-1;
                adcData(adcData > l_max) = adcData(adcData > l_max) - 2^numADCBits;
            end
            fileSize = size(adcData, 1);
            % real data reshape, filesize = numADCSamples*numChirps
            if isReal
                numChirps = fileSize/numADCSamples/numRX;
                LVDS = zeros(1, fileSize);
                %create column for each chirp
                LVDS = reshape(adcData, numADCSamples*numRX, numChirps);
                %each row is data from one chirp
                LVDS = LVDS.';
            else
                % for complex data
                % filesize = 2 * numADCSamples*numChirps
                numChirps = fileSize/2/numADCSamples/numRX;
                LVDS = zeros(1, fileSize/2);
                %combine real and imaginary part into complex data
                %read in file: 2I is followed by 2Q
                counter = 1;
                for i=1:4:fileSize-1
                LVDS(1,counter) = adcData(i) + sqrt(-1)*adcData(i+2);
                LVDS(1,counter+1) = adcData(i+1)+sqrt(-1)*adcData(i+3);
                counter = counter + 2;
                end
            end
            
            currChDataQ = real(LVDS(:));
            currChDataI = imag(LVDS(:));

            plotupdate(currChDataQ, currChDataI);
            drawnow;
                        

            % 이전 파일 크기를 업데이트합니다
            prevFileSize = currentFileSize;
            
            % 파일을 닫습니다
            fclose(fileID);
            currentFileSize = 0;
            prevFileSize = 0;
        end

        % CPU 과부하를 막기 위해 잠시 대기
        java.lang.Thread.sleep(100);
    end
catch ME
    disp('파일 읽기 오류.');
    disp(ME.message);
end

function plotupdate(currChDataQ, currChDataI)
    plot(currChDataI(:));
    hold on;
    plot(currChDataQ(:));
    xlabel('time (seconds)');                  
    ylabel('ADC time domain output');        
    title('Time Domain Output');
    hold off;
    grid on;
end