#include "../includes.h"
//#include "../ucos2/arm/OS_CPU.h"

#define WTCON *((volatile unsigned long*)0x53000000)
#define MPLLCON *((volatile unsigned long*)0x4C000004)
#define CAMDIVN *((volatile unsigned long*)0x4C000018)
#define CLKDIVN *((volatile unsigned long*)0x4C000014)

#define BWSCON *((volatile unsigned long*)0x48000000)
#define BANKCON6 *((volatile unsigned long*)0x4800001C)
#define REFRESH *((volatile unsigned long*)0x48000024)
#define BANKSIZE *((volatile unsigned long*)0x48000028)
#define MRSRB6 *((volatile unsigned long*)0x4800002C)

#define ULCON0 *((volatile unsigned long*)0x50000000)
#define UCON0 *((volatile unsigned long*)0x50000004)
#define UFCON0 *((volatile unsigned long*)0x50000008)
#define UBRDIV0 *((volatile unsigned long*)0x50000028)
#define UTRSTAT0 *((volatile unsigned long*)0x50000010)

#define UTXH0 *((volatile unsigned long*)0x50000020)
#define URXH0 *((volatile unsigned long*)0x50000024)

#define GPHCON *((volatile unsigned long*)0x56000070)

//TIMER
#define TCFG0 *((volatile unsigned long*)0x51000000)
#define TCFG1 *((volatile unsigned long*)0x51000004)
#define TCON *((volatile unsigned long*)0x51000008)

#define TCNTB0 *((volatile unsigned long*)0x5100000C)
#define TCMPB0 *((volatile unsigned long*)0x51000010)

//int ctrl reg
#define SRCPND *((volatile unsigned long*)0X4A000000)
#define INTPND *((volatile unsigned long*)0X4A000010)
#define INTMSK *((volatile unsigned long*)0X4A000008)

//nand flash read
#define NFCONF *((volatile unsigned long*)0x4E000000)
#define NFCONT *((volatile unsigned long*)0x4E000004)
#define NFCMD *((volatile unsigned long*)0x4E000008)
#define NFADDR *((volatile unsigned long*)0x4E00000C)
#define NFSTAT *((volatile unsigned long*)0x4E000020)
#define NFDATA *((volatile unsigned long*)0x4E000010)



#define GPBCON *((volatile unsigned long*)0x56000010)
#define GPBDAT *((volatile unsigned long*)0x56000014)



unsigned int temp_lr = 0;
unsigned int temp_spsr = 0;

void Main(void)
{
	GPBCON |=(1<<12) ;
  GPBDAT =  0;
	
#if 1
	WTCON = 0; //disable watch dog
	
	MPLLCON = 0x7f021; //405M
	CAMDIVN = 0;
	CLKDIVN = 1 | (2<<1); //FCLK:HCLK:PCLK=8:2:1

	//SDRAM initialize
	BWSCON = (2 << 24);
	BANKCON6 = (3 << 15)| 1;
	REFRESH = 1269 | (1<<18) | (1<<23);
	BANKSIZE = 1 | (1<<5) | (1<<7);
	MRSRB6 = (3<<4);
#endif
	//CP15
	__asm__ __volatile__ (
		"mcr p15,0, %0,c1,c0,0\n"
		:
		:"r" ((1<<1)|(0xf<<3)|(1<<12)|(3<<30))
		);

	/*UART0 config*/
	//char cmd_buf[1023];
	GPHCON &= ~(0xf << 4);
	GPHCON |= (0xa << 4);
	ULCON0 = 3;
	UCON0 = 1 | (1 << 2);
	UFCON0 = 0;
	UBRDIV0 = 27;
#if 0
	//INTMSK = 0;
	TCFG0 = 0; // prescaler = 0
	TCFG1 = 0x0; // 0:PCLK * 1/2
	INTMSK &= (~(1<<10));
	TCNTB0 = 65535;
	TCMPB0 = 0;
	TCON |= (1<<3);	//1 = Interval mode(auto reload)
	TCON |= (1<<1); //Timer 0 manual update on
	TCON |= (1<<2);	//1 = Inverter on for TOUT0
	TCON &= ~(1<<2);	//1 = Inverter off
	TCON |= 1;  //Timer 0 start
	TCON &= ~(1<<1); //Timer 0 manual update off		
#endif
	put_string("----------- Tony system start-----------1\n");
//	nand_read(0x30000000, 0, 100);//50k
	

//	put_string("----------- Tony system start-----------2\n");
	
	
	/*__asm__ __volatile__(\
	"ldr r0,=os_main\n"\
	"mov lr,pc\n"\
	"mov pc,r0\n"\
	);*/
	


	while(1)
	;
		
}

void nand_read(unsigned char *buf, unsigned long nand_addr, int page_cnt)
{

  
	//char buf[512];
	int i, j;
	
	NFCONF = (3<<8);
	NFCONT = 1;
	for(i=0; i<page_cnt; i++, nand_addr+=512){
	
		NFCMD = 0x00;
	
		NFADDR = nand_addr&0xff;
		NFADDR = (nand_addr>>9)&0xff;
		NFADDR = (nand_addr>>17)&0xff;
		NFADDR = (nand_addr>>25)&0x1;
	
		while(!(NFSTAT&1))
			;
	
		for(j=0; j<512; j++){
			*buf = NFDATA;
			buf++;
		}	
	}
	NFCONT = (1<<1);
}

void MainTask(void *pdata)
{
	  while(1){
	  	OSTimeDly(OS_TICKS_PER_SEC*10);
	  	put_string("MainTask\r\n");
	  }
}
OS_STK  MainTaskStk[256];
void test(void)
{
	put_string("test\r\n");
}
void swi_test(void)
{
	put_string("swi\r\n");
}

void os_main(void)
{

	#if 1	
 	OSInit();
   	
 	OSTimeSet(0);
   	
 	OSTaskCreate(MainTask,(void *)0, &(MainTaskStk[256 - 1]), 11);
	
	__asm__ __volatile__(
	 	"mrs r0, cpsr\n" 
	"and r0, r0, #0xFFFFFF3F\n"
	"msr cpsr, r0\n"
	);
	OSStart();
	#endif	
}



unsigned char get_char(void)
{
	while(!(UTRSTAT0&1));
	
	return URXH0;
	
}

void put_char(unsigned char ch)
{
	while(!(UTRSTAT0&(1 << 1)));
	
	UTXH0 = ch;
}

void put_string(const unsigned char* str)
{
	while(*str){
		put_char(*str);
		str++;
	}
}

void get_string(unsigned char* str)
{
	unsigned char ch;
	while(1){
		if ((*str)!='\0'){
			ch = get_char();
			if ((ch == '\n')||(ch == '\r')){
				*str = 0;
				break;
			}
			*str = ch;
			str++;
		}
	}
}


void irq_handler(void)
{
	//SRCPND &= ~( 1 << 10);
	//INTPND &= ~( 1 << 10);
	SRCPND |= ( 1 << 10);
	INTPND |= ( 1 << 10);
//	put_string("abc");
	put_string("irq_handler_enter\n\r");
#if 0
	switch(SRCPND){
		case (1<<10):
			SRCPND &= ~(1<<10);
			put_string("irq_handler\n");
			break;
		default:
			put_char("default\n");
			break;
	}
	#endif
	
}
