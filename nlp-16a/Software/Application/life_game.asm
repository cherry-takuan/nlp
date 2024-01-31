MainLoop:
    CALL IP+@PrintField    
    LOAD A, 0x9000
    STORE A, 0x9010

    LOAD B, 0x900F
    LOAD C, 0x9000
    MOV D, 0x00
MainLoopL1:
    MOV A, B
    MOV B, C
    LOAD C, D+0x9001
    CALL IP+@NextCells
    STORE A, D+0x9020
    INC D, D
    CMP D, 0x10
    JMP.nz IP+@MainLoopL1

    MOV D, 0x00
MainLoopL2:
    LOAD A, D+0x9020
    STORE A, D+0x9000
    INC D, D
    CMP D, 0x10
    JMP.nz IP+@MainLoopL2
    JMP IP+@MainLoop
S3:             ;3個
    .dw 0x0000
S2:             ;2個
    .dw 0x0000
S1:             ;1個
    .dw 0x0000
S0:             ;0個
    .dw 0x0000
S_DMY:             ;計算用
    .dw 0x0000


; A, B, C -> A : A:field[i-1], B:field[i], C:field[i+1]. 次のfield[i]を計算

NextCells:
    PUSH A
    MOV A, 0xFFFF
    STORE A, IP+@S0
    POP A
    STORE ZR, IP+@S1
    STORE ZR, IP+@S2
    STORE ZR, IP+@S3

    MOV E, 0x0D ; '\n'
    MOV E, 0x0A ; '\n'
    MOV E, 0x0D ; '\n'
    MOV E, 0x0A ; '\n'
    MOV E, 0x41 ; 'O'
    ;情報出力
    PUSH A
    CALL 0x43
    MOV E, 0x2C ; 'O'
    MOV A, B
    CALL 0x43
    MOV E, 0x2C ; 'O'
    MOV A, C
    CALL 0x43
    MOV E, 0x2C ; 'O'
    POP A

    ; 一度現在の行を退避
    PUSH B
    ; ul
    ROL B, A
    CALL IP+@AccumCount
    ; u
    ROR B, B
    CALL IP+@AccumCount
    ; ur
    ROR B, B
    CALL IP+@AccumCount
    ; dl
    ROL B, C
    CALL IP+@AccumCount
    ; d
    ROR B, B
    CALL IP+@AccumCount
    ; dr
    ROR B, B
    CALL IP+@AccumCount
    ; l
    POP B
    ROL B, B
    CALL IP+@AccumCount
    ; r
    ROR B, B
    ROR B, B
    CALL IP+@AccumCount

    ROL B, B               ; Bを元にもどす
    ; 退避
    PUSH C
    PUSH D
    ;必要なものをロード
    LOAD C, IP+@S2    ; c2
    LOAD D, IP+@S3    ; c3
    ; A = c & (c2|c3) | ~c & c3;
    OR C, C, D
    AND A, B, C
    NOT C, B
    AND C, C, D
    OR A, A, C

    ;情報出力
    PUSH A
    CALL 0x43
    MOV E, 0x2C ; 'O'
    POP A

    ; 復帰
    POP D
    POP C
    RET

; B -> _ : Bは加算する近隣のセルを表す値.

AccumCount:
    MOV E, 0x0D ; '\n'
    MOV E, 0x0A ; '\n'
    MOV E, 0x42 ; 'O'
    ; 退避
    PUSH A
    PUSH C
    PUSH D
    MOV A, IP+@S3           ; 開始アドレス代入
AccumCountL1:               ; Sn = Sn & ~B | Sn-1 & B
    MOV E, 0x43 ; 'O'
    LOAD C, A               ; Sn
    NOT B, B                ; ~B
    AND D, C, B             ; Sn & ~B

    INC A, A
    LOAD C, A               ; Sn-1
    NOT B, B                ; ~(~B) -> B
    AND C, C, B             ; Sn & B

    OR C, C, D              ; Sn = Sn & ~B | Sn-1 & B
    STORE C, A-0x01

    ;情報出力
    PUSH A
    MOV A, C
    CALL 0x43
    MOV E, 0x2C ; 'O'
    POP A

    MOV C, IP+@S_DMY        ;最終アドレス
    CMP A, C                ;最終アドレスと比較
    JMP.nz IP+@AccumCountL1 ;最後まで処理したならば終了

    ; 復帰
    POP D
    POP C
    POP A
    RET


; A -> _ : 16ビットを2進数で出力

Print16:
    PUSH A
    PUSH B  ; イテレータ
    PUSH C
    MOV B, 0x00

    ; do { ..; A <<= 1; B--;} while(B > 0)


Print16L1:
    ; if(A & 0x8000) putchar('O'); else putchar('.');


    MOV C, 0x40 ; 'O'


    AND ZR, A, 0x8000
    MOV.z C, 0x5F ; '.'

    
    MOV E, C
    
    SLL A, A
    INC B, B
    CMP B, 0x10
    JMP.nz IP+@Print16L1

    MOV E, 0x0D ; '\n'
    MOV E, 0x0A ; '\n'

    POP C
    POP B
    POP A
    RET

; _ -> _ : フィールド全体を出力


PrintField:
    PUSH A
    PUSH B
    MOV B, 0x00
    MOV E, 0x0D ; '\n'
    MOV E, 0x0A ; '\n'

PrintFieldL1:
    LOAD A, B+0x9000
    CALL IP+@Print16

    INC B, B
    CMP B, 0x10
    JMP.nz IP+@PrintFieldL1

    MOV E, 0x0D ; '\n'
    MOV E, 0x0A ; '\n'

    POP B
    POP A
    RET