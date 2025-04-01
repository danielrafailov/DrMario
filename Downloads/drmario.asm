################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Daniel Max, Rafailov, 1009970998
# Student 2: Christian Fisla, 1010394912
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    128
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

RESTART:
    .data
##############################################################################
# Immutable Data
##############################################################################
ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000
red_colour:
    .word 0xff0000
blue_colour:
    .word 0x0000ff 
yellow_colour:
    .word 0xffff00
white_colour:
    .word 0xFFFFFF
black_colour:
    .word 0x000000
brown_colour:
    .word 0x8B4513      
skin_colour:
    .word 0xF1C27D       
gray_colour:
    .word 0x808080       
BORDER_BOTTOM:
    .word 26832
sleep_timer:
    .word 100
sleep_timer_track:
    .word 100

##############################################################################
# Mutable Data
##############################################################################
top_left_left: .word 6392
top_left_right: .word 6396
top_right_left: .word 6400
top_right_right: .word 6404
bottom_left_left: .word 6904
bottom_left_right: .word 6908
bottom_right_left: .word 6912
bottom_right_right: .word 6916
top_left_left_start_pos: .word 6392
top_left_right_start_pos: .word 6396
top_right_left_start_pos: .word 6400
top_right_right_start_pos: .word 6404
bottom_left_left_start_pos: .word 6904
bottom_left_right_start_pos: .word 6908
bottom_right_left_start_pos: .word 6912
bottom_right_right_start_pos: .word 6916
left_colour: .word 0xff0000
right_colour: .word 0xff0000
next_left_colour: .word 0x0000ff 
next_right_colour: .word 0x0000ff 
current_orientation: .word 0    # 0 = horizontal, 1 = vertical
left_boundary: .word 53
right_boundary: .word 74
pause_flag: .word 0
top_left_bottle: .word 6864
top_right_bottle: .word 6956
bottom_left_bottle: .word 26320
bottom_right_bottle: .word 26412
columns: .word 24
column_pixels: .word 96
rows: .word 38
row_pixels: .word 152

DIFFICULTY_SELECTED: .word 1

TXT_EASY_OFFSET:   .word 7500    # roughly row 11, col ~ 44 
TXT_MED_OFFSET:    .word 12024    # a bit to the right of EASY
TXT_HARD_OFFSET:   .word 17064   # further to the right

virus_list: .word 0x20000000

##############################################################################
# Example Offsets for a "Triangle Pointer" (or single pixel) indicating selection
##############################################################################
# These pointer offsets are just a bit left of each label's offset,
# so it looks like a small arrow or highlight in front of the text.

PTR_EASY_OFFSET:   .word 7452
PTR_MED_OFFSET:    .word 11976
PTR_HARD_OFFSET:   .word 17016

##############################################################################
# Code
##############################################################################
	.text
	.globl main

select_loop:
    
    la  $t0, ADDR_DSPL         # $t0 -> address holding 0x10008000
    lw  $t0, 0($t0)            # $t0 = 0x10008000 (framebuffer base)
    la  $t1, black_colour
    lw  $t1, 0($t1)            # $t1 = black color value
    li  $t2, 128               # screen width
    li  $t3, 64                # screen height
    mul $t4, $t2, $t3          # total pixels = 128 * 64 = 8192
    li  $t5, 4                 # each pixel is 4 bytes

clear_screen_loop:
    sw  $t1, 0($t0)            # store black into this pixel
    add $t0, $t0, $t5          # move to next pixel
    sub $t4, $t4, 1            # decrement pixel counter
    bgtz $t4, clear_screen_loop
    # when finished, screen is all black

    #---------------------------------------------------------------------
    # 2) Draw "EASY", "MED", "HARD" in simple pixel form
    #    We'll do a tiny placeholder so you see them. 
    #    In a real game, you'd do a bigger pattern of sw instructions 
    #    or call a 'draw_text' subroutine.
    #---------------------------------------------------------------------
    la  $t0, ADDR_DSPL 
    lw  $t0, 0($t0)            # $t0 = 0x10008000
    la  $t1, white_colour
    lw  $t1, 0($t1)            # $t1 = white
    
    jal draw_text_easy
     
    jal draw_text_med
    
    jal draw_text_hard
    
    #---------------------------------------------------------------------
    # 3) We'll keep a cursor_index in $t7: 
    #    0 => "EASY", 1 => "MED", 2 => "HARD"
    #---------------------------------------------------------------------
    li  $t7, 0                 # Start on "EASY"

select_loop_main:

    li $v0, 32
    li $a0, 10
    syscall
    #---------------------------------------------------------------------
    # 3a) Draw the triangle cursor at whichever item $t7 points to
    #     We'll just place a single red pixel to the left of each label.
    #---------------------------------------------------------------------
    #  Clear all possible pointer spots to black first (so it "moves")
    jal  clear_select_pointers

    #  Actually draw the pointer
    #  We'll store the pointer offset for whichever $t7 is
    la   $t0, ADDR_DSPL 
    lw   $t0, 0($t0)           # $t0 = 0x10008000
    la   $t1, red_colour
    lw   $t1, 0($t1)           # $t1 = red

    # Switch on $t7 
    beq  $t7, $zero,  draw_ptr_easy
    li   $t9, 1
    beq  $t7, $t9,    draw_ptr_med
    li   $t9, 2
    beq  $t7, $t9,    draw_ptr_hard
    j    done_drawing_ptr

draw_ptr_easy:
    la   $t2, PTR_EASY_OFFSET
    lw   $t2, 0($t2) 
    add  $t2, $t2, $t0
    sw   $t1, 16($t2)
    
    addi $t2, $t2, 512
    sw   $t1, 20($t2)
    
    addi $t2, $t2, 512
    sw   $t1, 24($t2) 

    addi $t2, $t2, 512
    
    sw   $t1, 20($t2)
    
    addi $t2, $t2, 512

    sw   $t1, 16($t2)
    
    j    done_drawing_ptr

draw_ptr_med:
    la   $t2, PTR_MED_OFFSET
    lw   $t2, 0($t2) 
    add  $t2, $t2, $t0
    sw   $t1, 16($t2)
    
    addi $t2, $t2, 512
    sw   $t1, 20($t2)
    
    addi $t2, $t2, 512
    sw   $t1, 24($t2) 

    addi $t2, $t2, 512
    
    sw   $t1, 20($t2)
    
    addi $t2, $t2, 512

    sw   $t1, 16($t2)
    j    done_drawing_ptr

draw_ptr_hard:
    la   $t2, PTR_HARD_OFFSET
    lw   $t2, 0($t2) 
    add  $t2, $t2, $t0
    sw   $t1, 16($t2)
    
    addi $t2, $t2, 512
    sw   $t1, 20($t2)
    
    addi $t2, $t2, 512
    sw   $t1, 24($t2) 

    addi $t2, $t2, 512
    
    sw   $t1, 20($t2)
    
    addi $t2, $t2, 512

    sw   $t1, 16($t2)
    j    done_drawing_ptr

done_drawing_ptr:

    lw  $t0, ADDR_KBRD
    lw  $t8, 0($t0)        # $t8 = 1 if a key is currently pressed
    beq $t8, $zero, select_loop_main   # if 0 => no key => keep looping

    # If pressed, read the actual key
    lw  $t8, 4($t0)        # ASCII code in $t8

    li  $t9, 0x61          # 'a'
    beq $t8, $t9, move_cursor_right
    li  $t9, 0x64          # 'd'
    beq $t8, $t9, move_cursor_left
    li  $t9, 0x73          # 's'
    beq $t8, $t9, confirm_difficulty

    # If it's something else, just loop
    j select_loop_main

move_cursor_left:
    bgtz $t7, do_decrement   # only move left if t7>0
    j select_loop_main

do_decrement:
    addi $t7, $t7, -1        # t7--
    j select_loop_main

move_cursor_right:
    li   $t9, 2
    blt  $t7, $t9, do_increment  # only move right if t7<2
    j select_loop_main

do_increment:
    addi $t7, $t7, 1
    j select_loop_main

confirm_difficulty:
    la  $t0, DIFFICULTY_SELECTED
    sw  $t7, 0($t0)
    
    la  $t0, ADDR_DSPL         # $t0 -> address holding 0x10008000
    lw  $t0, 0($t0)            # $t0 = 0x10008000 (framebuffer base)
    la  $t1, black_colour
    lw  $t1, 0($t1)            # $t1 = black color value
    li  $t2, 128               # screen width
    li  $t3, 64                # screen height
    mul $t4, $t2, $t3          # total pixels = 128 * 64 = 8192
    li  $t5, 4                 # each pixel is 4 bytes

clear_screen_loop_before_start:
    sw  $t1, 0($t0)            # store black into this pixel
    add $t0, $t0, $t5          # move to next pixel
    sub $t4, $t4, 1            # decrement pixel counter
    bgtz $t4, clear_screen_loop_before_start
    
    # Done with selection => jump to main game code
    j main
    
draw_text_easy:
    la  $t0, ADDR_DSPL
    lw  $t0, 0($t0)           # 0x10008000
    la  $t1, white_colour
    lw  $t1, 0($t1)           # white
    lw  $t2, TXT_EASY_OFFSET            # offset for "EASY"
    add $t2, $t2, $t0         # $t2 => start in framebuffer
    
    sw $t1,   0($t2)    # col=0 => +0
    sw $t1,   4($t2)    # col=1 => +4
    sw $t1,   8($t2)    # col=2 => +8
    sw $t1,  12($t2)    # col=3 => +12

    # A(6..7)
    sw $t1,  24($t2)    # col=6 => +24
    sw $t1,  28($t2)    # col=7 => +28

    # S(10..12)
    sw $t1,  40($t2)   # col=10 => +40
    sw $t1,  44($t2)   # col=11 => +44
    sw $t1,  48($t2)   # col=12 => +48

    # Y(15,18) => col15 => +60, col18=>+72
    sw $t1,  56($t2)   
    sw $t1,  68($t2)

    # Move down one row => +512
    addi $t2, $t2, 512

    # E => col0 => 1
    sw $t1,   0($t2)
    # A => col5=20, col8=32 => let's say col5, col8
    sw $t1,  20($t2)
    sw $t1,  32($t2)
    # S => col10 => +40
    sw $t1,  40($t2)
    # Y => col15,16 => +60,64
    sw $t1,  56($t2)
    sw $t1,  68($t2)

    addi $t2, $t2, 512

    # ========== ROW 2 ==========
    # E => col=0..2 => 111
    sw $t1,   0($t2)
    sw $t1,   4($t2)
    sw $t1,   8($t2)
    # A => col5..8 => 1111 => 20,24,28,32
    sw $t1,  20($t2)
    sw $t1,  24($t2)
    sw $t1,  28($t2)
    sw $t1,  32($t2)
    # S => col10..12 => 011 => 40,44
    sw $t1,  40($t2)
    sw $t1,  44($t2)
    sw $t1,  48($t2)
    # Y => col15..18 => 0010 => let's pick col16=64
    sw $t1,  56($t2)
    sw $t1,  60($t2)
    sw $t1,  64($t2)
    sw $t1,  68($t2)
    
    addi $t2, $t2, 512

    sw $t1,   0($t2)   # E => col0
    sw $t1,  32($t2)   # A => col8
    sw $t1,  48($t2)   # S => col11
    sw $t1,  68($t2)   # Y => col15

    addi $t2, $t2, 512

    # ========== ROW 4 ==========
    # final row
    # E => col=0..3
    sw $t1,   0($t2)
    sw $t1,   4($t2)
    sw $t1,   8($t2)
    sw $t1,  12($t2)

    # A => col5..8 
    sw $t1,  20($t2)
    sw $t1,  24($t2)
    sw $t1,  28($t2)
    sw $t1,  32($t2)

    # S => col10..13
    sw $t1,  40($t2)
    sw $t1,  44($t2)
    sw $t1,  48($t2)

    # Y => col15..18
    sw $t1,  56($t2)
    sw $t1,  60($t2)
    sw $t1,  64($t2)
    sw $t1,  68($t2)

    jr $ra

draw_text_med:
    la  $t0, ADDR_DSPL
    lw  $t0, 0($t0)
    la  $t1, white_colour
    lw  $t1, 0($t1)
    lw  $t2, TXT_MED_OFFSET
    add $t2, $t2, $t0

    # We'll do 5 rows, each row +512. "M E D" horizontally => ~12 columns.
    # Row 0: e.g. M => columns 0,4, E => columns 5..7, D => columns 9..11, etc.
    # We'll just do a simple shape again.
    # row0
    sw $t1, 0($t2)    # M col=0
    sw $t1, 16($t2)   # M col=4
    sw $t1, 24($t2)   # E col=5
    sw $t1, 28($t2)   # E col=6
    sw $t1, 32($t2)   # E col=7
    sw $t1, 40($t2)   # D col=9
    sw $t1, 44($t2)   # D col=10
    sw $t1, 48($t2)   # D col=11

    addi $t2, $t2, 512
    # row1
    sw $t1, 0($t2) 
    sw $t1, 4($t2)
    sw $t1, 12($t2)
    sw $t1, 16($t2)
    sw $t1, 24($t2)
    sw $t1, 40($t2)
    sw $t1, 52($t2)

    addi $t2, $t2, 512
    # row2
    sw $t1, 0($t2) 
    sw $t1, 8($t2)
    sw $t1, 16($t2)
    sw $t1, 24($t2)
    sw $t1, 28($t2)
    sw $t1, 40($t2)
    sw $t1, 52($t2)

    addi $t2, $t2, 512
    # row3
    sw $t1, 0($t2)
    sw $t1, 16($t2)
    sw $t1, 24($t2)
    sw $t1, 40($t2)
    sw $t1, 52($t2)

    addi $t2, $t2, 512
    # row4
    sw $t1, 0($t2)
    sw $t1, 16($t2)
    sw $t1, 24($t2)
    sw $t1, 28($t2)
    sw $t1, 32($t2)
    sw $t1, 40($t2)
    sw $t1, 44($t2)
    sw $t1, 48($t2)
    jr $ra
    
