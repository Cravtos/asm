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
    ofmsg db 'Overflow', 0x0a
    ofmsglen equ ($ - ofmsg)

    bimsg db 'Bad input (NaN)', 0x0a
    bimsglen equ ($ - bimsg)

    negmsg db 'Got negative number while waiting for unsinged integer', 0x0a
    negmsglen equ ($ - negmsg)

    enternmsg db 'Enter amount of coordinates: ', 0x0a
    enternmsglen equ ($ - enternmsg)

    entercmsg db 'Enter coordinates in form "x,y" (without quotes)', 0x0a, \
                'One coordinate per line: ', 0x0a
    entercmsglen equ ($ - entercmsg)

    finqrtmsg db 'st quarter has '
    finqrtmsglen equ ($ - finqrtmsg)

    sinqrtmsg db ' points', 0x0a
    sinqrtmsglen equ ($ - sinqrtmsg)

    new_line db 0x0A
    minus db '-'

section .text
    global _start

_start:
    push ebp
    mov ebp, esp
    sub esp, 20

    %define n [local(1)]
    %define buf_ptr [local(2)]
    %define x_ptr [local(3)]
    %define y_ptr [local(4)]
    %define count_ptr [local(5)]

    ; create buffer for reading lines
    sub esp, BUFSIZE 
    mov buf_ptr, esp

    ; create array for counting amount of points in each quarter
    sub esp, 16
    mov count_ptr, esp

    ; init it with zero values
    mov edi, count_ptr
    mov ecx, 4
    .zero_count_arr:
        mov dword [edi], 0
        add edi, 4
        loop .zero_count_arr

    push enternmsglen
    push enternmsg
    call print
    add esp, 8

    push dword BUFSIZE
    push dword buf_ptr
    call read
    add esp, 8

    push dword buf_ptr
    call stou
    add esp, 4

    mov n, eax

    cmp eax, 0
    je .no_points

    ; allocating memory and using arrays can be avoided at all in this case,
    ; but it is here for educational purposes

    ; memory could also be allocated using mmap

    lea esi, [eax * 4] ; amount of bytes for memory holding an array with coordinates
    sub esp, esi
    mov x_ptr, esp

    sub esp, esi
    mov y_ptr, esp

    push dword 1
    push new_line
    call print
    add esp, 8

    push entercmsglen
    push entercmsg
    call print
    add esp, 8

    mov ecx, 0
    .read_cords:
        push dword BUFSIZE
        push dword buf_ptr
        call read
        add esp, 8

        push dword buf_ptr
        call stoi
        add esp, 4

        mov esi, x_ptr
        mov [esi + ecx*4], eax

        push dword BUFSIZE
        push dword buf_ptr
        call find_comma
        add esp, 8

        mov esi, buf_ptr
        lea esi, [esi + eax + 1]
        push esi
        call stoi
        add esp, 4

        mov esi, y_ptr
        mov [esi + ecx*4], eax

        inc ecx
        cmp ecx, n
        jne .read_cords

    mov ecx, 0
    .count_points:
        mov esi, x_ptr
        mov ebx, [esi + 4*ecx]

        mov esi, y_ptr
        mov edx, [esi + 4*ecx]

        push edx
        push ebx
        call det_qrt
        add esp, 8

        cmp eax, -1
        je .skip

        dec eax
        mov esi, count_ptr
        lea esi, [esi + 4*eax]
        add dword [esi], 1

        .skip:
        inc ecx
        cmp ecx, n
        jne .count_points

    .no_points:

    push dword 1
    push new_line
    call print
    add esp, 8

    mov ecx, 0
    .print_amount:
        mov esi, count_ptr
        lea esi, [esi + ecx*4]

        lea edi, [ecx+1]
        push dword edi
        call print_uint32
        add esp, 4

        push finqrtmsglen
        push finqrtmsg
        call print
        add esp, 8

        push dword [esi]
        call print_uint32
        add esp, 4

        push sinqrtmsglen
        push sinqrtmsg
        call print
        add esp, 8

        inc ecx
        cmp ecx, 4
        jne .print_amount
    
    %undef n
    %undef buf_ptr
    %undef x_ptr
    %undef y_ptr
    %undef count_ptr

    push 0x0
    call exit

