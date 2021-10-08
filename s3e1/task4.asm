; task4
; Найти K - количество точек с целочисленными координатами, 
; попадающих в круг радиуса R с центром в точке (0, 0).

; Points on circle border also counted!

%define arg(n) ebp+(4*n)+4
%define local(n) ebp-(4*n)
 
%define SYS_CALL 0x80
%define SYS_WRITE 0x4
%define SYS_READ 0x3
%define SYS_EXIT 0x1
 
%define STDOUT 0x1
%define STDIN 0x0
 
%define EOF 0x0
%define BUFSIZE 32
 
section .rodata
	msg_of db 'Overflow', 0x0A
	msg_of_len equ ($ - msg_of)

	msg_bi db 'Bad input', 0x0A
	msg_bi_len equ ($ - msg_bi)

	usage_msg db 'Usage: ./task4 radius-of-circle', 0x0A, \
				'Example ./task4 42', 0x0A
	usage_msg_len equ ($ - usage_msg)

    new_line db 0x0A
 
section .text
	global _start
  
_start:
	%define argc [arg(0)]
	%define argv1 [arg(2)]
	%define num [local(1)]

	; create a stack frame
	push ebp
	mov ebp, esp
	sub esp, 4 ; allocate space on the stack for local vars

	; check if 1 argument is passed
	cmp argc, dword 2
	jne usage

	; convert a string containing a number to uint32
	push dword argv1
	call stou
	add esp, 4
	mov num, eax

	; calculate number of integer points located inside circle with given radius
	push dword num
	call calc_points
	add esp, 4

    ; print result
    push eax
    call print_uint32
    add esp, 4

    push dword 1
    push new_line
    call print 
    add esp, 8

	; exit with code 0x0
	push 0x0
	call exit

	%undef argc
	%undef argv1
	%undef num
 
; calc_points returns number of integer points located inside circle with given radius.
; If radius == 0, since 0^2 + 0^2 <= 0^2, returned value is 1.
calc_points:
	%define radius [arg(1)]
    %define sq_radius [local(1)]
    %define result [local(2)]
    %define p_inside [local(3)]
    ; p_inside -- points inside circle but not on axises

    push ebp
    mov ebp, esp
	sub esp, 12

    ; TOOD: save used registers

    mov result, dword 1

    cmp radius, dword 0
    je .end

    ; count points lying on axises
    mov eax, radius

    ; now eax holds number of points lying on axis Ox, where x > 0
    ; multiplying that number by 4, we get number of points lying on all axises
    mov ebx, 4
    xor edx, edx
    mul ebx
    jo overflow

    add result, eax
    jc overflow

    ; calculate square of radius
    mov eax, radius
    xor edx, edx
    mul eax
    jo overflow
    mov sq_radius, eax

    ; now count points lying inside circle but not on axises 
    ; by comparing the distance from point to center with radius using Pythagorean theorem
    mov p_inside, dword 0
    mov ecx, radius
    .x_loop:
        push ecx
        
        ; calculate x^2 and keep it in esi
        mov eax, ecx
        xor edx, edx
        mul eax ; shouldn't overflow because we already calculated r^2
        mov esi, eax

        mov ecx, radius
        .y_loop:
            ; calculate y^2
            mov eax, ecx
            xor edx, edx
            mul eax ; shouldn't overflow because we already calculated r^2
            
            add eax, esi ; y^2 + x^2
            jc overflow

            cmp eax, sq_radius
            jbe .in_circle
            ; optimise to not calculate further for given x
        loop .y_loop

		.in_circle:
		add p_inside, ecx ; all points from y = 1 to y = ecx are in circle, so sum them
        pop ecx
		
    loop .x_loop

    xor edx, edx
    mov eax, p_inside
    mov ebx, 4
    mul ebx ; 4 * points_inside_one_section
    jo overflow
    
    add result, eax
    jc overflow

    .end:
    mov eax, result

    mov esp, ebp
	pop ebp
    ret

; stou takes a string containing uint32
; and returns parsed uint32 in eax.
; If not a number is given or overflow occurred,
; it terminates a program with a corresponding error.
stou:
	%define result [local(1)]
	%define string [arg(1)]

	push ebp
	mov ebp, esp
	sub esp, 4

    ; TOOD: save used registers

	mov esi, string
	mov ecx, 10 ; base
	xor ebx, ebx

	mov result, dword 0

	; check sign
	mov al, [esi]
	inc esi
	cmp al, '+'
	jne .check_input

	.loop:
		mov al, [esi]
		inc esi

		.check_input:

		; al == digit?
		cmp al, '0'
		jb .break
		cmp al, '9'
		ja .break

		mov bl, al
		
		mov eax, result
		mul ecx
		jo overflow
		
		sub bl, '0'
		
		add eax, ebx
		jc overflow
		mov result, eax
	jmp .loop
	.break:

	cmp al, byte EOF
	je .ok
	cmp al, 0xA ; '\n'
	je .ok
	cmp al, ' '
	je .ok
	jmp bad_input
	.ok:

	mov eax, result

	mov esp, ebp
	pop ebp

	%undef result
	%undef string
	ret
 
; Takes uint32 and prints it
print_uint32:
	%define num [arg(1)]
	%define buffer local(1)

	push ebp
	mov ebp, esp
	sub esp, BUFSIZE

	push eax
	push ecx
	push edx
	push esi
	push edi

	mov eax, num
	xor esi, esi           ; as len counter
	mov ecx, 10

	.handle_lsp:           ; integers to symbols
        xor edx, edx
		div ecx            ; n //= 10;
		add dl, '0'
		lea edi, [buffer+BUFSIZE-1]
		sub edi, esi
		mov [edi], dl

		inc esi            ; ++len

        cmp eax, 0
		je .break
	jmp .handle_lsp
	.break:

	lea edi, [buffer+BUFSIZE]
	sub edi, esi

	push esi
	push edi
	call print
	add esp, 8

	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax

	%undef number
	mov esp, ebp
	pop ebp
	ret
 
; print takes length and string and prints string.
; arg2 -- str
; arg1 -- len
print:
	%define str [arg(1)]
	%define len [arg(2)]
	push ebp
	mov ebp, esp

	push eax
	push ebx
	push ecx
	push edx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, str
	mov edx, len
	int SYS_CALL

	pop edx
	pop ecx
	pop ebx
	pop eax

	%undef str
	%undef len

	pop ebp
	ret
 
; ==
; error handlers
; ==
 
overflow:
	push msg_of_len
	push msg_of
	call print
	add esp, 8

	push 0x1        ; overflow exitcode
	call exit
 
usage:
	push usage_msg_len
	push usage_msg
	call print
	add esp, 8

	push 0x2        ; badinput exitcode
	call exit
 
bad_input:
	push msg_bi_len
	push msg_bi
	call print
	add esp, 8

	push 0x2        ; badinput exitcode
	call exit
 
; exit terminates program with given exitcode
; arg1 -- exitcode
exit:
	%define exitcode [arg(1)]
	push ebp
	mov ebp, esp

	mov eax, SYS_EXIT
	mov ebx, exitcode
	int SYS_CALL

	%undef exitcode
	pop ebp
	ret