import nlp_debug
from time import sleep
A_PATTERN = [
        0x0000,
        0x0001,
        0x1234,
        0x5555,
        0x7FFF,
        0xAAAA,
        0xfFFF,
    ]

if __name__ == '__main__':
    debug = nlp_debug.debugger()
    debug.reset()
    id = debug.scan_devides()
    if id != 3:
        del debug
        print("Error: Number of detected devices differs from configured value")
        exit(1)
    
    CTRL = 0x00
    Acc_OUTPUT = 0x01
    INPUT = 0x02

    debug.dir_set(CTRL,0xFFFF)
    debug.dir_set(Acc_OUTPUT,0x0000)
    debug.dir_set(INPUT,0xFFFF)
    phi1 = 0
    phi2 = 0
    debug.output(CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
    for A in A_PATTERN:
        debug.output(INPUT,A)
        phi1 = 1
        phi2 = 0
        debug.output(CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
        phi1 = 0
        phi2 = 0
        debug.output(CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
        phi1 = 0
        phi2 = 1
        debug.output(CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
        phi1 = 0
        phi2 = 0
        debug.output(CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
        value = debug.input(Acc_OUTPUT)
        if value == A:
            print("[ \033[32mpass\033[0m ]  ","{:04x}".format(A)," -> ","{:04x}".format(value))
        else:
            print("[\033[31mfailed\033[0m]  ","{:04x}".format(A)," -> ","{:04x}".format(value))
            del debug
            exit(1)
    for addr in range(0x10):
        debug.output(CTRL,(addr<<10) | 0b1111111111 | 0<<15 | 0<<14)
        sleep(0.2)
    del debug