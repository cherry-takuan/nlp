import re
import pprint
import alu_ref
import numpy as np
import sys
import time

# 入力関連
import os
if os.name == 'nt':  # Windows
    import msvcrt
    def getchar():
        tmp = msvcrt.getch().decode('ascii')
        if ord(tmp) == 3:
            exit()
        return ord(tmp)
else:  # Linux / Mac
    # 動作未確認
    import tty
    import termios
    def getchar():
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        return ch

#メモリ関連の構成
#シリアル等のメモリマップドデバイスはここに記述
class MEM:
    def __init__(self):
        self.ram  = np.zeros(64*1024, dtype=np.uint16)
    def MEM_RD(self,address):
        if False:
            print("MEM RD","0x{:04X},".format(address))
            exit(1)
        if address == 0xFF01:
            return 0x0000
        elif address == 0xFF00:
            return  getchar()
        #elif address == 0x88:
        #    print("\n[ Exit ]",flush=True)
        #    exit(0)
        return self.ram[address]
    def MEM_WR(self,address,data):
        #print(address,":",data)
        if address < 0xF000:
            self.ram[address] = data
        elif address == 0xFF00:
            #print(data,end="",flush=True)
            #exit(0)
            #print(data,end="",flush=True)
            if data == 0x0a:
                print("");
            elif data > 0xFF:
                print("\nwarning:",data,flush=True)
            else:
                print(chr(data&0xFF),end="",flush=True)
        elif address == 0xFF02:
            print(data,flush=True)
        elif address == 0xFFFF:
            exit()

