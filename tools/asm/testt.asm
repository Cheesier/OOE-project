:coldboot
	MOVE GR0, 0
	MOVE GR1, 0xD0
	MOVE GR4, 0xF0
	MOVE GR2, 1
	MOVE GR3, 2
	STORE GR4, x_pos
	STORE GR1, y_pos
	STORE GR0, z_pos
	STORE GR0, x_vel_dir
	STORE GR0, x_vel
	STORE GR0, y_vel_dir
	STORE GR0, y_vel
	STORE GR0, x_acc_dir
	STORE GR0, x_acc
	STORE GR2, y_acc_dir		;; gravity direction down 
	STORE GR3, y_acc 			;; gravity = 2
	BRA boot

:x_pos dat 0
:y_pos dat 0
:z_pos dat 0

:x_vel_dir dat 0 				;; 0 if left, 1 if right
:x_vel dat 0
:y_vel_dir dat 0 				;; 0 if up, 1 if down
:y_vel dat 0

:old_x_vel_dir dat 0 			;; 0 if left, 1 if right
:old_x_vel dat 0
:old_y_vel_dir dat 0 			;; 0 if up, 1 if down
:old_y_vel dat 0

:x_acc_dir dat 0 				;; 0 if left, 1 if right
:x_acc dat 0
:y_acc_dir dat 0 				;; 0 if up, 1 if down
:y_acc dat 0

:top_left_collide dat 0
:top_right_collide dat 0
:bottom_left_collide dat 0
:bottom_right_collide dat 0

:layer_disp_x
:layer0_disp_x dat 0
:layer1_disp_x dat 2
:layer2_disp_x dat 0
:layer3_disp_x dat 0
:layer_disp_y
:layer0_disp_y dat 0
:layer1_disp_y dat -4
:layer2_disp_y dat 0
:layer3_disp_y dat 0

:random_nr dat 0
:score dat 0
:current_collectable dat 0

;;;
;;; Collectables
;;;
:spaw_location_x
dat 0x0E0
dat 0x1A0
dat 0x1F0
dat 0x140
:spaw_location_y
dat 0x0C0
dat 0x0C0
dat 0x130
dat 0x1C0

:collision_addr
:layer0_collision dat 1600
:layer1_collision dat 1280

:boot
	SSP 0x7FF
:loop
	JSR random
	JSR input
	JSR handle_velocity_x
	JSR handle_velocity_y
	JSR handle_movement_x
	JSR handle_movement_y
	MOVE GR0, [x_pos]
	AND GR0, 0x0FFF
	STORE GR0, x_pos
	;JSR simple_input
	JSR find_collision
	JSR handle_collision
	JSR collectables_check
	JSR parallax
	JSR render

;;; DEBUG
	;MOVE GR2, [top_left_collide]
	;LSL GR2, 4
	;ADD GR2, [top_right_collide]
	;LSL GR2, 4
	;ADD GR2, [bottom_left_collide]
	;LSL GR2, 4
	;ADD GR2, [bottom_right_collide]

	MOVE GR2, [x_pos]
	
	MOVE GR3, [x_pos]
	MOVE GR4, [x_acc_dir]
	MOVE GR5, [x_vel_dir]
;;; END DEBUG
	WVS
	BRA loop


;;;
;;; RANDOM
;;;
:random
	PUSH GR0

	MOVE GR0, [random_nr]
	ADD GR0, 1
	AND GR0, 3
	STORE GR0, random_nr

	POP GR0

	RTS


;;;
;;; INPUT
;;; 
:input
	PUSH GR0
	PUSH GR1

:check_depth
	MOVE GR0, [0x8004]
	AND GR0, 0x1
	STORE GR0, z_pos

:check_up
	MOVE GR0, [0x8000]		;; up
	MOVE GR1, [bottom_left_collide]
	OR GR1, [bottom_right_collide]		; GR1 = BL or BR
	ADD GR0, GR1
	CMP GR0, 2
	BNE check_x				;; check next if button not down
	MOVE GR0, 32
	STORE GR0, y_vel
	MOVE GR0, 0
	STORE GR0, y_vel_dir

:check_x

	MOVE GR0, [0x8001]
	MOVE GR1, [0x8003]
	CMP GR0, GR1
	BMI acc_left
	BEQ no_x_input

:acc_right
	MOVE GR1, 2 				;; acceleration
	STORE GR1, x_acc
	MOVE GR1, 1 				;; acc directed right
	STORE GR1, x_acc_dir
	BRA done_directions
	
