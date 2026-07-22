.global _start

					
					
_start:
	b reset
	b undef
	b swi
	b abt_pre
	b abt_data
	.word 0
	b irq
	b fiq



reset:
 	@disable interrupt
 	
	mrs r0, cpsr 
	orr r0, r0, #0xc0
	msr cpsr, r0
	
/*	@Enable interrupt
 	mrs r0, cpsr 
	and r0, r0, #0xFFFFFF3F
	msr cpsr, r0*/
 
	@Disable Watch dog
 /* ldr r0, WTCON
  mov r1, #0
	str r1, [r0]	*/


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

/*
	
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
 */
 @led test
 
  ldr r0, GPBCON
  mov r1, #1
  lsl r1, r1, #10
	str r1, [r0]
 
  ldr r0, GPBDAT
  mov r1, #0
	str r1, [r0]
 
 

	mov sp, #0x1000 @set stack pointer to dram
	
	/* ldr r0, GPBCON
  mov r1, #1
  lsl r1, r1, #12
	str r1, [r0]
 
  ldr r0, GPBDAT
  mov r1, #0
	str r1, [r0]*/
	
	
	bl Main



loop:
	b loop


undef:
	b undef
	
swi:/*
	stmfd sp!,{r0-r12,lr,lr}
	mrs r0,spsr
	stmfd sp!,{r0}
	@save sp of current task'stack to OSTCBCur
	ldr r0,=OSTCBCur
	str sp, [r0]*/
/*	
	LDR R0,[LR,#-8]
	BIC R0,R0,#0xFF000000
	ldr	lr,[pc,#4]
	tst	R0,#0x1
*/
	/*BL	OSCtxSw
	@BEQ	OSCtxSw
	@BEQ swi_test
*/


abt_pre:
	b abt_pre
	
	
abt_data:
	b abt_data
	
	
irq:/*
	mov sp,#0x32000000
	stmfd sp!,{r0,r1}
	
  ldr r0, SRCPND
  ldr r1,[r0]
  orr r1,r1,#0x400
	str r1, [r0]
	ldr r0, INTPND
  ldr r1,[r0]
  orr r1,r1,#0x400
	str r1, [r0]
		
	ldr r0,=temp_spsr
	mrs r1,spsr
	str r1,[r0]
	ldr r0,=temp_lr
	mrs r1,spsr
	str r1,[r0]
	
	ldmfd sp!,{r0,r1}^ /* resotre r0,r1 and back to ori mode */

	/* back to ori mode */
	mrs lr,spsr
	msr cpsr,lr
	
	ldr lr,=temp_lr
	ldr lr,[lr]
	
	stmfd sp!,{lr,lr}
	stmfd sp!,{r0-r12}
	
	ldr r0,=temp_spsr
	ldr r0,[r0]
	stmfd sp!,{r0}
	
	ldr r0,=OSTCBCur
	str sp,[r0]
	
	/* back to irq mode */
	mrs r0,spsr
	msr cpsr,r0
		
	@bl irq_handler
	bl OSTickISR


	ldr r0,=OSTCBCur
	ldr sp,[r0]
	ldmfd sp!,{r0}
	msr spsr,r0
	ldmfd sp!,{r0-r12,lr,pc}^ /* restore reg and back to ori mode */
*/
	
	
fiq:
	b fiq




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