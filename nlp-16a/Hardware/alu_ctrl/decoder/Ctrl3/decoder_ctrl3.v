module decode_ctrl3(Ctrl3,INTERNAL_MOV,ADDRESS_MODE,INTERNAL_INC_DEC,INTERNAL_DEC,Ctrl3_out);
    input Ctrl3,INTERNAL_MOV,ADDRESS_MODE,INTERNAL_INC_DEC,INTERNAL_DEC;
    output Ctrl3_out;
    wire tmp1;
    NAND NAND1(Ctrl3,INTERNAL_MOV,tmp1);
    NAND NAND2(tmp1,tmp1,Ctrl3_out);
endmodule