; スタートベクタ ;;;;;;;;;;;;;;;;;;;;;;
    MOV A, 0x00
    STORE A, IP+@STATUS
    MOV A, 0x01
    STORE A, IP+@STAGE
    MOV A, 0x40
    STORE A, IP+@SPEED
    JMP IP+@INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ユーティリティ ;;;;;;;;;;;;;;;;;;;;;;

; ハードウェアドライバ
INEEE:
    PUSH B
    MOV A, ZR
INEEE_L:
    LOAD B, 0xFF01
	AND B, B, 0x09
    CMP B, 0x09
	JMP.z IP+@INEEE_SERIAL

	LOAD B, IP+@KEY_STATUS
    CMP B, 0x00
    JMP.ns IP+@KEY_STATUS_UPDATE

    LOAD B, 0xFF60
	AND ZR, B, 0x80
	JMP.nz IP+@INEEE_KEYBOARD

	JMP IP+@INEEE_END
; Serialからの入力
INEEE_SERIAL:
	LOAD A, 0xFF00
	AND A, A, 0x00FF
	JMP IP+@INEEE_END
; キーボートからの入力
INEEE_KEYBOARD:
	AND A, B, 0x7F
    
    MOV B, 0x07
    STORE B, IP+@KEY_STATUS
	
    JMP IP+@INEEE_END
; 終了処理
INEEE_END:
    POP B
	RET
KEY_STATUS_UPDATE:
    LOAD B, IP+@KEY_STATUS
    DEC B, B
    STORE B, IP+@KEY_STATUS
    JMP IP+@INEEE_END

CLEAR:
    MOV A,0xF000
CLEAR_L:
    CMP A,0xF740
    RET.z
    STORE ZR, A
    INC A,A
    JMP IP+@CLEAR_L
WAIT:
    PUSH A
    MOV A, 0x80
WAIT_L:
    SUB A, A, 0x01
    JMP.ns IP+@WAIT_L
WAIT_END:
    POP A
    RET
PRINT_NUM:
    PUSH A
    PUSH B
    MOV B, A
    MOV A, 0x00
PRINT_NUM_1000:
    INC A, A
    SUB B, B, 0x3E8 ;1000
    JMP.ns IP+@PRINT_NUM_1000
    ADD B, B, 0x3E8 ;1000
    ADD A, A, 0x2F
    CALL 0x11
    MOV A, 0x00
PRINT_NUM_100:
    INC A, A
    SUB B, B, 0x64 ;100
    JMP.ns IP+@PRINT_NUM_100
    ADD B, B, 0x64 ;100
    ADD A, A, 0x2F
    CALL 0x11
    MOV A, 0x00
PRINT_NUM_10:
    INC A, A
    SUB B, B, 0xA ;10
    JMP.ns IP+@PRINT_NUM_10
    ADD B, B, 0xA ;10
    ADD A, A, 0x2F
    CALL 0x11
    MOV A, 0x00
PRINT_NUM_1:
    INC A, A
    SUB B, B, 0x1 ;1
    JMP.ns IP+@PRINT_NUM_1
    ADD B, B, 0x1 ;1
    ADD A, A, 0x2F
    CALL 0x11
PRINT_NUM_END:
    POP B
    POP A
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; パラメータ ;;;;;;;;;;;;;;;;;;;;;;;;;;
KEY_STATUS:
    .dw 0x00

; 画面 40x30
; X, Y 位置
X:
    .DW 0x20
Y:
    .DW 0x05
; X_V, Y_V 速度
X_V:
    .DW 0xFFFF
Y_V:
    .DW 0xFFFE
CURSOL:
    .DW 0x09
STATUS:
    .DW 0x00
SCORE:
    .DW 0x00
STAGE:
    .DW 0x01
SPEED:
    .DW 0x30

.ascii:TITLE_STR "\r          Breaking blocks GAME\n\n\n\0"
.ascii:STAGE_STR "              STAGE : \0"
.ascii:STAGE_N_STR "\n\n\n\n\n\n\n\n\n\n\n\n\0"
.ascii:continue_STR "     [  press any key to start  ]\0"
.ascii:continue_del_STR "\r                                 \0"

