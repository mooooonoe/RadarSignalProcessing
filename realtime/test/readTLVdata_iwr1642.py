import serial

comport = input("mmWave: Auxiliary Data port (Demo output DATA_port) = ")

ser = serial.Serial(comport, 921600)

ser.isOpen()

data_dict = {}

cnt = 1
while cnt:
    
    byteCount = ser.inWaiting() 
    byte_str = ser.read(byteCount)

    if not byte_str:
        continue
    
    # Find the start of the frame using the magic word
    magicWord = b'\x02\x01\x04\x03\x06\x05\x08\x07'
    start_index = byte_str.find(magicWord)

    if start_index == -1:
        continue

    # Extract the frame header (44 bytes)
    if len(byte_str) < start_index + 44:
        continue

    frame_header = byte_str[start_index:start_index + 44 +100000]

    # Convert frame header to decimal values for easier interpretation
    frame_header_values = [int(byte) for byte in frame_header]
    # print("Frame Header Decimal values:", frame_header_values)
    
    # Further processing of the frame header
    version = int.from_bytes(frame_header[8:12], 'little')
    total_packet_length = int.from_bytes(frame_header[12:16], 'little')
    platform = int.from_bytes(frame_header[16:20], 'little')
    frame_number = int.from_bytes(frame_header[20:24], 'little')
    time_cpu_cycles = int.from_bytes(frame_header[24:28], 'little')
    num_detected_obj = int.from_bytes(frame_header[28:32], 'little')
    num_tlvs = int.from_bytes(frame_header[32:36], 'little')
    subframe_number = int.from_bytes(frame_header[36:40], 'little')

    # Print the parsed frame header values
    print(f"Total Packet Length: {total_packet_length}")
    print(f"Frame Number: {frame_number}")
    print(f"Number of TLVs: {num_tlvs}")

    type = int.from_bytes(frame_header[40:44], 'little')
    length = int.from_bytes(frame_header[44:48], 'little')
    value = int.from_bytes(frame_header[48:500], 'little')
    
    print(f"tlv type: {type}")
    print(f"tlv lenth: {length}")
    print(f"tlv value: {value}")
    cnt = cnt-1
