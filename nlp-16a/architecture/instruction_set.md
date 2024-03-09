# NLP-16A 命令セット

2024-03-09 改定

NLP-16Aの命令セット，2024/02/26時点での暫定．
本当はNLP-16にバイナリレベルでの後方互換を保ちたかったのですが，デコードの関係上ちょっとやめました．

## 命令bit構成
NLP-16A 命令セットでは1～3ワードの可変長命令を採用している．
各ワードの構成は以下の通り．

| 1word |  |  |
|:-:|:-:|:-:|
| opcode (8 bit) | Flag (4 bit) | operand A (4 bit)|

| 2word |  |  |
|:-:|:-:|:-:|
| operand B (4 bit)| operand C (4 bit)| 8 bit Imm (8 bit)|

| 3word |
|:-:|
| 16 bit Imm (16 bit)|

### Flagフィールド
NLP-16A命令セットではすべての命令において条件実行ができる．条件は1ワード目のFlagフィールドで設定し，条件に合致した場合は実行され，合致しない場合には命令は無視され，次の命令を実行する．

なお，必要クロック数は実行，非実行に依らない．

サフィックスはアセンブリでは以下のような表現になる．
`MOV.s B,A`(直前の演算結果が負の場合，RegAの値をRegBに転送する．)
| 条件 |サフィックス| 値 |
|:-:|:-:|:-:|
|NOP|.nop|0x0|
|Cが立っている時に実行|.c|0x8|
|前回の演算結果がオーバーフローしたときに実行|.v|0xA|
|0の時に実行|.z|0xC|
|負の時に実行|.s|0xE|
|常に実行|無|0x1|
|Cが立っていない時に実行|.nc|0x9|
|オーバーフローしなかったときに実行|.nv|0xB|
|非ゼロで実行|.nz|0xD|
|正，もしくは0の時に実行|.ns|0xF|

### 汎用レジスタID
operand AからCで指定するレジスタのID．アキュムレータAccは指定することはできない．
| 汎用レジスタ | 値 |
|:-:|:-:|
| Reg A | 0x5 |
| Reg B | 0x6 |
| Reg C | 0x7 |
| Reg D | 0x8 |
| Reg E | 0x9 |
| Reg F | 0xA |

## 演算系命令

`x`はDon't care，`-`は存在しない(例えば2ワード命令では3ワード目を使用しない等)フィールド．

### 算術演算

#### ADD
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|ADD c, a,  b<br>(c = a+b)|2| 0x0A | c | a | b | x | - ||
|ADD c, a,  Imm8<br>(c = a+Imm8)|2| 0x0A | c | a | 0x1 | Imm8 | - ||
|ADD c, a,  Imm16<br>(c = a+Imm16)|3| 0x0A | c | a | 0x2 | x | Imm16 ||
|ADD a<br>(a = a + Acc)|1| 0x4A | a | - | - | - | - ||
|ADC c, a,  b<br>(c = a+b+carry)|2| 0x0E | c | a | b | x | - ||
|ADC c, a,  Imm8<br>(c = a+Imm8+carry)|2| 0x0E | c | a | 0x1 | Imm8 | - ||
|ADC c, a,  Imm16<br>(c = a+Imm16+carry)|3| 0x0E | c | a | 0x2 | x | Imm16 ||
|ADC a<br>(a = a + Acc+carry)|1| 0x4E | a | - | - | - | - ||

#### SUB
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|SUB c, a,  b<br>(c = a-b)|2| 0x09 | c | a | b | x | - ||
|SUB c, a,  Imm8<br>(c = a-Imm8)|2| 0x09 | c | a | 0x1 | Imm8 | - |operand BとCは入れ替え(計算順序の入れ替え)可能(次行)|
|SUB c, Imm8, a<br>(c = Imm8 - a)|2| 0x09 | c | 0x01 | a | Imm8 | - |入れ替え後|
|SUB c, a,  Imm16<br>(c = a-Imm16)|3| 0x09 | c | a | 0x2 | x | Imm16 |計算順序の入れ替え可能 SUB c,a,Imm8参照|
|SUB a<br>(a = a - Acc)|1| 0x49 | a | - | - | - | - ||
|SBB c, a,  b<br>(c = a-b-borrow)|2| 0x0D | c | a | b | x | - ||
|SBB c, a,  Imm8<br>(c = a-Imm8-borrow)|2| 0x0D | c | a | 0x1 | Imm8 | - |計算順序の入れ替え可能 SUB c,a,Imm8参照|
|SBB c, a,  Imm16<br>(c = a-Imm16-borrow)|3| 0x0D | c | a | 0x2 | x | Imm16 |計算順序の入れ替え可能 SUB c,a,Imm8参照|
|SBB a<br>(a = a - Acc-borrow)|1| 0x4D | a | - | - | - | - ||

