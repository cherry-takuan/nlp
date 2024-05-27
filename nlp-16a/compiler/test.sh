#!/bin/bash
echo > report.txt
echo "debugger port select"
uart_dev_debug=$(./nlpdebug/UART_sel.py)
if [ $? -ne 0 ] ; then
    echo 'open error'
    exit 1
fi
echo "test port select"
uart_dev_test=$(./nlpdebug/UART_sel.py)
if [ $? -ne 0 ] ; then
    echo 'open error'
    exit 1
fi

echo "debugger:$uart_dev_debug"
echo "test dev:$uart_dev_test"

make

function test_value() {
  want="$1"
  input="$2"
  nlpcc_output=$(echo $input | ./nlpcc)
  if [ $? -ne 0 ] ; then
    echo 'nlpcc error'
    exit 1
  fi
  result="$(echo $input | ./nlpcc | nlpasm/ASCII.py | nlpasm/nlpasm.py | nlpdebug/test.py $uart_dev_debug $uart_dev_test)"
  if [ $? -ne 0 ] ; then
    echo 'execution error'
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

test_value 05 "if (2)if (0) return 3;else return 5;else return 7;"
test_value 06 "test_1=2;test_2=3;return test_1*test_2;"
test_value 07 "return 7;"
test_value 20 "a=4;b=2;c=3;a*(b+c);"
test_value 06 "a=2;b=3;a*b;"

test_value 0 "2*( (20-(6+2))/6 ) == 4*(2+3);"

test_value 1 "10>=5;"
test_value 1 "10>=10;"
test_value 0 "5>=10;"

test_value 0 "10<=5;"
test_value 1 "10<=10;"
test_value 1 "5<=10;"

test_value 0 "5>10;"
test_value 1 "10>5;"

test_value 1 "5<10;"
test_value 0 "10<5;"

test_value 0 "10!=10;"
test_value 1 "10!=5;"

test_value 1 "10==10;"
test_value 0 "10==5;"

test_value 05 "+5;"
test_value 03 "-2+5;"
test_value 04 "2*( (20-(6+2))/6 );"
test_value 05 "10/2;"
test_value 20 "4*(2+3);"
test_value 06 "2*3;"
test_value 05 "10  - (2+3);"
test_value 09 "10+(2-3);"
test_value 10 "10;"