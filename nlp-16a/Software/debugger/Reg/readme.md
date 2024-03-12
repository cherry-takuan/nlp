# ALUテスト，データバステスト
ALU，データバス，TMP Reg，Acc，I/Oの総合的なテストを実施します．これらのモジュールでのテストを実施することで，事前に基本的な内部の動作の欠陥を洗い出すことができます．

テスト対象のモジュールは以下の通りです．
- [ALU](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/alu_c)
- [ALU Ctrl](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/alu_ctrl)
- [Y BUS Ctrl](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/Y_BUS_Ctrl)
- [A BUS Ctrl](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/A_BUS_Ctrl)
- [Acc](https://github.com/cherry-takuan/nlp/tree/master/nlp-16a/Hardware/Accumulator)

## ハードウェア構成

 ハードウェアは以下のような構成になっています．検証対象のモジュールは実際のプロセッサの構成とほぼ同じように接続し，各種制御装置は命令デコーダではなくPCから操作されるデバッガに接続されます．

 また，データの入出力はバスターミネータ基板の外部I/Oバスにデバッガを接続し任意の値を転送します．
![テストハード構成](テストハード構成.png)  

# 実行内容
アキュムレータとI/Oポート間での演算を行い，結果を制御用PCに転送しすることでデータバス，および演算装置で正常に値の転送，演算ができているかの検証を行います．

検証はpythonからmain.pyを実行することで自動で行われます．(pyserialが必要)

# 実行内容(詳細)

1. デバッガ0～3の入出力を設定

1. A BUS制御でバスターミネータ(ID:11)を選択
1. Y BUS制御でゼロレジスタ(ID:15)を選択
1. ALU制御を転送命令に設定
1. デバッガ4を出力モードに設定の後テストデータを出力
1. Y BUS制御にphi1，phi2それぞれパルスを送りAccに転送
1. ALU Ctrlにテスト命令を出力
1. Y BUS制御にphi1パルスを送りTMP Regに転送
1. デバッガ4を入力モードに設定
1. A BUS制御でゼロレジスタ(ID:15)を選択
1. Y BUS制御でバスターミネータ(ID:11)を選択
1. デバッガ4のデータを読み取り -> ALUの演算出力

1. A BUS制御でバスターミネータ(ID:11)を選択
1. Y BUS制御でゼロレジスタ(ID:15)を選択
1. ALU制御を転送命令に設定
1. デバッガ4を出力モードに設定の後テストデータを出力
1. Y BUS制御にphi1，phi2それぞれパルスを送りAccに転送
1. ALU Ctrlにテスト命令を出力．出力をFlagモードに設定
1. Y BUS制御にphi1パルスを送りTMP Regに転送
1. デバッガ4を入力モードに設定
1. A BUS制御でゼロレジスタ(ID:15)を選択
1. Y BUS制御でバスターミネータ(ID:11)を選択
1. デバッガ4のデータを読み取り -> ALUのFlag出力

1. PCで想定される結果と比較

1. 2～24をすべての命令，値のパターンで実行する．

## 検証結果

第一回目の検証ではすべてのテストをパスしたため，モジュールの動作およびモジュール間の整合性に問題が無いことが確認できた．