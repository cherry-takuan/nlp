module AND(
  a, b, x
);

  input a, b;
  output x;

  assign x = a & b;

endmodule // AND

module NAND(a, b, y);
    input a, b;
    output y;
    wire tmp;
    AND AND(a,b,tmp);

    assign y = ~tmp;
endmodule



module test_tb ();

    parameter clk_period_p = 10;

    reg Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag;
    wire [0:0] ALU0_out,ALU1_out,ALU2_out,ALU3_out,ALU4_out,ALU5_out,ALU6_out,ALU7_out;

    decode_ALU0 decode_ALU0(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU0_out);
    decode_ALU1 decode_ALU1(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU1_out);
    decode_ALU2 decode_ALU2(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU2_out);
    decode_ALU3 decode_ALU3(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU3_out);
    decode_ALU4 decode_ALU4(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU4_out);
    decode_ALU5 decode_ALU5(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU5_out);
    decode_ALU6 decode_ALU6(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU6_out);
    decode_ALU7 decode_ALU7(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU7_out);

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0);
        $monitor("%t: |%b, %b, %b, %b, %b | %b, %b, %b |     C0 = %b, C1 = %b, C2 = %b, C3 = %b, C4 = %b, C5 = %b, c_flag = %b", $time,ALU0_out,ALU1_out,ALU2_out,ALU3_out,ALU4_out,ALU5_out,ALU6_out,ALU7_out,Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag);
        //ADD
        Ctrl0 = 0;
        Ctrl1 = 1;
        Ctrl2 = 0;
        Ctrl3 = 0;
        Ctrl4 = 1;
        Ctrl5 = 0;
        #clk_period_p;
        //SUB
        Ctrl0 = 0;
        Ctrl1 = 1;
        Ctrl2 = 0;
        Ctrl3 = 0;
        Ctrl4 = 0;
        Ctrl5 = 1;
        #clk_period_p;
        //OR
        Ctrl0 = 0;
        Ctrl1 = 0;
        Ctrl2 = 1;
        Ctrl3 = 0;
        Ctrl4 = 1;
        Ctrl5 = 0;
        #clk_period_p;
        //NOT
        Ctrl0 = 0;
        Ctrl1 = 0;
        Ctrl2 = 1;
        Ctrl3 = 1;
        Ctrl4 = 0;
        Ctrl5 = 0;
        #clk_period_p;
        //XOR
        Ctrl0 = 0;
        Ctrl1 = 0;
        Ctrl2 = 1;
        Ctrl3 = 1;
        Ctrl4 = 1;
        Ctrl5 = 0;
        #clk_period_p;
        //AND
        Ctrl0 = 0;
        Ctrl1 = 0;
        Ctrl2 = 0;
        Ctrl3 = 1;
        Ctrl4 = 1;
        Ctrl5 = 0;
        #clk_period_p;
        //MOV
        Ctrl0 = 0;
        Ctrl1 = 0;
        Ctrl2 = 0;
        Ctrl3 = 0;
        Ctrl4 = 0;
        Ctrl5 = 0;
        #clk_period_p;
        //INC
        Ctrl0 = 0;
        Ctrl1 = 1;
        Ctrl2 = 1;
        Ctrl3 = 0;
        Ctrl4 = 1;
        Ctrl5 = 1;
        #clk_period_p;
        //DEC
        Ctrl0 = 0;
        Ctrl1 = 1;
        Ctrl2 = 1;
        Ctrl3 = 0;
        Ctrl4 = 0;
        Ctrl5 = 0;
        #clk_period_p;
        //SLA
        Ctrl0 = 1;
        Ctrl1 = 0;
        Ctrl2 = 0;
        Ctrl3 = 1;
        Ctrl4 = 0;
        Ctrl5 = 0;
        #clk_period_p;
        //SLL
        Ctrl0 = 1;
        Ctrl1 = 0;
        Ctrl2 = 0;
        Ctrl3 = 0;
        Ctrl4 = 0;
        Ctrl5 = 0;
        #clk_period_p;
        //ROL
        Ctrl0 = 1;
        Ctrl1 = 0;
        Ctrl2 = 0;
        Ctrl3 = 0;
        Ctrl4 = 1;
        Ctrl5 = 0;
        #clk_period_p;
        //SRA
        Ctrl0 = 1;
        Ctrl1 = 0;
        Ctrl2 = 1;
        Ctrl3 = 1;
        Ctrl4 = 0;
        Ctrl5 = 0;
        #clk_period_p;
        //SRL
        Ctrl0 = 1;
        Ctrl1 = 0;
        Ctrl2 = 1;
        Ctrl3 = 0;
        Ctrl4 = 0;
        Ctrl5 = 0;
        #clk_period_p;
        //ROR
        Ctrl0 = 1;
        Ctrl1 = 0;
        Ctrl2 = 1;
        Ctrl3 = 0;
        Ctrl4 = 1;
        Ctrl5 = 0;
        #clk_period_p;

        $finish;
    end
endmodule