.ascii:result_STR "\rresult:\n\n\0"
.ascii:result_STAGE_STR "    STAGE : \0"
.ascii:bar_STR "  ---  \0"
.ascii:points_STR " points\n\n\0"
.ascii:total_STR "\n\ntotal : \0"
.ascii:good_STR "\ngood!!\n\0"
.ascii:great_STR "\ngreat!!\n\0"
.ascii:ending_STR "press any key to exit\0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; イニシャライズルーチン
; 各種パラメータの初期化
; 壁の生成
; Todo:ブロックの生成
; Todo:難易度調整のアレを
INIT:
    CALL IP+@CLEAR
    MOV A, IP+@TITLE_STR
    CALL 0x17
    MOV A, IP+@STAGE_STR
    CALL 0x17
    LOAD A, IP+@STAGE
    ;CALL 0x19
    CALL IP+@PRINT_NUM
    MOV A, IP+@STAGE_N_STR
    CALL 0x17
    
    CALL IP+@WAIT
    CALL IP+@WAIT
    CALL IP+@WAIT
    CALL IP+@WAIT
    CALL IP+@WAIT

    CALL IP+@CLEAR
    STORE ZR, IP+@STATUS
    STORE ZR, IP+@SCORE
    MOV A, 0x0A
    STORE A, IP+@Y
    MOV A, 0xF000
    MOV B, 0xF000
    MOV D, 0xC
INIT_X:
    CMP A, 0xF028
    JMP.ns IP+@INIT_Y
    STORE 0x1F, A
    INC A, A
    JMP IP+@INIT_X
INIT_Y:
    MOV A, 0x1F
    CMP B, 0xF700
    JMP.ns IP+@BLOCK_INIT
    STORE A, B
    STORE A, B+0x27
    ADD B, B, 0x40
    CALL IP+@WAIT
    JMP IP+@INIT_Y

BLOCK_INIT:
    MOV C, 0x03
BLOCK_INIT_Y:
    INC C, C
    CMP C, 0x08
    JMP.ns IP+@MAIN
    MOV B, 0x06
BLOCK_INIT_X:
    INC B, B
    CMP B, 0x20
    JMP.ns IP+@BLOCK_INIT_Y
    MOV A, 0x23
    CALL IP+@DISPLAY_ADDR
    CALL IP+@WAIT
    JMP IP+@BLOCK_INIT_X

MAIN:
    MOV A, 0x40
    CALL IP+@DISPLAY
    MOV A, IP+@continue_STR
    CALL 0x17
    CALL 0x13
    MOV A, IP+@continue_del_STR
    CALL 0x17
    CALL IP+@WAIT

MAIN_L:
    ;ステータス確認 0以外で終了
    LOAD B, IP+@STATUS
    CMP B, 0x02
    JMP.z IP+@STAGE_CLEAR
    CMP B, 0x00
    JMP.nz IP+@GAME_END
    
    ;入力
    LOAD B, IP+@CURSOL
    CALL IP+@INEEE
    ;CMP A, ZR
    ;CALL.nz IP+@BALL_UPDATE
    DEC D, D
    CALL.z IP+@L1
    CMP A, 0x1B
    RET.z

    ;カーソルの更新
    ;←
    CMP A, 0x61
    DEC.z B,B
    ;→
    CMP A, 0x64
    INC.z B,B
    ;範囲外のケア
    CMP B, 0x00
    MOV.s B, 0x00
    ;CMP B, 0x25
    ;MOV.ns B, 0x24
    CMP B, 0x22
    MOV.ns B, 0x21
    STORE B, IP+@CURSOL
    CALL IP+@CURSOL_UPDATE

    JMP IP+@MAIN_L
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 難易度調整 ;;;;;;;;;;;;;;;;;;;;;;;;;;
L1:
    ;更新速度
    LOAD D, IP+@SPEED
    CALL IP+@BALL_UPDATE
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ステージクリア ;;;;;;;;;;;;;;;;;;;;;;
STAGE_CLEAR:
    MOV A, 0x00
    STORE A, IP+@STATUS
    LOAD A, IP+@STAGE
    INC A, A
    STORE A, IP+@STAGE
    LOAD A, IP+@SPEED
    SUB A, A, 0x08
    STORE A, IP+@SPEED
    JMP IP+@INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ステージクリア ;;;;;;;;;;;;;;;;;;;;;;
