# NLP-16Aコンパイラ nlpcc  

開発中のNLP-16A向けのコンパイラです．最初はcherry c compilerの略でCCCにしようと思いましたがなんかアレなのでnlp c compilerからnlpccとしました．

機械語はコンパイル結果をnlpasmフォルダ内にあるアセンブラを通して生成します．
`make test`では実機が必要になります．

このコンパイラは主に以下のプロジェクトを参考にして作っています．  

- [低レイヤを知りたい人のためのCコンパイラ作成入門](https://www.sigbus.info/compilerbook)
- [comproc](https://github.com/uchan-nos/comproc/tree/main)