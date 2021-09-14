; task 2: 
; Верно ли высказывание, что цифра 5 входит в десятичную запись трехзначного целого числа k

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

	usage_msg db 'Usage: ./task1 3-digit-number', 0x0A, \
				'Example ./task1 153', 0x0A
	usage_msg_len equ ($ - usage_msg)

	contain_msg db 'Given number contains digit 5', 0x0A
	contain_msg_len equ ($ - contain_msg)

	not_contain_msg db 'Given number does not contain digit 5', 0x0A
	not_contain_msg_len equ ($ - not_contain_msg)

	minus db '-'
 
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

	; convert a string containing a number to an integer
	push dword argv1
	call stoi
	add esp, 4
	mov num, eax

	cmp eax, 0
	jge .is_positive
	; .is_negative:
		neg eax
		mov num, eax
	.is_positive:

	; check if the passed argument is 3 digit number
	push dword num
	call count_digits
	add esp, 4
	cmp eax, 3
	jne bad_input

	; check if the number contains 5
	; if so, eax will hold 1
	push dword num
	call contains5
	add esp, 4

	; if eax == 0
	test eax, eax
	je .false
	; .true:
		push contain_msg_len
		push contain_msg
		call print
		add esp, 8
	jmp .endif
	.false:
		push not_contain_msg_len
		push not_contain_msg
		call print
		add esp, 8
	.endif:

	; exit with code 0x0
	push 0x0
	call exit

	%undef argc
	%undef argv1
	%undef num
 
; count_digits counts amount of digits in number
count_digits:
	%define num [arg(1)]

	push ebp
	mov ebp, esp

	push ebx
	push edx

	mov eax, num
	mov ebx, 10
	xor ecx, ecx ; counter for digits

	.check_digit:
		xor edx, edx
		test eax, eax
		je .is_zero

		inc ecx

		div ebx
	jmp .check_digit

	.is_zero:
	mov eax, ecx

	pop edx
	pop ebx

	%undef num

	mov esp, ebp
	pop ebp
	ret
 
 
; contains5 checks if number contains digit 5
contains5:
	%define num [arg(1)]

	push ebp
	mov ebp, esp

	push ebx
	push edx

	mov eax, num
	mov ebx, 10

	.check_digit:
		xor edx, edx
		test eax, eax
		je .hasnt_5

		div ebx
		cmp edx, 5
		je .has_5
	jmp .check_digit

	.hasnt_5:
		mov eax, 0
	jmp .endif
	.has_5:
		mov eax, 1
	.endif:

	pop edx
	pop ebx

	%undef num

	mov esp, ebp
	pop ebp
	ret
 
; stoi takes a string containing uint/int
; and returns parsed int in eax.
; If not a number is given or overflow occurred,
; it terminates a program with a corresponding error.
stoi:
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
	mov edi, 1 ; sign (1 - positive, -1 - negative)
	mov al, [esi]
	inc esi
	cmp al, '+'
	je .loop
	cmp al, '-'
	jne .check_input
	neg edi

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
		jo overflow
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
	cmp edi, -0x1
	jne .positive
	neg eax
	.positive:

	mov esp, ebp
	pop ebp

	%undef result
	%undef string
	ret
 
; Takes signed int and prints it
print_int:
	%define number [arg(1)]
	%define buffer local(1)

	push ebp
	mov ebp, esp
	sub esp, BUFSIZE

	push eax
	push ecx
	push edx
	push esi
	push edi

	mov eax, number
	cmp eax, 0             ; is number negative or positive?
	jnl .positive
	neg eax

	push dword 0x1
	push minus
	call print
	add esp, 8

	.positive:

	xor esi, esi           ; as len counter
	mov ecx, 10
	.itoc:                 ; ints to symbols
		xor edx, edx
		div ecx            ; n //= 10;
		add dl, '0'
		lea edi, [buffer+BUFSIZE-1]
		sub edi, esi
		mov [edi], dl

		inc esi            ; ++len

		cmp eax, 0
		jle .break
	jmp .itoc
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