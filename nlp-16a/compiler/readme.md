# NLP-16Aコンパイラ nlpcc  

開発中のNLP-16A向けのコンパイラです．最初はcherry c compilerの略でCCCにしようと思いましたがなんかアレなのでnlp c compilerからnlpccとしました．

機械語はコンパイル結果をnlpasmフォルダ内にあるアセンブラを通して生成します．

このコンパイラは主に以下のプロジェクトを参考にして作っています．  

- [低レイヤを知りたい人のためのCコンパイラ作成入門](https://www.sigbus.info/compilerbook)
- [comproc](https://github.com/uchan-nos/comproc/tree/main)

`make test`を実行するとエミュレータを通してテストが実行され，テスト結果が[report.txt](report.txt)に出力されます。