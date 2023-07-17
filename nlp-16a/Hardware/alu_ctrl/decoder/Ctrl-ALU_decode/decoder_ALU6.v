module decode_ALU6(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU6_out);
    input Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    output ALU6_out;
    wire tmp1,tmp2,tmp3;
    NAND NAND1(Ctrl1,~Ctrl2,tmp1);
    NAND NAND2(~Ctrl1,Ctrl4,tmp2);
    NAND NAND3(tmp1,tmp2,tmp3);
    NAND NAND4(tmp3,tmp3,ALU6_out);
endmodule