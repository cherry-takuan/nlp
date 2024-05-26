import serial
from serial.tools import list_ports
from time import sleep
import sys

class debugger:
    def __init__(self,dev=None):
        #デバッガに流したデータのログを取る
        self.debug_log = list()
        #定数
        self.mode_table = {
            "ID_SET":0x00,
            "DIR_GET":0x01,
            "DIR_SET":0x02,
            "IO_SET":0x03,
            "IN_GET":0x04,
            "OUT_GET":0x05,
            "REVERSE_MODE":0x06,
            "RESET":0x0F
        }
        self.TO_ALL = 0xFE
        self.TO_MASTER = 0xFF
        
        #シリアル設定
        self.ser = None
        self.ser = self.select_port(dev)
        print("Please wait...",file=sys.stderr)
        sleep(2)
        self.ser.reset_input_buffer()
    def __del__(self):
        if self.ser != None:
            self.execute(self.TO_ALL,"RESET",0x0000)
            self.ser.close()

    def execute(self,to_id,mode,value):
        count = 0
        while(count < 10):#10回までトライする
            data = dict()
            #sleep(0.1)
            instruction = "{:0>2X}-{:0>2X}-{:0>4X}\n".format(to_id,self.mode_table[mode],value)
            data["command"] = instruction[:-1]
            self.ser.write(instruction.encode('ascii'))
            line = self.ser.readline()
            line_disp=line.strip().decode('UTF-8')
            data["response"] = line_disp
            self.debug_log.append(data)
            try:
                result_id = int(line_disp[0:2],16)
                result_mode = int(line_disp[3:5],16)
                result_value = int(line_disp[6:10],16)
            except Exception as e:
                print("Execute error(",count,") : ",e,file=sys.stderr)
                print("###################",file=sys.stderr)
                print("send\t:",instruction[:-1],file=sys.stderr)
                print("raw\t:",line_disp,file=sys.stderr)
                print("",file=sys.stderr)
                sleep(0.1)
                count+=1
            else:
                return result_id,result_mode,result_value
    def dir_set(self,id,dir):
        self.execute(id,"DIR_SET",dir)
    def output(self,id,data):
        self.execute(id,"IO_SET",data)
    def input(self,id):
        id,mode,value = self.execute(id,"IN_GET",0x0000)
        return value
    def reset(self):
        self.execute(self.TO_ALL,"RESET",0x0000)
    
    def device_status(self,id,bus_mode=False):
        bus = ""
        if bus_mode == True:
            bus="|"
        dir_id,dir_mode,dir_value = self.execute(id,"DIR_GET",0x0000)
        if dir_id != self.TO_MASTER:
            print("Error : 指定されたデバイスから応答がありません．",file=sys.stderr)
            return
        in_id,in_mode,in_value = self.execute(id,"IN_GET",0x0000)
        if in_id != self.TO_MASTER:
            print("Error : 指定されたデバイスから応答がありません．",file=sys.stderr)
            return
        out_id,out_mode,out_value = self.execute(id,"OUT_GET",0x0000)
        if out_id != self.TO_MASTER:
            print("Error : 指定されたデバイスから応答がありません．",file=sys.stderr)
            return
        
        print("    +-------------------------------+    "+bus,file=sys.stderr)
        print("    | slave:{:0>2X}                  ok  |    ".format(id)+bus,file=sys.stderr)
        print("    |  ---------------------------  |    "+bus,file=sys.stderr)
        print("    |F E D C B A 9 8 7 6 5 4 3 2 1 0|    "+bus,file=sys.stderr)
        #入出力方向
        msg = "DIR |"
        for num in reversed(range(0x10)):
            if dir_value & (1<<num) == 0:
                msg += "\033[41mI\033[0m "
            else:
                msg += "\033[44mO\033[0m "
        msg = msg[0:-1] + "|    "+bus
        print(msg,file=sys.stderr)
        #入力状態
        msg = "IN  |"
        for num in reversed(range(0x10)):
            if in_value & (1<<num) == 0:
                msg += "\033[41mL\033[0m "
            else:
                msg += "\033[44mH\033[0m "
        msg = msg[0:-1] + "|    "+bus
        print(msg,file=sys.stderr)
        #出力状態
        msg = "OUT |"
        for num in reversed(range(0x10)):
            if out_value & (1<<num) == 0:
                msg += "\033[41mL\033[0m "
            else:
                msg += "\033[44mH\033[0m "
        msg = msg[0:-1] + "|    "+bus
        print(msg,file=sys.stderr)


        print("    +-------------------------------+    "+bus,file=sys.stderr)

    def scan_devides(self):
        result_id,result_mode,result_value =  self.execute(self.TO_ALL,"ID_SET",0x00)
        if result_mode != self.mode_table["ID_SET"]:
            return -1
        print("Device:",result_value,file=sys.stderr)
        print("    +-------------------------------+",file=sys.stderr)
        print("    | master                        | <--+",file=sys.stderr)
        print("    +-------------------------------+    |",file=sys.stderr)
        print("                     |                   |",file=sys.stderr)
        print("                     |                   |",file=sys.stderr)
        for num in range(result_value):
            self.device_status(num,bus_mode=True)
            print("                     |                   |",file=sys.stderr)
        print("                     |                   |",file=sys.stderr)
        print("                     +-------------------+",file=sys.stderr)
        return result_value


    def Num_normalize(self,num):
        if num < 0:
            num = -num
            num = ~num
            num = num & 0xFFFF
            num += 1
        return num
    def select_port(self,dev=None):
        ser = serial.Serial()
        ser.baudrate = 115200
        ser.timeout = 2       # タイムアウトの時間
        if dev==None:
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
                num = int(input("Please enter the port number:" ))
                if num >= len(devices):
                    print("存在しません",file=sys.stderr)
                    exit(1)
                ser.port = devices[num]
        else:
            ser.port = dev
        
        # 開いてみる
        try:
            ser.open()
            return ser
        except:
            print("Error：The port could not be opened.",file=sys.stderr)
            exit(1)