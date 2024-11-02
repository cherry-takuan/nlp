;
DEBUG_PRINT:
    MOV A, IP+@TXT_BUF
    CALL 0x17
    CALL IP+@PRINT_LINE
    MOV A, 0x0A
    CALL 0x11
    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    CALL IP+@CHAR_DEL
    MOV A, 0x30
    CALL IP+@CHAR_INS
    MOV A, 0x31
    CALL IP+@CHAR_INS
    MOV A, 0x32
    CALL IP+@CHAR_INS
    MOV A, 0x33
    CALL IP+@CHAR_INS
    MOV A, 0x34
    CALL IP+@CHAR_INS
    MOV A, 0x35
    CALL IP+@CHAR_INS
    CALL IP+@PRINT_LINE
    MOV A, 0x0A
    CALL 0x11
    RET
;A文字目の文字を表示
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
    MOV B, IP+@TXT_BUF
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
    MOV C, IP+@TXT_BUF
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
TOP_END_P:
    .dw 0x0005
BOTTOM_START_P:
    .dw 0x000A
BUF_SIZE:
    .dw 0x10
.ascii:TXT_BUF "hello old world\r\n\0"