;開始アドレス
	JMP START
;サブルーチンアドレスベクタモドキ
;頭にすべて持ってくることで2ワードコール命令が使える
MEMDUMP:
	MOV ip, MEMDUMPsub
INHEX:
	MOV ip, INHEX_sub
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
PRINT:
	MOV ip, PRINT_sub
OUT4H:
	MOV IP, OUT4H_sub
CHAR2HEX:
    MOV IP, CHAR2HEXsub
;シリアルイニシャライズ
;コメントアウトされている箇所は8251のイニシャライズルーチン
SERIAL_INIT:
	MOV A 0xFF01
	STORE 0x00, A
	;STORE 0x00, A
	;STORE 0x00, A
	;STORE 0x40, A
	;MOV.nop ZR, ZR

	;STORE 0x4E, A
    ;STORE 0x4F, A
	
    ;STORE 0x27, A
    ;STORE 0x07, A
    ;ディスプレイ制御
    STORE ZR, 0x8050
    STORE ZR, 0x8051
	RET
;シリアルI/Oの基盤
;A -> Serial
OUTEEESub:
	STORE B, 0x8052
	STORE A, 0x8053
	;0x8054番地が0のときのみVGAに表示
	LOAD B, 0x8054
	CMP B, 0x00
	CALL.z VGA_UPDATE
	;CALL.nop VGA_UPDATE
	LOAD A, 0x8053
OUTEEE_L:
	LOAD B, 0xFF01
	AND ZR, B, 0x02
	JMP.z IP+@OUTEEE_L
	;AND ZR, B, 0x04
	;JMP.z IP+@OUTEEE_L
	STORE A, 0xFF00
	LOAD B, 0x8052
	RET

;シリアル入力
;Serial -> A
INEEEsub:
INEEE_L:
    LOAD A, 0xFF01
	AND A, A, 0x09
    CMP A, 0x09
	JMP.z IP+@INEEE_SERIAL

	LOAD A, 0xFF60
	AND ZR, A, 0x80
	JMP.nz IP+@INEEE_KEYBOARD

	JMP IP+@INEEE_L
; Serialからの入力
INEEE_SERIAL:
	LOAD A, 0xFF00
	AND A, A, 0x00FF
	JMP IP+@INEEE_END
; キーボートからの入力
INEEE_KEYBOARD:
	AND A, A, 0x7F
	PUSH A
INEEE_KEYBOARD_L:
    LOAD A, 0xFF60
	AND ZR, A, 0x80
	JMP.nz IP+@INEEE_KEYBOARD_L
	POP A
	JMP IP+@INEEE_END
; 終了処理
INEEE_END:
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
PRINT_sub:
	STORE B, 0x8010		;SPを退避
	MOV B, A				;スタートアドレスを代入
PRINTSUB:
	LOAD A, B
	CMP A, 0x0000			; 終端文字か比較
	JMP.Z IP+@PRINTEND		; 終了なら終了処理を
;PRINTcput:
	;OUTEEEと同様の理由で機能を塞ぐ
	CALL OUTEEE
	INC B, B
	JMP IP+@PRINTSUB			; 終端まで繰り返す
PRINTEND:
	LOAD B, 0x8010			;SPを復帰
	RET						;戻る
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;数値-文字列変換表示HEXサブルーチン
OUT4H_sub:
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
;16進4桁の文字列を入力
;エンターで確定
INHEX_sub:
	STORE B, 0x801A			;Bを退避
	STORE C, 0x801B			;Cを退避
	STORE D, 0x801C			;Cを退避
	;MOV B, 0x00
	MOV C, 0x00
    MOV A, C
    CALL OUT4H
INHEXmain:
	CALL INEEE				;1文字読み取り
    PUSH A
    CMP A, 0x0D
    JMP.z IP+@INHEXend
	;文字の検証
    CALL IP+@CHAR2HEX
    CMP A, 0xFFFF
	JMP.z IP+@INHEXnan
    POP ZR
INTHEXset:
	SLL C, C
	SLL C, C
	SLL C, C
	SLL C, C
	OR C, C, A				;結合
    MOV A, str4h
    CALL PRINT
    MOV A, C
    CALL OUT4H
	JMP IP+@INHEXmain
INHEXend:
    POP ZR
	MOV A, C
	LOAD B,  0x801A			;Bを復帰
	LOAD C,  0x801B			;Cを復帰
	LOAD D,  0x801C			;Cを復帰
	RET
