#!/usr/bin/env python3
import sys
import re

input=sys.stdin.readlines()

lines = input

ctrl_table = {
    "0":"0x0000",
    "a":"0x0007",
    "b":"0x0008",
    "t":"0x0009",
    "n":"0x000A",
    "v":"0x000B",
    "f":"0x000C",
    "r":"0x000D",
    "\\":"0x0024",
}
cn = 0
print(";line:",len(lines))
for line in lines:
    cn += 1
    line = line.replace("\n","")
    if ".ascii" in line:
        print(";string(ascii)")
        str_name = re.search("(?<=.ascii).*?(?= )",line)
        if str_name != None:
            str_name = str_name.group()
            print(";label :\t",str_name)
            #print("(?<="+str(str_name)+"\").*(?=\")")
            ascii_str = re.search("(?<="+str(str_name)+" \").*(?=\")",line)
            if ascii_str != None:
                ascii_str = ascii_str.group()
                print(";str :\t",ascii_str)
                print(str_name[1:]+":")
                ctrl_char = False
                for char in ascii_str:
                    if ctrl_char == True:
                        ctrl_char = False
                        print(";ctrl char:",char)
                        print(".dw "+str(ctrl_table[char]))
                    elif "\\" in char:
                        ctrl_char = True
                        #print("ctrl char")
                    else:
                        print(".dw "+format(char.encode('ascii')[0], '#04x'))

        else:
            print("Error : no label")
    else:
        print(line)