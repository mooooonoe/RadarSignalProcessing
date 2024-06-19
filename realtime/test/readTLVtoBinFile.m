clc; clear; close all;

% Prompt user for COM port input
comport = input('mmWave: Auxiliary Data port (Demo output DATA_port) = ', 's');

% Set up serial communication
baudRate = 115200;
s = serialport(comport, baudRate);

configureTerminator(s, "LF");
s.Timeout = 10;

% Initialize a map to store data
data_dict = containers.Map();

cnt = 1;
while cnt
    % Check number of bytes available in the serial buffer
    byteCount = s.NumBytesAvailable;
    if byteCount == 0
        pause(0.01); % small pause to prevent CPU overload
        continue;
    end

    % Read bytes from the serial buffer
    byte_str = read(s, byteCount, 'uint8');

    % Find the start of the frame using the magic word
    magicWord = [2 1 4 3 6 5 8 7];
    start_index = strfind(byte_str', magicWord);

    if isempty(start_index)
        continue;
    end

    start_index = start_index(1);

    % Extract the frame header (44 bytes)
    if length(byte_str) < start_index + 44
        continue;
    end

    frame_header = byte_str(start_index:start_index + 44 - 1);

    % Convert frame header to decimal values for easier interpretation
    frame_header_values = double(frame_header);
    % disp("Frame Header Decimal values:");
    % disp(frame_header_values);

    % Further processing of the frame header
    version = typecast(uint8(frame_header(9:12)), 'uint32');
    total_packet_length = typecast(uint8(frame_header(13:16)), 'uint32');
    platform = typecast(uint8(frame_header(17:20)), 'uint32');
    frame_number = typecast(uint8(frame_header(21:24)), 'uint32');
    time_cpu_cycles = typecast(uint8(frame_header(25:28)), 'uint32');
    num_detected_obj = typecast(uint8(frame_header(29:32)), 'uint32');
    num_tlvs = typecast(uint8(frame_header(33:36)), 'uint32');
    subframe_number = typecast(uint8(frame_header(37:40)), 'uint32');

    % Print the parsed frame header values
    fprintf('Total Packet Length: %d\n', total_packet_length);
    fprintf('Frame Number: %d\n', frame_number);
    fprintf('Number of TLVs: %d\n', num_tlvs);

    % Ensure there are enough bytes for TLV processing
    if length(byte_str) < start_index + total_packet_length
        continue;
    end

    % Read TLV data
    for i = 1:num_tlvs
        tlv_start = start_index + 44 + (i - 1) * 8;
        tlv_type = typecast(uint8(byte_str(tlv_start:tlv_start+3)), 'uint32');
        tlv_length = typecast(uint8(byte_str(tlv_start+4:tlv_start+7)), 'uint32');
        tlv_value_start = tlv_start + 8;
        tlv_value = byte_str(tlv_value_start:tlv_value_start+tlv_length-1);

        fprintf('TLV Type: %d\n', tlv_type);
        fprintf('TLV Length: %d\n', tlv_length);
        fprintf('TLV Value: %s\n', num2str(tlv_value'));

        % Save the TLV value to a .bin file
        fileID = fopen('endtlv_value2.bin', 'wb');
        fwrite(fileID, tlv_value, 'uint8');
        fclose(fileID);
    end

    cnt = cnt - 1;


% Close the serial port
clear s;
