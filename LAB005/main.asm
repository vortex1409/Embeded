#include "p18F45K20.inc"

_SYSF_TICK	EQU	    0
_SYSF_DA	EQU	    1
_TC_HEARTBEAT	EQU	    D'???'

		udata_acs   0x000
	
HPI_CONTEXT	res	    3
LPI_CONTEXT	res	    3
SYSFLAGS	res	    1
HEARTBEAT	res	    1
ADATA		res	    2
		
RSTV		code	    0x0
		goto	    GLEP
HPIV		code	    0x8
		goto	    HPIEP
LPIV		code	    0x18
		goto	    LPIEP
		
HPIEP: 
    movff   STATUS,HPI_CONTEXT+0
    movff   BSR,HPI_CONTEXT+1
    movwf   HPI_CONTEXT+2,A
    
    btfsc   INTCON,TM0IF,A
    call    Timer0ISR
    
    movf    HPI_CONTEXT+2,W,A
    movff   HPI_CONTEXT+1,BSR
    movff   HPI_CONTEXT+0,STATUS
LPIEP:
    movff   STATUS,LPI_CONTEXT+0
    movff   BSR,LPI_CONTEXT+1
    movwf   LPI_CONTEXT+2,A
    
    btfsc   PIR1,ADIF,A
    call    AnalogISR
    
    movf    LPI_CONTEXT+2,W,A
    movff   LPI_CONTEXT+1,BSR
    movff   LPI_CONTEXT+0,STATUS    
Timer0ISR:
    bcf	    INTCON,TMR0IF,A
    bsf	    SYSFLAGS,_SYSF_TICK,A
    return 
AnalogISR:
    bcf	    PIR1,ADIF,A
    bsf	    SYSFLAGS,_SYSF_DA,A
    movff   ADRESL,ADATA+0
    movff   ADRESH,ADATA+1
    bsf	    ADCON0,GO,A
    return
Initialize:
    movlw   0x70
    iorwf   OSCCON,F,A
    bsf	    OSCTUNE,PLLEN,A
    clrf    PORTD,A
    clrf    TRISD,A
    bcf	    PORTC,RC7,A
    bcf	    TRISC,RC7,A
    movlw   0x88
    movwf   T0CON,A
    bsf	    INTCON2,TM0IP,A
    bsf	    INTCON,TM0IE,A
    call    AnalogInit
    clrf    SYSFLAGS,A
    bsf	    RCON,IPEN,A
    bsf	    INTCON,GIEL,A
    bsf	    INTCON,GIEH,A
    return
AnalogInit:
    bsf	    TRISA,RA0,A
    bsf	    ANSEL,ANS0,A
    movlw   0x3E
    movwf   ADCON2,A
    clrf    ADCON1,A
    movlw   0x01
    movwf   ADCON0,A
    bcf	    PORTC,RC0,A
    bcf	    PORTC,RC1,A
    bcf	    TRISC,RC0,A
    bcf	    TRISC,RC1,A
    bcf	    IPR1,ADIP,A
    bcf	    IPR1,ADIE,A
    bsf	    ADCON0,,GO,A
    return
GLEP:
    call    Initialize
GLEPLoop:
    btfsc   SYSFLAGS,_SYSF_TICK,A
    call    SysTickHandler
    btfsc   SYSFLAGS,_SYSF_DA,A
    call    AnalogHandler
    bra	    GLEPLoop
SysTickHandler:
    bcf	    SYSFLAGS,SYSF_TICK,A
    decfsz  HEARTBEAT,F,A
    bra	    SysTickHandlerDone
    btg	    LATC,RC7,A
    movlw   _TC_HEARTBEAT
    movwf   HEARTBEAT,A
SysTickHandlerDone:
    return
AnalogHandler:
    bcf	    SYSFLAGS,_SYSF_DA
    movff   ADATA+1,LATD
    movlw   0xFc
    andwf   LATC,F,A
    movf    ADATA,W,A
    rlncf   WREG,A
    rlncf   WREG,A
    andlw   0x03
    iorwf   LATC,F,A
    return
