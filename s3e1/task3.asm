; task3
; Найти Z - произведение всех положительных нечетных чисел, меньших заданного числа X.

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

	usage_msg db 'Usage: ./task3 uint32', 0x0A, \
				'Example ./task3 42', 0x0A
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

	; calculate product of all odd numbers less than num
	push dword num
	call odd_fact
	add esp, 4

    ; print result (print_uint64 takes eax and edx)
    push eax
    push edx
    call print_uint64   ; for some bizarre reason i did print_uint64 function instead of uint32
    add esp, 8

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
 
; odd_fact calculates product of all odd numbers less than num
; returns product in edx:eax
odd_fact:
	%define num [arg(1)]

    push ebp
    mov ebp, esp

    mov eax, 0 ; eax - result
    cmp num, dword 1 ; if num is below or equal 1 - finish, 
                     ; since there is no positive numbers less than 1
    jbe .finish

    mov eax, 1
    xor edx, edx
    mov ebx, 3
    .next_odd:
        cmp num, ebx
        jbe .finish

        mul ebx
        jo overflow

        add ebx, 2
    loop .next_odd
    
    .finish:
    %undef num
    %undef result

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
 
; Takes uint64 and prints it
print_uint64:
    ; lsp, msp - least (most) significant part
	%define msp [arg(1)]
	%define lsp [arg(2)]
	%define buffer local(1)

	push ebp
	mov ebp, esp
	sub esp, BUFSIZE

	push eax
	push ecx
	push edx
	push esi
	push edi

	mov eax, lsp
    mov ebx, msp
	xor esi, esi           ; as len counter
	mov ecx, 10

    .handle_msp:
        xor edx, edx
        xchg eax, ebx      ; now eax holds msp
        div ecx
        xchg eax, ebx      ; now eax holds lsp
        div ecx
        add dl, '0'        ; now least significant digit is in dl
        lea edi, [buffer+BUFSIZE-1] ; put it in the buffer
		sub edi, esi
		mov [edi], dl

        inc esi

        cmp ebx, 0         ; is msp == 0? if so, handle lsp
        je .handle_lsp     ; this check is done after one iteration,
                           ; so if both lsp and msp is zero, one digit will be in buffer
    loop .handle_msp

	.handle_lsp:           ; integers to symbols
    	cmp eax, 0
		je .break

        xor edx, edx
		div ecx            ; n //= 10;
		add dl, '0'
		lea edi, [buffer+BUFSIZE-1]
		sub edi, esi
		mov [edi], dl

		inc esi            ; ++len
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