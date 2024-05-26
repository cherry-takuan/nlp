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
    TK_NUM=128,      // 整数トークン
    TK_EOF,      // 入力の終わりを表すトークン
} TokenKind;

typedef struct Token Token;
// トークン型
struct Token {
    TokenKind kind; // トークンの型
    int val;        // kindがTK_NUMの場合、その数値
    char *str;      // トークン文字列
    int len;
};

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
    //一文字演算子
    if (strchr("+-*/()", *src_p)){
        fprintf(stderr,"TK_RESERVED[%c]\n",*src_p);
        tk->kind = *src_p;
        tk->str = src_p;
        tk->len = 1;
        if(expct_kind == tk->kind){
            fprintf(stderr,"\x1b[32mmatch(TK_RESERVED)\x1b[39m [%c]\n",expct_kind);
            src_p++;
            return tk;
        }else{
            fprintf(stderr,"Unmatch(TK_RESERVED) [%d != %d]%c\n",expct_kind, tk->kind,*src_p);
            return NULL;
        }
    }
    if (isdigit(*src_p)) {
        tk->str = src_p;
        int x = strtol(src_p, &src_p, 10);
        tk->kind = TK_NUM;
        tk->len = src_p - tk->str;
        tk->val = x;
        fprintf(stderr,"TK_NUM[%d] len:%d\n",x,tk->len);
        if(expct_kind == TK_NUM){
            fprintf(stderr,"\x1b[32mmatch(TK_NUM)\x1b[39m [%d]\n",tk->val);
            return tk;
        }else{
            fprintf(stderr,"Unmatch(TK_NUM) [%d != %d]%c\n",expct_kind, TK_NUM,*src_p);
            src_p = tk->str;
            return NULL;
        }
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
Node *mul();
Node *primary();

Node *expr() {
    fprintf(stderr,"->expr()");
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
            fprintf(stderr,"->expr()end\n");
            return node;
        }
    }
}
Node *mul() {
    fprintf(stderr,"->mul()");
    Node *node = primary();
    while(1){
        if(consume('*')){
            node = new_node(ND_MUL,node,primary());
            fprintf(stderr,"\x1b[33m[*]\x1b[39m\n");
        }else if(consume('/')){
            node = new_node(ND_DIV,node,primary());
            fprintf(stderr,"\x1b[33m[/]\x1b[39m\n");
        }else{
            fprintf(stderr,"->mul()end\n");
            return node;
        }
    }
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
        fprintf(stdout,"\tMOV A,0x%04x\n",node->val);
        fprintf(stdout,"\tPUSH A\n");
        return;
    }
    gen(node->lhs);
    gen(node->rhs);
    switch(node->kind){
        case ND_ADD:
            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tADD A, B, C\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
        case ND_SUB:
            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tSUB A, B, C\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
        case ND_MUL:
            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tCALL MUL\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
        case ND_DIV:
            fprintf(stdout,"\tPOP C\n");
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tCALL DIV\n");
            fprintf(stdout,"\tPUSH A\n");
            break;
    }
}

int main(int argc, char **argv){
    FILE *input_file = stdin;
    FILE *output_file = stdout;
    src = malloc(MAX_LINE * MAX_ONELINE);
    src_p = src;
    size_t src_len = fread(src, 1, MAX_LINE * MAX_ONELINE - 1, input_file);
    src[src_len] = '\0';
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