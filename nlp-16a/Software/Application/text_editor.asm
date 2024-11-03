;
INIT:
    PUSH A
    PUSH B
    PUSH C
    PUSH D
    
    MOV A, IP+@TXT_BUF_START_ADDR
    STORE A, IP+@TXT_BUF
    ;CALL IP+@PRINT_LINE
;Bはカーソル行
;先頭行は1
;先頭に挿入はカーソルを0に持っていって挿入
MAIN:
    ;改行
    MOV A, 0x0D
    CALL 0x11
    MOV A, 0x0A
    CALL 0x11
    ;プロンプト表示
    MOV A, IP+@C_MODE
    CALL 0x0017

    CALL 0x0013 ;文字入力サブルーチン
    PUSH A
    CALL 0x11;プロンプトにコマンド表示
    POP A

    ;switch case
    CMP A, 0x70 ;p 表示
    CALL.z IP+@BUF_PRINTS
    CMP A, 0x61 ;a 追記
    CALL.z IP+@TXT_EDIT
    CMP A, 0x64 ;d 削除
    CALL.z IP+@LINE_DEL
    CMP A, 0x70 ;c 変更
    CMP A, 0x44 ;D デバッグ表示
    CALL.z IP+@DEBUG_VIEW
    CMP A, 0x71 ;q 終了
    JMP.z IP+@MAIN_END

    JMP IP+@MAIN
MAIN_END:
    POP D
    POP C
    POP B
    POP A
    RET

.ascii:C_MODE "c-mode>\0"

BUF_PRINTS:
    PUSH A
    PUSH C
    MOV A, 0x20 ;スペース
    CALL 0x11
    ;数値入力サブルーチン 強制数値入力モード設定
    ;MOV A, IP+@BUF_PRINTS_MENU
    MOV A, 0x00
    STORE A, 0x8018
    CALL 0x0006;開始行
    PUSH A
    MOV A, 0x2D ;ハイフン
    CALL 0x11
    CALL 0x0006;最終行
    INC B, A
    POP A

BUF_PRINTS_L0:
    ;表示
    MOV C, A
    CALL IP+@PRINT_LINE
    CMP A, 0xFFFF
    JMP.z IP+@BUF_PRINTS_END
    INC A, A
    CMP A, B
    JMP.s IP+@BUF_PRINTS_L0
BUF_PRINTS_END:
    MOV B, C ;Cに格納した現在のカーソル位置をBにPOP
    POP C
    POP A
    RET

BUF_PRINTS_MENU:


LINE_DEL:
    PUSH A
    PUSH B
;行の頭出し
    INC A, B ;ここのAは行
    CALL IP+@LINE_HEAD
    SUB B, A, 0x02
    DEC A, A
    CALL IP+@CURSOL_UPDATE
LINE_DEL_L0:
    MOV A, B
    CALL IP+@CHAR_GET
    PUSH A
    CALL IP+@CHAR_DEL
    POP A
    CMP A, 0x0A
    JMP.z IP+@LINE_DEL_END
    CMP A, 0xFFFF
    JMP.z IP+@LINE_DEL_END
    DEC B, B
    JMP IP+@LINE_DEL_L0
LINE_DEL_END:
    POP B
    DEC B, B ;削除したのでその分を戻す
    POP A
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TXT_EDIT:
    PUSH A
    PUSH B
    PUSH C
    MOV A, 0x0D
    CALL 0x11
    MOV A, 0x0A
    CALL 0x11
    MOV A, IP+@A_MODE
    CALL 0x17
    MOV A, B
    MOV C, 0x00 ;カーソル位置
;行の頭出し
    INC A, B
    CALL IP+@LINE_HEAD
    ;MOV C, 0x00
    MOV C, A
TXT_EDIT_CURSOL_MOVE:
    CALL IP+@CURSOL_UPDATE
    ;MOV A, B
    ;CALL IP+@PRINT_LINE
;文字入力の受付
TXT_EDIT_L2:
    CALL 0x0013
    
    ; ESC
    CMP A, 0x1B
    CALL.z IP+@DEBUG_VIEW
    ; BS
    CMP A, 0x08
    CALL.z IP+@BS
    ; ENTER
    CMP A, 0x0D
    JMP.z IP+@TXT_EDIT_END

    CMP A, 0x20
    JMP.s IP+@TXT_EDIT_L2
    CMP A, 0x7F
    JMP.ns IP+@TXT_EDIT_L2
    PUSH A
    CALL 0x11
    POP A
    ;INC C, C
    CALL IP+@CHAR_INS
    JMP IP+@TXT_EDIT_L2

TXT_EDIT_END:
    MOV A, 0x0A
    CALL IP+@CHAR_INS

    POP C
    POP B
    POP A
    RET
.ascii:A_MODE "a-mode>\0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
BS:
    ;CMP C, 0x01
    LOAD A, IP+@TOP_END_P
    CMP C, A
    RET.ns
    CALL IP+@CHAR_DEL
    MOV A, 0x08
    CALL 0x11
    MOV A, 0x20
    CALL 0x11
    MOV A, 0x08
    CALL 0x11
    DEC C, C
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEBUG_VIEW:
    PUSH A
    PUSH B
    PUSH C
    PUSH D
    ;改行
    MOV A, 0x0D
    CALL 0x11
    MOV A, 0x0A
    CALL 0x11
    
    LOAD A, IP+@TOP_END_P
    CALL 0x0019
    CALL 0x0015
    LOAD A, IP+@BOTTOM_START_P
    CALL 0x0019
    CALL 0x0015
    LOAD A, IP+@BUF_SIZE
    CALL 0x0019
    CALL 0x0015
    LOAD A, IP+@TXT_BUF
    CALL 0x0019
    CALL 0x0015

    MOV B, 0x00
    LOAD C, IP+@BUF_SIZE
    LOAD D, IP+@TXT_BUF
    MOV A, 0x3E
    CALL 0x11
DEBUG_VIEW_L0:
    CMP B, C
    JMP.ns IP+@DEBUG_VIEW_END
    LOAD A, B+D
    CMP A, 0x20
    MOV.s A, 0x40
    CMP A, 0x7F
    MOV.ns A, 0x2F
    CALL 0x11
    INC B, B
    JMP IP+@DEBUG_VIEW_L0
DEBUG_VIEW_END:
    MOV A, 0x3C
    CALL 0x11
    CALL 0x15
    ;CALL IP+@PRINT_LINE
    POP D
    POP C
    POP B
    POP A
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINT_LINE:
    PUSH B
    PUSH C
    MOV C, A
    MOV B, 0x00
    PUSH A
    MOV A, 0x0D
    CALL 0x11
    MOV A, 0x0A
    CALL 0x11
    MOV A, C
    CALL 0x0019
    MOV A, 0x3A
    CALL 0x11
    CMP C, 0x00
    JMP.z IP+@PRINT_LINE_END

    MOV A, C
    CALL IP+@LINE_HEAD
    CMP A, 0xFFFF
    JMP.z IP+@PRINT_LINE_END
    MOV B, A
PRINT_LINE_L2:
    MOV A, B
    CALL IP+@CHAR_GET
    CMP A, 0xFFFF
    JMP.z IP+@PRINT_LINE_END
    CMP A, 0x00
    JMP.z IP+@PRINT_LINE_END
    CMP A, 0x0A
    JMP.z IP+@PRINT_LINE_END
    CALL 0x11
    INC B, B
    JMP IP+@PRINT_LINE_L2
PRINT_LINE_END:
    MOV B, A
    POP A ;表示行を返す    
    ;エラーもしくは末端では0xFFFFを返す
    CMP B, 0xFFFF
    MOV.z A, 0xFFFF
    ;CMP B, 0x0000
    ;MOV.z A, 0xFFFF

    POP C
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A行目の先頭アドレスをAに返す
LINE_HEAD:
    PUSH B
    PUSH C
    MOV C, A ;行カウンタ
    MOV A, 0x00
    MOV B, 0x00 ;配列ポインタ
LINE_HEAD_L0:
    CMP C, 0x02
    JMP.s IP+@LINE_HEAD_END
    MOV A, B
    CALL IP+@CHAR_GET
    CMP A, 0xFFFF
    JMP.z IP+@LINE_HEAD_END
    INC B, B
    CMP A, 0x0A
    DEC.z C, C
    JMP IP+@LINE_HEAD_L0
LINE_HEAD_END:
    ;CMP A, 0xFFFF ;CHAR_GETの結果が0xFFFFであれば更新しない
    MOV A, B
    
    ;PUSH A
    ;CALL 0x0019
    ;POP A

    POP C
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;A番目の文字の配列内のアドレスをAに返す
CHAR_ADDR_GET:
    PUSH B
    LOAD B, IP+@TOP_END_P
    CMP A, B
    JMP.s IP+@CHAR_ADDR_GET_END
    SUB A, A, B
    LOAD B, IP+@BOTTOM_START_P
    ADD A, A, B
CHAR_ADDR_GET_END:
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;OUTPUT系
;A番目の文字をAに返す
CHAR_GET:
    PUSH B
    PUSH C
    CALL IP+@CHAR_ADDR_GET
CHAR_GET_END:
    ;この時点でAは配列内のアドレスに変換されている
    ;境界値検査
    MOV C, 0x00
    LOAD B, IP+@BUF_SIZE
    CMP A, B
    MOV.ns C, 0xFFFF
    ;実アドレスの計算
    LOAD B, IP+@TXT_BUF
    LOAD A, A+B
    ;境界値検査に引っ掛かっていればCは0xFFFFなので結果も0xFFFFになる。そうでなければ通常通り値が返される
    OR A, A, C
    POP C
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;挿入系

;現在のカーソル位置にAの文字を追加
;挿入成功 0x0000
;挿入失敗 0xFFFF
CHAR_INS:
    PUSH B
    PUSH C
    PUSH A
    
    MOV A, 0xFFFF
    LOAD B, IP+@TOP_END_P
    LOAD C, IP+@BOTTOM_START_P
    CMP B, C
    RET.ns ;バッファがFULLならば0xFFFFを返す

    ;実アドレスを計算し文字を格納
    POP A
    LOAD C, IP+@TXT_BUF
    STORE A, B+C
    ;アドレスを更新
    INC B, B
    STORE B, IP+@TOP_END_P

    MOV A, 0x00
    POP C
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;削除系
;現在のカーソル位置の一文字削除
CHAR_DEL:
    LOAD A, IP+@TOP_END_P
    CMP A, 0x01
    DEC.ns A, A
    STORE A, IP+@TOP_END_P
    ;CALL 0x0019 ;数値表示サブルーチン
    ;CALL 0x0015 ;OKサブルーチン
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;カーソル操作系
;カーソル位置をAにする
CURSOL_UPDATE:
    PUSH B
    PUSH C
    PUSH D
    MOV D, A ;new cursolはD
    LOAD B, IP+@TOP_END_P
    CMP A, B
    JMP.ns IP+@CURSOL_UPDATE_L1
CURSOL_UPDATE_L0:
    MOV A, D
    CALL IP+@CHAR_ADDR_GET
    LOAD B, IP+@TOP_END_P
    CMP A, B
    JMP.ns IP+@CURSOL_UPDATE_END
    ;--top_end_p,--bottom_start_p;
    LOAD B, IP+@TOP_END_P
    ;先頭まで
    DEC B, B
    CMP B, 0x00
    JMP.s IP+@CURSOL_UPDATE_END

    STORE B, IP+@TOP_END_P
    LOAD C, IP+@BOTTOM_START_P
    DEC C, C
    STORE C, IP+@BOTTOM_START_P
    ;buf[bottom_start_p] = buf[top_end_p];
    PUSH D
    LOAD D, IP+@TXT_BUF
    LOAD A, D+B
    STORE A, D+C
    POP D
    JMP IP+@CURSOL_UPDATE_L0

CURSOL_UPDATE_L1:
    MOV A, D
    CALL IP+@CHAR_ADDR_GET
    LOAD B, IP+@BOTTOM_START_P
    CMP B, A
    JMP.ns IP+@CURSOL_UPDATE_END
    ;buf[top_end_p] = buf[bottom_start_p];
    LOAD B, IP+@TOP_END_P
    LOAD C, IP+@BOTTOM_START_P
    PUSH D
    LOAD D, IP+@TXT_BUF
    LOAD A, D+C
    STORE A, D+B
    POP D
    ;++top_end_p,++bottom_start_p;
    INC B, B
    STORE B, IP+@TOP_END_P
    INC C, C

    LOAD A, IP+@BUF_SIZE
    CMP C, A
    JMP.ns IP+@CURSOL_UPDATE_END
    
    STORE C, IP+@BOTTOM_START_P
    JMP IP+@CURSOL_UPDATE_L1

CURSOL_UPDATE_END:
    POP D
    POP C
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOP_END_P:
    .dw 0x0017
BOTTOM_START_P:
    .dw 0x0040
BUF_SIZE:
    .dw 0x40
TXT_BUF:
    .dw 0xFFFF
.ascii:TXT_BUF_START_ADDR "hello\nold\nworld\nabcdefg\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"