CC = gcc

# コンパイルオプションを指定します
CFLAGS = -g

# オブジェクトファイルを指定します
OBJS = main.o

# デフォルトターゲットを指定します
.PHONY: all
all: nlpcc

# 実行ファイルnlpccを生成するルール
nlpcc: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# オブジェクトファイルmain.oを生成するルール
main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

# テストターゲット
.PHONY: test
test: nlpcc
	./test.sh

# クリーンアップルール
.PHONY: clean
clean:
	rm -f $(OBJS) nlpcc