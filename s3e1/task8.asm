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

	enterelmsg db 'Enter row elements, one per line. Row number '
	enterelmsglen equ ($ - enterelmsg)

    enternmsg db 'Enter matrix order: '
    enternmsglen equ ($ - enternmsg)

	simmsg db 'Matrix is simmetric', 0x0a
	simmsglen equ ($ - simmsg)

	notsimmsg db 'Matrix is not simmetric', 0x0a
	notsimmsglen equ ($ - notsimmsg)

	new_line db 0x0A
	lbracket db '['
	rbracket db ']'
	space db ' '
	minus db '-'

section .text
	global _start

_start:
	push ebp
	mov ebp, esp
	sub esp, 16

	%define n [local(1)]
	%define mat_ptr [local(2)]

	push enternmsglen
	push enternmsg
	call print
	add esp, 8

	; read order of matrix
	call read_uint32
	mov n, eax

    cmp eax, 2
    jb .is_sim

	; allocate space on stack for first dimension of matrix
	lea esi, [eax * 4]
	sub esp, esi
	mov mat_ptr, esp

    ; allocate space on stack for second dimension of matrix
    mov edi, esi ; how much memory one matrix row takes
    mov ecx, 0
    .alloc_next:
        mov esi, mat_ptr
        lea esi, [esi + ecx * 4]

        ; allocate memory for one more matrix row
        sub esp, edi
        mov [esi], esp
        
        inc ecx
        cmp ecx, n
        jne .alloc_next

    ; read elements of matrix, row by row
    mov ecx, 0
    .read_mat:
        push enterelmsglen
        push enterelmsg
        call print 
        add esp, 8

        mov eax, ecx
        inc eax
        push eax
        call print_uint32
        add esp, 4

        push dword 1
        push new_line
        call print
        add esp, 8

        mov edi, mat_ptr
        mov edi, [edi + ecx * 4]

        ; read elements of array x
        push dword n
        push edi
        call read_array
        add esp, 8

        inc ecx
        cmp ecx, n
        jne .read_mat

    mov ecx, 0
    .print_mat:
        mov edi, mat_ptr
        mov edi, [edi + ecx * 4]

        ; read elements of array x
        push dword n
        push edi
        call print_array
        add esp, 8

        push dword 1
        push new_line
        call print
        add esp, 8

        inc ecx
        cmp ecx, n
        jne .print_mat

    ; check if one array is in another
	push dword n
	push dword mat_ptr
	call is_sim
    add esp, 8

	cmp eax, 1
	je .is_sim
	; .not_sim:
		push notsimmsglen
		push notsimmsg
		call print
		add esp, 8
	jmp .exit
	.is_sim:
		push simmsglen
		push simmsg
		call print
		add esp, 8
	.exit:

	%undef n
    %undef mat_ptr

	push 0x0
	call exit

is_sim:
    push ebp
    mov ebp, esp

    %define n [arg(2)]
    %define mat_p [arg(1)]

    ; for (i = 0; i < n - 1; i++)
    ;     for (j = i + 1; j < n; j++)

    mov ecx, 0 ; ecx holds a row index
    .next_row:
    
        mov edx, 0 ; edx holds a col index
        .next_col:

            mov esi, mat_p
            mov esi, [esi + ecx * 4] ; now esi holds a row
            mov esi, [esi + edx * 4] ; now esi holds an element

            mov edi, mat_p
            mov edi, [edi + edx * 4] ; now edi holds a symmetric rows
            mov edi, [edi + ecx * 4] ; now edi holds a symmetric element

            cmp esi, edi
            jne .not_sim

            inc edx
            cmp edx, n
            jne .next_col

        inc ecx
        cmp ecx, n
        jne .next_row

    .sim:
		mov eax, 1
	jmp .exit
	.not_sim:
		mov eax, 0
	.exit:

    %undef n
    %undef mat_p

    mov esp, ebp
    pop ebp
    ret

; read_uint32 reads uint from stdin and returns it
read_uint32:
	push ebp
	mov ebp, esp
	sub esp, 4

	%define buf_ptr [local(1)]

	sub esp, BUFSIZE 
	mov buf_ptr, esp

	push dword BUFSIZE
	push dword buf_ptr
	call read
	add esp, 8

	push dword buf_ptr
	call stou
	add esp, 4

	%undef buf_ptr

	mov esp, ebp
	pop ebp
	ret

; read_int32 reads int32 from stdin and returns it 
read_int32:
	push ebp
	mov ebp, esp
	sub esp, 4

	%define buf_ptr [local(1)]

	sub esp, BUFSIZE 
	mov buf_ptr, esp

	push dword BUFSIZE
	push dword buf_ptr
	call read
	add esp, 8

	push dword buf_ptr
	call stoi
	add esp, 4

	%undef buf_ptr

	mov esp, ebp
	pop ebp
	ret

; read_array takes array pointer and array length
; and fills it with numbers from stdin
read_array:
	push ebp
	mov ebp, esp

	%define arr_ptr [arg(1)]
	%define len [arg(2)]

	push esi
	push ecx
    push eax

	cmp len, dword 0
	je .break

	mov ecx, 0
	.read_next:
		call read_int32

		mov esi, arr_ptr
		lea esi, [esi + ecx * 4]
		mov [esi], eax

		inc ecx
		cmp ecx, len
		jne .read_next
	.break:

    pop eax
	pop ecx
	pop esi

	%undef arr_ptr
	%undef len

	mov esp, ebp
	pop ebp
	ret

; print_array prints elements of array
print_array:
	push ebp
	mov ebp, esp

	%define arr_ptr [arg(1)]
	%define len [arg(2)]

	push esi
	push ecx
	
	push dword 1
	push lbracket
	call print
	add esp, 8

	cmp len, dword 0
	je .break

	mov esi, arr_ptr
	mov ecx, len
	.print_next:
		mov eax, [esi]

		push eax
		call print_int32
		add esp, 4

		cmp ecx, 1
		je .skip_space
			push dword 1
			push space
			call print
			add esp, 8
		.skip_space:

		add esi, 4
		loop .print_next
	.break:

	push dword 1
	push rbracket
	call print
	add esp, 8

	pop ecx
	pop esi

	%undef arr_ptr
	%undef len

	mov esp, ebp
	pop ebp
	ret

; stoi takes a string containing int32
; and returns parsed integer in eax.
; If not a number is given or overflow occurred,
; it terminates a program with a corresponding error.
stoi:
	push ebp
	mov ebp, esp
	sub esp, 4

	%define result [local(1)]
	%define string [arg(1)]

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

	%undef result
	%undef string

	mov esp, ebp
	pop ebp
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
	push edx

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

	pop edx
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
	push ecx
	push edx

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

	pop edx
	pop ecx
	pop edi
	pop esi

	%undef number
	%undef buf_ptr
	
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
	push edx

	mov eax, SYS_READ
	mov ebx, STDIN
	mov ecx, buf
	mov edx, len
	int SYS_CALL

	pop edx
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
	push edx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, str
	mov edx, len
	int SYS_CALL

	pop edx
	pop ecx
	pop ebx

	%undef str
	%undef len

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