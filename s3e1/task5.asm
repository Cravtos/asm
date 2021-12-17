; task5:
; Вычислить степень к заданного числа а, не используя операцию умножения. 
; Отдельно рассмотреть случаи, когда к=0, а=0, а=1. а может быть отрицательным числом. 
; Отслеживать переполнение при каждом сложении. 
; При возникновении переполнения выдавать ошибку

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
    
    mathmsg db 'Math error (0 ** 0)', 0x0a
    mathmsglen equ ($ - mathmsg)
    
    usagemsg db 'Usage: ./pow number power', 0x0a,     \
                '   number - int32, power - uint32', 0x0a, \
                'Example ./pow 2 3', 0x0a
    usagemsglen equ ($ - usagemsg)

    new_line db 0x0A
    minus db '-'


section .text
    global _start

_start:
    %define argc [arg(0)]
    %define argv1 [arg(2)]
    %define argv2 [arg(3)]

    %define n [local(1)]
    %define pow [local(2)]
    %define result [local(3)]

    push ebp
    mov ebp, esp
    sub esp, 12

    cmp argc, dword 3
    jne usage

    push dword argv1   ; number
    call stoi
    add esp, 4
    mov n, eax

    push dword argv2   ; power
    call stou
    add esp, 4
    mov pow, eax
    
    push dword pow
    push dword n  
    call power     
    add esp, 8      
    
    mov result, eax

    push dword result
    call print_int32
    add esp, 4

    push dword 1
    push new_line
    call print
    add esp, 8
    
    push 0x0
    call exit

    %undef argc
    %undef argv1
    %undef argv2
    %undef n
    %undef pow
    %undef result

; stoi takes a string containing int32
; and returns parsed integer in eax.
; If not a number is given or overflow occurred,
; it terminates a program with a corresponding error.
stoi:
	%define result [local(1)]
	%define string [arg(1)]

	push ebp
	mov ebp, esp
	sub esp, 4

    push esi
    push ebx
    push edi

	mov esi, string
	mov ecx, 10 ; base
	xor ebx, ebx

	mov result, dword 0

	mov edi, 1 ; sign: 1 means positive, -1 means negative
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
		
        xor edx, edx
		mov eax, result
		imul ecx
		jo overflow
		
		sub bl, '0'
		
		sub eax, ebx
		jo overflow
		mov result, eax
	jmp .loop
	.break:

	cmp al, byte EOF
	je .ok
	cmp al, 0x0a ; '\n'
	je .ok
	cmp al, ' '
	je .ok
	jmp bad_input
	.ok:

	mov eax, result
	cmp edi, -1
	je .negative

    cmp eax, 0x80000000 ; there is no 2147483648
    je overflow

	neg eax
	.negative:

    pop edi
    pop ebx
    pop esi

	mov esp, ebp
	pop ebp

	%undef result
	%undef string
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

    push esi
    push ebx

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

	mov eax, result

    pop ebx
    pop esi

	mov esp, ebp
	pop ebp

	%undef result
	%undef string
	ret

; arg2 -- pow (uint32)
; arg1 -- n (int32)
power:
    %define n [arg(1)]
    %define pow [arg(2)]

    push ebp
    mov ebp, esp

    push ebx
    
    mov eax, 1
    mov ebx, n
    mov ecx, pow

    ; 0 ** 0 check
    cmp ebx, ecx
    jne .ok
    cmp ebx, 0
    je math_err
    .ok:

    .mult:  
        cmp ecx, 0
        je .exit

        push ecx ; in cdecl ecx is caller-saved

        push eax
        push ebx

        cmp eax, 0
        jge .positive

        call neg_s_sum_mul
        jmp .clean_stack
        
        .positive:
        call pos_s_sum_mul

        .clean_stack:
        add esp, 8

        pop ecx

        dec ecx
    jmp .mult

    .exit:

    pop ebx

    %undef n
    %undef pow

    pop ebp
    ret

; pos_s_sum_mul does multiplication by addition,
; assuming that second multiple is positive
; Takes two multiples (int32) as arugments.
pos_s_sum_mul:
    %define f [arg(1)]
    %define s [arg(2)]

    push ebp
    mov ebp, esp

    mov eax, f

    mov ecx, s
    cmp ecx, 0
    je .break
    
    dec ecx

    .loop_add:
        cmp ecx, 0
        je .break

        add eax, f
        jo overflow ; check for wrap around

        dec ecx
    jmp .loop_add
    .break:

    %undef f
    %undef s

    mov esp, ebp
    pop ebp
    ret

; neg_s_sum_mul does multiplication by addition,
; assuming that second multiple is negative
; Takes two multiples (int32) as arugments.
neg_s_sum_mul:
    %define f [arg(1)]
    %define s [arg(2)]

    push ebp
    mov ebp, esp

    mov eax, f

    mov ecx, 0
    mov edx, s
    
    dec ecx

    .loop_add:
        cmp ecx, s
        je .break

        add eax, f
        jo overflow

        dec ecx
    jmp .loop_add
    .break:
    
    ; neg eax
    cmp eax, 0x80000000 ; there is no 2147483648
    je overflow

    neg eax

    %undef f
    %undef s

    mov esp, ebp
    pop ebp
    ret

; arg1 -- integer to print
print_int32:
    %define number [arg(1)]
    %define buffer ebp-BUFSIZE

    push ebp
    mov ebp, esp
    sub esp, BUFSIZE

    push esi
    push edi

    mov eax, number
    cmp eax, 0             ; is number negative or positive?
    jnl .positive
    neg eax

    push eax

    push dword 0x1
    push minus
    call print
    add esp, 8

    pop eax

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

    %undef number
    %undef buffer

    pop edi
    pop esi
    
    mov esp, ebp
    pop ebp
    ret

; arg2 -- str
; arg1 -- len
print:
	%define str [arg(1)]
	%define len [arg(2)]

	push ebp
	mov ebp, esp

    push ebx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, str
	mov edx, len
	int SYS_CALL

    %undef str
	%undef len

    pop ebx

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

usage:
    push usagemsglen
    push usagemsg
    call print
    add esp, 8

    push 0x2        ; badinput exitcode
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

math_err:
    push mathmsglen
    push mathmsg
    call print
    add esp, 8

    push 0x3        ; matherr exitcode
    call exit

; arg1 -- exitcode
; 0 - ok
; 1 - overflow
; 2 - badinput
; 3 - matherr
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