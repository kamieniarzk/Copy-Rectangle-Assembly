		.data
pImg:		.space 32830			# fits at most 512x512 bitmap
imgInf: 	.word 512, 512, pImg, 0, 0, 0	# requires setting bitmap size
# 0(imgInf) - width
# 4(imgInf) - height
# 8(imgInf) - buffer pointer
# 12(imgInf) - cX
# 16(imgInf) - cY
# 20(imgInf) - col

rect:		.word 0 0 0 0 
# 0(rect) - left
# 4(rect) - top
# 8(rect) - right
# 12(rect) - bottom
point:		.word 0 0
# 0(point) - x
# 4(point) - y
input:		.asciiz "start.bmp"
output:		.asciiz "output.bmp" 			
fsize:		.word 0 
r_error_msg:	.asciiz "\nError while reading file."
w_error_msg:	.asciiz "\nError while writing file."
wrong_rect_msg: .asciiz "\n Given rectangle does not fit within bitmap."
		.text
main:
	la $a0, input		# input filename 
	la $a1, pImg		# buffer
	li $a2, 32830
	jal read_file
	la $a2, point
	la $a0, imgInf
	li $t0, 150		# x
	li $t1, 150		# y
	sw $t0 0($a2) 
	sw $t1 4($a2)
	la $a1, rect
	li $t0, 0		# left	
	li $t1, 300		# top
	li $t2, 100		# right
	li $t3, 200		# bottom
	sw $t0, 0($a1)
	sw $t1, 4($a1)
	sw $t2, 8($a1)
	sw $t3, 12($a1)
	jal draw_rectangle
	la $a1, rect
	la $a2, point
	jal copy_rect
	
	la $a0, output		# output filename
	la $a1, pImg		# buffer
	jal write_file
	j exit
	
move_to:
	# a0 - imgInf
	# a1 - x
	# a2 - y
	sw	$a1, 12($a0)	
	sw	$a2, 16($a0)
	jr 	$ra
copy_rect:
	# a0 - imgInf
	# a1 - rect
	# a2 - pDst
	addi 	$sp, $sp, -4 	# make room on stack (non-leaf function)
	sw 	$ra, 0($sp) 
	
	lw 	$s0, 0($a1)	# pSrc->left
	lw 	$s1, 4($a1)	# pSrc->top	
	lw 	$s2, 8($a1)	# pSrc->right
	lw 	$s3, 12($a1)	# pSrc->bottom
	lw	$s4, 0($a2)	# pDst->x
	lw	$s5, 4($a2)	# pDst>y
	
	bgt	$s4, $s0, if2	
	bge	$s5, $s1, case1	# if(x <= left && y >= top)
if2:
	bge	$s4, $s0, if3
	blt	$s5, $s1, case2	# if(x < left && y < top)
if3:
	ble	$s5, $s1, case4	# if(x >= left && y <= top)
	bgt	$s5, $s1, case3	# if(x > left && y > top)
	
case4:	######################### if(x >= left && y <= top)
	move	$s6, $s3	# s6 = bottom
	move 	$s7, $s2	# s7 = right
y4_loop:
	bgt 	$s6, $s1, end_y4 # for(s6 = bottom; s6 <= top; s6++)
x4_loop:
	blt	$s7, $s0, end_x4 # for(s7 = right; s7 >= left; s7--)
	move	$a2, $s7	# a2 = s6
	move	$a3, $s6	# a3 = s7
	la 	$a1, pImg
	jal 	get_pixel
	move	$a1, $v0
	jal 	set_color	# sets color to that in a1
	subu	$t0, $s7, $s0	# s7 - left
	add	$a1, $t0, $s4	# x + (s7 - left)
	subu	$t1, $s6, $s1 	# s6 - top
	addu	$a2, $s5, $t1	# y + (s6 - top)
	jal 	move_to
	la	$a1, pImg
	jal 	set_pixel	# sets pixel at (cX, cY)
	addi	$s7, $s7, -1
	b 	x4_loop
end_x4:
	addi	$s6, $s6, 1
	move 	$s7, $s2
	b	y4_loop
end_y4:
	lw 	$ra, 0($sp) 	# retrieve return address
	addi 	$sp, $sp, 4 
	jr	$ra

case1: 	######################### if(x <= left && y >= top)			
	move	$s6, $s1	# s6 = top
	move 	$s7, $s0	# s7 = left
y1_loop:
	blt 	$s6, $s3, end_y1 # for(s6 = top; s6 >= bottom; s6--)
