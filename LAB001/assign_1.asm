    #include "p18f45k20.inc"
    org	  0

  call	Initialize

Loop:
    
    call    UpdateStatus ; calls the update status function
    
    btfsc   INTCON, TMR0IF, A
    call    Heartbeat ; calls the heartbeat function
    bra	    Loop ; branches to the loop
    
Initialize: ; intitalize function
    
    clrf    LATD, A
    clrf    TRISD, A
    bsf	    TRISB, RB0, A
    movlw   B'10000011' ; affects the time interval at which the LED is on
    movwf   T0CON, A
    
    return
    
UpdateStatus: ; update status function
    
    btfsc   PORTB, RB0, A ; sets bit in PORTB
    bsf	    LATD, RD6, A ; turns LED7 on when the bit is set (button pressed)
    ;change RD7 to RD6 for LED 6
    
    btfss   PORTB, RB0, A ;clears bit in PORTB
    bcf	    LATD, RD6, A ;shuts off LED7 off when bit is cleared
    ;(button released)
    ;when btfsc and btfss are reversed for part 2 reverses button function
    
    return
    
Heartbeat: ;heartbeat function
    
    bcf	    INTCON, TMR0IF, A ; calls timer0
    
    btg	    LATD, RD0, A ;timer0 effects LED0
    
    return
    
    end ; ends program


