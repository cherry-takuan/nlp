;逆ポーランド記法の計算機を作る
CAL:
	MOV A, IP+@CALop
	STORE A, 0x8018			;数値入力のモード設定(0)

CALin:
	CALL 0x06				;文字の入力サブルーチン
	CALL 0x15				;ok
	;PUSH A					;数値をスタックに
	CALL IP+@PUSH_A
	JMP IP+@CALin
CALop:						;数値以外

	;CALL 0x11				;演算子表示
	;CALL 0x15				;ok
	MOV D, A
	CALL IP+@POP_A
	MOV C, A
	CALL IP+@POP_A
	MOV B, A
	CMP D, 0x2b				;足し算
	ADD.z A, B, C
	CMP D, 0x2d				;引き算
	SUB.z A, B, C
	CMP D, 0x2a				;掛け算
	CALL.z IP+@MUL
	CMP D, 0x2f				;割り算
	CALL.z IP+@DIV
	CMP D, 0x1B				;ESC
	RET.z

	CALL IP+@PUSH_A

	CALL 0x19
	CALL 0x15
	JMP IP+@CALin
; 0x01 0x02 + 0x03 0x04 - *

PUSH_A:
	PUSH B
	PUSH C
	LOAD B, IP+@stack_addr
	;MOV C, IP+@stack
	MOV C, 0xA000
	STORE A, B+C
	INC B, B
	STORE B, IP+@stack_addr
	POP C
	POP B
	RET
POP_A:
	PUSH B
	PUSH C
	LOAD B, IP+@stack_addr
	DEC B, B
	;MOV C, IP+@stack
	MOV C, 0xA000
	LOAD A, B+C
	STORE B, IP+@stack_addr
	POP C
	POP B
	RET

;乗算に使うレジスタはBとCの間で掛け算してAに結果を置く
MUL:
	PUSH B
	PUSH C
    PUSH D
	;結果格納の初期化
	MOV A,0x00
	;カウントの初期化
	MOV D, 0x00
MULmain:
	CMP D, 0x0F
	JMP.ns  IP+@MULend
	AND ZR, C, 0x01
	ADD.nz A, A, B
	SLL B, B
	SLR C, C
	INC D, D
	JMP IP+@MULmain
MULend:
    POP D
	POP C
	POP B
	RET

DIV:
	PUSH C
    PUSH D
    MOV D, C

DIV_L1:
    SLL C, C
    JMP.ns IP+@DIV_L1

    MOV A, 0x00

DIVloop:
    CMP C, D
    JMP.z IP+@DIVend

    SLL A, A
    SLR C, C

    CMP B, C
    ;JMP.s IP+@DIVloop
    JMP.c IP+@DIVloop
    OR A, A, 0x0001
    SUB B, B, C
    JMP IP+@DIVloop
DIVend:
    POP D
	POP C
	RET

stack_addr:
	.dw 0x00
stack:
	.dw 0x00