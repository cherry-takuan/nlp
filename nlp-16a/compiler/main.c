#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define DEBUG
int scan_int() {
  int x = 0;
  scanf("%d", &x);
  return x;
}

int scan_char() {
  char c = '\0';
  while (scanf("%c", &c) == 1) {
    if (!isspace(c)) {
      break;
    }
  }
  return c;
}
int consume_char(int c) {
  int scanned = scan_char();
  if (scanned == c) {
    return c;
  }
  ungetc(scanned, stdin);
  return 0;
}

void Additive();
void Multiplicative();
void Primary();

void Additive(){
#ifdef DEBUG
    printf("->Additive()");
#endif
    Multiplicative();
    if(consume_char('+')){
        Additive();
        printf("+");
#ifdef DEBUG
        printf("ADD\n");
#endif
    }
    else if(consume_char('-')){//SubはAddの仲間
        Additive();
        printf("-");
#ifdef DEBUG
    printf("SUB\n");
#endif
    }
}
void Multiplicative(){
#ifdef DEBUG
    printf("->Multiplicative()");
#endif
    Primary();
    if(consume_char('*')){
        Multiplicative();
        printf("*");
#ifdef DEBUG
        printf("MUL\n");
#endif
    }
}
void Primary(){
#ifdef DEBUG
    printf("->Primary()");
#endif
    if(consume_char('(')){
#ifdef DEBUG
        printf("->Bracket [(]");
#endif
        Additive();
    }
    if(consume_char(')')){
        printf("->Bracket [)]");
        return;
    }
#ifdef DEBUG
        printf("num, %d\n", scan_int());
#endif
#ifndef DEBUG
        printf("%d,", scan_int());
#endif
    
}

int main(int argc, char **argv){
    Additive();
}

