
# WIP

import socket

if __name__ == "__main__":
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.settimeout(1.0)

    addr = ("127.0.0.1", 12345)