draw_text_hard:
    # "HARD" at offset=10000
    la  $t0, ADDR_DSPL
    lw  $t0, 0($t0)
    la  $t1, white_colour
    lw  $t1, 0($t1)
    lw $t2, TXT_HARD_OFFSET
    add $t2, $t2, $t0

    # 5 rows, "H A R D" ~16 columns
    # row0
    sw $t1,  0($t2)   # H col0
    sw $t1, 12($t2)   # H col3
    sw $t1, 24($t2)   # A col5
    sw $t1, 28($t2)   # A col6
    sw $t1, 40($t2)   # R col10
    sw $t1, 44($t2)   # R col10
    sw $t1, 48($t2)   # R col10
    sw $t1, 60($t2)   # D col15
    sw $t1, 64($t2)   # D col16
    sw $t1, 68($t2)   # D col16

    addi $t2, $t2, 512
    # row1
    sw $t1,  0($t2)
    sw $t1, 12($t2)
    sw $t1, 20($t2)
    sw $t1, 32($t2)
    sw $t1, 40($t2)  
    sw $t1, 52($t2)
    sw $t1, 60($t2)
    sw $t1, 72($t2)

    addi $t2, $t2, 512
    # row2
    sw $t1,  0($t2)
    sw $t1,  4($t2)
    sw $t1,  8($t2)
    sw $t1, 12($t2)
    sw $t1, 20($t2)
    sw $t1, 24($t2)
    sw $t1, 28($t2)
    sw $t1, 32($t2)
    sw $t1, 40($t2)
    sw $t1, 52($t2)
    sw $t1, 60($t2)
    sw $t1, 72($t2)

    addi $t2, $t2, 512
    # row3
    sw $t1,  0($t2)
    sw $t1, 12($t2)
    sw $t1, 20($t2)
    sw $t1, 32($t2)
    sw $t1, 40($t2)
    sw $t1, 44($t2)
    sw $t1, 48($t2)
    sw $t1, 60($t2)
    sw $t1, 72($t2)

    addi $t2, $t2, 512
    # row4
    sw $t1,  0($t2)
    sw $t1, 12($t2)
    sw $t1, 20($t2)
    sw $t1, 32($t2)
    sw $t1, 40($t2)
    sw $t1, 52($t2)
    sw $t1, 60($t2)
    sw $t1, 64($t2)
    sw $t1, 68($t2)

    jr $ra

##############################################################################
# Helper subroutine to clear all pointer spots to black (so the red "triangle"
# only shows where the player's selection is).
##############################################################################
clear_select_pointers:
    # We'll just store black into each possible pointer offset
    la  $t0, ADDR_DSPL
    lw  $t0, 0($t0)           # $t0 = 0x10008000
    la  $t1, black_colour
    lw  $t1, 0($t1)           # black

    # Clear pointer for easy
    la  $t2, PTR_EASY_OFFSET
    lw  $t2, 0($t2)
    add $t2, $t2, $t0
    sw  $t1, 16($t2)
    sw  $t1, 532($t2)
    sw  $t1, 1048($t2)
    sw  $t1, 1556($t2)
    sw  $t1, 2064($t2)

    # Clear pointer for med
    la  $t2, PTR_MED_OFFSET
    lw  $t2, 0($t2)
    add $t2, $t2, $t0
    sw  $t1, 16($t2)
    sw  $t1, 532($t2)
    sw  $t1, 1048($t2)
    sw  $t1, 1556($t2)
    sw  $t1, 2064($t2)

    # Clear pointer for hard
    la  $t2, PTR_HARD_OFFSET
    lw  $t2, 0($t2)
    add $t2, $t2, $t0
    sw  $t1, 16($t2)
    sw  $t1, 532($t2)
    sw  $t1, 1048($t2)
    sw  $t1, 1556($t2)
    sw  $t1, 2064($t2)

    jr $ra

main:
    lw $t0, ADDR_DSPL
    jal draw_cup_and_next_pill
    jal draw_bottle
    jal draw_dr_mario
    jal draw_viruses
    
    jal spawn_viruses
    
    lw $t3, DIFFICULTY_SELECTED
    li $t4, 0
    beq $t3, $t4, easy_changes
    addi $t4, $t4, 1
    beq $t3, $t4, med_changes
    addi $t4, $t4, 1
    beq $t3, $t4, hard_changes
    
spawn_done:
    jal random_pill

game_loop:
    lw $t0, ADDR_KBRD
    lw $t8, 0($t0)
    beq $t8, 1, keyboard_input
    
    lw $t7, pause_flag
    beq $t7, 1, skip_pause

    lw $t0, ADDR_DSPL
    
were_back:

    jal check_collisions
    jal game_over_check
    
    jal clear_old_location

    lw $t2, top_left_left
    lw $t3, top_left_right
    lw $t4, top_right_left
    lw $t5, top_right_right
    lw $t6, bottom_left_left
    lw $t7, bottom_left_right
    lw $t8, bottom_right_left
    lw $t9, bottom_right_right

    addi $t2, $t2, 512  
    addi $t3, $t3, 512  
    addi $t4, $t4, 512
    addi $t5, $t5, 512
    addi $t6, $t6, 512
    addi $t7, $t7, 512
    addi $t8, $t8, 512 
    addi $t9, $t9, 512

    sw $t2, top_left_left
    sw $t3, top_left_right
    sw $t4, top_right_left
    sw $t5, top_right_right
    sw $t6, bottom_left_left
    sw $t7, bottom_left_right
    sw $t8, bottom_right_left
    sw $t9, bottom_right_right

skip_pause:

    lw $t0, ADDR_DSPL 
    jal draw_cup_and_next_pill
    jal draw_pill
    addi $t1, $t1, 512
    
    li $v0, 32
    lw $a0, sleep_timer
    syscall

    j game_loop

easy_changes:
    li $t2, 100
    sw $t2, sleep_timer
    sw $t2, sleep_timer_track

    j spawn_done

med_changes:
    li $t2, 80
    sw $t2, sleep_timer
    sw $t2, sleep_timer_track

    j spawn_done
    
hard_changes:
    li $t2, 60
    sw $t2, sleep_timer
    sw $t2, sleep_timer_track

    j spawn_done

check_collisions:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t2, current_orientation
    
    beq $t2, 0, first_state_check
    beq $t2, 1, second_state_check
    beq $t2, 2, third_state_check
    beq $t2, 3, fourth_state_check

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
check_left_collision:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    lw   $t2, top_left_left    # Load the x-coordinate (address offset) for the top-left pixel
    addi $t2, $t2, -4
    lw   $t4, left_boundary    # Left boundary in pixels (45)
    andi $t3, $t2, 0x1FF        # Get offset within the row in bytes (0–511)
    srl  $t3, $t3, 2           # Convert byte offset to pixel column (0–127)

    blt  $t3, $t4, collision_detected_left
    
    li   $v0, 0               # No collision
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
collision_detected_left:
    li   $v0, 1               # Collision detected
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

check_right_collision:
    addi $sp, $sp, -4         # Create stack frame
    sw   $ra, 0($sp)          # Save return address

    lw   $t2, top_right_right # Load x-coordinate of the pill's right-most pixel
    lw   $t4, right_boundary
    andi $t3, $t2, 0x1FF      # Get offset within the row in bytes (0–511)
    srl  $t3, $t3, 2         # Convert byte offset to pixel column (divide by 4)

    bgt  $t3, $t4, collision_detected_right  # If pixel column > right boundary, collision detected

    li   $v0, 0              # No collision
    lw   $ra, 0($sp)         # Restore return address
    addi $sp, $sp, 4         # Restore stack pointer
    jr   $ra                 # Return

collision_detected_right:
    li   $v0, 1              # Collision detected
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
first_state_check:
    addi $sp, $sp, -4         # Create stack frame
    sw   $ra, 0($sp)          # Save return address
    
    lw $t2, BORDER_BOTTOM
    lw $t0, ADDR_DSPL
    
    lw $t6, bottom_left_left
    add $t6, $t6, $t0
    addi $t6, $t6, 512
    lw $t7, bottom_left_right
    add $t7, $t7, $t0
    addi $t7, $t7, 512
    lw $t8, bottom_right_left
    add $t8, $t8, $t0
    addi $t8, $t8, 512
    lw $t9, bottom_right_right
    add $t9, $t9, $t0
    addi $t9, $t9, 512
    
    bge $t1, $t2, pill_at_bottom_event
    
    lw $t6, 0($t6) # Load the colour of the pixel below the bottom left pixel
    lw $t7, 0($t7) # Load the colour of the pixel below the bottom left right pixel
    lw $t8, 0($t8) # Load the colour of the pixel below the bottom right left pixel
    lw $t9, 0($t9) # Load the colour of the pixel below the bottom right right pixel

    # Check for collisions with non-black pixels
    lw $t5, black_colour

    bne $t5, $t6, pill_at_bottom_event
    bne $t5, $t7, pill_at_bottom_event
    bne $t5, $t8, pill_at_bottom_event
    bne $t5, $t9, pill_at_bottom_event
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
second_state_check:
    addi $sp, $sp, -4         # Create stack frame
    sw   $ra, 0($sp)          # Save return address
    
    lw $t2, BORDER_BOTTOM
    lw $t0, ADDR_DSPL
    
    lw $t6, top_right_right
    add $t6, $t6, $t0
    addi $t6, $t6, 512
    lw $t7, bottom_right_right
    add $t7, $t7, $t0
    addi $t7, $t7, 512
    
    bge $t1, $t2, pill_at_bottom_event
    
    lw $t6, 0($t6) # Load the colour of the pixel below the bottom left pixel
    lw $t7, 0($t7) # Load the colour of the pixel below the bottom left right pixel

    # Check for collisions with non-black pixels
    lw $t5, black_colour

    bne $t5, $t6, pill_at_bottom_event
    bne $t5, $t7, pill_at_bottom_event
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

third_state_check:
    addi $sp, $sp, -4         # Create stack frame
    sw   $ra, 0($sp)          # Save return address
    
    lw $t2, BORDER_BOTTOM
    
    lw $t0, ADDR_DSPL
    
    lw $t6, top_left_left
    add $t6, $t6, $t0
    addi $t6, $t6, 512
    lw $t7, top_left_right
    add $t7, $t7, $t0
    addi $t7, $t7, 512
    lw $t8, top_right_left
    add $t8, $t8, $t0
    addi $t8, $t8, 512
    lw $t9, top_right_right
    add $t9, $t9, $t0
    addi $t9, $t9, 512
    
    addi $t2, $t2, -512
    bge $t1, $t2, pill_at_bottom_event
    
    lw $t6, 0($t6) # Load the colour of the pixel below the bottom left pixel
    lw $t7, 0($t7) # Load the colour of the pixel below the bottom left right pixel
    lw $t8, 0($t8) # Load the colour of the pixel below the bottom right left pixel
    lw $t9, 0($t9) # Load the colour of the pixel below the bottom right right pixel

    # Check for collisions with non-black pixels
    lw $t5, black_colour

    bne $t5, $t6, pill_at_bottom_event
    bne $t5, $t7, pill_at_bottom_event
    bne $t5, $t8, pill_at_bottom_event
    bne $t5, $t9, pill_at_bottom_event
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
fourth_state_check:
    addi $sp, $sp, -4         # Create stack frame
    sw   $ra, 0($sp)          # Save return address
    
    lw $t2, BORDER_BOTTOM
    lw $t0, ADDR_DSPL
    
    lw $t6, top_left_left
    add $t6, $t6, $t0
    addi $t6, $t6, 512
    lw $t7, bottom_left_left
    add $t7, $t7, $t0
    addi $t7, $t7, 512
    
    addi $t2, $t2, -1536
    bge $t1, $t2, pill_at_bottom_event
    
    lw $t6, 0($t6) # Load the colour of the pixel below the bottom left pixel
    lw $t7, 0($t7) # Load the colour of the pixel below the bottom left right pixel

    # Check for collisions with non-black pixels
    lw $t5, black_colour

    bne $t5, $t6, pill_at_bottom_event
    bne $t5, $t7, pill_at_bottom_event
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

keyboard_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $a0, 4($t0)
    
    lw $t8, pause_flag
    li $t7, 1
    beq $t8, $t7, pause_input_skip
    
    beq $a0, 0x71, exit
    beq $a0, 0x61, move_left    # A key
    beq $a0, 0x64, move_right   # D key
    beq $a0, 0x73, incr_speed   # S key
    beq $a0, 0x77, rotate_pill  # W key
    
