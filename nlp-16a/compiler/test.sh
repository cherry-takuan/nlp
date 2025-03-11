#!/bin/bash
echo > report.txt
#echo "debugger port select"
#uart_dev_debug=$(./nlpdebug/UART_sel.py)
#if [ $? -ne 0 ] ; then
#    echo 'open error'
#    exit 1
#fi
#echo "test port select"
#uart_dev_test=$(./nlpdebug/UART_sel.py)
#if [ $? -ne 0 ] ; then
#    echo 'open error'
#    exit 1
#fi

#echo "debugger:$uart_dev_debug"
#echo "test dev:$uart_dev_test"

make

function test_value() {
  want="$1"
  input="$2"
  nlpcc_output=$(echo $input | ./nlpcc.exe)
  if [ $? -ne 0 ] ; then
    echo 'nlpcc error'
    echo "[FAILED]: $input -> '$result', want '$want' nlpcc error" >> report.txt
    return
  fi
#  result="$(echo $input | ./nlpcc | nlpasm/ASCII.py | nlpasm/nlpasm.py | nlpdebug/test.py $uart_dev_debug $uart_dev_test)"
  result="$(echo $input | ./nlpcc.exe | python nlpasm/ASCII.py | python nlpasm/nlpasm.py | python nlpemu/nlp16a.py )"
  if [ $? -ne 0 ] ; then
    echo 'execution error'
    echo $?
    echo $result
    exit 1
  fi

  if [ $((0x$want)) = $((0x$result)) ]
  then
    echo "[  OK  ]: $input -> '$result'"
    echo "[  OK  ]: $input -> '$result'" >> report.txt
  else
    echo "[FAILED]: $input -> '$result', want '$want'"
    echo "[FAILED]: $input -> '$result', want '$want'" >> report.txt
  fi
}
test_value 3 "int main() {int a;a=0;++a;++a;++a;return a;}"
test_value 9 "int main() {int a[3];a[2] = 6;a[0] = a[1] = 4;a[ a[2] - a[0] ] = 5;return a[2]+a[0];}"
test_value 45 "int array_test(){int test[10];int i;i = 0;while(i < 10){*(test+i) = i;i = i+1;}i = 0;int acc;acc = 0;while(i < 10){acc = acc + *(test+i);i = i+1;}return acc;}int main() {return array_test();}"
test_value 3 "int main() {int a[2];*a = 1;*(a+1) = 2;int *p;p = a;return *p + *(p+1);}"
test_value 233 "int fib(int n){if(n == 1 || n == 2){return 1;}return fib(n-1) + fib(n-2);}int main() {int **test_pt_pt;{int test;int *test_pt;test_pt_pt = &test_pt;test_pt = &test;test = 13;}return fib(**test_pt_pt);}"
test_value 20 "int main(){return test();}int test(){return 4*(2+3);}"
test_value 04 "int main(){int a;a = 2*( (20-(6+2))/6 );return a;}"
test_value 02 "int main(){int a;int b;int c;a = 10;b = a/2;c = b-3;return c;}"
test_value 05 "int main(){if (2)if (0) return 3;else return 5;else return 7;}"
test_value 06 "int main(){int test_1; int test_2; test_1=2;test_2=3;return test_1*test_2;}"
test_value 07 "int main(){return 7;}"
test_value 20 "int main(){int a;int b;int c;a=4;b=2;c=3;return a*(b+c);}"
test_value 06 "int main(){int b;int a;a=2;b=3;return a*b;}"

test_value 0 "int main(){return 2*( (20-(6+2))/6 ) == 4*(2+3);}"

test_value 1 "int main(){return 10>=5;}"
test_value 1 "int main(){return 10>=10;}"
test_value 0 "int main(){return 5>=10;}"

test_value 0 "int main(){return 10<=5;}"
test_value 1 "int main(){return 10<=10;}"
test_value 1 "int main(){return 5<=10;}"

test_value 0 "int main(){return 5>10;}"
test_value 1 "int main(){return 10>5;}"

test_value 1 "int main(){return 5<10;}"
test_value 0 "int main(){return 10<5;}"

test_value 0 "int main(){return 10!=10;}"
test_value 1 "int main(){return 10!=5;}"

test_value 1 "int main(){return 10==10;}"
test_value 0 "int main(){return 10==5;}"

test_value 05 "int main(){return +5;}"
test_value 03 "int main(){return -2+5;}"
test_value 04 "int main(){return 2*( (20-(6+2))/6 );}"
test_value 05 "int main(){return 10/2;}"
test_value 20 "int main(){return 4*(2+3);}"
test_value 06 "int main(){return 2*3;}"
test_value 05 "int main(){return 10  - (2+3);}"
test_value 09 "int main(){return 10+(2-3);}"
test_value 10 "int main(){return 10;}"

# 過去のテスト
# 関数を導入して文法に合わなくなったので。
#test_value 13 "{a=0;b=1;c=0;for(i=0;i<=5;i=i+1){c = a+b;a = b;b = c;}return c;}"
#test_value 02 "{a = 10;b = a/2;c = b-3;}return c;"
#test_value 55 "a=0;for(i=0;i<=10;i=i+1)a=a+i;return a;"
#test_value 05 "if (2)if (0) return 3;else return 5;else return 7;"
#test_value 06 "test_1=2;test_2=3;return test_1*test_2;"
#test_value 07 "return 7;"
#test_value 20 "a=4;b=2;c=3;a*(b+c);"
#test_value 06 "a=2;b=3;a*b;"

#test_value 0 "2*( (20-(6+2))/6 ) == 4*(2+3);"

#test_value 1 "10>=5;"
#test_value 1 "10>=10;"
#test_value 0 "5>=10;"

#test_value 0 "10<=5;"
#test_value 1 "10<=10;"
#test_value 1 "5<=10;"

#test_value 0 "5>10;"
#test_value 1 "10>5;"

#test_value 1 "5<10;"
#test_value 0 "10<5;"

#test_value 0 "10!=10;"
#test_value 1 "10!=5;"

#test_value 1 "10==10;"
#test_value 0 "10==5;"

#test_value 05 "+5;"
#test_value 03 "-2+5;"
#test_value 04 "2*( (20-(6+2))/6 );"
#test_value 05 "10/2;"
#test_value 20 "4*(2+3);"
#test_value 06 "2*3;"
#test_value 05 "10  - (2+3);"
#test_value 09 "10+(2-3);"
#test_value 10 "10;"