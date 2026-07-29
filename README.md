# Porting uCOS2 OS onto Friendly ARM Tiny2440(Samsung s3c2440 SOC)



## 說明:

    此系統開發過程中無依賴任何ARM IDE，例如: ADS

    目的是為了深入了解開發過程所牽涉到的技術，避免因IDE將細節屏蔽，導致知其然不知其所以然，故我選擇從0開始移植uCOS2 Real Time OS到Friendly ARM Tiny2440開發板。此外，這個系統除了OS以外，所有程式碼皆由我一個人獨力完成。

    須完成的工作主要分為以下部分:

        1. 開發Bootcode, Bootloader

        2. 移植uCOS2到ARM開發板上

        3. 撰寫Makefile和Link script  

        4. SDRAM init，NAND Flash driver，CPU init，MMU init，Code Relocation


## 系統組成架構:

    硬體:

        開發板: Friendly ARM Tiny2440

        CPU: SAMSUNG s3c2440

    軟體:

        uCOS2 Real-Time OS


## 使用的軟體工具:

    Toolchain: ARM Linux GCC

    編譯環境: Linux ubuntu 2.6.32-24-generic i686

    程式編輯器: Source Insight 3.5

## 開發工作階段:
- 熟悉硬體特性
- 熟悉uSOS2特性
- 架設開發平台
- Coding
- 開發過程細節說明:
- 熟悉硬體特性
- 熟悉uSOS2特性
- 依據記憶體配置，寫Link Script
- 根據所有Source Code寫Makefile做自動化編譯
- 針對uCOS2的移植層，加入CPU相關的程式碼，共有三個檔案:

        OS_CPU.H

        OS_CPU_A.S

        OS_CPU_C.C


## 開發項目:

- 一開始必須寫bootcode，來啟動CPU及周邊的初始化
- 接著移植 OS_CPU_A.ASM的API如下:

        OSTickISR

        OSStartHighRdy

        OSCtxSw

        OSIntCtxSw

        OSCPUSaveSR

        OSCPURestoreSR

- 開發前分析:

- s3c2440:
- 內部有一4K SRAM
- 一上電，CPU裡的Flash Controller會自動將nand flash前4k copy到SRAM。
- 問題發現1:

        我寫的Code超過4K，並燒到Flash，而CPU只會COPY 4K。

        解決方式: 將程式做Relocation

        (1) 在4K範圍內將SDRAM initial做好，並將全部的code從Flash複製到SDRAM去。

        (2) 複製完後，跳轉到SDRAM去執行遇到問題:

        在4K執行期間遇到CPU exception !

- 問題發現2:

        跳轉到SDRAM去執行時遇到CPU exception

        原因:

            因Link Address為SDRAM的位址，故在function call或變數參考到錯誤的address

        解決方式:

            將4K內的code寫成 PIC (Position Independent Code)

- Disable Watch Dog
- 初始化SDRAM

- ARM架構分析:

    ARM有以下幾種Exception:(發生特定事件時,CPU會跳到對應的

    Address去run，並同時CPU會切換到特定mode)

    Exception Vectors:

    &nbsp; Address &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Exception &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Mode in Entry

    \----------- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--------------------- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;------------------

    0x00000000 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Reset &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Supervisor

    0x00000004 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Undefined &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;instruction Undefined

    0x00000008 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Software Interrupt &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Supervisor

    0x0000000C &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Abort (prefetch) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Abort

    0x00000010 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Abort (data) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Abort

    0x00000014 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Reserved &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Reserved

    0x00000018 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;IRQ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;IRQ

    0x0000001C &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;FIQ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;FIQ



- 開發過程說明：

        OSTickISR:

            此API用來做整個系統的計時:

            stmfd sp!,{lr} // 將當前Task的狀態存在Stack

            bl OSIntEnter // 計算巢狀中斷次數

            bl OSTimeTick // 累積系統計數(一個tick是10ms)

            bl OSIntExit // 離開時需要判斷，是否有高Priority TaskReady

            ldmfd sp!,{lr} // 自Stack取出data，回復中斷前 Task的狀態

            mov pc,lr

            此API使用Timer每10ms中斷一次，設成10ms避免影響 CPU效能。


        OSStartHighRdy:

            這個function只會被呼叫一次，即OS啟動之初用來啟動 Priority最高的Task。


        OSCtxSw:

            做Context Switch的工作:

            先將當前被Premptive的Task的Registers值存到自己的PCB，接著再將要執行的Task的Process Control Block裡的值逐一放到 暫存器。


        OSIntCtxSw:

            做Context Switch的工作:

            與OSCtxSw類似，但這是發生在Interrupt時所呼叫的。

            將當前被Premptive的Task的Registers值存到自己的PCB 。


        OSCPUSaveSR:

            將CPU切換到Supervisor Mode


        OSCPURestoreSR:

            將CPU回復道原來到Mode


- 成果測試:

        (1) 建立了三個Task

        (2) 並彼此傳遞Message，分別採用block和noblock的方式

        (3) 三個Task能正常的做Context Switch

        (4) OS的Wait(Idle功能OK

        (5) UART能印出訊息