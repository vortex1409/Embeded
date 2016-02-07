movf    0x03C,0,0 ; Move contents of 3Ch to WREG
addwf   0x03D,0,0 ; Add contents of 3Dh to WREG
addwf   0x03E,0,0 ; Add contents of 3Eh to WREG
movwf   0x03F,0,0 ; Take content of WREG and place it in 3Fh