INHEXnan:
    POP A
	LOAD D,  0x8018			;Bを復帰
	MOV ZR, D
	JMP.z IP+@INHEXmain
	POP ZR
	PUSH D
	LOAD B,  0x801A			;Bを復帰
	LOAD C,  0x801B			;Cを復帰
	LOAD D,  0x801C			;Cを復帰
	RET
.ascii:str4h "\b\b\b\b\0"

;文字からHEXに変換 一桁
;0 - Fまでの値を取る
;範囲外であれば0xFFFFを返す
CHAR2HEXsub:
    ;文字の検証
	CMP A, 0x3A
	JMP.ns IP+@CHAR2HEXchar
	CMP A, 0x30
	JMP.s IP+@CHAR2HEXnan
	SUB A, A, 0x30
	RET
CHAR2HEXchar:
	CMP A, 0x41
	JMP.s IP+@CHAR2HEXnan
	CMP A, 0x47
	JMP.ns IP+@CHAR2HEXnan
	SUB A, A, 0x37
    RET
CHAR2HEXnan:
    MOV A, 0xFFFF
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;メモリダンプ
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
	;POP D					;戻りアドレスをDへ
	STORE D, 0x8024			;戻りアドレスを0x8004へ

	MOV A, 0x00
	STORE A, 0x8018			;数値入力のモード設定(0)

    MOV A, strDUMP
	CALL PRINT
	CALL INHEX
	MOV C, A					;開始アドレスをCへ

	MOV A, 0x2D
	CALL OUTEEE
	CALL INHEX
	MOV D, A					;終了アドレスをDへ

	MOV A, 0x0D				;\r
	CALL OUTEEE
	MOV A, 0x0A				;\n
	CALL OUTEEE
MEMDUMPmain:
	;開始アドレスを加工 下位2bitを消去
	AND C, C, 0xFFFC
	CMP D, C				;現在アドレスよりも終端アドレスが大きければ
	JMP.s IP+@MEMDUMPend		;終了
	MOV A, C
	CALL OUT4H				;アドレス表示

	MOV A, 0x2D				;ハイフン
	CALL OUTEEE

	CALL IP+@MEMDUMPdata		;Dataを16進表示

	MOV A, 0x20				;SP
	CALL OUTEEE
	SUB C, C, 0x04		;アドレスを戻す
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
	AND ZR, C, 0x03			;下位2bitのみにする
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
	AND ZR, C, 0x03			;下位2bitのみにする
	ret.z					;結果が0であればリターン
	JMP IP+@MEMDUMPchar

MEMDUMPend:
	;CALL OK
	LOAD D,  0x8024			;戻りアドレスを取得
	;PUSH D					;戻りアドレスを復帰
	LOAD A,  0x8020			;Aを復帰
	LOAD B,  0x8021			;Bを復帰
	LOAD C,  0x8022			;Bを復帰
	LOAD D,  0x8023			;Dを復帰
	RET						;戻る

.ascii:strDUMP "D >\0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;全然使わんので消した
REGDUMPsub:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;メモリ領域操作ルーチン
;スペースでスキップ，ESCで終了
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
	;CMP A, 0x0D
    CMP A, 0x20
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
	;CALL OK
	PUSH D					;戻りアドレスを復帰
	LOAD A,  0x8030			;Aを復帰
	LOAD B,  0x8031			;Bを復帰
	LOAD C,  0x8032			;Bを復帰
	LOAD D,  0x8033			;Dを復帰
	RET						;戻る
.ascii:strModify "M >\0"
.ascii:strModifyfailed "FAILED\0"
.ascii:strModifyunknown "\r\nErr:unknown operation\r\n\0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;バイナリ転送ルーチン
;改行か/が来たら終了
LOADsub:
	MOV A, strLOAD
	CALL PRINT
	CALL INHEX
    CALL OK
    MOV C, 0x01
    STORE C, 0x8054
	MOV C, A					;開始アドレスをCへ

LOAD_MAIN:
	CALL IP+@LOAD_INHEX
    ;CALL INHEX
	STORE A, C
	LOAD B, C
	CMP A, B
	JMP.nz IP+@LOAD_filed
	INC C, C
    MOV A, 0x2E
    AND ZR, C, 0x07
    CALL.z OUTEEE
	JMP IP+@LOAD_main

