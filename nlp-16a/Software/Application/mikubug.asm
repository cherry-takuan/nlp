	JMP START
MEMDUMP:
	MOV ip, MEMDUMPsub
INHEX:
	MOV ip, INHEXsub
REGDUMP:
	MOV ip, REGDUMPsub
MODIFY:
	MOV ip, MODIFYsub
GO:
	MOV ip, GOsub	
OUTEEE:
	MOV ip, OUTEEESub
INEEE:
	MOV ip, INEEESub
OK:
	MOV ip, OKsub
;シリアルI/Oの基盤
;A -> Serial
OUTEEESub:
	;やり方を再考の必要アリ
	;レジスタを複数持たせるべき
	;変更すべきでもここで一度定義しておくことで後の置き換えを容易にする
	;AND ZR, E, 0x6000
	;jmp.nz @CPUT			;不能なら再度
	AND E, A, 0xFF
	RET
;Serial -> A
INEEEsub:
	MOV A, E
	AND ZR, A, 0x8000
	JMP.nz IP+@INEEE			;未受信ならばループ
	AND A, A, 0xFF
	RET
;ok.と表示する
OKsub:
	PUSH A
	MOV A, strOK
	CALL PRINT
	POP A
	RET
.ascii:strOK " ok.\r\n\0"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;文字表示サブルーチン
PRINT:
	STORE SP, 0x8010		;SPを退避
	MOV SP, A				;スタートアドレスを代入
PRINTSUB:
	POP A					; 1byte読み取り
	CMP A, 0x0000			; 終端文字か比較
	JMP.Z IP+@PRINTEND		; 終了なら終了処理を
;PRINTcput:
	;OUTEEEと同様の理由で機能を塞ぐ
	MOV E, A
	JMP IP+@PRINTSUB			; 終端まで繰り返す
PRINTEND:
	LOAD SP, 0x8010			;SPを復帰
	RET						;戻る
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;数値-文字列変換表示HEXサブルーチン
OUT4H:
	STORE B, 0x8014			;Bを退避
	STORE C, 0x8015			;Cを退避
	MOV B, 0x00				;カウンタ値を0へ
	MOV C, A
OUT4Hsep:
	CMP B, 0x04
	JMP.z IP+@OUT4Hend			;3周したら表示ルーチンへ

	ROL C, C				;4ビット分ずらす
	ROL C, C
	ROL C, C
	ROL C, C

	AND A, C, 0x000F		;桁を分離

	CMP 0x09, A
	ADD.s A, A, 0x37				;文字コード変換
	CMP 0x09, A
	ADD.ns A, A, 0x30				;文字コード変換
	CALL OUTEEE

	INC B, B				;カウントアップ
	JMP IP+@OUT4Hsep
OUT4Hend:
	LOAD B,  0x8014			;Bを復帰
	LOAD C,  0x8015			;Bを復帰
	RET						;戻る

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INHEXsub:
	STORE B, 0x801A			;Bを退避
	STORE C, 0x801B			;Cを退避
	STORE D, 0x801C			;Cを退避
	MOV B, 0x00
	MOV C, 0x00
INHEXmain:
	CMP B, 0x04				;4文字あるか
	JMP.z IP+@INHEXend
	CALL INEEE				;1文字読み取り
	;文字の検証
	CMP A, 0x3A
	JMP.ns IP+@INHEXchar
	CMP A, 0x30
	JMP.s IP+@INHEXnan
	;数値確定
	CALL OUTEEE
	SUB A, A, 0x30
	JMP IP+@INTHEXset
INHEXchar:
	CMP A, 0x41
	JMP.s IP+@INHEXnan
	CMP A, 0x47
	JMP.ns IP+@INHEXnan
	CALL OUTEEE
	SUB A, A, 0x37
INTHEXset:
	AND ZR, A, 0xFFF0		;上位12bitに1bitでも1があれば0x00に
	JMP.nz IP+@INHEXnan
	
	SLL C, C
	SLL C, C
	SLL C, C
	SLL C, C
	OR C, C, A				;結合

	INC B, B
	JMP IP+@INHEXmain
INHEXend:
	MOV A, C
	LOAD B,  0x801A			;Bを復帰
	LOAD C,  0x801B			;Cを復帰
	LOAD D,  0x801C			;Cを復帰
	RET