pause_input_skip:
    beq $a0, 0x70, pause

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
pause:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t7, pause_flag      # Load current pause flag
    li   $t3, 0
    beq  $t7, $t3, set_pause   # If unpaused, go to set_pause

    li   $t7, 0
    sw   $t7, pause_flag
    j    done_pause

set_pause:
    li   $t7, 1
    sw   $t7, pause_flag       # Set pause flag (paused)
    
done_pause:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

rotate_pill:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Set up syscall arguments
    li $v0, 31    # syscall code for async play note
    li $a1, 1000  # duration
    li $a2, 8     # instrument
    li $a3, 100   # volume
    syscall
    
    lw $t2, current_orientation
    li $t6, 0
    li $t7, 1
    li $t8, 2
    li $t9, 3
    
    beq $t2, $t6, rotate_east_to_south
    beq $t2, $t7, rotate_south_to_west
    beq $t2, $t8, rotate_west_to_north
    beq $t2, $t9, rotate_north_to_east
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

rotate_east_to_south:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_old_location

    lw $t2, top_left_left
    addi $t2, $t2, -508
    sw $t2, top_left_left
    
    lw $t2, bottom_left_left
    addi $t2, $t2, -1024
    sw $t2, bottom_left_left
    
    lw $t2, top_left_right
    addi $t2, $t2, 0
    sw $t2, top_left_right
    
    lw $t2, bottom_left_right
    addi $t2, $t2, -516
    sw $t2, bottom_left_right
    
    lw $t2, top_right_left
    addi $t2, $t2, 504
    sw $t2, top_right_left
    
    lw $t2, bottom_right_left
    addi $t2, $t2, -4
    sw $t2, bottom_right_left
    
    lw $t2, top_right_right
    addi $t2, $t2, 1016
    sw $t2, top_right_right
    
    lw $t2, bottom_right_right
    addi $t2, $t2, 500
    sw $t2, bottom_right_right
    
    lw $t2, current_orientation
    addi $t2, $t2, 1
    sw $t2, current_orientation
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
rotate_south_to_west:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_old_location

    lw $t2, top_left_left
    addi $t2, $t2, 1032
    sw $t2, top_left_left
    
    lw $t2, bottom_left_left
    addi $t2, $t2, 524
    sw $t2, bottom_left_left
    
    lw $t2, top_left_right
    addi $t2, $t2, 516
    sw $t2, top_left_right
    
    lw $t2, bottom_left_right
    addi $t2, $t2, 8
    sw $t2, bottom_left_right
    
    lw $t2, top_right_left
    addi $t2, $t2, 4
    sw $t2, top_right_left
    
    lw $t2, bottom_right_left
    addi $t2, $t2, -512
    sw $t2, bottom_right_left
    
    lw $t2, top_right_right
    addi $t2, $t2, -516
    sw $t2, top_right_right
    
    lw $t2, bottom_right_right
    addi $t2, $t2, -1024
    sw $t2, bottom_right_right
    
    lw $t2, current_orientation
    addi $t2, $t2, 1
    sw $t2, current_orientation
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

rotate_west_to_north:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_old_location

    lw $t2, top_left_left
    addi $t2, $t2, 500
    sw $t2, top_left_left
    
    lw $t2, bottom_left_left
    addi $t2, $t2, 1016
    sw $t2, bottom_left_left
    
    lw $t2, top_left_right
    addi $t2, $t2, -8
    sw $t2, top_left_right
    
    lw $t2, bottom_left_right
    addi $t2, $t2, 508
    sw $t2, bottom_left_right
    
    lw $t2, top_right_left
    addi $t2, $t2, -516
    sw $t2, top_right_left
    
    lw $t2, bottom_right_left
    addi $t2, $t2, 0
    sw $t2, bottom_right_left
    
    lw $t2, top_right_right
    addi $t2, $t2, -1024
    sw $t2, top_right_right
    
    lw $t2, bottom_right_right
    addi $t2, $t2, -508
    sw $t2, bottom_right_right
    
    lw $t2, current_orientation
    addi $t2, $t2, 1
    sw $t2, current_orientation
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
rotate_north_to_east:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_old_location

    lw $t2, top_left_left
    addi $t2, $t2, -1028
    sw $t2, top_left_left
    
    lw $t2, bottom_left_left
    addi $t2, $t2, -520
    sw $t2, bottom_left_left
    
    lw $t2, top_left_right
    addi $t2, $t2, -512
    sw $t2, top_left_right
    
    lw $t2, bottom_left_right
    addi $t2, $t2, -4
    sw $t2, bottom_left_right
    
    lw $t2, top_right_left
    addi $t2, $t2, 4
    sw $t2, top_right_left
    
    lw $t2, bottom_right_left
    addi $t2, $t2, 512
    sw $t2, bottom_right_left
    
    lw $t2, top_right_right
    addi $t2, $t2, 520
    sw $t2, top_right_right
    
    lw $t2, bottom_right_right
    addi $t2, $t2, 1028
    sw $t2, bottom_right_right
    
    lw $t2, current_orientation
    li $t2, 0
    sw $t2, current_orientation
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

incr_speed:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, sleep_timer     # Load current timer
    lw $t1, sleep_timer_track
    beq $t0, $t1, set_fast  # If currently 100, go to set_fast
    lw $t0, sleep_timer_track             # Else, set back to normal
    j done_toggle

set_fast:
    li $t0, 10              # Set to fast speed

done_toggle:
    sw $t0, sleep_timer     # Store updated timer

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
move_left:
    # Set up syscall arguments
    li $v0, 31    # syscall code for async play note
    li $a1, 1000  # duration
    li $a2, 8     # instrument
    li $a3, 100   # volume
    syscall
    
    addi $sp, $sp, -4       # Move stack pointer to empty location
    sw $ra, 0($sp)          # Push $ra onto the stack, to keep it safe
    
    jal clear_old_location
    
    jal check_left_collision
    beq  $v0, 1, skip_move_left 
    
    # Load the current coordinates from memory
    lw $t2, top_left_left
    lw $t3, top_left_right
    lw $t4, top_right_left
    lw $t5, top_right_right
    lw $t6, bottom_left_left
    lw $t7, bottom_left_right
    lw $t8, bottom_right_left
    lw $t9, bottom_right_right

    # Decrement the x-coordinate (move pill left)
    addi $t2, $t2, -8
    addi $t3, $t3, -8
    addi $t4, $t4, -8
    addi $t5, $t5, -8
    addi $t6, $t6, -8
    addi $t7, $t7, -8
    addi $t8, $t8, -8
    addi $t9, $t9, -8

    # Store the updated coordinates back to memory
    sw $t2, top_left_left
    sw $t3, top_left_right
    sw $t4, top_right_left
    sw $t5, top_right_right
    sw $t6, bottom_left_left
    sw $t7, bottom_left_right
    sw $t8, bottom_right_left
    sw $t9, bottom_right_right
    
    lw $ra, 0($sp)    # Pop return address off the stack
    addi $sp, $sp, 4  # Move stack pointer to top element of the stack
    
    jr $ra

skip_move_left:

    lw   $ra, 0($sp)    # Restore return address
    addi $sp, $sp, 4
    jr   $ra
    
move_right:
    # Set up syscall arguments
    li $v0, 31    # syscall code for async play note
    li $a1, 1000  # duration
    li $a2, 8     # instrument
    li $a3, 100   # volume
    syscall
    
    addi $sp, $sp, -4       # Move stack pointer to empty location
    sw $ra, 0($sp)          # Push $ra onto the stack, to keep it safe
    
    jal clear_old_location
    
    jal check_right_collision  # Check if pill is at or past the right boundary
    beq  $v0, 1, skip_move_right  # If collision detected, skip moving
    
    # Load the current coordinates from memory
    lw $t2, top_left_left
    lw $t3, top_left_right
    lw $t4, top_right_left
    lw $t5, top_right_right
    lw $t6, bottom_left_left
    lw $t7, bottom_left_right
    lw $t8, bottom_right_left
    lw $t9, bottom_right_right

    # Decrement the x-coordinate (move pill left)
    addi $t2, $t2, 8 
    addi $t3, $t3, 8
    addi $t4, $t4, 8
    addi $t5, $t5, 8
    addi $t6, $t6, 8
    addi $t7, $t7, 8
    addi $t8, $t8, 8
    addi $t9, $t9, 8

    # Store the updated coordinates back to memory
    sw $t2, top_left_left
    sw $t3, top_left_right
    sw $t4, top_right_left
    sw $t5, top_right_right
    sw $t6, bottom_left_left
    sw $t7, bottom_left_right
    sw $t8, bottom_right_left
    sw $t9, bottom_right_right

    lw $ra, 0($sp)    # Pop return address off the stack
    addi $sp, $sp, 4  # Move stack pointer to top element of the stack
    
    jr $ra

skip_move_right:
    lw   $ra, 0($sp)        # Restore return address
    addi $sp, $sp, 4        # Restore stack pointer
    jr   $ra                # Return to caller
	
pill_at_bottom_event:    
    addi $sp, $sp, -4       # Move stack pointer to empty location
    sw $ra, 0($sp)          # Push $ra onto the stack, to keep it safe

    jal four_in_a_row_horizontal_check
    jal four_in_a_row_vertical_check
    
    lw $t2, top_left_left_start_pos
    lw $t3, top_left_right_start_pos
    lw $t4, top_right_left_start_pos
    lw $t5, top_right_right_start_pos
    lw $t6, bottom_left_left_start_pos
    lw $t7, bottom_left_right_start_pos
    lw $t8, bottom_right_left_start_pos
    lw $t9, bottom_right_right_start_pos
    
    sw $t2, top_left_left
    sw $t3, top_left_right
    sw $t4, top_right_left
    sw $t5, top_right_right
    sw $t6, bottom_left_left
    sw $t7, bottom_left_right
    sw $t8, bottom_right_left
    sw $t9, bottom_right_right
    
    lw $t2, next_left_colour
    lw $t3, next_right_colour
    
    sw $t2, left_colour
    sw $t3, right_colour
    
    # Set up syscall arguments
    li $v0, 31    # syscall code for async play note
    li $a1, 1000  # duration
    li $a2, 8     # instrument
    li $a3, 100   # volume
    syscall
    
    jal random_pill
    
    # set orientation back to default
    lw $t2, current_orientation
    li $t2, 0
    sw $t2, current_orientation

    li $t1, 0
    
    lw $t2, sleep_timer_track
    
    li $t9, 40
    beq $t9, $t2, do_not_decrease_speed_jump
    
    addi $t2, $t2, -1
    sw $t2, sleep_timer_track
    
do_not_decrease_speed_jump:

    lw $t0, sleep_timer_track      # Reset speed to normal
    sw $t0, sleep_timer
    
    lw $ra, 0($sp)    # Pop return address off the stack
    addi $sp, $sp, 4  # Move stack pointer to top element of the stack
    
    jr $ra
	
random_pill:
    addi $sp, $sp, -4       # Move stack pointer to empty location
    sw $ra, 0($sp)          # Push $ra onto the stack, to keep it safe

    li $v0, 42     # generate a random number between 0 and 5
    li $a0, 0
    li $a1, 6
    syscall
    
    li $v0, 1
    syscall

    # Get the colours based on the combination
    li $t2, 0              # Initialize index for the first half of the pill
    li $t3, 0              # Initialize index for the second half of the pill

    # Determine first colour based on pill combination
    beq $a0, 0x00000000, red_red
    beq $a0, 0x00000001, blue_blue
    beq $a0, 0x00000002, yellow_yellow
    beq $a0, 0x00000003, red_blue
    beq $a0, 0x00000004, red_yellow
    beq $a0, 0x00000005, blue_yellow
    
    lw $ra, 0($sp)    # Pop return address off the stack
    addi $sp, $sp, 4  # Move stack pointer to top element of the stack
    
    jr $ra
red_red:
    lw $t0, red_colour    # Load the value of red_colour into register $t0
    sw $t0, next_left_colour   # Store the value of $t0 (red_colour) into left_colour
    sw $t0, next_right_colour  # Store the value of $t0 (red_colour) into right_colour
    jr $ra

blue_blue:
    lw $t0, blue_colour   # Load the value of blue_colour into register $t0
    sw $t0, next_left_colour   # Store the value of $t0 (blue_colour) into left_colour
    sw $t0, next_right_colour  # Store the value of $t0 (blue_colour) into right_colour
    jr $ra

yellow_yellow:
    lw $t0, yellow_colour # Load the value of yellow_colour into register $t0
    sw $t0, next_left_colour   # Store the value of $t0 (yellow_colour) into left_colour
    sw $t0, next_right_colour  # Store the value of $t0 (yellow_colour) into right_colour
    jr $ra

red_blue:
    lw $t0, red_colour    # Load the value of red_colour into register $t0
    sw $t0, next_left_colour   # Store the value of $t0 (red_colour) into left_colour
    lw $t0, blue_colour   # Load the value of blue_colour into register $t0
    sw $t0, next_right_colour  # Store the value of $t0 (blue_colour) into right_colour
    jr $ra

