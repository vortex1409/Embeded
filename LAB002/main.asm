#include "p18f45k20.inc"

STATUS_TEMP	EQU 0x020 ; Equate STATUS_TEMP to 20h
BSR_TEMP	EQU 0x021 ; Equate BSR_TEMP to 21h
WREG_TEMP	EQU 0x022 ; Equate WREG_TEMP to 22h
	
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
	bsf	OSCCON, IDLEN, A
	;bcf	OSCCON, IDLEN, A ; Part 4
	clrf	LATD, A
	clrf	TRISD, A
	
	bsf	TRISB, RD0, A
	bcf	INTCON2, INTEDG0, A ;  Part ? Falling Edge Trigger
	;bcf	INTCON2, INTEDG1, A ;Part 3 Rusing Edge Trigger
	bsf	INTCON, INT0IE, A ; bsf
	
	movlw	B'10000010' ; 2 Second On/Off pulse
	;movlw   B'10000000' ;Faster Hearbeat
	;movlw   B'10001000' ;Quarter Second
	;movlw   B'10000011' ;4.19 seconds
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
    
    movf	WREG_TEMP, W, A
    movff	BSR_TEMP, BSR
    movff	STATUS_TEMP, STATUS
    
    retfie
    
LPIEP:
    retfie
    
Timer0ISR:
    bcf		INTCON, TMR0IF, A
    call	Heartbeat
    
    return
    
Int0ISR:
    bcf		INTCON, INT0IF, A
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
