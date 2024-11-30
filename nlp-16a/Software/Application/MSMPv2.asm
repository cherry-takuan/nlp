INIT:
    .dw 0xFE00 ;割り込み禁止
    MOV A, IP+@ID_STR
    CALL 0x17
    
    MOV A, 0x00
    STORE A, 0x8018			;数値入力のモード設定(0:数値強制モード)
    CALL 0x06
    SLL B, A
    SLL B, B
    SLL B, B
    SLL B, B
    OR A, A, B
    STORE A, IP+@MSMP_ADDR
    CALL 0x15
    CALL 0x19
    CALL 0x15

    MOV D, 0xFF ; 初期ステート
    STORE D, IP+@R_STATE  ;ステート更新(種別，メッセージ長ステートへ遷移)
    
    MOV IV, IP+@RS232C_INT
    .dw 0xFF00 ;割り込み許可

MAIN:
    MOV A, 0x3E ; >
    CALL 0x11
    CALL 0x13
    CALL 0x11
    CALL 0x15
	CMP A, 0x73 ; 送信
	CALL.z IP+@T_MSG_SEND
	CMP A, 0x71 ; 終了
	RET.z
	CMP A, 0x74 ; 送信先(TO)設定
	CALL.z IP+@T_ID_SET
    CMP A, 0x6d ; メッセージ作成
	CALL.z IP+@T_MSG_SET
	;CALL OK
    JMP IP+@MAIN

.ascii:ID_STR "My MSMP Addr >\0"
; MSMP受信ルーチン
MSMP_IN:
    PUSH B
    MOV B 0xFF21
MSMP_IN_L:
    LOAD A, B
	AND A, A, 0x09
    CMP A, 0x09
	JMP.nz IP+@MSMP_IN_L
	LOAD A, 0xFF20
	AND A, A, 0x00FF
	POP B
	RET

; 受信時の割り込みサブルーチン
; ステートのチェックと割り振りを行う
RS232C_INT:
    PUSH A
    PUSH B
    LOAD B, IP+@R_STATE
    ;MOV A, B
    ;CALL 0x19
    ;CALL 0x15
    CALL IP+@MSMP_IN ;Reg Aに受信データが入る
    CMP B, 0xFF
    CALL.z IP+@M_ADDR_SET
    CMP B, 0xFE
    CALL.z IP+@M_LEN_SET
    CMP B, 0x40
    CALL.s IP+@M_RESEIVE
    POP B
    POP A
    .dw 0xFF00 ;割り込み許可
    IRET
MSMP_WAIT:
    PUSH A
    MOV A, 0x0100
PRINT_DELAY:
    DEC A, A
	CMP A, 0x00
    JMP.ns IP+@PRINT_DELAY
    POP A
    RET
; MSMP出力ルーチン
MSMP_OUT:
    PUSH B
MSMP_OUT_L0:
	LOAD B, 0xFF21
	AND ZR, B, 0x02
	JMP.z IP+@MSMP_OUT_L0
	STORE A, 0xFF20
	POP B
	RET

