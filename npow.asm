;
; Gets (n ** n) w/o using multiplication.
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
%define ENDL 0xA ; '\n'

%define BUFSIZE 32

section .data
    ofmsg db 'Overflow.', 10
    ofmsglen equ ($ - ofmsg)
    bimsg db 'Bad input (NaN).', 10
    bimsglen equ ($ - bimsg)

section .bss
    n resd 1
    buf resb BUFSIZE

section .text
    global _start

_start:

    call get_int    ; Reads int into eax ONLY USGN INT
    mov [n], eax
    
    ; push dword [n]  ;
    ; call npow       ; n ** n -> EAX
    ; add esp, 4      ;
    
    ; mov [n], eax    ; Result

    push dword [n]
    call print_int
    add esp, 4
    
    push 0x0
    call exit

; arg_0 -- n
npow:
    %define pn arg(1)
    push ebp
    mov ebp, esp

    xor eax, eax
    mov ebx, [pn]
    
    mov ecx, ebx         ; n times
    dec ecx
    .mult_cycle:
        push ecx
        dec ecx
        .sum_cycle:
            add eax, ebx
            jo overflow
        loop .sum_cycle
        mov ebx, eax
        pop ecx
    loop .mult_cycle
    
    %undef pn
    pop ebp
    ret
    
; EAX <- int
get_int:
    push ebp
    mov ebp, esp
    sub esp, 4

    push ebx
    push ecx
    mov ecx, 10 ; base
    xor ebx, ebx
    %define result [local(1)]

    mov result, dword 0
    .loop:
        call getchar
        
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
    cmp al, byte ENDL
    je .ok
    ; but what if first char was eof? catch it in a pow func as 0 ** 0
    jmp bad_input
    .ok:

    mov eax, result
    %define result
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

; arg1 -- number
print_int:
    push ebp
    mov ebp, esp
    %define number [arg(1)]
    pushad

    mov eax, number
    mov ecx, 10
    xor esi, esi    ; as len counter
    .itoc:  ; int to chars
        cmp eax, 0
        jle .break

        xor edx, edx
        div ecx     ; n //= 10;
        add dl, '0'
        mov [buf+esi], dl   ; buf[len] = (n % 10);

        inc esi     ; ++len
    jmp .itoc
    .break:
    
    push esi
    push buf
    call reverse
    add esp, 8

    mov eax, SYS_WRITE
    mov ebx, STDIN
    mov ecx, buf
    mov edx, esi
    int SYS_CALL
    
    popad
    %undef number
    pop ebp
    ret

; arg2 -- string len
; arg1 -- string
reverse:
    push ebp 
    mov ebp, esp

    %define len [ebp+12]
    %define string [ebp+8] 
   
    mov ecx, len ; len --> ecx
 
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
 
    mov esp, ebp
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