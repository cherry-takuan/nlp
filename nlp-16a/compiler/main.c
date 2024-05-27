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
    fprintf(stderr, "Error : line[%d]\n", line_count);
    for(int line=1;line_count!=line;src++,pos--){
        if(*src=='\n'|*src=='\0'){
            line++;
        }
    }
    for(;*src!='\n' & *src!='\0';src++){
        fprintf(stderr, "%c", *src);
    }
    //fprintf(stderr, "%s\n", src);
    fprintf(stderr, "\n%*s", pos, " "); // pos個の空白を出力
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
    TK_IDENT,       // 識別子
    TK_EOF,         // 入力の終わりを表すトークン
    //二文字以上のトークン
    TK_EQ,          // == 比較関連はTexのコマンドパクったので一般的な略称ではないかも(私がやり易い)
    TK_NE,          // !=
    TK_LE,          // <=
    TK_GE,          // >=
    TK_RET,         // return
    TK_IF,          // if
    TK_ELSE,        // else
    TK_FOR,         // for
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
Token *keyword_cmp(Token* tk,int expct_kind,char*name){
    char *p = src_p;
    tk = reserved_cmp(tk,expct_kind,name);
    if (tk!=NULL & isalnum(*src_p) == 0 & *src_p != '_'){
        fprintf(stderr,"\x1b[32mmatch(%s)\x1b[39m\n","return");
        return tk;
    }else{
        fprintf(stderr,"Unmatch(%s)\n","return");
        src_p = p;
        return NULL;
    }
    return tk;
}

