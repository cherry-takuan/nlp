import sys
#sys.path.append("/home/cherry/.local/lib/python2.7/site-packages")
import serial
from serial.tools import list_ports
from time import sleep


def select_port(baudrate=19200):
    ser = serial.Serial()
    ser.baudrate = baudrate    
    ser.timeout = 2       # タイムアウトの時間
    ports = list_ports.comports()    # ポートデータを取得
    devices = [info.device for info in ports]
    if len(devices) == 0:
        # シリアル通信できるデバイスが見つからなかった場合
        print("Error: Port not found")
        return None
    else:
        # 複数ポートの場合、選択
        for i in range(len(devices)):
            print(f"input {i:d} open {devices[i]}")
        num = int(input("Please enter the port number:" ))
        ser.port = devices[num]
    
    # 開いてみる
    try:
        ser.open()
        return ser
    except:
        print("Error：The port could not be opened.")
        return None