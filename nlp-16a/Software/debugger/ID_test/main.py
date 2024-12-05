import nlp_debug
from time import sleep
import random

Reg_name = [
    "IR1",
    "IR2",
    "IV",
    "IR3",
    "Flag",
    "Reg A",
    "Reg B",
    "Reg C",
    "Reg D",
    "Reg E",#9 標準では未実装
    "Reg F",# A 標準では未実装
    "MEM",#11 B
    "Addr",#12 C
    "IP",#13 D
    "SP",#14 E
    "Zero",#15
]

test_inst = {
    "MOV":0x6600,#MOV
    "CALL":0xB0,#CALL
    "CALL":0x66B0,#CALL
    "RET":0xC0,#RET
    "IRET":0xE0,#IRET
    "PUSH":0xD0,#PUSH
    "LOAD":0x80,#LOAD
    "STORE":0x9A,#STORE
    "IE":0xFF,#IE
    "ID":0xFE,#ID
}

Internal_Reg_name = [
    "\033[32mInternal\033[0m",
    "IR1",
    "IR2",
    "IV/Acc",
    "IR3",
    "Flag",
    "MEM",
    "Addr",
    "IP",
    "SP",
]
def Y_BUS_Check(id):
    value = debug.input(id)
    for cn in range(10):
        if cn != 3 and value & 0b1<<cn == 0:
            print(Internal_Reg_name[cn],", ",end="")
        if cn == 3 and value & 0b1<<cn != 0:
            print(Internal_Reg_name[cn],", ",end="")
    if value & 0b1 != 0:
        print("\t[",Reg_name[value>>10&0xF],"]")
    else:
        print("")
def A_BUS_Check(id):
    value = debug.input(id)
    for cn in range(10):
        if value & 0b1<<cn == 0:
            print(Internal_Reg_name[cn],", ",end="")
    if value & 0b1 != 0:
        print("\t[",Reg_name[value>>10&0xF],"]")
    else:
        print("")
def clk(id,mode,wait=0):
    print("--------------")
    phi2 = 1
    phi1 = 0
    debug.output(id,phi1<<7 | phi2<<6 |mode<<1)
    phi2 = 0
    phi1 = 0
    debug.output(id,phi1<<7 | phi2<<6 |mode<<1)
    value = debug.input(ID2)
    print("A BUS\t:",end="")
    A_BUS_Check(A_BUS)
    if wait=="M":
        dmy = input()
    else:
        sleep(wait)
    phi2 = 0
    phi1 = 1
    debug.output(id,phi1<<7 | phi2<<6 |mode<<1)
    phi2 = 0
    phi1 = 0
    debug.output(id,phi1<<7 | phi2<<6 |mode<<1)
    print("Y BUS\t:",end="")
    Y_BUS_Check(Y_BUS)
    if (value & (0b0100<<8) ==0):
        print("BUS A/B : \033[32mRA3->\033[0m")
    else:
        print("BUS A/B : RA2->")
    
    if (value & (0b0010<<8) ==0):
        print("BUS A/Y : \033[32mRA1->\033[0m")
    else:
        print("BUS A/Y : RA2->")
    
    if (value & (0b10000000<<8) ==0):
        print("ALU : Internal")
    else:
        print("ALU : \033[32mnormal\033[0m")
    
    if (value & (0b01000000<<8) ==0):
        print("    INC : \033[32mINC\033[0m")
    else:
        print("    INC : ")
    
    if (value & (0b00100000<<8) ==0):
        print("    DEC : \033[32mDEC\033[0m")
    else:
        print("    DEC : ")
    if (value & (0b0001<<8) !=0):
        print("INT EN : \033[32menable\033[0m")
    else:
        print("INT EN : disable")
    #print("BUS A/B : ",(value & (0b0100<<8) ==0))
    #print("BUS A/Y : ",(value & (0b0010<<8) ==0))
    #print("ALU : ",(value & (0b10000000<<8) ==0))
    #print("INC : ",(value & (0b01000000<<8) ==0))
    #print("DEC : ",(value & (0b00100000<<8) ==0))
    if wait=="M":
        dmy = input()
    else:
        sleep(wait)
    return

if __name__ == '__main__':
    debug = nlp_debug.debugger()

    debug.reset()
    id = debug.scan_devides()
    if id != 4:
        del debug
        exit()
    
    A_BUS = 0x00
    Y_BUS = 0x01
    ID1 = 0x02
    ID2 = 0x03

    print("ID1 DIR_SET")
    debug.dir_set(ID1,0xFFFF)
    #debug.execute(ID1,"REVERSE_MODE",0x0001)
    print("ID2 DIR_SET")
    debug.dir_set(ID2,0x00FF)
    debug.execute(ID2,"REVERSE_MODE",0x0001)
    print("A BUS CTRL DIR_SET")
    debug.dir_set(A_BUS,0x0000)
    print("Y BUS CTRL DIR_SET")
    debug.dir_set(Y_BUS,0x0000)

    mode = 0b01101#通常
    #mode = 0b11101#NOP
    #mode = 0b11111#割り込み

    #debug.output(ID1,0x6600)#MOV
    #debug.output(ID1,0xB0)#CALL
    #debug.output(ID1,0x66B0)#CALL
    #debug.output(ID1,0xC0)#RET
    #debug.output(ID1,0xE0)#IRET
    #debug.output(ID1,0xD0)#PUSH
    #debug.output(ID1,0x80)#LOAD
    #debug.output(ID1,0x9A)#STORE
    #debug.output(ID1,0xFF)#IE
    #debug.output(ID1,0xFE)#ID
    for inst_name in test_inst.keys():
        print(inst_name)
        debug.output(ID1,test_inst[inst_name])
        print("RS...",end="")
        for dmy in range(14):
            clk(ID2,mode&0b10111)
            #seed
        print("done")
        print("\033[41mSequence start\033[0m")
        clk(ID2,mode&0b11011)
        last_fetch = True
        inst_cn = 0
        for dmy in range(40):
            clk(ID2,mode,wait=0.1)#クロック自動
            #clk(ID2,mode,wait="M")#クロック手動
            value = debug.input(ID2)
            if (value & (0b1000<<8) ==0) != last_fetch:
                last_fetch = (value & (0b1000<<8) ==0)
                inst_cn+=1
                if inst_cn >= 2:
                #if inst_cn >= 4:#割り込み用
                    break
        

    debug.device_status(ID1)
    debug.device_status(ID2)    
    del debug