/********************************** (C) COPYRIGHT *******************************
 * File Name          : main.c
 * Author             : WCH
 * Version            : V1.0.0
 * Date               : 2022/08/08
 * Description        : Main program body.
 *********************************************************************************
 * Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
 * Attention: This software (modified or not) and binary are used for 
 * microcontroller manufactured by Nanjing Qinheng Microelectronics.
 *******************************************************************************/

/*
 *@Note
 *Multiprocessor communication mode routine:
 *Master:USART1_Tx(PD5)\USART1_Rx(PD6).
 *This routine demonstrates that USART1 receives the data sent by CH341 and inverts
 *it and sends it (baud rate 115200).
 *
 *Hardware connection:PD5 -- Rx
 *                     PD6 -- Tx
 *
 */

#include "debug.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <limits.h>


/* Global define */

//instruction
#define ID_SET 0x00
#define DIR_GET 0x01
#define DIR_SET 0x02
#define IO_UPDATE 0x03
#define IN_GET 0x04
#define OUT_GET 0x05
#define REVERSE_MODE 0x06
#define BOARD_RESET 0x0F
#define PROGRAMMING_MODE 0xFF

//address
#define TO_ALL 0xFE
#define TO_MASTER 0xFF

/* Global Variable */

struct pin_assign {
    GPIO_TypeDef * reg;
    uint16_t num;
};

struct pin_assign PIN__ARRAY[]= {
            {GPIOD,GPIO_Pin_0},
            {GPIOC,GPIO_Pin_0},
            {GPIOA,GPIO_Pin_2},
            {GPIOA,GPIO_Pin_1},
            {GPIOD,GPIO_Pin_7},
            {GPIOD,GPIO_Pin_4},
            {GPIOD,GPIO_Pin_3},
            {GPIOD,GPIO_Pin_2},
            {GPIOC,GPIO_Pin_7},
            {GPIOC,GPIO_Pin_6},
            {GPIOC,GPIO_Pin_5},
            {GPIOC,GPIO_Pin_4},
            {GPIOC,GPIO_Pin_3},
            {GPIOC,GPIO_Pin_2},
            {GPIOC,GPIO_Pin_1},
            {GPIOD,GPIO_Pin_1}
    };

const size_t PIN__ARRAY_COUNT = (sizeof(PIN__ARRAY) / sizeof(PIN__ARRAY[0]));

vu8 val;
#define Buf_size 20
char serial_rx[Buf_size] = "";

uint16_t id = 0x00;
uint16_t dir = 0x0000;
uint16_t output = 0x0000;
uint16_t input = 0x0000;

uint16_t gpio_reverse = 0;
// gpio_reverse == 1 =>reverse

/*********************************************************************
 * @fn      USARTx_CFG
 *
 * @brief   Initializes the USART2 & USART3 peripheral.
 *
 * @return  none
 */
void USARTx_CFG(void)
{
    GPIO_InitTypeDef  GPIO_InitStructure = {0};
    USART_InitTypeDef USART_InitStructure = {0};

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOD | RCC_APB2Periph_USART1, ENABLE);

    /* USART1 TX-->D.5   RX-->D.6 */
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
    GPIO_Init(GPIOD, &GPIO_InitStructure);
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init(GPIOD, &GPIO_InitStructure);

    USART_InitStructure.USART_BaudRate = 19200;
    USART_InitStructure.USART_WordLength = USART_WordLength_8b;
    USART_InitStructure.USART_StopBits = USART_StopBits_1;
    USART_InitStructure.USART_Parity = USART_Parity_No;
    USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
    USART_InitStructure.USART_Mode = USART_Mode_Tx | USART_Mode_Rx;

    USART_Init(USART1, &USART_InitStructure);
    USART_Cmd(USART1, ENABLE);
}

/*********************************************************************
 * @fn      serialReceive
 *
 * @brief   UART receive
 *
 * @return  none
 */
