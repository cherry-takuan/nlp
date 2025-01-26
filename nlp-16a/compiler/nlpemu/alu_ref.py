# ハードウェアには触らない。あくまでも出力のリファレンスを出すだけ
class ALU:
    def __init__(self) -> None:
        self.func_table = {
            "ADD"       :0b011111010100,
            "SUB"       :0b011111100100,
            
            "INC"     :0b011111110110,
            "DEC"     :0b011111000110,

            "SHL"      :0b011111000001,
            "SHR"      :0b011111000011,
            
            "ROR"      :0b011111000001,#コードは仮
            "ROL"      :0b011111000011,#コードは仮

            
            "AND"   :0b011111011000,
            "OR"    :0b011111010010,
            "XOR"   :0b011111011010,

            "A"         :0b011111000000,
            "NOT"     :0b011111001010,
        }
    def Num_normalize(self,num):
        if num < 0:
            num = -num
            num = ~num
            num = num & 0xFFFF
            num += 1
        num &= 0xFFFF
        return num

    def flag_gen(self, A,B,ans,func):
        Z = 1
        V = 1
        S = 0
        dec = 0x0000
        if func == "SUB":
            dec = 0xFFFF
        if ans ==  0:
            Z = 0
        if ((A ^ B ^ dec )& 0x8000 == 0) and ((A ^ ans)& 0x8000 != 0):
            V = 0
        if ans & 0x8000 == 0:
            S = 1
        return Z, V, S

    def ref_gen(self, A,B,func):
        A = int(A)
        B = int(B)
        want_value = 0
        C = 0
        if func == "A":
            want_value = A
        elif func == "ADD":
            want_value = A + B
            C = want_value>0xFFFF
        elif func == "SUB":
            want_value = A - B
            C = want_value >= 0
        elif func == "INC":
            want_value = A+1
        elif func == "DEC":
            want_value = A-1
        elif func == "AND":
            want_value = A & B
        elif func == "OR":
            want_value = A | B
        elif func == "NOT":
            want_value = ~A
        elif func == "XOR":
            want_value = A ^ B
        elif func == "SHL":
            want_value = A<<1
        elif func == "SHR":
            mask = 0xFFFF  # 8ビットマスク (11111111)
            want_value = (A & mask) >> 1
        elif func == "MOV":
            want_value = A
        elif func == "ROL":
            want_value = A<<1
            #want_value |= ((A&0x8000) != 0) * 0x01
            want_value |= ((A&0x8000) != 0)
        elif func == "ROR":
            want_value = A>>1
            #want_value |= ((A&0x01) != 0) * 0x8000
            want_value |= ((A&0x01) != 0) << 15
        else:
            print("未定義ALU命令",func)
            exit(1)
        want_value = self.Num_normalize(want_value)
        #print(A,B,want_value)
        Z, V, S = self.flag_gen(A, B, want_value, func)
        return want_value, Z, V, S, C
    def cmp(self, A,B,func,result_value, result_flag):
        flag_mask = 0xC
        if func == "ADD" or func == "SUB":
            flag_mask = 0xE
        want_value, Z, V, S = self.ref_gen(A,B,func)
        return want_value == result_value and (result_flag & flag_mask == (S<<3 | Z<<2 | V<<1)&flag_mask )
