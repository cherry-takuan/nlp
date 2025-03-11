INIT:
    MOV SP, 0xEFFF
	CALL MAIN
	JMP END
;シリアルI/Oの基盤
;A -> Serial
OUTEEE:
	STORE A, 0xFF02
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
END:
;debug out
	CALL OUTEEE
	STORE ZR, 0xFFFF
END_Loop:
	JMP IP+@END_Loop
