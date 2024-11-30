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

    MOV D, 0x00 ;フラグ初期設定は転送なし，受信無し
    LOAD C, IP+@MSMP_ADDR ; 自身のアドレスを取得
    AND C, C, 0xF0 ; 上位のみにマスク
    CMP B, C ;転送先が自身ならば
    OR.z D, D, 0x02 ;受信フラグを立てる
    CMP B, C ;転送先が自身でなければ
    OR.nz D, D, 0x01 ;送信フラグを立てる
    CMP B, 0xF0 ;転送先がブロードキャストならば
    OR.z D, D, 0x03 ;受信フラグと転送フラグを立てる
    
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
    MOV B, A

    ;メッセージ受信完了でヘッダー待ちに遷移(種別，メッセージ長ステートへ遷移)
    LOAD A, IP+@R_STATE
    DEC A, A

    CMP A, 0x01
    JMP.ns IP+@M_RESEIVE_NO_OK
    AND ZR, D, 0x02
    CALL.nz 0x15 ; 最終文字であればokを表示
M_RESEIVE_NO_OK:

    CMP A, 0x01
    MOV.s A, 0xFF
    CMP B, 0x00
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

T_ADDR:
    .dw 0x00
.ascii:T_MSG_ADDR "hello\0"