		.include "m16def.inc"   ; ���������� ATMega16

;= Start 	macro.inc ========================================
   .macro    OUTI         ; ��� �������� �������. ����� ��� outi ���������� � ����, �� ���������� ��
      ldi    R16,@1
   .if @0 < 0x40
      out    @0,R16         ; �������. ������ ������ ���� �������� ��������� ����� ������� � ������� R16, � �� ����
   .else
      sts      @0,R16
   .endif
   .endm

   	.macro    UOUT        
   	.if	@0 < 0x40
      	out	@0,@1         
	.else
      	sts	@0,@1
   	.endif
   	.endm

;.............................................................
	.MACRO PUSHF
	PUSH	R16
	IN	R16,SREG
	PUSH	R16
	.ENDM


	.MACRO POPF
	POP	R16
	OUT	SREG,R16
	POP	R16
	.ENDM
;= End 		macro.inc ========================================

;== ��������� ���������� =========
		.def temp = r16
		.def razr1 = r17
		.def razr2 = r18
		.def razr3 = r19



; RAM ========================================================
		.DSEG


; FLASH ======================================================
         .CSEG
         .ORG $000        ; (RESET) 
         RJMP   Reset
         .ORG $002
         RETI             ; (INT0) External Interrupt Request 0
         .ORG $004
         RETI             ; (INT1) External Interrupt Request 1
         .ORG $006
         RETI		      ; (TIMER2 COMP) Timer/Counter2 Compare Match
         .ORG $008
         RETI             ; (TIMER2 OVF) Timer/Counter2 Overflow
         .ORG $00A
         RETI		      ; (TIMER1 CAPT) Timer/Counter1 Capture Event
         .ORG $00C 
         RETI             ; (TIMER1 COMPA) Timer/Counter1 Compare Match A
         .ORG $00E
         RETI             ; (TIMER1 COMPB) Timer/Counter1 Compare Match B
         .ORG $010
         RETI             ; (TIMER1 OVF) Timer/Counter1 Overflow
         .ORG $012
         RETI             ; (TIMER0 OVF) Timer/Counter0 Overflow
         .ORG $014
         RETI             ; (SPI,STC) Serial Transfer Complete
         .ORG $016
         RJMP	RX_OK     		 ; (USART,RXC) USART, Rx Complete
         .ORG $018
         RETI             ; (USART,UDRE) USART Data Register Empty
         .ORG $01A
         RETI             ; (USART,TXC) USART, Tx Complete
         .ORG $01C
         RETI		    ; (ADC) ADC Conversion Complete
         .ORG $01E
         RETI             ; (EE_RDY) EEPROM Ready
         .ORG $020
         RETI             ; (ANA_COMP) Analog Comparator
         .ORG $022
         RETI             ; (TWI) 2-wire Serial Interface
         .ORG $024
         RETI             ; (INT2) External Interrupt Request 2
         .ORG $026
         RETI             ; (TIMER0 COMP) Timer/Counter0 Compare Match
         .ORG $028
         RETI             ; (SPM_RDY) Store Program Memory Ready

	 	.ORG   INT_VECTORS_SIZE      	; ����� ������� ����������

; Interrupts ==============================================
RX_OK:		PUSHF			; ������, �������� � ���� SREG � R16
 
			IN	R16,UDR		; ��� ������� ������� ���� �� UDR ����� 
							; ���� ���������� �� ��������
							; ������, ���� ����� ���������, ����� � ����������

			OUT	PORTB, R16
;			CPI	R16,Value	; ��������, ��������� �� ������ � ��������� ��������
;			BRNE	NXT		; ������� CASE ����������.
;			Action1			; ������ ��� ������ ������. ������� �� ������ � �����
;					; �������� ���������. � �� ����� ���� ������. 
;NXT:		CPI	R16,Value2
;			BRNE	RX_Exit
;			Action2			; ������ ��� ������ ������2
;
Rx_Exit:	POPF			; ������� SREG � R16
			RETI



; End Interrupts ==========================================


Reset:   	LDI 	temp,Low(RAMEND)	; ������������� �����
		    OUT 	SPL,temp			; �����������!!!

		 	LDI 	temp,High(RAMEND)
		 	OUT 	SPH,temp
	 
; Start coreinit.inc
RAM_Flush:	LDI		ZL,Low(SRAM_START)	; ����� ������ ��� � ������
			LDI		ZH,High(SRAM_START)
			CLR		temp					; ������� R16
Flush:		ST 		Z+,temp				; ��������� 0 � ������ ������
			CPI		ZH,High(RAMEND)		; �������� ����� ����������?
			BRNE	Flush				; ���? �������� ������!
 
			CPI		ZL,Low(RAMEND)		; � ������� ���� ������ �����?
			BRNE	Flush
 
			LDI		ZL, 30					; +-----------------------+
			CLR		ZH						; |						  |
			DEC		ZL						; | ������� ��� (R00-R31) |
			ST		Z, ZH					; |	[10 ���� ����]	      |
			BRNE	PC-2				; +-----------------------+
