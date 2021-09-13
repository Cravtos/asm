; task 1:

; Дано трехзначное число. 
; В нем зачеркнули первую слева цифру и приписали ее справа. 
; Вывести полученное число.

; 123 -> 231

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
    ofmsg db 'Overflow', 10
    ofmsglen equ ($ - ofmsg)

    bimsg db 'Bad input', 10
    bimsglen equ ($ - bimsg)
    
    usagemsg db 'Usage: ./task1 3-digit-number', 0xA, \
                'Example ./task1 123', 0xA
    usagemsglen equ ($ - usagemsg)


section .text
    global _start
    
_start:
    %define argc [arg(0)]
    %define argv1 [arg(2)]
    %define num [local(1)]

    ; create stack frame
    push ebp 
    mov ebp, esp
    sub esp, 4 ; alocate space on stack for local vars

    ; check if 1 argument is passed
    cmp argc, dword 2
    jne usage

    ; check if passed argument is 3 digit number
    push dword argv1
    call check_input
    add esp, 4

    ; convert string containing number to integer
    push dword argv1
    call stoi
    add esp, 4
    mov num, eax

    ; move front digit to back
    push dword num
    call front2end
    add esp, 4
    mov num, eax

    ; print result
    push dword num
    call print_int
    add esp, 4

    ; also print new line
    push dword 0xA
    call putchar
    add esp, 4

    ; exit with code 0x0
    push 0x0
    call exit

    %undef argc
    %undef argv1
    %undef num

; check_input checks if string contain 3 digit number
; if it is not - bad input error occurs
check_input:
    %define num [arg(1)]

    push ebp
    mov ebp, esp

    mov ecx, 0 ; digit counter

    mov esi, num
    
    .check_digit:
        mov al, [esi]
        ; al == digit?
        cmp al, '0'
        jb .not_digit
        cmp al, '9'
        ja .not_digit

        inc ecx ; plus 1 digit
        inc esi
        jmp .check_digit

    .not_digit:
    cmp al, byte EOF
    je .ok
    jmp bad_input
    .ok:

    cmp ecx, 3
    jne bad_input

    %undef num
    pop ebp
    ret


; front2end takes first digit of number and makes it last
front2end:
    %define num [arg(1)]
    %define rem [local(1)]

    push ebp
    mov ebp, esp
    sub esp, 4

    push ebx
    push edx

    ; dividend
    mov eax, num ; e.g.: eax = 123
    xor edx, edx

    ; divisor
    mov ebx, 100
    div ebx ; eax = 1

    ; save quotinent
    mov rem, eax

    mov eax, edx ; eax = 23
    mov ebx, 10 
    mul ebx ; eax = 230
    add eax, rem ; eax = 231

    pop edx
    pop ebx

    %undef num
    %undef rem

    mov esp, ebp
    pop ebp
    ret

; stoi takes a string containing uint/int
; and returns parsed int in eax.
; If not a number given or overflow occured,
; it terminates a program with corresponding error.
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

    push dword '-'
    call putchar
    add esp, 4

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

; putchar prints one char
; arg1 -- char
putchar:
    %define char [arg(1)]
	push ebp
	mov ebp, esp

    push eax
    push ebx
    push ecx
    push edx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	lea ecx, char
	mov edx, 0x1
	int SYS_CALL

	pop edx
    pop ecx
    pop ebx
    pop eax

	pop ebp
	%undef char
	ret

; == 
; error handlers
; ==

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