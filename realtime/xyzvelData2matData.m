% 텍스트 파일 경로 설정
file_path = 'data_file.txt';

% 파일 열기
fileID = fopen(file_path, 'r');

% 변수 초기화
frame_numbers = [];
detected_objects = [];
det_objs = struct();

% 데이터 처리
frame_idx = 0;
while ~feof(fileID)
    tline = fgetl(fileID);
    if startsWith(tline, 'Frame Number:')
        frame_number = sscanf(tline, 'Frame Number: %d');
        frame_numbers = [frame_numbers; frame_number];
        frame_idx = frame_idx + 1;
    elseif startsWith(tline, 'Number of Detected Objects:')
        num_detected_obj = sscanf(tline, 'Number of Detected Objects: %d');
        detected_objects = [detected_objects; num_detected_obj];
    elseif startsWith(tline, 'detObj:')
        det_obj_str = tline(length('detObj:')+1:end);
        det_obj = eval(det_obj_str);
        det_objs(frame_idx).numObj = det_obj.numObj;
        det_objs(frame_idx).x = det_obj.x;
        det_objs(frame_idx).y = det_obj.y;
        det_objs(frame_idx).z = det_obj.z;
        det_objs(frame_idx).velocity = det_obj.velocity;
    end
end

% 파일 닫기
fclose(fileID);

% 결과 출력
disp(frame_numbers);
disp(detected_objects);
disp(det_objs);

% 결과를 저장할 수도 있습니다.
save('parsed_data.mat', 'frame_numbers', 'detected_objects', 'det_objs');
