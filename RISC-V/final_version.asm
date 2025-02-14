#program ten na podstawie podanych mu 1 pliku .bmp i 4 punktów
#wyrysowuje miêdzy tymi punktami prost¹ na osi metod¹ algorytmu Xialin Wu
	
	
	.data
file_name: .asciz "source.bmp"
out_name: .asciz "out2.bmp"
variable_x1: 	.space 8
variable_y1:	.space 8
variable_x2: 	.space 8
variable_y2:	.space 8
prompt1: .asciz "Podaj zmienn¹ x pierwszego punktu prostej:"
prompt2: .asciz "Podaj zmienn¹ y pierwszego punktu prostej:"
prompt3: .asciz "Podaj zmienn¹ x drugiego punktu prostej:"
prompt4: .asciz "Podaj zmienn¹ y drugiego punktu prostej:"
header: .space 54
width: .word 0
height: .word 0
image: .word 0
.text


main:
	jal read_file
	j prepare_file
draw_function:
	jal get_function_data
	j start_alghoritm
save_and_end:
	j save_file
	
	
get_function_data:
#args: none
#return: none
#gets from user information about points to display
	li a7, 4
	la a0, prompt1
	ecall
	
	li a7, 5
	la a0, variable_x1
	li a1, 10
	ecall
	la t1, variable_x1
	sw a0, 0(t1)
	
	li a7, 4
	la a0, prompt2
	ecall
	
	li a7, 5
	li a1, 10
	ecall
	la t1, variable_y1
	sw a0, 0(t1)
	
	li a7, 4
	la a0, prompt3
	ecall
	
	li a7, 5
	li a1, 10
	ecall
	la t1, variable_x2
	sw a0, 0(t1)
	
	li a7, 4
	la a0, prompt4
	ecall
	
	li a7, 5
	li a1, 10
	ecall
	la t1, variable_y2
	sw a0, 0(t1)

	jr ra


start_alghoritm:
	#a3 x1
	#a4 y1
	#a5 x2
	#a6 y2
	lw a3, variable_x1
	lw a4, variable_y1
	lw a5, variable_x2
	lw a6, variable_y2

	
	
	sub t5, a6, a4
	li t1, 0
	bgt t5, t1, deltay_positive #deltay
	neg t5, t5
	addi t5, t5, 1
deltay_positive:	
	sub t6, a5, a3
	bgt t6, t1, deltax_positive #deltax
	neg t6, t6
	addi t6, t6, 1
deltax_positive:
	blt t5, t6, check_cond #delta t6<t5 deltax<deltay
swap_x_y:	
	mv t1, a3 
	mv t2, a5
	mv a3, a4
	mv a4, t1
	mv a5, a6
	mv a6, t2
	li s10, 1
check_cond:
	blt a3, a5, gradient_calculate
swap_x_x_y_y:
	mv t1, a3 #x1
	mv t2, a4 #y1
	mv a3, a5 #x2->x1
	mv a4, a6 #y2->y1
	mv a5, t1 #x1->x2
	mv a6, t2 #y1->y2
gradient_calculate:
	sub s8, a5, a3
	sub t0, a5, a3
	bgez t0, gradient_positive_1
	neg t0, t0
	addi t0, t0, 1
gradient_positive_1:
	sub s9, a6, a4 #deltay
	sub t1, a6, a4 #deltay
	bgez t1, gradient_positive_2
	neg t1, t1
	addi t1, t1, 1
gradient_positive_2:
	#calculate gradient t1/t0 
	beqz t0, set_gradient
	li t3, 0xFF
	mul t1, t1, t3
loop:
	sub t1, t1, t0
	ble t1, t0, end_gradient_calculate
	addi t2, t2, 1
	j loop
end_gradient_calculate:
	mv t5, t2
	mv t4, t5
	slli t4, t4, 8
	mv t3, t5
	slli t3, t3, 16
	li s6, 0x00000000
	add s6, s6, t5
	add s6, s6, t4
	add s6, s6, t3
	li t3, 0
	blt s8, t3, neg_gradient
	blt s9, t3, neg_gradient
	j draw_line
neg_gradient_check:
	blt s8, t3, check_two_negative
neg_gradient:
	li s7, 5 #gradient negative mark
	j draw_line
	
check_two_negative:
	blt s9, t3, draw_line
	j neg_gradient
	
set_gradient:
	li s6, 0x00000000
