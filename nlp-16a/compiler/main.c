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

void error_at(char *loc, char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    int pos = loc - src;
    fprintf(stderr, "%s\n", src);
    fprintf(stderr, "%*s", pos, " "); // pos個の空白を出力
    fprintf(stderr, "^ ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    exit(1);
}

// トークン関連
// トークンの種類
typedef enum {
  TK_RESERVED, // 記号
  TK_NUM,      // 整数トークン
  TK_EOF,      // 入力の終わりを表すトークン
} TokenKind;

typedef struct Token Token;

// トークン型
struct Token {
  TokenKind kind; // トークンの型
  Token *next;    // 次の入力トークン
  int val;        // kindがTK_NUMの場合、その数値
  char *str;      // トークン文字列
  int len;
};

Token *token;

// 新しいトークンを作成してcurに繋げる
Token *new_token(TokenKind kind, Token *cur, char *str) {
    Token *tok = calloc(1, sizeof(Token));
    tok->kind = kind;
    tok->str = str;
    cur->next = tok;
    return tok;
}

// 次のトークンが期待している記号のときには、トークンを1つ読み進めて
// 真を返す。それ以外の場合には偽を返す。
bool consume(char op) {
  if (token->kind != TK_RESERVED || token->str[0] != op)
    return false;
  token = token->next;
  return true;
}

// 次のトークンが期待している記号のときには、トークンを1つ読み進める。
// それ以外の場合にはエラーを報告する。
void expect(char op) {
  if (token->kind != TK_RESERVED || token->str[0] != op)
    //error("'%c'ではありません", op);
    error_at(token->str, "is not [%c]",op);
  token = token->next;
}

// 次のトークンが数値の場合、トークンを1つ読み進めてその数値を返す。
// それ以外の場合にはエラーを報告する。
int expect_number() {
    if (token->kind != TK_NUM)
        //error("数ではありません");
        //fprintf(stderr,"is not number");
        error_at(token->str, "is not number");
    int val = token->val;
    fprintf(stderr,"Num : [%d]",val);
    token = token->next;
    return val;
}

bool at_eof() {
  return token->kind == TK_EOF;
}

// 入力文字列srcをトークナイズしてそれを返す
Token *tokenize() {
    char* p = src;
    Token head;
    head.next = NULL;
    Token *cur = &head;
    fprintf(stderr,"tokenize\n");
    while(*p) {
        if (isspace(*p)){
            p++;
            continue;
        }
        if (strchr("+-*/()", *p)){
            cur = new_token(TK_RESERVED, cur, p);
            fprintf(stderr,"TK_RESERVED[%c]\n",*p);
            p++;
            continue;
        }
        if (isdigit(*p)) {
            cur = new_token(TK_NUM, cur, p);
            int x = 0;
            x = strtol(p, &p, 10);
            cur->val = x;
            fprintf(stderr,"TK_NUM[%d]\n",x);
            continue;
        }
        error_at(p,"Tokenize error\n");
    }

    new_token(TK_EOF, cur, NULL);
    return head.next;
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
  Node *node = calloc(1, sizeof(Node));
  node->kind = ND_NUM;
  node->val = val;
  return node;
}

Node *expr();
Node *mul();
Node *primary();

Node *expr(){
    fprintf(stderr,"->expr()");
    Node *node = mul();
    while(1){
        if(consume('+')){
            node = new_node(ND_ADD,node,mul());
            fprintf(stderr,"[+]");
        }
        else if(consume('-')){//SubはAddの仲間
            node = new_node(ND_SUB,node,mul());
            fprintf(stderr,"[-]");
        }else{
            fprintf(stderr,"->expr()end\n");
            return node;
        }
    }
}
Node *mul(){
    fprintf(stderr,"->mul()");
    Node *node = primary();
    while(1){
        if(consume('*')){
            node = new_node(ND_MUL,node,primary());
            fprintf(stderr,"[*]");
        }else if(consume('/')){
            node = new_node(ND_DIV,node,primary());
            fprintf(stderr,"[/]");
        }else{
            fprintf(stderr,"->mul()end\n");
            return node;
        }
    }
}
Node *primary(){
    fprintf(stderr,"->primary()");
    if(consume('(')){
        fprintf(stderr,"->Bracket [(]");
        Node *node = expr();
        expect(')');
        fprintf(stderr,"->Bracket end\n");
        return node;
    }
    fprintf(stderr,"->primary() end\n");
    return new_node_num(expect_number());
    
}

void gen(){
}

int main(int argc, char **argv){
    FILE *input_file = stdin;
    FILE *output_file = stdout;
    src = malloc(MAX_LINE * MAX_ONELINE);
    size_t src_len = fread(src, 1, MAX_LINE * MAX_ONELINE - 1, input_file);
    src[src_len] = '\0';
    token = tokenize();
    Token *print_tkn = token;
    while(1){
        if(print_tkn->kind==TK_EOF)break;
        if(print_tkn->kind==TK_RESERVED)fprintf(stderr,"kind:TK_RESERVED,str:%c\n",*print_tkn->str);
        if(print_tkn->kind==TK_NUM)fprintf(stderr,"kind:TK_NUM,val:%d\n",print_tkn->val);
        print_tkn = print_tkn->next;
    }
    Node *node = expr();
}