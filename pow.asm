;
; Usage: ./pow number power
; 
; number - int, power - uint
; Example ./pow 2 3
; 
;

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
    ofmsg db 'Overflow', 10
    ofmsglen equ ($ - ofmsg)
    bimsg db 'Bad input (NaN)', 10
    bimsglen equ ($ - bimsg)
    mathmsg db 'Math error (0 ** 0)', 10
    mathmsglen equ ($ - mathmsg)
    usagemsg db 'Usage: ./pow number power', 0xA,     \
                '   number - int, power - uint', 0xA, \
                'Example ./pow 2 3', 0xA
    usagemsglen equ ($ - usagemsg)
    endl db 0xA ; \n
    minus db '-'

section .bss
    n resd 1
    pow resd 1
    result resd 1
    buf resb BUFSIZE

section .text
    global _start

_start:
    %define argc [arg(0)]
    %define argv1 [arg(1)]
    %define argv2 [arg(2)]
    %define argv3 [arg(3)]

    push ebp
    mov ebp, esp

    cmp argc, dword 3
    jne usage

    push dword argv2   ; number
    call stoi
    add esp, 4
    mov [n], eax

    push dword argv3   ; power
    call stoi
    add esp, 4
    mov [pow], eax
    
    push dword [pow]
    push dword [n]  
    call power      
    add esp, 8      
    
    mov [result], eax   

    push dword [result]
    call print_int
    add esp, 4

    push dword 0x1
    push endl
    call print
    add esp, 8
    
    push 0x0
    call exit

; EAX <- int
; arg1 -- string containing uint/int
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

    mov edi, 1
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
    cmp al, [endl]
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


; arg2 -- pow (unsigned)
; arg1 -- n (signed)
power:
    %define n [arg(1)]
    %define pow [arg(2)]
    push ebp
    mov ebp, esp

    push ebx
    push ecx
    
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

        imul ebx
        jo overflow
        dec ecx
    jmp .mult

    .exit:

    pop ecx
    pop ebx

    pop ebp
    %undef n
    %undef pow
    ret
    

; arg1 -- signed int
print_int:
    %define number [arg(1)]

    push ebp
    mov ebp, esp
    pushad

    mov eax, number
    cmp eax, 0      ; is number negative or positive?
    jnl .positive
    neg eax

    push 0x1
    push minus  ; print '-' if negative
    call print
    add esp, 8
    
    .positive:


    mov ecx, 10
    xor esi, esi    ; as len counter
    .itoc:  ; ints to symbols
        xor edx, edx
        div ecx     ; n //= 10;
        add dl, '0'
        mov [buf+esi], dl   ; buf[len] = (n % 10); 
                            ; buf contains reversed number 

        inc esi     ; ++len

        cmp eax, 0
        jle .break
    jmp .itoc
    .break:
    
    push esi
    push buf
    call reverse ; since buf contains reversed number
    add esp, 8

    push esi
    push buf
    call print
    add esp, 8
    
    popad
    pop ebp
    %undef number
    ret

; arg2 -- string len
; arg1 -- string
reverse:
    %define len [ebp+12]
    %define string [ebp+8] 

    push ebp 
    mov ebp, esp

    pushad
   
    mov ecx, len ; len --> ecx
    cmp ecx, 2
    jl .less2

    mov esi, string     ; address of first char
    mov edi, esi
    add edi, ecx        ; address of last char
    dec edi             ; ^
 
    shr ecx, 1          ; len /= 2
    
    .swap:
        mov al, [esi]
        mov bl, [edi]
        mov [esi], bl
        mov [edi], al
        inc esi
        dec edi
    loop .swap
    .less2:

    popad

    mov esp, ebp
    pop ebp
    %undef len
    %undef string
    ret

; arg2 -- str
; arg1 -- len
print:
	%define str [arg(1)]
	%define len [arg(2)]

	push ebp
	mov ebp, esp

    pushad

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, str
	mov edx, len
	int SYS_CALL

	popad

	pop ebp
	%undef str
	%undef len
	ret

; error handlers

overflow:
    push ofmsglen
    push ofmsg
    call print
    add esp, 8

    push 0x1 ; overflow exitcode
    call exit

usage:
    push usagemsglen
    push usagemsg
    call print
    add esp, 8

    push 0x2    ; bad input
    call exit

bad_input:
    push bimsglen
    push bimsg
    call print
    add esp, 8

    push 0x2 ; badinput exitcode
    call exit

math_err:
    push mathmsglen
    push mathmsg
    call print
    add esp, 8

    push 0x3 ; matherr exitcode
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

    pop ebp
    ret