:boot
	MOVEVH VR0, 0
	MOVEVH VR1, 0
	MOVE GR0, 1
	SSP 0x7FF
:loop
	JSR input
	WVS
	BRA loop


:input
	SUBVH VR1, [0x8000] ;; up
	SUBVH VR0, [0x8001] ;; left
	ADDVH VR1, [0x8002] ;; down
	ADDVH VR0, [0x8003] ;; right
	RTS