void serial_buf_clear(){
    for(int i=0; i < Buf_size;i++){
        serial_rx[i] = '\0';
    }
}
void serialReceive(){
    char c;
    //文字列初期化
    serial_buf_clear();
    while(1){
        while(USART_GetFlagStatus(USART1, USART_FLAG_RXNE) == RESET)
        {/* waiting for receiving finish */}
        c = (USART_ReceiveData(USART1));

        size_t now = strlen(serial_rx);
        if(c == '\r'){
            continue;
        }
        if(c == '\n'){
            //10文字でなければクリア，10文字なら本処理に返す
            if(now!=10) serial_buf_clear();
            else        return;
        }
        if(isprint(c)){
            if(now > 10){
                //10文字以上であれば受信データクリアして先頭から書き込み
                serial_buf_clear();
                serial_rx[0] = c;
            }else{
                serial_rx[now] = c;
            }
        }
    }
}

/*********************************************************************
 * @fn      serial_send
 *
 * @brief   serial_send
 *
 * @return  none
 */
void serial_send(char *str){
    if(strlen(str) != 10)return;
    for(int i=0; i<10; i++){
        USART_SendData(USART1, str[i]);
        while(USART_GetFlagStatus(USART1, USART_FLAG_TXE) == RESET)
        {/* waiting for sending finish */}
    }
    USART_SendData(USART1, '\n');
    while(USART_GetFlagStatus(USART1, USART_FLAG_TXE) == RESET)
    {/* waiting for sending finish */}
}

void data_stansfer(uint16_t to_id, uint16_t mode, uint16_t value){
  if(0 <= to_id && to_id <= 0xFF &&
     0 <= mode  && mode <= 0xFF  &&
     0 <= value && value <= 0xFFFF){
    char Buf[12];
    sprintf(Buf,"%02X-%02X-%04X",to_id,mode,value);
    serial_send(Buf);
  }
}
/*********************************************************************
 * @fn      hex_to_int
 *
 * @brief
 *
 * @return  none
 */
int hex_str_to_int(char *str){
  char *endptr;
  long wk = strtol(str,&endptr,16);
  if (str == endptr) {
      return -1;
  }
  if (wk > INT_MAX || wk < INT_MIN) {
      return -1;
  }
  return (int)wk;
}


void GPIO_DIR_UPDATE(uint16_t pin_dir)
{
    GPIO_InitTypeDef GPIO_InitStructure = {0};
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA|RCC_APB2Periph_GPIOC|RCC_APB2Periph_GPIOD, ENABLE);
    for(int i=0,mask=1; i< PIN__ARRAY_COUNT; i++,mask<<=1){
        int array_num = (gpio_reverse == 0 ? i : (PIN__ARRAY_COUNT-1 - i));
        GPIO_InitStructure.GPIO_Pin = PIN__ARRAY[ array_num ].num;
        GPIO_InitStructure.GPIO_Mode = mask&pin_dir?GPIO_Mode_Out_PP:GPIO_Mode_IN_FLOATING;
        GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
        GPIO_Init(PIN__ARRAY[ array_num].reg, &GPIO_InitStructure);
    }
}

void GPIO_OUTPUT(uint16_t output,uint16_t pin_dir)
{
    output = output & pin_dir;
    for(int i=0,mask=1; i< PIN__ARRAY_COUNT; i++,mask<<=1){
        int array_num = (gpio_reverse == 0 ? i : (PIN__ARRAY_COUNT-1 - i));
        if((mask & pin_dir) != 0){
            GPIO_WriteBit(PIN__ARRAY[array_num].reg, PIN__ARRAY[array_num].num, mask&output?Bit_SET:Bit_RESET);
        }
    }
}
uint16_t GPIO_INPUT(uint16_t pin_dir)
{
    uint16_t input[3] = {};
    for(int j=0; j<3; j++){
        for(int i=0,mask=1; i< PIN__ARRAY_COUNT; i++,mask<<=1){
            int array_num = (gpio_reverse == 0 ? i : (PIN__ARRAY_COUNT-1 - i));
            //int in = ((mask&~pin_dir) ? GPIO_ReadInputDataBit(PIN__ARRAY[array_num].reg, PIN__ARRAY[array_num].num) : 0);
            input[j] |= ((mask&~pin_dir) ? GPIO_ReadInputDataBit(PIN__ARRAY[array_num].reg, PIN__ARRAY[array_num].num) : 0)<<i;
            Delay_Us(1);
        }
    }
    //3回のデータを多数決する
    return (input[0]&input[1]) | (input[1]&input[2]) | (input[2]&input[0]);
}
void status_print(){
  printf("status : id:%02X,dir:%04X,in:%04X,out:%04X\n",id,dir,input,output);
}

