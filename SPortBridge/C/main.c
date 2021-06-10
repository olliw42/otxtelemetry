/*
#define SPORT_UART    UART2
#define SPORT_BAUD    400000

#define SPORT_TX_EN_LEVEL_GPIO   PA1
#define SPORT_RX_EN_LEVEL_GPIO   PA4

#define SERIAL_UART   USART1
#define SERIAL_BAUD   57600

#define SERIAL2_UART  UART3
#define SERIAL2_BAUD  57600

#define LED_GPIO      PA7
#define LED2_GPIO     PA6
*/


#include <stdlib.h>

#include "stm32f10x.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include "stm32f10x_tim.h"


//------------------------------
// uart = UART2 = one-wire OpenTx channel

#define UART_BAUD           400000

#define UART_TXBUFSIZE      256 //MUST be 2^N
#define UART_TXBUFSIZEMASK  (UART_TXBUFSIZE-1)

volatile char uart_txbuf[UART_TXBUFSIZE];
volatile uint16_t uart_txwritepos;
volatile uint16_t uart_txreadpos;

#define UART_RXBUFSIZE      256 //MUST be 2^N
#define UART_RXBUFSIZEMASK  (UART_RXBUFSIZE-1)

volatile char uart_rxbuf[UART_RXBUFSIZE];
volatile uint16_t uart_rxwritepos;
volatile uint16_t uart_rxreadpos;

#define UART_UARTx          USART2
#define UART_TX_GPIOx       GPIOA
#define UART_TX_PIN         GPIO_Pin_2
#define UART_RX_GPIOx       GPIOA
#define UART_RX_PIN         GPIO_Pin_3
#define UART_USARTx_IRQn    USART2_IRQn

void USART2_IRQHandler(void)
{
  uint16_t usart_sr = UART_UARTx->SR;
  uint8_t usart_dr = UART_UARTx->DR;
  if( usart_sr & USART_SR_RXNE ){
    //uint8_t usart_dr = UART_UARTx->DR;
    uint16_t next = ( uart_rxwritepos + 1 ) & UART_RXBUFSIZEMASK;
    if( uart_rxreadpos != next ){
      uart_rxbuf[next] = usart_dr;
      uart_rxwritepos = next;
    }
  }
  if( usart_sr & USART_SR_TXE ){
    if( uart_txwritepos != uart_txreadpos ){
      uart_txreadpos = ( uart_txreadpos + 1 ) & UART_TXBUFSIZEMASK;
      UART_UARTx->DR = uart_txbuf[uart_txreadpos];
    }else
      UART_UARTx->CR1 &=~ USART_CR1_TXEIE;
  }
}

uint16_t uart_putc(char c)
{
  uint16_t next = ( uart_txwritepos + 1 ) & UART_TXBUFSIZEMASK;
  if( uart_txreadpos != next ){
    uart_txbuf[next] = c;
    uart_txwritepos = next;
    UART_UARTx->CR1 |= USART_CR1_TXEIE;
    return 1;
  }
  return 0;
}

uint16_t uart_rx_available(void)
{
  if( uart_rxwritepos == uart_rxreadpos ) return 0;
  return 1;
}

char uart_getc(void)
{
  uart_rxreadpos = ( uart_rxreadpos + 1 ) & UART_RXBUFSIZEMASK;
  return uart_rxbuf[uart_rxreadpos];
}

void uart_rx_enableisr(FunctionalState flag)
{
  if( flag == ENABLE ){
    USART_ClearITPendingBit(UART_UARTx, USART_IT_RXNE);
    USART_ITConfig(UART_UARTx, USART_IT_RXNE, ENABLE);
  }else{
    USART_ITConfig(UART_UARTx, USART_IT_RXNE, DISABLE);
    USART_ClearITPendingBit(UART_UARTx, USART_IT_RXNE);
  }
}

