import nlp_debug
from time import sleep
import random
from tqdm import tqdm

if __name__ == '__main__':
    debug = nlp_debug.debugger()

    debug.reset()
    id = debug.scan_devides()
    if id != 3:
        del debug
        exit()
    
    CTRL = 0x02
    DATA = 0x01
    ADDRESS = 0x00

    WR = 0b0001
    RD = 0b0010
    RS = 0b0100

    debug.dir_set(CTRL,0xFFFF)
    #debug.execute(CTRL,"REVERSE_MODE",0x0001)
    debug.dir_set(DATA,0x0000)
    debug.execute(DATA,"REVERSE_MODE",0x0001)
    debug.dir_set(ADDRESS,0x0000)
    debug.execute(ADDRESS,"REVERSE_MODE",0x0001)
    
    debug.output(CTRL,WR*1 | RD*1 | RS*1)
    dmy = input("Ready?")
    debug.dir_set(ADDRESS,0xFFFF)

    for now_address in tqdm(range(0xF0)):
        debug.output(CTRL,WR*1 | RD*1 | RS*1)
        debug.output(ADDRESS,now_address<<8)
        
        debug.dir_set(DATA,0xFFFF)
        debug.output(DATA,0x5555)
        debug.output(CTRL,WR*0 | RD*1 | RS*1)
        debug.output(CTRL,WR*1 | RD*1 | RS*1)

        debug.dir_set(DATA,0x0000)
        debug.output(CTRL,WR*1 | RD*0 | RS*1)
        value = debug.input(DATA)
        debug.output(CTRL,WR*1 | RD*1 | RS*1)
        if value == 0x5555:
            pass
        else:
            print("\nError ",end="")
            print("{:04x}".format(now_address<<8),"\t:want:0x5555 result:\t","{:04x}".format(value))
            del debug
            exit(1)

        debug.dir_set(DATA,0xFFFF)
        debug.output(DATA,0xAAAA)
        debug.output(CTRL,WR*0 | RD*1 | RS*1)
        debug.output(CTRL,WR*1 | RD*1 | RS*1)

        debug.dir_set(DATA,0x0000)
        debug.output(CTRL,WR*1 | RD*0 | RS*1)
        value = debug.input(DATA)
        debug.output(CTRL,WR*1 | RD*1 | RS*1)
        if value == 0xAAAA:
            pass
        else:
            print("\nError ",end="")
            print("{:04x}".format(now_address<<8),"\t:want:0xAAAA result:\t","{:04x}".format(value))
            del debug
            exit(1)
        #sleep(0.005)
    print("test passed")
    del debug