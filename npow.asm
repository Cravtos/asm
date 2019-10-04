;
; Gets (n ** n) w/o using multiplication.
;

section .data
    n dd 4

section .text
    global _start

_start:
    push dword [n]  ;
    call npow       ; n ** n -> EAX
    sub esp, 4      ;

    mov [n], eax    ; Result

    mov eax, 1      ;
    xor ebx, ebx    ; Terminate program
    int 0x80        ;


; arg_0 -- n
npow:
    push ebp
    mov ebp, esp

    xor eax, eax
    mov ebx, [ebp+8]
    
    mov ecx, ebx         ; n times
    dec ecx
.mult_cycle:
    push ecx
    dec ecx
    .sum_cycle:
        add eax, ebx
    loop .sum_cycle

    mov ebx, eax

    pop ecx
loop .mult_cycle
    
    pop ebp
    ret

; (n ** n) ==  (n * n) [n - 1 time] == {(n + n) [n - 1 times]} [n - 1 times] == (n + 1) [(n - 1) * (n - 1) times]
; e.g.: 27 == 3 ** 3 == ((3 * 3) * 3) == ((3 + 3 + 3 ...