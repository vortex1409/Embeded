#include    "p18f45k20.inc"
_SYSF_TICK EQU     0
_SYSF_DA EQU     1
_SYSF_MC EQU     2
_TC_HEARTBEAT EQU     D'61'
  
    udata_acs   0x000
    
HPI_CONTEXT RES 3
LPI_CONTEXT RES 3
SYSFLAGS RES 1
HEARTBEAT RES 1
ADATA  RES 2
   
RSTV  CODE 0X0000
   GOTO GLEP
HPIV  CODE 0X0008
   GOTO HPIEP
LPIV  CODE 0X0018
   GOTO LPIEP
    
HPIEP:     
     
     MOVFF   STATUS,HPI_CONTEXT+0
     MOVFF   BSR,HPI_CONTEXT+1
     MOVWF   HPI_CONTEXT+2,A
     
     BTFSC   INTCON,TMR0IF,A
     CALL    Timer0ISR
     
     MOVF    HPI_CONTEXT+2,W,A
     MOVFF   HPI_CONTEXT+1,BSR
     MOVFF   HPI_CONTEXT+0,STATUS
     
     RETFIE
     
LPIEP:
     
     MOVFF   STATUS,LPI_CONTEXT+0
     MOVFF   BSR,LPI_CONTEXT+1
     MOVWF   LPI_CONTEXT+2,A
     
     BTFSC   PIR1,ADIF,A
     CALL    AnalogISR
     
     MOVF    LPI_CONTEXT+2,W,A
     MOVFF   LPI_CONTEXT+1,BSR
     MOVFF   LPI_CONTEXT+0,STATUS
     
     RETFIE
     
Timer0ISR:
     
     BCF     INTCON,TMR0IF,A
     BSF     SYSFLAGS,_SYSF_TICK,A
     RETURN
     
AnalogISR:
     
     BCF     PIR1,ADIF,A
     BSF     SYSFLAGS,_SYSF_DA,A
     
     MOVFF   ADRESL,ADATA+0
     MOVFF   ADRESH,ADATA+1
     
     RETURN
    
Initialize:
     
     MOVLW   0X70
     IORWF   OSCCON,F,A
     BSF     OSCTUNE,PLLEN,A
    
     CALL   SysTickInit
     
     CALL    AnalogInit
     
     CALL   MotorInit
     
     CLRF    SYSFLAGS,A
     
     BSF     RCON,IPEN,A
     BSF     INTCON,GIEL,A
     BSF     INTCON,GIEH,A
     
     RETURN
     
SysTickInit:
    
     BCF    LATC,RC7,A
     BCF    TRISC,RC7,A
     
     MOVLW  0X88
     MOVWF  T0CON,A
     
     BSF    INTCON2,TMR0IP,A
     BSF    INTCON,TMR0IE,A
     
     RETURN
     
AnalogInit:
     
     BSF     TRISA,RA0,A
     BSF     ANSEL,ANS0,A
     
     CLRF   LATD,A
     CLRF   TRISD,A
     MOVLW  0XCF
     ANDWF  LATC,F,A
     ANDWF  TRISC,F,A
     
     MOVLW   0X3E
     MOVWF   ADCON2,A
     
     CLRF    ADCON1,A
     
     MOVLW   0X01
     MOVWF   ADCON0,A
     
     BCF     IPR1,ADIP,A
     BSF     PIE1,ADIE,A
     
     BSF     ADCON0,GO,A
     
     RETURN
     
MotorInit:
    
    MOVLW   0XF0
    ANDWF   LATC,F,A
    ANDWF   TRISC,F,A
    
    CLRF    T2CON,A
    MOVLW   D'127'
    MOVWF   PR2,A
    BSF     T2CON,TMR2ON,A
    
    CLRF    CCPR1L,A
    MOVLW   0X0C
    MOVWF   CCP1CON,A
    
    RETURN
     
GLEP:
     
     CALL    Initialize
     
GLEPLoop:
     
     BTFSC   SYSFLAGS,_SYSF_TICK,A
     CALL    SysTickHandler
     
     BTFSC   SYSFLAGS,_SYSF_DA,A
     CALL    AnalogHandler
     
     BTFSC  SYSFLAGS,_SYSF_MC,A
     CALL   MotorHandler
     
     BRA     GLEPLoop
     
SysTickHandler:
     
     BCF     SYSFLAGS,_SYSF_TICK,A
     DECFSZ  HEARTBEAT,F,A
     BRA     SysTickHandlerDone
     
     BTG     LATC,RC7,A
     MOVLW   _TC_HEARTBEAT
     MOVWF   HEARTBEAT,A
     
SysTickHandlerDone:
     
     RETURN
     
AnalogHandler:
     
     BCF     SYSFLAGS,_SYSF_DA
     
     MOVFF   ADATA+1,LATD
     
     MOVLW   0XCF
     ANDWF   LATC,F,A
     MOVF    ADATA+0,W,A
     RRNCF   WREG,A
     RRNCF   WREG,A
     ANDLW   0X30
     IORWF   LATC,F,A
     
     BSF    SYSFLAGS,_SYSF_MC,A
     
     RETURN
     
MotorHandler:
     
     BCF    SYSFLAGS,_SYSF_MC,A
     btfsc  ADATA+1,7,A
     BRA    MotorHandlerCW
MotorHandlerCCW:
     
     BCF    LATC,RC1,A
     BSF    LATC,RC0,A
     
     COMF   ADATA+1,F,A
     COMF   ADATA+0,F,A
     BRA    MotorHandlerSetSpeed
     
MotorHandlerCW:
     
     BCF    LATC,RC0,A
     BSF    LATC,RC1,A
     
MotorHandlerSetSpeed:
     BSF    LATC,RC3
     BCF    ADATA+1,7,A
     RRNCF  ADATA+0,F,A
     RRNCF  ADATA+0,W,A
     ANDLW  0X30
     BCF    CCP1CON,DC1B1,A
     BCF    CCP1CON,DC1B0,A
     IORWF  CCP1CON,A
     MOVFF  ADATA+1,CCPR1L
     
     BSF    ADCON0,GO,A
     RETURN
     
     END​
