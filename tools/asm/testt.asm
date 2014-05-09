:boot
	SSP 0x7FF
:loop
	JSR input
	WVS
	BRA loop


:input
	;;PUSH GR1

	MOVE GR0, [0x8004]

	CMP GR0, 0
	BNE sp1

	MOVE GR1, [0x9001]
	SUB GR1, [0x8000]		;; up
	ADD GR1, [0x8002]		;; down
	STORE GR1, 0x9001

	MOVE GR1, [0x9000]		;; 
	ADD GR1, [0x8001]		;; right
	SUB GR1, [0x8003]		;; left
	STORE GR1, 0x9000

	BRA input_done

:sp1
	CMP GR0, 1
	BNE input_done

	MOVE GR1, [0x9003]
	SUB GR1, [0x8000]		;; up
	ADD GR1, [0x8002]		;; down
	STORE GR1, 0x9003

	MOVE GR1, [0x9002]		;; 
	ADD GR1, [0x8001]		;; right
	SUB GR1, [0x8003]		;; left
	STORE GR1, 0x9002

:input_done

	;;POP GR1
	RTS
