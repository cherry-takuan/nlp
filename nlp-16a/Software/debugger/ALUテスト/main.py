import serial_ctrl
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
    ser = serial_ctrl.select_port(baudrate=19200)
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
    if id != 4:
        ser.close()
        exit()
    
    CTRL = 0x00
    A_BUS = 0x01
    B_BUS = 0x02
    Y_BUS = 0x03

    Func = {
        "A<<1"      :0b011111001001,
        "A>>1"      :0b011111001101,

        "A+B"       :0b011111010010,
        "A-B"       :0b011111100010,
        "A_AND_B"   :0b011111011000,
        "A_OR_B"    :0b011111010100,
        "A_XOR_B"   :0b011111011100,

        "A"         :0b011111000000,
        "NOT_A"     :0b011111001100,
        "A_INC"     :0b011111110110,
        "A_DEC"     :0b011111000110,
    }
    print("CTRL DIR_SET")
    execute(ser,CTRL,"DIR_SET",0x0FFF)
    print("A_BUS DIR_SET")
    execute(ser,A_BUS,"DIR_SET",0xFFFF)
    print("B_BUS DIR_SET")
    execute(ser,B_BUS,"DIR_SET",0xFFFF)
    print("Y_BUS DIR_SET")
    execute(ser,Y_BUS,"DIR_SET",0x0000)

    device_status(ser,CTRL)
    device_status(ser,A_BUS)
    device_status(ser,B_BUS)
    device_status(ser,Y_BUS)

    A_PATTERN = [
        0x0000,
        0x1234,
        0x4321,
        0x5555,
        0x5678,
        0xAAAA,
        0xfFFF,

        0x0001,
        0x0002,
        0x0004,
        0x0008,

        0x0010,
        0x0020,
        0x0040,
        0x0080,

        0x0100,
        0x0200,
        0x0400,
        0x0800,

        0x1000,
        0x2000,
        0x4000,
        0x8000,
    ]
    B_PATTERN = [
        0x0000,
        0x1234,
        0x4321,
        0x5555,
        0x5678,
        0xAAAA,
        0xFFFF,

        0x0001,
        0x0002,
        0x0004,
        0x0008,

        0x0010,
        0x0020,
        0x0040,
        0x0080,

        0x0100,
        0x0200,
        0x0400,
        0x0800,

        0x1000,
        0x2000,
        0x4000,
        0x8000,
    ]

    failed = 0
    pass_num = 0
    failed_list = list()
    for F in Func.keys():
        print(F)
        execute(ser,CTRL,"IO_SET",Func[F]^0b000010)
        for B in B_PATTERN:
            execute(ser,B_BUS,"IO_SET",B)
            for A in A_PATTERN:
                execute(ser,A_BUS,"IO_SET",A)
                id, mode, value = execute(ser,Y_BUS,"IN_GET",0x0000)
                if "A+B" == F:
                    ans = A + B
                elif "A-B" == F:
                    ans = A - B
                elif "A_AND_B" == F:
                    ans = A & B
                elif "A_OR_B" == F:
                    ans = A | B
                elif "A_XOR_B" == F:
                    ans = A ^ B
                elif "A" == F:
                    ans = A
                elif "NOT_A" == F:
                    ans = ~A
                elif "A_INC" == F:
                    ans = A + 1
                elif "A_DEC" == F:
                    ans = A - 1
                elif "A<<1" == F:
                    ans = (A<<1 & 0x7FFF) | (A & 0x8000)
                elif "A>>1" == F:
                    ans = (A>>1 & 0x7FFF)| (A & 0x8000)
                ans &= 0xFFFF
                ans = Num_normalize(ans)

                if ans == value:
                    print("[ pass ]\tA:","{:04x}".format(A),"\tB:","{:04x}".format(B),"\tFunc:",F,"\ttest:","{:04x}".format(ans),"==","{:04x}".format(value))
                    pass_num += 1
                else:
                    print("\033[41m[failed]\tA:","{:04x}".format(A),"\tB:","{:04x}".format(B),"\tFunc:",F,"\ttest:","{:04x}".format(ans),"!=","{:04x}".format(value),"\033[0m")
                    wk = "\033[41m[failed]\tA:"+"{:04x}".format(A)+"\tB:"+"{:04x}".format(B)+"\tFunc:"+F+"\ttest:"+"{:04x}".format(ans)+"!="+"{:04x}".format(value)+"\033[0m"
                    failed_list.append(wk)
                    failed += 1


                    id, mode, value = execute(ser,Y_BUS,"IN_GET",0x0000)
                    ser.close()
                    exit(1)
    if failed == 0:
        print("All tests'(",pass_num,") passed.")
    else:
        print("Failed ",failed," tests.")
        print("passed ",pass_num," tests.")
        for wk in failed_list:
            print(wk)

    execute(ser,TO_ALL,"RESET",0x0000)
    ser.close()