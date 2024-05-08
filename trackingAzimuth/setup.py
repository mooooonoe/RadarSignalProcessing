import codecs
import socket
import struct
from enum import Enum
import numpy as np

class CMD(Enum):
    RESET_FPGA_CMD_CODE = '0100'
    RESET_AR_DEV_CMD_CODE = '0200'
    CONFIG_FPGA_GEN_CMD_CODE = '0300'
    CONFIG_EEPROM_CMD_CODE = '0400'
    RECORD_START_CMD_CODE = '0500'
    RECORD_STOP_CMD_CODE = '0600'
    PLAYBACK_START_CMD_CODE = '0700'
    PLAYBACK_STOP_CMD_CODE = '0800'
    SYSTEM_CONNECT_CMD_CODE = '0900'
    SYSTEM_ERROR_CMD_CODE = '0a00'
    CONFIG_PACKET_DATA_CMD_CODE = '0b00'
    CONFIG_DATA_MODE_AR_DEV_CMD_CODE = '0c00'
    INIT_FPGA_PLAYBACK_CMD_CODE = '0d00'
    READ_FPGA_VERSION_CMD_CODE = '0e00'

    def __str__(self):
        return str(self.value)

CONFIG_HEADER = '5aa5'
CONFIG_STATUS = '0000'
CONFIG_FOOTER = 'aaee'

ADC_PARAMS = {
    'chirps': 128,
    'rx': 4,
    'tx': 3,
    'samples': 128,
    'IQ': 2,
    'bytes': 2
}

MAX_PACKET_SIZE = 4096
BYTES_IN_PACKET = 1456

BYTES_IN_FRAME = (ADC_PARAMS['chirps'] * ADC_PARAMS['rx'] * ADC_PARAMS['tx'] *
                  ADC_PARAMS['IQ'] * ADC_PARAMS['samples'] * ADC_PARAMS['bytes'])
BYTES_IN_FRAME_CLIPPED = (BYTES_IN_FRAME // BYTES_IN_PACKET) * BYTES_IN_PACKET
PACKETS_IN_FRAME = BYTES_IN_FRAME / BYTES_IN_PACKET
PACKETS_IN_FRAME_CLIPPED = BYTES_IN_FRAME // BYTES_IN_PACKET
UINT16_IN_PACKET = BYTES_IN_PACKET // 2
UINT16_IN_FRAME = BYTES_IN_FRAME // 2

class DCA1000:
    def __init__(self, static_ip='192.168.33.30', adc_ip='192.168.33.180',
                 data_port=4098, config_port=4096):
        self.cfg_dest = (adc_ip, config_port)
        self.cfg_recv = (static_ip, config_port)
        self.data_recv = (static_ip, data_port)
        self.config_socket = socket.socket(socket.AF_INET,
                                           socket.SOCK_DGRAM,
                                           socket.IPPROTO_UDP)
        self.data_socket = socket.socket(socket.AF_INET,
                                         socket.SOCK_DGRAM,
                                         socket.IPPROTO_UDP)
        self.data_socket.bind(self.data_recv)
        self.config_socket.bind(self.cfg_recv)
        self.data = []
        self.packet_count = []
        self.byte_count = []
        self.frame_buff = []
        self.curr_buff = None
        self.last_frame = None
        self.lost_packets = None

    def configure(self):
        print(self._send_command(CMD.SYSTEM_CONNECT_CMD_CODE))
        print(self._send_command(CMD.READ_FPGA_VERSION_CMD_CODE))
        print(self._send_command(CMD.CONFIG_FPGA_GEN_CMD_CODE, '0600', 'c005350c0000'))
        print(self._send_command(CMD.CONFIG_PACKET_DATA_CMD_CODE, '0600', 'c005350c0000'))

    def close(self):
        self.data_socket.close()
        self.config_socket.close()

    def read(self, timeout=1):
        self.data_socket.settimeout(timeout)
        ret_frame = np.zeros(UINT16_IN_FRAME, dtype=np.uint16)
        while True:
            packet_num, byte_count, packet_data = self._read_data_packet()
            if byte_count % BYTES_IN_FRAME_CLIPPED == 0:
                packets_read = 1
                ret_frame[0:UINT16_IN_PACKET] = packet_data
                break
        while True:
            packet_num, byte_count, packet_data = self._read_data_packet()
            if byte_count % BYTES_IN_FRAME_CLIPPED == 0:
                self.lost_packets = PACKETS_IN_FRAME_CLIPPED - packets_read
                return ret_frame
            curr_idx = ((packet_num - 1) % PACKETS_IN_FRAME_CLIPPED)
            try:
                ret_frame[curr_idx * UINT16_IN_PACKET:(curr_idx + 1) * UINT16_IN_PACKET] = packet_data
            except:
                pass
            if packets_read > PACKETS_IN_FRAME_CLIPPED:
                packets_read = 0

    def _send_command(self, cmd, length='0000', body='', timeout=1):
        self.config_socket.settimeout(timeout)
        resp = ''
        msg = codecs.decode(''.join((CONFIG_HEADER, str(cmd), length, body, CONFIG_FOOTER)), 'hex')
        try:
            self.config_socket.sendto(msg, self.cfg_dest)
            resp, addr = self.config_socket.recvfrom(MAX_PACKET_SIZE)
        except socket.timeout as e:
            print(e)
        return resp

    def _read_data_packet(self):
        data, addr = self.data_socket.recvfrom(MAX_PACKET_SIZE)
        packet_num = struct.unpack('<1l', data[:4])[0]
        byte_count = struct.unpack('>Q', b'\x00\x00' + data[4:10][::-1])[0]
        packet_data = np.frombuffer(data[10:], dtype=np.uint16)
        return packet_num, byte_count, packet_data

    def _listen_for_error(self):
        self.config_socket.settimeout(None)
        msg = self.config_socket.recvfrom(MAX_PACKET_SIZE)
        if msg == b'5aa50a000300aaee':
            print('stopped:', msg)

    def _stop_stream(self):
        return self._send_command(CMD.RECORD_STOP_CMD_CODE)
