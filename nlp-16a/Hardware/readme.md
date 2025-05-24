# ハードウェア
ハードウェアへのリンク。回路/基板データをクリックするとブラウザからアートワークや回路が閲覧できます。kicanvasすごい。ありがとう。

## NLP-16A本体
***
### 演算装置
ALUはプロセッサ内での演算処理を行うユニットです。NLP-16Aでは8bit ALUを2ユニット使用し16bitの並列演算を行っています。

ALU制御回路回路はALUを操作するための制御信号生成し，また演算結果からフラグを生成する機能を持っています。
***
#### ALU本体
[alu_c](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/alu_c)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2Falu_c)

最新バージョン : v1.2

#### ALU制御
[alu_ctrl](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/alu_ctrl)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2Falu_ctrl)

最新バージョン : v1.1
***
### レジスタファイル
レジスタファイルとは，プロセッサ内で一時的に記憶するレジスタと呼ばれる回路を複数集積したものです。NLP-16Aでは16bitのデータを記憶可能なレジスタを16本持っています。

汎用レジスタは5本で，残りのレジスタは何らかの役割を持ち，単純な記憶以外の動作も行うことがあります。

***
### レジスタ
[Reg](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/Reg)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FReg)

最新バージョン : v1.1

#### アキュムレータ
[Accumulztor](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/Accumulator)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FAccumulator)

最新バージョン : v1.1

#### ALU入力バス(A BUS)制御
[A_BUS_Ctrl](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/A_BUS_Ctrl)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FA_BUS_Ctrl)

最新バージョン : v1.1

#### ALU出力バス(Y BUS)制御
[Y_BUS_Ctrl](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/Y_BUS_Ctrl)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FY_BUS_Ctrl)

最新バージョン : v1.2
***
### 入出力
NLP-16Aは16 bit x 64 kwordの1つの入出力ポートを持っています。
内部的にはレジスタの一つとしてアクセス可能な構造になっています。

主記憶及び外部デバイスとの接続に使用されます。
***
#### 外部バス制御
[Bus_terminator](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/BUS_terminator)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FBUS_terminator)

最新バージョン : v1.1

***
### 制御装置
制御装置では，上記のユニットを入力された命令に従って制御を行います。

***

#### 命令デコーダ
[Instruction_decoder](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/Instruction_decoder)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FInstruction_decoder)

最新バージョン : v1.1

#### ステート保持レジスタ
[State_hold](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/State_hold)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FState_hold)

最新バージョン : v1.0

#### 命令デコーダ グルーロジック
[ID_interface](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/ID_interface)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FID_interface)

最新バージョン : v1.1

***

## 周辺機器

***

### NLP-16A専用デバッガ
基板の自動テストやRAMへのIPLデータ書き込み等で使用。
[debug](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/debug)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2Fdebug)

最新バージョン : v1.1

### マザーボード
プロセッサに周辺機器を接続するためのボード。マザーと言いつつ本体よりかなり小さい。
[IO_board](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/IO_board)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FIO_board)

最新バージョン : v1.1

### RAMボード(デバッガ接続版)
主記憶装置。デバッガから内容を書き換えることが可能で，IPL等の導入に使用できる。
[RAM_board](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/RAM_board)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FRAM_board)

最新バージョン : v1.1

### 通信ボード
RS-232Cを介して様々なデバイスと通信可能。PC，サーマルプリンタ，MSMPインターフェイス等と接続した実績がある。
[RS_232C_board](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/RS_232C_board)
[回路/基板データ](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fcherry-takuan%2Fnlp%2Ftree%2Fmaster%2Fnlp-16a%2FHardware%2FRS_232C_board)

最新バージョン : v1.2