red_yellow:
    lw $t0, red_colour    # Load the value of red_colour into register $t0
    sw $t0, next_left_colour   # Store the value of $t0 (red_colour) into left_colour
    lw $t0, yellow_colour # Load the value of yellow_colour into register $t0
    sw $t0, next_right_colour  # Store the value of $t0 (yellow_colour) into right_colour
    jr $ra

blue_yellow:
    lw $t0, blue_colour   # Load the value of blue_colour into register $t0
    sw $t0, next_left_colour   # Store the value of $t0 (blue_colour) into left_colour
    lw $t0, yellow_colour # Load the value of yellow_colour into register $t0
    sw $t0, next_right_colour  # Store the value of $t0 (yellow_colour) into right_colour
    jr $ra

draw_cup_and_next_pill:
    #draw cup
    lw $t0, ADDR_DSPL
    lw $t4, white_colour
    
    sw $t4, 6284($t0)
    sw $t4, 6796($t0)
    sw $t4, 7308($t0)
    sw $t4, 7820($t0)
    sw $t4, 8332($t0)
    sw $t4, 8844($t0)
    sw $t4, 9356($t0)
    
    sw $t4, 9324($t0)
    sw $t4, 9328($t0)
    sw $t4, 9332($t0)
    sw $t4, 9336($t0)
    sw $t4, 9340($t0)
    sw $t4, 9344($t0)
    sw $t4, 9348($t0)
    sw $t4, 9352($t0)
    sw $t4, 9356($t0)
    
    sw $t4, 6248($t0)
    sw $t4, 6760($t0)
    sw $t4, 7272($t0)
    sw $t4, 7784($t0)
    sw $t4, 8296($t0)
    sw $t4, 8808($t0)
    sw $t4, 9320($t0)
    
    #draw next pill
    lw $t0, ADDR_DSPL   # Load the address of the display back into $t0

    # Load left and right colours into registers
    lw $t8, next_left_colour      # Load left colour into $t2
    lw $t9, next_right_colour     # Load right colour into $t3

    # Draw the left side of the pill
    li $t2, 7288    # Load the top left left coordinate into $t1
    add $t4, $t0, $t2        # Add this to the value of the display and store it in $t4
    sw $t8, 0($t4)           # Put the left colour into $t4 and draw to the display

    li $t2, 6776   # Load the top left right coordinate into $t1
    add $t4, $t0, $t2        # Add this to the value of the display and store it in $t4
    sw $t8, 0($t4)           # Put the left colour into $t4 and draw to the display

    li $t2, 7292 # Load the bottom left left coordinate into $t1
    add $t4, $t0, $t2     # Add this to the value of the display and store it in $t4
    sw $t8, 0($t4)           # Put the left colour into $t4 and draw to the display

    li $t2, 6780
    add $t4, $t0, $t2
    sw $t8, 0($t4)

    # Draw the right side of the pill
    li $t2, 6264
    add $t4, $t0, $t2
    sw $t9, 0($t4)

    li $t2, 5752
    add $t4, $t0, $t2
    sw $t9, 0($t4)

    li $t2, 6268
    add $t4, $t0, $t2
    sw $t9, 0($t4)

    li $t2, 5756
    add $t4, $t0, $t2
    sw $t9, 0($t4)

    jr $ra
    