void uart_init_isroff(void)
{
GPIO_InitTypeDef GPIO_InitStructure;
USART_ClockInitTypeDef USART_ClockInitStructure;
USART_InitTypeDef USART_InitStructure;

  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2, ENABLE);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO, ENABLE);

  GPIO_InitStructure.GPIO_Pin = UART_TX_PIN;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(UART_TX_GPIOx, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = UART_RX_PIN;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(UART_RX_GPIOx, &GPIO_InitStructure);

  USART_ClockStructInit(&USART_ClockInitStructure);
  USART_ClockInit(UART_UARTx, &USART_ClockInitStructure);

  USART_InitStructure.USART_BaudRate = 400000;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_Init(UART_UARTx, &USART_InitStructure);

  NVIC_SetPriority(UART_USARTx_IRQn, 6);
  NVIC_EnableIRQ(UART_USARTx_IRQn);

  USART_ITConfig(UART_UARTx, USART_IT_TXE, DISABLE);
  USART_ClearITPendingBit(UART_UARTx, USART_IT_TXE);
  USART_ClearITPendingBit(UART_UARTx, USART_IT_TC);
  uart_txwritepos = uart_txreadpos = 0;

  USART_ITConfig(UART_UARTx, USART_IT_RXNE, DISABLE);
  USART_ClearITPendingBit(UART_UARTx, USART_IT_RXNE);
  uart_rxwritepos = uart_rxreadpos = 0;

  USART_Cmd(UART_UARTx, ENABLE);
}

void uart_init(void)
{
  uart_init_isroff();
  uart_rx_enableisr(ENABLE);
}


//------------------------------
// uartb = UART1 = MAVLink channel

#define UARTB_BAUD           57600

#define UARTB_TXBUFSIZE      256 //MUST be 2^N
#define UARTB_TXBUFSIZEMASK  (UARTB_TXBUFSIZE-1)

volatile char uartb_txbuf[UARTB_TXBUFSIZE];
volatile uint16_t uartb_txwritepos;
volatile uint16_t uartb_txreadpos;

#define UARTB_RXBUFSIZE      256 //MUST be 2^N
#define UARTB_RXBUFSIZEMASK  (UARTB_RXBUFSIZE-1)

volatile char uartb_rxbuf[UARTB_RXBUFSIZE];
volatile uint16_t uartb_rxwritepos;
volatile uint16_t uartb_rxreadpos;

#define UARTB_UARTx          USART1
#define UARTB_TX_GPIOx       GPIOA
#define UARTB_TX_PIN         GPIO_Pin_9
#define UARTB_RX_GPIOx       GPIOA
#define UARTB_RX_PIN         GPIO_Pin_10
#define UARTB_USARTx_IRQn    USART1_IRQn

void USART1_IRQHandler(void)
{
  uint16_t usart_sr = UARTB_UARTx->SR;
  uint8_t usart_dr = UARTB_UARTx->DR;
  if( usart_sr & USART_SR_RXNE ){
    //uint8_t usart_dr = UARTB_UARTx->DR;
    uint16_t next = ( uartb_rxwritepos + 1 ) & UARTB_RXBUFSIZEMASK;
    if( uartb_rxreadpos != next ){
      uartb_rxbuf[next] = usart_dr;
      uartb_rxwritepos = next;
    }
  }
  if( usart_sr & USART_SR_TXE ){
    if( uartb_txwritepos != uartb_txreadpos ){
      uartb_txreadpos = ( uartb_txreadpos + 1 ) & UARTB_TXBUFSIZEMASK;
      UARTB_UARTx->DR = uartb_txbuf[uartb_txreadpos];
    }else
      UARTB_UARTx->CR1 &=~ USART_CR1_TXEIE;
  }
}

uint16_t uartb_putc(char c)
{
  uint16_t next = ( uartb_txwritepos + 1 ) & UARTB_TXBUFSIZEMASK;
  if( uartb_txreadpos != next ){
    uartb_txbuf[next] = c;
    uartb_txwritepos = next;
    UARTB_UARTx->CR1 |= USART_CR1_TXEIE;
    return 1;
  }
  return 0;
}

uint16_t uartb_rx_available(void)
{
  if( uartb_rxwritepos == uartb_rxreadpos ) return 0;
  return 1;
}

char uartb_getc(void)
{
  uartb_rxreadpos= ( uartb_rxreadpos + 1 ) & UARTB_RXBUFSIZEMASK;
  return uartb_rxbuf[uartb_rxreadpos];
}

