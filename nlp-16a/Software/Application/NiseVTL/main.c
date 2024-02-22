#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define BUF_SIZE 200
#define END_OF_P BUF_SIZE-1
char buf[BUF_SIZE];
char input_buf[BUF_SIZE];
int top_end_p;
int bottom_start_p;

#define STACK_SIZE 100
int stack[STACK_SIZE] = {};
int sp=0;
#define VAR(n) n-48
int variable[30] = {};

#define ARRAY_SIZE 256
int array[ARRAY_SIZE];

char char_get(int now_p);
int p_get(int now_p);
void cursol_update(int new_cursol);
void insert(char data);
void view_raw_data();
int print_line(int line_num);
int line_head(int line_num);
void text_insert(int line_num);
int line_count();
void line_del(int line_num);
void text_change(int line_num);
int VTL_RUN();
int POP();
void PUSH(int data);
int stack_top();
void stack_print();

int main(void){
    top_end_p =  0;
    bottom_start_p = BUF_SIZE;
    cursol_update(0);
    for(int now_p = 0; now_p<BUF_SIZE;now_p++){buf[now_p]='\0';}
    int cursol_line = 1;
    for(cursol_line = 1;print_line(cursol_line);cursol_line++){}
    while(1){
        printf("editor c-mode>");
        fgets(input_buf, sizeof(input_buf), stdin);
        input_buf[strlen(input_buf) - 1] = '\0';
        fflush(stdin);
        int input_num[2] = {};
        int now_input_num = 0;
        int sign_flag=0;
        switch (input_buf[0])
        {
        case 'q':exit(0);//終了
        case 'a':text_insert(cursol_line);break;//挿入
        case 'c':text_change(cursol_line);break;//変更
        case 'n':printf("now cursol:%d\n",cursol_line);break;//現在のカーソル位置
        case 'p':for(cursol_line = 1;print_line(cursol_line);cursol_line++){}break;//全行表示
        case 'd':line_del(cursol_line);break;//削除
        case 'r':VTL_RUN();break;//インタプリタ実行
        case 'D':view_raw_data();break;//ギャップバッファデバッグ用
        default:
        /***
         * カーソル移動関連．.は現在のカーソル，$は最終行．
         * 数値,数値で指定範囲の表示．
         * カーソルや指定範囲には．や$に+-で指定も可能．
        */
            for(int count = 0;count < BUF_SIZE;count++){
                if(isdigit(input_buf[count])){
                    int num = 0;
                    for(;count < BUF_SIZE && isdigit(input_buf[count]);count++){
                        num *= 10;
                        num += input_buf[count]-48;
                    }
                    if(sign_flag==0)input_num[now_input_num] += num;
                    else input_num[now_input_num] -= num;
                    sign_flag = 0;
                    count--;
                }else if(input_buf[count] == '+'){
                }else if(input_buf[count] == '-'){
                    sign_flag=1;
                }else if(input_buf[count] == '.'){
                    input_num[now_input_num] = cursol_line;
                }else if(input_buf[count] == '$'){
                    input_num[now_input_num] = line_count();
                }else if(input_buf[count] == ','){
                    now_input_num++;
                }else if(input_buf[count]=='\0'){
                    if(input_num[1]>input_num[0]){
                        for(int cn=input_num[0];cn<=input_num[1];cn++){
                            print_line(cn);
                            cursol_line = input_num[1];
                        }
                    }else{
                        cursol_line = input_num[0];
                        print_line(cursol_line);
                    }
                    break;
                }
            }
        }
    }
    return 0;
}
/****************
 * スタックはアドレス計算のタイミングをハードの仕様に合わせてある．
 * ただスタックが伸びる方向が逆になっているので0番地が使われない謎仕様．
 * 問題はないのでおｋ
 ************* **/