; End coreinit.inc



; Internal Hardware Init  ======================================
			
			.equ 	XTAL = 8000000 	
			.equ 	baudrate = 9600  
			.equ 	bauddivider = XTAL/(16*baudrate)-1
 
uart_init:	LDI 	temp, low(bauddivider)	  //set baud rate
			OUT 	UBRRL, temp	  //set baud rate uart baud rate register hight bite
			LDI 	temp, high(bauddivider)	  //set baud rate
			OUT 	UBRRH, temp	  //set baud rate uart baud rate register low bite

 			LDI 	temp, 0
			OUT 	UCSRA, temp	  //CONTROL and STATUS REGISTER A

; ���������� ���������, �����-�������� ��������.
;			LDI 	temp, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(0<<TXCIE)|(0<<UDRIE)
;			OUT 	UCSRB, temp	  //CONTROL and STATUS REGISTER B

; ���������� ���������, �����-�������� ��������.
			LDI 	R16, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(0<<UDRIE)
			OUT 	UCSRB, R16

; ������ ����� - 8 ���, ����� � ������� UCSRC, �� ��� �������� ��� ��������	URSEL
			LDI 	temp, 86 //(1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)	 //8 bit, 1 stop bit
			OUT 	UCSRC, temp	  //CONTROL and STATUS REGISTER C 				
			SEI	  //���������� ���������� � ��������, ��� ����� ���������� �������� �� �����
; End Internal Hardware Init ===================================



; External Hardware Init  ======================================
			LDI		temp, 0xff //0b11111111 255 ���������� ��� ���� � �������
			OUT		DDRB, temp //�������������� ��� ���� ����� �� �����
			LDI		temp, 0x00
			OUT		DDRA, temp //�� ����
			LDI		temp, 0xff
			OUT		PORTA, temp // �������� �� +
			LDI		r20, 0x00
; End Internal Hardware Init ===================================



; Run ==========================================================

; End Run ======================================================



; Main =========================================================


Proga:		RCALL	uart_snt
			SBIC	PINA, 0   //���� 0 ��� � �������� PINA is clear ���������� ��������� ������� (��������� ������ �� ������)
			RJMP	Proga
			RJMP	Press_key		
;			LDI		temp, 0x07 // �������, ������� ����������� ����� �� ����� ����� ������
;			OUT		PORTB, temp
;			RCALL	Delay
;			LDI		temp, 0x00
;			OUT		PORTB, temp
;			RCALL	Delay 		
			RJMP	Proga 


; End Main =====================================================


; Procedure ====================================================

; ��������� �������� �����
uart_snt:	PUSHF
			IN		R16, PORTB
			SBIS 	UCSRA,UDRE		; ������� ���� ��� ����� ����������
			RJMP	uart_snt 		; ���� ���������� - ����� UDRE
 			OUT		UDR, R16		; ���� ����
			;RCALL	Delay
			POPF
			RET						; �������

Press_key:	IN		R16, PORTB
			RCALL	Delay			//�������� ��� ���������� �������� ������
			CPI		r20, 0x03
			BREQ	Reset_count		//���� �������� ��� �����, ��������� ���
			INC		r20	 			//����������� ������� �� 1 (���������)
			RJMP	Switch			//������� ������� ���� �������� ����� ������� ������

Switch:		CPI		r20, 0x01
			BREQ	Lamp1
			CPI		r20, 0x02
			BREQ	Lamp2
			CPI		r20, 0x03
			BREQ	Lamp3

Reset_count:LDI		r20, 0x00
			LDI		temp, 0x00
			OUT		PORTB, temp
			RJMP	Proga

Lamp1:		LDI		temp, 1
			OUT		PORTB, temp
			RJMP	Proga

Lamp2:		LDI		temp, 3
			OUT		PORTB, temp
			RJMP	Proga

Lamp3:		LDI		temp, 7
			OUT		PORTB, temp
			RJMP	Proga

Delay:		LDI		razr1, 255
			LDI		razr2, 255
			LDI		razr3, 11
PDelay:		DEC		razr1
			BRNE	PDelay
			DEC		razr2
			BRNE	PDelay
			DEC		razr3
			BRNE	PDelay
			RET




;������� �����:
;			RCALL 	uart_init 		; �������� ���� ��������� �������������.
;
;Main:		LDI 	R16,'E'			; �������� � ������� ��� ����� �E�
;			RCALL	uart_snt		; �������� ��������� �������� �����. 
;
;			NOP						; ����� ���������� ���
;			NOP

;�������� �����
;uart_rcv:	SBIS	UCSRA,RXC		; ���� ����� ������� �����
;			RJMP	uart_rcv		; �������� � �����
; 
;			IN	R16,UDR				; ���� ������ - ��������.
;			RET						; �������. ��������� � R16		
				
; End Procedure ================================================


; EEPROM =====================================================
			.ESEG				; ������� EEPROM
