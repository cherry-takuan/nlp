import nlp_debug
from time import sleep
import alu_ref
A_PATTERN = [
        0x0000,
        0x0001,
        0x1234,
        0x5555,
        0xAAAA,
        0xfFFF,
    ]
B_PATTERN = [
        0x0000,
        0x0001,
        0x1234,
        0x5555,
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
        exit()
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

                if ALU_ref.cmp(A,B,func,value,flag):
                    print("[ pass ]  A:","{:04x}".format(A),"  B:","{:04x}".format(B),"  Func:",func," \t->\t","{:04x}".format(value),",","{:04b}".format(flag))
                else:
                    print("[failed]  A:","{:04x}".format(A),"  B:","{:04x}".format(B),"  Func:",func,"\twant:","{:04x}".format(want_value),",","{:04b}".format((S<<3 | Z<<2 | V<<1)),"->result:","{:04x}".format(value),",","{:04b}".format(flag))
                    del debug
                    exit(1)