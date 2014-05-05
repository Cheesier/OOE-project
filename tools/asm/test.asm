;; Simple example of the assembly language like the 68K assembly.
;; every instruction except for 'dat' needs it's own line.
;; 'dat' and 'org' does not support values to be labels.
;; any eventual relative jump (BRA) will not have it's address calculated
;; the input given here will be the offset.


	:val_3 dat v3			; pointer to v3
	:v2 dat 5
	:v3 dat 6
	:out dat 0
	dat v2

	;;ORG 0A				; Instructions now writing from 0x0A and onward
:main
	LOAD GR1, v2			; Direct addressing
	ADD GR1, 3				; Immediate addressing
	ADD GR1, [val_3]		; Indirect addressing
	STORE GR1, out
	JMP main

;; memory at location 'out' after at least one iteration
;; M('out') = 5 + 3 + 6 = 0xE
