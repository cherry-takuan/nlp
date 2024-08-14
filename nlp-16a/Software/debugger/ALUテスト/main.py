import nlp_debug
from time import sleep
import alu_ref
A_PATTERN = [
        0x0000,
        0x0001,
        0x1234,
        0x5555,
        0x7FFF,
        0xAAAA,
        0xfFFF,
    ]
B_PATTERN = [
        0x0000,
        0x0001,
        0x1234,
        0x5555,
        0x7FFF,
        0xAAAA,
        0xFFFF,
    ]
def ALU(debug,func):
    debug.output(CTRL,func)
    value = debug.input(Y_BUS)
    debug.output(CTRL,func|0x800)
    flag = debug.input(Y_BUS)
    flag &= 0xE
    return value, flag
if __name__ == '__main__':
    debug = nlp_debug.debugger()
    debug.reset()
    id = debug.scan_devides()
    if id != 4:
        del debug
        print("Error: Number of detected devices differs from configured value")
        exit(1)
    ALU_ref = alu_ref.ALU()
    
    CTRL = 0x00
    A_BUS = 0x01
    B_BUS = 0x02
    Y_BUS = 0x03

    debug.dir_set(CTRL,0x0FFF)
    debug.dir_set(A_BUS,0xFFFF)
    debug.dir_set(B_BUS,0xFFFF)
    debug.dir_set(Y_BUS,0x0000)
    for func in ALU_ref.func_table.keys():
        for B in B_PATTERN:
            debug.output(B_BUS,B)
            for A in A_PATTERN:
                debug.output(A_BUS,A)
                ########
                value, flag = ALU(debug,ALU_ref.func_table[func]) # ADD
                want_value, Z, V, S = ALU_ref.ref_gen(A, B, func)
                ########
                flag_msg = ""
                flag_msg += "S" if (flag & 0x8 != 0) else " "
                flag_msg += "Z" if (flag & 0x4 != 0) else " "
                flag_msg += "V" if (flag & 0x2 != 0) else " "
                want_flag_msg = ""
                want_flag_msg += "S" if (S != 0) else " "
                want_flag_msg += "Z" if (Z != 0) else " "
                want_flag_msg += "V" if (V != 0) else " "
                if ALU_ref.cmp(A,B,func,value,flag):
                    print("[ \033[32mpass\033[0m ]  A:","{:04x}".format(A),"  B:","{:04x}".format(B)," ",func.ljust(4)," ->  \033[32m","{:04x}".format(value),",",flag_msg,"\033[0m")
                else:
                    print("[\033[31mfailed\033[0m]  A:","{:04x}".format(A),"  B:","{:04x}".format(B)," ",func.ljust(4),"  \033[32mwant:","{:04x}".format(want_value),",",want_flag_msg,"\033[0m->\033[31mresult:","{:04x}".format(value),",",flag_msg,"\033[0m")
                    del debug
                    exit(1)
    del debug
    exit(1)