GAME_END:
    CALL IP+@CLEAR
    MOV A, IP+@result_STR
    CALL 0x17
    MOV B, 0x00
    MOV D, 0x00
GAME_END_L:
    ADD B, B, 0x01
    MOV A, IP+@result_STAGE_STR
    CALL 0x17
    MOV A, B
    ;CALL 0x19
    CALL IP+@PRINT_NUM
    MOV A, IP+@bar_STR
    CALL 0x17

    LOAD C, IP+@STAGE
    CMP B, C
    JMP.ns IP+@GAME_END_TOTAL

    MOV A, 0x64
    ADD D, D, A
    CALL IP+@PRINT_NUM
    ;CALL 0x19
    MOV A, IP+@points_STR
    CALL 0x17
    JMP IP+@GAME_END_L

GAME_END_TOTAL:
    LOAD A, IP+@SCORE
    ;CALL 0x19
    ADD D, D, A
    CALL IP+@PRINT_NUM
    MOV A, IP+@points_STR
    CALL 0x17

    MOV A, IP+@total_STR
    CALL 0x17
    MOV A, D
    CALL IP+@PRINT_NUM
    MOV A, IP+@points_STR
    CALL 0x17

    CMP D, 0x64
    MOV.ns A, IP+@good_STR
    CMP D, 0x12c
    MOV.ns A, IP+@great_STR
    CMP D, 0x64
    CALL.ns 0x17

    MOV A, IP+@ending_STR
    CALL 0x17
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ボールの当たり判定 ;;;;;;;;;;;;;;;;;;
BALL_UPDATE:
    PUSH A
    PUSH B
    PUSH C
    ; ボール消去
    MOV A, 0x00
    CALL IP+@DISPLAY

    ; Xの当たり判定
    ; (X+X_V , Y) != 0
    MOV B, 0xFFFF
    LOAD C, IP+@X_V
    CMP C, 0x00
    MOV.ns B, 0x01
    LOAD C, IP+@X
    ADD B, B, C
    LOAD C, IP+@Y
    CALL IP+@DISP_GET
    ; 0x00で無ければ衝突
    CMP A, 0x00
    JMP.z IP+@Y_UPDATE
    CALL IP+@VELOCITY_X_UPDATE
    MOV A, 0x00
    CALL IP+@DISPLAY_ADDR
Y_UPDATE:
    ; Yの当たり判定
    ; (X , Y+Y_V) != 0
    MOV C, 0xFFFF
    LOAD B, IP+@Y_V
    CMP B, 0x00
    MOV.ns C, 0x01
    LOAD B, IP+@Y
    ADD C, C, B
    
    LOAD B, IP+@X
    CALL IP+@DISP_GET
    ; 0x00で無ければ衝突
    CMP A, 0x00
    JMP.z IP+@BOUND_UPDATE
    CALL IP+@VELOCITY_Y_UPDATE
    MOV A, 0x00
    CALL IP+@DISPLAY_ADDR
BOUND_UPDATE:
    ;カーソルのバウンド
    LOAD A, IP+@Y
    CMP A, 0x1B
    CALL.ns IP+@BOUND
    ;位置の更新
    LOAD A, IP+@X
    LOAD B, IP+@X_V
    ADD A, A, B
    STORE A, IP+@X

    LOAD A, IP+@Y
    LOAD B, IP+@Y_V
    ADD A, A, B
    STORE A, IP+@Y

    MOV A, 0x40
    CALL IP+@DISPLAY

    POP C
    POP B
    POP A
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 速度更新(反射時) ;;;;;;;;;;;;;;;;;;;;
VELOCITY_X_UPDATE:
    PUSH A
    LOAD A, IP+@X_V
    SUB A, ZR, A
    STORE A, IP+@X_V
    POP A
    RET