int POP(){
    int wk = stack[sp];
    if(sp <= 0){
        printf("Error : stack pop[%d]",sp);
        exit(1);
    }
    sp--;
    return wk;
}
void PUSH(int data){
    if(sp >= STACK_SIZE){
        printf("Error : stack push[%d]",sp);
        exit(1);
    }
    ++sp;
    stack[sp]=data;
}
int stack_top(){
    return stack[sp];
}
int VTL_RUN(){
    int line = 0;
    int to_jump = 0;
    sp = 0;
    for(int count = 0;count < BUF_SIZE;count++){
        if(char_get(count)=='\0' || char_get(count)==EOF)return 0;//末尾で終了
        if(isdigit(char_get(count))){//数値を読み取り
            int num=0;
            for(;char_get(count) != EOF && isdigit(char_get(count));count++){
                num *= 10;
                num += char_get(count)-48;
            }
            PUSH(num);//入力された数値をスタックへ積む
            count--;
        }else{
            //各種計算関連
            if(char_get(count) == '+'){
                int wk1 = POP();//全てでこのようにPOPを並べているが，アセンブリにするときに都合が良いのでこのまま．
                int wk2 = POP();
                PUSH(wk1+wk2);
            }else if(char_get(count) == '-'){
                int wk1 = POP();
                int wk2 = POP();
                PUSH(wk1-wk2);
            }else if(char_get(count) == '/'){
                int wk1 = POP();
                int wk2 = POP();
                PUSH(wk2/wk1);
            }else if(char_get(count) == '*'){
                int wk1 = POP();
                int wk2 = POP();
                PUSH(wk1*wk2);
            }else if(char_get(count) == '%'){
                int wk1 = POP();
                int wk2 = POP();
                PUSH(wk2%wk1);
            }else if(char_get(count) == '$'){
                PUSH(getchar());
            }else if(char_get(count) == '?'){
                int tmp;
                scanf("%d",&tmp);
                getchar();
                PUSH(tmp);
            }else if(char_get(count) == '>'){
                int wk1 = POP();
                int wk2 = POP();
                PUSH(wk2>wk1);
            }else if(char_get(count) == '<'){
                int wk1 = POP();
                int wk2 = POP();
                PUSH(wk2<wk1);
            }else if(char_get(count) == '='){
                count++;
                if(char_get(count) == '='){//==で比較演算子
                    int wk1 = POP();
                    int wk2 = POP();
                    PUSH(wk2==wk1);//基本的に比較も含めて結果はすべてスタックに積む．
                }else{//=の次が=でなければ代入演算子
                    char operand = char_get(count);
                    int wk1 = POP();
                    if(operand=='?'){//数値として表示
                        printf("%d",wk1);
                    }else if(operand=='$'){//文字として表示
                        printf("%c",wk1);
                    }else if(operand=='#'){//プログラムカウンタに代入(かなり投げやりな実装)
                        if(wk1==0)continue;
                        to_jump = wk1;
                        count=0;
                    }else if(operand==':'){
                        if(0 <= wk1 && wk1 <= ARRAY_SIZE)array[wk1] = POP();
                        else{
                            printf("out of range [%c] line:[%d]\n",wk1,line);
                        }
                    }else{
                        if('A' <= operand && operand <= 'Z')variable[VAR(operand)] = wk1;
                        else{
                            printf("unknow variable [%c] line:[%d]\n",operand,line);
                        }
                    }
                }
            }else if(char_get(count) == '\n'){
                line = 0;
            }else if(char_get(count) == '\''){//文字リテラル表示
                count++;
                for(;char_get(count) != EOF && char_get(count)!='\'' && char_get(count)!='\n';count++){
                    if(char_get(count)=='\\'){
                        count++;
                        switch (char_get(count))
                        {
                            case 'n':printf("\n");break;
                            case 't':printf("\t");break;
                            case 'a':printf("\a");break;
                        }
                    }else printf("%c",char_get(count));
                }
            }else if(char_get(count) == ':'){//配列をスタックに．最上位のスタックをアドレスとして処理．
                int address = POP();
                if(0 <= address && address <= ARRAY_SIZE)PUSH(array[address]);
                else{
                    printf("out of range [%c] line:[%d]\n",address,line);
                }
            }else if(char_get(count) == ' '){//行の数値を取得
                line = POP();
                if(to_jump!=0){//0でなければジャンプ中
                    if(line!=to_jump){//一致しなければ行末まで読み飛ばす
                        for(;char_get(count) != EOF && char_get(count)!='\n';count++){}
                        count--;
                    }else{//一致していればジャンプ中を解除してそのまま読み進める
                        to_jump=0;
                    }
                }
            }else if(isalpha(char_get(count)) && char_get(count) < 'a'){//それ以外でA-Zの1文字なら変数
                PUSH(variable[VAR(char_get(count))]);
            }
        }
    }
}