draw_dr_mario:
    lw $t0, ADDR_DSPL
    lw $t1, blue_colour
    sw $t1, 4964($t0)
    sw $t1, 4968($t0)
    sw $t1, 4972($t0)
    sw $t1, 4976($t0)
    sw $t1, 4980($t0)
    sw $t1, 4984($t0)
    sw $t1, 4988($t0)
    sw $t1, 5472($t0)
    sw $t1, 5476($t0)
    sw $t1, 5500($t0)
    sw $t1, 5984($t0)
    sw $t1, 5992($t0)
    sw $t1, 5996($t0)
    sw $t1, 6000($t0)
    sw $t1, 6004($t0)
    sw $t1, 6008($t0)
    sw $t1, 6012($t0)
    sw $t1, 6496($t0)
    sw $t1, 6500($t0)
    sw $t1, 6504($t0)
    sw $t1, 6508($t0)
    sw $t1, 6512($t0)
    sw $t1, 6516($t0)
    sw $t1, 6520($t0)
    sw $t1, 6524($t0)
    sw $t1, 7008($t0)
    sw $t1, 7012($t0)
    sw $t1, 7016($t0)
    sw $t1, 7020($t0)
    sw $t1, 7024($t0)
    sw $t1, 7028($t0)
    sw $t1, 7032($t0)
    sw $t1, 7036($t0)
    sw $t1, 7520($t0)
    sw $t1, 7524($t0)
    sw $t1, 7528($t0)
    sw $t1, 7532($t0)
    sw $t1, 7536($t0)
    sw $t1, 7540($t0)
    sw $t1, 7544($t0)
    sw $t1, 7548($t0)
    sw $t1, 8036($t0)
    sw $t1, 8040($t0)
    sw $t1, 8044($t0)
    sw $t1, 8048($t0)
    sw $t1, 8052($t0)
    sw $t1, 8056($t0)
    sw $t1, 8060($t0)
    lw $t2, red_colour
    sw $t2, 4996($t0)
    sw $t2, 5000($t0)
    sw $t2, 5004($t0)
    sw $t2, 5008($t0)
    sw $t2, 5012($t0)
    sw $t2, 5016($t0)
    sw $t2, 5528($t0)
    sw $t2, 5532($t0)
    sw $t2, 6020($t0)
    sw $t2, 6024($t0)
    sw $t2, 6028($t0)
    sw $t2, 6032($t0)
    sw $t2, 6036($t0)
    sw $t2, 6040($t0)
    sw $t2, 6044($t0)
    sw $t2, 6532($t0)
    sw $t2, 6536($t0)
    sw $t2, 6540($t0)
    sw $t2, 6544($t0)
    sw $t2, 6548($t0)
    sw $t2, 6552($t0)
    sw $t2, 6556($t0)
    sw $t2, 7044($t0)
    sw $t2, 7048($t0)
    sw $t2, 7052($t0)
    sw $t2, 7056($t0)
    sw $t2, 7060($t0)
    sw $t2, 7064($t0)
    sw $t2, 7068($t0)
    sw $t2, 7556($t0)
    sw $t2, 7560($t0)
    sw $t2, 7564($t0)
    sw $t2, 7568($t0)
    sw $t2, 7572($t0)
    sw $t2, 7576($t0)
    sw $t2, 7580($t0)
    sw $t2, 8080($t0)
    sw $t2, 8084($t0)
    sw $t2, 8088($t0)
    lw $t3, gray_colour
    sw $t3, 5480($t0)
    sw $t3, 5484($t0)
    sw $t3, 5488($t0)
    sw $t3, 5492($t0)
    sw $t3, 5496($t0)
    sw $t3, 5988($t0)
    sw $t3, 9080($t0)
    sw $t3, 9608($t0)
    sw $t3, 10088($t0)
    sw $t3, 10108($t0)
    sw $t3, 10112($t0)
    sw $t3, 10128($t0)
    sw $t3, 10132($t0)
    sw $t3, 10136($t0)
    sw $t3, 10140($t0)
    sw $t3, 10144($t0)
    sw $t3, 10148($t0)
    sw $t3, 10152($t0)
    sw $t3, 10156($t0)
    sw $t3, 10160($t0)
    sw $t3, 10164($t0)
    sw $t3, 10676($t0)
    sw $t3, 15280($t0)
    sw $t3, 15792($t0)
    sw $t3, 17840($t0)
    sw $t3, 18352($t0)
    sw $t3, 18864($t0)
    sw $t3, 20912($t0)
    sw $t3, 20916($t0)
    sw $t3, 21424($t0)
    sw $t3, 21896($t0)
    sw $t3, 21908($t0)
    sw $t3, 21920($t0)
    sw $t3, 21936($t0)
    sw $t3, 21944($t0)
    sw $t3, 21948($t0)
    sw $t3, 21952($t0)
    sw $t3, 21956($t0)
    sw $t3, 21960($t0)
    sw $t3, 22388($t0)
    sw $t3, 22392($t0)
    sw $t3, 22396($t0)
    sw $t3, 22400($t0)
    sw $t3, 22404($t0)
    sw $t3, 22428($t0)
    sw $t3, 22436($t0)
    sw $t3, 22440($t0)
    sw $t3, 22444($t0)
    sw $t3, 22448($t0)
    sw $t3, 22452($t0)
    sw $t3, 22456($t0)
    sw $t3, 22460($t0)
    sw $t3, 22464($t0)
    sw $t3, 22468($t0)
    sw $t3, 22472($t0)
    sw $t3, 22908($t0)
    sw $t3, 22912($t0)
    sw $t3, 22916($t0)
    sw $t3, 22928($t0)
    sw $t3, 22936($t0)
    sw $t3, 22940($t0)
    sw $t3, 22948($t0)
    sw $t3, 22952($t0)
    sw $t3, 22960($t0)
    sw $t3, 22968($t0)
    sw $t3, 23472($t0)
    sw $t3, 23476($t0)
    sw $t3, 23984($t0)
    sw $t3, 27504($t0)
    sw $t3, 27580($t0)
    lw $t4, skin_colour
    sw $t4, 5508($t0)
    sw $t4, 5512($t0)
    sw $t4, 5516($t0)
    sw $t4, 5520($t0)
    sw $t4, 5524($t0)
    sw $t4, 11660($t0)
    sw $t4, 12176($t0)
    sw $t4, 12196($t0)
    sw $t4, 12684($t0)
    sw $t4, 12704($t0)
    sw $t4, 12708($t0)
    sw $t4, 12728($t0)
    sw $t4, 12732($t0)
    sw $t4, 13196($t0)
    sw $t4, 13216($t0)
    sw $t4, 13220($t0)
    sw $t4, 13232($t0)
    sw $t4, 13236($t0)
    sw $t4, 13240($t0)
    sw $t4, 13244($t0)
    sw $t4, 13248($t0)
    sw $t4, 13692($t0)
    sw $t4, 13696($t0)
    sw $t4, 13700($t0)
    sw $t4, 13704($t0)
    sw $t4, 13708($t0)
    sw $t4, 13712($t0)
    sw $t4, 13724($t0)
    sw $t4, 13728($t0)
    sw $t4, 13744($t0)
    sw $t4, 13748($t0)
    sw $t4, 13756($t0)
    sw $t4, 13760($t0)
    sw $t4, 14196($t0)
    sw $t4, 14200($t0)
    sw $t4, 14204($t0)
    sw $t4, 14208($t0)
    sw $t4, 14212($t0)
    sw $t4, 14216($t0)
    sw $t4, 14220($t0)
    sw $t4, 14224($t0)
    sw $t4, 14228($t0)
    sw $t4, 14232($t0)
    sw $t4, 14236($t0)
    sw $t4, 14240($t0)
    sw $t4, 14244($t0)
    sw $t4, 14248($t0)
    sw $t4, 14252($t0)
    sw $t4, 14256($t0)
    sw $t4, 14260($t0)
    sw $t4, 14268($t0)
    sw $t4, 14272($t0)
    sw $t4, 14708($t0)
    sw $t4, 14712($t0)
    sw $t4, 14716($t0)
    sw $t4, 14720($t0)
    sw $t4, 14724($t0)
    sw $t4, 14728($t0)
    sw $t4, 14732($t0)
    sw $t4, 14736($t0)
    sw $t4, 14748($t0)
    sw $t4, 14752($t0)
    sw $t4, 14756($t0)
    sw $t4, 14760($t0)
    sw $t4, 14768($t0)
    sw $t4, 14772($t0)
    sw $t4, 14776($t0)
    sw $t4, 14780($t0)
    sw $t4, 14784($t0)
    sw $t4, 15228($t0)
    sw $t4, 15232($t0)
    sw $t4, 15236($t0)
    sw $t4, 15240($t0)
    sw $t4, 15244($t0)
    sw $t4, 15268($t0)
    sw $t4, 15272($t0)
    sw $t4, 15276($t0)
    sw $t4, 15288($t0)
    sw $t4, 15292($t0)
    sw $t4, 15776($t0)
    sw $t4, 15780($t0)
    sw $t4, 15784($t0)
    sw $t4, 15788($t0)
    sw $t4, 16280($t0)
    sw $t4, 16284($t0)
    sw $t4, 16288($t0)
    sw $t4, 16292($t0)
    sw $t4, 16296($t0)
    sw $t4, 16772($t0)
    sw $t4, 16776($t0)
    sw $t4, 16788($t0)
    sw $t4, 16792($t0)
    sw $t4, 16796($t0)
    sw $t4, 16800($t0)
    sw $t4, 16804($t0)
    sw $t4, 16808($t0)
    sw $t4, 17288($t0)
    sw $t4, 17292($t0)
    sw $t4, 17296($t0)
    sw $t4, 17300($t0)
    sw $t4, 17304($t0)
    sw $t4, 17308($t0)
    sw $t4, 17332($t0)
    sw $t4, 19892($t0)
    sw $t4, 20404($t0)
    sw $t4, 22964($t0)
    sw $t4, 24500($t0)
    sw $t4, 26036($t0)
    sw $t4, 26548($t0)
    lw $t5, white_colour
    sw $t5, 8580($t0)
    sw $t5, 8584($t0)
    sw $t5, 8588($t0)
    sw $t5, 9068($t0)
    sw $t5, 9088($t0)
    sw $t5, 9092($t0)
    sw $t5, 9100($t0)
    sw $t5, 9104($t0)
    sw $t5, 9580($t0)
    sw $t5, 9600($t0)
    sw $t5, 9604($t0)
    sw $t5, 9612($t0)
    sw $t5, 9616($t0)
    sw $t5, 10092($t0)
    sw $t5, 10116($t0)
    sw $t5, 10120($t0)
    sw $t5, 10124($t0)
    sw $t5, 10600($t0)
    sw $t5, 10604($t0)
    sw $t5, 10620($t0)
    sw $t5, 10628($t0)
    sw $t5, 10632($t0)
    sw $t5, 10636($t0)
    sw $t5, 10644($t0)
    sw $t5, 10648($t0)
    sw $t5, 10652($t0)
    sw $t5, 10656($t0)
    sw $t5, 10660($t0)
    sw $t5, 10664($t0)
    sw $t5, 10668($t0)
    sw $t5, 10672($t0)
    sw $t5, 11112($t0)
    sw $t5, 11116($t0)
    sw $t5, 11120($t0)
    sw $t5, 11124($t0)
    sw $t5, 11128($t0)
    sw $t5, 11132($t0)
    sw $t5, 11624($t0)
    sw $t5, 11628($t0)
    sw $t5, 11632($t0)
    sw $t5, 11636($t0)
    sw $t5, 11640($t0)
    sw $t5, 12164($t0)
    sw $t5, 12168($t0)
    sw $t5, 12180($t0)
    sw $t5, 12184($t0)
    sw $t5, 12188($t0)
    sw $t5, 12648($t0)
    sw $t5, 12652($t0)
    sw $t5, 12656($t0)
    sw $t5, 12660($t0)
    sw $t5, 12664($t0)
    sw $t5, 12668($t0)
    sw $t5, 12676($t0)
    sw $t5, 12692($t0)
    sw $t5, 12696($t0)
    sw $t5, 12700($t0)
    sw $t5, 13160($t0)
    sw $t5, 13164($t0)
    sw $t5, 13168($t0)
    sw $t5, 13172($t0)
    sw $t5, 13176($t0)
    sw $t5, 13188($t0)
    sw $t5, 13204($t0)
    sw $t5, 13208($t0)
    sw $t5, 13212($t0)
    sw $t5, 13672($t0)
    sw $t5, 13676($t0)
    sw $t5, 13680($t0)
    sw $t5, 13716($t0)
    sw $t5, 13720($t0)
    sw $t5, 14184($t0)
    sw $t5, 14188($t0)
    sw $t5, 14700($t0)
    sw $t5, 15212($t0)
    sw $t5, 15724($t0)
    sw $t5, 15728($t0)
    sw $t5, 16240($t0)
    sw $t5, 16244($t0)
    sw $t5, 16248($t0)
    sw $t5, 16752($t0)
    sw $t5, 16756($t0)
    sw $t5, 16760($t0)
    sw $t5, 16764($t0)
    sw $t5, 17268($t0)
    sw $t5, 17272($t0)
    sw $t5, 17276($t0)
    sw $t5, 17280($t0)
    sw $t5, 17324($t0)
    sw $t5, 17328($t0)
    sw $t5, 17788($t0)
    sw $t5, 17792($t0)
    sw $t5, 17824($t0)
    sw $t5, 17828($t0)
    sw $t5, 17844($t0)
    sw $t5, 17848($t0)
    sw $t5, 17852($t0)
    sw $t5, 18304($t0)
    sw $t5, 18316($t0)
    sw $t5, 18320($t0)
    sw $t5, 18332($t0)
    sw $t5, 18336($t0)
    sw $t5, 18356($t0)
    sw $t5, 18360($t0)
    sw $t5, 18364($t0)
    sw $t5, 18368($t0)
    sw $t5, 18812($t0)
    sw $t5, 18816($t0)
    sw $t5, 18832($t0)
    sw $t5, 18840($t0)
    sw $t5, 18844($t0)
    sw $t5, 18848($t0)
    sw $t5, 18868($t0)
    sw $t5, 18872($t0)
    sw $t5, 18876($t0)
    sw $t5, 18880($t0)
    sw $t5, 19324($t0)
    sw $t5, 19328($t0)
    sw $t5, 19344($t0)
    sw $t5, 19352($t0)
    sw $t5, 19372($t0)
    sw $t5, 19376($t0)
    sw $t5, 19380($t0)
    sw $t5, 19384($t0)
    sw $t5, 19388($t0)
    sw $t5, 19392($t0)
    sw $t5, 19396($t0)
    sw $t5, 19836($t0)
    sw $t5, 19840($t0)
    sw $t5, 19860($t0)
    sw $t5, 19864($t0)
    sw $t5, 19884($t0)
    sw $t5, 19888($t0)
    sw $t5, 19900($t0)
    sw $t5, 19904($t0)
    sw $t5, 19908($t0)
    sw $t5, 20340($t0)
    sw $t5, 20344($t0)
    sw $t5, 20348($t0)
    sw $t5, 20352($t0)
    sw $t5, 20356($t0)
    sw $t5, 20372($t0)
    sw $t5, 20396($t0)
    sw $t5, 20400($t0)
    sw $t5, 20412($t0)
    sw $t5, 20416($t0)
    sw $t5, 20420($t0)
    sw $t5, 20852($t0)
    sw $t5, 20856($t0)
    sw $t5, 20860($t0)
    sw $t5, 20864($t0)
    sw $t5, 20868($t0)
    sw $t5, 20884($t0)
    sw $t5, 20904($t0)
    sw $t5, 20908($t0)
    sw $t5, 20920($t0)
    sw $t5, 20924($t0)
    sw $t5, 20928($t0)
    sw $t5, 20932($t0)
    sw $t5, 20936($t0)
    sw $t5, 21364($t0)
    sw $t5, 21368($t0)
    sw $t5, 21372($t0)
    sw $t5, 21376($t0)
    sw $t5, 21380($t0)
    sw $t5, 21412($t0)
    sw $t5, 21416($t0)
    sw $t5, 21420($t0)
    sw $t5, 21432($t0)
    sw $t5, 21436($t0)
    sw $t5, 21440($t0)
    sw $t5, 21444($t0)
    sw $t5, 21448($t0)
    sw $t5, 21876($t0)
    sw $t5, 21880($t0)
    sw $t5, 21884($t0)
    sw $t5, 21888($t0)
    sw $t5, 21892($t0)
    sw $t5, 21924($t0)
    sw $t5, 21928($t0)
    sw $t5, 21932($t0)
    sw $t5, 22408($t0)
    sw $t5, 22420($t0)
    sw $t5, 22432($t0)
    sw $t5, 22920($t0)
    sw $t5, 22932($t0)
    sw $t5, 22944($t0)
    sw $t5, 22972($t0)
    sw $t5, 22976($t0)
    sw $t5, 22980($t0)
    sw $t5, 22984($t0)
    sw $t5, 23420($t0)
    sw $t5, 23424($t0)
    sw $t5, 23428($t0)
    sw $t5, 23432($t0)
    sw $t5, 23440($t0)
    sw $t5, 23444($t0)
    sw $t5, 23448($t0)
    sw $t5, 23456($t0)
    sw $t5, 23460($t0)
    sw $t5, 23464($t0)
    sw $t5, 23484($t0)
    sw $t5, 23488($t0)
    sw $t5, 23492($t0)
    sw $t5, 23496($t0)
    sw $t5, 23932($t0)
    sw $t5, 23936($t0)
    sw $t5, 23940($t0)
    sw $t5, 23944($t0)
    sw $t5, 23968($t0)
    sw $t5, 23972($t0)
    sw $t5, 23976($t0)
    sw $t5, 23980($t0)
    sw $t5, 23992($t0)
    sw $t5, 23996($t0)
    sw $t5, 24000($t0)
    sw $t5, 24004($t0)
    sw $t5, 24448($t0)
    sw $t5, 24452($t0)
    sw $t5, 24456($t0)
    sw $t5, 24464($t0)
    sw $t5, 24468($t0)
    sw $t5, 24472($t0)
    sw $t5, 24476($t0)
    sw $t5, 24480($t0)
    sw $t5, 24484($t0)
    sw $t5, 24488($t0)
    sw $t5, 24492($t0)
    sw $t5, 24496($t0)
    sw $t5, 24960($t0)
    sw $t5, 24964($t0)
    sw $t5, 24968($t0)
    sw $t5, 24976($t0)
    sw $t5, 24980($t0)
    sw $t5, 24984($t0)
    sw $t5, 24988($t0)
    sw $t5, 24992($t0)
    sw $t5, 24996($t0)
    sw $t5, 25000($t0)
    sw $t5, 25004($t0)
    sw $t5, 25008($t0)
    sw $t5, 25012($t0)
    sw $t5, 25016($t0)
    sw $t5, 25020($t0)
    sw $t5, 25988($t0)
    sw $t5, 25992($t0)
    sw $t5, 25996($t0)
    sw $t5, 26000($t0)
    sw $t5, 26004($t0)
    sw $t5, 26016($t0)
    sw $t5, 26020($t0)
    sw $t5, 26024($t0)
    sw $t5, 26028($t0)
    sw $t5, 26032($t0)
    sw $t5, 26500($t0)
    sw $t5, 26504($t0)
    sw $t5, 26508($t0)
    sw $t5, 26512($t0)
    sw $t5, 26516($t0)
    sw $t5, 26528($t0)
    sw $t5, 26532($t0)
    sw $t5, 26536($t0)
    sw $t5, 26540($t0)
    sw $t5, 26544($t0)
    sw $t5, 27012($t0)
    sw $t5, 27016($t0)
    sw $t5, 27020($t0)
    sw $t5, 27024($t0)
    sw $t5, 27028($t0)
    sw $t5, 27040($t0)
    sw $t5, 27044($t0)
    sw $t5, 27048($t0)
    lw $t6, brown_colour
    sw $t6, 9076($t0)
    sw $t6, 9112($t0)
    sw $t6, 9116($t0)
    sw $t6, 9120($t0)
    sw $t6, 9124($t0)
    sw $t6, 9588($t0)
    sw $t6, 9592($t0)
    sw $t6, 9624($t0)
    sw $t6, 9628($t0)
    sw $t6, 9632($t0)
    sw $t6, 9636($t0)
    sw $t6, 11152($t0)
    sw $t6, 11156($t0)
    sw $t6, 11160($t0)
    sw $t6, 11164($t0)
    sw $t6, 11168($t0)
    sw $t6, 11172($t0)
    sw $t6, 11176($t0)
    sw $t6, 11180($t0)
    sw $t6, 11184($t0)
    sw $t6, 11188($t0)
    sw $t6, 11192($t0)
    sw $t6, 11648($t0)
    sw $t6, 11652($t0)
    sw $t6, 11656($t0)
    sw $t6, 11664($t0)
    sw $t6, 11680($t0)
    sw $t6, 11684($t0)
    sw $t6, 11688($t0)
    sw $t6, 11692($t0)
    sw $t6, 11696($t0)
    sw $t6, 11700($t0)
    sw $t6, 11704($t0)
    sw $t6, 12172($t0)
    sw $t6, 12200($t0)
    sw $t6, 12204($t0)
    sw $t6, 12208($t0)
    sw $t6, 12212($t0)
    sw $t6, 12216($t0)
    sw $t6, 12712($t0)
    sw $t6, 12716($t0)
    sw $t6, 12720($t0)
    sw $t6, 12724($t0)
    sw $t6, 13224($t0)
    sw $t6, 13228($t0)
    sw $t6, 13732($t0)
    sw $t6, 13736($t0)
    sw $t6, 13740($t0)
    sw $t6, 13752($t0)
    sw $t6, 14264($t0)
    sw $t6, 14764($t0)
    sw $t6, 15284($t0)
    sw $t6, 15296($t0)
    sw $t6, 15796($t0)
    sw $t6, 15800($t0)
    sw $t6, 15804($t0)
    sw $t6, 15808($t0)
    sw $t6, 16308($t0)
    sw $t6, 16312($t0)
    sw $t6, 16316($t0)
    sw $t6, 19896($t0)
    sw $t6, 20408($t0)
    sw $t6, 21428($t0)
    sw $t6, 26992($t0)
    sw $t6, 26996($t0)
    sw $t6, 27000($t0)
    sw $t6, 27004($t0)
    sw $t6, 27064($t0)
    sw $t6, 27068($t0)
    sw $t6, 27072($t0)
    sw $t6, 27500($t0)
    sw $t6, 27508($t0)
    sw $t6, 27512($t0)
    sw $t6, 27516($t0)
    sw $t6, 27520($t0)
    sw $t6, 27564($t0)
    sw $t6, 27568($t0)
    sw $t6, 27572($t0)
    sw $t6, 27576($t0)
    sw $t6, 27584($t0)
    sw $t6, 27588($t0)
    sw $t6, 28012($t0)
    sw $t6, 28016($t0)
    sw $t6, 28020($t0)
    sw $t6, 28024($t0)
    sw $t6, 28028($t0)
    sw $t6, 28032($t0)
    sw $t6, 28036($t0)
    sw $t6, 28040($t0)
    sw $t6, 28044($t0)
    sw $t6, 28048($t0)
    sw $t6, 28052($t0)
    sw $t6, 28064($t0)
    sw $t6, 28068($t0)
    sw $t6, 28072($t0)
    sw $t6, 28076($t0)
    sw $t6, 28080($t0)
    sw $t6, 28084($t0)
    sw $t6, 28088($t0)
    sw $t6, 28092($t0)
    sw $t6, 28096($t0)
    sw $t6, 28100($t0)
    sw $t6, 28528($t0)
    sw $t6, 28532($t0)
    sw $t6, 28536($t0)
    sw $t6, 28540($t0)
    sw $t6, 28544($t0)
    sw $t6, 28548($t0)
    sw $t6, 28552($t0)
    sw $t6, 28556($t0)
    sw $t6, 28560($t0)
    sw $t6, 28564($t0)
    sw $t6, 28576($t0)
    sw $t6, 28580($t0)
    sw $t6, 28584($t0)
    sw $t6, 28588($t0)
    sw $t6, 28592($t0)
    sw $t6, 28596($t0)
    sw $t6, 28600($t0)
    sw $t6, 28604($t0)
    sw $t6, 28608($t0)
    jr $ra

