#include "p18f45k20.inc"

_SYSF_TICK	EQU	    0
_TC_HEARTBEAT   EQU	    D'61'
_TC_RELAY	EQU	    D'488'
	
		udata_acs   0x020

SYSFLAGS	res	    1
HBCTR		res	    1
RLYCTR		res	    2
HPI_CONTEXT	res	    3
LPI_CONTExT	res	    3

RSTV		code	    0x0
		goto	    GLEP
HPIV		code	    0x8
		goto	    HPIEP
LPIV		code	    0x18
		goto	    LPIEP

GLEP:
		call	    Initialize
GLEPLoop:
		btfsc	    SYSFLAGS, SYSF_TICK,A
		call	    SysTickHandler
		bra	    GLEPLoop

Initialize:
		; Increase System Clock to 64 MHz
		movlw	    0x070
		iorwf	    OSCON,F,A
		bsf	    OSCTUNE,PLLEN,A
		
		; Configure LED Interface
		clrf	    LATD,A
		clrf	    TRISD,A
		
		; Configure External Signals
		clrf	    LATC,A
		movlw	    0xCF
		movwf	    TRISC,A
		
		; Configure SW1 Interface
		bsf	    TRISB,RB0,A
		bcf	    INTCON2,INTEDG0,A
		bsf	    INTCON,INT0IE,A
		
		; Configure Timer0
		movlw	    0x88
		movwf	    T0CON,A
		bsf	    INTCON2,TMR0IP,A
		bsf	    INTCON,TMR0IE,A
		
		; Clear System Flags
		clrf	    SYSFLAGS,A
		
		; Load HBCTR (Heartbeat Counter)
		movlw	    _TC_HEARTBEAT
		movwf	    HBCTR,A
		
		; Clear RLYCTR (Relay Counter
		clrf	    RLYCTR+0,A
		clrf	    RLYCTR+1,A
		
		; Enable Interupts
		bsf	    RCON,IPEN,A
		bsf	    INTCON,GIEL,A
		bsf	    INTCON,GIEH,A
		
		; Return
		return
SysTickHandler:
		; Clear Tick Flag
		bcf	    SYSFLAGS,_SYSF_TICK,A
SysTickHandlerHeartbeat:
		decfsz	    HBCTR,F,A
		bra	    SysTickHandlerRelay
		
		btg	    LATD,RD0,A
		btg	    LATC,RC5,A ; Toggles External LED
		
		movlw	    _TC_HEARTBEAT
		movwf	    HBCTR,A
SysTickHandlerRelay:
		movf	    RLYCTR+0,W,A
		iorwf	    RLYCTR+1,W,A
		bz	    SysTickHandlerDone
		
		; Decrement a 2 byte variable
		movf	    FLYCTR+0,F,A
		btfsc	    STATUS,Z,A
		decf	    RLYCTR+1,F,A
		decF	    RLYCTR+0,F,A
		
		movf	    RLYCTR+0,W,A
		iorwf	    RLYCTR+1,W,A
		bnz	    SysTickHandlerDone
		
		bcf	    LATD,RD7,A
		bcf	    LATC,RC4,A
SysTickHandlerDone:
		return

HPIEP:
		movff	    STATUS,HPI_CONTEXT+0
		movff	    BSR,HPI_CONTEXT+1
		movwf	    HPI_CONTEXT+2,A
		
		btfsc	    INTCON,TMR0IF,A
		call	    Timer0ISR
		
		btfsc	    INTCON,INT0IF,A
		call	    Int0ISR
		
		movf	    HPI_CONTEXT+2,W,A
		movff	    HPI_CONTEXT+1,BSR
		movff	    HPI_CONTEXT+0,STATUS
		
		retfie
LPIEP:
		retfie

Timer0ISR:
		bcf	    INTCON,TMR0IF,A
		bsf	    SYSFLAGS,_SYSF_TICK,A
		return

Int0ISR:
		bcf	    INTCON,INT0IF,A
		
		; Load RLYCTR (High)
		movlw	    low _TC_RELAY
		movwf	    RLYCTR+0,A
		; Low
		movlw	    high _TC_RELAY
		movwf	    RLYCTR+1,A
		
		; Energize the Relay
		bsf	    LATD,RD7,A
		bsf	    LATC,RC4,A
		
		return

    end
