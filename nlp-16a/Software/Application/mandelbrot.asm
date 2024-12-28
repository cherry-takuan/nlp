MAIN:
	STORE ZR, IP+@stack_addr

	MOV A, 0xFFF4 ;-12
	STORE A, IP+@Y
	
Y_LOOP:
	MOV A, 0xFFD8 ;-12
	STORE A, IP+@X
	X_LOOP:
		CALL IP+@M_L1
		
		LOAD A, IP+@X
		INC A, A
		STORE A, IP+@X
		CMP A, 0x28
		JMP.s IP+@X_LOOP
	
	MOV  A, 0x40
	CALL 0x11

	LOAD A, IP+@stack_addr
	CALL 0x19
	CALL 0x15

	LOAD A, IP+@Y
	INC A, A
	STORE A, IP+@Y

	CMP A, 0x0C
    JMP.s IP+@Y_LOOP
	RET

X:
    .dw 0x00
Y:
    .dw 0x00

M_L1:
	PUSH A
	PUSH B
	PUSH C
	PUSH D
	;int a_tmp = x*229/100;
	LOAD A, IP+@X
	CALL IP+@RPN_A
	MOV A, 0xE5
	CALL IP+@RPN_A
	CALL IP+@RPN_MUL

	MOV A, 0x64
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV
	
	CALL IP+@POP_A
	STORE A, IP+@A_TMP

	;int c = a;
	MOV C, A

    ;int b_tmp = y*416/100;
	LOAD A, IP+@Y
	CALL IP+@RPN_A
	MOV A, 0x01A0
	CALL IP+@RPN_A
	CALL IP+@RPN_MUL
	MOV A, 0x64
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV
	CALL IP+@POP_A
	STORE A, IP+@B_TMP

	;int d = b;
	MOV D, A

	; i=0;
	STORE ZR, IP+@I_TMP
	

M_L1_1:
	; a = a_tmp
	; b = b_tmp
	LOAD A, IP+@A_TMP
	LOAD B, IP+@B_TMP
	CALL IP+@M_L2
	CMP A, 0x05
	JMP.ns IP+@M_L1_1END1

	LOAD B, IP+@I_TMP
	CMP B, 0x10
	JMP.ns IP+@M_L1_1END2
	INC B, B
	STORE B, IP+@I_TMP
	JMP IP+@M_L1_1

M_L1_1END1:
	LOAD A, IP+@I_TMP
	CMP A, 0x0A
	ADD.ns A, A, 0x07
	ADD A, A, 0x30
	CALL 0x11
	JMP IP+@M_L1_END
M_L1_1END2:
	MOV A, 0x20
	CALL 0x11
M_L1_END:
	POP D
	POP C
	POP B
	POP A
	RET
A_TMP:
    .dw 0x00
B_TMP:
    .dw 0x00
I_TMP:
    .dw 0x00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

M_L2:
	; 中置記法を手で逆ポーランドに変換
	; RPNインタプリタはCALL命令列で記述することにする
	; a,b,c,dに数値を入れる
	; c,dは次のループでも使う値が保持
	; aには判定式の結果が入る
	; bは破壊

	;int t = a + ( c * c -  d * d ) / 50; //PUSH
	;  a  c  c *  d  d * - 50 / +
	
	CALL IP+@RPN_A

	CALL IP+@RPN_C
	CALL IP+@RPN_C
	CALL IP+@RPN_MUL

	CALL IP+@RPN_D
	CALL IP+@RPN_D
	CALL IP+@RPN_MUL

	CALL IP+@RPN_SUB

	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV

	CALL IP+@RPN_ADD
	
	CALL IP+@POP_A
	PUSH A
	

    ;d = b + 2 * ((c*(d/50)) + (c * (d- ( (d/50)*50))/50 ) );
	;    B  2  C  D 50 / *  C  D  D 50 / 50 * - * 50 / + * +
	CALL IP+@RPN_B
	
	MOV A, 0x02
	CALL IP+@RPN_A

	CALL IP+@RPN_C

	CALL IP+@RPN_D;(d/50)
	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV
	CALL IP+@RPN_MUL

	CALL IP+@RPN_C
	CALL IP+@RPN_D
	CALL IP+@RPN_D

	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV
	
	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_MUL
	CALL IP+@RPN_SUB
	CALL IP+@RPN_MUL

	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV
	CALL IP+@RPN_ADD
	CALL IP+@RPN_MUL
	CALL IP+@RPN_ADD

	CALL IP+@POP_A
	MOV D, A


    ;c = t;//POP
	POP C
	
	;( c / 50 ) * ( c / 50 ) + ( d / 50 ) * ( d / 50 )
	; C 50 /  C 50 / *  D 50 /  D 50 / * + 
	CALL IP+@RPN_C
	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV

	CALL IP+@RPN_C
	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV

	CALL IP+@RPN_MUL

	CALL IP+@RPN_D
	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV

	CALL IP+@RPN_D
	MOV A, 0x32
	CALL IP+@RPN_A
	CALL IP+@RPN_DIV

	CALL IP+@RPN_MUL

	CALL IP+@RPN_ADD

	CALL IP+@POP_A
	;CALL 0x15
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;以下RPNインタプリタ

