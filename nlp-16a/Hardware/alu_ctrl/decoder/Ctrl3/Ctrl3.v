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

    reg Ctrl3,INTERNAL_MOV,ADDRESS_MODE,INTERNAL_INC_DEC,INTERNAL_DEC;
    wire [0:0] out_Ctrl3;

    decode_ctrl3 decode_ctrl3(Ctrl3,INTERNAL_MOV,ADDRESS_MODE,INTERNAL_INC_DEC,INTERNAL_DEC,Ctrl3_out);

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0);
        $monitor("%t: Ctrl3 = %b, INTERNAL_MOV =%b, ADDRESS_MODE = %b, INTERNAL_INC_DEC = %b, INTERNAL_DEC = %b, Ctrl3_out = %b", $time,Ctrl3,INTERNAL_MOV,ADDRESS_MODE,INTERNAL_INC_DEC,INTERNAL_DEC,Ctrl3_out);
        //通常モード
        Ctrl3 = 0;
        INTERNAL_MOV = 1;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;

        Ctrl3 = 1;
        INTERNAL_MOV = 1;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;

        //内部処理 MOV
        Ctrl3 = 0;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;

        Ctrl3 = 1;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;

        //内部処理 INC
        Ctrl3 = 0;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 1;
        #clk_period_p;

        Ctrl3 = 1;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 1;
        #clk_period_p;

        //内部処理 INC
        Ctrl3 = 0;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 0;
        #clk_period_p;

        Ctrl3 = 1;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 1;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 0;
        #clk_period_p;

      //アドレス演算モード//
        //通常モード
        Ctrl3 = 0;
        INTERNAL_MOV = 1;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;
        Ctrl3 = 1;
        INTERNAL_MOV = 1;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;
        //内部処理 MOV
        Ctrl3 = 0;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;

        Ctrl3 = 1;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 1;
        INTERNAL_DEC = 1;
        #clk_period_p;

        //内部処理 INC
        Ctrl3 = 0;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 1;
        #clk_period_p;

        Ctrl3 = 1;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 1;
        #clk_period_p;

        //内部処理 INC
        Ctrl3 = 0;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 0;
        #clk_period_p;

        Ctrl3 = 1;
        INTERNAL_MOV = 0;
        ADDRESS_MODE = 0;
        INTERNAL_INC_DEC = 0;
        INTERNAL_DEC = 0;
        #clk_period_p;

        $finish;
    end
endmodule