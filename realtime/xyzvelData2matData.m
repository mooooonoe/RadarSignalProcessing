file_path = 'data_file.txt';

fileID = fopen(file_path, 'r');
data = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);
% 
% xy_values = [];

% for i = 1:numel(data{1})
%     frame_info = strsplit(data{1}{i}, {'Frame Number: ', 'Number of Detected Objects: ', 'detObj: {'});
%     frame_number = str2double(frame_info{2});
% 
%     xy_start_index = strfind(data{1}{i}, 'x:');
%     xy_end_index = strfind(data{1}{i}, 'dtype');
%     xy_str = data{1}{i}(xy_start_index+4:xy_end_index-3);
%     xy_values_cell = strsplit(xy_str, ', ');
%     xy_values_frame = [];
%     for j = 1:numel(xy_values_cell)
%         xy_values_frame(j) = str2double(xy_values_cell{j});
%     end
% 
%     xy_values = [xy_values; xy_values_frame];
% end
% 
% disp(xy_values);

%origVel

%function parseData(data)
    p = [];
    origdata = data{1,1,1};
    for k =1:length(origdata)
        C = strsplit(data{k});
        if strcmp(C{1}, 'Frame Number')
            p.Frame_number = str2num(C{3});
        elseif strcmp(C{1}, ' Number of Detected Objects')
            p.Detect_num = str2num(C{3});
        elseif strcmp(C{1}, 'detObj')
            p.DetObj = str2num(C{3});
                % if strcmp(p.DetObj, 'numObj')
                %     objnum = str2num(p.DetObj(C{2}));
                %     origVel(k) = zeros(objnum);
                % end
        end
    end
%end

file_path = 'data_file.txt';

fileID = fopen(file_path, 'r');
data = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);
% 
% origdata = data{1,1,1};
% str = origdata{1};
% 
% startIndex = strfind(str, 'Frame Number: ') + length('Frame Number: ');
% endIndex = strfind(str, '}') - 1;
% frameNumberStr = str(startIndex:endIndex);
% 
% frameNumber = str2double(frameNumberStr);
% myStruct.FrameNumber = frameNumber;
% disp(myStruct);

% 문자열 정의
origdata = data{1,1,1};

for k = 1:length(origdata)
    str = origdata{k};
        if sscanf(str,)
end



% 숫자 부분 추출
frameNumber = sscanf(str, 'Frame Number: %d');

% 구조체 정의
Frame_number.data = frameNumber;

% 결과 출력
disp(Frame_number);