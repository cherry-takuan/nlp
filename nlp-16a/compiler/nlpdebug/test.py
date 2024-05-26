#!/usr/bin/env python3

import nlp_debug
from time import sleep
import random
import sys
import serial
from serial.tools import list_ports
def port_open(dev):
        ser = serial.Serial()
        ser.baudrate = 9600
        ser.timeout = 30       # タイムアウトの時間
        ser.port = dev
        # 開いてみる
        try:
            ser.open()
            return ser
        except:
            print("Error：The port could not be opened.",file=sys.stderr)
            exit(1)

if __name__ == '__main__':
    args = sys.argv
    if len(args)!=3:
        exit(1)
    debug = nlp_debug.debugger(dev=args[1])
    test_data = sys.stdin.read().split(",")
    program_data = list()
    for data in test_data:
         if len(data) != 4:
              break
         program_data.append(int(data,base=16))

    debug.reset()
    id = debug.scan_devides()
    if id != 3:
        del debug
        exit()
    
    DATA = 0x00
    ADDRESS = 0x01
    CTRL = 0x02

    WR = 0b0010
    RD = 0b0001
    CPU_ADDR = 0b0100
    RS = 0b1000

    print("CTRL DIR_SET",file=sys.stderr)
    debug.dir_set(CTRL,0xFFFF)
    print("DATA DIR_SET",file=sys.stderr)
    debug.dir_set(DATA,0x0000)
    debug.execute(DATA,"REVERSE_MODE",0x0001)
    print("ADDRESS CTRL DIR_SET",file=sys.stderr)
    debug.dir_set(ADDRESS,0x0000)
    debug.execute(ADDRESS,"REVERSE_MODE",0x0001)
    
    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*1)
    sleep(1)
    #dmy = input("Ready?")
    print("Sending...",file=sys.stderr)
    debug.dir_set(ADDRESS,0xFFFF)
    for now_address in range(len(program_data)):
        debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*1)
        
        debug.output(ADDRESS,now_address)
        
        debug.dir_set(DATA,0xFFFF)
        debug.output(DATA,program_data[now_address])
        debug.output(CTRL,WR*1 | RD*0 | CPU_ADDR*1 | RS*1)
        debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*1)

        debug.dir_set(DATA,0x0000)
        debug.output(CTRL,WR*0 | RD*1 | CPU_ADDR*1 | RS*1)
        value = debug.input(DATA)
        debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*1)
        if value != program_data[now_address]:
            print("Error ",end="",file=sys.stderr)
            print("{:04x}".format(now_address),"\t:\t","{:04x}".format(value),"{:04x}".format(program_data[now_address]),file=sys.stderr)
            del debug
            exit(1)
        sleep(0.005)
    print("Done",file=sys.stderr)
    debug.dir_set(DATA,0x0000)

    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*1)
    debug.dir_set(ADDRESS,0x0000)
    debug.dir_set(DATA,0x0000)
    sleep(0.1)
    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*0 | RS*1)
    sleep(0.1)
    #dmy = input("Run")
    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*0 | RS*0)
    #dmy = input("Running...(stop : enter key)")
    test_dev = port_open(args[2])
    print("Running...",file=sys.stderr)
    val =  test_dev.read()
    result = int.from_bytes(val,"little")
    test_dev.close()
    print(result)
    del debug