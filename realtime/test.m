% MATLAB Code

% Prompt user for the COM port
comport = input('mmWave:Auxillary Data port (Demo output DATA_port) = ', 's');

% Set the baud rate
baudRate = 921600;

% Open the serial port
ser = serialport(comport, baudRate);

% Define the magic word
magicWord = [2, 1, 4, 3, 6, 5, 8, 7];

while true
    % Check the number of bytes available
    byteCount = ser.NumBytesAvailable;
    
    if byteCount > 0
        % Read the available bytes
        byte_str = read(ser, byteCount, 'uint8');
        
        % Convert to row vector for find function
        byte_str = byte_str(:)';
        
        % Find the starting index of the magic word
        start_index = strfind(byte_str, magicWord);
        
        if ~isempty(start_index)
            % Extract packet data starting from the magic word
            packet_data = byte_str(start_index(1):end);
            
            % Convert packet data to decimal values
            decimal_values = double(packet_data);
            
            % Display the packet decimal values
            disp('Packet Decimal values:');
            disp(decimal_values);
        end
    end
end
