onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider lab_tb
add wave -noupdate /lab_tb/clk
add wave -noupdate /lab_tb/rst
add wave -noupdate /lab_tb/rx
add wave -noupdate /lab_tb/seg
add wave -noupdate /lab_tb/an
add wave -noupdate /lab_tb/tb_running
add wave -noupdate /lab_tb/rxs
add wave -noupdate -divider lab
add wave -noupdate /lab_tb/uut/clk
add wave -noupdate /lab_tb/uut/rst
add wave -noupdate /lab_tb/uut/rx
add wave -noupdate /lab_tb/uut/rx1
add wave -noupdate /lab_tb/uut/rx2
add wave -noupdate /lab_tb/uut/lp
add wave -noupdate /lab_tb/uut/sp
add wave -noupdate /lab_tb/uut/sreg
add wave -noupdate -radix unsigned /lab_tb/uut/pos
add wave -noupdate -radix hexadecimal /lab_tb/uut/tal
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {88676 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ns} {525 us}
