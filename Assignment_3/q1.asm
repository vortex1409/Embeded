movlw 0x012 ;Load 12h into WREG
addwf 0x02C,1,0 ;Add WREG to 2Ch
addwf 0x02E,1,0 ;Add WREG to 2Eh
addwf 0x03C,1,0 ;Add WREG to 3Ch