:acc_left
	MOVE GR1, 2					;; acceleration
	STORE GR1, x_acc
	MOVE GR1, 0 				;; acc directed left
	STORE GR1, x_acc_dir
	BRA done_directions

:no_x_input
	MOVE GR1, [x_vel]
	CMP GR1, 0
	BEQ stop_acc_x
	INV GR1, [x_vel_dir]		;; invert direction
	ADD GR1, 1
	STORE GR1, x_acc_dir
	MOVE GR1, 1 				;; acceleration = 1
	STORE GR1, x_acc
	BRA done_directions

:stop_acc_x
	MOVE GR1, 0
	STORE GR1, x_acc

:done_directions
	POP GR1
	POP GR0
	RTS
	
;;; 
;;; HANDLE VELOCITY X
;;; 
;; Handle all the Velocity thingies
:handle_velocity_x
	PUSH GR0
	PUSH GR1

	MOVE GR0, [x_vel_dir]
	CMP GR0, [x_acc_dir]
	BEQ x_dir_same
	BNE x_dir_not_same

:x_dir_same
	MOVE GR0, [x_vel]
	ADD GR0, [x_acc]
	STORE GR0, x_vel
	BRA x_vel_clamp

:x_dir_not_same
	MOVE GR0, [x_vel]
	SUB GR0, [x_acc]
	BMI x_vel_negative				;; jump to inverter
	STORE GR0, x_vel
	BRA x_vel_clamp

:x_vel_negative
	INV GR0, [x_vel]
	STORE GR0, x_vel
	INV GR0, [x_vel_dir]
	ADD GR0, 1
	STORE GR0, x_vel_dir

:x_vel_clamp
	MOVE GR0, [x_vel]
	CMP GR0, 24						;; max speed
	BMI x_vel_done
	MOVE GR0, 24					;; max speed
	STORE GR0, x_vel

:x_vel_done

	POP GR1
	POP GR0
	RTS

;;; 
;;; HANDLE VELOCITY Y
;;; 
:handle_velocity_y
	PUSH GR0
	PUSH GR1

	MOVE GR0, [y_vel_dir]
	CMP GR0, [y_acc_dir]
	BEQ y_dir_same
	BNE y_dir_not_same

:y_dir_same
	MOVE GR0, [y_vel]
	ADD GR0, [y_acc]
	STORE GR0, y_vel
	BRA y_vel_clamp

:y_dir_not_same
	MOVE GR0, [y_vel]
	SUB GR0, [y_acc]
	BMI y_vel_negative				;; jump to inverter
	STORE GR0, y_vel
	BRA y_vel_clamp

:y_vel_negative
	INV GR0, [y_vel]
	STORE GR0, y_vel
	INV GR0, [y_vel_dir]
	ADD GR0, 1
	STORE GR0, y_vel_dir

:y_vel_clamp
	MOVE GR0, [y_vel_dir]
	CMP GR0, 1
	BNE y_vel_done				;; if jumping dont clamp
	MOVE GR0, [y_vel]
	CMP GR0, 32					;; max speed
	BMI y_vel_done
	MOVE GR0, 32				;; max speed
	STORE GR0, y_vel

:y_vel_done

	POP GR1
	POP GR0
	RTS

;;; 
;;; HANDLE MOVEMENT X
;;; 
:handle_movement_x
	PUSH GR0
	PUSH GR1
	PUSH GR8

	MOVE GR0, [x_vel]
	MOVE GR1, [x_pos]
	LSR GR0, 3
	MOVE GR8, [x_vel_dir]
	CMP GR8, 1						;; handle movement right?
	BNE x_handle_movement_left
:x_handle_movement_right
	ADD GR1, GR0					;; POS + Velocity
	BRA x_handle_movement_done
:x_handle_movement_left
	SUB GR1, GR0					;; POS - Velocity
:x_handle_movement_done
	STORE GR1, x_pos

	POP GR8
	POP GR1
	POP GR0
	RTS
	
;;; 
;;; HANDLE MOVEMENT Y
;;; 
:handle_movement_y
	PUSH GR0
	PUSH GR1
	PUSH GR8

	MOVE GR0, [y_vel]
	MOVE GR1, [y_pos]
	LSR GR0, 3
	MOVE GR8, [y_vel_dir]
	CMP GR8, 1						;; handle movement right?
	BNE y_handle_movement_up
:y_handle_movement_down
    
	ADD GR1, GR0					;; POS + Velocity
	BRA y_handle_movement_done