// 次のトークンが期待している記号のときには、トークンを1つ読み進めてトークンを返す。それ以外の場合には偽を返す。
// トークナイズと一緒にやる
Token *consume(int expct_kind) {
    Token* tk = calloc(1, sizeof(Token));
    fprintf(stderr,"now address:[%d](%c)\n",src_p,*src_p);
    while (isspace(*src_p)){
        if(*src_p=='\n'){
            line_count++;
        }
        src_p++;
    }
    if (expct_kind == TK_EOF){
        if( *src_p == '\0' ){
            fprintf(stderr,"\x1b[32mEOF\x1b[39m\n");
            tk->len = 0;
            tk->kind = expct_kind;
            tk->str = src_p;
            src_p += tk->len;
            return tk;
        }else{
            fprintf(stderr,"Unmatch(TK_EOF)%c\n",*src_p);
            return NULL;
        }
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
        }else{
            fprintf(stderr,"Unmatch(TK_NUM) [%d != %d]%c\n",expct_kind, TK_NUM,*src_p);
            src_p = tk->str;
            return NULL;
        }
    }
    if (expct_kind == TK_IDENT){
        if (isalpha(*src_p)){
            tk->str = src_p;
            while(isalnum(*src_p) | *src_p == '_'){
                src_p++;
            }
            tk->len = src_p - tk->str;
            tk->kind = expct_kind;
            fprintf(stderr,"\x1b[32mmatch(TK_IDENT)[%.*s] len:%d\x1b[39m\n",tk->len,tk->str,tk->len);
            return tk;
        }else{
            fprintf(stderr,"Unmatch(TK_IDENT)%c\n",*src_p);
            return NULL;
        }
    }
    if (expct_kind>=128){
        char *ret_src_p = src_p;
        switch (expct_kind){
            case TK_EQ:
                return reserved_cmp(tk,TK_EQ,"==");
            case TK_NE:
                return reserved_cmp(tk,TK_NE,"!=");
            case TK_LE:
                return reserved_cmp(tk,TK_LE,"<=");
            case TK_GE:
                return reserved_cmp(tk,TK_GE,">=");
            case TK_RET:
                return keyword_cmp(tk,TK_RET,"return");
            case TK_IF:
                return keyword_cmp(tk,TK_IF,"if");
            case TK_ELSE:
                return keyword_cmp(tk,TK_ELSE,"else");
            case TK_FOR:
                return keyword_cmp(tk,TK_FOR,"for");
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
    ND_ADD,     // +
    ND_SUB,     // -
    ND_MUL,     // *
    ND_DIV,     // /
    ND_NUM,     // 整数
    ND_EQ,      // ==
    ND_NE,      // !=
    // 比較演算子はCPUの仕様上
    // 小なり(つまりCMP結果がFlag_S=1，)大なりイコール(CMP結果がFlag_S=0)
    // となるためこの二つ．
    ND_LT,      // <
    ND_GE,      // >=

    ND_ASSIGN,  // =
    ND_LVAR,    // ローカル変数
    ND_RET,     // return
    ND_IF,      // if
    ND_ELSE,    // else
    ND_FOR,     // for
} NodeKind;

typedef struct Node Node;

// 抽象構文木のノードの型
struct Node {
    NodeKind kind;  // ノードの型
    Node *lhs;      // 左辺
    Node *rhs;      // 右辺
    int val;        // kindがND_NUMの場合のみ使う
    int offset;     // ローカル変数のSPオフセット

    Node *cond;     //条件expr
    Node *then;     //then節もしくはcontinue;
    Node *els;      //else節もしくはbreak;
    // for ( init; cond; update)
    Node *init;     //for文の初期化
    Node *update;   //for文の式の更新
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
// 変数関連
typedef struct LVar LVar;
struct LVar {
    LVar *next;     //次のLVar
    char *name;     //変数名
    int len;        //変数名長
    int offset;     //オフセット
};
LVar *locals;
LVar *new_lvar(Token *tok) {
    LVar *lvar= calloc(1, sizeof(LVar));
    lvar->next = locals;
    lvar->name = tok->str;
    lvar->len = tok->len;
    lvar->offset = locals->offset+1;
    locals = lvar;
    return lvar;
}
LVar *find_lvar(Token *tok){
    for (LVar *var = locals; var; var = var->next)
        if (var->len == tok->len && !memcmp(tok->str, var->name, var->len)){
            return var;
        }
    return NULL;
}
// コードはステートメントの列
Node* code[100];
//呼び出し順
void program();
Node *stmt();
Node *expr();
Node *assign();
Node *equality();
Node *relation();
Node *add();
Node *mul();
Node *unary();
Node *primary();

void program(){
    fprintf(stderr,"\x1b[36m->program()\x1b[39m");
    locals= calloc(1, sizeof(LVar));
    int i;
    for(i=0;consume(TK_EOF) == NULL;i++){
        code[i] = stmt();
    }
    code[i] = NULL;
    fprintf(stderr,"\x1b[36m->program()end\x1b[39m\n");
}
Node *stmt(){
    fprintf(stderr,"\x1b[35m->stmt()\x1b[39m");
    Node *node;
    if(consume(TK_RET)){
        fprintf(stderr,"\x1b[35m->return()\x1b[39m");
        fprintf(stderr,"\x1b[33m[return]\x1b[39m\n");
        node = new_node(ND_RET,NULL,expr());
        fprintf(stderr,"\x1b[35m->return()end\x1b[39m\n");
        expect(';');
    }else if(consume(TK_IF)){
        fprintf(stderr,"\x1b[35m->if()\x1b[39m");
        fprintf(stderr,"\x1b[33m[if]\x1b[39m\n");
        expect('(');
        node = new_node(ND_IF,NULL,NULL);
        node->cond = expr();
        expect(')');
        node->then = stmt();
        if(consume(TK_ELSE)){
            fprintf(stderr,"\x1b[33m[else]\x1b[39m\n");
            node->els = stmt();
        }
        fprintf(stderr,"\x1b[35m->if()end\x1b[39m\n");
    }else if(consume(TK_FOR)){
        fprintf(stderr,"\x1b[33m[for]\x1b[39m\n");
        expect('(');
        node = new_node(ND_FOR,NULL,NULL);
        if (!consume(';')){
            node->init = expr();
            expect(';');
        }
        if (!consume(';')){
            node->cond = expr();
            expect(';');
        }
        if (!consume(')')){
            node->update = expr();
            expect(')');
        }
        node->then = stmt();

        fprintf(stderr,"\x1b[35m->for()end\x1b[39m\n");
    }else{
        node = expr();
        expect(';');
    }
    fprintf(stderr,"\x1b[35m->stmt()end\x1b[39m\n");
    return node;
}
Node *expr() {
    fprintf(stderr,"->expr()");
    return assign();
}
Node *assign(){
    fprintf(stderr,"->assign()");
    Node *node = equality();
    if(consume('=')){
        fprintf(stderr,"\x1b[33m[=]\x1b[39m\n");
        node = new_node(ND_ASSIGN,node,assign());
    }
    fprintf(stderr,"->assign()end\n");
    return node;
}
Node *equality(){
    fprintf(stderr,"->equality()");
    Node *node = relation();
    while(1){
        if(consume(TK_EQ)){
            fprintf(stderr,"\x1b[33m[==]\x1b[39m\n");
            node = new_node(ND_EQ,node,relation());
        }else if(consume(TK_NE)){
            fprintf(stderr,"\x1b[33m[!=]\x1b[39m\n");
            node = new_node(ND_NE,node,relation());
        }else{
            fprintf(stderr,"->equality()end\n");
            return node;
        }
    }
}
Node *relation(){
    fprintf(stderr,"->relation()");
    Node *node = add();
    while(1){
        if(consume(TK_LE)){
            fprintf(stderr,"\x1b[33m[<=]\x1b[39m\n");
            node = new_node(ND_GE,add(),node);
        }else if(consume(TK_GE)){
            fprintf(stderr,"\x1b[33m[>=]\x1b[39m\n");
            node = new_node(ND_GE,node,add());
        }else if(consume('<')){
            fprintf(stderr,"\x1b[33m[<]\x1b[39m\n");
            node = new_node(ND_LT,node,add());
        }else if(consume('>')){
            fprintf(stderr,"\x1b[33m[>]\x1b[39m\n");
            node = new_node(ND_LT,add(),node);
        }else{
            fprintf(stderr,"->relation()end\n");
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
    Token *tk = consume(TK_IDENT);
    if(tk!=NULL){
        fprintf(stderr,"->local var()\n");
        Node *node = new_node(ND_LVAR,NULL,NULL);
        LVar *lvar = find_lvar(tk);
        if (lvar) {
            node->offset = lvar->offset;
        } else {
            fprintf(stderr,"local var : [%.*s] len:%d\x1b[39m\n",tk->len,tk->str,tk->len);
            lvar = new_lvar(tk);
            node->offset = lvar->offset;
        }

        fprintf(stderr,"\x1b[36mlocal var offset : [BP-%d]\x1b[39m\n",node->offset);
        fprintf(stderr,"->local var() end\n");
        return node;
    }
    fprintf(stderr,"->primary() end\n");
    Node* node = new_node_num(expect_number());
    fprintf(stderr,"\x1b[33m[%d]\x1b[39m\n",node->val);
    return node;
    
}
// B <- LVAR address
void gen_lvar(Node *node){
    if(node->kind != ND_LVAR){
        fprintf(stderr,"\x1b[31mlhs syntax error(Local var)\x1b[39m\n");
        exit(1);
    }else{
        fprintf(stdout,"\tSUB A, D, 0x%04x\n",node->offset);
        fprintf(stdout,"\tPUSH A\t;local val address\n");
    }
}
int Label_number=0;
void gen(Node *node) {
    int l_label = Label_number;
    switch (node->kind){
        case ND_NUM:
            fprintf(stderr,"Stack <- NUM:[%d]\n",node->val);
            fprintf(stdout,"\tMOV A,0x%04x\n",node->val);
            fprintf(stdout,"\tPUSH A\t;val\n");
            return;
        case ND_LVAR://スタックにローカル変数値を積む
            gen_lvar(node);
            fprintf(stderr,"Stack <- LVAR[BP-%d]\n",node->offset);
            fprintf(stdout,"\tPOP B\n");
            fprintf(stdout,"\tLOAD A, B\n");
            fprintf(stdout,"\tPUSH A\t;val\n");
            return;
        case ND_ASSIGN://ローカル変数代入
            gen_lvar(node->lhs);
            gen(node->rhs);
            fprintf(stderr,"LVAR[BP-%d] <- Stack\n",node->lhs->offset);
            fprintf(stdout,"\tPOP A\t;val\n");//右辺地
            fprintf(stdout,"\tPOP B\t;address\n");//左辺値(アドレス)
            fprintf(stdout,"\tSTORE A, B\n");
            fprintf(stdout,"\tPUSH A\n");//右辺地
            return;
        case ND_RET:
            gen(node->rhs);
            fprintf(stderr,"RET\n");
            fprintf(stdout,"\tPOP A\n");
            fprintf(stdout,"\tMOV SP, D\n");
            fprintf(stdout,"\tPOP D\n");
            fprintf(stdout,"\tRET\n");
            return;
        case ND_IF:
            fprintf(stderr,"IF\n");
            Label_number++;
            gen(node->cond);
            fprintf(stdout,"\tPOP A\n");
            fprintf(stdout,"\tMOV ZR, A\n");
            fprintf(stdout,"\tJMP.z L_ELSE_%d\n",l_label);
            gen(node->then);
            fprintf(stdout,"\tJMP L_IF_%d\n",l_label);
            fprintf(stdout,"L_ELSE_%d:\n",l_label);
            gen(node->els);
            fprintf(stdout,"L_IF_%d:\n",l_label);
            return;
        case ND_FOR:
            fprintf(stderr,"FOR\n");
            if(node->init!=NULL){
                gen(node->init);
                fprintf(stdout,"\tPOP ZR\n");
            }
            fprintf(stdout,"L_FOR_BEGIN_%d:\n",l_label);
            if(node->cond!=NULL){
                gen(node->cond);
                fprintf(stdout,"\tPOP A\n");
                fprintf(stdout,"\tMOV ZR, A\n");
                fprintf(stdout,"\tJMP.z L_FOR_END_%d\n",l_label);
            }
            gen(node->then);
            fprintf(stdout,"\tPOP ZR\n");
            gen(node->update);
            fprintf(stdout,"\tPOP ZR\n");
            fprintf(stdout,"\tJMP L_FOR_BEGIN_%d\n",l_label);
            fprintf(stdout,"L_FOR_END_%d:\n",l_label);
            return;
    }
    gen(node->lhs);
    gen(node->rhs);
    // A <- B (op) C
    fprintf(stdout,"\tPOP C\n");
    fprintf(stdout,"\tPOP B\n");
    switch(node->kind){
        case ND_ADD:
            fprintf(stderr,"ADD\n");
            fprintf(stdout,"\tADD A, B, C\n");
            break;
        case ND_SUB:
            fprintf(stderr,"SUB\n");
            fprintf(stdout,"\tSUB A, B, C\n");
            break;
        case ND_MUL:
            fprintf(stderr,"MUL\n");
            fprintf(stdout,"\tCALL MUL\n");
            break;
        case ND_DIV:
            fprintf(stderr,"DIV\n");
            fprintf(stdout,"\tCALL DIV\n");
            break;
        case ND_EQ:
            fprintf(stderr,"CMP(EQ)\n");
            fprintf(stdout,"\tMOV A,0x00\n");
            fprintf(stdout,"\tCMP B, C\n");
            fprintf(stdout,"\tMOV.z A,0x01\n");
            break;
        case ND_NE:
            fprintf(stderr,"CMP(NE)\n");
            fprintf(stdout,"\tMOV A,0x00\n");
            fprintf(stdout,"\tCMP B, C\n");
            fprintf(stdout,"\tMOV.nz A,0x01\n");
            break;
        case ND_LT:
            fprintf(stderr,"CMP(LT)\n");
            fprintf(stdout,"\tMOV A,0x00\n");
            fprintf(stdout,"\tCMP B, C\n");
            fprintf(stdout,"\tMOV.s A,0x01\n");
            break;
        case ND_GE:
            fprintf(stderr,"CMP(GE)\n");
            fprintf(stdout,"\tMOV A,0x00\n");
            fprintf(stdout,"\tCMP B, C\n");
            fprintf(stdout,"\tMOV.ns A,0x01\n");
            break;
        default:
            fprintf(stderr,"Unknown node kind\n");
    }
    fprintf(stdout,"\tPUSH A\n");
}

int main(int argc, char **argv){
    FILE *input_file = stdin;
    FILE *output_file = stdout;
    src = malloc(MAX_LINE * MAX_ONELINE);
    src_p = src;
    size_t src_len = fread(src, 1, MAX_LINE * MAX_ONELINE - 1, input_file);
    src[src_len] = '\0';
    fprintf(stderr,"%c->%c\n",*src_p,src_p[1]);//一つ先をポインタを変えずに見たい
    program();
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
    //Dをベースポインタとする．
    fprintf(stdout,"\tPUSH D\n");
    fprintf(stdout,"\tMOV D, SP\n");
    fprintf(stdout,"\tSUB SP, SP, 0x20\n");
    for(int i=0;code[i];i++){
        gen(code[i]);
    }
    fprintf(stdout,"\tPOP A\n");
    fprintf(stdout,"\tMOV SP, D\n");
    fprintf(stdout,"\tPOP D\n");
    fprintf(stdout,"\tRET\n");

    fprintf(stderr,"\x1b[32mok. \x1b[39m\n");
}