/*********************************************************************
 * @fn      main
 *
 * @brief   Main program.
 *
 * @return  none
 */
int main(void)
{
    NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
    SystemCoreClockUpdate();
    Delay_Init();
    USARTx_CFG();
    RCC_APB2PeriphClockCmd( RCC_APB2Periph_AFIO, ENABLE);
    GPIO_PinRemapConfig(GPIO_Remap_SDI_Disable, ENABLE);
    GPIO_DIR_UPDATE(dir);
    printf("debug board firmware v1.6 (c)cherry tech 2023\n\n");
    while(1)
    {
        serialReceive();
        //Delay_Ms(1);
        char wk[10] = "";
        strncpy(wk,serial_rx,2);
        int to_id = hex_str_to_int(wk);//ID取得16進2桁
        strncpy(wk,serial_rx+3,5);
        int mode = hex_str_to_int(wk);//命令のモード取得16進2桁
        strncpy(wk,serial_rx+6,10);
        int value = hex_str_to_int(wk);//値取得16進2桁
        if(to_id == -1 || mode == -1 || value == -1) continue;

        if(to_id != id && to_id != TO_ALL){//宛先が自身ではなく かつ 全体に向けてのものでなければ 受け取った命令を次のボードへ転送する
            data_stansfer(to_id,mode,value);
            continue;
        }
        switch(mode){
            case ID_SET:
                //00 - 識別番号
                id = value;
                data_stansfer(TO_ALL,mode,value+1);
                break;
            case DIR_GET:
                //01 - 入出力方向確認
                data_stansfer(TO_MASTER,mode,dir);
                break;
            case DIR_SET:
                //02 - 入出力方向指定
                dir = value;
                GPIO_DIR_UPDATE(dir);
                data_stansfer(TO_MASTER,mode,dir);
                break;
            case IO_UPDATE:
                //03 - 入出力
                output = value;
                //input = IO(output);
                input = GPIO_INPUT(dir);
                GPIO_OUTPUT(output, dir);
                data_stansfer(TO_MASTER,mode,input);
                break;
            case IN_GET:
                //04 - 入力
                input = GPIO_INPUT(dir);
                data_stansfer(TO_MASTER,mode,input);
                break;
            case OUT_GET:
                //05 - 出力
                data_stansfer(TO_MASTER,mode,output);
                break;
            case REVERSE_MODE:
                //逆順モード
                gpio_reverse = value;
                GPIO_DIR_UPDATE(dir);
                data_stansfer(TO_MASTER,mode,dir);
                break;
            case BOARD_RESET:
                //04 - Reset
                id=0x00;
                dir=0x0000;
                output=0x0000;
                gpio_reverse = 0;
                GPIO_DIR_UPDATE(dir);
                if(to_id == TO_ALL){
                    data_stansfer(TO_ALL,mode,value);
                }
                break;
            case PROGRAMMING_MODE:
                GPIO_PinRemapConfig(GPIO_Remap_SDI_Disable, DISABLE);
                RCC_APB2PeriphClockCmd( RCC_APB2Periph_AFIO, DISABLE);
                break;
            default:
                break;
        }
        //status_print();
    }
}