;逆ポーランド記法の計算機を作る
RPN_A:
	CALL IP+@PUSH_A
	RET
RPN_B:
	PUSH A
	MOV A, B
	CALL IP+@PUSH_A
	POP A
	RET
RPN_C:
	PUSH A
	MOV A, C
	CALL IP+@PUSH_A
	POP A
	RET
RPN_D:
	PUSH A
	MOV A, D
	CALL IP+@PUSH_A
	POP A
	RET
RPN_ADD:
	PUSH A
	PUSH B
	PUSH C
	CALL IP+@POP_A
	MOV C, A
	CALL IP+@POP_A
	MOV B, A
	ADD A, B, C
	CALL IP+@PUSH_A
	POP C
	POP B
	POP A
	RET
RPN_SUB:
	PUSH A
	PUSH B
	PUSH C
	CALL IP+@POP_A
	MOV C, A
	CALL IP+@POP_A
	MOV B, A
	SUB A, B, C
	CALL IP+@PUSH_A
	POP C
	POP B
	POP A
	RET
RPN_MUL:
	PUSH A
	PUSH B
	PUSH C
	CALL IP+@POP_A
	MOV C, A
	CALL IP+@POP_A
	MOV B, A
	CALL IP+@MUL
	CALL IP+@PUSH_A
	POP C
	POP B
	POP A
	RET
RPN_DIV:
	PUSH A
	PUSH B
	PUSH C
	CALL IP+@POP_A
	MOV C, A
	CALL IP+@POP_A
	MOV B, A
	CALL IP+@DIV
	CALL IP+@PUSH_A
	POP C
	POP B
	POP A
	RET

PUSH_A:
	PUSH B
	PUSH C
	LOAD B, IP+@stack_addr
	MOV C, IP+@stack
	;MOV C, 0xA000
	STORE A, B+C
	INC B, B
	STORE B, IP+@stack_addr
	;MOV A, B
	;CALL 0x19
	;CALL 0x15
	POP C
	POP B
	RET
POP_A:
	PUSH B
	PUSH C
	LOAD B, IP+@stack_addr
	DEC B, B
	MOV C, IP+@stack
	;MOV C, 0xA000
	LOAD A, B+C
	STORE B, IP+@stack_addr
	;MOV A, B
	;CALL 0x19
	;CALL 0x15
	POP C
	POP B
	RET

;乗算に使うレジスタはBとCの間で掛け算してAに結果を置く
;乗算に使うレジスタはBとCの間で掛け算してAに結果を置く
MUL:
	PUSH B
	PUSH C
    PUSH D
	MOV A, 0x00
	
	CMP B, 0x00
	JMP.ns IP+@MUL_B
	INC A, A
	NOT B, B
	INC B, B
MUL_B:
	CMP C, 0x00
	JMP.ns IP+@MUL_C
	INC A, A
	NOT C, C
	INC C, C
MUL_C:
	PUSH A
	MOV D, C
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
	POP C
	CMP C, 0x01
	NOT.z A, A
	CMP C, 0x01
	INC.z A, A
    POP D
	POP C
	POP B
	RET

DIV:
	PUSH C
    PUSH D

	MOV A, 0x00
	
	CMP B, 0x00
	JMP.ns IP+@DIV_B
	INC A, A
	NOT B, B
	INC B, B
DIV_B:
	CMP C, 0x00
	JMP.ns IP+@DIV_C
	INC A, A
	NOT C, C
	INC C, C
DIV_C:
	PUSH A
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
	POP C
	CMP C, 0x01
	NOT.z A, A
	CMP C, 0x01
	INC.z A, A

    POP D
	POP C
	RET

stack_addr:
	.dw 0x00

stack:
	.dw 0x00
; 以降スタック領域