#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdarg.h>
#include <string.h>

#define MAX_LINE 1000//最大行数
#define MAX_ONELINE 85//一行の文字数
char* src;//コードを格納
char* src_p;
int line_count = 1;

void error_at(char *loc, char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    int pos = loc - src;
    fprintf(stderr, "\x1b[31m");
    fprintf(stderr, "Error:line:%d\n", line_count);
    fprintf(stderr, "%s\n", src);
    fprintf(stderr, "%*s", pos, " "); // pos個の空白を出力
    fprintf(stderr, "^ ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\x1b[39m\n");
    exit(1);
}

// トークン関連
// トークンの種類
typedef enum {
    //0-127は一文字トークン(+や*等)で使用．文字コードそのまま．
    // 実装済み
    // + - * / ( ) < >

    TK_NUM=128,     // 整数トークン
    TK_EOF,         // 入力の終わりを表すトークン
    //二文字以上のトークン
    TK_EQ,          // == 比較関連はTexのコマンドパクったので一般的な略称ではないかも(私がやり易い)
    TK_NE,          // !=
    TK_LE,          // <=
    TK_GE,          // >=
} TokenKind;

typedef struct Token Token;
// トークン型
struct Token {
    TokenKind kind; // トークンの型
    int val;        // kindがTK_NUMの場合、その数値
    char *str;      // トークン文字列
    int len;
};

Token *reserved_cmp(Token* tk,int expct_kind,char*name){
    if( memcmp(src_p,name,strlen(name)) != 0 ){
        fprintf(stderr,"Unmatch(%s)\n",name);
        return NULL;
    }else{
        fprintf(stderr,"\x1b[32mmatch(%s)\x1b[39m\n",name);
        tk->len = strlen(name);
        tk->kind = expct_kind;
        tk->str = src_p;
        src_p += tk->len;
        return tk;
    }
}

// 次のトークンが期待している記号のときには、トークンを1つ読み進めてトークンを返す。それ以外の場合には偽を返す。
// トークナイズと一緒にやる
Token *consume(int expct_kind) {
    Token* tk = calloc(1, sizeof(Token));
    while (isspace(*src_p)){
        if(*src_p=='\n'){
            line_count++;
        }
        src_p++;
    }
    if(expct_kind == TK_NUM){
        tk->str = src_p;
        if (isdigit(*src_p)) {
            int x = strtol(src_p, &src_p, 10);
            tk->kind = TK_NUM;
            tk->len = src_p - tk->str;
            tk->val = x;
            fprintf(stderr,"TK_NUM[%d] len:%d\n",x,tk->len);
            fprintf(stderr,"\x1b[32mmatch(TK_NUM)\x1b[39m [%d]\n",tk->val);
            return tk;
        }
        fprintf(stderr,"Unmatch(TK_NUM) [%d != %d]%c\n",expct_kind, TK_NUM,*src_p);
        src_p = tk->str;
        return NULL;
    }
    // 二文字以上のトークンを優先
    if (expct_kind>=128){
        fprintf(stderr,"TK >= 128\n");
        switch (expct_kind){
            case TK_EQ:
                return reserved_cmp(tk,TK_EQ,"==");
            case TK_NE:
                return reserved_cmp(tk,TK_NE,"!=");
            case TK_LE:
                return reserved_cmp(tk,TK_LE,"<=");
            case TK_GE:
                return reserved_cmp(tk,TK_GE,">=");
            default:
                error_at(src_p,"Unknown token(expct_kind)\n");
        }
    }
    if (expct_kind == *src_p){
        fprintf(stderr,"\x1b[32mmatch(TK_RESERVED)\x1b[39m [%c]\n",expct_kind);
        tk->kind = expct_kind;
        tk->str = src_p;
        tk->len = 1;
        src_p++;
        return tk;
    }else{
        fprintf(stderr,"Unmatch(TK_RESERVED) [%d != %d]%c\n",expct_kind, tk->kind,*src_p);
        return NULL;
    }
    error_at(src_p,"Tokenize error\n");
    return NULL;
}
Token *expect(int expct_kind) {
    Token *tok = consume(expct_kind);
    if (tok == NULL) {
        error_at(src_p,"Tokenize error\n");
    }
    return tok;
}
int expect_number() {
    fprintf(stderr,"TK_NUM [%d]\n",TK_NUM);
    Token *tok = consume(TK_NUM);
    if (tok == NULL) {
        error_at(src_p,"Tokenize error\n");
    }
    int val = tok->val;
    return val;
}

// ノード関連
// 抽象構文木のノードの種類
typedef enum {
    ND_ADD, // +
    ND_SUB, // -
    ND_MUL, // *
    ND_DIV, // /
    ND_NUM, // 整数
    ND_EQ,  // ==
    ND_NE,
    ND_LE,
    ND_GE,
} NodeKind;

typedef struct Node Node;

