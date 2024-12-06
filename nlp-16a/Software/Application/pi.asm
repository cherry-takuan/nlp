; 参考 : 「自作TTLコンピュータで円周率を計算する」がたろう
; 円周率を150桁まで計算可能
; 計算には0x9000から0x9200までの領域を使用
; http://diode.matrix.jp/SOFT/R8/PAI_1.htm
INIT:
    MOV D, 0x00
INIT_L:
    CMP D, 0x200 ;MAXARRAY
    JMP.ns IP+@MAIN
    MOV A, 0x02
    STORE A, 0x9000+D
    INC D,D
    JMP IP+@INIT_L
MAIN:
    MOV D,0x1FF ;MAXARRAY-1
MAIN_L1:
    CMP ZR, D
    JMP.ns IP+@OUTPUT
    ; C=0
    MOV C, 0x00
    SUB B, D-0x01
    CALL IP+@MAIN_L2
    STORE C, 0x95FF-D ;MAXARRAY-D-1
    DEC D, D
    JMP IP+@MAIN_L1

MAIN_L2:
    CMP ZR, B
    RET.ns
    ;C      = C * B + nom[B] * 10;
    ;      = C * B;
    ;     +=nom[B] * 10;
    ;        nom[B] = C % (2*B-1);
    ;A      = C * B;
    CALL IP+@MUL
    ;C = A
    MOV C, A
    ;A      +=nom[B] * 10;
    PUSH B
    PUSH C
    LOAD B, 0x9000+B
    MOV C, 0x0A
    CALL IP+@MUL

    POP C
    POP B
    ;C = C+A
    ADD C, C, A

    ;B = C % (2*B-1); -> nom[B]
    ;A = C / (2*B-1); -> C
    PUSH B
    ;B = 2*B-1
    SLL B, B
    DEC B, B
    ;B = C % B;
    XOR B, B, C
    XOR C, B, C
    XOR B, B, C
    CALL IP+@DIV
    ;nom[B] = 
    MOV C, A
    POP A
    STORE B, 0x9000+A
    MOV B, A
    ;C      = C / (2*B-1);
    DEC B,B
    JMP IP+@MAIN_L2

OUTPUT:
    MOV B,0x200 ;MAXARRAY
OUTPUT_L1:
    DEC B,B
    CMP ZR, B
    JMP.ns IP+@OUTPUT_INIT

    LOAD C, 0x9400+B
    CMP C, 0x0A
    JMP.s IP+@OUTPUT_L1
    SUB C, C,0x0A
    STORE C, 0x9400+B
    LOAD C, 0x93FF+B
    INC C,C
    STORE C, 0x93FF+B
    JMP IP+@OUTPUT_L1
OUTPUT_INIT:
    MOV A, IP+@str_pi
    CALL 0x17
    MOV B, 0x01
OUTPUT_L2:
    CMP B,0x200 ;MAXARRAY
    RET.ns
    LOAD C, 0x9400+B
    ADD A, C,0x30
    CALL 0x11
    INC B, B

    PUSH B
    MOV C, 0x0A
    CALL IP+@DIV
    MOV C, B
    POP B
    CMP C,0x00
    JMP.nz IP+@OUTPUT_L2
    MOV A, 0x20
    CALL 0x11

    PUSH B
    MOV C, 0x14
    CALL IP+@DIV
    MOV C, B
    POP B
    CMP C,0x00
    JMP.nz IP+@OUTPUT_L2
    MOV A, 0x0D
    CALL 0x11
    MOV A, 0x0A
    CALL 0x11

    JMP IP+@OUTPUT_L2
.ascii:str_pi "3.1\0"
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