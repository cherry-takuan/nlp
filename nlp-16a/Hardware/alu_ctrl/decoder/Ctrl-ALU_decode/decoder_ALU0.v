module decode_ALU0(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU0_out);
    input Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    output ALU0_out;
    NAND NAND1(~Ctrl0,Ctrl1,ALU0_out);
endmodule