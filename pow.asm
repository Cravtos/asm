;
; Gets (n ** n) w/o using multiplication.
;

; TODO:
;   1) WORKING WITH EAX:EDX 

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
    endl db 0xA ; \n
    minus db '-'

section .bss
    n resd 1
    pow resd 1
    result resd 2   
    buf resb BUFSIZE

section .text
    global _start

_start:
    call get_int    ; Reads int into eax ONLY USGN INT
    mov [n], eax

    call get_int
    mov [pow], eax
    
    push dword [pow]
    push dword [n]  ;
    call power       ; n ** n -> EAX
    add esp, 8      ;
    
    mov [result], eax    ; Result
    mov [result+4], edx

    push dword [result]
    call print_int
    add esp, 4

    push dword 0x1
    push endl
    call print
    add esp, 8
    
    push 0x0
    call exit


; arg2 -- pow (unsigned)
; arg1 -- n (signed)
power:
    push ebp
    mov ebp, esp

    push ebx
    push ecx

    %define n [arg(1)]
    %define pow [arg(2)]
    
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
    %undef n
    %undef pow

    pop ecx
    pop ebx

    pop ebp
    ret
    
; EAX <- int
get_int:
    push ebp
    mov ebp, esp
    sub esp, 4

    push ebx
    push ecx
    push edx
    push esi


    mov ecx, 10 ; base
    xor ebx, ebx
    %define result [local(1)]

    mov result, dword 0

    mov esi, 1
    call getchar
    cmp al, '+'
    je .loop
    cmp al, '-'
    jne .check_input
    neg esi

    .loop:
        call getchar

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
    cmp esi, -0x1
    jne .positive
    neg eax
    .positive:
    %undef result

    pop esi
    pop edx
    pop ecx
    pop ebx

    mov esp, ebp
    pop ebp
    ret

overflow:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, ofmsg
    mov edx, ofmsglen
    int SYS_CALL

    push 0x1 ; overflow exitcode
    call exit

bad_input:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, bimsg
    mov edx, bimsglen
    int SYS_CALL

    push 0x2 ; badinput exitcode
    call exit

math_err:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, mathmsg
    mov edx, mathmsglen
    int SYS_CALL

    push 0x3 ; matherr exitcode
    call exit

; AL <- char
getchar:
    push ebp
    mov ebp, esp

    pushad

    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, buf
    mov edx, 0x1    ; read one char
    int SYS_CALL

    popad

    mov al, [buf]

    pop ebp
    ret

; arg1 -- signed int
print_int:
    push ebp
    mov ebp, esp
    %define number [arg(1)]
    pushad

    mov eax, number
    cmp eax, 0
    jnl .positive
    neg eax
    push 0x1
    push minus
    call print
    add esp, 8
    .positive:


    mov ecx, 10
    xor esi, esi    ; as len counter
    .itoc:  ; int to chars
        xor edx, edx
        div ecx     ; n //= 10;
        add dl, '0'
        mov [buf+esi], dl   ; buf[len] = (n % 10);

        inc esi     ; ++len

        cmp eax, 0
        jle .break
    jmp .itoc
    .break:
    
    push esi
    push buf
    call reverse
    add esp, 8

    push esi
    push buf
    call print
    add esp, 8
    
    popad
    %undef number
    pop ebp
    ret

; arg2 -- string len
; arg1 -- string
reverse:
    push ebp 
    mov ebp, esp

    pushad 

    %define len [ebp+12]
    %define string [ebp+8] 
   
    mov ecx, len ; len --> ecx
    cmp ecx, 2
    jl .less2

    mov esi, string     ; address of first char
    mov edi, esi
    add edi, ecx        ; address of last char
    dec edi             ;
 
    shr ecx, 1
    
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
    
    %undef len
    %undef string

    mov esp, ebp
    pop ebp
    ret

; arg2 -- str
; arg1 -- len
print:
	push ebp
	mov ebp, esp


	%define str arg(1)
	%define len arg(2)

	push eax
	push ebx
	push ecx
	push edx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, [str]
	mov edx, [len]
	int SYS_CALL

	%undef str
	%undef len

	pop edx
	pop ecx
	pop ebx
	pop eax

	pop ebp
	ret


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

    pop ebp
    ret