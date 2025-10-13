;システムコール一覧
;MEMDUMP         0003
;INHEX   0006
;REGDUMP         0008
;MODIFY  000B
;GO      000E
;OUTEEE  0011
;INEEE   0013
;OK      0015
;PRINT   0017
;OUT4H   0019
INIT:
    MOV SP, 0xEFFF
	MOV A, IP+@malloc_start
	STORE A,IP+@malloc_addr
	CALL IP+@MAIN
	JMP IP+@END
;シリアルI/Oの基盤
;A -> Serial
OUTCHAR:
	;STORE A, 0xFF00
	CALL 0x11
	RET
GETCHAR:
	;LOAD A, 0xFF00
	CALL 0x13
	RET
EXIT:
	MOV B, 0x0a
	STORE A, 0xFF00
	MOV B, 0x40
	STORE A, 0xFF00
	STORE A, 0xFF03
	JMP IP+@END
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

SHIFT_L:
	PUSH B
	PUSH C
SHIFT_L_1:
	CMP C, 0x00
	JMP.z IP+@SHIFT_L_END
	SLL B, B
	DEC C, C
	JMP IP+@SHIFT_L_1
SHIFT_L_END:
	MOV A, B
	POP C
	POP B
	RET

SHIFT_R:
	PUSH B
	PUSH C
SHIFT_R_1:
	CMP C, 0x00
	JMP.z IP+@SHIFT_R_END
	SLR B, B
	DEC C, C
	JMP IP+@SHIFT_R_1
SHIFT_R_END:
	MOV A, B
	POP C
	POP B
	RET

END:
	;RET
;debug out
	STORE A, 0xFFFF
END_Loop:
	JMP IP+@END_Loop