x1_loop:
	bgt	$s7, $s2, end_x1 # for(s7 = left; s7 <= right; s7++)
	move	$a2, $s7	# a2 = s7
	move	$a3, $s6	# a3 = s6
	la 	$a1, pImg
	jal 	get_pixel
	move	$a1, $v0
	jal 	set_color	# sets color to that in a1
	subu	$t0, $s7, $s0	# s7 - left
	add	$a1, $t0, $s4	# x + (s7 - left)
	subu	$t1, $s6, $s1 	# s6 - top
	addu	$a2, $s5, $t1	# y + (s6 - top)
	jal 	move_to
	la	$a1, pImg
	jal 	set_pixel	# sets pixel at (cX, cY)
	addi	$s7, $s7, 1
	b 	x1_loop
end_x1:
	addi	$s6, $s6, -1
	move 	$s7, $s0
	b	y1_loop
end_y1:
	lw 	$ra, 0($sp) 	# retrieve return address
	addi 	$sp, $sp, 4 
	jr	$ra
	
case2: 	######################### if(x < left && y < top)
	move	$s6, $s3	# s6 = bottom
	move 	$s7, $s0	# s7 = left
y2_loop:
	bgt 	$s6, $s1, end_y2 # for(s6 = bottom; s6 <= top; s6++)
x2_loop:
	bgt	$s7, $s2, end_x2 # for(s7 = left; s7 <= right; s7++)
	move	$a2, $s7	# a2 = s7
	move	$a3, $s6	# a3 = s6
	la 	$a1, pImg
	jal 	get_pixel
	move	$a1, $v0
	jal 	set_color	# sets color to that in a1
	subu	$t0, $s7, $s0	# s7 - left
	add	$a1, $t0, $s4	# x + (s7 - left)
	subu	$t1, $s6, $s1 	# s6 - top
	addu	$a2, $s5, $t1	# y + (s6 - top)
	jal 	move_to
	la	$a1, pImg
	jal 	set_pixel	# sets pixel at (cX, cY)
	addi	$s7, $s7, 1
	b 	x2_loop
end_x2:
	addi	$s6, $s6, 1
	move 	$s7, $s0
	b	y2_loop
end_y2:
	lw 	$ra, 0($sp) 	# retrieve return address
	addi 	$sp, $sp, 4 
	jr	$ra			

case3: ########################## if(x > left && y > top)				
	move	$s6, $s1	# s6 = top
	move 	$s7, $s2	# s7 = right
y3_loop:
	blt 	$s6, $s3, end_y3 # for(s6 = top; s6 >= bottom; s6--)
x3_loop:
	blt	$s7, $s0, end_x3 # for(s7 = right; s7 >= left; s7--)
	move	$a2, $s7	# a2 = s7
	move	$a3, $s6	# a3 = s6
	la 	$a1, pImg
	jal 	get_pixel
	move	$a1, $v0
	jal 	set_color	# sets color to that in a1
	subu	$t0, $s7, $s0	# s7 - left
	add	$a1, $t0, $s4	# x + (s7 - left)
	subu	$t1, $s6, $s1 	# s6 - top
	addu	$a2, $s5, $t1	# y + (s6 - top)
	jal 	move_to
	la	$a1, pImg
	jal 	set_pixel	# sets pixel at (cX, cY)
	addi	$s7, $s7, -1
	b 	x3_loop
end_x3:
	addi	$s6, $s6, -1
	move 	$s7, $s2
	b	y3_loop
end_y3:
	lw 	$ra, 0($sp) 	# retrieve return address
	addi 	$sp, $sp, 4 
	jr	$ra
	
draw_rectangle:			# (set color first)
	# a0 - imgInf
	# a1 - rect
	addi 	$sp, $sp, -4 	# make room on stack
	sw 	$ra, 0($sp) 
	
	lw 	$s0, 0($a1)	# left
	lw 	$s1, 4($a1)	# top	
	lw 	$s2, 8($a1)	# right
	lw 	$s3, 12($a1)	# bottom
	li	$a1, 0
	jal 	set_color
	
	move	$s4, $s0	# t4 = current x 
	move 	$s5, $s3	# t5 = current y
x_loop:
	bgt 	$s4, $s2, end_x	# for t4 = left; t4 <= right; t4++
y_loop:
	bgt	$s5, $s1, end_y	# for t5 = bottom; t5 <= top; t5++
	move	$a1, $s4	# a1 = cX
	move	$a2, $s5	# a2 = cY
	jal 	move_to		# sets cX and cY to current x and y
	la 	$a1, pImg
	jal 	set_pixel	# sets pixel at (cX, cY)
	addi	$s5, $s5, 1
	
	b 	y_loop
end_y:
	addi	$s4, $s4, 1
	move	$s5, $s3
	b	x_loop
end_x:
	lw 	$ra, 0($sp) 	# retrieve return address
	addi 	$sp, $sp, 4 
	jr	$ra
	
