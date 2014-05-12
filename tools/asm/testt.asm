:coldboot
	MOVE GR0, 0
	MOVE GR1, 0x40
	MOVE GR2, 1
	STORE GR1, x_pos
	STORE GR0, y_pos
	STORE GR0, z_pos
	STORE GR0, x_vel_dir
	STORE GR0, x_vel
	STORE GR0, y_vel_dir
	STORE GR0, y_vel
	STORE GR0, x_acc_dir
	STORE GR0, x_acc
	STORE GR2, y_acc_dir		;; gravity direction down 
	STORE GR2, y_acc 			;; gravity = 1
	BRA boot

:x_pos dat 0
:y_pos dat 0
:z_pos dat 0

:x_vel_dir dat 0 				;; 0 if left, 1 if right
:x_vel dat 0
:y_vel_dir dat 0 				;; 0 if up, 1 if down
:y_vel dat 0

:x_acc_dir dat 0 				;; 0 if left, 1 if right
:x_acc dat 0
:y_acc_dir dat 0 				;; 0 if up, 1 if down
:y_acc dat 0

:boot
	SSP 0x7FF
:loop
	JSR input
	JSR handle_velocity_x
	JSR handle_velocity_y
	JSR handle_movement_x
	JSR handle_movement_y
	JSR render_char
	MOVE GR2, [x_vel]
	MOVE GR3, [x_acc]
	MOVE GR4, [x_acc_dir]
	MOVE GR5, [x_vel_dir]
	WVS
	BRA loop

:input
	PUSH GR0
	PUSH GR1

:check_up
	MOVE GR0, [0x8000]		;; up
	CMP GR0, 1
	BNE check_x				;; check next if button not down
	MOVE GR0, 8
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
	MOVE GR1, 1 				;; acceleration
	STORE GR1, x_acc
	MOVE GR1, 1 				;; acc directed right
	STORE GR1, x_acc_dir
	BRA done_directions

:acc_left
	MOVE GR1, 1					;; acceleration
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
	CMP GR0, 3					;; max speed
	BMI x_vel_done
	MOVE GR0, 3					;; max speed
	STORE GR0, x_vel

:x_vel_done

	POP GR1
	POP GR0
	RTS

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
	CMP GR0, 1					;; max speed
	BMI y_vel_done
	MOVE GR0, 1					;; max speed
	STORE GR0, y_vel

:y_vel_done

	POP GR1
	POP GR0
	RTS

:handle_movement_x
	PUSH GR0
	PUSH GR1
	PUSH GR8

	MOVE GR0, [x_vel]
	MOVE GR1, [x_pos]
	;;LSR GR0, 4
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

:handle_movement_y
	PUSH GR0
	PUSH GR1
	PUSH GR8

	MOVE GR0, [y_vel]
	MOVE GR1, [y_pos]
	;;LSR GR0, 4
	MOVE GR8, [y_vel_dir]
	CMP GR8, 1						;; handle movement right?
	BNE y_handle_movement_left
:y_handle_movement_right
	ADD GR1, GR0					;; POS + Velocity
	BRA y_handle_movement_done
:y_handle_movement_left
	SUB GR1, GR0					;; POS - Velocity
:y_handle_movement_done
	STORE GR1, y_pos

	POP GR8
	POP GR1
	POP GR0
	RTS



:render_char
	PUSH GR0

	MOVE GR0, [x_pos]
	STORE GR0, 0x9000
	MOVE GR0, [y_pos]
	STORE GR0, 0x9001

	POP GR0
	RTS


