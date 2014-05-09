:boot
	SSP 0x7FF
:loop
	JSR input
	WVS
	BRA loop


:input
	;;PUSH GR1

	MOVE GR1, [0x9001]		;; VR1
	SUB GR1, [0x8000]		;; up
	ADD GR1, [0x8002]		;; down
	STORE GR1, 0x9001

	MOVE GR2, [0x9000]		;; VR0
	ADD GR2, [0x8001]		;; right
	SUB GR2, [0x8003]		;; left
	STORE GR2, 0x9000

	;;POP GR1
	RTS
