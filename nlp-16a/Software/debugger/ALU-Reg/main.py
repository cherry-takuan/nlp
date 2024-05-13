import nlp_debug
from time import sleep
import random
Func = {
        "A+B"       :0b011111010010,
        "A-B"       :0b011111100010,
        
        "A_INC"     :0b011111110110,
        "A_DEC"     :0b011111000110,

        "A<<1"      :0b011111001001,
        "A>>1"      :0b011111001101,

        
        "A_AND_B"   :0b011111011000,
        "A_OR_B"    :0b011111010100,
        "A_XOR_B"   :0b011111011100,

        "A"         :0b011111000000,
        "NOT_A"     :0b011111001100,
    }
Func = {

        "A+B"       :0b011111010100,
        "A-B"       :0b011111100100,
        
        "A_INC"     :0b011111110110,
        "A_DEC"     :0b011111000110,

        "A<<1"      :0b011111001001,
        "A>>1"      :0b011111001101,
        "A>>1"      :0b011111001011,

        
        "A_AND_B"   :0b011111011000,
        "A_OR_B"    :0b011111010010,
        "A_XOR_B"   :0b011111011010,

        "A"         :0b011111000000,
        "NOT_A"     :0b011111001010,
        
        
        "A+B_M"     :0b011101010100,#MOV優先
        "A-B_M"     :0b011100100100,#アドレスモードより優先
        
        "A<<1_INC"  :0b011001001001,
        "A>>1_DEC"  :0b010001001101,

        "A+B_ADDR"  :0b011110010111,#アドレスモードADD
        "A-B_ADDR"  :0b011110100111,#アドレスモードSUB
    }
A_PATTERN = [
        0x0000,
        #0x1234,
        0x5555,
        0xAAAA,
        0xfFFF,
    ]