void uartb_init(void)
{
GPIO_InitTypeDef GPIO_InitStructure;
USART_ClockInitTypeDef USART_ClockInitStructure;
USART_InitTypeDef USART_InitStructure;

  RCC_APB2PeriphClockCmd(RCC_APB2Periph_USART1 | RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO, ENABLE);

  GPIO_InitStructure.GPIO_Pin = UARTB_TX_PIN;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(UARTB_TX_GPIOx, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = UARTB_RX_PIN;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(UARTB_RX_GPIOx, &GPIO_InitStructure);

  USART_ClockStructInit(&USART_ClockInitStructure);
  USART_ClockInit(UARTB_UARTx, &USART_ClockInitStructure);

  USART_InitStructure.USART_BaudRate = UARTB_BAUD;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_Init(UARTB_UARTx, &USART_InitStructure);

  NVIC_SetPriority(UARTB_USARTx_IRQn, 7);
  NVIC_EnableIRQ(UARTB_USARTx_IRQn);

  USART_ITConfig(UARTB_UARTx, USART_IT_TXE, DISABLE);
  USART_ClearITPendingBit(UARTB_UARTx, USART_IT_TXE);
  USART_ClearITPendingBit(UARTB_UARTx, USART_IT_TC);
  uartb_txwritepos = uartb_txreadpos = 0;

  USART_ClearITPendingBit(UARTB_UARTx, USART_IT_RXNE);
  USART_ITConfig(UARTB_UARTx, USART_IT_RXNE, ENABLE);
  uartb_rxwritepos = uartb_rxreadpos = 0;

  USART_Cmd(UARTB_UARTx, ENABLE);
}


//------------------------------
// tim1

void tim_init(void)
{
TIM_TimeBaseInitTypeDef TIM_TimeBase_InitStructure;

  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2 , ENABLE);

  TIM_TimeBase_InitStructure.TIM_ClockDivision = TIM_CKD_DIV1;
  TIM_TimeBase_InitStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBase_InitStructure.TIM_Period = 0xFFFF;
  TIM_TimeBase_InitStructure.TIM_Prescaler = (SystemCoreClock/1000000)-1; //0;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBase_InitStructure);

  TIM_Cmd(TIM2, ENABLE);
}

uint16_t micros(void)
{
  return TIM2->CNT;
}


//------------------------------
// led
#define GPIO_TOGGLEBIT(x,y) ((x)->BSRR = (((x)->ODR ^ (y)) & (y)) | ((y) << 16))


#define LED_RCC_APB2Periph_GPIOx    RCC_APB2Periph_GPIOA
#define LED_GPIOx                   GPIOA
#define LED_GPIO_Pin_x              GPIO_Pin_7

#define LED2_RCC_APB2Periph_GPIOx   RCC_APB2Periph_GPIOA
#define LED2_GPIOx                  GPIOA
#define LED2_GPIO_Pin_x             GPIO_Pin_6


#define LED_ON                      GPIO_WriteBit( LED_GPIOx, LED_GPIO_Pin_x, Bit_SET )
#define LED_OFF                     GPIO_WriteBit( LED_GPIOx, LED_GPIO_Pin_x, Bit_RESET )
#define LED_TOGGLE                  GPIO_TOGGLEBIT( LED_GPIOx, LED_GPIO_Pin_x )

#define LED2_ON                     GPIO_WriteBit( LED2_GPIOx, LED2_GPIO_Pin_x, Bit_SET )
#define LED2_OFF                    GPIO_WriteBit( LED2_GPIOx, LED2_GPIO_Pin_x, Bit_RESET )
#define LED2_TOGGLE                 GPIO_TOGGLEBIT( LED2_GPIOx, LED2_GPIO_Pin_x )


void led_init(void)
{
GPIO_InitTypeDef GPIO_InitStructure;

  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);

  GPIO_InitStructure.GPIO_Pin = LED_GPIO_Pin_x;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(LED_GPIOx, &GPIO_InitStructure);
}


void led2_init(void)
{
GPIO_InitTypeDef GPIO_InitStructure;

  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);

  GPIO_InitStructure.GPIO_Pin = LED2_GPIO_Pin_x;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(LED2_GPIOx, &GPIO_InitStructure);
}


//------------------------------
// Here it comes, the code
//------------------------------

void uart_transmit_enable(FunctionalState flag)
{
//GPIO_InitTypeDef GPIO_InitStructure;

//    GPIO_InitStructure.GPIO_Pin = UART_TX_PIN;
//    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    if (flag == ENABLE) {
//        GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
//        GPIO_Init(UARTB_TX_GPIOx, &GPIO_InitStructure);
        uart_rx_enableisr(DISABLE);
    } else {
//        GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
//        GPIO_Init(UARTB_TX_GPIOx, &GPIO_InitStructure);
//        GPIO_SetBits(UARTB_TX_GPIOx, UART_TX_PIN);
        uart_rx_enableisr(ENABLE);
    }
}


