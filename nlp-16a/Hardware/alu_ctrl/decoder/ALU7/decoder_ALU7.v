module decode_ALU7(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU7_out);
    input Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    output ALU7_out;
    NAND NAND4(~Ctrl0,Ctrl4,ALU7_out);
endmodule