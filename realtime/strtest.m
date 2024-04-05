file_path = 'data_file_orig.txt';

fileID = fopen(file_path, 'r');
data = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);

origdata = data{1,1,1};
numLines = length(origdata);

Frames(numLines) = struct('FrameNumber', [], 'objNum', [], 'coordinate', []);

for i = 1:numLines
    Frames(i).FrameNumber = 0;
    Frames(i).objNum = 0;
    Frames(i).coordinate = [];
end

cnt = 0;
cntkLines = 0;
numLinesf = 0;

for k = 1:numLines

    str = origdata{k};
    velocity_idx = strfind(str, 'velocity');
    array_idx = strfind(str, 'array');
    
    if startsWith(str, 'Frame Number:')
        numLinesf = k;
        cntkLines= 1;
        cnt = cnt + 1;
        Frames(cnt).FrameNumber = sscanf(str, 'Frame Number: %d');
        objNum_idx = strfind(str, 'detObj:') + length('detObj:');
        Frames(cnt).objNum = sscanf(str(objNum_idx:end), '%d', 1);
        Frames(cnt).coordinate = zeros(Frames(cnt).objNum, 2);
    elseif numLinesf < k && k <= Frames(cnt).objNum + numLinesf
        strsp = split(str);

        Frames(cnt).coordinate(cntkLines,1) = str2double(strsp{1});
        Frames(cnt).coordinate(cntkLines,2) = str2double(strsp{2});
        cntkLines = cntkLines + 1;
    end
end

figure;
hold on;
for i = 1:cnt
    coords = Frames(i).coordinate;
    plot(coords(:, 1), coords(:, 2), 'o');
end

hold off; 

xlabel('X coordinate');
ylabel('Y coordinate');
title('Plot of XY coordinates for all frames');