import serial_ctrl

import random

from time import sleep
mode_table = {
    "ID_SET":0x00,
    "DIR_GET":0x01,
    "DIR_SET":0x02,
    "IO_SET":0x03,
    "IN_GET":0x04,
    "OUT_GET":0x05,
    "RESET":0x0F
}
TO_ALL = 0xFE
TO_MASTER = 0xFF

def serial_start():
    ser = serial_ctrl.select_port(baudrate=115200)
    if ser == None:
        return 0
    print("Please wait...")
    sleep(3)
    ser.reset_input_buffer()
    #消すな
    return ser
def execute(ser,to_id,mode,value):
    count = 0
    while(count < 5):
        #sleep(0.1)
        instruction = "{:0>2X}-{:0>2X}-{:0>4X}\n".format(to_id,mode_table[mode],value)
        ser.write(instruction.encode('ascii'))
        line = ser.readline()
        line_disp=line.strip().decode('UTF-8')
        #print("inst\t:",instruction[:-1])
        #print("raw\t:",line_disp)
        #print("mode\t:",int(line_disp[3:5],16),line_disp[3:5])
        #print("value\t:",int(line_disp[6:10],16),line_disp[6:10])
        #print("send\t:",instruction[:-1],", result:",line_disp)
        #print()
        try:
            result_id = int(line_disp[0:2],16)
            result_mode = int(line_disp[3:5],16)
            result_value = int(line_disp[6:10],16)
        except Exception as e:
            print("Execute error(",count,") : ",e)
            print("###################")
            print("send\t:",instruction[:-1])
            print("raw\t:",line_disp)
            print()
            sleep(1)
            count+=1
        else:
            return result_id,result_mode,result_value

def device_status(ser,id,bus_mode=False):
    bus = ""
    if bus_mode == True:
        bus="|"
    dir_id,dir_mode,dir_value = execute(ser,id,"DIR_GET",0x0000)
    if dir_id != TO_MASTER:
        print("Error : 指定されたデバイスから応答がありません．")
        return
    in_id,in_mode,in_value = execute(ser,id,"IN_GET",0x0000)
    if in_id != TO_MASTER:
        print("Error : 指定されたデバイスから応答がありません．")
        return
    out_id,out_mode,out_value = execute(ser,id,"OUT_GET",0x0000)
    if out_id != TO_MASTER:
        print("Error : 指定されたデバイスから応答がありません．")
        return
    
    print("    +-------------------------------+    "+bus)
    print("    | slave:{:0>2X}                  ok  |    ".format(id)+bus)
    print("    |  ---------------------------  |    "+bus)
    print("    |F E D C B A 9 8 7 6 5 4 3 2 1 0|    "+bus)
    #入出力方向
    msg = "DIR |"
    for num in reversed(range(0x10)):
        if dir_value & (1<<num) == 0:
            msg += "\033[41mI\033[0m "
        else:
            msg += "\033[44mO\033[0m "
    msg = msg[0:-1] + "|    "+bus
    print(msg)
    #入力状態
    msg = "IN  |"
    for num in reversed(range(0x10)):
        if in_value & (1<<num) == 0:
            msg += "\033[41mL\033[0m "
        else:
            msg += "\033[44mH\033[0m "
    msg = msg[0:-1] + "|    "+bus
    print(msg)
    #出力状態
    msg = "OUT |"
    for num in reversed(range(0x10)):
        if out_value & (1<<num) == 0:
            msg += "\033[41mL\033[0m "
        else:
            msg += "\033[44mH\033[0m "
    msg = msg[0:-1] + "|    "+bus
    print(msg)


    print("    +-------------------------------+    "+bus)

def scan_devides(ser):
    result_id,result_mode,result_value =  execute(ser,TO_ALL,"ID_SET",0x00)
    if result_mode != mode_table["ID_SET"]:
        return -1
    print("Device:",result_value)
    print("    +-------------------------------+")
    print("    | master                        | <--+")
    print("    +-------------------------------+    |")
    print("                     |                   |")
    print("                     |                   |")
    for num in range(result_value):
        device_status(ser,num,bus_mode=True)
        print("                     |                   |")
    print("                     |                   |")
    print("                     +-------------------+")
    return result_value


def Num_normalize(num):
    if num < 0:
        num = -num
        num = ~num
        num = num & 0xFFFF
        num += 1
    return num

