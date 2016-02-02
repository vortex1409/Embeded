#include "p18F45K20.inc"

    org	    0
    
    movf    0x022,0,0
    subwf   0x020,0,0
    movwf   0x024,0
    movf    0x023,0,0
    subwfb  0x021,0,0
    movwf   0x025
    
    bra	    $
    
    end
