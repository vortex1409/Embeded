    #include "p18f45k20.inc"
    org	  0

    call    Initialize

Loop: ;Loop Function
    
    call    UpdateStatus ;Call Update Status Function
    btfsc   INTCON, TMR0IF, A
    call    Heartbeat ;Call Heartbeat Function
    bra	    Loop ;Branch to Loop
    
Initialize: ;Init Function
    
    clrf    LATD, A
    clrf    TRISD, A
    bsf	    TRISB, RB0, A
    ;movlw   B'10000000' ;Faster Hearbeat
    movlw   B'10001000' ;Quarter Second
    ;movlw   B'10000011' ;4.19 seconds
    movwf   T0CON, A
    
    return
    
UpdateStatus: ;Update Status Function
    
    ;btfss   PORTB, RB0, A ;Sets PORTB Bit
    btfsc   PORTB, RD0, A
    bsf	    LATD, RD6, A ;Turns on LED6 when pressed
    ;bsf	    LATD, RD7, A ;Turns on LED7 When Pressed
    
    ;btfsc   PORTB, RB0, A ;clears bit in PORTB
    btfss   PORTB, RD0, A
    bcf	    LATD, RD6, A ;TUrns off LED6 when released
    ;bcf	    LATD, RD7, A ;Turns off LED7 when released
    
    return
    
Heartbeat: ;heartbeat function
    
    bcf	    INTCON, TMR0IF, A ;Calls timer0
    btg	    LATD, RD0, A ;timer0 alters LED0
    
    return
    
    end