draw_viruses:
    lw $t0, ADDR_DSPL

    # Blue viruses
    lw $t1, blue_colour
    lw $t2, yellow_colour
    lw $t3, black_colour
    
    # Top-left blue virus (x=10, y=25)
    # Base position calculation: (25*128*4) + (10*4) = 12800 + 40 = 12840
    li $t4, 12840   # Starting position
    add $t4, $t4, $t0
    
    # Draw top-left blue virus
    # Row 1 (top antennas)
    sw $t1, 0($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    
    # Row 2
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t1, 0($t4)      # Blue
    sw $t1, 4($t4)      # Blue
    sw $t1, 8($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Row 3
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t2, 0($t4)      # Yellow (eye)
    sw $t3, 4($t4)      # Black (pupil)
    sw $t1, 8($t4)      # Blue
    sw $t3, 12($t4)     # Black (pupil)
    sw $t2, 16($t4)     # Yellow (eye)
    
    # Row 4
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t1, 0($t4)      # Blue
    sw $t1, 4($t4)      # Blue
    sw $t1, 8($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Row 5 (mouth)
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t1, 0($t4)      # Blue
    sw $t3, 4($t4)      # Black
    sw $t3, 8($t4)      # Black
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Row 6 (bottom)
    addi $t4, $t4, 512
    sw $t1, 0($t4)      # Blue
    sw $t1, 4($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Top-middle red virus (exactly 3 pixels/12 bytes to the right of the blue one)
    # Start from the end of blue virus (rightmost pixel) + 12 bytes (3 pixels)
    # Blue virus ends at x=16, so add 12 to get x=28
    lw $t1, red_colour
    li $t4, 12840   # Starting position for blue virus
    addi $t4, $t4, 28   # Move to x=28
    add $t4, $t4, $t0
    
    # Row 1 (top antennas)
    sw $t1, 0($t4)      # Red
    sw $t1, 12($t4)     # Red
    
    # Row 2
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t1, 0($t4)      # Red
    sw $t1, 4($t4)      # Red
    sw $t1, 8($t4)      # Red
    sw $t1, 12($t4)     # Red
    sw $t1, 16($t4)     # Red
    
    # Row 3
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t2, 0($t4)      # Blue (eye)
    sw $t3, 4($t4)      # Black (pupil)
    sw $t1, 8($t4)      # Red
    sw $t3, 12($t4)     # Black (pupil)
    sw $t2, 16($t4)     # Blue (eye)
    
    # Row 4
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t1, 0($t4)      # Red
    sw $t1, 4($t4)      # Red
    sw $t1, 8($t4)      # Red
    sw $t1, 12($t4)     # Red
    sw $t1, 16($t4)     # Red
    
    # Row 5 (yellow smile)
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t1, 0($t4)      # Red
    sw $t2, 4($t4)      # Yellow
    sw $t2, 8($t4)      # Yellow
    sw $t2, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Red
    
    # Row 6 (bottom)
    addi $t4, $t4, 512
    sw $t1, 0($t4)      # Red
    sw $t1, 4($t4)      # Red
    sw $t1, 12($t4)     # Red
    sw $t1, 16($t4)     # Red
    
    # Top-right yellow virus (exactly 3 pixels/12 bytes to the right of the red one)
    # Red virus ends at x=44, so add 12 to get x=56
    lw $t1, yellow_colour
    lw $t5, blue_colour  # For eyes
    lw $t6, red_colour   # For dot
    
    li $t4, 12840   # Starting position for blue virus
    addi $t4, $t4, 56   # Move to x=56
    add $t4, $t4, $t0
    
    # Row 1 (top antennas - blue)
    sw $t5, 0($t4)      # Blue
    sw $t5, 12($t4)     # Blue
    
    # Row 2
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t1, 0($t4)      # Yellow
    sw $t1, 4($t4)      # Yellow
    sw $t1, 8($t4)      # Yellow
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    # Row 3
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t5, 0($t4)      # Blue (eye)
    sw $t3, 4($t4)      # Black (pupil)
    sw $t1, 8($t4)      # Yellow
    sw $t3, 12($t4)     # Black (pupil)
    sw $t5, 16($t4)     # Blue (eye)
    
    # Row 4
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t1, 0($t4)      # Yellow
    sw $t1, 4($t4)      # Yellow
    sw $t1, 8($t4)      # Yellow
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    # Row 5 (red dot)
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t1, 0($t4)      # Yellow
    sw $t1, 4($t4)      # Yellow
    sw $t6, 8($t4)      # Red
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    # Row 6 (bottom)
    addi $t4, $t4, 512
    sw $t1, 0($t4)      # Yellow
    sw $t1, 4($t4)      # Yellow
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    # Bottom row viruses (2 pixels below top row)
    # If top row is at y=25, then 2 pixel gap + 6 rows = y=33
    
    # Bottom-left blue virus
    lw $t1, blue_colour
    li $t4, 16920   # Base position: (33*128*4) + (10*4) = 16896 + 40 = 16936
    add $t4, $t4, $t0
    
    # Row 1 (top antennas)
    sw $t1, 0($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    
    # Row 2
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t1, 0($t4)      # Blue
    sw $t1, 4($t4)      # Blue
    sw $t1, 8($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Row 3
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t2, 0($t4)      # Yellow (eye)
    sw $t3, 4($t4)      # Black (pupil)
    sw $t1, 8($t4)      # Blue
    sw $t3, 12($t4)     # Black (pupil)
    sw $t2, 16($t4)     # Yellow (eye)
    
    # Row 4
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t1, 0($t4)      # Blue
    sw $t1, 4($t4)      # Blue
    sw $t1, 8($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Row 5 (mouth - single dot)
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Blue
    sw $t1, 0($t4)      # Blue
    sw $t1, 4($t4)      # Blue
    sw $t3, 8($t4)      # Black
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Row 6 (bottom)
    addi $t4, $t4, 512
    sw $t1, 0($t4)      # Blue
    sw $t1, 4($t4)      # Blue
    sw $t1, 12($t4)     # Blue
    sw $t1, 16($t4)     # Blue
    
    # Bottom-middle red virus
    lw $t1, red_colour
    li $t4, 16936   # Base position
    addi $t4, $t4, 28   # Move to x=28
    add $t4, $t4, $t0
    
    # Row 1 (top antennas)
    sw $t1, 0($t4)      # Red
    sw $t1, 12($t4)     # Red
    
    # Row 2
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t1, 0($t4)      # Red
    sw $t1, 4($t4)      # Red
    sw $t1, 8($t4)      # Red
    sw $t1, 12($t4)     # Red
    sw $t1, 16($t4)     # Red
    
    # Row 3
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t2, 0($t4)      # Blue (eye)
    sw $t3, 4($t4)      # Black (pupil)
    sw $t1, 8($t4)      # Red
    sw $t3, 12($t4)     # Black (pupil)
    sw $t2, 16($t4)     # Blue (eye)
    
    # Row 4
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t1, 0($t4)      # Red
    sw $t1, 4($t4)      # Red
    sw $t1, 8($t4)      # Red
    sw $t1, 12($t4)     # Red
    sw $t1, 16($t4)     # Red
    
    # Row 5 (yellow smile)
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Red
    sw $t1, 0($t4)      # Red
    sw $t2, 4($t4)      # Yellow
    sw $t2, 8($t4)      # Yellow
    sw $t2, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Red
    
    # Row 6 (bottom)
    addi $t4, $t4, 512
    sw $t1, 0($t4)      # Red
    sw $t1, 4($t4)      # Red
    sw $t1, 12($t4)     # Red
    sw $t1, 16($t4)     # Red
    
    # Bottom-right yellow virus
    lw $t1, yellow_colour
    li $t4, 16936   # Base position
    addi $t4, $t4, 56   # Move to x=56
    add $t4, $t4, $t0
    
    # Row 1 (top antennas - blue)
    sw $t5, 0($t4)      # Blue
    sw $t5, 12($t4)     # Blue
    
    # Row 2
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t1, 0($t4)      # Yellow
    sw $t1, 4($t4)      # Yellow
    sw $t1, 8($t4)      # Yellow
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    # Row 3
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t5, 0($t4)      # Blue (eye)
    sw $t3, 4($t4)      # Black (pupil)
    sw $t1, 8($t4)      # Yellow
    sw $t3, 12($t4)     # Black (pupil)
    sw $t5, 16($t4)     # Blue (eye)
    
    # Row 4
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t1, 0($t4)      # Yellow
    sw $t1, 4($t4)      # Yellow
    sw $t1, 8($t4)      # Yellow
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    # Row 5 (black mouth line)
    addi $t4, $t4, 512
    sw $t1, -4($t4)     # Yellow
    sw $t1, 0($t4)      # Yellow
    sw $t3, 4($t4)      # Black
    sw $t3, 8($t4)      # Black
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    # Row 6 (bottom)
    addi $t4, $t4, 512
    sw $t1, 0($t4)      # Yellow
    sw $t1, 4($t4)      # Yellow
    sw $t1, 12($t4)     # Yellow
    sw $t1, 16($t4)     # Yellow
    
    jr $ra
    
spawn_viruses:
    addi $sp, $sp, -4       # Move stack pointer to empty location
    sw $ra, 0($sp)          # Push $ra onto the stack, to keep it safe

    lw $t0, ADDR_DSPL  # Starting coordinate
    
    # FIRST ROW
    li $v0, 42
    li $a0, 0
    li $a1, 11
    syscall  
    
    li $t8, 8
    mul $t2, $a0, $t8
    
    addi $t2, $t2, 16080
    add $t0, $t2, $t0
    
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    li $t9, 0
    beq $a0, $t9, set_red
    li $t9, 1
    beq $a0, $t9, set_blue
    li $t9, 2
    beq $a0, $t9, set_yellow

set_red:
    lw $t5, red_colour
    j write
    
set_blue:
    lw $t5, blue_colour
    j write
    
set_yellow:
    lw $t5, yellow_colour
write:
    
    sw $t5, 0($t0)
    sw $t5, 4($t0)
    sw $t5, 512($t0)
    sw $t5, 516($t0)
    
    # SECOND ROW
    lw $t0, ADDR_DSPL
    
    li $v0, 42
    li $a0, 0
    li $a1, 11
    syscall  
    
    li $t8, 8
    mul $t2, $a0, $t8
    
    addi $t2, $t2, 22224
    add $t0, $t2, $t0
    
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    li $t9, 0
    beq $a0, $t9, set_red_1
    li $t9, 1
    beq $a0, $t9, set_blue_1
    li $t9, 2
    beq $a0, $t9, set_yellow_1

set_red_1:
    lw $t5, red_colour
    j write_1
    
set_blue_1:
    lw $t5, blue_colour
    j write_1
    
set_yellow_1:
    lw $t5, yellow_colour
write_1:
    
    sw $t5, 0($t0)
    sw $t5, 4($t0)
    sw $t5, 512($t0)
    sw $t5, 516($t0)

    # THIRD ROW
    lw $t0, ADDR_DSPL
    
    li $v0, 42
    li $a0, 0
    li $a1, 11
    syscall  
    
    li $t8, 8
    mul $t2, $a0, $t8
    
    addi $t2, $t2, 18128
    add $t0, $t2, $t0
    
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    li $t9, 0
    beq $a0, $t9, set_red_2
    li $t9, 1
    beq $a0, $t9, set_blue_2
    li $t9, 2
    beq $a0, $t9, set_yellow_2

set_red_2:
    lw $t5, red_colour
    j write_2
    
set_blue_2:
    lw $t5, blue_colour
    j write_2
    
set_yellow_2:
    lw $t5, yellow_colour
write_2:

    sw $t5, 0($t0)
    sw $t5, 4($t0)
    sw $t5, 512($t0)
    sw $t5, 516($t0)

    # FOURTH ROW
    lw $t0, ADDR_DSPL
    
    li $v0, 42
    li $a0, 0
    li $a1, 11
    syscall  
    
    li $t8, 8
    mul $t2, $a0, $t8
    
    addi $t2, $t2, 20176
    add $t0, $t2, $t0
    
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    li $t9, 0
    beq $a0, $t9, set_red_3
    li $t9, 1
    beq $a0, $t9, set_blue_3
    li $t9, 2
    beq $a0, $t9, set_yellow_3

set_red_3:
    lw $t5, red_colour
    j write_3
    
set_blue_3:
    lw $t5, blue_colour
    j write_3
    
set_yellow_3:
    lw $t5, yellow_colour
write_3:

    sw $t5, 0($t0)
    sw $t5, 4($t0)
    sw $t5, 512($t0)
    sw $t5, 516($t0)
    
    lw $t8, DIFFICULTY_SELECTED
    li $t7, 0
    beq $t8, $t7 end

    # FIFTH ROW
    lw $t0, ADDR_DSPL
    
    li $v0, 42
    li $a0, 0
    li $a1, 11
    syscall  
    
    li $t8, 8
    mul $t2, $a0, $t8
    
    addi $t2, $t2, 24272
    add $t0, $t2, $t0

    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    li $t9, 0
    beq $a0, $t9, set_red_4
    li $t9, 1
    beq $a0, $t9, set_blue_4
    li $t9, 2
    beq $a0, $t9, set_yellow_4

set_red_4:
    lw $t5, red_colour
    j write_4
    
set_blue_4:
    lw $t5, blue_colour
    j write_4
    
set_yellow_4:
    lw $t5, yellow_colour
write_4:
    sw $t5, 0($t0)
    sw $t5, 4($t0)
    sw $t5, 512($t0)
    sw $t5, 516($t0)
    
    li $t7, 1
    lw $t8 DIFFICULTY_SELECTED
    beq $t8, $t7 end

    # SIXTH ROW
    lw $t0, ADDR_DSPL
    
    li $v0, 42
    li $a0, 0
    li $a1, 11
    syscall  
    
    li $t8, 8
    mul $t2, $a0, $t8
    
    addi $t2, $t2, 14032
    add $t0, $t2, $t0
    
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    li $t9, 0
    beq $a0, $t9, set_red_5
    li $t9, 1
    beq $a0, $t9, set_blue_5
    li $t9, 3
    beq $a0, $t9, set_yellow_5

set_red_5:
    lw $t5, red_colour
    j write_5
    
set_blue_5:
    lw $t5, blue_colour
    j write_5
    
set_yellow_5:
    lw $t5, yellow_colour
write_5:
    sw $t5, 0($t0)
    sw $t5, 4($t0)
    sw $t5, 512($t0)
    sw $t5, 516($t0)

end:
    lw $ra, 0($sp)    # Pop return address off the stack
    addi $sp, $sp, 4  # Move stack pointer to top element of the stack
    jr $ra                     # Return from the subroutine
    
next_colour:
    lw $t9, red_colour
    beq $t2, $t9, change_to_blue
    lw $t9, blue_colour
    beq $t2, $t9, change_to_yellow
    lw $t9, yellow_colour
    beq $t2, $t9, change_to_red
    change_to_blue:
        lw $t2, blue_colour
        jr $ra
    change_to_yellow:
        lw $t2, yellow_colour
        jr $ra
    change_to_red:
        lw $t2, red_colour
        jr $ra
    
draw_bottle:
    lw $t4, white_colour    # Load white colour into $t4
    
    sw $t4, 4324($t0)       # Start drawing the bottle
    sw $t4, 4328($t0)
    sw $t4, 4332($t0)
    sw $t4, 4336($t0)
    
    sw $t4, 4836($t0)
    sw $t4, 5348($t0)
    
    sw $t4, 5352($t0)
    sw $t4, 5356($t0)
    sw $t4, 5360($t0)
    
    sw $t4, 5872($t0)
    sw $t4, 6384($t0)
    
    sw $t4, 6380($t0)
    sw $t4, 6376($t0)
    
    sw $t4, 6372($t0)
    sw $t4, 6368($t0)
    sw $t4, 6364($t0)
    sw $t4, 6360($t0)
    sw $t4, 6356($t0)
    sw $t4, 6352($t0)
    sw $t4, 6348($t0)
    
    sw $t4, 6860($t0)
    sw $t4, 7372($t0)
    sw $t4, 7884($t0)
    sw $t4, 8396($t0)
    sw $t4, 8908($t0)
    sw $t4, 9420($t0)
    sw $t4, 9932($t0)
    sw $t4, 10444($t0)
    sw $t4, 10956($t0)
    sw $t4, 11468($t0)
    sw $t4, 11980($t0)
    sw $t4, 12492($t0)
    sw $t4, 13004($t0)
    sw $t4, 13516($t0)
    sw $t4, 14028($t0)
    sw $t4, 14540($t0)
    sw $t4, 15052($t0)
    sw $t4, 15564($t0)
    sw $t4, 16076($t0)
    sw $t4, 16588($t0)
    sw $t4, 17100($t0)
    sw $t4, 17612($t0)
    sw $t4, 18124($t0)
    sw $t4, 18636($t0)
    sw $t4, 19148($t0)
    sw $t4, 19660($t0)
    sw $t4, 20172($t0)
    sw $t4, 20684($t0)
    sw $t4, 21196($t0)
    sw $t4, 21708($t0)
    sw $t4, 22220($t0)
    sw $t4, 22732($t0)
    sw $t4, 23244($t0)
    sw $t4, 23756($t0)
    sw $t4, 24268($t0)
    sw $t4, 24780($t0)
    sw $t4, 25292($t0)
    sw $t4, 25804($t0)
    sw $t4, 26316($t0)
    sw $t4, 26828($t0)
    
    sw $t4, 26832($t0)
    sw $t4, 26836($t0)
    sw $t4, 26840($t0)
    sw $t4, 26844($t0)
    sw $t4, 26848($t0)
    sw $t4, 26852($t0)
    sw $t4, 26856($t0)
    sw $t4, 26860($t0)
    sw $t4, 26864($t0)
    sw $t4, 26868($t0)
    sw $t4, 26872($t0)
    sw $t4, 26876($t0)
    sw $t4, 26880($t0)
    sw $t4, 26884($t0)
    sw $t4, 26888($t0)
    sw $t4, 26892($t0)
    sw $t4, 26896($t0)
    sw $t4, 26900($t0)
    sw $t4, 26904($t0)
    sw $t4, 26908($t0)
    sw $t4, 26912($t0)
    sw $t4, 26916($t0)
    sw $t4, 26920($t0)
    sw $t4, 26924($t0)
    sw $t4, 26928($t0)
    
    sw $t4, 26416($t0)
    sw $t4, 25904($t0)
    sw $t4, 25392($t0)
    sw $t4, 24880($t0)
    sw $t4, 24368($t0)
    sw $t4, 23856($t0)
    sw $t4, 23344($t0)
    sw $t4, 22832($t0)
    sw $t4, 22320($t0)
    sw $t4, 21808($t0)
    sw $t4, 21296($t0)
    sw $t4, 20784($t0)
    sw $t4, 20272($t0)
    sw $t4, 19760($t0)
    sw $t4, 19248($t0)
    sw $t4, 18736($t0)
    sw $t4, 18224($t0)
    sw $t4, 17712($t0)
    sw $t4, 17200($t0)
    sw $t4, 16688($t0)
    sw $t4, 16176($t0)
    sw $t4, 15664($t0)
    sw $t4, 15152($t0)
    sw $t4, 14640($t0)
    sw $t4, 14128($t0)
    sw $t4, 13616($t0)
    sw $t4, 13104($t0)
    sw $t4, 12592($t0)
    sw $t4, 12080($t0)
    sw $t4, 11568($t0)
    sw $t4, 11056($t0)
    sw $t4, 10544($t0)
    sw $t4, 10032($t0)
    sw $t4, 9520($t0)
    sw $t4, 9008($t0)
    sw $t4, 8496($t0)
    sw $t4, 7984($t0)
    sw $t4, 7472($t0)
    sw $t4, 6960($t0)
    sw $t4, 6448($t0)  #top right of the bottle
    
    sw $t4, 6444($t0)
    sw $t4, 6440($t0)
    sw $t4, 6436($t0)
    sw $t4, 6432($t0)
    sw $t4, 6428($t0)
    sw $t4, 6424($t0)
    sw $t4, 6420($t0)
    sw $t4, 6416($t0)
    sw $t4, 6412($t0)
    sw $t4, 6408($t0)
    
    sw $t4, 5896($t0)
    sw $t4, 5384($t0)
    
    sw $t4, 5388($t0)
    sw $t4, 5392($t0)
    sw $t4, 5396($t0)

    sw $t4, 4884($t0)
    sw $t4, 4372($t0)

    sw $t4, 4368($t0)
    sw $t4, 4364($t0)
    sw $t4, 4360($t0)
    
    jr $ra
    
draw_pill:
    addi $sp, $sp, -4       # Move stack pointer to empty location
    sw $ra, 0($sp)          # Push $ra onto the stack, to keep it safe
    
    lw $t0, ADDR_DSPL   # Load the address of the display back into $t0

    # Load left and right colors into registers
    lw $t2, left_colour      # Load left color into $t2
    lw $t3, right_colour     # Load right color into $t3

    
    # Draw the left side of the pill
    lw $t1, top_left_left    # Load the top left left coordinate into $t1
    add $t4, $t0, $t1        # Add this to the value of the display and store it in $t4
    sw $t2, 0($t4)           # Put the left colour into $t4 and draw to the display

    lw $t1, top_left_right   # Load the top left right coordinate into $t1
    add $t4, $t0, $t1        # Add this to the value of the display and store it in $t4
    sw $t2, 0($t4)           # Put the left colour into $t4 and draw to the display

    lw $t1, bottom_left_left # Load the bottom left left coordinate into $t1
    add $t4, $t0, $t1        # Add this to the value of the display and store it in $t4
    sw $t2, 0($t4)           # Put the left colour into $t4 and draw to the display

    lw $t1, bottom_left_right
    add $t4, $t0, $t1
    sw $t2, 0($t4)

    # Draw the right side of the pill
    lw $t1, top_right_left
    add $t4, $t0, $t1
    sw $t3, 0($t4)

    lw $t1, top_right_right
    add $t4, $t0, $t1
    sw $t3, 0($t4)

    lw $t1, bottom_right_left
    add $t4, $t0, $t1
    sw $t3, 0($t4)

    lw $t1, bottom_right_right
    add $t4, $t0, $t1
    sw $t3, 0($t4)

    lw $ra, 0($sp)    # Pop return address off the stack
    addi $sp, $sp, 4  # Move stack pointer to top element of the stack
    
    jr $ra

clear_old_location:
    lw $t0, ADDR_DSPL   # Load the address of the display back into $t0

    # Load left and right colours into registers
    lw $t2, black_colour      # Load black color into $t2
    lw $t3, black_colour      # Load right color into $t3

    # Draw the left side of the pill
    lw $t1, top_left_left    # Load the top left left coordinate into $t1
    add $t4, $t0, $t1        # Add this to the value of the display and store it in $t4
    sw $t2, 0($t4)           # Put the left colour into $t4 and draw to the display

    lw $t1, top_left_right   # Load the top left right coordinate into $t1
    add $t4, $t0, $t1        # Add this to the value of the display and store it in $t4
    sw $t2, 0($t4)           # Put the left colour into $t4 and draw to the display

    lw $t1, bottom_left_left # Load the bottom left left coordinate into $t1
    add $t4, $t0, $t1        # Add this to the value of the display and store it in $t4
    sw $t2, 0($t4)           # Put the left colour into $t4 and draw to the display

    lw $t1, bottom_left_right
    add $t4, $t0, $t1
    sw $t2, 0($t4)

    # Draw the right side of the pill
    lw $t1, top_right_left
    add $t4, $t0, $t1
    sw $t3, 0($t4)

    lw $t1, top_right_right
    add $t4, $t0, $t1
    sw $t3, 0($t4)

    lw $t1, bottom_right_left
    add $t4, $t0, $t1
    sw $t3, 0($t4)

    lw $t1, bottom_right_right
    add $t4, $t0, $t1
    sw $t3, 0($t4)
    
    jr $ra
    
four_in_a_row_horizontal_check:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t4, ADDR_DSPL
    
    # first we initialize the registers with this first 4 coordinates
    lw $t0, top_left_bottle # first coordinate
    add $t0, $t0, $t4
    
    lw $t1, top_left_bottle
    add $t1, $t1, $t4
    addi $t1, $t1, 8  # second coordinate
    
    lw $t2, top_left_bottle
    add $t2, $t2, $t4
    addi $t2, $t2, 16  # third coordinate
    
    lw $t3, top_left_bottle
    add $t3, $t3, $t4
    addi $t3, $t3, 24 # fourth coordinate
    
    # we want to use a loop to iterate until the 4th coordinate reaches the bottle width
    li $t4, 1  # initialize counter for inner loop
    li $t5, 1 # initialize counter for outer loop
    lw $t6, columns
    lw $t7, rows
    
    INNER_LOOP_HORIZONTAL:
        beq $t4, $t6, reset_inner_loop_horizontal
        CONT_LOOP_HORIZONTAL:
        # Load colors from display memory
        lw $t6, 0($t0) # load in the colours
        lw $t7, 0($t1)
        lw $t8, 0($t2)
        lw $t9, 0($t3)
            
        beq $t6, $t7, first_check_horizontal
        
        COME_BACK_HORIZONTAL:
            lw $t6, columns
            lw $t7, rows
            
            addi $t0, $t0, 4  # first coordinate
            addi $t1, $t1, 4  # second coordinate
            addi $t2, $t2, 4  # third coordinate
            addi $t3, $t3, 4  # fourth coordinate
            
            addi $t4, $t4, 1
            j INNER_LOOP_HORIZONTAL
    
    done_horizontal_check:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
first_check_horizontal:
    beq $t7, $t8, second_check_horizontal
    j COME_BACK_HORIZONTAL
    
second_check_horizontal:  
    beq $t8, $t9, four_in_a_row_horizontal
    j COME_BACK_HORIZONTAL
    
four_in_a_row_horizontal:
    li $v0, 31
    li $a1, 1000
    li $a2, 8
    li $a3, 100
    syscall
    
    # change the colour of the coordinates to black
    lw $t9, black_colour
    sw $t9, 0($t0)  # Only clear the current row
    sw $t9, 0($t1)
    sw $t9, 0($t2)
    sw $t9, 0($t3)
    
    # make all the pixels above it fall down
    j COME_BACK_HORIZONTAL

reset_inner_loop_horizontal:
    beq $t5, $t7, done_horizontal_check
    
    # move first coordinate down one row
    lw $t0, top_left_bottle  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t0, $t0, $t6 # this is the new coordinate
    lw $t4, ADDR_DSPL  # Reload display address
    add $t0, $t0, $t4  # Add display address
    
    # move second coordinate down one row
    lw $t1, top_left_bottle  # load in the initial coordinate
    addi $t1, $t1, 8  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t1, $t1, $t6 # this is the new coordinate
    add $t1, $t1, $t4  # Add display address
    
    # move third coordinate down one row
    lw $t2, top_left_bottle  # load in the initial coordinate
    addi $t2, $t2, 16  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t2, $t2, $t6 # this is the new coordinate
    add $t2, $t2, $t4  # Add display address
    
    # move fourth coordinate down one row
    lw $t3, top_left_bottle  # load in the initial coordinate
    addi $t3, $t3, 24  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t3, $t3, $t6 # this is the new coordinate
    add $t3, $t3, $t4  # Add display address
    
    li $t4, 1  # Reset inner loop counter
    addi $t5, $t5, 1  # Increment outer loop counter
    
    j CONT_LOOP_HORIZONTAL

four_in_a_row_vertical_check:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t4, ADDR_DSPL
    
    # first we initialize the registers with this first 4 coordinates
    lw $t0, top_left_bottle # first coordinate
    add $t0, $t0, $t4
    
    lw $t1, top_left_bottle
    add $t1, $t1, $t4
    addi $t1, $t1, 1024  # second coordinate
    
    lw $t2, top_left_bottle
    add $t2, $t2, $t4
    addi $t2, $t2, 2048  # third coordinate
    
    lw $t3, top_left_bottle
    add $t3, $t3, $t4
    addi $t3, $t3, 3072 # fourth coordinate
    
    # we want to use a loop to iterate until the 4th coordinate reaches the bottle width
    li $t4, 1  # initialize counter for inner loop
    li $t5, 1 # initialize counter for outer loop
    lw $t6, columns
    lw $t7, rows
    
    INNER_LOOP_VERTICAL:
        beq $t4, $t6, reset_inner_loop_vertical
        CONT_LOOP_VERTICAL:
        # Load colors from display memory
        lw $t6, 0($t0) # load in the colours
        lw $t7, 0($t1)
        lw $t8, 0($t2)
        lw $t9, 0($t3)
            
        beq $t6, $t7, first_check_vertical
        
        COME_BACK_VERTICAL:
            lw $t6, columns
            lw $t7, rows
            
            addi $t0, $t0, 4  # first coordinate
            addi $t1, $t1, 4  # second coordinate
            addi $t2, $t2, 4  # third coordinate
            addi $t3, $t3, 4  # fourth coordinate
            
            addi $t4, $t4, 1
            j INNER_LOOP_VERTICAL
    
    done_vertical_check:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
first_check_vertical:
    beq $t7, $t8, second_check_vertical
    j COME_BACK_VERTICAL
    
second_check_vertical:  
    beq $t8, $t9, four_in_a_row_vertical
    j COME_BACK_VERTICAL
    
four_in_a_row_vertical:
    li $v0, 31
    li $a1, 1000
    li $a2, 8
    li $a3, 100
    syscall
    
    # change the colour of the coordinates to black
    lw $t9, black_colour
    sw $t9, 0($t0)  # Clear only the current pixel
    sw $t9, 0($t1)
    sw $t9, 0($t2)
    sw $t9, 0($t3)
    
    # make all the pixels above it fall down
    j COME_BACK_VERTICAL

reset_inner_loop_vertical:
    beq $t5, $t7, done_vertical_check
    
    # move first coordinate down one row
    lw $t0, top_left_bottle  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t0, $t0, $t6 # this is the new coordinate
    lw $t4, ADDR_DSPL  # Reload display address
    add $t0, $t0, $t4  # Add display address
    
    # move second coordinate down one row
    lw $t1, top_left_bottle  # load in the initial coordinate
    addi $t1, $t1, 1024  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t1, $t1, $t6 # this is the new coordinate
    add $t1, $t1, $t4  # Add display address
    
    # move third coordinate down one row
    lw $t2, top_left_bottle  # load in the initial coordinate
    addi $t2, $t2, 2048  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t2, $t2, $t6 # this is the new coordinate
    add $t2, $t2, $t4  # Add display address
    
    # move fourth coordinate down one row
    lw $t3, top_left_bottle  # load in the initial coordinate
    addi $t3, $t3, 3072  # load in the initial coordinate
    li $t6, 512 # load in 512
    mult  $t5, $t6 # figure out the next row
    mflo $t6
    add $t3, $t3, $t6 # this is the new coordinate
    add $t3, $t3, $t4  # Add display address
    
    li $t4, 1  # Reset inner loop counter
    addi $t5, $t5, 1  # Increment outer loop counter
    
    j CONT_LOOP_VERTICAL
    
game_over_check:    
    # Load top pill positions
    li $t0, 6904
    li $t1, 6916
    li $t2, 7416
    li $t3, 7428
    
    # Load positions below top pill
    li $t4, 7416
    addi $t4, $t4, 512    # Move down two rows
    li $t5, 7416
    addi $t5, $t5, 516    # Move down two rows
    li $t6, 7416
    addi $t6, $t6, 520    # Move down two rows
    li $t7, 7416
    addi $t7, $t7, 524    # Move down two rows
    
    # Load display address
    lw $t8, ADDR_DSPL
    
    # Add display address to all positions
    add $t0, $t0, $t8
    add $t1, $t1, $t8
    add $t2, $t2, $t8
    add $t3, $t3, $t8
    add $t4, $t4, $t8
    add $t5, $t5, $t8
    add $t6, $t6, $t8
    add $t7, $t7, $t8
    
    # Load colors at spawn positions (top pill)
    lw $t0, 0($t0)
    lw $t1, 0($t1)
    lw $t2, 0($t2)
    lw $t3, 0($t3)
    
    # Load colors at positions below spawn
    lw $t4, 0($t4)
    lw $t5, 0($t5)
    lw $t6, 0($t6)
    lw $t7, 0($t7)
    
    # Load black color for comparison
    lw $t8, black_colour
    
    # First check if ALL top pill positions are not black
    beq $t0, $t8, RETURN
    beq $t1, $t8, RETURN
    beq $t2, $t8, RETURN
    beq $t3, $t8, RETURN
    
    # Now check if at least one position below is not black
    beq $t4, $t8, check_below_2
    j game_over
    
    RETURN:
        jr $ra
    
check_below_2:
    beq $t5, $t8, check_below_3
    j game_over
    
check_below_3:
    beq $t6, $t8, check_below_4
    j game_over
    
check_below_4:
    beq $t7, $t8, RETURN
    j game_over

game_over:
    li $v0, 1      # syscall code for print integer
    li $a0, 2      # print the number 2
    syscall
    
    lw $t0, ADDR_DSPL
    li $t1, 0 # inner counter
    li $t2, 0 # outer counter
    li $t3, 127 # inner stop
    li $t4, 63 # outer stop
    
    LAST_LOOP:
        beq $t1, $t3, INCR_OUTER
        CONT_LAST_LOOP:
            lw $t5, black_colour
            add $t0, $t0, 4
            sw $t5, 0($t0)
            addi $t1, $t1, 1
        j LAST_LOOP
       
    DRAW_GAME_OVER:
        li $v0, 31
        li $a1, 1000
        li $a2, 8
        li $a3, 100
        syscall
    
        lw $t0, ADDR_DSPL
        lw $t6, white_colour
        
        add $t1, $t0, 9932
        sw $t6, 0($t1)
        add $t1, $t0, 9936
        sw $t6, 0($t1)
        add $t1, $t0, 9940
        sw $t6, 0($t1)
        add $t1, $t0, 9944
        sw $t6, 0($t1)
        add $t1, $t0, 9948
        sw $t6, 0($t1)
        
        add $t1, $t0, 10444
        sw $t6, 0($t1)
        add $t1, $t0, 10956
        sw $t6, 0($t1)
        add $t1, $t0, 11468
        sw $t6, 0($t1)
        add $t1, $t0, 11980
        sw $t6, 0($t1)
        add $t1, $t0, 12492
        sw $t6, 0($t1)
        add $t1, $t0, 13004
        sw $t6, 0($t1)
        
        add $t1, $t0, 13008
        sw $t6, 0($t1)
        add $t1, $t0, 13012
        sw $t6, 0($t1)
        add $t1, $t0, 13016
        sw $t6, 0($t1)
        add $t1, $t0, 13020
        sw $t6, 0($t1)
        
        add $t1, $t0, 13032
        sw $t6, 0($t1)
        
        add $t1, $t0, 13044
        sw $t6, 0($t1)
        add $t1, $t0, 13048
        sw $t6, 0($t1)
        add $t1, $t0, 13052
        sw $t6, 0($t1)
        add $t1, $t0, 13056
        sw $t6, 0($t1)
        
        add $t1, $t0, 9972
        sw $t6, 0($t1)
        add $t1, $t0, 9976
        sw $t6, 0($t1)
        add $t1, $t0, 9980
        sw $t6, 0($t1)
        add $t1, $t0, 9984
        sw $t6, 0($t1)
        add $t1, $t0, 10496
        sw $t6, 0($t1)
        
        add $t1, $t0, 9984
        sw $t6, 0($t1)
        add $t1, $t0, 10496
        sw $t6, 0($t1)
        add $t1, $t0, 11008
        sw $t6, 0($t1)
        add $t1, $t0, 11520
        sw $t6, 0($t1)
        add $t1, $t0, 12032
        sw $t6, 0($t1)
        add $t1, $t0, 12544
        sw $t6, 0($t1)

        add $t1, $t0, 9972
        sw $t6, 0($t1)
        add $t1, $t0, 10484
        sw $t6, 0($t1)
        add $t1, $t0, 10996
        sw $t6, 0($t1)
        add $t1, $t0, 11508
        sw $t6, 0($t1)
        add $t1, $t0, 12020
        sw $t6, 0($t1)
        add $t1, $t0, 12532
        sw $t6, 0($t1)
  
        add $t1, $t0, 12508
        sw $t6, 0($t1)
        add $t1, $t0, 11996
        sw $t6, 0($t1)
        add $t1, $t0, 11992
        sw $t6, 0($t1)
        
    GAME_OVER_INPUT_LOOP:
        lw $t0, ADDR_KBRD
        lw $t8, 0($t0)         # Check if key is pressed (1)
        beq $t8, 1, CHECK_FOR_RESET
        j GAME_OVER_INPUT_LOOP
    
    CHECK_FOR_RESET:
        lw $a0, 4($t0)         # Load the key value
        beq $a0, 0x72, restart_clear   # ASCII 'r'
        li $t8, 0              # Reset flag
        j GAME_OVER_INPUT_LOOP
        
restart_clear:
    clear_bitmap:
        lw $t0, ADDR_DSPL     # Load base address of framebuffer
        lw $t1, black_colour       # Black pixel
        li $t2, 128              # Width
        li $t3, 64               # Height
        mul $t4, $t2, $t3        # Total pixels = 128 * 64
        li $t5, 4                # Each pixel is 4 bytes
    
    clear_loop:
        sw $t1, 0($t0)           # Store black pixel
        add $t0, $t0, $t5        # Move to next pixel
        sub $t4, $t4, 1          # Decrement pixel count
        bgtz $t4, clear_loop     # Loop if more pixels remain
    
j RESTART

INCR_OUTER:
    addi $t2, $t2, 1
    beq $t2, $t4, DRAW_GAME_OVER
    li $t1, 0
    li $t9, 512
    mult $t2, $t9
    mflo $t0
    lw $t8, ADDR_DSPL
    add $t0, $t0, $t8
    j CONT_LAST_LOOP
            
exit:
    li $v0, 1                      # Quit the program
	syscall