draw_line:
#based on there is or not steep add to x1, x2 or y1, y1 height or width
	li t4, 1
	beq s10, t4, draw_line_steep
	la t0, height
	lw t1, 0(t0)
	li t3, 2
	slli t2, t1, 31
	srli t2, t2, 31
	sub t1, t1, t2
	li t2, 2
	srli t1, t1, 1
	add a4, a4, t1
	add a6, a6, t1
	la t0, width
	lw t1, 0(t0)
	li t3, 2
	slli t2, t1, 31
	srli t2, t2, 31
	sub t1, t1, t2
	li t2, 2
	srli t1, t1, 1
	add a3, a3, t1
	add a5, a5, t1
	mv s1, a3 #x1
	mv s2, a5 #x2
	addi s2, s2, 1
	mv s3, a4 #y1
	slli s6, s6, 8
	srli s6, s6, 8
	mv s5, s6 #gradient
	srli s5, s5, 16
	j line_loop_not_steep
draw_line_steep:
	la t0, width
	lw t1, 0(t0)
	li t3, 2
	slli t2, t1, 31
	srli t2, t2, 31
	sub t1, t1, t2
	li t2, 2
	srli t1, t1, 1
	add a4, a4, t1
	add a6, a6, t1
	la t0, height
	lw t1, 0(t0)
	li t3, 2
	slli t2, t1, 31
	srli t2, t2, 31
	sub t1, t1, t2
	li t2, 2
	srli t1, t1, 1
	add a3, a3, t1
	add a5, a5, t1
	mv s1, a3 #x1
	mv s2, a5 #x2
	addi s2, s2, 1
	mv s3, a4 #y1
	slli s6, s6, 8
	srli s6, s6, 8
	mv s5, s6 #gradient
	srli s5, s5, 16
line_loop_steep:
#args: s1, s3, s6
#return: none		
#make line from point x1,y1 to x2, y2 when there is steep	
	mv t5, s3
	li t4, 1
	sub t5, t5, t4
	mv a0, t5
	mv a1, s1
	mv a2, s6
	jal color_pixel
	li t3, 0x00ffffff
	sub t3, t3, s6
	mv a0, s3
	mv a1, s1
	mv a2, t3
	jal color_pixel
	
	
	
	beq s1, s2, save_and_end
	li t2, 5
	srli s6, s6, 16
	beq s7, t2, gradient_negative_steep
	li t2, 0xff
	add s6,  s6, s5
	blt s6, t2, cont_steep
	slli s6, s6, 24
	srli s6, s6, 24
	addi s3, s3, 1
	j cont_steep
gradient_negative_steep:
	sub s6, s6, s5
	li t2, 0
	bgt s6, t2, cont_steep
	slli s6, s6, 24
	srli s6, s6, 24
	li t2, 1
	sub s3, s3, t2
	
cont_steep:
	mv t1, s6
	slli t1, t1, 16
	mv t2, s6
	slli t2, t2, 8
	li t3, 0x00000000
	add t3, t3, t1
	add t3, t3, t2
	add t3, t3, s6
	mv s6, t3
	addi s1, s1, 1
	j line_loop_steep

line_loop_not_steep:
#args: s1, s3, s6
#return: none		
#make line from point x1,y1 to x2, y2 when there is no steep
	mv a0, s1
	mv a1, s3
	mv a2, s6
	jal color_pixel
	li t3, 0x00ffffff
	sub t3, t3, s6
	mv a0, s1
	mv  t2, s3
	li t5, 1
	sub t2, t2, t5
	mv a1, t2
	mv a2, t3
	jal color_pixel

	
	
	beq s1, s2, save_and_end
	li t2, 5
	srli s6, s6, 16
	beq s7, t2, gradient_negative_not_steep
	li t2, 0xff
	add s6,  s6, s5
	blt s6, t2, cont_not_steep
	slli s6, s6, 24
	srli s6, s6, 24
	addi s3, s3, 1
	j cont_not_steep
gradient_negative_not_steep:
	sub s6, s6, s5
	li t2, 0
	bgt s6, t2, cont_not_steep
	slli s6, s6, 24
	srli s6, s6, 24
	li t2, 1
	sub s3, s3, t2
cont_not_steep:
	mv t1, s6
	slli t1, t1, 16
	mv t2, s6
	slli t2, t2, 8
	li t3, 0x00000000
	add t3, t3, t1
	add t3, t3, t2
	add t3, t3, s6
	mv s6, t3
	addi s1, s1, 1
	j line_loop_not_steep




