#include "p18F45K20.inc"

    org	    0
    
SETPOINT    EQU H'030'
GAIN	    EQU	H'031'
SPAN	    EQU	H'040'
	    
clrf    0x030,0
comf    SETPOINT,1,0
bcf	0x030,2,0
bcf	SETPOINT,1,0
movf    0x030,0,0
andlw   0x9F
movwf   SETPOINT,0
	    
movlw   0x5A
iorlw   0x05
movwf   D'64',0
	    
movlw   0xDB
movwf   0x031,0
btfss   0x031,4,0
addlw   2
addlw   1
movwf   GAIN,0
    
    bra	    $
    
    end
