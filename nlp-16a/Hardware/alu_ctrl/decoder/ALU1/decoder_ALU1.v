module decode_ALU1(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU1_out);
    input Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    output ALU1_out;
    wire tmp1,tmp2;
    NAND NAND1(~Ctrl0,~Ctrl1,tmp1);
    NAND NAND2(tmp1,tmp1,tmp2);
    NAND NAND3(tmp2,Ctrl2,ALU1_out);
endmodule