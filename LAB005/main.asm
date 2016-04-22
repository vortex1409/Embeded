		#include "p18f45k20.inc"

; System T|ick Bit
_SYSF_TICK	EQU	    0

; Data Available Bit
_SYSF_DA	EQU	    1

; Heartbeat Tick Count
_TC_HEARTBEAT   EQU	    D'244'
   
		udata_acs   0x000
		
; High Priority Interrupt Context Save
HPI_CONTEXT	res	    3

; Low Priority Interrupt Context Save
LPI_CONTEXT	res	    3

; System Flags
SYSFLAGS	res	    1

; Heartbeat Counter	
HBCTR		res	    1

; Analog Data		
ADATA		res	    2

; Reset Vector		
RSTV		code	    0x0000
		goto	    GLEP
		
; High Priority Interrupt Vector
HPIV		code	    0x0008
		goto	    HPIEP
		
; Low Priority Interrupt Vector
LPIV		code	    0x0018
		goto	    LPIEP

; ======================================================
; High Priority Interrupt Execution Path
; The high priority interupt execution
; path executes the high priority
; interupts such as moving context bits
; setting the interupt flags and moving
; status bits.
HPIEP:
		movff	    STATUS,HPI_CONTEXT+0
		movff	    BSR,HPI_CONTEXT+1
		movwf	    HPI_CONTEXT+2,A
		
		btfsc	    INTCON,TMR0IF,A
		call	    Timer0ISR
		
		movf	    HPI_CONTEXT+2,W,A
		movff	    HPI_CONTEXT+1,BSR
		movff	    HPI_CONTEXT+0,STATUS
		
		retfie
		
; ======================================================
; Low Priority Interrupt Execution Path
; The Low Priority Interupt Execution Path Stores the
; bit context from STATUS and BSR and sends it 
; to AnalogISR before restoring it for the next cycle
LPIEP:
		movff	    STATUS,LPI_CONTEXT+0
		movff	    BSR,LPI_CONTEXT+1
		movwf	    LPI_CONTEXT+2,A
    
		btfsc	    PIR1,ADIF,A
		call	    AnalogISR
    
		movf	    LPI_CONTEXT+2,W,A
		movff	    LPI_CONTEXT+1,BSR
		movff	    LPI_CONTEXT+0,STATUS  
    
		retfie

; ======================================================
; Timer0 Interrupt Service Routine
; The timer interupt service routine clears
; the interupt flag register of INTCON
; and sets the system tick bit of 
; SYSFLAGS and returns 
Timer0ISR:
		bcf	    INTCON,TMR0IF,A
		bsf	    SYSFLAGS,_SYSF_TICK,A
		return

; ======================================================
; Analog Interrupt Service Routine
; The AnalogISR acknowledges interupts, sets the ADATA
; bit and moves upper and lower bits using the
; ADRESL/ADRESH operators to set the ADCON register
; to operate.
AnalogISR:
		bcf	    PIR1,ADIF,A
		bsf	    SYSFLAGS,_SYSF_DA,A
		
		movff	    ADRESL,ADATA+0
    		movff	    ADRESH,ADATA+1
		
		bsf	    ADCON0,GO,A
    
		return
    
; ======================================================
; Initialize Routine
Initialize:
		;Configure SYstem Clock to 64 MHz
		movlw	    0x70
		iorwf	    OSCCON,F,A
		bsf	    OSCTUNE,PLLEN,A
		
		; Configure LED Interface
		clrf	    LATD,A
		clrf	    TRISD,A
		
		; Configure External Signals
		bcf	    LATC,RC7,A
		bcf	    TRISC,RC7,A
    
		; Configure Timer0
		movlw	    0x88
		movwf	    T0CON,A
		bsf	    INTCON2,TMR0IP,A
		bsf	    INTCON,TMR0IE,A
		
		; Initialize the AnalogInit Subroutine
		call	    AnalogInit
    
		; Clear System Flags
		clrf	    SYSFLAGS,A
    
		; Enable Interupts
		bsf	    RCON,IPEN,A
		bsf	    INTCON,GIEL,A
		bsf	    INTCON,GIEH,A
    
		; Return
		return		

; ======================================================
; Analog Initialization
AnalogInit:
		; Configure Analog I/O Ports
		bsf	    TRISA,RA0,A
		bsf	    ANSEL,ANS0,A
    
		; Configure Analog to Digital Converter
		movlw	    0x3B
		movwf	    ADCON2,A
    
		clrf	    ADCON1,A
    
		movlw	    0x01
		movwf	    ADCON0,A
    
		; Configure ADC External LED's
		bcf	    LATC,RC0,A
		bcf	    LATC,RC1,A
		bcf	    TRISC,RC0,A
		bcf	    TRISC,RC1,A
		
		; Configure ADC Interrupts
		bcf	    IPR1,ADIP,A
		bsf	    PIE1,ADIE,A
    
		; Start Analog to Digital Converter
		bsf	    ADCON0,GO,A
    
		return
		
; ======================================================
; Ground Level Execution Path
GLEP:
		call	    Initialize

; ======================================================
; Ground Level Execution Path Loop
; GLEPLoop handles the logic of the System Flag Ticks
; When SYSF_TICK is 1 it calls the SysTickHandler
; When SYSF_DA is 1 it calls the AnalogHandler
; When Neither condition is met loop to beginning
GLEPLoop:
		btfsc	    SYSFLAGS, _SYSF_TICK,A
		call	    SysTickHandler
		
		btfsc	    SYSFLAGS,_SYSF_DA,A
		call	    AnalogHandler
    
		; Branch to beginning of subroutine
		bra	    GLEPLoop
		    
; ======================================================
; System Tick Handler
SysTickHandler:
		bcf	    SYSFLAGS,_SYSF_TICK,A
		decfsz	    HBCTR,F,A
		bra	    SysTickHandlerDone
    
		btg	    LATC,RC7,A
		movlw	    _TC_HEARTBEAT
		movwf	    HBCTR,A
							
; ======================================================
; Tick Handler Done
SysTickHandlerDone:
		return

; ======================================================
; Analog Handler
; The Analog Handler handles the clearing of the 
; ADATA flag as well as moving analog data to the 
; LATD register
AnalogHandler:
		bcf	    SYSFLAGS,_SYSF_DA,A
    
		movff	    ADATA+1,LATD
    
		movlw	    0xFC
		andwf	    LATC,F,A
		movf	    ADATA+0,W,A
		rlncf	    WREG,A
		rlncf	    WREG,A
		andlw	    0x03
		iorwf	    LATC,F,A
    
		return

; ======================================================
    end
