:boot
	MOVEV VR0, 0
	MOVE GR0, 1
:loop
	ADDV VR0, GR0
	;;WVS
	JMP loop