; アドレスを取得し，R_STATUSを更新
M_ADDR_SET:
    PUSH D
    PUSH C
    PUSH B
    PUSH A

    ;受信したアドレスを分割し，転送元，送信先を分離
    AND B, A, 0xF0 ;転送先
    AND A, A, 0x0F ;送信元

    STORE A, IP+@F_ADDR ; 送信元を保存

    MOV D, 0x00 ;フラグ初期設定は転送なし，受信無し
    LOAD C, IP+@MSMP_ADDR ; 自身のアドレスを取得
    AND C, C, 0xF0 ; 上位のみにマスク
    CMP B, C ;転送先が自身ならば
    OR.z D, D, 0x02 ;受信フラグを立てる
    CMP B, C ;転送先が自身でなければ
    OR.nz D, D, 0x01 ;送信フラグを立てる
    CMP B, 0xF0 ;転送先がブロードキャストならば
    OR.z D, D, 0x03 ;受信フラグと転送フラグを立てる

    ADD C, C, 0x10
    CMP B, C ;転送先が設定値+1ならば
    OR.z D, D, 0x06 ;RPNフラグを立てる
    
    LOAD C, IP+@MSMP_ADDR ; 自身のアドレスを取得
    AND C, C, 0x0F ; 下位のみにマスク
    CMP A, C ;送信元が自身ならば
    AND.z D, D, 0xFE ;転送フラグを無効に
    CMP A, C ;送信元が自身ならば
    OR.z D, D, 0x02 ;受信フラグを立てる

    STORE D, IP+@R_STATUS ;ステータス更新

    ; 以下転送関連
    PUSH A
    OR A, A, B
    AND ZR, D, 0x01 ; 転送フラグが立っていれば転送
    CALL.nz IP+@MSMP_OUT
    POP A
    ; 文字コード変換
    CMP 0x09, A
	ADD.s A, A, 0x37
	CMP 0x09, A
	ADD.ns A, A, 0x30

    AND ZR, D, 0x02 ; 受信フラグが立っていればシリアルに表示
    CALL.nz 0x11
    MOV A, 0x3E ; >
    AND ZR, D, 0x02 ; 受信フラグが立っていればシリアルに表示
    CALL.nz 0x11

    ; 次のステートを指定
    MOV D, 0xFE
    STORE D, IP+@R_STATE  ;ステート更新(種別，メッセージ長ステートへ遷移)

    POP A
    POP B
    POP C
    POP D
    RET

; メッセージ長を取得し残りメッセージ長を更新
; ひとまずTYPEは無視(ごめんなさい)
M_LEN_SET:
    PUSH A
    PUSH B

    ; 以下転送関連
    LOAD D, IP+@R_STATUS ;ステータス取得
    AND ZR, D, 0x01 ; 転送フラグが立っていれば転送
    CALL.nz IP+@MSMP_OUT
    ; 表示はなし

    AND A, A, 0x3F
    ;;;;;;;;;;;;;
    MOV B, A
    CMP A, 0x00
    MOV.z B, 0xFF ;メッセージ長が0ならばヘッダー待ちに遷移
    STORE B, IP+@R_STATE  ;ステート更新(種別，メッセージ長ステートへ遷移)
    POP B
    POP A
    RET

; 文字を取得
; メッセージ長が0になったらヘッダー待ちに遷移
M_RESEIVE:
    PUSH A
    PUSH B

    ; 以下転送関連
    LOAD D, IP+@R_STATUS
    AND ZR, D, 0x02
    CALL.nz 0x11
    AND ZR, D, 0x01 ; 転送フラグが立っていれば転送
    CALL.nz IP+@MSMP_OUT
    AND ZR, D, 0x04 ; RPNフラグが立っていれば計算へ
    CALL.nz IP+@RPN
    MOV B, A

    ;メッセージ受信完了でヘッダー待ちに遷移(種別，メッセージ長ステートへ遷移)
    LOAD A, IP+@R_STATE
    DEC A, A

    CMP A, 0x01
    JMP.ns IP+@M_RESEIVE_NO_OK
    AND ZR, D, 0x02
    CALL.nz 0x15 ; 最終文字であればokを表示
M_RESEIVE_NO_OK:
    LOAD D, IP+@R_STATUS
    CMP A, 0x01 ; 終端で無ければ
    AND.ns D, D, 0x00 ; ステータスをマスク
    AND ZR, D, 0x04 ; RPNが有効ならば
    CALL.nz IP+@RPN_SEND ; 結果を返信

    CMP A, 0x01 ; 終端であればヘッダ待ちステートへ
    MOV.s A, 0xFF
    CMP B, 0x00 ; 転送された値が0x00ならばステートリセット
    MOV.s A, 0xFF
    STORE A, IP+@R_STATE

    POP B
    POP A
    RET


T_MSG_LEN:
    PUSH B
    PUSH C
    MOV A, 0x00
    MOV B, IP+@T_MSG_ADDR
T_MSG_LEN_L0:
    LOAD C, A+B
    CMP C, 0x00
    JMP.z IP+@T_MSG_LEN_END
    INC A, A
    JMP IP+@T_MSG_LEN_L0
