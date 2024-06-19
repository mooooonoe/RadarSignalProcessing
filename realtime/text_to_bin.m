textFilePath = 'adcRawData.txt';  % 변환할 텍스트 파일 경로
binFilePath = 'adcRawData.bin';   % 저장할 이진 파일 경로

% 텍스트 파일을 읽습니다.
fid = fopen(textFilePath, 'r');
if fid == -1
    error('텍스트 파일을 열 수 없습니다.');
end
textData = fread(fid, '*char')';
fclose(fid);

% 텍스트 데이터를 이진 데이터로 변환합니다.
binaryData = uint8(textData);

% 이진 파일로 저장합니다.
fid = fopen(binFilePath, 'wb');
if fid == -1
    error('이진 파일을 열 수 없습니다.');
end
fwrite(fid, binaryData, 'uint8');
fclose(fid);
