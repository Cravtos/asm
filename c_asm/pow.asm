%define arg(n) ebp+(4*n)+4
%define local(n) ebp-(4*n)

%define MATH_ERR 0x1
%define OVERFLOW_ERR 0x2
%define CALLBACK_ERR 0x3
%define BAD_ARGS 0x4

global power
section .text

; arg3 -- callback (function address)
; arg2 -- pow (unsigned)
; arg1 -- num (signed)
power:
    ; Give names to arguments
    %define num [arg(1)]
    %define pow [arg(2)]
    %define callback [arg(3)]

    ; Make stack frame
    push ebp
    mov ebp, esp

    ; Save used registers
    push ebx
    push ecx
    push edi
    
    mov eax, 1
    mov ebx, num
    mov ecx, pow
    mov edi, callback

    .mult:  
        cmp ecx, 0
        je .exit

        imul ebx
        jo .overflow
        dec ecx
    jmp .mult

    .exit:

    ; Call int process_result(int result)
    push eax
    call edi
    add esp, 4

    cmp eax, 0
    je .return

    ; Handle errors
.callback_err:
    mov eax, CALLBACK_ERR
    jmp .return

.overflow:
    mov eax, OVERFLOW_ERR
    jmp .return

    ; Give registers its saved values and return
.return:
    pop edi
    pop ecx
    pop ebx

    pop ebp
    %undef num
    %undef pow
    %undef callback
    ret