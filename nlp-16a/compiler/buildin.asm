INIT:
    MOV SP, 0xEFFF
    CALL SERIAL_INIT
    CALL MAIN
	JMP END
SERIAL_INIT:
	MOV A 0xFF01
	STORE 0x00, A
	STORE 0x00, A
	STORE 0x00, A
	STORE 0x40, A

	STORE 0x4E, A
	STORE 0x27, A
	RET
;シリアルI/Oの基盤
;A -> Serial
OUTEEE:
	;やり方を再考の必要アリ
	;レジスタを複数持たせるべき
	;変更すべきでもここで一度定義しておくことで後の置き換えを容易にする
	;AND ZR, E, 0x6000
	;jmp.nz @CPUT			;不能なら再度
	;AND E, A, 0xFF
	PUSH B
	LOAD B, 0xFF01
	AND ZR, B, 0x01
	JMP.z IP+@OUTEEE
	STORE A, 0xFF00
	POP B
	RET
MUL:
	PUSH B
	PUSH C
	PUSH D
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
	POP D
	POP C
	POP B
	RET
DIV:
	PUSH B
	PUSH C
	PUSH D

    MOV D, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
	MOV A, 0x00

DIVloop:
    CMP D, C
    JMP.z IP+@DIVend

	SLL A, A
    SLR C, C

    CMP B, C
    JMP.s IP+@DIVloop
    OR A, A, 0x0001
    SUB B, B, C
    JMP IP+@DIVloop
DIVend:
	POP D
	POP C
	POP B
	RET
END:
;debug out
	CALL OUTEEE
END_Loop:
	JMP IP+@END_Loop
MAIN:
