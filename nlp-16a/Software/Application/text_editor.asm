;
DEBUG_PRINT:
    MOV A, IP+@TXT_BUF_START_ADDR
    STORE A, IP+@TXT_BUF
    LOAD A, IP+@TXT_BUF
    CALL 0x17
    CALL IP+@DEBUG_VIEW
    CALL IP+@PRINT_LINE
    CALL 0x0015

    MOV A, 0x09
    CALL IP+@CURSOL_UPDATE
    CALL IP+@DEBUG_VIEW
    CALL IP+@PRINT_LINE
    CALL 0x0015


    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    CALL IP+@PRINT_LINE
    CALL 0x0015

    MOV A, 0x4E
    CALL IP+@CHAR_INS
    MOV A, 0x45
    CALL IP+@CHAR_INS
    MOV A, 0x57
    CALL IP+@CHAR_INS
    CALL IP+@DEBUG_VIEW
    CALL IP+@PRINT_LINE
    CALL 0x0015
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEBUG_VIEW:
    PUSH A
    PUSH B
    PUSH C
    PUSH D
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
    POP D
    POP C
    POP B
    POP A
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINT_LINE:
    MOV B, 0x00
PRINT_LINE_L0:
    MOV A, B
    CALL IP+@CHAR_GET
    CMP A, 0xFFFF
    RET.z
    CMP A, 0x00
    RET.z
    CMP A, 0x0A
    RET.z
    CALL 0x11
    INC B, B
    JMP IP+@PRINT_LINE_L0
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
    ;CALL 0x0019 数値表示サブルーチン
    ;CALL 0x0015 OKサブルーチン
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
    JMP.ns IP+@CURSOL_UPDATE_L1
    ;--top_end_p,--bottom_start_p;
    LOAD B, IP+@TOP_END_P
    DEC B, B
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
    DEC B, B
    STORE B, IP+@TOP_END_P
    DEC C, C
    STORE C, IP+@BOTTOM_START_P
    JMP IP+@CURSOL_UPDATE_L1

CURSOL_UPDATE_END:
    POP D
    POP C
    POP B
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOP_END_P:
    .dw 0x000F
BOTTOM_START_P:
    .dw 0x0040
BUF_SIZE:
    .dw 0x40
TXT_BUF:
    .dw 0xFFFF
.ascii:TXT_BUF_START_ADDR "hello old world\n\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"