#### INC
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|INC b, a<br>(b = a+1)|2| 0x1B | b | a | x | x | - ||
|INC a, Imm8<br>(a = Imm8+1)|2| 0x1B | a | 0x1 | x | Imm8 | - ||
|INC a, Imm16<br>(a = Imm16+1)|3| 0x1B | a | 0x2 | x | x | Imm16 ||
|INC a<br>(a = a+1)|1| 0x5B | a | - | - | - | - ||
|INCC b, a<br>(b = a+1+carry)|2| 0x1F | b | a | x | x | - ||
|INCC a, Imm8<br>(a = Imm8+1+carry)|2| 0x1F | a | 0x1 | x | Imm8 | - ||
|INCC a, Imm16<br>(a = Imm16+1+carry)|3| 0x1F | a | 0x2 | x | x | Imm16 ||
|INCC a<br>(a = a+1+carry)|1| 0x5F | a | - | - | - | - ||

#### DEC
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|DEC b, a<br>(b = a-1)|2| 0x18 | b | a | x | x | - ||
|DEC a, Imm8<br>(a = Imm8-1)|2| 0x18 | a | 0x1 | x | Imm8 | - ||
|DEC a, Imm16<br>(a = Imm16-1)|3| 0x18 | a | 0x2 | x | x | Imm16 ||
|DEC a<br>(a = a-1)|1| 0x58 | a | - | - | - | - ||
|DECB b, a<br>(b = a-1-borrow)|2| 0x1C | b | a | x | x | - ||
|DECB a, Imm8<br>(a = Imm8-1-borrow)|2| 0x1C | a | 0x1 | x | Imm8 | - ||
|DECB a, Imm16<br>(a = Imm16-1-borrow)|3| 0x1C | a | 0x2 | x | x | Imm16 ||
|DECB a<br>(a = a-1-borrow)|1| 0x5C | a | - | - | - | - ||

### 論理演算
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|AND c, a,b<br>(c = a & b)|2| 0x06 | c | a | b | x | - ||
|AND a<br>(a = a & Acc)|1| 0x46 | a | - | - | - | - ||
|OR c, a,b<br>(c = a \| b)|2| 0x12 | c | a | b | x | - ||
|OR a<br>(a = a \| Acc)|1| 0x52 | a | - | - | - | - ||
|NOT b, a<br>(b = ~a)|2| 0x14 | b | a | x | x | - ||
|NOT a<br>(a = ~a)|1| 0x54 | a | - | - | - | - ||
|XOR c, a,b<br>(c = a ^ b)|2| 0x16 | c | a | b | x | - ||
|XOR a<br>(a = a ^ Acc)|1| 0x56 | a | - | - | - | - ||

### シフト演算
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|SHL a<br>(a = a << 1)|1| 0x60 | a | - | - | - | - ||
|SHR a<br>(a = a >> 1)|1| 0x70 | a | - | - | - | - ||
|SAL a<br>(a = a << 1)|1| 0x64 | a | - | - | - | - |算術シフト|
|SAR a<br>(a = a >> 1)|1| 0x74 | a | - | - | - | - |算術シフト|
|ROL a<br>(a = a << 1)|1| 0x62 | a | - | - | - | - |ロール命令|
|ROR a<br>(a = a >> 1)|1| 0x72 | a | - | - | - | - |ロール命令|
|SHL b,a<br>(b = a << 1)|2| 0x60 | b | a | x | x | - ||
|SHR b,a<br>(b = a >> 1)|2| 0x70 | b | a | x | x | - ||
|SAL b,a<br>(b = a << 1)|2| 0x64 | b | a | x | x | - |算術シフト|
|SAR b,a<br>(b = a >> 1)|2| 0x74 | b | a | x | x | - |算術シフト|
|ROL b,a<br>(b = a << 1)|2| 0x62 | b | a | x | x | - |ロール命令|
|ROR b,a<br>(b = a >> 1)|2| 0x72 | b | a | x | x | - |ロール命令|

## 転送命令
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|MOV b, a<br>(b <- a)|2| 0x00 | b | a | x | x | - ||
|MOV a, Imm8<br>(a <- Imm8)|2| 0x00 | a | 0x1 | x | Imm8 | - ||
|MOV a, Imm16<br>(a <- Imm16)|3| 0x00 | a | 0x2 | x | x | Imm16 ||

## JMP命令
### 無条件JMP命令
#### 直接アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|JMP Imm8<br>(IP <- Imm8)|2| 0x00 | 0xD | 0x1 | Imm8 | x | - ||
|JMP Imm16<br>(IP <- Imm16)|3| 0x00 | 0xD | 0x2 | x | x | Imm16 ||

