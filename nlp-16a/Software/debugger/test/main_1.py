import nlp_debug
from time import sleep
import random

program_data = [
    0x0019,
    0x3005,
    0x00AA,
    
    0x0019,
    0x100A,
    
    0x001D,
    0x1000
]

if __name__ == '__main__':
    debug = nlp_debug.debugger()

    debug.reset()
    id = debug.scan_devides()
    if id != 3:
        del debug
        exit()
    
    CTRL = 0x00
    DATA = 0x01
    ADDRESS = 0x02

    WR = 0b0001
    RD = 0b0010
    CPU_ADDR = 0b0100
    RS = 0b1000

    print("CTRL DIR_SET")
    debug.dir_set(CTRL,0xFFFF)
    print("DATA DIR_SET")
    debug.dir_set(DATA,0x0000)
    debug.execute(DATA,"REVERSE_MODE",0x0001)
    print("ADDRESS CTRL DIR_SET")
    debug.dir_set(ADDRESS,0x0000)
    
    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*0)
    dmy = input("Ready?")
    debug.dir_set(ADDRESS,0xFFFF)
    for now_address in range(len(program_data)):
        debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*0)
        
        debug.output(ADDRESS,now_address)
        
        debug.dir_set(DATA,0xFFFF)
        debug.output(DATA,program_data[now_address])
        debug.output(CTRL,WR*1 | RD*0 | CPU_ADDR*1 | RS*0)
        debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*0)

        debug.dir_set(DATA,0x0000)
        debug.output(CTRL,WR*0 | RD*1 | CPU_ADDR*1 | RS*0)
        value = debug.input(DATA)
        debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*0)
        if value == program_data[now_address]:
            print("OK ",end="")
        else:
            print("Error ",end="")
        print("{:04x}".format(now_address),"\t:\t","{:04x}".format(value),"{:04x}".format(program_data[now_address]))
        sleep(0.5)
    
    debug.dir_set(DATA,0x0000)
    for now_address in range(len(program_data)):
        debug.output(ADDRESS,now_address)
        debug.output(CTRL,WR*0 | RD*1 | CPU_ADDR*1 | RS*0)
        value = debug.input(DATA)
        debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*0)
        print("{:04x}".format(now_address),"\t:\t","{:04x}".format(value))
        sleep(0.5)
    
    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*1 | RS*0)
    debug.dir_set(ADDRESS,0x0000)
    debug.dir_set(DATA,0x0000)
    sleep(0.1)
    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*0 | RS*0)
    sleep(0.1)
    dmy = input("Run")
    debug.output(CTRL,WR*0 | RD*0 | CPU_ADDR*0 | RS*1)
    dmy = input("End")
    del debug