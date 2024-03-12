import nlp_debug
from time import sleep

A_PATTERN = [
        0x0000,
        0x1234,
        0x5555,
        0xAAAA,
        0xfFFF,
    ]
def clk(id,address):
    phi1 = 1
    phi2 = 0
    debug.output(id,(address<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
    phi1 = 0
    phi2 = 0
    debug.output(id,(address<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
    phi1 = 0
    phi2 = 1
    debug.output(id,(address<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
    phi1 = 0
    phi2 = 0
    debug.output(id,(address<<10) | 0b1111111111 | phi1<<15 | phi2<<14)
    return

if __name__ == '__main__':
    debug = nlp_debug.debugger()

    debug.reset()
    id = debug.scan_devides()
    if id != 4:
        del debug
        exit()
    
    A_BUS_CTRL = 0x00
    Y_BUS_CTRL = 0x01
    ALU_CTRL = 0x02
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
    failed = 0
    pass_num = 0
    failed_list = list()
    phi1 = 0
    phi2 = 0
    debug.output(Y_BUS_CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)    #出力先を適当に設定
    debug.dir_set(IO_BUS,0x0000)
    debug.output(A_BUS_CTRL,(0x01<<10) | 0b1111111111)                    #入力をIOに設定
    debug.output(ALU_CTRL,0b011111110110)#ALU転送命令
    for A in range(0x10):
        #debug.output(IO_BUS,A)
        clk(Y_BUS_CTRL,A)
        sleep(1)
        
    if failed == 0:
        print("test all passed")
    del debug