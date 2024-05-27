#!/usr/bin/env python3

import sys
import re


class assemble:
    def __init__(self):
        self.ASM_DEBUG_MODE = False
        self.COMMENT = ";"
        self.LABEL = ":"

        self.MNEMONIC = {
            #inst   bin         to      from1       from2
            "ADD"   :[0x0A,     ";",      ";",        ";"],
            "SUB"   :[0x09,     ";",      ";",        ";"],
            "ADC"   :[0x0E,     ";",      ";",        ";"],
            "SBB"   :[0x0D,     ";",      ";",        ";"],
            "INC"   :[0x1B,     ";",      ";",        ";;"],
            "DEC"   :[0x18,     ";",      ";",        ";;"],
            "INCC"  :[0x1F,     ";",      ";",        ";;"],
            "DECB"  :[0x1C,     ";",      ";",        ";;"],

            "OR"    :[0x12,     ";",      ";",        ";" ],
            "NOT"   :[0x14,     ";",      ";",        "" ],
            "XOR"   :[0x16,     ";",      ";",        ";" ],
            "AND"   :[0x06,     ";",      ";",        ";" ],

            "SLR"   :[0x30,     ";",      ";",        ";;"],
            "SLL"   :[0x20,     ";",      ";",        ";;"],

            "SAR"   :[0x34,     ";",      ";",        ";;"],
            "SAL"   :[0x24,     ";",      ";",        ";;"],

            "ROR"   :[0x32,     ";",      ";",        ";;"],
            "ROL"   :[0x22,     ";",      ";",        ";;"],


            "MOV"   :[0x00,     ";",      ";",        ";;" ],
            "JMP"   :[0x00,     "IP",     ";",        ";;" ],

            "PUSH"  :[0xD0,     ";",      "",         ""  ],
            "POP"   :[0xC0,     ";",      "",         ""  ],

            "CALL"  :[0xB0,     "IP",     ";",        ";;" ],
            "RET"   :[0xC0,     "IP",     "",         ""  ],
            "IRET"  :[0xE0,     "IP",     "",         ""  ],

            "LOAD"  :[0x80,     ";",      ";",        ";;" ],
            "STORE" :[0x90,     ";",      ";",        ";;" ],

            "CMP"   :[0x09,     "ZR",      ";",        ";" ]
        }
        self.REG = {
            "IR1"   :0x00,    "IR2"   :0x01,    "IR3"   :0x03,    "IV"    :0x02,
            "FLAG"  :0x04,    "A"     :0x05,    "B"     :0x06,    "C"     :0x07,
            "D"     :0x08,    "E"     :0x09,    "F"     :0x0A,    "MEM"   :0x0B,
            "ADDR"  :0x0C,    "IP"    :0x0D,    "SP"    :0x0E,    "ZR"    :0x0F,
            ""    :0x00,";;"    :0x00,
        }
        self.FLAG = {
            "NOP"   :0x00,
            "C"     :0x09,    "V"    :0x0B,    "Z"     :0x0D,    "S"    :0x0F,
            ""      :0x01,
            "NC"    :0x08,    "NV"   :0x0A,    "NZ"    :0x0C,    "NS"   :0x0E
            
        }
        self.err_msg_str = ""
        self.msg_str = ""
        self.bin = list()
        self.label_list = list()

    def oprand(self,op):
        oprand_list = []
        imm = 0x0000
        label = ""
        relative = ""
        oprand_tmp_list = []

        for oprand_str in op[1:]:
            oprands = re.split("[+-]",oprand_str)
            oprand_tmp_list += oprands
            if "+" in oprand_str:
                relative = "+"
            elif "-" in oprand_str:
                relative = "-"
        for tmp in oprand_tmp_list:
            tmp = tmp.split(",")[0]
            if tmp in self.REG.keys():
                oprand_list.append(tmp)
            elif tmp[0:2] == "0X":
                try:
                    num = int(tmp[2:],16)
                except:
                    self.err_msg_str += "Error : value error [" + str(tmp)+"]\n"
                    return oprand_list, imm, label, relative
                if num <= 0xFF:
                    imm = num
                    oprand_list.append("IR2")
                elif num <= 0xFFFF:
                    imm = num
                    oprand_list.append("IR3")
                else:
                    self.err_msg_str += "Error:Imm error [" + str("{:04x}".format(num))+"]\n"
                    return oprand_list, imm, label, relative
            else:
                oprand_list.append("LABEL")
                label = tmp

        return oprand_list, imm, label, relative

    def path_1(self,line_str, line_num):
        line = dict()
        line["type"] = "" #inst,label,data,None
        line["data"] = None
        line["length"] = 0
        line["raw"] = ""
        line["raw"] = str(line_num)+":\t"+line_str
        
        op = list()
        for wk in line_str.split():
            for wk2 in wk.split(","):
                if wk2 != "":
                    op.append(wk2)
        #op = line_str.split()
        if len(op) < 1:
            line["type"] = "None" #inst,label,data,None
            line["data"] = None
            line["length"] = 0
            line["raw"] = ""
            line["raw"] = str(line_num)+":\t"+line_str
            return line
        if self.ASM_DEBUG_MODE:
            self.msg_str += str(line_num)+":\t"+str(op)+"\n"
            #print(line_num,":\t",op)
            
        if len(op[0].split(".")) == 2:
            opcode = op[0].split(".")[0]
        elif len(op[0].split(".")) == 1:
            opcode = op[0].split(".")[0]
        else:
            self.err_msg_str += "Error : illigal flag\n"
            self.err_msg_str += str(line_num)+":\t"+str(line_str)+"\n"
            return line

        if opcode in self.MNEMONIC.keys():
            #print(opcode,MNEMONIC[opcode],"flag:",op_flag,"oprand:",oprand(op))
            oprand_list, imm,  label, relative = self.oprand(op)
            if self.err_msg_str !="":
                self.err_msg_str += str(line_num)+":\t"+str(line_str)+"\n"
                return line
            line["type"] = "inst"
            line["data"] = op
            if opcode == "POP" or opcode == "PUSH" or opcode == "RET" or opcode == "IRET":
                line["length"] = 1
            else:
                line["length"] = 2
                for reg in oprand_list:
                    if reg == "IR3":
                        line["length"] = 3
        elif op[0][0] == ".":
            if self.ASM_DEBUG_MODE:
                self.msg_str += "Extended command:"+str(op[0])+str(op)+"\n"
                #print("Extended command:",op[0],op)
            if "DW" in op[0]:
                line["type"] = "data"
                line["data"] = op[1]
                line["length"] = 1
        else:
            #LABEL
            if op[0][-1] == ":":
                line["type"] = "label"
                line["data"] = op[0][:-1]
                line["length"] = 0
            else:
                self.err_msg_str += "Error : illigal label ["+str(op[0])+"]\n"
                self.err_msg_str += str(line_num)+":\t"+str(line_str)+"\n"
                return line
        return line
    def label_search(self,middle_list,label,now_address):
        label_address = 0
        abs_label = True
        if label[0] == "@":
            label = label[1:]
            abs_label = False
        for line in middle_list:
            if line["type"] == "label" and line["data"] == label:
                if abs_label == True:
                        return label_address
                else:
                    return label_address - now_address
            else:
                label_address += line["length"]
        return None
    def path_2(self,middle_list):
        address = 0
        for line_num in range(len(middle_list)):
            line = middle_list[line_num]
            address += line["length"]
            if line["type"] == "inst":
                op = line["data"]
                oprand_list, imm, label, relative = self.oprand(op)
                if label != "":
                    label_address = self.label_search(middle_list,label,address)
                    if label_address == None:
                        self.err_msg_str += "Error : label is not found ["+str(label)+"]\n"
                        self.err_msg_str += str(line["raw"])+"\n"
                        return True

                    if abs(label_address) > 0xFFFF:
                        self.err_msg_str += "Error : label address is out of range["+str(label)+"]\n"
                        self.err_msg_str += str(line["raw"])+"\n"
                        return True
                    if self.ASM_DEBUG_MODE:
                        self.msg_str += str(label)+"\t["+str(label_address)+"]\tlength:"+str(middle_list[line_num]["length"])+"\n"
                        #print(label,label_address,"\tlength:",middle_list[line_num]["length"])
                    if len(op[0].split(".")) == 2:
                        opcode = op[0].split(".")[0]
                    elif len(op[0].split(".")) == 1:
                        opcode = op[0].split(".")[0]
                    adressing = opcode == "JMP" or opcode =="CALL" or opcode =="LOAD" or opcode =="STORE"
                    #相対アドレッシングかつJMP類は0以下の条件がいらない
                    if  (line["length"] == 2 and #長さが2ワードで
                            (label_address > 0x00FF or #0x00FF以上は問題あり
                            (label_address < 0 and label[0] != "@" and adressing != True))):#もしくは相対アドレッシングではなく
                        if self.ASM_DEBUG_MODE:
                            self.msg_str += str(label)+"\t"+str(label_address)+"\tlength:"+str(middle_list[line_num]["length"])+"\n"
                            #print(label,label_address,"\tlength:",middle_list[line_num]["length"])
                            self.msg_str += "Warning:label address is out of range["+str(label_address)+"]"+"\n"
                            #print("Warning:label address is out of range[",label_address,"]")
                            print(line["raw"])
                        self.msg_str += (label+"{:04x}".format(label_address)+"\tlength:"+str(middle_list[line_num]["length"]))+"\n"
                        self.msg_str += "Warning:label address is out of range["+"{:04x}".format(label_address)+"]"+"\n"
                        self.msg_str += line["raw"]+"\n"
                        middle_list[line_num]["length"] = 3
                        return False
        return True

    def view_1word(self,address,raw,data1):
        self.msg_str += ("{:08x}".format(address)+":\t"+"{:04x}".format(data1)+",    "+"     "+"  |"+raw.replace("\t","").replace("  "," "))+"\n"
        tmp = dict()
        tmp["address"] = address
        tmp["bin"] = data1
        self.bin.append(tmp)
    def view_2word(self,address,raw,data1,data2):
        self.msg_str +=("{:08x}".format(address)+":\t"+"{:04x}".format(data1)+","+"{:04x}".format(data2)+",    "+"  |"+raw.replace("\t","").replace("  "," "))+"\n"
        tmp = dict()
        tmp["address"] = address
        tmp["bin"] = data1
        self.bin.append(tmp)
        tmp = dict()
        tmp["address"] = address+1
        tmp["bin"] = data2
        self.bin.append(tmp)
    def view_3word(self,address,raw,data1,data2,data3):
        self.msg_str +=("{:08x}".format(address)+":\t"+"{:04x}".format(data1)+","+"{:04x}".format(data2)+","+"{:04x}".format(data3)+", |"+raw.replace("\t","").replace("  "," "))+"\n"
        tmp = dict()
        tmp["address"] = address
        tmp["bin"] = data1
        self.bin.append(tmp)
        tmp = dict()
        tmp["address"] = address+1
        tmp["bin"] = data2
        self.bin.append(tmp)
        tmp = dict()
        tmp["address"] = address+2
        tmp["bin"] = data3
        self.bin.append(tmp)


    def path_3(self,middle_list):
        address = 0x00
        for line in middle_list:
            if line["type"] == "label":
                if self.ASM_DEBUG_MODE:
                    #self.msg_str += "LABEL :"+str(line["data"])+"\n"
                    #print("LABEL :",line["data"])
                    pass
                self.msg_str += ("LABEL :"+line["data"])+"\n"
                label_data = dict()
                label_data["label"] = line["data"]
                label_data["address"] = address
                self.label_list.append(label_data)
                continue
            elif line["type"] == "data":
                try:
                    num = int(line["data"][2:],16)
                except:
                    self.err_msg_str += "Error : value error["+str(line["data"])+"]\n"
                    self.err_msg_str += str(line["raw"])+"\n"
                    return False
                if num > 0xFFFF:
                    self.err_msg_str += "Error : value error["+str(line["data"])+"]\n"
                    self.err_msg_str += str(line["raw"])+"\n"
                    return False
                self.view_1word(address,line["raw"]+" \t: "+chr(int(num)),num)
                address += line["length"]
            elif line["type"] == "inst":
                op = line["data"]
                if len(op[0].split(".")) == 2:
                    opcode = op[0].split(".")[0]
                    op_flag = op[0].split(".")[1]
                elif len(op[0].split(".")) == 1:
                    opcode = op[0].split(".")[0]
                    op_flag = ""
                oprand_list, imm, label, relative = self.oprand(op)
                if self.err_msg_str != "":
                    self.err_msg_str += str(line["raw"])+"\n"
                    return False
                Reg1 = self.MNEMONIC[opcode][1]
                if Reg1 == ";" and len(oprand_list) > 0:
                    reg = oprand_list.pop(0)
                    if reg in self.REG.keys():
                        Reg1 = reg
                    elif line["length"] ==2:
                        Reg1 = "IR2"
                    elif line["length"] ==3:
                        Reg1 = "IR3"
                Reg2 = self.MNEMONIC[opcode][2]
                if Reg2 == ";" and len(oprand_list) > 0:
                    reg = oprand_list.pop(0)
                    if reg in self.REG.keys():
                        Reg2 = reg
                    elif line["length"] ==2:
                        Reg2 = "IR2"
                    elif line["length"] ==3:
                        Reg2 = "IR3"
                Reg3 = self.MNEMONIC[opcode][3]
                #if Reg3 == ";;" and relative == "":
                    #Reg3 = ""
                if Reg3 == ";" and len(oprand_list) > 0:
                    reg = oprand_list.pop(0)
                    if reg in self.REG.keys():
                        Reg3 = reg
                    elif line["length"] ==2:
                        Reg3 = "IR2"
                    elif line["length"] ==3:
                        Reg3 = "IR3"
                if Reg3 == ";;" and len(oprand_list) > 0 and relative != "":
                    reg = oprand_list.pop(0)
                    if reg in self.REG.keys():
                        Reg3 = reg
                    elif line["length"] ==2:
                        Reg3 = "IR2"
                    elif line["length"] ==3:
                        Reg3 = "IR3"
                
                if len(oprand_list) != 0:
                    self.err_msg_str += "Error : Unused Reg exists["+str(oprand_list)+"]\n"
                    self.err_msg_str += str(line["raw"])+"\n"
                    return False

                addressing = (opcode == "JMP" or opcode =="CALL" or opcode =="LOAD" or opcode =="STORE" or opcode =="MOV")
                if label != "":
                    label_address = self.label_search(middle_list,label,address+line["length"])
                    imm = label_address
                    if addressing and label_address < 0:
                        #アドレスが負なら正数にしてアドレッシングを減算にする
                        imm = -label_address
                        if relative == "-":
                            relative = "+"
                        else:
                            relative = "-"

                data1 = 0x0000
                data2 = 0x0000
                data3 = 0x0000
                data1 = self.MNEMONIC[opcode][0] << 8
                if op_flag in self.FLAG.keys():
                    data1 |= self.FLAG[op_flag] << 4
                else:
                    if self.ASM_DEBUG_MODE:
                        self.msg_str += "Error : Flag does not exist["+str(op_flag)+"]"+"\n"
                        #print("Error : Flag does not exist[",op_flag,"]")
                        self.msg_str += str(line["raw"])+"\n"
                        #print(line["raw"])
                    #exit(1)
                    self.err_msg_str += "Error : Unknown Flag ["+str(op_flag)+"]\n"
                    self.err_msg_str += str(line["raw"])+"\n"
                    return False
                
                if Reg1 == ";" or Reg2 == ";" or Reg3 == ";":
                    self.err_msg_str += "Error : Reg is missing. ["+str(line["data"])+"]\n"
                    self.err_msg_str += str(line["raw"])+"\n"
                    return False
                data1 |= self.REG[Reg1]

                if addressing and Reg3!=";;":
                    if relative == "+":
                        data1 |= 0x0A00
                    if relative == "-":
                        data1 |= 0x0900

                data2 |= self.REG[Reg2] << 12
                data2 |= self.REG[Reg3] << 8
                data2 |= imm & 0xFF

                data3 = imm & 0xFFFF

                if line["length"] == 1:
                    self.view_1word(address,line["raw"],data1)
                elif line["length"] == 2:
                    self.view_2word(address,line["raw"],data1,data2)
                elif line["length"] == 3:
                    self.view_3word(address,line["raw"],data1,data2,data3)

                address += line["length"]
            else:
                pass

    def main(self,source,debug=False):
        #構文解析
        self.ASM_DEBUG_MODE = debug
        middle_list = list()
        for line_num in range(len(source)):
            line_str = source[line_num].split(self.COMMENT)[0].replace('\n', '').upper()#コメント
            if self.ASM_DEBUG_MODE:
                #self.msg_str += str(line_num)+":\t"+str(line_str)+"\n"
                #print(line_num,":\t",line_str,end="")
                pass
            line = self.path_1(line_str,line_num)
            if self.err_msg_str != "":
                return False
            if line["type"] != "None":
                middle_list.append(line)
        self.msg_str += ("[ ok ]path1 successd\n")
        #ラベル整理(命令ワード確定)
        #for line in middle_list:
            #print(line)
        while True:
            if self.path_2(middle_list):
                break
        if self.err_msg_str != "":
            return False
        self.msg_str += ("[ ok ]path2 successd\n")
        self.path_3(middle_list)
        if self.err_msg_str != "":
            return False
        self.msg_str += ("[ ok ]path3 successd\n")
        return True

    def Num_normalize(self,num):
        if num < 0:
            num = -num
            num = ~num
            num = num & 0xFFFF
            num += 1
        return num

if __name__ == "__main__":
    source=sys.stdin.readlines()
    #main(source)
    asm = assemble()
    
    if asm.main(source,debug=True):
        print(asm.msg_str,file=sys.stderr)
        #for bin in asm.bin:
            #print("{:04x}".format(bin["address"]) ," : " "{:04x}".format(bin["bin"]))
        """
        with open("./test.hex", mode='w') as f:
            for bin in asm.bin:
                #print("{:04x}".format(bin["address"]) ," : " "{:04x}".format(bin["bin"]))
                f.write("{:04x}".format(bin["bin"]))
        """
        for label in asm.label_list:
            print(label["label"],"\t{:04X}".format(label["address"]),file=sys.stderr)

        for line in asm.bin:
            print("{:04X},".format(line["bin"]),end="")
        
        #print('bin      #########')
        #print(program_bin)
        #print('##################')
        cn = 0
        most_side = list()
        last_side = list()
        for line in asm.bin:
            most_side.append((line["bin"] >> 8) & 0xFF)
            last_side.append((line["bin"]) & 0xFF)
            cn+=1
    else:
        print(asm.err_msg_str,file=sys.stderr)