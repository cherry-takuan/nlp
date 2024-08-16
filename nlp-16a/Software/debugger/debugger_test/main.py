import nlp_debug
from time import sleep
from tqdm import tqdm

if __name__ == '__main__':
    debug = nlp_debug.debugger()
    debug.reset()
    id = debug.scan_devides()
    if id != 1:
        del debug
        print("Error: Number of detected devices differs from configured value")
        exit(1)
    debugger_id = 0x00
    
    print("test1")
    debug.dir_set(debugger_id,0x00FF)
    for data in tqdm(range(0xFF)):
        debug.output(debugger_id,data)
        value = (debug.input(debugger_id)>>8) & 0xFF
        if data != value:
            print("\n\nFailed want:",data,"result:",value)
            debug.device_status(debugger_id)
            del debug
            exit(1)
    print("test2")
    debug.dir_set(debugger_id,0xFF00)
    for data in tqdm(range(0xFF)):
        debug.output(debugger_id,data<<8)
        value = debug.input(debugger_id) & 0xFF
        if data != value:
            print("\n\nFailed want:",data,"result:",value)
            debug.device_status(debugger_id)
            del debug
            exit(1)
    print("test passed")
    del debug