#### レジスタ間接アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|JMP a<br>(IP <- a)|2| 0x00 | 0xD | a | x | x | - ||

#### ベース修飾アドレッシング？
ベースレジスタは存在しないため，ベースレジスタに代わり汎用レジスタを使用する
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|JMP a+Imm8<br>(IP <- a+Imm8)|2| 0x0A | 0xD | a | 0x1 | Imm8 | - |ベース+オフセット(Imm)|
|JMP a+Imm16<br>(IP <- a+Imm16)|3| 0x0A | 0xD | a | 0x2 | x | Imm16 |ベース+オフセット(Imm)|
|JMP a-Imm8<br>(IP <- a-Imm8)|2| 0x09 | 0xD | a | 0x1 | Imm8 | - |ベース-オフセット(Imm)|
|JMP a-Imm16<br>(IP <- a-Imm16)|3| 0x09 | 0xD | a | 0x2 | x | Imm16 |ベース-オフセット(Imm)|
|JMP a+b<br>(IP <- a+b)|2| 0x0A | 0xD | a | b | x | - ||
|JMP a-b<br>(IP <- a-b)|2| 0x09 | 0xD | a | b | x | - ||

#### IP相対アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|JMP IP+a<br>(IP <- IP+a)|2| 0x0A | 0xD | 0xD | a | x | - ||
|JMP IP+Imm8<br>(IP <- a+Imm8)|2| 0x0A | 0xD | 0xD | 0x1 | Imm8 | - ||
|JMP IP+Imm16<br>(IP <- a+Imm16)|3| 0x0A | 0xD | 0xD | 0x2 | x | Imm16 ||
|JMP IP-a<br>(IP <- IP-a)|2| 0x09 | 0xD | 0xD | a | x | - ||
|JMP IP-Imm8<br>(IP <- a-Imm8)|2| 0x09 | 0xD | 0xD | 0x1 | Imm8 | - ||
|JMP IP-Imm16<br>(IP <- a-Imm16)|3| 0x09 | 0xD | 0xD | 0x2 | x | Imm16 ||

### 条件JMP命令
NLP-16Aではすべての命令を条件実行可能なため，通常のJMP命令のFlagフィールドに条件を指定し，条件JMPを実現する．

## サブルーチン命令
### サブルーチンコール命令
#### 直接アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|CALL Imm8<br>(IP <- Imm8)|2| 0xB0 | 0xD | 0x1 | Imm8 | x | - ||
|CALL Imm16<br>(IP <- Imm16)|3| 0xB0 | 0xD | 0x2 | x | Imm16 | - ||

#### レジスタ間接アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|CALL a<br>(IP <- a)|2| 0xB0 | 0xD | a | x | x | - ||

#### ベース修飾アドレッシング？
ベースレジスタは存在しないため，ベースレジスタに代わり汎用レジスタを使用する
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|CALL a+Imm8<br>(IP <- a+Imm8)|2| 0xBA | 0xD | a | 0x1 | Imm8 | - |ベース+オフセット(Imm)|
|CALL a+Imm16<br>(IP <- a+Imm16)|3| 0xBA | 0xD | a | 0x2 | x | Imm16 |ベース+オフセット(Imm)|
|CALL a-Imm8<br>(IP <- a-Imm8)|2| 0xB9 | 0xD | a | 0x1 | Imm8 | - |ベース-オフセット(Imm)|
|CALL a-Imm16<br>(IP <- a-Imm16)|3| 0xB9 | 0xD | a | 0x2 | x | Imm16 |ベース-オフセット(Imm)|
|CALL a+b<br>(IP <- a+b)|2| 0xBA | 0xD | a | b | x | - ||
|CALL a-b<br>(IP <- a-b)|2| 0xB9 | 0xD | a | b | x | - ||

#### IP相対アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|CALL IP+a<br>(IP <- IP+a)|2| 0xBA | 0xD | 0xD | a | x | - ||
|CALL IP+Imm8<br>(IP <- a+Imm8)|2| 0xBA | 0xD | 0xD | 0x1 | Imm8 | - ||
|CALL IP+Imm16<br>(IP <- a+Imm16)|3| 0xBA | 0xD | 0xD | 0x2 | x | Imm16 ||
|CALL IP-a<br>(IP <- IP-a)|2| 0xB9 | 0xD | 0xD | a | x | - ||
|CALL IP-Imm8<br>(IP <- a-Imm8)|2| 0xB9 | 0xD | 0xD | 0x1 | Imm8 | - ||
|CALL IP-Imm16<br>(IP <- a-Imm16)|3| 0xB9 | 0xD | 0xD | 0x2 | x | Imm16 ||

