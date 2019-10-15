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
%define BUFSIZE 15

section .data
    ofmsg db 'Overflow.', 10
    ofmsglen equ ($ - ofmsg)

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

    mov eax, SYS_EXIT
    mov ebx, 0
    int SYS_CALL


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

overflow:
    mov eax, SYS_WRITE
    mov ebx, STDIN
    mov ecx, ofmsg
    mov edx, ofmsglen
    int SYS_CALL

    mov eax, SYS_EXIT
    mov ebx, 1
    int SYS_CALL

; arg1 -- dst
get_int:
    %define dst arg(1)
    push ebp
    mov ebp, esi

    mov eax, 0
    

    %undef dst
    pop ebp
    ret