LOAD_filed:
	MOV A, strModifyfailed
	CALL PRINT
	MOV A, 0x3A
	CALL OUTEEE
	LOAD A, C
	CALL OUT4H
	;CALL OK
	JMP IP+@LOAD_main

LOADend:
    STORE ZR, 0x8054
    POP ZR
    POP ZR
    POP ZR
    CALL OK
	RET						;戻る
.ascii:strLOAD "L >\0"

LOAD_INHEX:
    PUSH B
    PUSH C
    MOV B, 0x00
LOAD_INHEX_L:
    CMP B, 0x04				;4文字あるか
	JMP.z IP+@LOAD_INHEXend
	CALL INEEE				;1文字読み取り
    CMP A,0x1B
    JMP.z IP+@LOADend
    CMP A,0x2F
    JMP.z IP+@LOADend
    CMP A,0x0D
    JMP.z IP+@LOADend
    CALL CHAR2HEX
    CMP A, 0xFFFF
    JMP.z IP+@LOAD_filed
    SLL C, C
	SLL C, C
	SLL C, C
	SLL C, C
	OR C, C, A				;結合
	INC B, B
    JMP IP+@LOAD_INHEX_L
LOAD_INHEXend:
    MOV A, C
    POP C
    POP B
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ユーザープログラム呼び出しルーチン
GOsub:
	STORE A, 0x8034			;Aを退避
	STORE B, 0x8035			;Bを退避

	MOV A, 0x00
	STORE A, 0x8018			;数値入力のモード設定(0)

	MOV A, strGO
	CALL PRINT
	CALL INHEX
	MOV B, A					;開始アドレスをCへ
	CALL OK
	MOV A, GOend
	PUSH A
	MOV IP, B
GOend:
	;CALL OK
	LOAD A,  0x8034			;Aを復帰
	LOAD B,  0x8035			;Aを復帰
	RET


.ascii:strGO "G >\0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; VGA制御用ドライバ
VGA_UPDATE:
    PUSH A
    PUSH C
    LOAD B, 0x8050
    CMP B, 0x27
    CALL.ns IP+@VGA_UPDATE_L0

    CMP A, 0x0D
    JMP.z IP+@VGA_UPDATE_CR
    CMP A, 0x0A
    JMP.z IP+@VGA_UPDATE_LF
    CMP A, 0x08
    JMP.z IP+@VGA_UPDATE_B

    ;ADD C, B, 0xF740
	ADD C, B, 0xF700
    STORE A,C
    INC B, B
    STORE B,0x8050
    POP C
    POP A
    RET
VGA_UPDATE_LF:
    CALL IP+@VGA_UPDATE_L0
    STORE ZR,0x8050
    POP C
    POP A
    RET
VGA_UPDATE_CR:
    STORE ZR,0x8050
    POP C
    POP A
    RET
VGA_UPDATE_B:
    DEC B, B
    STORE B,0x8050
    POP C
    POP A
    RET
VGA_UPDATE_L0:
    PUSH A
    MOV B,0xF040  ;x
VGA_UPDATE_L1:
    LOAD A, B
    STORE A,B-0x40
    CMP B,0xF768
    JMP.ns IP+@VGA_UPDATE_L2
    INC B, B
    JMP.s IP+@VGA_UPDATE_L1
VGA_UPDATE_L2:
    ;MOV A, 0xF740
	MOV A, 0xF700
VGA_UPDATE_L3:
    STORE ZR,A
    INC A, A
    CMP A,0xF768
    JMP.s IP+@VGA_UPDATE_L3
    MOV B, 0x00
    POP A
    RET

.ascii:LOGO "\rNLP-16A mikubug v4.0 build:2025/03/23\r\n(c)cherry tech\r\n\0"

.ascii:DMY "MAIN"

;メイン
START:
	MOV SP, 0xEFFF
	STORE ZR, 0x8054
	CALL SERIAL_INIT
	MOV A, LOGO
	CALL PRINT
	CALL OK
;コマンドポーリング
MAIN:
    MOV A, str_main
    CALL PRINT
	CALL INEEE
	CMP A, 0x44
	CALL.z MEMDUMP
	CMP A, 0x4D
	CALL.z MODIFY
	CMP A, 0x47
	CALL.z GO
	CMP A, 0x4C
	CALL.z LOADsub
	CALL OK
	JMP IP+@MAIN
.ascii:str_main "\r\n*\0"