T_MSG_LEN_END:
    POP C
    POP B
    RET
T_MSG_SEND:
    .dw 0xFE00 ;割り込み禁止
    PUSH A
    PUSH B
    PUSH C
    MOV A, IP+@T_MSG_STR
    CALL 0x17
;ヘッダー出力開始
    LOAD A, IP+@T_ADDR ; 送信先アドレス
    LOAD B, IP+@MSMP_ADDR ; 自分のアドレス
    SLL A, A
    SLL A, A
    SLL A, A
    SLL A, A
    AND B, B, 0x0F
    OR A, A, B
    CALL IP+@MSMP_OUT ; 送信先，送信元を出力
    CALL IP+@T_MSG_LEN ; 送信文字列長取得
    CALL IP+@MSMP_WAIT
    CALL IP+@MSMP_OUT ; TYPE,LEN送信
;PRINTルーチンのコピー
	MOV B, IP+@T_MSG_ADDR   ;スタートアドレスを代入
PRINTSUB:
	LOAD A, B
	CMP A, 0x0000			; 終端文字か比較
	JMP.Z IP+@PRINTEND		; 終了なら終了処理を
    
    CALL IP+@MSMP_WAIT

	CALL IP+@MSMP_OUT
    ;CALL 0x11
	INC B, B
	JMP IP+@PRINTSUB			; 終端まで繰り返す
PRINTEND:
;ここまで
    CALL 0x15
    POP C
    POP B
    POP A
    .dw 0xFF00 ;割り込み許可
    RET
.ascii:T_MSG_STR "Sending...\0"
T_MSG_SET:
    PUSH A
    PUSH B
    PUSH C
    MOV A, IP+@T_MSG_ADDR
    CALL 0x17
T_MSG_SET_MAIN:
    CALL 0x13 ;INEEE
    CMP A, 0x1B ;ESC 終了
    JMP.z IP+@T_MSG_SET_END
    CMP A, 0x0D ;ENTER 終了
    JMP.z IP+@T_MSG_SET_END
    CMP A, 0x08 ;BS 後退
    JMP.z IP+@T_MSG_BS
    CMP A, 0x20 ;制御文字
    JMP.s IP+@T_MSG_SET_MAIN
    
    CALL 0x11 ;入力文字表示
    MOV B, A ;入力文字をBへ
    CALL IP+@T_MSG_LEN
    CMP A, 0x62
    JMP.ns IP+@T_MSG_SET_MAIN
    MOV C, IP+@T_MSG_ADDR ;先頭アドレスを取得
    ;CALL 0x19
    STORE B, A+C ;カーソル位置+先頭アドレス
    INC A, A
    STORE ZR, A+C ;カーソル位置+先頭アドレス
    JMP IP+@T_MSG_SET_MAIN
T_MSG_SET_END:
    CALL 0x15
    POP C
    POP B
    POP A
    RET
T_MSG_BS:
    CALL IP+@T_MSG_LEN
    CMP A, 0x00
    JMP.s IP+@T_MSG_SET_MAIN
    DEC A, A
    MOV C, IP+@T_MSG_ADDR ;先頭アドレスを取得
    STORE ZR, A+C ;カーソル位置+先頭アドレス
    MOV A, IP+@T_MSG_BS_STR
    CALL 0x17
    JMP IP+@T_MSG_SET_MAIN
.ascii:T_MSG_BS_STR "\b \b\0"

T_ID_SET:
    PUSH A
    MOV A, 0x00
    STORE A, 0x8018			;数値入力のモード設定(0:数値強制モード)
    CALL 0x06
    STORE A, IP+@T_ADDR
    CALL 0x15
    POP A
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RPN:
	PUSH A
    PUSH B
    PUSH C
    PUSH D
	LOAD C, IP+@RPN_NUM_BUF ;最後の数値を取得
INHEXmain:
	;文字の検証
	CMP A, 0x3A
	JMP.ns IP+@INHEXchar
	CMP A, 0x30
	JMP.s IP+@INHEXnan
	;数値確定
	SUB A, A, 0x30
	JMP IP+@INTHEXset