:y_handle_movement_up
	SUB GR1, GR0					;; POS - Velocity
:y_handle_movement_done
	STORE GR1, y_pos

	POP GR8
	POP GR1
	POP GR0
	RTS
	
;;;
;;; FIND COLLISION
;;; 
:find_collision
	PUSH GR0
	PUSH GR1
	PUSH GR2

	MOVE GR0, [x_pos]	; top left corner
	MOVE GR1, [y_pos]
	JSR collide_check
	STORE GR0, top_left_collide

	MOVE GR0, [x_pos]	; top right corner
	ADD GR0, 15
	MOVE GR1, [y_pos]
	JSR collide_check
	STORE GR0, top_right_collide

	MOVE GR0, [x_pos]	; bottom left corner
	MOVE GR1, [y_pos]
	ADD GR1, 15
	JSR collide_check
	STORE GR0, bottom_left_collide

	MOVE GR0, [x_pos]	; bottom right corner
	ADD GR0, 15
	MOVE GR1, [y_pos]
	ADD GR1, 15
	JSR collide_check
	STORE GR0, bottom_right_collide

	POP GR2
	POP GR1
	POP GR0
	RTS
;;;
;;; COLLIDE CHECK
;;; 
	;; takes GR0 as x coord and GR1 as y coord
	;; returns collision status in GR0
:collide_check
	PUSH GR2
	PUSH GR3
	PUSH GR4
	PUSH GR15
	
	LSR GR0, 4			; X pix coord to tile coord
	LSR GR1, 4			; Y  -------||------
	MOVE GR5, GR0		; copy of x tile coord

	LSR GR0, 4			; X >> 4
	AND GR0, 0x7 		; X AND 7
	LSL GR1, 3			; Y * 8
	ADD GR0, GR1		; X + Y

	MOVE GR15, [z_pos]
	MOVE GR15, (collision_addr)

	ADD GR15, GR0		; GR15 = addr + offset
	MOVE GR2, (0)		; addr to "box"

	MOVE GR0, GR5 		; x tile coord
	AND GR0, 0xF		; X AND 1111
	MOVE GR3, 15		; 16 - 1
	SUB GR3, GR0		; 15 - X
	
	MOVE GR4, 1			; addr index
	LSL GR4, GR3		; 2^(15-X)
	AND GR2, GR4		; choose bit
	CMP GR2, 0			; collides?
	BEQ no_collide
	MOVE GR0, 1
	BRA done_collide_check

:no_collide
	MOVE GR0, 0

:done_collide_check
	
	POP GR15
	POP GR4
	POP GR3
	POP GR2
	RTS

;;;						
;;; HANDLE COLLISION
;;; 
:handle_collision
	PUSH GR0
	PUSH GR1
	PUSH GR2
	
	MOVE GR0, [top_left_collide]
	CMP GR0, 1
	BEQ TL_collides

	MOVE GR0, [top_right_collide]
	CMP GR0, 1
	BEQ TR_collides

	MOVE GR0, [bottom_left_collide]
	CMP GR0, 1
	BEQ BL_collides

	MOVE GR0, [bottom_right_collide]
	CMP GR0, 1
	BEQ bottom_right_corner_collides
	BRA done_handle_collision

:TL_collides
	MOVE GR0, [top_right_collide]
	CMP GR0, 1
	BEQ roof_collides
	MOVE GR0, [bottom_left_collide]
	CMP GR0, 1
	BEQ left_wall_collides
	BRA top_left_corner_collides

:TR_collides
	MOVE GR0, [bottom_right_collide]
	CMP GR0, 1
	BEQ right_wall_collides
	BRA top_right_corner_collides

:BL_collides
	MOVE GR0, [bottom_right_collide]
	CMP GR0, 1
	BEQ floor_collides
	BRA bottom_left_corner_collides

:roof_collides
	MOVE GR0, 0
	STORE GR0, [y_vel]
	MOVE GR0, [bottom_left_collide]
	CMP GR0, 1
	BEQ TL_TR_BL_collides
	MOVE GR0, [bottom_right_collide]
	CMP GR0, 1
	BEQ TL_TR_BR_collides			; Else, continue

	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	MOVE GR3, 16
	SUB GR3, GR1
	ADD GR2, GR3					; y_pos + tile offset
	STORE GR2, y_pos
	BRA done_handle_collision

