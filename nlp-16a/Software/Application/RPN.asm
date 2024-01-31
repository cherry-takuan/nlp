;逆ポーランド記法の計算機を作る
CAL:
	MOV A, IP+@CALop
	STORE 0x8018, A			;数値入力のモード設定(0)

CALin:
	CALL 0x06				;文字の入力サブルーチン
	CALL 0x1F				;ok
	PUSH A					;数値をスタックに
	JMP IP+@CALin
CALop:						;数値以外

	CALL 0x12				;演算子表示
	CALL 0x1F				;ok
	POP B
	POP C

	CMP A, 0x2b				;足し算
	ADD.z A, C, B
	CMP A, 0x2d				;引き算
	SUB.z A, C, B
	CMP A, 0x2a				;掛け算
	CALL.z IP+@MUL
	CMP A, 0x2f				;割り算
	CALL.z IP+@DIV

	PUSH A

	CALL 0x3F
	CALL 0x1F
	JMP IP+@CALin
; 0x01 0x02 + 0x03 0x04 - *

;乗算に使うレジスタはBとCの間で掛け算してAに結果を置く
MUL:
	PUSH B
	PUSH C
	;結果格納の初期化
	MOV A, 0x00
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
	POP B
	RET

DIV:
	PUSH B
	PUSH C
    MOV C, B
    MOV D, 0x00
    SLR B, B
    SLR B, B
    SLR B, B
    SLR B, B
    SLR B, B
    SLR B, B
    SLR B, B
    SLR B, B

DIVloop:
    CMP C, B
    JMP.z IP+@DIVend

    SLR D, D
    SLL B, B

    CMP A, B
    JMP.s IP+@DIVloop
    OR D, D, 0x0001
    SUB A, A, B
    JMP IP+@DIVloop
DIVend:
	POP C
	POP B
	RET