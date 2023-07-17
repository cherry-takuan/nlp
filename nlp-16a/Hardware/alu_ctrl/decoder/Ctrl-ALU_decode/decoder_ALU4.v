module decode_ALU4(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU4_out);
    input Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    output ALU4_out;
    wire tmp1,tmp2;
    NAND NAND1(Ctrl0,Ctrl2,ALU4_out);
endmodule