set_pixel:			
	# a0 - imgInf
	# a1 - pImg
		
	lw	$t0, 12($a0)	# x
	lw	$t1, 16($a0)	# y
	lw	$t2, 0($a0)	# width	
	lw	$t3, 4($a0)	# height
	la	$t4, 0($a1)	# pImg
	li	$t6, 0x80	# mask = 0x80	
	lw	$t9, 20($a0)	# color
	
	# boundaries check
	bgt 	$t0, $t2, end_pixel
	bgt	$t1, $t3, end_pixel
	bltz	$t0, end_pixel
	bltz	$t1, end_pixel
	
	add	$t4, $t4, 62	# pPix + 62 (jump ahead of bmp header) - buffer pointer
	multu 	$t1, $t2	# y * width
	mflo 	$t5   		# 
	addu 	$t5, $t5, $t0	# y * width + x
	li	$t6, 8
	divu 	$t5, $t6	
	mfhi	$t6		# (x + y*width) mod 8
	mflo 	$t5		# (x + y*width)/8
	addu	$t5, $t5, $t4	# current byte index + buffer pointer
	
	li	$t7, 128	
	srlv	$t7, $t7, $t6	# mask = 0x80 >> (x&7)

	
	lb 	$t8, ($t5)	# get current byte (*pPix)
	
	or	$t8, $t8, $t7	# *pPix |= mask
	bnez	$t9, black	# if color is white

	not 	$t7, $t7	# !mask
	and 	$t8, $t8, $t7	# *pPix &= !mask
black:
	sb 	$t8, ($t5)
	jr 	$ra
	
end_pixel:			# wrong arguments
	jr	$ra

get_pixel:			# returns bit index if color is white, 0 if color is black
	# a0 - imgInf
	# a1 - pImg
	# a2 - x
	# a3 - y
	move	$t0, $a2	# x
	move	$t1, $a3	# y
	lw	$t2, 0($a0)	# width	
	lw	$t3, 4($a0)	# height
	la	$t4, 0($a1)	# pImg
	li	$t6, 0x80	# mask = 0x80	
	lw	$t9, 20($a0)	# color
	# boundaries check
	bgt 	$t0, $t2, end_get
	bgt	$t1, $t3, end_get
	bltz	$t0, end_get
	bltz	$t1, end_get
	
	add	$t4, $t4, 62	# jump past header
	multu 	$t1, $t2	# Y * width
	mflo 	$t5   		# 
	addu 	$t5, $t5, $t0	# y * width + x
	li	$t6, 8
	divu 	$t5, $t6
	mfhi	$t6		# (x + y*width) mod 8
	mflo 	$t5		# (x + y*width)/8
	addu	$t5, $t5, $t4	# current byte index + buffer pointer
	
	li	$t7, 128	
	srlv	$t7, $t7, $t6	# mask = 0x80 >> (x&7)
	lb 	$t8, ($t5)	# get current byte (*pPix)
	and	$v0, $t8, $t7	# return *pPix & mask
	jr	$ra
end_get:
	li 	$v0, 0		# return 0 if outside boundaries
	jr 	$ra


set_color:
	# a0 - imgInf
	# a1 - color
	sw 	$a1, 20($a0)
	jr	$ra
	
read_file:			
	# a0 - file name, 
	# a1 - buffer, 
	# a2 - size
	move	$s0, $a1	# s0 = buffer
	move 	$s1, $a2	# s1 = size
	li	$a1, 0		# flag	
	li	$a2, 0		# mode
	li	$v0, 13		# open file
	syscall
	
	bltz	$v0, read_error
	move	$a0, $v0	# file descriptor	
	move	$a1, $s0	# buffer
	move	$a2, $s1	# size
	li	$v0, 14		# read from file
	syscall
	
	sw	$v0, fsize	# store fsize
	
	li	$a0, 3
	li 	$v0, 16		# close file
	syscall
	jr	$ra
	
write_file:			# a0 - file descriptor
	move	$s0, $a1	# s0 = buffer	
	li	$a1, 1		# a1 - buffer
	li	$a2, 3
	li	$v0, 13		# open file
	syscall
	bltz	$v0, write_error

	move	$a0, $v0	# descriptor
	move	$a1, $s0	# buffer
	lw	$a2, fsize
	li 	$v0, 15		# write file
	syscall
	
	move	$a0, $s1
	li 	$v0, 16		# close file
	syscall
	jr	$ra
read_error:
	li 	$v0, 4
	la 	$a0, r_error_msg
	syscall
	j 	exit
write_error:
	li 	$v0, 4
	la 	$a0, w_error_msg
	syscall
	j 	exit
	
wrong_rectangle:
	li 	$v0, 4
	la 	$a0, wrong_rect_msg
	syscall
	j 	exit
	
exit:
	li 	$v0, 10
	syscall
