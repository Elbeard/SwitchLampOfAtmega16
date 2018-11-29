		.include "m16def.inc"   ; Используем ATMega16

;= Start 	macro.inc ========================================
   .macro    OUTI         ; Это описание макроса. Везде где outi встретится в коде, то заменяется на
      ldi    R16,@1
   .if @0 < 0x40
      out    @0,R16         ; макроса. Данный макрос тупо копирует введенное число сначала в регистр R16, а из него
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

;== объявляем переменные =========
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

	 	.ORG   INT_VECTORS_SIZE      	; Конец таблицы прерываний

; Interrupts ==============================================
RX_OK:		PUSHF			; Макрос, пихающий в стек SREG и R16
 
			IN	R16,UDR		; Тут главное забрать байт из UDR иначе 
							; флаг прерывания не снимется
							; Дальше, если время позволяет, можно и обработать

			OUT	PORTB, R16
;			CPI	R16,Value	; Например, разобрать по байтам и выполнить действие
;			BRNE	NXT		; Обычным CASE оператором.
;			Action1			; Делаем что нибудь ценное. Главное не забыть в стеке
;					; Регистры попрятать. А то будет тебе упячка. 
;NXT:		CPI	R16,Value2
;			BRNE	RX_Exit
;			Action2			; Делаем что нибудь ценное2
;
Rx_Exit:	POPF			; Достаем SREG и R16
			RETI



; End Interrupts ==========================================


Reset:   	LDI 	temp,Low(RAMEND)	; Инициализация стека
		    OUT 	SPL,temp			; Обязательно!!!

		 	LDI 	temp,High(RAMEND)
		 	OUT 	SPH,temp
	 
; Start coreinit.inc
RAM_Flush:	LDI		ZL,Low(SRAM_START)	; Адрес начала ОЗУ в индекс
			LDI		ZH,High(SRAM_START)
			CLR		temp					; Очищаем R16
Flush:		ST 		Z+,temp				; Сохраняем 0 в ячейку памяти
			CPI		ZH,High(RAMEND)		; Достигли конца оперативки?
			BRNE	Flush				; Нет? Крутимся дальше!
 
			CPI		ZL,Low(RAMEND)		; А младший байт достиг конца?
			BRNE	Flush
 
			LDI		ZL, 30					; +-----------------------+
			CLR		ZH						; |						  |
			DEC		ZL						; | Очистка РОН (R00-R31) |
			ST		Z, ZH					; |	[10 байт кода]	      |
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

; Прерывания запрещены, прием-передача разрешен.
;			LDI 	temp, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(0<<TXCIE)|(0<<UDRIE)
;			OUT 	UCSRB, temp	  //CONTROL and STATUS REGISTER B

; Прерывания разрешены, прием-передача разрешен.
			LDI 	R16, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(0<<UDRIE)
			OUT 	UCSRB, R16

; Формат кадра - 8 бит, пишем в регистр UCSRC, за это отвечает бит селектор	URSEL
			LDI 	temp, 86 //(1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)	 //8 bit, 1 stop bit
			OUT 	UCSRC, temp	  //CONTROL and STATUS REGISTER C 				
			SEI	  //РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ В ПРИНЦИПЕ, БЕЗ ЭТОГО ПРЕРЫВАНИЯ РАБОТАТЬ НЕ БУДУТ
; End Internal Hardware Init ===================================



; External Hardware Init  ======================================
			LDI		temp, 0xff //0b11111111 255 выставляем все биты в еденицы
			OUT		DDRB, temp //инициализируем все ноги порта на выход
			LDI		temp, 0x00
			OUT		DDRA, temp //на вход
			LDI		temp, 0xff
			OUT		PORTA, temp // подтяжка на +
			LDI		r20, 0x00
; End Internal Hardware Init ===================================



; Run ==========================================================

; End Run ======================================================



; Main =========================================================


Proga:		RCALL	uart_snt
			SBIC	PINA, 0   //если 0 бит в регистре PINA is clear пропустить следующую команду (проверяем нажата ли кнопка)
			RJMP	Proga
			RJMP	Press_key		
;			LDI		temp, 0x07 // мигание, сначала прописываем плюсы на ногах потом минусы
;			OUT		PORTB, temp
;			RCALL	Delay
;			LDI		temp, 0x00
;			OUT		PORTB, temp
;			RCALL	Delay 		
			RJMP	Proga 


; End Main =====================================================


; Procedure ====================================================

; Процедура отправки байта
uart_snt:	PUSHF
			IN		R16, PORTB
			SBIS 	UCSRA,UDRE		; Пропуск если нет флага готовности
			RJMP	uart_snt 		; ждем готовности - флага UDRE
 			OUT		UDR, R16		; шлем байт
			;RCALL	Delay
			POPF
			RET						; Возврат

Press_key:	IN		R16, PORTB
			RCALL	Delay			//задержка для устранения дребезга кнопки
			CPI		r20, 0x03
			BREQ	Reset_count		//если включены все лампы, вуключить все
			INC		r20	 			//увеличиваем счётчик на 1 (инкремент)
			RJMP	Switch			//смотрим сколько ламп включить после нажатия кнопки

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




;Посылка байта:
;			RCALL 	uart_init 		; вызываем нашу процедуру инициализации.
;
;Main:		LDI 	R16,'E'			; загоняем в регистр код буквы «E»
;			RCALL	uart_snt		; Вызываем процедуру отправки байта. 
;
;			NOP						; Любой дальнейший код
;			NOP

;Ожидание байта
;uart_rcv:	SBIS	UCSRA,RXC		; Ждем флага прихода байта
;			RJMP	uart_rcv		; вращаясь в цикле
; 
;			IN	R16,UDR				; байт пришел - забираем.
;			RET						; Выходим. Результат в R16		
				
; End Procedure ================================================


; EEPROM =====================================================
			.ESEG				; Сегмент EEPROM
