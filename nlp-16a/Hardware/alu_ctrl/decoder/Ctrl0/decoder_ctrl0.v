module decode_ctrl0(Ctrl0,INTERNAL_MOV,ADDRESS_MODE,INTERNAL_INC_DEC,INTERNAL_DEC,Ctrl0_out);
    input Ctrl0,INTERNAL_MOV,ADDRESS_MODE,INTERNAL_INC_DEC,INTERNAL_DEC;
    output Ctrl0_out;
    wire tmp1,tmp2,tmp3;
    NAND NAND1(Ctrl0,ADDRESS_MODE,tmp1);
    NAND NAND2(tmp1,tmp1,tmp2);
    NAND NAND3(tmp2,INTERNAL_MOV,tmp3);
    NAND NAND4(tmp3,tmp3,Ctrl0_out);
endmodule