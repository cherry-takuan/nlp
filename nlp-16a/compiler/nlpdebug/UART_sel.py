#!/usr/bin/env python3
import sys
import serial
from serial.tools import list_ports

def select_port(baud=115200,timeout=2):
        ser = serial.Serial()
        ser.baudrate = baud
        ser.timeout = timeout       # タイムアウトの時間
        ports = list_ports.comports()    # ポートデータを取得
        devices = [info.device for info in ports]
        if len(devices) == 0:
            # シリアル通信できるデバイスが見つからなかった場合
            print("Error: Port not found",file=sys.stderr)
            exit(1)
        else:
            # 複数ポートの場合、選択
            for i in range(len(devices)):
                print(f"input {i:d} open {devices[i]}",file=sys.stderr)
            print("Please enter the port number:",end="",file=sys.stderr)
            num = int(input())
            if num >= len(devices):
                print("存在しません",file=sys.stderr)
                exit(1)
            ser.port = devices[num]
        
        # 開いてみる
        try:
            ser.open()
            ser.close()
            print(devices[num])
        except:
            print("Error：The port could not be opened.",file=sys.stderr)
            exit(1)
        exit(0)
if __name__ == '__main__':
     select_port()