// 抽象構文木のノードの型
struct Node {
    NodeKind kind; // ノードの型
    Node *lhs;     // 左辺
    Node *rhs;     // 右辺
    int val;       // kindがND_NUMの場合のみ使う
};
// 二項演算子
Node *new_node(NodeKind kind, Node *lhs, Node *rhs) {
    Node *node = calloc(1, sizeof(Node));
    node->kind = kind;
    node->lhs = lhs;
    node->rhs = rhs;
    return node;
}
// 数値
Node *new_node_num(int val) {
    Node *node = new_node(ND_NUM,NULL,NULL);
    node->val = val;
    return node;
}

Node *expr();
Node *equality();
Node *add();
Node *mul();
Node *unary();
Node *primary();

Node *expr() {
    fprintf(stderr,"->expr()");
    return equality();
}
Node *equality(){
    fprintf(stderr,"->equality()");
    Node *node = add();
    while(1){
        if(consume(TK_EQ)){
            fprintf(stderr,"\x1b[33m[==]\x1b[39m\n");
            node = new_node(ND_EQ,node,add());
        }else if(consume(TK_NE)){
            fprintf(stderr,"\x1b[33m[!=]\x1b[39m\n");
            node = new_node(ND_NE,node,add());
        }else{
            fprintf(stderr,"->equality()end\n");
            return node;
        }
    }
}
Node *add(){
    fprintf(stderr,"->add()");
    Node *node = mul();
    while(1){
        if(consume('+')){
            node = new_node(ND_ADD,node,mul());
            fprintf(stderr,"\x1b[33m[+]\x1b[39m\n");
        }
        else if(consume('-')){//SubはAddの仲間
            node = new_node(ND_SUB,node,mul());
            fprintf(stderr,"\x1b[33m[-]\x1b[39m\n");
        }else{
            fprintf(stderr,"->add()end\n");
            return node;
        }
    }
}
Node *mul() {
    fprintf(stderr,"->mul()");
    Node *node = unary();
    while(1){
        if(consume('*')){
            node = new_node(ND_MUL,node,unary());
            fprintf(stderr,"\x1b[33m[*]\x1b[39m\n");
        }else if(consume('/')){
            node = new_node(ND_DIV,node,unary());
            fprintf(stderr,"\x1b[33m[/]\x1b[39m\n");
        }else{
            fprintf(stderr,"->mul()end\n");
            return node;
        }
    }
}

Node *unary(){// 単項プラス/マイナス
    if(consume('+')){// +を消費したい
        return primary();
    }else if(consume('-')){
        fprintf(stderr,"\x1b[33m[0-]\x1b[39m\n");
        // つまり単項マイナス演算子の左辺値？を0にして0-数値として実現する．貧弱CPUには少しうーむといった所．
        return new_node(ND_SUB,new_node_num(0),primary());
    }
    return primary();
}

Node *primary() {
    fprintf(stderr,"->primary()");
    if(consume('(')){
        fprintf(stderr,"->Bracket [(]");
        Node *node = expr();
        expect(')');
        fprintf(stderr,"->Bracket end\n");
        return node;
    }
    fprintf(stderr,"->primary() end\n");
    Node* node = new_node_num(expect_number());
    fprintf(stderr,"\x1b[33m[%d]\x1b[39m\n",node->val);
    return node;
    
}

void gen(Node *node) {
    if(node->kind == ND_NUM){
        fprintf(stderr,"NUM:[%d]\n",node->val);
        fprintf(stdout,"\tMOV A,0x%04x\n",node->val);
        fprintf(stdout,"\tPUSH A\n");
        return;
    }
    gen(node->lhs);
    gen(node->rhs);
    switch(node->kind){
        case ND_ADD:
            fprintf(stderr,"ADD\n");

            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tADD A, B, C\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
        case ND_SUB:
            fprintf(stderr,"SUB\n");

            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tSUB A, B, C\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
        case ND_MUL:
            fprintf(stderr,"MUL\n");

            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tCALL MUL\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
        case ND_DIV:
            fprintf(stderr,"DIV\n");

            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tCALL DIV\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
        case ND_EQ:
            fprintf(stderr,"CMP(EQ)\n");
        case ND_NE:
            fprintf(stderr,"CMP(NE)\n");
    }
}

int main(int argc, char **argv){
    FILE *input_file = stdin;
    FILE *output_file = stdout;
    src = malloc(MAX_LINE * MAX_ONELINE);
    src_p = src;
    size_t src_len = fread(src, 1, MAX_LINE * MAX_ONELINE - 1, input_file);
    src[src_len] = '\0';
    fprintf(stderr,"%c->%c\n",*src_p,*(src_p+1));//一つ先をポインタを変えずに見たい
    Node *node = expr();
    // ビルドイン関数
    FILE * buildin_file = NULL;
    buildin_file = fopen( "buildin.asm", "r");
    if(buildin_file == NULL){
        fprintf(stderr,"open error");
    }
    char c;
	while ((c = fgetc(buildin_file)) != EOF){
		fprintf(stdout,"%c", c);
	}
	fclose(buildin_file);

    gen(node);
    fprintf(stdout,";debug out\n\tPOP A\n\tCALL OUTEEE\nEND:\n\tJMP IP+@END");
}