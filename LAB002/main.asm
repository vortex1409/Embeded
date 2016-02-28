#include "p18f45k20.inc"

Status_Temp	EQU 0x20
BSR_Temp	EQU 0x021
WREG_Temp	EQU 0x022
	
	org 0x0000
	goto GLEP
	org 0x0008
	goto HPIEP
	org 0x0018
	goto LPIEP
	
GLEP:
	call Initalize
	
Loop:
	sleep
	bra Loop
	
Initalize:
	bsf	OSCON, IDLEN, A
	clrf	LATD, A
	clrf	TRISD, A
	
	bsf	TRISB, RD0, A
	bcf	INTCON2, INTEDG0, A
	bcf	INTCON, INT0IE, A
	
	movlw	B'10000000'
	movwf	T0CON, A
	bsf	INTCON2, TMR0IP, A
	bsf	INTCON, TMR0IE, A
	bsf	RCON, IPEN, A
	
	bsf	INTCON, GIEL, A
	bsf	INTCON, GIEH, A
	
	return
	
HPIEP:
    movff	STATUS, STATUS_TEMP
    movff	BSR, BSR_TEMP
    movwf	WREG_TEMP, A
    
    btfsc	INTCON, TMR0IF, A
    call	Timer0ISR
    
    btfsc	INTCON, INT0IF, A
    call	Int0ISR
    
    movf	WREG_TEMP, w, A
    movff	BSR_TEMP, BSR
    movff	STATUS_TEMP, STATUS
    
    retfie
    
LPIEP:
    retfie
    
TImer0ISR:
    bcf		INTCON, TMR0IF, A
    call	Heartbeat
    
    return
    
Int0ISR:
    bcf		INTCON, Int0IF, A
    call	UpdateStatus
    
    return
    
Heartbeat:
    btg		LATD, RD0, A
    bcf		LATD, RD7, A
    
    return
    
UpdateStatus:
    bsf		LATD, RD7, A
    
    return
    
    end