; det_qrt determines in which quarter point is locatated
; -1 is returned if point is laying on axis
det_qrt:
    push ebp
    mov ebp, esp

    push ebx
    push ecx

    %define x [arg(1)]
    %define y [arg(2)]

    mov ebx, x
    mov ecx, y

    mov eax, -1

    cmp ebx, 0
    je .break
    cmp ecx, 0
    je .break

    cmp ebx, 0
    jg .pos_x1

    ; here x is negative

    cmp ecx, 0
    jg .pos_y1

    ; here x is negative and y is negative

    mov eax, 3
    jmp .break

    .pos_y1:
    ; here x is negative and y is positive
    mov eax, 2
    jmp .break

    .pos_x1:
    cmp ecx, 0
    jg .pos_y2

    ; here x is poitive and y is negative
    mov eax, 4
    jmp .break

    .pos_y2:
    ; here x and y are positive
    mov eax, 1
    
    .break:

    %undef x
    %undef y

    pop ecx
    pop ebx

    mov esp, ebp
    pop ebp
    ret

; find_comma takes a string and returns an index of first comma in it
; if not a +/- or digit met, bad input error is thrown
find_comma:
    push ebp
    mov ebp, esp

    %define str [arg(1)]
    %define len [arg(2)]

    push esi
    push ecx

    mov esi, str
    mov ecx, len
    mov eax, 0

    .next:
        cmp byte [esi], ','
        je .break

        inc eax
        inc esi

        cmp eax, len
        je bad_input
        
        jmp .next
    .break:

    pop ecx
    pop esi

    %undef str
    %undef len

    mov esp, ebp
    pop ebp
    ret


; stoi takes a string containing int32
; and returns parsed integer in eax.
; If not a number is given or overflow occurred,
; it terminates a program with a corresponding error.
stoi:
	%define result [local(1)]
	%define string [arg(1)]

	push ebp
	mov ebp, esp
	sub esp, 4

    push esi
    push ebx
    push edi
    push ecx

	mov esi, string
	mov ecx, 10 ; base
	xor ebx, ebx

	mov result, dword 0

	mov edi, 1 ; sign: 1 means positive, -1 means negative
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
		
        xor edx, edx
		mov eax, result
		imul ecx
		jo overflow
		
		sub bl, '0'
		
		sub eax, ebx
		jo overflow
		mov result, eax
	jmp .loop
	.break:

	cmp al, byte EOF
	je .ok
	cmp al, 0x0a ; '\n'
	je .ok
	cmp al, ' '
	je .ok
    cmp al, ','
	je .ok
	jmp bad_input
	.ok:

    ; check if actually no digit was parsed
    mov ecx, string
    inc ecx
    cmp ecx, esi
    je bad_input

	mov eax, result
	cmp edi, -1
	je .negative

    cmp eax, 0x80000000 ; there is no 2147483648
    je overflow

	neg eax
	.negative:

    pop ecx
    pop edi
    pop ebx
    pop esi

	mov esp, ebp
	pop ebp

	%undef result
	%undef string
	ret

; stou takes a string containing uint32
; and returns parsed uint32 in eax.
; If not a number is given or overflow occurred,
; it terminates a program with a corresponding error.
stou:
	push ebp
	mov ebp, esp
	sub esp, 4

    %define result [local(1)]
	%define string [arg(1)]

    push esi
    push ebx
    push ecx

	mov esi, string
	mov ecx, 10 ; base
	xor ebx, ebx

	mov result, dword 0

	; check sign
	mov al, [esi]
	inc esi
    cmp al, '-'
    je negative
	cmp al, '+'
	jne .check_input

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
		
        xor edx, edx
		mov eax, result
		mul ecx
		jo overflow
		
		sub bl, '0'
		
		add eax, ebx
		jc overflow
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

    ; check if actually no digit was parsed
    mov ecx, string
    inc ecx
    cmp ecx, esi
    je bad_input

	mov eax, result

    pop ecx
    pop ebx
    pop esi

    %undef result
	%undef string

	mov esp, ebp
	pop ebp
	ret

