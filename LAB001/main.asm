#include "p18F45K20.inc"
    org 0
    
    Start:	  		
        movlw	0x0FF		      ;Load the port pin types of RB
        movwf	TRISB,A		      ;Set RB ports to inputs
        movlw	0x000	 	      ;Set the port pin types of RD pins
        movwf	TRISD,A		      ;Set RD ports to outputs
    Main:
      	btfsc	PORTB,0
      	goto	Open
    Closed:
        movlw	0x0FF
	      movwf	LATD,A
	      goto	Main
    Open:
	      movlw	0x000
	      movwf	LATD,A
	      goto	Main
    end