INHEXchar:
	CMP A, 0x41
	JMP.s IP+@INHEXnan
	CMP A, 0x47
	JMP.ns IP+@INHEXnan
	SUB A, A, 0x37
INTHEXset:
	SLL C, C
	SLL C, C
	SLL C, C
	SLL C, C
	OR C, C, A				;結合
    STORE C, IP+@RPN_NUM_BUF ;数値を更新
    JMP IP+@INHEX_END
INHEXnan:
    MOV D, A ; 入力キーをDへ
    MOV A, C ; 数値をAへ
    CMP D, 0x20 ; スペースならばスタックにPUSH
    CALL.z IP+@PUSH_A
    CMP D, 0x20 ; スペースならば数値をリセット
    STORE.z ZR, IP+@RPN_NUM_BUF ;数値をリセット
    CMP D, 0x20 ; スペースならば以上で終了
    JMP.z IP+@INHEX_END

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

    CALL IP+@PUSH_A
INHEX_END:
	POP D
    POP C
    POP B
    POP A
	RET
RPN_NUM_BUF:
    .dw 0x00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RPNスタック関連
PUSH_A:
	PUSH B
	PUSH C
	LOAD B, IP+@stack_addr
	;MOV C, IP+@stack
	MOV C, 0xA000
	STORE A, B+C
	INC B, B
	STORE B, IP+@stack_addr
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
	;MOV C, IP+@stack
	MOV C, 0xA000
	LOAD A, B+C
	STORE B, IP+@stack_addr
	POP C
	POP B
	RET
stack_addr:;計算スタックの奴
	.dw 0x00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RPN_SEND:
    .dw 0xFE00 ;割り込み禁止
    PUSH A
    PUSH B
    PUSH C
;ヘッダー出力開始
    LOAD A, IP+@F_ADDR ; 送信先アドレス
    LOAD B, IP+@MSMP_ADDR ; 自分のアドレス
    SLL A, A
    SLL A, A
    SLL A, A
    SLL A, A
    AND B, B, 0x0F
    OR A, A, B
    CALL IP+@MSMP_OUT ; 送信先，送信元を出力
    CALL IP+@MSMP_WAIT
    MOV A, 0x04
    CALL IP+@MSMP_OUT ; TYPE,LEN送信
    
    CALL IP+@POP_A ; スタックトップを取得
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;数値-文字列変換表示HEXサブルーチン
	MOV B, 0x00				;カウンタ値を0へ
	MOV C, A
OUT4Hsep:
	CMP B, 0x04
	JMP.z IP+@OUT4Hend			;4回送信で終了

	ROL C, C				;4ビット分ずらす
	ROL C, C
	ROL C, C
	ROL C, C
	AND A, C, 0x000F		;桁を分離

	CMP 0x09, A
	ADD.s A, A, 0x37				;文字コード変換
	CMP 0x09, A
	ADD.ns A, A, 0x30				;文字コード変換
	CALL IP+@MSMP_WAIT; 送信wait
    CALL IP+@MSMP_OUT ; TYPE,LEN送信

	INC B, B				;カウントアップ
	JMP IP+@OUT4Hsep
OUT4Hend:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    POP C
    POP B
    POP A
    .dw 0xFF00 ;割り込み許可
    RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 計算ルーチン
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MSMP_ADDR:
    .dw 0x0A ;デフォルトは2
R_STATE:
    ; 0xFF ヘッダー(アドレス)待ち
    ; 0xFE 種別，メッセージ長さ待ち
    ; 0x3F以下 残りメッセージ長
    ; メッセージ長の転記以外は基本的にDEC以外の操作を禁止
    .dw 0xFF
R_STATUS:
    ; 0x01 転送
    ; 0x02 受信
    ; 以上を組み合わせ
    ; 例:ブロードキャスト受信
    ; 0x03 (受信かつ転送)
    .dw 0x00

T_WAIT_TIME:

F_ADDR:
    .dw 0x00
T_ADDR:
    .dw 0x00
.ascii:T_MSG_ADDR "hello\0"