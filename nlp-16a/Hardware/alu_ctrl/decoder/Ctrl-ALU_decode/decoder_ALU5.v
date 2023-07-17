module decode_ALU5(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU5_out);
    input Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    output ALU5_out;
    wire tmp1;
    NAND NAND1(~Ctrl1,~Ctrl3,tmp1);
    NAND NAND2(tmp1,tmp1,ALU5_out);
endmodule