INHEXnan:
	LOAD D,  0x8018			;Bを復帰
	MOV ZR, D
	JMP.z IP+@INHEXmain
	POP ZR
	PUSH D
	LOAD B,  0x801A			;Bを復帰
	LOAD C,  0x801B			;Cを復帰
	LOAD D,  0x801C			;Cを復帰
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;使用レジスタ A,B,C,D
;退避場所
;A	0x8000
;B	0x8001
;C	0x8002
;D	0x8003
MEMDUMPsub:
	STORE A, 0x8020			;Aを退避
	STORE B, 0x8021			;Bを退避
	STORE C, 0x8022			;Cを退避
	STORE D, 0x8023			;Dを退避
	;開始表示
	POP D					;戻りアドレスをDへ
	STORE D, 0x8024			;戻りアドレスを0x8004へ

	MOV A, 0x00
	STORE A, 0x8018			;数値入力のモード設定(0)

	MOV A, strDUMPaddress
	CALL PRINT
	MOV A, 0x0A
	CALL OUTEEE
	MOV A, 0x0D
	CALL OUTEEE

	MOV A, 0x3E
	CALL OUTEEE
	CALL INHEX
	MOV C, A					;開始アドレスをCへ
	MOV A, 0x0A
	CALL OUTEEE
	MOV A, 0x0D
	CALL OUTEEE

	MOV A, 0x3E
	CALL OUTEEE
	CALL INHEX
	MOV D, A					;終了アドレスをDへ

	MOV A, strDUMPaddress
	CALL PRINT
	MOV A, C					;開始アドレスをPOP
	CALL OUT4H				;開始アドレス表示
	MOV A, 0x2D				;ハイフン
	CALL OUTEEE
	MOV A, D
	CALL OUT4H				;終了アドレス表示
	MOV A, 0x0D				;\r
	CALL OUTEEE
	MOV A, 0x0A				;\n
	CALL OUTEEE
MEMDUMPmain:
	;開始アドレスを加工 下位3bitを消去
	AND C, C, 0xFFF8
	CMP D, C				;現在アドレスよりも終端アドレスが大きければ
	JMP.s IP+@MEMDUMPend		;終了
	MOV A, C
	CALL OUT4H				;アドレス表示

	MOV A, 0x20				;Space
	CALL OUTEEE
	CALL OUTEEE

	CALL IP+@MEMDUMPdata		;Dataを16進表示

	MOV A, 0x20				;SP
	CALL OUTEEE
	SUB C, C, 0x08		;アドレスを戻す
	CALL IP+@MEMDUMPchar		;Dataを文字表示

	
	MOV A, 0x0D				;\r
	CALL OUTEEE
	MOV A, 0x0A				;\n
	CALL OUTEEE

	JMP IP+@MEMDUMPmain		;繰り返し

	;データ16進表示
MEMDUMPdata:
	LOAD A, C				;現在のアドレスからロード
	CALL OUT4H				;16進表示
	MOV A, 0x20				;SP
	CALL OUTEEE
	INC C, C
	AND ZR, C, 0x07			;下位3bitのみにする
	ret.z					;結果が0であればリターン
	JMP IP+@MEMDUMPdata

	;データ文字表示
MEMDUMPchar:
	LOAD A, C				;現在のアドレスからロード
	CMP A, 0x20				;文字範囲外では
	MOV.s A, 0x2E			;ドットを表示
	CMP A, 0x7F
	MOV.ns A, 0x2E
	CALL OUTEEE				;表示
	INC C, C
	AND ZR, C, 0x07			;下位3bitのみにする
	ret.z					;結果が0であればリターン
	JMP IP+@MEMDUMPchar

MEMDUMPend:
	CALL OK
	LOAD D,  0x8024			;戻りアドレスを取得
	PUSH D					;戻りアドレスを復帰
	LOAD A,  0x8020			;Aを復帰
	LOAD B,  0x8021			;Bを復帰
	LOAD C,  0x8022			;Bを復帰
	LOAD D,  0x8023			;Dを復帰
	RET						;戻る

.ascii:strDUMP "\r\nMEM DUMP\r\n\0"
.ascii:strDUMPaddress "\r\nAddress :\0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




REGDUMPsub:
	STORE FLAG, 0x802A		;Dを退避
	STORE A, 0x802B			;Dを退避
	STORE B, 0x802C			;Dを退避
	STORE C, 0x802D			;Dを退避
	STORE D, 0x802E			;Dを退避
	;STORE BANK, 0x802F		;Dを退避
	STORE SP, 0x8028		;Dを退避
	STORE IV, 0x8029		;Dを退避
	MOV A, strREGDUMP
	CALL PRINT
	MOV C, 0x8028