#CPU本体
class nlp16a:
    def __init__(self,MEM_RD,MEM_WR):
        self.MEM_RD = MEM_RD
        self.MEM_WR = MEM_WR
        #内部状態
        #self.ram  = np.zeros(64*1024, dtype=np.uint16)
        self.reg = np.zeros(0x10, dtype=np.uint16)
        self.int_enable = True
        self.ALU_T = {
            0x00    :"A",
            0x0A    :"ADD",     0x0E:"ADC",
            0x09    :"SUB",     0x0D:"SBB",
            0x1B    :"INC",     0x1F:"INCC",
            0x18    :"DEC",     0x1C:"DECB",
            0x06    :"AND",
            0x12    :"OR",
            0x14    :"NOT",
            0x16    :"XOR",
            0x20    :"SHL",     0x30    :"SHR",
            0x24    :"SAL",     0x34    :"SAR",
            0x22    :"ROL",     0x32    :"ROR"
        }
        self._inst=0
        self._RA1=0
        self._RA2=0
        self._RA3=0
        self._branch=0
        self._ACC = 0

        self.alu = alu_ref.ALU()

        self.program_area = 0

    #プログラム転送(別に必ず使う必要はない)
    def program_input(self,program_bin,start_address = 0):
        program_bin = list(program_bin)
        address = start_address
        while True:
            data = ""
            if len(program_bin) < 4:
                break
            data += program_bin.pop(0)
            data += program_bin.pop(0)
            data += program_bin.pop(0)
            data += program_bin.pop(0)
            try:
                data = int(data,16)
            except Exception as e:
                print("プログラム格納エラー",file=sys.stderr)
                print(e,file=sys.stderr)
                exit(1)
            else:
                self.MEM_WR(address,data)
                address += 1
        self.program_area = address

    #レジスタ読み書きのインターフェイス
    #MEMやRA1等のレジスタとして本当に触るわけではないものの処理
    def reg_read(self,reg_num):
        if reg_num == 0x0B:#MEM
            return self.MEM_RD(self.reg[0x0C])
        elif reg_num == 0x01:#IR2
            return self.reg[0x01]&0xFF
        elif reg_num == 0x0F:
            return 0
        else:
            return self.reg[reg_num]
    def reg_write(self,reg_num,data):
        if self._branch == True:
            if reg_num == 0x0B:
                self.MEM_WR(self.reg[0x0C],data)
            elif (reg_num == 0x0D) or (reg_num == 0x0E):
                self.reg[reg_num] = data
                self.reg[0x0C] = data
            elif reg_num == 0x0F:
                pass
            else:
                self.reg[reg_num] = data
    def _ACC_set(self):
        if self._branch == True:
            self._ACC = self.reg_read(self._RA3)
    def _IR2_load(self):
        # 2nd word load
        self.reg[0x01] = self.MEM_RD(self.reg[0x0C]) # IR2 <- RAM[ADDR]
        self.reg[0x0D] += 1 #IP <- IP+1
        self.reg[0x0C] = self.reg[0x0D] # ADDR <- IP
        self._RA2 =  self.reg[0x01]>>12
        self._RA3 = (self.reg[0x01]>>8 ) & 0x0F
    def _IR3_load(self):
        # 3rd word load
        self.reg[0x03] = self.MEM_RD(self.reg[0x0C]) # IR3 <- RAM[ADDR]
        self.reg[0x0D] += 1 #IP <- IP+1
        self.reg[0x0C] = self.reg[0x0D] # ADDR <- IP

    def _PUSH(self):
        self.reg_write(0x0E,self.reg[0x0E]-1)
        self.reg_write(0x0C,self.reg[0x0E])
        self.reg_write(0x0B,self.reg_read(self._RA1))
    def _POP(self):
        self.reg_write(0x0C,self.reg[0x0E])
        self.reg_write(self._RA1,self.MEM_RD(self.reg[0x0C]))
        self.reg_write(0x0E,self.reg[0x0E]+1)

        if self._RA1 == 0x0D:
            print("V addres:","{:04X}".format(self.inst_head_address)," RET:","{:04X}".format(self.reg[0x0D]),file=sys.stderr)        

    def _LOAD(self):
        self._ACC_set()
        self.reg[0x0C] = self._EXE()
        self.reg_write(self._RA1,self.reg_read(0x0B))
    def _STORE(self):
        self._ACC_set()
        self.reg[0x0C] = self._EXE()
        if self.program_area > self.reg[0x0C]:
            print("Illegal MEM op\naddres:","{:04X}".format(self.reg[0x0C]),"\ndata:","{:04X}".format(self.reg_read(self._RA1)),"\nIP:","{:04X}".format(self.inst_head_address),file=sys.stderr)
            self.ram_viewer()
            exit(1)
        self.reg_write(0x0B,self.reg_read(self._RA1))

    def _MOV(self):
        if self._inst&0x4 == 0:
            self._ACC = self.reg_read(self._RA3)
        self.reg_write(self._RA1,self._EXE())
    
    def _CALL(self):
        self._PUSH()
        self._ACC = self.reg_read(self._RA3)
        self.reg_write(self._RA1,self._EXE())
        print("V addres:","{:04X}".format(self.inst_head_address)," Call:","{:04X}".format(self.reg[0x0D]),file=sys.stderr)        

    def _EXE(self):
        if self._OP in self.ALU_T.keys():
            result, Z, V, S, C = self.alu.ref_gen(self.reg_read(self._RA2),self._ACC,self.ALU_T[self._OP])#from (func) Acc -> to
            if self._inst == 0x00:
                self.reg_write(0x04, S<<3 | Z<<2 | V<<1 | C)
            return result
        else:
            print("Illegal ALU opcode:","{:04X}".format(self._OP),file=sys.stderr)
            print("           address:","{:04X}".format(self.reg[0x0C]),file=sys.stderr)
            self.ram_viewer()
            exit(1)
    def _branch_decode(self,branch):
        inv = (branch & 0x01) == 0
        shift = (branch>>1) & 0x03
        flag = ((self.reg[0x04]>>shift)&0x01)==0
        if (branch & 0x08) == 0:
            flag = 0x01
        return ((flag != 0) ^ inv) != 0
    def execute_inst(self):
        # 1st word load
        self.reg[0x0C] = self.reg[0x0D] #ADDR <- IP
        self.inst_head_address = self.reg[0x0D]

        if self.inst_head_address > self.program_area:
            print("\033[31m",end="",file=sys.stderr)
            print("warning:Executing an out of range instruction")
            print("   last opcode:","{:04X}".format(self._inst),file=sys.stderr)
            print("    op address:","{:04X}".format(self.inst_head_address),file=sys.stderr)
            print("\033[0m",file=sys.stderr)
            self.ram_viewer()
            exit(1)
        self.reg[0x00] = self.MEM_RD(self.reg[0x0C]) # IR1 <- RAM[ADDR]
        self.reg[0x0D] += 1 #IP <- IP+1
        self.reg[0x0C] = self.reg[0x0D] # ADDR <- IP

        # bit field get
        self._inst = self.reg[0x00]>>12
        if self._inst&0x08 == 0:
            self._inst &= 0x0C
        self._branch = self._branch_decode((self.reg[0x00]>>4) & 0xF)
        self._RA1 = self.reg[0x00] & 0xF
        self._OP = ((self.reg[0x00]>>8) & 0xF) if (self._inst & 0x8 != 0) else ((self.reg[0x00]>>8) & 0x3F) # ALU opecode for EXE phase

        if not (self._inst == 0xC or self._inst == 0xD):
            # PUSH POP以外
            self._IR2_load()
            if self._RA2 == 0x03 or self._RA3 == 0x03:
                self._IR3_load()
            if self._inst == 0x0:
                self._MOV()
            elif self._inst == 0x8:
                self._LOAD()
            elif self._inst == 0x9:
                self._STORE()
            elif self._inst == 0xB:
                self._CALL()
            else:
                print("\033[31m",end="",file=sys.stderr)
                print("Unknown opcode:","{:04X}".format(self._inst),file=sys.stderr)
                print("    op address:","{:04X}".format(self.inst_head_address),file=sys.stderr)
                print("  last address:","{:04X}".format(self.reg[0x0C]),file=sys.stderr)
                print("\033[0m",file=sys.stderr)
                self.ram_viewer()
                exit(1)
        else:
            # PUSH POP関連
            if self._inst == 0xC:
                self._POP()
            else:
                self._PUSH()
        #self.reg_viewer()
    #レジスタ表示
    def reg_viewer(self):
        REG_T = {
            "IR1"   :0x00,    "IR2"   :0x01,    "IR3"   :0x03,    "IV"    :0x02,
            "FLAG"  :0x04,    "A"     :0x05,    "B"     :0x06,    "C"     :0x07,
            "D"     :0x08,    "E"     :0x09,
            "ADDR"  :0x0C,    "IP"    :0x0D,    "SP"    :0x0E
        }
        for name in REG_T.keys():
            try:
                dmy = int(name)
            except Exception:
                print(name,": [","{:04X}".format(self.reg[REG_T[name]]),"]",end="",file=sys.stderr)
            else:
                continue
        print("",file=sys.stderr)
    #MEM表示
    #最後に使ったアドレス付近20を表示
    def ram_viewer(self):
        view_range = 20
        last_address = self.reg[0x0C]
        print("SP    : 0x{:04X},".format(self.reg[0x0E]),file=sys.stderr)
        print("BP(D) : 0x{:04X},".format(self.reg[0x08]),file=sys.stderr)
        print("\nRAM===============",file=sys.stderr)
        bias = last_address-int(view_range/2)
        if last_address < view_range/2:
            bias = 0
        if last_address > 64*1024 - view_range/2:
            bias = 64*1024 - view_range
        for address in range(view_range):
            print("0x{:04X},".format(address+bias)," : 0x{:04X},".format(self.MEM_RD(address+bias)),end="",file=sys.stderr)
            if address+bias == last_address:
                print("  <-- last address",file=sys.stderr)
            elif address+bias == self.reg[0x0E]:
                print("  <-- SP address",file=sys.stderr)
            elif address+bias == self.reg[0x08]:
                print("  <-- BP address",file=sys.stderr)
            else:
                print("",file=sys.stderr)
        print("==================",file=sys.stderr)
if __name__ == "__main__":
    ram = MEM()
    cpu = nlp16a(ram.MEM_RD,ram.MEM_WR)
    cpu.program_input(sys.stdin.readline())
    cpu.reg_viewer()
    try:
        while True:
            cpu.execute_inst()
            #cpu.reg_viewer()
            #time.sleep(0.2)
    except KeyboardInterrupt:
        cpu.ram_viewer()