void text_insert(int line_num){//line_num行に挿入
    int cursol = line_head(line_num);
    cursol_update(cursol);
    while(1){
        printf("editor a-mode>");
        fgets(input_buf, sizeof(input_buf), stdin);
        input_buf[strlen(input_buf) - 1] = '\0';
        fflush(stdin);
        if(strlen(input_buf) == 1 && input_buf[0] == '.') break;
        for(int count = 0;count<strlen(input_buf);insert(input_buf[count++])){}
        insert('\n');
    }
}
void text_change(int line_num){//line_num行を上書き
    line_del(line_num);
    text_insert(line_num);
}
void line_del(int line_num){//line_num行を削除
    if(line_head(line_num+1) < 0) return;
    int cursol = line_head(line_num+1);
    cursol_update(cursol);
    top_end_p = p_get(line_head(line_num));
}
int edit_p(int cursol){//文字数から配列内のアドレスに変換
    if(cursol <= top_end_p){
        return cursol;
    }else{
        return cursol-top_end_p + bottom_start_p;
    }
}
void cursol_update(int new_cursol){//カーソルを移動する．ついでにギャップを移動
    if(new_cursol >= BUF_SIZE){
        printf("Error : out of buf area[%d]",new_cursol);
        view_raw_data();
        exit(1);
    }
    if(new_cursol < top_end_p){
        for(;edit_p(new_cursol)<top_end_p;){
            --top_end_p,--bottom_start_p;
            buf[bottom_start_p] = buf[top_end_p];
        }
    }else{
        for(;edit_p(new_cursol)>bottom_start_p;){
            buf[top_end_p] = buf[bottom_start_p];
            ++top_end_p,++bottom_start_p;
        }
    }
    return;
}
char char_get(int now_p){//now_p文字目の文字を返す
    int p;
    if(now_p < top_end_p){
            p = now_p;
    }
    else{
        p = now_p + bottom_start_p - top_end_p;
    }
    if(p >= BUF_SIZE) return EOF;
    return buf[p];
}
int p_get(int now_p){//now_p文字目の配列内のアドレスを返す
    int p;
    if(now_p < top_end_p){
            p = now_p;
    }
    else{
        p = now_p + bottom_start_p - top_end_p;
    }
    if(p >= BUF_SIZE) return EOF;
    return p;
}
void insert(char data){//一文字挿入する
    if(top_end_p >= bottom_start_p){
        printf("Error : buf full");
        view_raw_data();
        exit(1);
    }
    buf[top_end_p]=data;
    top_end_p++;
}
void view_raw_data(){//ギャップバッファデバッグ用出力
    printf("\n\ntop:%d,bottom:%d\n",top_end_p,bottom_start_p);
    printf("|");
    for(int i=0; i<BUF_SIZE;i++){
        if(i == top_end_p) printf("T");
        else if(i == bottom_start_p) printf("B");
        else printf(" ");
    }
    printf("|\n|");
    for(int i=0; i<BUF_SIZE;i++){
        if(isprint(buf[i])) printf("%c",buf[i]);
        else printf(" ");
    }
    printf("|\n");
}
int print_line(int line_num){//line_num行を表示
    int line = 1;
    for(int now_p = 0; now_p<BUF_SIZE;now_p++){
        if(char_get(now_p)== EOF){printf("[EOF]\n");break;}
        if(char_get(now_p)=='\0') break;
        if(char_get(now_p)=='\n'){
            if(line==line_num){
                printf("\n");
                return 1;
            }
            line++;
            continue;
        }
        if(line==line_num) printf("%c",char_get(now_p));
    }
    return 0;
}
int line_head(int line_num){////line_num行の先頭の位置を返す(配列のアドレスではなく何文字目か)
    if(line_num==1)return 0;
    int line = 1;
    for(int now_p = 0; now_p<BUF_SIZE;now_p++){
        if(char_get(now_p)== EOF) break;
        if(char_get(now_p)=='\0') break;
        if(char_get(now_p)=='\n'){
            line++;
            if(line==line_num){
                return now_p+1;
            }
        }
    }
    return -1;
}
int line_count(){//何行あるか(投げやり)
    int line = 1;
    for(int now_p = 0; now_p<BUF_SIZE;now_p++){
        if(char_get(now_p)== EOF) break;
        if(char_get(now_p)=='\0') break;
        if(char_get(now_p)=='\n'){
            line++;
        }
    }
    return line;
}