
    #include "p18F45K20.inc"
    org 0
    
Start:	  		
        movlw 0x0FF		      ;Load the port pin types of RB
        movwf TRISB		      ;Set RB ports to inputs
        movlw 0x000	 	      ;Set the port pin types of RD pins
        movwf TRISD		      ;Set RD ports to outputs

MainLoop:
        btfsc PORTB,0	      ;Read RB0 pin (the button - is active lo)
        goto  Button_Open	  ;If RB0 is '0', skip this and goto Button_Closed
    
Button_Closed:
        bsf  PORTD,0	;Set RD0 output
        bsf  PORTD,1	;Set RD1 output
        bsf  PORTD,2	;Set RD2 output
        bsf  PORTD,3	;Set RD3 output
        bsf  PORTD,4	;Set RD4 output
        bsf  PORTD,5	;Set RD5 output
        bsf  PORTD,6	;Set RD6 output
        bsf  PORTD,7	;Set RD7 output
        goto MainLoop
    
Button_Open:
        bcf  PORTD,0	;Clear RD0 output
        bcf  PORTD,1	;Clear RD1 output
        bcf  PORTD,2	;Clear RD2 output
        bcf  PORTD,3	;Clear RD3 output
        bcf  PORTD,4	;Clear RD4 output
        bcf  PORTD,5	;Clear RD5 output
        bcf  PORTD,6	;Clear RD6 output
        bcf  PORTD,7	;Clear RD7 output
        goto MainLoop
    
    end