VELOCITY_Y_UPDATE:
    PUSH A
    LOAD A, IP+@Y_V
    SUB A, ZR, A
    STORE A, IP+@Y_V
    POP A
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (X,Y)の値を取得
; X : A
; Y : B
; result : A
DISP_GET:
    PUSH B
    PUSH C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    OR C, C, B
    OR C, C, 0xF000
    LOAD A, C
    AND A, A,0xFF
    ;STORE 0x40, C
    POP C
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 表示 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DISPLAY:
    PUSH B
    PUSH C
    LOAD C, IP+@Y
    LOAD B, IP+@X
    CMP B, 0x01
    MOV.s B, 0x01
    CMP B, 0x27
    MOV.ns B, 0x26
    STORE B, IP+@X
    CALL IP+@DISPLAY_ADDR
    POP C
    POP B
    RET
DISPLAY_ADDR:
    PUSH B
    PUSH C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    SLL C, C
    OR C, C, B
    OR C, C, 0xF000
    ; Todo:点数追加ルーチンを追加
    LOAD B, C
    CMP B, 0xFF23
    CALL.z IP+@SCORE_INC
    ; 更新先が壁かどうか (0x1Fならば更新しない)
    LOAD B, C
    CMP B, 0xFF1F
    STORE.nz A, C
    POP C
    POP B
    RET

SCORE_INC:
    PUSH A
    PUSH B
    MOV A, 0x0D
    CALL 0x11
    LOAD A, IP+@SCORE
    INC A, A
    STORE A, IP+@SCORE
    MOV B, 0x02
    ;CMP A, 0xA
    CMP A, 0x64
    ;CMP A, 0x73
    STORE.ns B, IP+@STATUS
    ;CALL 0x19
    CALL IP+@PRINT_NUM
    POP B
    POP A
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; カーソル位置更新 ;;;;;;;;;;;;;;;;;;;;
CURSOL_UPDATE:
    PUSH A
    PUSH B
    MOV B, 0x00
    LOAD A, IP+@CURSOL
    DEC A,A
    ADD A, A, 0xF700
    STORE ZR, A
CURSOL_UPDATE_L:
    INC A, A
    STORE 0x3D, A
    INC B, B
    ;CMP B, 0x04
    CMP B, 0x06
    JMP.s IP+@CURSOL_UPDATE_L
    INC A, A
    STORE ZR, A
    POP B
    POP A
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; カーソル表面での反射 ;;;;;;;;;;;;;;;;
BOUND:
    PUSH A
    PUSH B
    PUSH C
    
    LOAD B, IP+@X
    LOAD C, IP+@CURSOL
    SUB B, B, C
    ;ステータス更新
    MOV A, 0x01
    CMP B, 0xFFFF
    STORE.s A, IP+@STATUS
    CMP B, 0x06
    STORE.ns A, IP+@STATUS

    MOV A, 0x1B
    STORE A, IP+@Y

    LOAD A, IP+@Y_V
    LOAD C, IP+@X_V
    ;反射角度の設定
    CMP B, 0x00
    CALL.z IP+@BOUND_A
    CMP B, 0x01
    CALL.z IP+@BOUND_B
    CMP B, 0x02
    CALL.z IP+@BOUND_C
    CMP B, 0x03
    CALL.z IP+@BOUND_D
    CMP B, 0x04
    CALL.z IP+@BOUND_E
    CMP B, 0x05
    CALL.z IP+@BOUND_F

    ;LOAD A, IP+@Y_V
    ;CALL 0x19
    STORE A, IP+@Y_V
    STORE C, IP+@X_V

    POP C
    POP B
    POP A
    RET
BOUND_A:
    MOV A, 0xFFFF
    MOV C, 0xFFFE
    RET
BOUND_B:
    MOV A, 0xFFFF
    MOV C, 0xFFFF
    RET
BOUND_C:
    MOV A, 0xFFFE
    MOV C, 0xFFFF
    RET
BOUND_D:
    MOV A, 0xFFFE
    MOV C, 0x01
    RET
BOUND_E:
    MOV A, 0xFFFF
    MOV C, 0x01
    RET
BOUND_F:
    MOV A, 0xFFFF
    MOV C, 0x02
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;