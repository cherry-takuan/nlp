#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdarg.h>
#include <string.h>

#define MAX_LINE 1000//最大行数
#define MAX_ONELINE 85//一行の文字数

FILE *input_file;
FILE *asm_output;
FILE *ast_output;
#define AST_OUT ast_output
#define ASM_OUT asm_output
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
    TK_LOGICAL_OR,  // ||
    TK_LOGICAL_AND, // &&
    TK_EQ,          // ==
    TK_NE,          // !=
    TK_LE,          // <=
    TK_GE,          // >=
    TK_RET,         // return
    TK_IF,          // if
    TK_ELSE,        // else
    TK_WHILE,       // while
    TK_INT,         // int
    TK_CHAR_DATA,   //一文字
    TK_INC,         //++
    TK_DEC,         //--
    TK_PUTS         //puts()
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
        //fprintf(stderr,"Unmatch(%s)\n",name);
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
        //fprintf(stderr,"\x1b[32mmatch return\x1b[39m\n");
        return tk;
    }else{
        //fprintf(stderr,"Unmatch return\n");
        src_p = p;
        return NULL;
    }
    return tk;
}

// 次のトークンが期待している記号のときには、トークンを1つ読み進めてトークンを返す。それ以外の場合には偽を返す。
// トークナイズと一緒にやる
Token *consume(int expct_kind) {
    Token* tk = calloc(1, sizeof(Token));
    //fprintf(stderr,"now address:[%d](%c)\n",src_p,*src_p);
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
            //fprintf(stderr,"Unmatch(TK_EOF)%c\n",*src_p);
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
            //fprintf(stderr,"Unmatch(TK_NUM) [%d != %d]%c\n",expct_kind, TK_NUM,*src_p);
            src_p = tk->str;
            return NULL;
        }
    }
    if(expct_kind == TK_CHAR_DATA){
        tk->str = src_p;
        if (isprint(*src_p)) {
            fprintf(stderr,"\x1b[32m%c\x1b[39m\n",*src_p);
            tk->len = 1;
            tk->kind = expct_kind;
            tk->str = src_p;
            tk->val = (int)*src_p;
            src_p += tk->len;
            return tk;
        }else{
            //fprintf(stderr,"Unmatch(TK_NUM) [%d != %d]%c\n",expct_kind, TK_NUM,*src_p);
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
            fprintf(stderr,"\x1b[32mmatch(TK_IDENT)\x1b[39m [%.*s] len:%d\n",tk->len,tk->str,tk->len);
            return tk;
        }else{
            //fprintf(stderr,"Unmatch(TK_IDENT)%c\n",*src_p);
            return NULL;
        }
    }
    if (expct_kind>=128){
        char *ret_src_p = src_p;
        switch (expct_kind){
            case TK_INC:
                return reserved_cmp(tk,TK_INC,"++");
            case TK_DEC:
                return reserved_cmp(tk,TK_DEC,"--");
            case TK_LOGICAL_OR:
                return reserved_cmp(tk,TK_LOGICAL_OR,"||");
            case TK_LOGICAL_AND:
                return reserved_cmp(tk,TK_LOGICAL_AND,"&&");
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
            case TK_WHILE:
                return keyword_cmp(tk,TK_WHILE,"while");
            case TK_INT:
                return keyword_cmp(tk,TK_INT,"int");
            case TK_PUTS:
                return keyword_cmp(tk,TK_PUTS,"puts");
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
        //fprintf(stderr,"Unmatch(TK_RESERVED) [%d != %d]%c\n",expct_kind, tk->kind,*src_p);
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
int expect_char() {
    Token *tok = consume(TK_CHAR_DATA);
    if (tok == NULL) {
        error_at(src_p,"Tokenize error\n");
    }
    int val = tok->val;
    return val;
}
Token *check_tk(int expct_kind){
    char *now = src_p;
    Token *tok = consume(expct_kind);
    src_p = now;
    return tok;
}

typedef enum{
    LVar_INT,
    LVar_ARRAY,
    LVar_POINTER,
} LVar_type;

// 変数関連
typedef struct LVar LVar;
struct LVar {
    LVar *next;     //次のLVar
    char *name;     //変数名
    int len;        //変数名長
    int offset;     //オフセット
    int size;
    LVar_type type; //種類
};

// ノード関連
// 抽象構文木のノードの種類
typedef enum {
    ND_ROOT,
    ND_DEF_LIST,
    ND_ADD,     // +
    ND_SUB,     // -
    ND_MUL,     // *
    ND_DIV,     // /
    ND_MOD,     // %
    ND_NUM,     // 整数
    ND_LOGICAL_OR,  // ||
    ND_LOGICAL_AND, // &&
    ND_EQ,      // ==
    ND_NE,      // !=
    // 比較演算子はCPUの仕様上
    // 小なり(つまりCMP結果がFlag_S=1，)大なりイコール(CMP結果がFlag_S=0)
    // となるためこの二つ．
    ND_LT,      // <
    ND_GE,      // >=

    ND_ASSIGN,  // =

    ND_DEF_FUNC,//関数定義
    ND_BLOCK,   //ステートメントのリスト
    ND_STMT,    //ステートメント本体
    ND_RET,     // return
    ND_LVAR,    // ローカル変数
    ND_IF,      // if
    ND_ELSE,    // else
    ND_WHILE,   // while
    ND_BREAK,   //break
    ND_CONTINUE,//continue
    
    ND_CAL_FUNC,//関数呼び出し

    ND_ARG_LIST,    //引数リスト
    ND_ARG,    //引数

    ND_ADDR,    //&
    ND_DEREF,   //*
    ND_INC,
    ND_DEC,
    ND_PUTS,
} NodeKind;

typedef struct Node Node;

// 抽象構文木のノードの型
struct Node {
    NodeKind kind;  // ノードの型
    Token *tk;
    Node *parent;
    Node *list;
    Node *cond;      // 左辺
    Node *lhs;      // 左辺
    Node *rhs;      // 右辺
    int val;        // ND_NUM : num
                    // ND_DEF_FUNC : max lvar offset

    LVar *locals;
};
Node *new_node(NodeKind kind,Node *parent, Node *(*lhs)(Node *parent), Node *(*rhs)(Node *parent),Node *nd) {
    Node *node = calloc(1, sizeof(Node));
    node->kind = kind;
    node->parent = parent;
    if(lhs != NULL){
        node->lhs = lhs(node);
    }else{
        node->lhs = nd;
    }
    if(rhs != NULL){
        node->rhs = rhs(node);
    }else{
        node->rhs = nd;
    }
    node->locals = NULL;
    return node;
}
// 数値
Node *new_node_num(Node *parent,int val) {
    Node *node = new_node(ND_NUM,parent,NULL,NULL,NULL);
    node->val = val;
    return node;
}

LVar *new_arg(Token *tok,Node *func_node,int offset){
    if(func_node->kind == ND_DEF_FUNC){
        LVar *lvar= calloc(1, sizeof(LVar));
        lvar->next = func_node->locals;
        lvar->name = tok->str;
        lvar->len = tok->len;
        lvar->offset = offset;
        func_node->locals = lvar;
        return lvar;
    }return NULL;
}
LVar *new_lvar(Token *tok,Node *parent,int size, LVar_type type) {
    for (Node *nd = parent; nd!=NULL; nd = nd->parent){
        if(nd->kind == ND_BLOCK){
            LVar *lvar= calloc(1, sizeof(LVar));
            lvar->next = nd->locals;
            lvar->name = tok->str;
            lvar->len = tok->len;
            //lvar->offset = nd->locals->offset - nd->locals->size;
            lvar->offset = nd->locals->offset - size;
            lvar->size = size;
            lvar->type = type;
            nd->locals = lvar;
            return lvar;
        }
    }
    error_at(src_p,"lvar error : failed to make a LVar\n");
}
LVar *find_lvar_block(Token *tok,Node *parent){
    Node *nd;
    for (nd = parent; nd!=NULL && nd->locals==NULL; nd = nd->parent){}
    if(nd==NULL){
        return NULL;
    }
    for (LVar *var = nd->locals; var; var = var->next){
        if (var->len == tok->len && !memcmp(tok->str, var->name, var->len)){
            return var;
        }
    }
    return NULL;
}
LVar *find_lvar(Token *tok,Node *parent){
    for (Node *nd = parent; nd!=NULL; nd = nd->parent){
        for (LVar *var = nd->locals; var; var = var->next){
            if (var->len == tok->len && !memcmp(tok->str, var->name, var->len)){
                return var;
            }
        }
    }
    return NULL;
}
int block_offset(Node* nd){
    for (LVar *var = nd->locals; var; var = var->next){
        return var->offset;
    }
}
int lvar_offset(Node *parent){
    for (Node *nd = parent; nd!=NULL; nd = nd->parent){
        if(nd->kind==ND_BLOCK){
            return block_offset(nd);
        }
    }
    return 0;
}
//呼び出し順
Node *program();
Node *def_list(Node *parent);
Node *block(Node *parent);
Node *stmt_list(Node *parent);
Node *stmt(Node *parent);
Node *expr(Node *parent);
Node *assign(Node *parent);
Node *logical_or(Node *parent);
Node *logical_and(Node *parent);
Node *equality(Node *parent);
Node *relation(Node *parent);
Node *add(Node *parent);
Node *mul(Node *parent);
Node *unary(Node *parent);
Node *postfix_expr(Node *parent);
Node *primary(Node *parent);

Node *program(){
    fprintf(stderr,"\x1b[36m->program()\x1b[39m");
    Node *prog = new_node(ND_ROOT,NULL,NULL,NULL,NULL);
    Node *cur = prog;
    while (consume(TK_EOF)==NULL){
        Node *nd = new_node(ND_DEF_LIST,prog,def_list,NULL,NULL);
        cur->list = nd;
        cur = nd;
    }
    fprintf(stderr,"\x1b[36m->program()end\x1b[39m\n");
    return prog;
}
int arg_list(Node *node){
    if(check_tk(')')){
        return 2;
    }else{
        expect(TK_INT);
        while(consume('*'));
        Token *tk = consume(TK_IDENT);
        consume(',');
        int arg_offset = arg_list(node);
        LVar *lvar = new_arg(tk,node,arg_offset);
        fprintf(stderr,"local var : [%.*s] len:%d offset:%d\n",tk->len,tk->str,tk->len,lvar->offset);
        return ++arg_offset;
    }
}
Node *def_list(Node *parent){
    Node *node;
    expect(TK_INT);
    Token *tk = expect(TK_IDENT);
    node = new_node(ND_DEF_FUNC,parent,NULL,NULL,NULL);
    node->tk = tk; //関数名とかがtk内に入る
    node->locals = calloc(1, sizeof(LVar));//ローカル変数生成
    expect('(');
    arg_list(node);
    expect(')');
    node->lhs = block(node);
    return node;
}
Node *block(Node *parent){
    Node *node = new_node(ND_BLOCK,parent,NULL,NULL,NULL);
    node->locals= calloc(1, sizeof(LVar));//ローカル変数生成
    node->locals->offset = lvar_offset(parent);
    node->locals->size = 1;
    expect('{');

    Node *cur = node;
    while (consume('}')==NULL)
    {
        Node *nd = new_node(ND_STMT,node,stmt,NULL,NULL);
        cur->list = nd;
        cur = nd;
    }
    int offset = block_offset(node);
    if(node->val > offset){
        node->val = offset;
    }
    for (Node *nd = node; nd!=NULL; nd = nd->parent){
        if(nd->kind == ND_BLOCK && nd->val > offset){
            nd->val = offset;
        }
    }
    return node;
}
void decl_list(Node *parent){
    fprintf(stderr,"\x1b[35m->decl_list()\x1b[39m");
    while(consume(TK_INT) != NULL){
        LVar_type type=LVar_INT;
        while(consume('*')){type = LVar_POINTER;};
        Token *tk = consume(TK_IDENT);
        LVar *lvar = find_lvar_block(tk,parent);
        if (lvar!=NULL){
            error_at(src_p," error: redeclaration of '%.*s'",tk->len,tk->str);
        }
        int size = 1;
        while(consume('[')){
            size *= expect_number();
            expect(']');
            type = LVar_ARRAY;
        }
        expect(';'); 
        lvar = new_lvar(tk,parent,size,type);
        fprintf(stderr,"local var : [%.*s] len:%d offset:%d\n",tk->len,tk->str,tk->len,lvar->offset);
    }
    fprintf(stderr,"\x1b[35m->decl_list()end\x1b[39m\n");
    return;
}
Node *stmt(Node *parent){
    Node *node;
    fprintf(stderr,"\x1b[35m->stmt()\x1b[39m");
    decl_list(parent);
    if(consume(TK_RET)){
        fprintf(stderr,"\x1b[35m->return()\x1b[39m");
        fprintf(stderr,"\x1b[33m[return]\x1b[39m\n");
        if(consume(';')){// リターンのみ
            node = new_node(ND_RET,parent,NULL,NULL,NULL);
        }else{// 値を返す
            node = new_node(ND_RET,parent,expr,NULL,NULL);
            expect(';');
        }
        fprintf(stderr,"\x1b[35m->return()end\x1b[39m\n");
    }else if(consume(TK_IF)){
        fprintf(stderr,"\x1b[35m->if()\x1b[39m");
        fprintf(stderr,"\x1b[33m[if]\x1b[39m\n");
        node = new_node(ND_IF,parent,NULL,NULL,NULL);
        expect('(');
        node->cond = expr(node);
        expect(')');
        node->lhs = stmt(node);
        if(consume(TK_ELSE)){
            fprintf(stderr,"\x1b[33m[else]\x1b[39m\n");
            node->rhs = stmt(node);
        }
        fprintf(stderr,"\x1b[35m->if()end\x1b[39m\n");
    }else if(consume(TK_WHILE)){
        fprintf(stderr,"\x1b[35m->while()\x1b[39m");
        fprintf(stderr,"\x1b[33m[wehike]\x1b[39m\n");
        node = new_node(ND_WHILE,parent,NULL,NULL,NULL);
        expect('(');
        node->cond = expr(node);
        expect(')');
        node->lhs = stmt(node);
        fprintf(stderr,"\x1b[35m->while()end\x1b[39m\n");
    }else if(check_tk('{')){
        node = block(parent);
    }else{
        node = expr(parent);
        expect(';');
    }
    fprintf(stderr,"\x1b[35m->stmt()end\x1b[39m\n");
    return node;
}
Node *expr(Node *parent) {
    fprintf(stderr,"->expr()");
    return assign(parent);
}
Node *assign(Node *parent){
    fprintf(stderr,"->assign()");
    Node *node = logical_or(parent);
    if(consume('=')){
        fprintf(stderr,"\x1b[33m[=]\x1b[39m\n");
        node = new_node(ND_ASSIGN,parent,NULL,assign,node);
    }
    fprintf(stderr,"->assign()end\n");
    return node;
}

Node *logical_or(Node *parent){
    fprintf(stderr,"->equality()");
    Node *node = logical_and(parent);
    while(1){
        if(consume(TK_LOGICAL_OR)){
            fprintf(stderr,"\x1b[33m[==]\x1b[39m\n");
            node = new_node(ND_LOGICAL_OR,parent,NULL,logical_and,node);
        }else{
            fprintf(stderr,"->equality()end\n");
            return node;
        }
    }
}

Node *logical_and(Node *parent){
    fprintf(stderr,"->equality()");
    Node *node = equality(parent);
    while(1){
        if(consume(TK_LOGICAL_AND)){
            fprintf(stderr,"\x1b[33m[==]\x1b[39m\n");
            node = new_node(ND_LOGICAL_AND,parent,NULL,equality,node);
        }else{
            fprintf(stderr,"->equality()end\n");
            return node;
        }
    }
}

Node *equality(Node *parent){
    fprintf(stderr,"->equality()");
    Node *node = relation(parent);
    while(1){
        if(consume(TK_EQ)){
            fprintf(stderr,"\x1b[33m[==]\x1b[39m\n");
            node = new_node(ND_EQ,parent,NULL,relation,node);
        }else if(consume(TK_NE)){
            fprintf(stderr,"\x1b[33m[!=]\x1b[39m\n");
            node = new_node(ND_NE,parent,NULL,relation,node);
        }else{
            fprintf(stderr,"->equality()end\n");
            return node;
        }
    }
}
Node *relation(Node *parent){
    fprintf(stderr,"->relation()");
    Node *node = add(parent);
    while(1){
        if(consume(TK_LE)){
            fprintf(stderr,"\x1b[33m[<=]\x1b[39m\n");
            node = new_node(ND_GE,parent,add,NULL,node);
        }else if(consume(TK_GE)){
            fprintf(stderr,"\x1b[33m[>=]\x1b[39m\n");
            node = new_node(ND_GE,parent,NULL,add,node);
        }else if(consume('<')){
            fprintf(stderr,"\x1b[33m[<]\x1b[39m\n");
            node = new_node(ND_LT,parent,NULL,add,node);
        }else if(consume('>')){
            fprintf(stderr,"\x1b[33m[>]\x1b[39m\n");
            node = new_node(ND_LT,parent,add,NULL,node);
        }else{
            fprintf(stderr,"->relation()end\n");
            return node;
        }
    }
}
Node *add(Node *parent){
    fprintf(stderr,"->add()");
    Node *node = mul(parent);
    while(1){
        if(consume('+')){
            node = new_node(ND_ADD,parent,NULL,mul,node);
            fprintf(stderr,"\x1b[33m[+]\x1b[39m\n");
        }
        else if(consume('-')){//SubはAddの仲間
            node = new_node(ND_SUB,parent,NULL,mul,node);
            fprintf(stderr,"\x1b[33m[-]\x1b[39m\n");
        }else{
            fprintf(stderr,"->add()end\n");
            return node;
        }
    }
}
Node *mul(Node *parent) {
    fprintf(stderr,"->mul()");
    Node *node = unary(parent);
    while(1){
        if(consume('*')){
            node = new_node(ND_MUL,parent,NULL,unary,node);
            fprintf(stderr,"\x1b[33m[*]\x1b[39m\n");
        }else if(consume('/')){
            node = new_node(ND_DIV,parent,NULL,unary,node);
            fprintf(stderr,"\x1b[33m[/]\x1b[39m\n");
        }else if(consume('%')){
            node = new_node(ND_MOD,parent,NULL,unary,node);
            fprintf(stderr,"\x1b[33m[/]\x1b[39m\n");
        }else{
            fprintf(stderr,"->mul()end\n");
            return node;
        }
    }
}

Node *unary(Node *parent){// 単項プラス/マイナス
    if(consume(TK_INC)){
        Node *node = primary(parent);
        Node *add = new_node(ND_ADD,parent,NULL,NULL,NULL);
        add->lhs = node;
        add->rhs = new_node_num(parent,1);
        node = new_node(ND_ASSIGN,parent,NULL,NULL,node);
        node->rhs = add;
        return node;
    }else if(consume(TK_DEC)){
        Node *node = primary(parent);
        Node *sub = new_node(ND_SUB,parent,NULL,NULL,NULL);
        sub->lhs = node;
        sub->rhs = new_node_num(parent,1);
        node = new_node(ND_ASSIGN,parent,NULL,NULL,node);
        node->rhs = sub;
        return node;
    }else if(consume('+')){// +を消費したい
        return primary(parent);
    }else if(consume('-')){
        fprintf(stderr,"\x1b[33m[0-]\x1b[39m\n");
        // つまり単項マイナス演算子の左辺値？を0にして0-数値として実現する．貧弱CPUには少しうーむといった所．
        //return new_node(ND_SUB,new_node_num(0),primary());
        return new_node(ND_SUB,parent,NULL,primary,new_node_num(parent,0));
    }else if(consume('*')){
        fprintf(stderr,"\x1b[33m[*]\x1b[39m\n");
        return new_node(ND_DEREF,parent,unary,NULL,NULL);
    }else if(consume('&')){
        fprintf(stderr,"\x1b[33m[&]\x1b[39m\n");
        return new_node(ND_ADDR,parent,unary,NULL,NULL);
    }
    return postfix_expr(parent);
}

Node *arg_exprs(Node *parent){
    Node *head = new_node(ND_ARG_LIST,parent,NULL,NULL,NULL);
    expect('(');
    Node *cur = head;
    int arg_num = 0;
    while (consume(')')==NULL)
    {
        Node *nd = new_node(ND_ARG,head,expr,NULL,NULL);
        cur->list = nd;
        cur = nd;
        consume(',');
        arg_num++;
    }
    head->val = arg_num;
    return head;
}
Node *postfix_expr(Node *parent){
    Node *node = primary(parent);
    if(consume('[')){
        fprintf(stderr,"->Bracket [ [ ]");
        node = new_node(ND_ADD,parent,NULL,expr,node);
        node = new_node(ND_DEREF,parent,NULL,NULL,node);
        expect(']');
        fprintf(stderr,"->Bracket end\n");
    }
    fprintf(stderr,"->equality()end\n");
    return node;
}

Node *primary(Node *parent) {
    Node *node;
    fprintf(stderr,"->primary()");
    if(consume('(')){
        fprintf(stderr,"->Bracket [(]");
        node = expr(parent);
        expect(')');
        fprintf(stderr,"->Bracket end\n");
        return node;
    }
    if(consume(TK_PUTS)){
        return new_node(ND_PUTS,parent,expr,NULL,NULL);
    }
    Token *tk = consume(TK_IDENT);
    if(tk!=NULL){// IDENTを使うのは関数と変数
        if(check_tk('(')){//関数
            fprintf(stderr,"->func call\n");
            Node *node = new_node(ND_CAL_FUNC,parent,NULL,NULL,NULL);
            node->tk = tk;
            // 引数リスト
            check_tk('(');
            node->lhs = arg_exprs(node);
            return node;
        }else{//変数
            fprintf(stderr,"->local var\n");
            Node *node = new_node(ND_LVAR,parent,NULL,NULL,NULL);
            LVar *lvar = find_lvar(tk,parent);
            if (lvar==NULL){
                // エラー処理追加
                /*
                fprintf(stderr,"local var : [%.*s] len:%d\x1b[39m\n",tk->len,tk->str,tk->len);
                lvar = new_lvar(tk,parent);
                fprintf(stderr,"ok\n");
                */
               error_at(src_p,"lvar error : undefined ident\n");
            }
            node->locals = lvar;
            fprintf(stderr,"->local var() end\n");
            return node;
        }
    }
    if(consume('\'')){
        node = new_node_num(parent,expect_char());
        fprintf(stderr,"\x1b[33mchar [%c]\x1b[39m\n",node->val);
        expect('\'');
        return node;
    }
    fprintf(stderr,"->primary() end\n");
    node = new_node_num(parent,expect_number());
    fprintf(stderr,"\x1b[33m[%d]\x1b[39m\n",node->val);
    return node;
    
}

void gen(Node *node);

void gen_lvar_list(Node *node){
    LVar *locals = node->locals;
    fprintf(AST_OUT,"\t\"%d_LVar\" [label=\"{ <top> LVar ",node);
    while (locals->next != NULL){
        fprintf(AST_OUT,"| %.*s BP+( %d )",locals->len,locals->name,locals->offset);
        locals = locals->next;
    }
    fprintf(AST_OUT,"}\" shape=record margin=\"0.2,0\"];\n");
    fprintf(AST_OUT,"\t%d -> \"%d_LVar\"\n",node,node);
    fprintf(AST_OUT,"\t{ rank=same; %d \"%d_LVar\"};\n",node,node);
}
// B <- LVAR address
void gen_lvar_addr(Node *node){
    switch(node->kind){
        case ND_LVAR:
            if(node->locals->offset>0){
                fprintf(ASM_OUT,"\tADD A, D, 0x%04x\n",node->locals->offset);
            }else if(node->locals->offset==0){
                fprintf(ASM_OUT,"\x1b[31m code gen err : lvar offset is zero\x1b[39m\n");
                exit(1);
            }else{
                fprintf(ASM_OUT,"\tSUB A, D, 0x%04x\n",-node->locals->offset);
            }
            fprintf(AST_OUT,"\t%d [label=\"%.*s  BP+( %d )\",shape = note,margin=\"0.2,0\"];\n",node,node->locals->len,node->locals->name,node->locals->offset);
            return;
        case ND_DEREF:
            fprintf(AST_OUT,"\t%d [label=\"DEREF(Addr)\"];\n",node);
            gen(node->lhs);
            fprintf(ASM_OUT,"\tPOP A\n");
            fprintf(AST_OUT,"\t%d -> %d\n",node,node->lhs);
            return;
        default:
            fprintf(ASM_OUT,"\x1b[31mlhs syntax error(Local var)\x1b[39m\n");
            exit(1);
    }
}

int Label_number=0;
void gen(Node *node) {
    int l_num = Label_number;
    if(node == NULL){
        fprintf(AST_OUT,"\t%d [label=\"NULL\",shape=plaintext];\n",node);
        return;
    }
    if(node->parent!=NULL){
        // Lvar search path
        // fprintf(AST_OUT,"\t%d -> %d [style=dashed,weight = 0.2tailport = nw]\n",node,node->parent);
    }
    switch (node->kind){
        case ND_ROOT:
            fprintf(AST_OUT,"\t%d [label=\"ROOT\"];\n",node);
            fprintf(AST_OUT,"\t%d -> %d\n",node,node->list);
            gen(node->list);
            return;
        case ND_DEF_LIST:
            while(node != NULL){
                fprintf(AST_OUT,"\t%d [label=\"DEF LIST\",shape=octagon];\n",node);
                if(node->lhs != NULL){
                    fprintf(AST_OUT,"\t%d -> %d\n",node,node->lhs);
                }
                if(node->list!=NULL){
                    fprintf(AST_OUT,"\t%d -> %d\n [tailport = e,headport = w,weight=0.2];",node,node->list);
                    fprintf(AST_OUT,"\t{ rank=same; %d %d};\n",node,node->list);
                }
                gen(node->lhs);
                node = node->list;
            }
            return;
        case ND_BLOCK:
            fprintf(AST_OUT,"\t%d [label=\"BLOCK\nframe size:%d\",shape = box3d,margin=\"0.4,0.2\"];\n",node,-node->val);
            fprintf(AST_OUT,"\t%d -> %d\n",node,node->list);
            gen(node->list);
            gen_lvar_list(node);
            return;
        case ND_STMT:
            while(node != NULL){
                fprintf(AST_OUT,"\t%d [label=\"STMT\",shape=octagon];\n",node);
                if(node->lhs != NULL){
                    fprintf(AST_OUT,"\t%d -> %d;\n",node,node->lhs);
                    gen(node->lhs);
                    if(node->lhs->kind != ND_BLOCK&&
                       node->lhs->kind != ND_IF &&
                       node->lhs->kind != ND_WHILE &&
                       node->lhs->kind != ND_RET){
                        fprintf(ASM_OUT,"\tPOP ZR\n\n\n");
                    }
                }
                if(node->list!=NULL){
                    fprintf(AST_OUT,"\t%d -> %d[tailport = e,headport = w,weight=0.2];\n",node,node->list);
                    fprintf(AST_OUT,"\t{ rank=same; %d %d};\n",node,node->list);
                }
                node = node->list;
            }
            return;
        case ND_NUM:
            fprintf(AST_OUT,"\t%d [label=%d];\n",node,node->val);

            fprintf(ASM_OUT,"\t;Stack <- NUM:[%d]\n",node->val);
            fprintf(ASM_OUT,"\tMOV A,0x%04x\n",node->val);
            fprintf(ASM_OUT,"\tPUSH A\t;val\n");
            return;
        case ND_LVAR://スタックにローカル変数値を積む
            //fprintf(AST_OUT,"\t%d [label=\"%.*s  BP+( %d )\",shape = note,margin=\"0.2,0\"];\n",node,node->locals->len,node->locals->name,node->locals->offset);
            gen_lvar_addr(node);
            if(node->locals->type != LVar_ARRAY){
                fprintf(ASM_OUT,"\tLOAD A, A\n");
            }
            fprintf(ASM_OUT,"\tPUSH A\n");
            return;
        case ND_ASSIGN://ローカル変数代入
            fprintf(AST_OUT,"\t%d [label=\"ASSIGN\"];\n",node);
            gen_lvar_addr(node->lhs);
            fprintf(ASM_OUT,"\tPUSH A\n");
            gen(node->rhs);
            fprintf(AST_OUT,"\t%d -> %d [label = dest,tailport = sw]\n",node,node->lhs);
            fprintf(AST_OUT,"\t%d -> %d [label = src,tailport = se]\n",node,node->rhs);
            
            fprintf(ASM_OUT,"\tPOP A\t;val\n");//右辺地
            fprintf(ASM_OUT,"\tPOP B\t;address\n");//左辺値(アドレス)
            fprintf(ASM_OUT,"\tSTORE A, B\n");
            fprintf(ASM_OUT,"\tPUSH A\n\n");//右辺地
            return;
        case ND_IF:
            Label_number++;
            fprintf(AST_OUT,"\t%d [label=\"IF label : %d\"];\n",node,l_num);
            fprintf(ASM_OUT,"IF_L_%d:\n",l_num);
            gen(node->cond);
            fprintf(ASM_OUT,"\tPOP A\n");
            fprintf(ASM_OUT,"\tMOV ZR, A\n");
            fprintf(ASM_OUT,"\tJMP.z IP+@IF_L_%d_ELSE\n",l_num);
            fprintf(AST_OUT,"\t%d -> %d [label = cond,tailport = sw]\n",node,node->cond);
            fprintf(ASM_OUT,"IF_L_%d_THEN:\n",l_num);
            gen(node->lhs);
            fprintf(ASM_OUT,"\tJMP IP+@IF_L_%d_END\n",l_num);
            fprintf(AST_OUT,"\t%d -> %d [label = then,tailport = s]\n",node,node->lhs);
            fprintf(ASM_OUT,"IF_L_%d_ELSE:\n",l_num);
            gen(node->rhs);
            fprintf(ASM_OUT,"IF_L_%d_END:\n",l_num);
            fprintf(AST_OUT,"\t%d -> %d [label = else,tailport = se]\n",node,node->rhs);
            return;
        case ND_WHILE:
            Label_number++;
            fprintf(AST_OUT,"\t%d [label=\"WHILE label : %d\"];\n",node,l_num);
            
            fprintf(ASM_OUT,"WHILE_L_%d:\n",l_num);

            gen(node->cond);

            fprintf(ASM_OUT,"\tPOP A\n");
            fprintf(ASM_OUT,"\tMOV ZR, A\n");
            fprintf(ASM_OUT,"\tJMP.z IP+@WHILE_L_%d_END\n",l_num);

            fprintf(AST_OUT,"\t%d -> %d [label = cond,tailport = sw]\n",node,node->cond);
            gen(node->lhs);
            fprintf(AST_OUT,"\t%d -> %d [label = then,tailport = se]\n",node,node->lhs);
            fprintf(ASM_OUT,"\tJMP IP+@WHILE_L_%d\n",l_num);
            fprintf(ASM_OUT,"WHILE_L_%d_END:\n",l_num);
            return;
        case ND_DEF_FUNC:
            fprintf(AST_OUT,"\t%d [label= \"%.*s\nframe size:%d\",shape = box3d,margin=\"0.4,0.2\"];\n",node,node->tk->len,node->tk->str,-node->lhs->val);
            gen_lvar_list(node);            
            fprintf(stderr,"FUNC [%.*s]\n",node->tk->len,node->tk->str);

            fprintf(ASM_OUT,"%.*s:\n",node->tk->len,node->tk->str);
            //Dをベースポインタとする．
            fprintf(ASM_OUT,"\tPUSH D\n");
            fprintf(ASM_OUT,"\tMOV D, SP\n");
            fprintf(ASM_OUT,"\tSUB SP, SP, 0x%04x\n\n",-(node->lhs->val));
            gen(node->lhs);
            //終了処理
            fprintf(ASM_OUT,"\t; return(default)\n");
            fprintf(ASM_OUT,"\tMOV SP, D\n");
            fprintf(ASM_OUT,"\tPOP D\n");
            fprintf(ASM_OUT,"\tRET\n\n");
            
            fprintf(AST_OUT,"\t%d -> %d [tailport = s]\n",node,node->lhs);
            return;
        case ND_CAL_FUNC:
            fprintf(AST_OUT,"\t%d [label=\"Func : %.*s\",shape = note,margin=\"0.2,0\"];\n",node,node->tk->len,node->tk->str);
            fprintf(ASM_OUT,"\t; func call\n");
            gen(node->lhs);
            fprintf(ASM_OUT,"\tCALL IP+@%.*s\n",node->tk->len,node->tk->str);
            for(int i = node->lhs->val;i != 0;i--){
                fprintf(ASM_OUT,"\tPOP ZR ;arg pop\n");
            }
            fprintf(ASM_OUT,"\tPUSH A\n");
            fprintf(AST_OUT,"\t%d -> %d [tailport = s]\n",node,node->lhs);
            return;
        case ND_ARG_LIST:
            fprintf(AST_OUT,"\t%d [label=\"Param LIST\",shape=octagon];\n",node);
            gen(node->list);
            fprintf(AST_OUT,"\t%d -> %d [tailport = s]\n",node,node->list);
            return;
        case ND_ARG:
            while(node != NULL){
                fprintf(AST_OUT,"\t%d [label=\"Param\",shape=octagon];\n",node);
                if(node->lhs != NULL){
                    fprintf(AST_OUT,"\t%d -> %d[label=\"expr\"];\n",node,node->lhs);
                }
                if(node->list!=NULL){
                    fprintf(AST_OUT,"\t%d -> %d\n",node,node->list);
                    fprintf(AST_OUT,"\t{ rank=same; %d %d};\n",node,node->list);
                }
                gen(node->lhs);//arg expr
                node = node->list;
            }
            return;
        case ND_RET:
            fprintf(ASM_OUT,"\t; return\n");
            fprintf(AST_OUT,"\t%d [label=\"RET\"];\n",node);
            if(node->lhs != NULL){
                gen(node->lhs);
                fprintf(AST_OUT,"\t%d -> %d\n",node,node->lhs);
                fprintf(ASM_OUT,"\tPOP A\n");
            }
            fprintf(ASM_OUT,"\tMOV SP, D\n");
            fprintf(ASM_OUT,"\tPOP D\n");
            fprintf(ASM_OUT,"\tRET\n\n");
            return;
        case ND_DEREF:
            fprintf(AST_OUT,"\t%d [label=\"DEREF\"];\n",node);
            gen(node->lhs);
            fprintf(ASM_OUT,"\tPOP A\n");
            fprintf(ASM_OUT,"\tLOAD A, A\n");
            fprintf(ASM_OUT,"\tPUSH A\n");
            fprintf(AST_OUT,"\t%d -> %d\n",node,node->lhs);
            return;
        case ND_ADDR:
            gen_lvar_addr(node->lhs);
            fprintf(ASM_OUT,"\tPUSH A\n");
            
            fprintf(AST_OUT,"\t%d [label=\"ADDR\"];\n",node);
            fprintf(AST_OUT,"\t%d -> %d\n",node,node->lhs);
            return;
        case ND_PUTS:
            gen(node->lhs);
            fprintf(ASM_OUT,"\tPOP A\n");
            fprintf(ASM_OUT,"\tCALL IP+@OUTCHAR\n");
            fprintf(ASM_OUT,"\tPUSH A\n");
            
            fprintf(AST_OUT,"\t%d [label=\"PUTS\"];\n",node);
            fprintf(AST_OUT,"\t%d -> %d\n",node,node->lhs);
            return;
    }
    gen(node->lhs);
    gen(node->rhs);
    fprintf(AST_OUT,"\t%d -> %d [label = lhs,tailport = sw]\n",node,node->lhs);
    fprintf(AST_OUT,"\t%d -> %d [label = rhs,tailport = se]\n",node,node->rhs);

    fprintf(ASM_OUT,"\tPOP C\n");
    fprintf(ASM_OUT,"\tPOP B\n");
    switch(node->kind){
        case ND_ADD:
            fprintf(AST_OUT,"\t%d [label=\"ADD\"];\n",node);
            fprintf(ASM_OUT,"\tADD A, B, C\n");
            break;
        case ND_SUB:
            fprintf(AST_OUT,"\t%d [label=\"SUB\"];\n",node);
            fprintf(ASM_OUT,"\tSUB A, B, C\n");
            break;
        case ND_MUL:
            fprintf(AST_OUT,"\t%d [label=\"MUL\"];\n",node);
            fprintf(ASM_OUT,"\tCALL IP+@MUL\n");
            break;
        case ND_DIV:
            fprintf(AST_OUT,"\t%d [label=\"DIV\"];\n",node);
            fprintf(ASM_OUT,"\tCALL IP+@DIV\n");
            break;
        case ND_MOD:
            fprintf(AST_OUT,"\t%d [label=\"MOD\"];\n",node);
            fprintf(ASM_OUT,"\tCALL IP+@DIV\n");
            fprintf(ASM_OUT,"\tMOV A, B\n");
            break;
        case ND_LOGICAL_OR:
            fprintf(AST_OUT,"\t%d [label=\"||\"];\n",node);
            fprintf(ASM_OUT,"\tOR A, B, C\n");
            break;
        case ND_LOGICAL_AND:
            fprintf(AST_OUT,"\t%d [label=\"&&\"];\n",node);
            fprintf(ASM_OUT,"\tAND A, B, C\n");
            break;
        case ND_EQ:
            fprintf(AST_OUT,"\t%d [label=\"==\"];\n",node);
            fprintf(ASM_OUT,"\tMOV A,0x00\n");
            fprintf(ASM_OUT,"\tCMP B, C\n");
            fprintf(ASM_OUT,"\tMOV.z A,0x01\n");
            break;
        case ND_NE:
            fprintf(AST_OUT,"\t%d [label=\"!=\"];\n",node);
            fprintf(ASM_OUT,"\tMOV A,0x00\n");
            fprintf(ASM_OUT,"\tCMP B, C\n");
            fprintf(ASM_OUT,"\tMOV.nz A,0x01\n");
            break;
        case ND_LT:
            fprintf(AST_OUT,"\t%d [label=\"<\"];\n",node);
            fprintf(ASM_OUT,"\tMOV A,0x00\n");
            fprintf(ASM_OUT,"\tCMP B, C\n");
            fprintf(ASM_OUT,"\tMOV.s A,0x01\n");
            break;
        case ND_GE:
            fprintf(AST_OUT,"\t%d [label=\">=\"];\n",node);
            fprintf(ASM_OUT,"\tMOV A,0x00\n");
            fprintf(ASM_OUT,"\tCMP B, C\n");
            fprintf(ASM_OUT,"\tMOV.ns A,0x01\n");
            break;
        default:
            fprintf(stderr,"//Unknown node kind\n");
    }
    fprintf(ASM_OUT,"\tPUSH A\n");
}

int main(int argc, char **argv){
    input_file = stdin;
    asm_output = stdout;
    ast_output = NULL;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--ast") == 0) {
          ast_output = stdout;
          asm_output = NULL;
        }
    }
    src = malloc(MAX_LINE * MAX_ONELINE);
    src_p = src;
    size_t src_len = fread(src, 1, MAX_LINE * MAX_ONELINE - 1, input_file);
    src[src_len] = '\0';
    Node *root = program();
    fprintf(AST_OUT,"digraph G {\n\trankdir=TB;\n\tgraph [fontname=\"MyricaM M\"];\n\tnode  [fontname=\"MyricaM M\"];\n\tedge  [fontname=\"MyricaM M\"];\n");
    
    // ビルドイン関数
    FILE * buildin_file = NULL;
    buildin_file = fopen( "buildin.asm", "r");
    if(buildin_file == NULL){
        fprintf(stderr,"open error");
    }
    char c;
	while ((c = fgetc(buildin_file)) != EOF){
		fprintf(ASM_OUT,"%c", c);
	}
	fclose(buildin_file);

    gen(root);
    
    fprintf(AST_OUT,"}");

    fprintf(stderr,"\x1b[32mok. \x1b[39m\n");
}