enum TxStateEnum {
    TXSTATE_IDLE = 0,
    TXSTATE_RECEIVE_W,
    TXSTATE_RECEIVE_LEN,
    TXSTATE_RECEIVE_PAYLOAD,
    TXSTATE_DELAY,
    TXSTATE_TRANSMIT,
    TXSTATE_TRANSMIT_CLOSE,
};


uint8_t tx_state = TXSTATE_IDLE;
uint8_t tx_len = 0;
uint8_t tx_cnt;
uint16_t tlast_us;


// this should be called repeatedly
void spinOnce(void)
{
    switch (tx_state) {
    case TXSTATE_IDLE:
        if (uart_rx_available()) {
            uint8_t c = uart_getc();
            tlast_us = micros();
            if (c == 'O') tx_state = TXSTATE_RECEIVE_W;
        }
        break;
    case TXSTATE_RECEIVE_W: {
        if (uart_rx_available()) {
            uint8_t c = uart_getc();
            tlast_us = micros();
            if (c == 'W') tx_state = TXSTATE_RECEIVE_LEN; else tx_state = TXSTATE_IDLE; // error
        }
        uint16_t dt = micros() - tlast_us;
        if (dt > 50) tx_state = TXSTATE_IDLE; // timeout error
        }break;
    case TXSTATE_RECEIVE_LEN: {
        if (uart_rx_available()) {
            tx_len = uart_getc();
            tlast_us = micros();
            tx_cnt = 0;
            if (tx_len > 16) {
                tx_state = TXSTATE_IDLE; // error
            } else if (tx_len > 0) {
                tx_state = TXSTATE_RECEIVE_PAYLOAD;
            } else {
                tx_state = TXSTATE_DELAY;
            }
        }
        uint16_t dt = micros() - tlast_us;
        if (dt > 50) tx_state = TXSTATE_IDLE; // timeout error
        }break;
    case TXSTATE_RECEIVE_PAYLOAD: {
        if (uart_rx_available()) {
            uint8_t c = uart_getc();
            tlast_us = micros();
            uartb_putc(c);
            tx_cnt++;
            if (tx_cnt >= tx_len) tx_state = TXSTATE_DELAY;
        }
        uint16_t dt = micros() - tlast_us;
        if (dt > 50) tx_state = TXSTATE_IDLE; // timeout error
        }break;
    case TXSTATE_DELAY: {
        uint16_t dt = micros() - tlast_us;
        if (dt > 50) tx_state = TXSTATE_TRANSMIT;
        }break;
    case TXSTATE_TRANSMIT: {
        // switch to transmit to OpenTx
        uart_transmit_enable(ENABLE);
        tlast_us = micros();
        // send up to 16 bytes to OpenTx
        for (uint8_t i = 0; i < 16; i++) {
            if (!uartb_rx_available()) break;
            uint8_t c = uartb_getc();
            uart_putc(c);
        }
        tx_state = TXSTATE_TRANSMIT_CLOSE;
        }break;
    case TXSTATE_TRANSMIT_CLOSE: {
        // wait for bytes to be transmitted
        uint16_t dt = micros() - tlast_us;
        if (dt > 500) { // 16 bytes @ 400000 bps = 400 us
            // switch back to receive from OpenTx when all are transmitted
            uart_transmit_enable(DISABLE);
            tx_state = TXSTATE_IDLE;
        }
        }break;
    }
}



uint16_t tick_tlast_us;
uint16_t tick_ms;

int main(void)
{
    NVIC_SetPriorityGrouping(0);
    uart_init();
    uartb_init();
    tim_init();

    uart_transmit_enable(DISABLE);

    led_init();
    led2_init();
    LED_ON;
    LED2_OFF;

    tick_tlast_us = micros();
    tick_ms = 0;

    while(1) {
        spinOnce();

        uint16_t dt = micros() - tick_tlast_us;
        if (dt > 1000) {
          tick_tlast_us += 1000;
          tick_ms++;
          if (tick_ms >= 500) tick_ms = 0;

          if( !tick_ms) LED2_TOGGLE;
        }
    }
}
