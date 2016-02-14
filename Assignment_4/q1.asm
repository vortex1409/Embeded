; Moves 5 to Working Register
movlw   0x5

; Subtract contents of WREG from f 0x03C
subwf   0x03C,1,0

; Subtracks contents of WREG from f 0x030
subwf   0x030,1,0

; Subtracts contents of WREG from f 0x03E
subwf   0x03E,1,0
