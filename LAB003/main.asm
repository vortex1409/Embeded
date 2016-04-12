#include "p18f45k20.inc"

_SYSF_TICK	EQU	    0
_TC_HEARTBEAT   EQU	    D'61'
_TC_RELAY	EQU	    D'488'

		udata_acs   0x020
		
; Setting variables
SYSFLAGS	res	    1
HBCTR		res	    1
RLYCTR		res	    2
HPI_CONTEXT	res	    3
LPI_CONTExT	res	    3

;///////////////////////////////////////////////////////////
		; Placing routines at specified locations
		; in flash memory
RSTV		code	    0x0
		goto	    GLEP
HPIV		code	    0x8
		goto	    HPIEP
LPIV		code	    0x18
		goto	    LPIEP
		
;///////////////////////////////////////////////////////////
;		; The ground level execution path calls the
		; Initialize routine for execution
GLEP:
		call	    Initialize
		
;///////////////////////////////////////////////////////////
		; The GLEP Loop checks to see if the system
		; flag is set and then increments the sys
		; tick and calls the tick handler
GLEPLoop:
		btfsc	    SYSFLAGS, _SYSF_TICK,A
		call	    SysTickHandler
		
		; When sleep is activated the CPU uses
		; signifigantly less power
		Sleep
		
		bra	    GLEPLoop
		
;///////////////////////////////////////////////////////////
		; The initialize routine sets the clock
		; speed, configures the I/O ports as well
		; as enabling interupts and setting/clearning
		; bits.
Initialize:
		; Increase System Clock to 64 MHz
		; The clock speed had to be increased to 
		; allow actions to be completed within a 
		; two second interval
		movlw	    0x070
		iorwf	    OSCCON,F,A
		bsf	    OSCTUNE,PLLEN,A
		
		; Configure LED Interface
		clrf	    LATD,A
		clrf	    TRISD,A
		
		; Configure External Signals
		clrf	    LATC,A
		movlw	    0xCF
		movwf	    TRISC,A
		
		; Configure SW1 Interface
		bsf	    TRISB,RB0,A
		bcf	    INTCON2,INTEDG0,A
		bsf	    INTCON,INT0IE,A
		
		; Configure Timer0
		movlw	    0x88
		movwf	    T0CON,A
		bsf	    INTCON2,TMR0IP,A
		bsf	    INTCON,TMR0IE,A
		
		; Clear System Flags
		clrf	    SYSFLAGS,A
		
		; Load HBCTR (Heartbeat Counter)
		movlw	    _TC_HEARTBEAT
		movwf	    HBCTR,A
		
		; Clear RLYCTR (Relay Counter)
		clrf	    RLYCTR+0,A
		clrf	    RLYCTR+1,A
		
		; Enables OSCON IDLE Mode
		bsf	    OSCCON,IDLEN,A
		
		; Enable Interupts
		bsf	    RCON,IPEN,A
		bsf	    INTCON,GIEL,A
		bsf	    INTCON,GIEH,A
			
		; Return
		return
				
;///////////////////////////////////////////////////////////
		; The System Tick Handler handles the
		; bit clearing of the file register
		; of the System Flags
SysTickHandler:
		; Clear Tick Flag
		bcf	    SYSFLAGS,_SYSF_TICK,A
				
;///////////////////////////////////////////////////////////
		; The Heartbeat System Tick Handler
		; decrements the heartbeat counter and 
		; branches to the Tick Relay handler
		; while toggling I/O ports RD0 and RC5
SysTickHandlerHeartbeat:
		decfsz	    HBCTR,F,A
		bra	    SysTickHandlerRelay
		
		btg	    LATD,RD0,A
		btg	    LATC,RC5,A ; Toggles External LED
		
		movlw	    _TC_HEARTBEAT
		movwf	    HBCTR,A
				
;///////////////////////////////////////////////////////////
SysTickHandlerRelay:
		movf	    RLYCTR+0,W,A
		iorwf	    RLYCTR+1,W,A
		bz	    SysTickHandlerDone
		
		; Decrement a 2 byte variable
		movf	    RLYCTR+0,F,A
		btfsc	    STATUS,Z,A
		decf	    RLYCTR+1,F,A
		decF	    RLYCTR+0,F,A
		
		movf	    RLYCTR+0,W,A
		iorwf	    RLYCTR+1,W,A
		bnz	    SysTickHandlerDone
		
		bcf	    LATD,RD7,A
		bcf	    LATC,RC4,A
				
;///////////////////////////////////////////////////////////
		; Tick Handler Done returns from the 
		; sub-routine when the SysTickHandler
		; routine is finished executing its 
		; code.
SysTickHandlerDone:
		return
		
;///////////////////////////////////////////////////////////
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
		
		btfsc	    INTCON,INT0IF,A
		call	    Int0ISR
		
		movf	    HPI_CONTEXT+2,W,A
		movff	    HPI_CONTEXT+1,BSR
		movff	    HPI_CONTEXT+0,STATUS
		
		retfie
		
;///////////////////////////////////////////////////////////
		; Only purpose is to return from a low
		; priority interupt as there are none
LPIEP:
		retfie
		
;///////////////////////////////////////////////////////////
		; The timer interupt service routine clears
		; the interupt flag register of INTCON
		; and sets the system tick bit of 
		; SYSFLAGS and returns 
Timer0ISR:
		bcf	    INTCON,TMR0IF,A
		bsf	    SYSFLAGS,_SYSF_TICK,A
		return
		
;///////////////////////////////////////////////////////////
		; The interupt service routine (ISR)
		; clears the interupt flags of the INTCON
		; register and energizes the relay when
		; the pushbutton is pressed.
Int0ISR:
		bcf	    INTCON,INT0IF,A
		
		; Load RLYCTR (High)
		movlw	    low _TC_RELAY
		movwf	    RLYCTR+0,A
		; Low
		movlw	    high _TC_RELAY
		movwf	    RLYCTR+1,A
		
		; Energize the Relay
		bsf	    LATD,RD7,A
		bsf	    LATC,RC4,A
		
		return
		
;///////////////////////////////////////////////////////////
    end