:left_wall_collides
	MOVE GR0, 0
	STORE GR0, [x_vel]
	MOVE GR0, [bottom_right_collide]
	CMP GR0, 1
	BEQ TL_BL_BR_collides			; Else, continue

	MOVE GR1, [x_pos]
	AND GR1, 0xF 					; GR1 = X & 0xF, distance to tile border
	MOVE GR2, [x_pos] 				; GR2 = x_pos
	MOVE GR3, 16 					; GR3 = distance to tile border
	SUB GR3, GR1
	ADD GR2, GR3					; X_pos + distance to tile border
	STORE GR2, x_pos
	BRA done_handle_collision

:right_wall_collides
	MOVE GR0, 0
	STORE GR0, [x_vel]
	MOVE GR0, [bottom_left_collide]
	CMP GR0, 1
	BEQ TR_BL_BR_collides			; Else, continue

	MOVE GR1, [x_pos]
	AND GR1, 0xF 					; GR1 = X & 0xF, distance to tile border
	MOVE GR2, [x_pos] 				; GR2 = x_pos
	SUB GR2, GR1					; X_pos - distance to tile border
	STORE GR2, x_pos
	BRA done_handle_collision

:floor_collides
	MOVE GR0, 0
	STORE GR0, [y_vel]
	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = Y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	SUB GR2, GR1					; y_pos - distance to tile border
	STORE GR2, y_pos
	BRA done_handle_collision


;;; SINGLE AND TRIPPLE CASES
:TL_TR_BL_collides
	;; roof
	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	MOVE GR3, 16
	SUB GR3, GR1
	ADD GR2, GR3					; y_pos + tile offset
	STORE GR2, y_pos

	;; left-wall
	MOVE GR0, 0
	STORE GR0, [x_vel]
	MOVE GR1, [x_pos]
	AND GR1, 0xF 					; GR1 = X & 0xF, distance to tile border
	MOVE GR2, [x_pos] 				; GR2 = x_pos
	MOVE GR3, 16 					; GR3 = distance to tile border
	SUB GR3, GR1
	ADD GR2, GR3					; X_pos + distance to tile border
	STORE GR2, x_pos
	BRA done_handle_collision

	
:TL_TR_BR_collides
	;; roof
	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	MOVE GR3, 16
	SUB GR3, GR1
	ADD GR2, GR3					; y_pos + tile offset
	STORE GR2, y_pos

	;; right-wall
	MOVE GR0, 0
	STORE GR0, [x_vel]
	MOVE GR1, [x_pos]
	AND GR1, 0xF 					; GR1 = X & 0xF, distance to tile border
	MOVE GR2, [x_pos] 				; GR2 = x_pos
	SUB GR2, GR1					; X_pos - distance to tile border
	STORE GR2, x_pos
	BRA done_handle_collision


:TL_BL_BR_collides
	;; left-wall
	MOVE GR1, [x_pos]
	AND GR1, 0xF 					; GR1 = X & 0xF, distance to tile border
	MOVE GR2, [x_pos] 				; GR2 = x_pos
	MOVE GR3, 16 					; GR3 = distance to tile border
	SUB GR3, GR1
	ADD GR2, GR3					; X_pos + distance to tile border
	STORE GR2, x_pos

	;; floor
	MOVE GR0, 0
	STORE GR0, [y_vel]
	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = Y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	SUB GR2, GR1					; y_pos - distance to tile border
	STORE GR2, y_pos
	BRA done_handle_collision


:TR_BL_BR_COLLIDES
	;; right-wall
	MOVE GR1, [x_pos]
	AND GR1, 0xF 					; GR1 = X & 0xF, distance to tile border
	MOVE GR2, [x_pos] 				; GR2 = x_pos
	SUB GR2, GR1					; X_pos - distance to tile border
	STORE GR2, x_pos

	;; floor
	MOVE GR0, 0
	STORE GR0, [y_vel]
	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = Y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	SUB GR2, GR1					; y_pos - distance to tile border
	STORE GR2, y_pos
	BRA done_handle_collision

:top_left_corner_collides
	; roof
	MOVE GR0, 0
	STORE GR0, [y_vel]
	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	MOVE GR3, 16
	SUB GR3, GR1
	ADD GR2, GR3					; y_pos + tile offset
	STORE GR2, y_pos
	BRA done_handle_collision

:top_right_corner_collides
	; roof
	MOVE GR1, [y_pos]
	AND GR1, 0xF 					; GR1 = y & 0xF, distance to tile border
	MOVE GR2, [y_pos] 				; GR2 = y_pos
	MOVE GR3, 16
	SUB GR3, GR1
	ADD GR2, GR3					; y_pos + tile offset
	STORE GR2, y_pos
	BRA done_handle_collision

