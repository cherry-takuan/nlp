module decode_ALU3(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU3_out);
    input Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    output ALU3_out;
    wire tmp1,tmp2;
    NAND NAND1(Ctrl0,~Ctrl2,ALU3_out);
endmodule