#### 条件サブルーチンコール
条件JMP同様．

### リターン命令
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|RET|1| 0xC0 | 0xD | - | - | - | - ||

## メモリ操作
### LOAD命令
#### 直接アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|LOAD a,Imm8<br>(a <-MEM\[Imm8])|2| 0x80 | a | 0x1 | Imm8 | x | - ||
|LOAD a,Imm16<br>(a <-MEM\[Imm16])|3| 0x80 | a | 0x2 | x | x | Imm16 ||

#### レジスタ間接アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|LOAD a,b<br>(a <-MEM\[b])|2| 0x80 | a | b | x | x | - ||

#### ベース修飾アドレッシング？
ベースレジスタは存在しないため，ベースレジスタに代わり汎用レジスタを使用する
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|LOAD a,b+Imm8<br>(a <-MEM\[b+Imm8])|2| 0x8A | a | b | 0x1 | Imm8 | - |ベース+オフセット(Imm)|
|LOAD a,b+Imm16<br>(a <-MEM\[b+Imm16])|3| 0x8A | a | b | 0x2 | x | Imm16 |ベース+オフセット(Imm)|
|LOAD a,b-Imm8<br>(a <-MEM\[b-Imm8])|2| 0x89 | a | b | 0x1 | Imm8 | - |ベース-オフセット(Imm)|
|LOAD a,b-Imm16<br>(a <-MEM\[b-Imm16])|3| 0x89 | a | b | 0x2 | x | Imm16 |ベース-オフセット(Imm)|
|LOAD a,b+c<br>(a <-MEM\[b+c])|2| 0x8A | a | b | c | x | - ||
|LOAD a,b-c<br>(a <-MEM\[b-c])|2| 0x89 | a | b | c | x | - ||

#### IP相対アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|LOAD a,IP+b|2| 0x8A | a | 0xD | b | x | - ||
|LOAD a,IP+Imm8|2| 0x8A | a | 0xD | 0x1 | Imm8 | - ||
|LOAD a,IP+Imm16|3| 0x8A | a | 0xD | 0x2 | x | Imm16 ||
|LOAD a,IP-b<br>|2| 0x89 | a | 0xD | b | x | - ||
|LOAD a,IP-Imm8|2| 0x89 | a | 0xD | 0x1 | Imm8 | - ||
|LOAD a,IP-Imm16|3| 0x89 | a | 0xD | 0x2 | x | Imm16 ||

#### SP相対アドレッシング
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|LOAD a,SP+b|2| 0x8A | a | 0xE | b | x | - ||
|LOAD a,SP+Imm8|2| 0x8A | a | 0xE | 0x1 | Imm8 | - ||
|LOAD a,SP+Imm16|3| 0x8A | a | 0xE | 0x2 | x | Imm16 ||
|LOAD a,SP-b<br>|2| 0x89 | a | 0xE | b | x | - ||
|LOAD a,SP-Imm8|2| 0x89 | a | 0xE | 0x1 | Imm8 | - ||
|LOAD a,SP-Imm16|3| 0x89 | a | 0xE | 0x2 | x | Imm16 ||

### STORE命令
LOADのopcode最上位ニブルが0x9となる．例えばSP相対の`STORE a,SP+Imm8`であれば以下のようになる．
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|STORE a,SP+Imm8<br>(MEM\[SP+Imm8] <- a)|2| 0x9A | a | 0xE | 0x1 | Imm8 | - ||

その他のアドレッシングでもLOAD同様である．

## POP，PUSH命令
### POP
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|POP a|1| 0xD0 | a | - | - | - | - ||
### PUSH
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|PUSH a|1| 0xC0 | a | - | - | - | - ||

## 比較命令
### CMP
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|CMP a, b|2| 0x09 | 0xF | a | b | x | - ||

#### 即値とのCMP
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|CMP a, Imm8|2| 0x09 | 0xF | a | 0x1 | Imm8 | - ||
|CMP a, Imm8|3| 0x09 | 0xF | a | 0x2 | x | Imm16 ||

## 割り込み命令
### 割り込み許可
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|IE|1| 0xFF | x | - | - | - | - ||
### 割り込み禁止
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|ID|1| 0xFE | x | - | - | - | - ||
### 割り込み復帰
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|IRET|1| 0xE0 | 0xD | - | - | - | - ||
### ソフトウェア割り込み
JMP先はハードウェア割り込みと同様にIV Regにある番地に飛ぶ．
|ニモニック (効果)| 命令ワード数 | opcode | operand A | operand B | operand C| 8 bit Imm| 16 bit Imm|備考|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|INT|1| 0xFC | x | - | - | - | - ||

以上．