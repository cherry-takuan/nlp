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


/* Global define */


/* Global Variable */
vu8 val;

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

    USART_InitStructure.USART_BaudRate = 115200;
    USART_InitStructure.USART_WordLength = USART_WordLength_8b;
    USART_InitStructure.USART_StopBits = USART_StopBits_1;
    USART_InitStructure.USART_Parity = USART_Parity_No;
    USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
    USART_InitStructure.USART_Mode = USART_Mode_Tx | USART_Mode_Rx;

    USART_Init(USART1, &USART_InitStructure);
    USART_Cmd(USART1, ENABLE);
}
void GPIO_SET(GPIO_TypeDef * reg,uint16_t num, uint16_t mode){
    GPIO_InitTypeDef GPIO_InitStructure = {0};
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA|RCC_APB2Periph_GPIOC|RCC_APB2Periph_GPIOD, ENABLE);
    GPIO_InitStructure.GPIO_Pin = num;
    GPIO_InitStructure.GPIO_Mode = mode;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(reg, &GPIO_InitStructure);
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
    USART_Printf_Init(115200);
    printf("SystemClk:%d\r\n",SystemCoreClock);
    printf( "ChipID:%08x\r\n", DBGMCU_GetCHIPID() );

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOD, ENABLE);

    GPIO_SET(GPIOD, GPIO_Pin_2, GPIO_Mode_Out_PP);//GP LED

    USARTx_CFG();

    printf( "start write...\r\n");
    //Flash¤Î•ø¤­Þz¤ß¤ò¥¢¥ó¥í¥Ã¥¯
    FLASH_Unlock();
    //FLASH_Unlock_Fast();
    //UserOptionByte¤ÇPD7¤òÓÐ„¿¤Ë¤¹¤ë
    FLASH_Status status = FLASH_UserOptionByteConfig(OB_IWDG_SW, OB_STOP_NoRST, OB_STDBY_NoRST,OB_RST_NoEN, OB_PowerON_Start_Mode_BOOT);
    //FLASH_Status status = FLASH_UserOptionByteConfig(OB_IWDG_SW, OB_STOP_NoRST, OB_STDBY_NoRST,OB_RST_EN_DT12ms, OB_PowerON_Start_Mode_BOOT);
    FLASH_Lock();
    //¥ì¥¹¥Ý¥ó¥¹±íÊ¾
    switch(status){
    case FLASH_COMPLETE:
            printf( "FLASH_COMPLETE");
            break;
    case FLASH_BUSY:
            printf( "FLASH_BUSY");
            break;
    case FLASH_ERROR_PG:
            printf( "FLASH_ERROR_PG");
            break;
    case FLASH_ERROR_WRP:
            printf( "FLASH_ERROR_WRP");
            break;
    case FLASH_TIMEOUT:
            printf( "FLASH_TIMEOUT");
            break;
    }
    printf( "\n\r%d",FLASH_GetUserOptionByte());
    printf( "\r\nFinish");

    while(1){
        GPIO_WriteBit(GPIOD,GPIO_Pin_2,Bit_SET);
        Delay_Ms(100);
        GPIO_WriteBit(GPIOD,GPIO_Pin_2,Bit_RESET);
        Delay_Ms(200);
    }
}
