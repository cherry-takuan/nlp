import nlp_debug
from time import sleep
import random
import alu_ref

A_PATTERN = [
        0x0000,
        0x5555,
        0xAAAA,
        0xFFFF,
    ]
B_PATTERN = [
        0x0000,
        0x5555,
        0xAAAA,
        0xFFFF,
    ]
def clk(id,address,internal=0b1111110111):
    phi1 = 1
    phi2 = 0
    debug.output(id,(address<<10) | internal | phi1<<15 | phi2<<14)
    phi1 = 0
    phi2 = 0
    debug.output(id,(address<<10) | internal | phi1<<15 | phi2<<14)
    phi1 = 0
    phi2 = 1
    debug.output(id,(address<<10) | internal | phi1<<15 | phi2<<14)
    phi1 = 0
    phi2 = 0
    debug.output(id,(address<<10) | internal | phi1<<15 | phi2<<14)
    return

if __name__ == '__main__':
    debug = nlp_debug.debugger()
    ALU_ref = alu_ref.ALU()
    debug.reset()
    id = debug.scan_devides()
    if id != 4:
        del debug
        exit()
    
    A_BUS_CTRL = 0x02
    Y_BUS_CTRL = 0x01
    ALU_CTRL = 0x00
    IO_BUS = 0x03

    print("A BUS CTRL DIR_SET")
    debug.dir_set(A_BUS_CTRL,0xFFFF)
    print("Y BUS CTRL DIR_SET")
    debug.dir_set(Y_BUS_CTRL,0xFFFF)
    print("ALU CTRL DIR_SET")
    debug.dir_set(ALU_CTRL,0x0FFF)
    print("I/O BUS DIR_SET")
    debug.dir_set(IO_BUS,0x0000)
    debug.execute(IO_BUS,"REVERSE_MODE",0x0001)

    debug.device_status(A_BUS_CTRL)
    debug.device_status(Y_BUS_CTRL)
    debug.device_status(ALU_CTRL)
    debug.device_status(IO_BUS)

    IO_ADDRESS = 11

    reg_list = {0,1,2,3,4,5,6,7,8,12,13,14}
    func_list = {"ADD","AND","OR", "A"}
    for reg_num in reg_list:
        print("[ \033[36minfo\033[0m ] test Reg:","{:04x}".format(reg_num),"--------------------------")
        for func_name in func_list:
            for B in B_PATTERN:
                for A in A_PATTERN:
                    phi1 = 0
                    phi2 = 0
                    debug.output(A_BUS_CTRL,(IO_ADDRESS<<10) | 0b1111111111)                    #入力をIOに設定
                    debug.output(Y_BUS_CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)    #出力先を適当に設定
                    debug.output(ALU_CTRL,ALU_ref.func_table["A"])#ALU転送命令
                    debug.dir_set(IO_BUS,0xFFFF)                                                #IO用デバッガを出力モードに設定
                    #入力Bの値をAccに転送
                    debug.output(IO_BUS,B)
                    clk(Y_BUS_CTRL,0x0F,0b1111111110)
                    #入力Aの値を出力
                    debug.output(IO_BUS,A)
                    clk(Y_BUS_CTRL,reg_num)
                    debug.dir_set(IO_BUS,0x0000)
                    debug.output(A_BUS_CTRL,(reg_num<<10) | 0b1111111111)                    #入力を0x00に設定
                    #演算命令をセット
                    #debug.output(ALU_CTRL,Func[F]^0b000010)
                    debug.output(ALU_CTRL,ALU_ref.func_table[func_name])
                    #dmy = input("Aに転送")
                    #reg_numに結果を格納
                    clk(Y_BUS_CTRL,reg_num)
                    #dmy = input("結果を出力")
                    debug.output(ALU_CTRL,0b011101001001)#ALU転送命令
                    clk(Y_BUS_CTRL,IO_ADDRESS)
                    value = debug.input(IO_BUS)
                        
                    debug.output(A_BUS_CTRL,(IO_ADDRESS<<10) | 0b1111111111)                    #入力をIOに設定
                    debug.output(Y_BUS_CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)    #出力先を適当に設定
                    debug.output(ALU_CTRL,0b011101001001)#ALU転送命令
                    debug.dir_set(IO_BUS,0xFFFF)                                                #IO用デバッガを入力モードに設定
                    #入力Bの値をAccに転送
                    debug.output(IO_BUS,B)
                    #clk(Y_BUS_CTRL,0x0F)
                    clk(Y_BUS_CTRL,0x0F,0b1111111110)
                    #入力Aの値を出力
                    debug.output(IO_BUS,A)
                    clk(Y_BUS_CTRL,reg_num)
                        
                    debug.dir_set(IO_BUS,0x0000)                                             #IO用デバッガを入力モードに設定
                    debug.output(A_BUS_CTRL,(reg_num<<10) | 0b1111111111)                    #入力を0x00に設定
                    #演算命令をセット
                    debug.output(ALU_CTRL,ALU_ref.func_table[func_name]|0x800)
                    #Regに結果を格納
                    clk(Y_BUS_CTRL,IO_ADDRESS)
                        
                    flag = debug.input(IO_BUS)

                    ########
                    want_value, Z, V, S = ALU_ref.ref_gen(A, B, func_name)
                    ########
                    flag_msg = ""
                    flag_msg += "S" if (flag & 0x8 != 0) else " "
                    flag_msg += "Z" if (flag & 0x4 != 0) else " "
                    flag_msg += "V" if (flag & 0x2 != 0) else " "
                    want_flag_msg = ""
                    want_flag_msg += "S" if (S != 0) else " "
                    want_flag_msg += "Z" if (Z != 0) else " "
                    want_flag_msg += "V" if (V != 0) else " "
                    if ALU_ref.cmp(A,B,func_name,value,flag):
                        print("[ \033[32mpass\033[0m ]  A:","{:04x}".format(A),"  B:","{:04x}".format(B)," ",func_name.ljust(4)," ->  \033[32m","{:04x}".format(value),",",flag_msg,"\033[0m")
                        pass
                    else:
                        print("[\033[31mfailed\033[0m]  A:","{:04x}".format(A),"  B:","{:04x}".format(B)," ",func_name.ljust(4),"  \033[32mwant:","{:04x}".format(want_value),",",want_flag_msg,"\033[0m->\033[31mresult:","{:04x}".format(value),",",flag_msg,"\033[0m")
                        del debug
                        exit(1)
        print("[ \033[32mpass\033[0m ] Reg:","{:04x}".format(reg_num))
    print("test all passed")
    del debug