; arg1 -- integer to print
print_int32:
    push ebp
    mov ebp, esp
    sub esp, 4

    %define number [arg(1)]
    %define buf_ptr [local(1)]

    sub esp, BUFSIZE
    mov buf_ptr, esp
    
    push esi
    push edi

    mov eax, number
    cmp eax, 0             ; is number negative or positive?
    jnl .positive
    neg eax

    push eax

    push dword 0x1
    push minus
    call print
    add esp, 8

    pop eax

    .positive:

    xor esi, esi           ; as len counter
    mov ecx, 10
    .itoc:                 ; ints to symbols
        xor edx, edx
        div ecx            ; n //= 10;
        add dl, '0'
        mov edi, buf_ptr
        lea edi, [edi+BUFSIZE-1]
        sub edi, esi
        mov [edi], dl

        inc esi            ; ++len

        cmp eax, 0
        jle .break
    jmp .itoc
    .break:

    mov edi, buf_ptr
    lea edi, [edi+BUFSIZE]
    sub edi, esi
    
    push esi
    push edi
    call print
    add esp, 8

    %undef number
    %undef buf_ptr

    pop edi
    pop esi
    
    mov esp, ebp
    pop ebp
    ret

; Takes uint32 and prints it
print_uint32:
	push ebp
	mov ebp, esp
    sub esp, 4

    %define num [arg(1)]
	%define buf_ptr [local(1)]

	sub esp, BUFSIZE
    mov buf_ptr, esp

	push eax
	push ecx
	push edx
	push esi
	push edi

	mov eax, num
	xor esi, esi           ; as len counter
	mov ecx, 10

	.handle_lsp:           ; integers to symbols
        xor edx, edx
		div ecx            ; n //= 10;
		add dl, '0'
        mov edi, buf_ptr
		lea edi, [edi+BUFSIZE-1]
		sub edi, esi
		mov [edi], dl

		inc esi            ; ++len

        cmp eax, 0
		je .break
	jmp .handle_lsp
	.break:

    mov edi, buf_ptr
	lea edi, [edi+BUFSIZE]
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

	%undef num
    %undef buffer

    mov esp, ebp
	pop ebp
	ret

; arg1 -- buf
; arg2 -- len
read:
    push ebp
    mov ebp, esp

    %define buf [arg(1)]
    %define len [arg(2)]

    push ebx
    push ecx

    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, buf
    mov edx, len
    int SYS_CALL

    pop ecx
    pop ebx
    
    %undef buf
    %undef len

    mov esp, ebp
    pop ebp
    ret

; arg2 -- str
; arg1 -- len
print:
	push ebp
	mov ebp, esp

    %define str [arg(1)]
	%define len [arg(2)]

    push ebx
    push ecx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, str
	mov edx, len
	int SYS_CALL

    %undef str
	%undef len

    pop ecx
    pop ebx

    mov esp, ebp
	pop ebp
	ret

; error handlers

overflow:
    push ofmsglen
    push ofmsg
    call print
    add esp, 8

    push 0x1        ; overflow exitcode
    call exit

bad_input:
    push bimsglen
    push bimsg
    call print
    add esp, 8

    push 0x2        ; badinput exitcode
    call exit

negative:
    push negmsglen
    push negmsg
    call print
    add esp, 8

    push 0x2        ; badinput exitcode
    call exit

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

    %undef exitcode

    mov esp, ebp
    pop ebp
    ret