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
%define BUFSIZE 8

section .data
    ofmsg db 'Overflow.', 10
    ofmsglen equ ($ - ofmsg)
    bimsg db 'Bad input (NaN)', 10
    bimsglen equ ($ - bimsg)

section .bss
    n resd 1
    buff resb BUFSIZE

section .text
    global _start

_start:
    call get_int    ; Reads int into eax
    mov [n], eax
    
    push dword [n]  ;
    call npow       ; n ** n -> EAX
    add esp, 4      ;
    mov [n], eax    ; Result

    push n
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

;   Using C:
;
;   // c = getchar();
;   // if (c == EOF) error();
;   // if (c == '-' || c == '+')
;   res = 0;
;   while (c = getchar() == is_digit(c)) {
;       res *= 10;
;       check_overflow();
;       res += c - '0';
;       check_overflow();
;   }
;   if (c != EOF || c != '\n') bad_input();
;   return res
;
; EAX <- int
get_int:
    push ebp
    mov ebp, esi
    sub esp, 4

    push ebx
    %define result [local(1)]

    mov result, 0
    .loop;
        call getchar
        ; isdigit() ? nop : break

        mov bl, al
        
        mov eax, result
        mul 10
        jo overflow
        
        sub bl, '0'
        
        add eax, bl
        jo overflow
        mov result, eax
    jmp .loop
    .break:

    cmp al, EOF 
    je .ok
    cmp al, '\n'
    je .ok
    ; 
    jmp bad_input

    mov eax, result
    %define result
    pop ebx
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

    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, buff
    mov edx, 1
    int SYS_CALL

    mov al, [buff]

    pop ebp
    ret

; arg1 -- exitcode
; 0 - ok
; 1 - overflow
; 2 - badinput
exit:
    %define exitcode [arg(1)]
    mov eax, SYS_EXIT
    mov ebx, exitcode
    int SYS_CALL