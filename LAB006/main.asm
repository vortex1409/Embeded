		#include "p18f45k20.inc"

_SYSF_TICK	EQU	    0
_SYSF_DA	EQU	    1
_SYSF_MC	EQU	    2
_TC_HEARTBEAT	EQU	    D'61'
  
                udata_acs   0x000
    
HPI_CONTEXT	res	    3
LPI_CONTEXT	res	    3
SYSFLAGS	res	    1
HEARTBEAT	res	    1
ADATA		res	    2
   
RSTV		code	    0X0000
		goto	    GLEP
HPIV		code	    0X0008
		goto	    HPIEP
LPIV		code	    0X0018
		goto	    LPIEP
    
HPIEP:     
     
		movff	    STATUS,HPI_CONTEXT+0
		movff	    BSR,HPI_CONTEXT+1
		movwf	    HPI_CONTEXT+2,A
     
		btfsc	    INTCON,TMR0IF,A
		call	    Timer0ISR
     
		movf	    HPI_CONTEXT+2,W,A
		movff	    HPI_CONTEXT+1,BSR
		movff	    HPI_CONTEXT+0,STATUS
     
		retfie
     
LPIEP:
     
		movff	    STATUS,LPI_CONTEXT+0
		movff	    BSR,LPI_CONTEXT+1
		movwf	    LPI_CONTEXT+2,A
     
		btfsc	    PIR1,ADIF,A
		call	    AnalogISR
     
		movf	    LPI_CONTEXT+2,W,A
		movff	    LPI_CONTEXT+1,BSR
		movff	    LPI_CONTEXT+0,STATUS
     
		retfie
     
Timer0ISR:
     
		bcf	    INTCON,TMR0IF,A
		bsf	    SYSFLAGS,_SYSF_TICK,A
		
		return
     
AnalogISR:
     
		bcf	    PIR1,ADIF,A
		bsf	    SYSFLAGS,_SYSF_DA,A
     
		movff	    ADRESL,ADATA+0
		movff	    ADRESH,ADATA+1
     
		return
    
Initialize:
     
		movlw	    0X70
		iorwf	    OSCCON,F,A
		bsf	    OSCTUNE,PLLEN,A
    
		call	    SysTickInit
     
		call	    AnalogInit
     
		call	    MotorInit
     
		clrf	    SYSFLAGS,A
     
		bsf	    RCON,IPEN,A
		bsf	    INTCON,GIEL,A
		bsf	    INTCON,GIEH,A
     
		return
     
SysTickInit:
    
		bcf	    LATC,RC7,A
		bcf	    TRISC,RC7,A
     
		movlw	    0X88
		movwf	    T0CON,A
     
		bsf	    INTCON2,TMR0IP,A
		bsf	    INTCON,TMR0IE,A
     
		return
     
AnalogInit:
     
		bsf	    TRISA,RA0,A
		bsf	    ANSEL,ANS0,A
     
		clrf	    LATD,A
		clrf	    TRISD,A
		movlw	    0XCF
		andwf	    LATC,F,A
		andwf	    TRISC,F,A
     
		movlw	    0X3E
		movwf	    ADCON2,A
     
		clrf	    ADCON1,A
     
		movlw	    0X01
		movwf	    ADCON0,A
     
		bcf	    IPR1,ADIP,A
		bsf	    PIE1,ADIE,A
     
		bsf	    ADCON0,GO,A
     
		return
     
MotorInit:
    
		movlw	    0XF0
		andwf	    LATC,F,A
		andwf	    TRISC,F,A
    
		clrf	    T2CON,A
		movlw	    D'127'
		movwf	    PR2,A
		bsf	    T2CON,TMR2ON,A
    
		clrf	    CCPR1L,A
		movlw	    0X0C
		movwf	    CCP1CON,A
    
		return
     
GLEP:
     
		call	    Initialize
     
GLEPLoop:
     
		btfsc	    SYSFLAGS,_SYSF_TICK,A
		call	    SysTickHandler
     
		btfsc	    SYSFLAGS,_SYSF_DA,A
		call	    AnalogHandler
     
		btfsc	    SYSFLAGS,_SYSF_MC,A
		call	    MotorHandler
     
		bra	    GLEPLoop
     
SysTickHandler:
     
		bcf	    SYSFLAGS,_SYSF_TICK,A
		decfsz	    HEARTBEAT,F,A
		bra	    SysTickHandlerDone
     
		btg	    LATC,RC7,A
		movlw	    _TC_HEARTBEAT
		movwf	    HEARTBEAT,A
     
SysTickHandlerDone:
     
		return
     
AnalogHandler:
     
		bcf	    SYSFLAGS,_SYSF_DA
     
		movff	    ADATA+1,LATD
     
		movlw	    0XCF
		andwf	    LATC,F,A
		movf	    ADATA+0,W,A
		rrncf	    WREG,A
		rrncf	    WREG,A
		andlw	    0X30
		iorwf	    LATC,F,A
     
		bsf	    SYSFLAGS,_SYSF_MC,A
     
		return
     
MotorHandler:
     
		bcf	    SYSFLAGS,_SYSF_MC,A
		btfsc	    ADATA+1,7,A
		bra	    MotorHandlerCW
MotorHandlerCCW:
     
		bcf	    LATC,RC1,A
		bsf	    LATC,RC0,A
     
		comf	    ADATA+1,F,A
		comf	    ADATA+0,F,A
		bra	    MotorHandlerSetSpeed
     
MotorHandlerCW:
     
		bcf	    LATC,RC0,A
		bsf	    LATC,RC1,A
     
MotorHandlerSetSpeed:
		bsf	    LATC,RC3,A
		bcf	    ADATA+1,7,A
		rrncf	    ADATA+0,F,A
		rrncf	    ADATA+0,W,A
		andlw	    0X30
		bcf	    CCP1CON,DC1B1,A
		bcf	    CCP1CON,DC1B0,A
		iorwf	    CCP1CON,A
		movff	    ADATA+1,CCPR1L
     
		bsf	    ADCON0,GO,A
		return
     
        end
