clc; clear; close all;

filename = 'tlv_value2.bin';

prevFileSize = 0;

try
    while true
        % 파일 크기를 확인합니다
        fileInfo = dir(filename);
        if isempty(fileInfo)
            disp('파일을 찾을 수 없습니다.');
            break;
        end
        currentFileSize = fileInfo.bytes;

        if currentFileSize > prevFileSize
            % 파일을 읽기 모드로 엽니다
            fileID = fopen(filename, 'rb');

            if fileID == -1
                error('파일을 열 수 없습니다.');
            end

            % 마지막 읽기 위치로 이동
            fseek(fileID, prevFileSize, 'bof');
            
            % 마지막 읽기 위치에서 파일 끝까지 새 데이터를 읽습니다
            newDataSize = currentFileSize - prevFileSize;
            newData = fread(fileID, newDataSize, 'uint8');
            
            % 데이터 한 줄로 출력
            fprintf('파일에서 새로 읽은 데이터: ');
            fprintf('%d ', newData);
            fprintf('\n');
            
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
