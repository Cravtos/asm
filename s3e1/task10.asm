; task10:
; Построить таблицу значений функции y = (2.434*x^2)/(3-x^(1/3))
; при заданных значениях аргумента x в отрезке [1,2] и шагом h=0.05

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
    tablerowfmt db 'x = %lf, y(x) = %lf', 0x0a, 0

    const dq 2.434
    step dq 0.05

    three dq 3.0
    twoe dq 2.001 ; two + epsilon (used for comparing)
    two dq 2.0
    one dq 1.0

section .text
	global _start
    extern printf
    extern exit

_start:
	push ebp
	mov ebp, esp

    fld qword [one]

    .calc:
        ; calculate y(x). value is returned in st0
        sub esp, 8
        fst qword [esp] ; here x is passed through stack, but it also could be passed as is in st0
        call calc
        add esp, 8

        ; print result
        sub esp, 8
        fst qword [esp]
        fstp st0 ; remove returned value from stack
        sub esp, 8
        fst qword [esp]
        push tablerowfmt
        call printf
        add esp, 20

        ; add step
        fld qword [step]
        faddp

        ; compare current value with number two and set CPU flags
        fld qword [twoe]
        fcomip
        fwait
        ja .calc

	push 0x0
	call exit

; calculates y(x) = (2.434*x^2)/(3-x^(1/3))
calc:
    push ebp
    mov ebp, esp
    sub esp, 0

    %define x [ebp+4+4]

    ; load value of x twice
    fld qword x
    fld qword x

    ; calculate x^2
    fmulp 
    
    ; calculate 2.434 * x^2
    fld qword [const]
    fmulp

    ; load number 3 and x
    fld qword [three]
    fld qword x

    ; calculate x^(1/3)
    ; put x to stack as argument
    ; returns result in st0
    sub esp, 8
    fstp qword [esp]
    call calc_cube_root
    add esp, 8

    ; calculate 3 - x^(1/3)
    fsubp

    ; calculate y(x) = (2.434*x^2)/(3-x^(1/3))
    fdivp

    %undef x

    mov esp, ebp
    pop ebp
    ret

; calculate cube root of a number using Newtons method
; a - number to find root to
; x_(k+1) = (2/3)*x_k + (a/3)/((x_k)^2)
calc_cube_root:
    push ebp
    mov ebp, esp

    %define a [ebp+4+4]

    ; calculate a/3
    fld qword a
    fld qword [three]
    fdivp 

    ; calculate 2/3
    fld qword [two]
    fld qword [three]
    fdivp

    fld qword a ; stack: x0, 2/3, x0/3

    mov ecx, 7 ; 7 rounds of approximation
    .appr:
        fld st0     ; stack: xk, xk, 2/3, a/3
        fmul st0    ; stack: xk^2, x_k, 2/3, a/3 
        fdivr st3   ; stack: (a/3)/xk^2, xk, 2/3, a/3
        fxch st1    ; stack: xk, (a/3)/xk^2, 2/3, a/3
        fmul st2    ; stack: xk * 2/3, (a/3)/xk^2, 2/3, a/3
        faddp       ; stack: xk * 2/3 + (a/3)/xk^2, 2/3, a/3
        loop .appr

    ; save calculated root and clean stack
    fxch st0, st2
    fstp st0
    fstp st0

    %undef a

    mov esp, ebp
    pop ebp
    ret