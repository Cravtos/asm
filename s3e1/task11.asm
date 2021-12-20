; task11:
; Вычислить значение функции ln(1 - x) = -(x + x^2/2 + x^3/3 + x^4/4 + …) в точке x = 0.

section .data
    fmt_read db '%lf', 0
    fmt_result db 'ln(1-x) = %lf', 0x0a, 0
    fmt_bad_input db 'Bad input', 0x0a, 0
    one dq 1.0
    zero dq 0.0

section .text
	global _start
    
    extern printf
    extern scanf
    extern exit

_start:
	push ebp
	mov ebp, esp
    sub esp, 8

    push esp
    push fmt_read
    call scanf
    add esp, 8

    ; check if scanf parsed number correctly
    cmp eax, 1 
    jne bad_input

    ; calculate ln(1-x)
    fld qword [esp]
    call lnmx

    ; print result
    fstp qword [esp]

    push dword [esp + 4]
    push dword [esp]
    push fmt_result
    call printf
    add esp, 12

	push 0x0
	call exit
bad_input:
    push fmt_bad_input
    call printf
    add esp, 4

    push 0x1
    call exit

; calculates ln(1-x) using Taylor Series
; ln(1-x) = -(x + x^2/2 + x^3/3 + ...)
; x is passed in st0
lnmx:
    push ebp
    mov ebp, esp

    ; put 1 on stack
    fld qword [one] ; stack: 1, x
    fld st1       ; stack: x, 1, x
    fld st0       ; stack: x, x, 1, x

    mov ecx, 7
    .round:
        ; stack: x^(i), x, i, x + ... + x^(i)/(i)
        fmul st1  ; stack: x^(i+1), x, i, x + ... + x^(i)/(i)
        fld qword [one] ; stack: 1, x^(i+1), x, i, x + ... + x^(i)/(i)
        faddp st3 ; stack: x^(i+1), x, (i+1), x + ... + x^(i)/(i)
        fld st0 ; stack: x^(i+1), x^(i+1), x, (i+1), x + ... + x^(i)/(i)
        fdiv st3 ; stack: x^(i+1)/(i+1), x^(i+1), x, (i+1), x + ... + x^(i)/(i)
        fadd st0, st4 ; stack: x + ... + x^(i)/(i) + x^(i+1)/(i+1), x^(i+1), x, (i+1), x + ... + x^(i)/(i)
        fxch st4 ; stack: x + ... + x^(i)/(i), x^(i+1), x, (i+1), x + ... + x^(i)/(i) + x^(i+1)/(i+1)
        fstp st0 ; stack: x^(i+1), x, (i+1), x + ... + x^(i)/(i) + x^(i+1)/(i+1)
    loop .round

    ; clear stack
    fstp st0 ; stack: x, (n+1), x + ... + x^(n)/(n)
    fstp st0 ; stack: (n+1), x + ... + x^(n)/(n)
    fstp st0 ; stack: x + ... + x^(n)/(n)

    ; neg result
    fld qword [zero]
    fxch st1
    fsubp

    mov esp, ebp
    pop ebp
    ret