if __name__ == '__main__':
    ser = serial_start()

    execute(ser,TO_ALL,"RESET",0x0000)
    id = scan_devides(ser)
    if id != 3:
        ser.close()
        exit()
    
    CTRL = 0x02
    ADDRESS = 0x01
    DATA = 0x00

    RAM_FUNC = {
        "HOID" : 0x100,
        "HOID_IN" : 0x08,
        "CE" : 0x04,
        "OE" : 0x02,
        "WE" : 0x01,
    }
    print("CTRL DIR_SET")
    execute(ser,CTRL,"DIR_SET",0x0000)
    print("HOID WAIT...")
    while True:
        id, mode, value = execute(ser,CTRL,"IN_GET",0x0000)
        if value & RAM_FUNC["HOID_IN"] != 0:
            break

    print("CTRL DIR_SET")
    execute(ser,CTRL,"DIR_SET",0x00FF)
    execute(ser,CTRL,"IO_SET", RAM_FUNC["CE"]*1 + RAM_FUNC["OE"]*1 + RAM_FUNC["WE"]*1 + RAM_FUNC["HOID"]*1)
    
    print("ADDRESS_BUS DIR_SET")
    execute(ser,ADDRESS,"DIR_SET",0xFFFF)
    print("DATA_BUS DIR_SET")
    execute(ser,DATA,"DIR_SET",0x0000)

    device_status(ser,CTRL)
    device_status(ser,ADDRESS)
    device_status(ser,DATA)
    
    failed = 0
    pass_num = 0
    failed_list = list()

    program = [
        0x3E,        0x00,
        0xD3,        0x00,
        0xC6,        0x01,
        0xC3,        0x02,        0x00,
    ]

    for count in range(len(program)):
        test_address = count
        test_data = program[count]
        #RAMを3ステートに設定
        execute(ser,CTRL,"IO_SET",RAM_FUNC["CE"]*0 + RAM_FUNC["OE"]*1 + RAM_FUNC["WE"]*1 + RAM_FUNC["HOID"]*1)
        #アドレス値を設定
        execute(ser,ADDRESS,"IO_SET",test_address)
        #データバスを出力モードに
        execute(ser,DATA,"DIR_SET",0xFFFF)
        #テストデータを出力
        execute(ser,DATA,"IO_SET",test_data)
        #RAMをWRITEモードに
        execute(ser,CTRL,"IO_SET",RAM_FUNC["CE"]*0 + RAM_FUNC["OE"]*1 + RAM_FUNC["WE"]*0 + RAM_FUNC["HOID"]*1)
        sleep(0.001)
        execute(ser,CTRL,"IO_SET",RAM_FUNC["CE"]*0 + RAM_FUNC["OE"]*1 + RAM_FUNC["WE"]*1 + RAM_FUNC["HOID"]*1)
        #sleep(0.001)
        #RAMを3ステートに
        execute(ser,CTRL,"IO_SET",RAM_FUNC["CE"]*0 + RAM_FUNC["OE"]*1 + RAM_FUNC["WE"]*1 + RAM_FUNC["HOID"]*1)
        #sleep(0.001)
        #データバスを入力モードに
        execute(ser,DATA,"DIR_SET",0x0000)
        #RAMをREADモードに
        execute(ser,CTRL,"IO_SET",RAM_FUNC["CE"]*0 + RAM_FUNC["OE"]*0 + RAM_FUNC["WE"]*1 + RAM_FUNC["HOID"]*1)
        #データをリード
        id, mode, value = execute(ser,DATA,"IN_GET",0x0000)
        #RAMを3ステートに
        execute(ser,CTRL,"IO_SET",RAM_FUNC["CE"]*1 + RAM_FUNC["OE"]*1 + RAM_FUNC["WE"]*1 + RAM_FUNC["HOID"]*1)

        #結果を比較
        value = value & 0xFF
        if test_data == value:
            print("[ pass ]\tADDRESS:","{:04x}".format(test_address),"\tDATA:","{:04x}".format(test_data),"{:04x}".format(test_data),"==","{:04x}".format(value))
            pass_num += 1
        else:
            print("\033[41m[failed]\tADDRESS:","{:04x}".format(test_address),"\tDATA:","{:04x}".format(test_data),"{:04x}".format(test_data),"==","{:04x}".format(value),"\033[0m")
            failed += 1

    if failed == 0:
        print("All tests'(",pass_num,") passed.")
    else:
        print("Failed ",failed," tests.")
        print("passed ",pass_num," tests.")
        for wk in failed_list:
            print(wk)

    #execute(ser,TO_ALL,"RESET",0x0000)
    execute(ser,CTRL,"DIR_SET",RAM_FUNC["HOID"])
    execute(ser,DATA,"DIR_SET",0x0000)
    execute(ser,ADDRESS,"DIR_SET",0x0000)
    execute(ser,CTRL,"IO_SET",0x00)
    device_status(ser,CTRL)
    device_status(ser,DATA)
    device_status(ser,ADDRESS)
    ser.close()