:bottom_left_corner_collides
	BRA floor_collides
:bottom_right_corner_collides
	BRA floor_collides

	BRA done_handle_collision
	
:done_handle_collision
	POP GR2
	POP GR1
	POP GR0
	RTS


;;;
;;; Collectables check
;;;
:collectables_check
	PUSH GR0
	PUSH GR1
	PUSH GR15

	MOVE GR15, [current_collectable]

	MOVE GR0, (spaw_location_x) 	; GR0 = x location for collectable
	LSR GR0, 4						; GR0 = tile pos for collectable
	MOVE GR1, [x_pos]
	LSR GR1, 4						; GR1 = tile pos for player
	CMP GR0, GR1 					; collides? in that case
	BEQ collectables_check_y 		; check if collides in y axis

	ADD GR1, 1 						; GR1 = tile pos for player + 1
	CMP GR0, GR1 					; collides? in that case
	BEQ collectables_check_y 		; check if collides in y axis

	BRA collectables_check_done 	; did not collide, exit

:collectables_check_y
	MOVE GR0, (spaw_location_y) 	; GR0 = y location for collectable
	LSR GR0, 4						; GR0 = tile pos for collectable
	MOVE GR1, [y_pos]
	LSR GR1, 4						; GR1 = tile pos for player
	CMP GR0, GR1 					; collides? in that case
	BEQ collectables_collide 		; give player score and place a new one

	ADD GR1, 1 						; GR1 = tile pos for player + 1
	CMP GR0, GR1 					; collides? in that case
	BEQ collectables_collide 		; give player score and place a new one

	BRA collectables_check_done 	; did not collide, exit

:collectables_collide
	MOVE GR0, [score]
	ADD GR0, 1 						; score++
	STORE GR0, score

	MOVE GR0, [random_nr] 
	CMP GR0, [current_collectable]
	BNE collectables_inequals
	ADD GR0, 1
	AND GR0, 3

:collectables_inequals
	STORE GR0, current_collectable

:collectables_check_done
	POP GR15
	POP GR1
	POP GR0

	RTS

;;;
;;; PARALLAX
;;; 
:parallax
	PUSH GR0

	MOVE GR0, [x_pos]
	LSR GR0, 3 						; every 8th pixel, move planets
	INV GR0, GR0
	STORE GR0, layer2_disp_x

	MOVE GR0, [x_pos]
	LSR GR0, 4 						; every 16th pixel, move background
	INV GR0, GR0
	STORE GR0, layer3_disp_x

	POP GR0
	RTS


;;;
;;; RENDER
;;; 
:render
	PUSH GR0
	PUSH GR15

	MOVE GR15, [z_pos]

	;; Character
	MOVE GR0, [x_pos]
	ADD GR0, (layer_disp_x)
	STORE GR0, 0x9000
	MOVE GR0, [y_pos]
	ADD GR0, (layer_disp_y)
	STORE GR0, 0x9001

	MOVE GR0, [z_pos]
	LSL GR0, 14
	STORE GR0, 0x901A

	;; Layers
	MOVE GR0, [layer0_disp_x]
	STORE GR0, 0x9010
	MOVE GR0, [layer0_disp_y]
	STORE GR0, 0x9011
	MOVE GR0, [layer1_disp_x]
	STORE GR0, 0x9012
	MOVE GR0, [layer1_disp_y]
	STORE GR0, 0x9013
	MOVE GR0, [layer2_disp_x]
	STORE GR0, 0x9014
	MOVE GR0, [layer2_disp_y]
	STORE GR0, 0x9015
	MOVE GR0, [layer3_disp_x]
	STORE GR0, 0x9016
	MOVE GR0, [layer3_disp_y]
	STORE GR0, 0x9017

	;; Collectable
	MOVE GR15, [current_collectable]
	MOVE GR0, (spaw_location_x)
	STORE GR0, 0x9002
	MOVE GR0, (spaw_location_y)
	STORE GR0, 0x9003

	POP GR15
	POP GR0
	RTS


:simple_input
	PUSH GR0

	MOVE GR0, [y_pos]
	SUB GR0, [0x8000]
	ADD GR0, [0x8002]
	STORE GR0, y_pos

	MOVE GR0, [x_pos]
	ADD GR0, [0x8001]
	SUB GR0, [0x8003]
	STORE GR0, x_pos

	POP GR0
	RTS