B_PATTERN = [
        #0x1234,

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
    for dmy in range(1):
        try:
            for F in Func.keys():
                print(F,":",dmy)
                for B in B_PATTERN:
                    for A in A_PATTERN:
                        #test_reg = 3
                        test_reg = random.randrange(0,13)
                        if test_reg >=11:
                            test_reg += 1
                        #test_reg = 12
                        #クロック初期化
                        phi1 = 0
                        phi2 = 0
                        debug.output(A_BUS_CTRL,(IO_ADDRESS<<10) | 0b1111111111)                    #入力をIOに設定
                        debug.output(Y_BUS_CTRL,(0x0F<<10) | 0b1111111111 | phi1<<15 | phi2<<14)    #出力先を適当に設定
                        debug.output(ALU_CTRL,0b011100000000 | random.randrange(0x00,0x7F))#ALU転送命令
                        debug.dir_set(IO_BUS,0xFFFF)                                                #IO用デバッガを出力モードに設定
                        print(A,B)
                        #入力Bの値をAccに転送
                        debug.output(IO_BUS,B)
                        #clk(Y_BUS_CTRL,0x0F)
                        clk(Y_BUS_CTRL,0x0F,0b1111111110)
                        #dmy = input("値を転送")
                        #入力Aの値を出力
                        debug.output(IO_BUS,A)
                        clk(Y_BUS_CTRL,test_reg)
                        #dmy = input("値を転送")
                        debug.dir_set(IO_BUS,0x0000)

                        debug.output(A_BUS_CTRL,(test_reg<<10) | 0b1111111111)                    #入力を0x00に設定
                        #演算命令をセット
                        #debug.output(ALU_CTRL,Func[F]^0b000010)
                        debug.output(ALU_CTRL,Func[F])
                        #dmy = input("Aに転送")
                        #test_regに結果を格納
                        clk(Y_BUS_CTRL,test_reg)
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
                        clk(Y_BUS_CTRL,test_reg)
                        
                        debug.dir_set(IO_BUS,0x0000)                                                #IO用デバッガを入力モードに設定

                        debug.output(A_BUS_CTRL,(test_reg<<10) | 0b1111111111)                    #入力を0x00に設定
                        #演算命令をセット
                        #debug.output(ALU_CTRL,Func[F]^0b000010)
                        debug.output(ALU_CTRL,Func[F]|0x800)
                        #dmy = input("Aに転送")
                        #0x00Regに結果を格納
                        clk(Y_BUS_CTRL,IO_ADDRESS)
                        
                        flag = debug.input(IO_BUS)

                        mask = 0b1100
                        DEC = 0x0000

                        if "A+B" == F or "A+B_ADDR" == F:
                            ans = A + B
                            mask = 0xE
                        elif "A-B" == F or "A-B_ADDR" == F:
                            ans = A - B
                            mask = 0xE
                            DEC = 0xFFFF
                        elif "A_AND_B" == F:
                            ans = A & B
                        elif "A_OR_B" == F:
                            ans = A | B
                        elif "A_XOR_B" == F:
                            ans = A ^ B
                        elif "A" == F or "A+B_M" == F  or "A-B_M" == F:
                            ans = A
                        elif "NOT_A" == F:
                            ans = ~A
                        elif "A_INC" == F or "A<<1_INC" == F:
                            ans = A + 1
                            #mask = 0xE
                        elif "A_DEC" == F  or "A>>1_DEC" == F:
                            ans = A - 1
                            B = 0xFFFF
                            #mask = 0xE
                            DEC = 0xFFFF
                        elif "A<<1" == F:
                            ans = (A<<1 & 0x7FFF) | (A & 0x8000)
                        elif "A>>1" == F:
                            ans = (A>>1 & 0x7FFF)| (A & 0x8000)

                        flag = flag & mask


                        ans &= 0xFFFF
                        ans = debug.Num_normalize(ans)

                        Z = 1
                        if ans ==  0:
                            Z = 0
                        V = 1
                        if (A^ B ^ DEC )& 0x8000 == 0 and (A^ans)& 0x8000 != 0:
                            V = 0
                        S = 0
                        if ans & 0x8000 == 0:
                            S = 1

                        if ans == value and (flag == ((S<<3 | Z<<2 | V<<1)& mask) ):
                            pass_num += 1
                            print("[ \033[32mpass\033[0m ]\tA:","{:04x}".format(A),"\tB:","{:04x}".format(B),"\tFunc:",F,"\ttest:","{:04x}".format(ans),"==","{:04x}".format(value),"{:04b}".format(flag),"{:04b}".format(((S<<3 | Z<<2 | V<<1)& mask) ),",\ttest",failed + pass_num,",Reg ID:","{:02x}".format(test_reg))
                        else:
                            failed += 1
                            print("\033[41m[failed]\tA:","{:04x}".format(A),"\tB:","{:04x}".format(B),"\tFunc:",F,"\ttest:","{:04x}".format(ans),"!=","{:04x}".format(value),"{:04b}".format(flag),"{:04b}".format(((S<<3 | Z<<2 | V<<1)& mask) ),",\tReg ID:","{:02x}".format(test_reg),"\033[0m")
                            wk = "\033[41m[failed]\tA:"+"{:04x}".format(A)+"\tB:"+"{:04x}".format(B)+"\tFunc:"+F+"\ttest:"+"{:04x}".format(ans)+"!="+"{:04x}".format(value)+"{:04b}".format(flag)+"{:04b}".format(((S<<3 | Z<<2 | V<<1)& mask) )+",\tReg ID:"+"{:02x}".format(test_reg)+"\033[0m"
                            failed_list.append(wk)
                            dmy = input()

        except KeyboardInterrupt:
            print("test\t",pass_num+failed)
            print("Failed\t",failed)
            print("passed\t",pass_num)    
            print("Error rate\t",round(failed/(failed + pass_num)*100,4),"%")    
            for wk in failed_list:
                print(wk)
            incode = input('test stop N, continue enter\n>>')
            if incode == "N":
                #print("debug log\ncommand    \t->\tresponse")
                #for data in debug.debug_log:
                #    print(data["command"],"\t->\t",data["response"])
                del debug
                exit()
    #print("debug log\ncommand    \t->\tresponse")
    #for data in debug.debug_log:
    #    print(data["command"],"\t->\t",data["response"])
    print("test\t",pass_num+failed)
    print("Failed\t",failed)
    print("passed\t",pass_num)
    if failed == 0:
        print("test all passed")
    del debug