prepare_file:
#args: none
#return: none
#make all pixels in file white and then print on heap file black axis x,y
	li a3, 0 #width
	li a4, 0 #height
clear:
	li a4, 0
clear_iner_loop:
	mv a0, a3
	mv a1, a4
	li a2, 0x00FFFFFF
	jal color_pixel
	la t0, height
	lw t1, 0(t0)
	beq a4, t1, clear_outer_loop
	addi a4, a4, 1
	j clear_iner_loop
clear_outer_loop:	
	la t0, width
	lw t1, 0(t0)
	beq a3, t1, axis_y
	addi a3, a3, 1
	j clear
axis_y:
	la t0, width
	lw t1, 0(t0)
	li t3, 2
	slli t2, t1, 31
	srli t2, t2, 31
	sub t1, t1, t2
	li t2, 2
	srli t1, t1, 1
	mv a3, t1
	li a4, 0 #height
axis_y_loop:
	mv a0, a3
	mv a1, a4
	li a2, 0x00000000
	jal color_pixel
	la t0, height
	lw t1, 0(t0)
	beq a4, t1, axis_x
	addi a4, a4, 1
	j axis_y_loop
axis_x:				
	la t0, height
	lw t1, 0(t0)
	li t3, 2
	slli t2, t1, 31
	srli t2, t2, 31
	sub t1, t1, t2
	li t2, 2
	srli t1, t1, 1
	mv a4, t1
	li a3, 0 #width
axis_x_loop:
	mv a0, a3
	mv a1, a4
	li a2, 0x00000000
	jal color_pixel
	la t0, width
	lw t1, 0(t0)
	addi a3, a3, 1
	beq a3, t1, draw_function
	j axis_x_loop	




color_pixel:
#args: 
#a0 - x pixel position
#a1 - y pixel position
#a2 - color on which pixel on x, y pos ought to be colored	
#reutrn: none
#color pixel at x,y on choosen color in file saved on heap

	#pixel address calculation
	li t6, 3
	la t5, width
	lw t4, 0(t5)
	mul t6, t6, t4
	li t1, 4
	slli t5, t6, 30
	srli t5, t5, 30
	sub t1, t1, t5
	li t2, 4
	beq t1, t2, skip_padding
	add t6, t6, t1
skip_padding:	
	mul t1, a1, t6 
	mv t3, a0		
	slli a0, a0, 1
	add t3, t3, a0	
	add t1, t1, t3	
	li t0, 0
	add t0, t0, s0
	addi t0, t0, 54
	add t0, t0, t1
	
	#set new color
	sb a2,0(t0)
	srli a2,a2,8
	sb a2,1(t0)
	srli a2,a2,8
	sb a2,2(t0)
	jr ra
	
read_file:
#args: file_name
#reutrn: none
#reads file and gets it's height, width and save whole file on heap
	la a0, file_name
	li a1, 0
	li a7, 1024
	ecall
	mv s1, a0 #file decipher
	
	li a7, 63
	mv a0, s1
	la a1, header
	li a2, 54
	ecall
	mv t0, a1 #header address
		
	mv a0, s1
	li a7, 57
	ecall
	
	la a0, file_name
	li a1, 0
	li a7, 1024
	ecall
	mv s1, a0 #file decipher
	addi t0, t0, 0x22
	li t5, 4
	slli t6, t0, 30
	srli t6, t6, 30
	beq t6, t5, skip_alligment
	sub t5, t5, t6
	add t0, t0, t5
skip_alligment:
	li a7, 9
	lw a0, (t0)
	ecall	
	mv s0, a0 #heap adress
	
	li t6, 0x14
	sub t0, t0, t6
	lw t5, 0(t0)
	la t6, width
	srli t5, t5, 16
	sw t5, 0(t6)
	
	li t6, 0x04
	add t0, t0, t6
	lw t5, 0(t0)
	la t6, height
	srli t5, t5, 16
	sw t5, 0(t6)
	
	
	li a7, 63
	mv a0, s1
	mv a1, s0
	lw a2, 0(t0)
	ecall
	mv s4, a0 #data read length
	
	mv a0, s1
	li a7, 57
	ecall
	
	jr ra
	
save_file:
#args: out_name
#reutrn:
	la a0, out_name
	li a1, 1
	li a7, 1024
	ecall
	mv s1, a0 #file decipher
	
	mv a0, s1
	mv a1, s0
	mv a2, s4
	li a7, 64
	ecall
	
	mv a0, s1
	li a7, 57
	ecall

end:
	li a7, 10
	ecall
	

	  
