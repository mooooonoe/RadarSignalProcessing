import socket
import threading

HOST = 'localhost'
PORT = 5555

def handle_client(client_socket):
    while True:
        data = client_socket.recv(1024)
        if not data:
            break
        
        print("[받은 데이터]:", data.decode('utf-8'))

        client_socket.sendall(data)

    client_socket.close()

def main():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((HOST, PORT))
    server_socket.listen(5)

    print("[서버] 클라이언트 연결 대기 중...")

    while True:
        # 클라이언트 연결 받기
        client_socket, addr = server_socket.accept()
        print("[서버] 연결됨:", addr)

        # 클라이언트 핸들링을 위한 스레드 생성
        client_handler = threading.Thread(target=handle_client, args=(client_socket,))
        client_handler.start()

if __name__ == "__main__":
    main()