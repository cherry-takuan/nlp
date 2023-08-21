import serial_ctrl
from time import sleep
mode_table = {
    "ID_SET":0x00,
    "DIR_GET":0x01,
    "DIR_SET":0x02,
    "IO_SET":0x03,
    "IN_GET":0x04,
    "OUT_GET":0x05,
    "RESET":0x06
}
TO_ALL = 0xFE
TO_MASTER = 0xFF

def serial_start():
    ser = serial_ctrl.select_port(baudrate=9600)
    if ser == None:
        return 0
    print("Please wait...")
    sleep(3)
    ser.reset_input_buffer()
    #消すな
    return ser
def execute(ser,to_id,mode,value):
    instruction = "{:0>2X}-{:0>2X}-{:0>4X}\n".format(to_id,mode_table[mode],value)
    ser.write(instruction.encode('ascii'))
    line = ser.readline()
    line_disp=line.strip().decode('UTF-8')
    #print("mode:",int(line_disp[3:5],16),line_disp[3:5])
    #print("value:",int(line_disp[6:10],16),line_disp[6:10])
    #print("send:",instruction[:-1],", result:",line_disp)
    result_id = int(line_disp[0:2],16)
    result_mode = int(line_disp[3:5],16)
    result_value = int(line_disp[6:10],16)
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

if __name__ == '__main__':
    ser = serial_start()
    id = scan_devides(ser)
    if id < 0:
        ser.close()
        exit()
    
    A_BUS = 0x00
    B_BUS = 0x01
    Y_BUS = 0x02
    Ctrl = 0x03

    # Func S3 S2 S1 S0 Cn
    Func = {
        #"Clear":0b0000,
        #"B_Minus_A":0b0011,
        "A_Minus_B":0b0101,
        "A_Plus_B":0b0110,
        "A_XOR_B":0b1000,
        "A_OR_B":0b1010,
        "A_AND_B":0b1100,
        #"PRESET":0b1110,
    }
    execute(ser,A_BUS,"DIR_SET",0xFFFF)
    execute(ser,B_BUS,"DIR_SET",0xFFFF)
    execute(ser,Y_BUS,"DIR_SET",0x0000)
    execute(ser,Ctrl,"DIR_SET",0xFFFF)

    failed = 0
    for F in Func:
        execute(ser,Ctrl,"IO_SET",Func[F])
        for A in range(0x10):
            execute(ser,A_BUS,"IO_SET",A)
            for B in range(0x10):
                execute(ser,B_BUS,"IO_SET",B)
                id, mode, value = execute(ser,Y_BUS,"IN_GET",0x0000)

                if F == "B_Minus_A":
                    ans = B - A
                elif F == "A_Minus_B":
                    ans = A - B
                elif F == "A_Plus_B":
                    ans = A + B
                elif F == "A_XOR_B":
                    ans = A ^ B
                elif F == "A_OR_B":
                    ans = A | B
                elif F == "A_AND_B":
                    ans = A & B
                
                test = value
                #if test > 0x08:
                #    test = test - 0x08
                #value = signed_hex2int(value,4)

                if ans == test:
                    print("[ pass ]\tA:",A,"\tB:",B,"\tFunc:",F,"\ttest:",ans,"==",test)
                else:
                    print("[failed]\tA:",A,"\tB:",B,"\tFunc:",F,"\ttest:",ans,"==",test)
                    failed += 1
    if failed == 0:
        print("All tests passed.")
    else:
        print("Failed ",failed," tests.")
    """
    execute(ser,A_BUS,"DIR_SET",0xFFFF)
    execute(ser,B_BUS,"DIR_SET",0xFFFF)
    execute(ser,Y_BUS,"DIR_SET",0x0000)
    execute(ser,Ctrl,"DIR_SET",0xFFFF)

    #scan_devides(ser)

    execute(ser,A_BUS,"IO_SET",0x000A)
    execute(ser,B_BUS,"IO_SET",0x0005)
    execute(ser,Ctrl,"IO_SET",Func["A_OR_B"])
    #id, mode, value = execute(ser,Y_BUS,"IN_GET",0x0000)
    device_status(ser,Y_BUS)

    execute(ser,Ctrl,"IO_SET",Func["A_AND_B"])
    device_status(ser,Y_BUS)

    execute(ser,Ctrl,"IO_SET",Func["A_XOR_B"])
    device_status(ser,Y_BUS)


    execute(ser,A_BUS,"IO_SET",0x0001)
    execute(ser,B_BUS,"IO_SET",0x0002)
    execute(ser,Ctrl,"IO_SET",Func["A_Plus_B"])
    #id, mode, value = execute(ser,Y_BUS,"IN_GET",0x0000)
    device_status(ser,Y_BUS)
    """
    

    execute(ser,TO_ALL,"RESET",0x1000)
    ser.close()