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
    wire [0:0] out_Ctrl0;

    decode_ALU2 decode_ALU2(Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU2_out);

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0);
        $monitor("%t: Ctrl0 = %b, Ctrl1 = %b, Ctrl2 = %b, Ctrl3 = %b, Ctrl4 = %b, Ctrl5 = %b, c_flag = %b, ALU2_out = %b, ", $time,Ctrl0,Ctrl1,Ctrl2,Ctrl3,Ctrl4,Ctrl5,c_flag,ALU2_out);
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