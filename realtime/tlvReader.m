% 사용자로부터 포트 입력 받기
comport = input('mmWave: Auxiliary Data port (Demo output DATA_port) = ', 's');

% 시리얼 포트 열기
ser = serialport(comport, 921600);

% 데이터 사전 초기화
data_dict = struct();

while true
    % 버퍼에 있는 바이트 수 확인
    byteCount = ser.NumBytesAvailable;

    if byteCount == 0
        continue;
    end

    % 바이트 스트링 읽기
    byte_str = read(ser, byteCount, 'uint8');

    % 프레임 시작을 찾기 위한 매직 워드
    magicWord = uint8([2 1 4 3 6 5 8 7]);
    start_index = find(byte_str == magicWord(1), 1);

    if isempty(start_index) || length(byte_str) < start_index + length(magicWord) - 1
        continue;
    end

    if ~isequal(byte_str(start_index:start_index+length(magicWord)-1), magicWord)
        continue;
    end

    % 프레임 헤더 추출 (44 바이트)
    if length(byte_str) < start_index + 44
        continue;
    end

    frame_header = byte_str(start_index:start_index + 44);

    % 프레임 헤더를 10진수 값으로 변환
    frame_header_values = double(frame_header);
    disp('Frame Header Decimal values:');
    disp(frame_header_values);

    % 프레임 헤더의 추가 처리
    version = typecast(uint8(frame_header(9:12)), 'uint32');
    total_packet_length = typecast(uint8(frame_header(13:16)), 'uint32');
    platform = typecast(uint8(frame_header(17:20)), 'uint32');
    frame_number = typecast(uint8(frame_header(21:24)), 'uint32');
    time_cpu_cycles = typecast(uint8(frame_header(25:28)), 'uint32');
    num_detected_obj = typecast(uint8(frame_header(29:32)), 'uint32');
    num_tlvs = typecast(uint8(frame_header(33:36)), 'uint32');
    subframe_number = typecast(uint8(frame_header(37:40)), 'uint32');

    % 파싱된 프레임 헤더 값 출력
    fprintf('Total Packet Length: %d\n', total_packet_length);
    fprintf('Frame Number: %d\n', frame_number);
    fprintf('Number of TLVs: %d\n', num_tlvs);

    tlv_type = typecast(uint8(frame_header(41:44)), 'uint32');
    tlv_length = typecast(uint8(frame_header(45:48)), 'uint32');
    tlv_value = typecast(uint8(frame_header(49:52)), 'uint32'); % 데이터 길이를 조정하세요

    fprintf('TLV Type: %d\n', tlv_type);
    fprintf('TLV Length: %d\n', tlv_length);
    fprintf('TLV Value: %d\n', tlv_value);
end
