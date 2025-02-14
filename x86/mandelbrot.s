section .text
global mandelbrot
;
; RDI = pixelBuffer;
; RSI = width;
; RDX = height
; RCX = processPower;
; R8 = setPoint;
; xmm0 = centerReal;
; xmm1 = centerImag;
; xmm2 = zoom;

mandelbrot:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    push r13
    push r14

    ; Body

    ; Check if width or height are not positive
    cmp rsi, 0
    jle end
    cmp rdx, 0
    jle end

    ; Calculate buffer size: r9 = bufferSize = 4 * width * height
    mov rax, rsi
    imul rax, rdx
    shl rax, 2
    mov r9, rax

    ; Initialize y = 0 (integer for loop control)
    mov r10, 0          ; yRegister = r10 = y = 0

for_y_loop:
    ; Check if y < height
    cmp r10, rdx
    jge end

    ; Initialize x = 0 (integer for loop control)
    mov r11, 0          ; xRegister = r11 = x = 0

for_x_loop:
    ; Check if x < width
    cmp r11, rsi
    jge end_x_loop

    ; Calculate cReal
    ; xmm6 = cReal = (x / width - 0.5) * 4.0 / zoom + centerReal
    ; cReal = (4x - 2width) / (width * zoom) + centerReal
    mov rax, r11
    shl rax, 2
    cvtsi2sd xmm3, rax      ; 4x
    mov rax, rsi
    shl rax, 1
    cvtsi2sd xmm4, rax      ; 2width
    movsd xmm6, xmm3        ; cReal = 4x
    subsd xmm6, xmm4        ; cReal = 4x - 2 width
    cvtsi2sd xmm3, rsi
    mulsd xmm3, xmm2        ; width * zoom
    divsd xmm6, xmm3
    addsd xmm6, xmm0        ; xmm6 = cReal

    ; Calculate cImag
    ; xmm7 = cImag = (y / height - 0.5) * 4.0 / zoom + centerImag

    mov rax, r10
    shl rax, 2
    cvtsi2sd xmm3, rax      ; 4y
    mov rax, rdx
    shl rax, 1
    cvtsi2sd xmm4, rax      ; 2height
    movsd xmm7, xmm3
    subsd xmm7, xmm4
    cvtsi2sd xmm3, rdx
    mulsd xmm3, xmm2
    divsd xmm7, xmm3
    addsd xmm7, xmm0        ; xmm7 = cImag

    ; isInSet(cReal=xmm5, cImag=xmm8, processPower=rcx, setPoint=r8)
    ; Initialize Iters
    mov r12, 0        ; int i = r12 = 0

    ; Initialize zReal and zImag
    xorpd xmm8, xmm8      ; zReal
    xorpd xmm9, xmm9     ; zImag

is_in_mandelbrot:
    ; Check if Iters >= processPower
    cmp r12, rcx
    jge max_iter_reached

    inc r12

    ; x^2 + 2xyj - y^2
    movsd xmm10, xmm8    ; xmm10 = zReal copy
    mulsd xmm10, xmm10    ; zReal^2

    movsd xmm11, xmm9   ; xmm11 = zImag copy
    mulsd xmm11, xmm11    ; zImag^2

    subsd xmm10, xmm11    ; xmm10 = zReal^2 - zImag^2

    movsd xmm11, xmm9   ; xmm11 = zImag
    mulsd xmm11, xmm8    ; zReal * zImag
    addsd xmm11, xmm11    ; xmm11 = 2 * zReal * zImag

    ; zReal = complexSquaredReal + cReal
    addsd xmm10, xmm6    ; xmm9 = zReal = (zReal^2 - zImag^2) + cReal
    ; zImag = complexSquaredImag + cImag
    addsd xmm11, xmm7    ; xmm9 = zImag = (2 * zReal * zImag) + cImag

    ; Update zReal and zImag
    movsd xmm8, xmm10
    movsd xmm9, xmm11

    ; Calculate |z|
    movsd xmm10, xmm8
    mulsd xmm10, xmm10
    movsd xmm11, xmm9
    mulsd xmm11, xmm11
    addsd xmm10, xmm11  ; xmm10 = |z|

    ; Check if |z| > setPoint^2
    mov rax, r8
    imul rax, r8
    cvtsi2sd xmm11, rax   ; xmm10 = setPoint ^ 2
    ucomisd xmm10, xmm11
    jbe  is_in_mandelbrot

    jmp return_iter

max_iter_reached:
    ; If max iterations reached (iters == processPower), set color to black
    mov bl, 0          ; RBX = 0 (black color)
    jmp calculate_pixel_idx

return_iter:
    ; Calculate pixel colors
    mov bl, 1       ; Set flag for coloring in bl

    mov rax, r12
    push rdx
    imul rax, 10
    and rax, 0xFF
    mov byte [ rbp - 1 ], al
    mov rax, r12
    imul rax, 15
    and rax, 0xFF
    mov byte [ rbp - 2 ], al
    mov rax, r12
    imul rax, 20
    and rax, 0xFF
    mov byte [ rbp - 3 ], al
    pop rdx

calculate_pixel_idx:
    ; long pixelIdx = 4 * (y * width + x);
    mov rax, r10
    imul rax, rsi
    add rax, r11
    shl rax, 2
    mov r13, rax        ; r13 = pixelIdx

    add rax, 3
    cmp rax, r9
    jge end             ; if (pixelIdx + 3 >= bufferSize) return;

    test bl, bl
    jz set_black


set_colored:
    mov bl, byte [ rbp - 1 ]
    mov byte [ rdi + r13 ], bl      ; R
    add r13, 1
    mov bl, byte [ rbp - 2 ]
    mov byte [ rdi + r13 ], bl      ; G
    add r13, 1
    mov bl, byte [ rbp - 3 ]
    mov byte [ rdi + r13 ], bl      ; B
    add r13, 1
    mov byte [ rdi + r13 ], 255     ; A
    jmp next_pixel

set_black:
    mov dword [ rdi + r13], 0xFF000000

next_pixel:
    inc r11                 ; increment x
    jmp for_x_loop

end_x_loop:
    inc r10                 ; increment y
    jmp for_y_loop

end:
    ; Epilogue
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret