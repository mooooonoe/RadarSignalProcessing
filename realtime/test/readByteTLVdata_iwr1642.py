import serial

comport = input("mmWave:Auxillary Data port (Demo output DATA_port) = ")

ser = serial.Serial(comport, 921600)

ser.isOpen()

magicWord = [2, 1, 4, 3, 6, 5, 8, 7]

while True:
    byteCount = ser.inWaiting()
    byte_str = ser.read(byteCount)

    if not byte_str:
        continue

    start_index = byte_str.find(bytes(magicWord))

    if start_index == -1:
        continue

    packet_data = byte_str[start_index:]

    decimal_values = [int(byte) for byte in packet_data]

    print("Packet Decimal values:", decimal_values)
