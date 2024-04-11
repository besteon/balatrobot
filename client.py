
# WIP

import socket
import sys
import signal

def signal_handler(signal, frame):
    sys.exit(0)

def is_socket_closed(sock: socket.socket):
    try:
        data = sock.recv(16, socket.MSG_DONTWAIT | socket.MSG_PEEK)
        if len(data) == 0:
            return True
    except BlockingIOError:
        return False
    except ConnectionResetError:
        return True
    except Exception as e:
        return False
    return False

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.settimeout(1.0)

    addr = ("127.0.0.1", 12345)

    client_socket.sendto(b'SEND_GAMESTATE', addr)

    running = True
    while running:
        
        try:
            data, addr = client_socket.recvfrom(1024)
            print(data.decode())
        except:
            print('Request Timed Out')

        running = False

