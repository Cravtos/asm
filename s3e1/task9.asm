; task9:
; Является ли число X палиндромом в двоичной системе счисления?

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

section .data
	ofmsg db 'Overflow', 0x0a
	ofmsglen equ ($ - ofmsg)

	bimsg db 'Bad input (NaN)', 0x0a
	bimsglen equ ($ - bimsg)

	negmsg db 'Got negative number while waiting for unsinged integer', 0x0a
	negmsglen equ ($ - negmsg)

    ispalmsg db 'Given number is palindrome in binary', 0x0a
    ispalmsglen equ ($ - ispalmsg)

    notpalmsg db 'Given number is not palindrome in binary', 0x0a
    notpalmsglen equ ($ - notpalmsg)

    enterx db 'Enter number: '
    enterxmsg equ ($ - enterx)

	new_line db 0x0A
	lbracket db '['
	rbracket db ']'
	space db ' '
	minus db '-'

section .text
	global _start

_start:
	push ebp
	mov ebp, esp
	sub esp, 16

	push enterxmsg
	push enterx
	call print
	add esp, 8

	call read_uint32
    push eax
    call is_palindrome
    add esp, 4

	cmp eax, 1
    je .is_pal

	; .not_pal:
		push notpalmsglen
		push notpalmsg
		call print
		add esp, 8
	jmp .exit
	.is_pal:
		push ispalmsglen
		push ispalmsg
		call print
		add esp, 8
	.exit:

	push 0x0
	call exit

is_palindrome:
    push ebp
    mov ebp, esp
    
    %define n [arg(1)]

    ; m = 0;
    ; for (tmp = n; tmp; tmp >>= 1)
    ;     m = (m << 1) | (tmp & 1);
    ; return m == n;

    mov eax, 0 ; eax := m
    mov ebx, n ; ebx := tmp

    .next:
        cmp ebx, 0 ; if (tmp == 0) break;
        je .break

        shl eax, 1 ; m <<= 1
        mov edx, ebx
        and edx, 1 ; edx = (tmp & 1)
        or eax, edx ; m |= (tmp & 1)

        shr ebx, 1 ; tmp >>= 1
        jmp .next
    .break:
    
    cmp n, eax
    jne .not_pal

    .pal:
		mov eax, 1
	jmp .exit
	.not_pal:
		mov eax, 0
	.exit:

    %undef n

    mov esp, ebp
    pop ebp
    ret

; read_uint32 reads uint from stdin and returns it
read_uint32:
	push ebp
	mov ebp, esp
	sub esp, 4

	%define buf_ptr [local(1)]

	sub esp, BUFSIZE 
	mov buf_ptr, esp

	push dword BUFSIZE
	push dword buf_ptr
	call read
	add esp, 8

	push dword buf_ptr
	call stou
	add esp, 4

	%undef buf_ptr

	mov esp, ebp
	pop ebp
    ret

; stou takes a string containing uint32
; and returns parsed uint32 in eax.
; If not a number is given or overflow occurred,
; it terminates a program with a corresponding error.
stou:
	push ebp
	mov ebp, esp
	sub esp, 4

	%define result [local(1)]
	%define string [arg(1)]

	push esi
	push ebx
	push ecx
	push edx

	mov esi, string
	mov ecx, 10 ; base
	xor ebx, ebx

	mov result, dword 0

	; check sign
	mov al, [esi]
	inc esi
	cmp al, '-'
	je negative
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
		
		xor edx, edx
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

	; check if actually no digit was parsed
	mov ecx, string
	inc ecx
	cmp ecx, esi
	je bad_input

	mov eax, result

	pop edx
	pop ecx
	pop ebx
	pop esi

	%undef result
	%undef string

	mov esp, ebp
	pop ebp
	ret

; arg1 -- buf
; arg2 -- len
read:
	push ebp
	mov ebp, esp

	%define buf [arg(1)]
	%define len [arg(2)]

	push ebx
	push ecx
	push edx

	mov eax, SYS_READ
	mov ebx, STDIN
	mov ecx, buf
	mov edx, len
	int SYS_CALL

	pop edx
	pop ecx
	pop ebx
	
	%undef buf
	%undef len

	mov esp, ebp
	pop ebp
	ret

; arg2 -- str
; arg1 -- len
print:
	push ebp
	mov ebp, esp

	%define str [arg(1)]
	%define len [arg(2)]

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

	%undef str
	%undef len

	mov esp, ebp
	pop ebp
	ret

; error handlers

overflow:
	push ofmsglen
	push ofmsg
	call print
	add esp, 8

	push 0x1        ; overflow exitcode
	call exit

bad_input:
	push bimsglen
	push bimsg
	call print
	add esp, 8

	push 0x2        ; badinput exitcode
	call exit

negative:
	push negmsglen
	push negmsg
	call print
	add esp, 8

	push 0x2        ; badinput exitcode
	call exit

; arg1 -- exitcode
; 0 - ok
; 1 - overflow
; 2 - badinput
exit:
	push ebp
	mov ebp, esp

	%define exitcode [arg(1)]

	mov eax, SYS_EXIT
	mov ebx, exitcode
	int SYS_CALL

	%undef exitcode

	mov esp, ebp
	pop ebp
	ret