REGDUMPmain:
	CMP 0x8030, C
	JMP.s IP+@REGDUMPend
	LOAD B, C

	MOV A, C
	CALL OUT4H
	MOV A, 0x3A
	CALL OUTEEE
	MOV A, B
	CALL OUT4H
	CALL OK
	INC C, C
	JMP IP+@REGDUMPmain
REGDUMPend:
	CALL OK
	LOAD A,  0x802B			;Aを復帰
	LOAD B,  0x802C			;Bを復帰
	LOAD C,  0x802D			;Bを復帰
	LOAD D,  0x802F			;Dを復帰
	RET	
.ascii:strREGDUMP "\r\nREG DUMP\r\n\0"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODIFYsub:
	STORE A, 0x8030			;Aを退避
	STORE B, 0x8031			;Bを退避
	STORE C, 0x8032			;Cを退避
	STORE D, 0x8033			;Dを退避
	POP D					;戻りアドレスをDへ

	MOV A, 0x00
	STORE A, 0x8018			;数値入力のモード設定(0)

	MOV A, strModify
	CALL PRINT

	MOV A, 0x3E
	CALL OUTEEE
	CALL INHEX
	MOV C, A					;開始アドレスをCへ
	MOV A, 0x0A
	CALL OUTEEE
	MOV A, 0x0D
	CALL OUTEEE

	MOV A, MODIFYmenu
	STORE A, 0x8018			;数値入力のモード設定(0)

MODIFYmain:
	CALL IP+@MODIFYprint
	CALL INHEX
	STORE A, C
	MOV B, A

	MOV A, 0x0D
	CALL OUTEEE

	CALL IP+@MODIFYprint
	LOAD A, C
	CMP A, B
	JMP.nz IP+@MODIFYfaild
MODIFYnext:
	CALL OK
	INC C, C
	JMP IP+@MODIFYmain

MODIFYmenu:
	CMP A, 0x0D
	JMP.z IP+@MODIFYnext
	CMP A, 0x1B
	JMP.z IP+@MODIFYend
	MOV A, strModifyunknown
	CALL PRINT
	JMP IP+@MODIFYmain
MODIFYprint:
	MOV A, C
	CALL OUT4H				;アドレス表示
	MOV A, 0x3A
	CALL OUTEEE
	LOAD A, C
	CALL OUT4H				;データ表示

	MOV A, 0x09
	CALL OUTEEE
	MOV A, 0x2A
	CALL OUTEEE
	RET
MODIFYfaild:
	MOV A, strModifyfailed
	CALL PRINT
	MOV A, 0x3A
	CALL OUTEEE
	LOAD A, C
	CALL OUT4H
	CALL OK
	JMP IP+@MODIFYmain

MODIFYend:
	CALL OK
	PUSH D					;戻りアドレスを復帰
	LOAD A,  0x8030			;Aを復帰
	LOAD B,  0x8031			;Bを復帰
	LOAD C,  0x8032			;Bを復帰
	LOAD D,  0x8033			;Dを復帰
	RET						;戻る
.ascii:strModify "\r\nMODIFY\r\n\0"
.ascii:strModifyfailed "FAILED\0"
.ascii:strModifyunknown "\r\nErr:unknown operation\r\n\0"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GOsub:
	STORE A, 0x8034			;Aを退避
	STORE B, 0x8035			;Bを退避

	MOV A, 0x00
	STORE A, 0x8018			;数値入力のモード設定(0)

	MOV A, strGO
	CALL PRINT
	CALL INHEX
	MOV B, A					;開始アドレスをCへ
	MOV A, 0x0A
	CALL OUTEEE
	MOV A, 0x0D
	CALL OUTEEE

	MOV A, B
	CALL OUT4H
	CALL OK
	MOV A, GOend
	PUSH A
	MOV IP, B
GOend:
	CALL OK
	LOAD A,  0x8034			;Aを復帰
	LOAD B,  0x8035			;Aを復帰
	RET


.ascii:strGO "\r\nGO:\0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.ascii:LOGO "\rNLP-16 mikubug build:2023/07/01-10\r\n\0"

.ascii:DMY "MAIN"
START:
	MOV A, LOGO
	CALL PRINT
	CALL OK
MAIN:
	CALL INEEE
	CMP A, 0x44
	CALL.z MEMDUMP
	CMP A, 0x52
	CALL.z REGDUMP
	CMP A, 0x4D
	CALL.z MODIFY
	CMP A, 0x47
	CALL.z GO
	CALL OK
	JMP IP+@MAIN