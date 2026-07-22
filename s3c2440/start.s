.global _start
					
					
_start:
	b reset
	ldr pc, =undef
	ldr pc, =swi
	ldr pc, =abt_pre
	ldr pc, =abt_data
	.word 0
	ldr pc, =irq
	ldr pc, =fiq


reset:
 	@disable interrupt
	mrs r0, cpsr
	orr r0, r0, #0xc0
	msr cpsr, r0
	
 
	@Disable Watch dog
  ldr r0, WTCON
  mov r1, #0
	str r1, [r0]	

/*
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
*/


	
	@init PLL
	ldr r0, MPLLCON
  ldr r1, =0x7f021
	str r1, [r0]
	
	ldr r0, CAMDIVN
  mov r1, #0
	str r1, [r0]	
		
  ldr r0, CLKDIVN
  mov r1, #2
  lsl r1, r1, #1
  orr r1, r1, #1
	str r1, [r0]	
	
  @SDRAM initialize
  ldr r0, BWSCON
  mov r1, #2
  lsl r1, r1, #24
	str r1, [r0]
	
  ldr r0, BANKCON6
  mov r1, #3
  lsl r1, r1, #15
  orr r1, r1, #1
	str r1, [r0]
	
	ldr r0, REFRESH
	mov r1, #1
	lsl r1, r1, #18
	mov r2, #1
	lsl r2, r2, #23
  orr r1, r1, r2
  ldr r3, =1269
  orr r1, r1, r3
	str r1, [r0]
		
	ldr r0, BANKSIZE
	mov r1, #1
	lsl r1, r1, #5
	mov r2, #1
	lsl r2, r2, #7
  orr r1, r1, r2
  orr r1, r1, #1
	str r1, [r0]
	
	ldr r0, MRSRB6
  mov r1, #3
  lsl r1, r1, #4
	str r1, [r0]
 
 @led test
 
  ldr r0, GPBCON
  mov r1, #1
  lsl r1, r1, #10
	str r1, [r0]
 
  ldr r0, GPBDAT
  mov r1, #0
	str r1, [r0]
 

	@set irq mode stack pointer
	mov r0, #0xc0|0x12
	msr cpsr, r0
	mov sp,#0x32000000
	
	@set svc mode stack pointer
	mov r0, #0xc0|0x13
	msr cpsr, r0
	mov sp, #0x33000000
	
	
	b Main



loop:
	b loop


undef:
	mov sp, #0x31000000
	b undef
	
swi:
	stmfd sp!,{lr}
	stmfd sp!,{r0-r12,lr}
	mrs r0,spsr
	stmfd sp!,{r0}
	@save sp of current task'stack to OSTCBCur
	ldr r0,=OSTCBCur
	ldr r1, [r0]
	str sp, [r1]
/*	
	LDR R0,[LR,#-8]
	BIC R0,R0,#0xFF000000
	tst	R0,#0x1
*/
	bl	OSCtxSw
	@BEQ	OSCtxSw
	@BEQ swi_test

	
loop2:
	b loop2

abt_pre:
	mov sp, #0x31000000

	b abt_pre
	
	
abt_data:
	mov sp, #0x31000000

	b abt_data
	
	
irq:

	stmfd sp!,{r0,r1}
	
		
	@store irq mode's spsr(ie. ori mode's cpsr) and lr into global var	for return ori mode
	ldr r0,=temp_spsr
	mrs r1,spsr
	str r1,[r0]
	ldr r0,=temp_lr
	str lr,[r0]

	ldmfd sp!,{r0,r1} /* resotre r0,r1*/
	
	mrs lr,spsr
	orr lr,lr,#0x80
	msr cpsr,lr  @back to ori mode(svc)
	
	@>>>>> START to save ori mode's reg >>>>>>>>>>>>>>
	sub sp,sp,#4   @prepare mem for pc in stack
	stmfd sp!,{r0-r12,lr}
	ldr r0,=temp_lr
	ldr r1,[r0]
	sub r1,r1,#4
	str r1,[sp,#(14*4)]
	
	ldr r0,=temp_spsr
	ldr r1,[r0]
	stmfd sp!,{r1}
	
	ldr r0,=OSTCBCur
	ldr r1,[r0]
	str sp,[r1]
	@<<<<< END to save ori mode's reg <<<<<<<<<<<<<<<<

	bl irq_handler @clear interrupt pending

	
	bl OSTickISR
	/*
	  ldr r0, SRCPND
  ldr r1,[r0]
  orr r1,r1,#0x400
	str r1, [r0]
	ldr r0, INTPND
  ldr r1,[r0]
  orr r1,r1,#0x400
	str r1, [r0]*/


	ldr r0,=OSTCBCur
	ldr r1,[r0]
	ldr r2,[r1]
	mov sp,r2
	ldmfd sp!,{r0}
	msr spsr,r0
	ldmfd sp!,{r0-r12,lr,pc}^ /* restore reg and back to ori mode */

	
	
fiq:
	mov sp, #0x31000000
	b fiq


	
loop3:
	b loop3

	


BWSCON:
	.word 0x48000000
BANKCON6:
	.word 0x4800001C
REFRESH: 
	.word 0x48000024
BANKSIZE: 
	.word 0x48000028
MRSRB6:
	.word 0x4800002C

	
UTXH0: 
	.word 0x50000020
	
SRCPND:
	.word 0X4A000000
INTPND:
	.word 0X4A000010

GPBCON:
	.word 0x56000010
GPBDAT:
	.word 0x56000014
	
	
	
WTCON:
	.word 0x53000000
MPLLCON:
	.word 0x4C000004
CAMDIVN:
	.word 0x4C000018
CLKDIVN:
	.word 0x4C000014
	
	
	
	
str_abt_data:
	.asciz "str_abt_data\n\r"

str_irq:
	.asciz "str_irq\n\r"
	
str_irq_handler2:
	.asciz "str_irq_handler2\n\r"
	
