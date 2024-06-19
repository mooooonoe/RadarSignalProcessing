% Prompt user for COM port input
comport = input('mmWave: Auxiliary Data port (Demo output DATA_port) = ', 's');

% Set up serial communication
baudRate = 921600;
ser = serial(comport, 'BaudRate', baudRate, 'Terminator', 'LF');
fopen(ser);

% Initialize a buffer for the incoming data
buffer = [];

% Magic word to find the start of the frame
magicWord = [2 1 4 3 6 5 8 7];

cnt = 1;
while cnt
    % Check number of bytes available in the serial buffer
    byteCount = ser.BytesAvailable;
    if byteCount == 0
        pause(0.01); % small pause to prevent CPU overload
        continue;
    end

    % Read bytes from the serial buffer
    byte_str = fread(ser, byteCount, 'uint8');

    % Append the newly read bytes to the buffer
    buffer = [buffer; byte_str];

    % Find the start of the frame using the magic word
    start_index = strfind(buffer', magicWord);

    if isempty(start_index)
        continue;
    end

    start_index = start_index(1);

    % Extract the frame header (44 bytes)
    if length(buffer) < start_index + 44
        continue;
    end

    frame_header = buffer(start_index:start_index + 512);

    % Convert frame header to decimal values for easier interpretation
    frame_header_values = double(frame_header);
    
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

    type = typecast(uint8(frame_header(41:44)), 'uint32');
    length = typecast(uint8(frame_header(45:48)), 'uint32');
    value = frame_header(49:48+length);
    
    fprintf('TLV Type: %d\n', type);
    fprintf('TLV Length: %d\n', length);
    fprintf('TLV Value: %s\n', num2str(value'));

    % Here you can directly process the 'value' without saving to a file
    % For example, perform some signal processing
    % signalProcessingFunction(value);

    % Remove the processed frame from the buffer
    buffer = buffer(start_index + total_packet_length:end);

    cnt = cnt - 1;
end

% Close the serial port
fclose(ser);
delete(ser);
clear ser;
