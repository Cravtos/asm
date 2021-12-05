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

	dubmsg db 'Got dublicate elements', 0x0a
	dubmsglen equ ($ - dubmsg)

	negmsg db 'Got negative number while waiting for unsinged integer', 0x0a
	negmsglen equ ($ - negmsg)

	enterxnmsg db 'Enter amount of elemets in array X: ', 0x0a
	enterxnmsglen equ ($ - enterxnmsg)

	enterynmsg db 'Enter amount of elemets in array Y: ', 0x0a
	enterynmsglen equ ($ - enterynmsg)

	enterelmsg db 'Enter array elements, one per line, no repeating: ', 0x0a
	enterelmsglen equ ($ - enterelmsg)

	inmsg db 'X is in Y', 0x0a
	inmsglen equ ($ - inmsg)

	notinmsg db 'X is not in Y', 0x0a
	notinmsglen equ ($ - notinmsg)

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

	%define xn [local(1)]
	%define yn [local(2)]
	%define x_ptr [local(3)]
	%define y_ptr [local(4)]

	push enterxnmsglen
	push enterxnmsg
	call print
	add esp, 8

	; read amount of elements in array x
	call read_uint32
	mov xn, eax

	; allocate space on stack for array x
	lea esi, [eax * 4]
	sub esp, esi
	mov x_ptr, esp

	cmp xn, dword 0
	je .x_arr_emtpy
		push enterelmsglen
		push enterelmsg
		call print 
		add esp, 8

		; read elements of array x
		push dword xn
		push dword x_ptr
		call read_array
		add esp, 8
	.x_arr_emtpy:

	push enterynmsglen
	push enterynmsg
	call print
	add esp, 8

	; read amount of elements in array y
	call read_uint32
	mov yn, eax

	; allocate space on stack for array y
	lea esi, [eax * 4]
	sub esp, esi
	mov y_ptr, esp

	cmp yn, dword 0
	je .y_arr_emtpy
		push enterelmsglen
		push enterelmsg
		call print 
		add esp, 8

		; read elements of array y
		push dword yn
		push dword y_ptr
		call read_array
		add esp, 8
	.y_arr_emtpy:

	; check for dub elements in arrays
	push dword xn
	push dword x_ptr
	call check_dub
	add esp, 8

	cmp eax, 1
	je dublicate

	push dword yn
	push dword y_ptr
	call check_dub
	add esp, 8

	cmp eax, 1
	je dublicate

	; check if one array is in another
	push dword yn
	push dword xn
	push dword y_ptr
	push dword x_ptr
	call is_in

	cmp eax, 1
	je .is_in
	; .not_in:
		push notinmsglen
		push notinmsg
		call print
		add esp, 8
	jmp .exit
	.is_in:
		push inmsglen
		push inmsg
		call print
		add esp, 8
	.exit:

	%undef xn
	%undef yn
	%undef buf_ptr
	%undef x_ptr
	%undef y_ptr

	push 0x0
	call exit

; is_in checks if first array has all its elements in second
; if is in, return 1, if not, returns 0
is_in:
	push ebp
	mov ebp, esp

	%define f_arr [arg(1)]
	%define s_arr [arg(2)]
	%define fn [arg(3)]
	%define sn [arg(4)]

	push esi
	push edi
	push ecx
	push edx

	mov esi, fn
	cmp esi, sn
	ja .not_in

	cmp esi, 0
	je .in

	; for (i = 0; i < fn; i++)
	mov ecx, 0
	.pick_el:
		mov esi, f_arr
		mov esi, [esi + ecx * 4]

		; for (j = 0; j < len; j++)
		mov edx, 0
		.cmp_with_rest:
			mov edi, s_arr
			mov edi, [edi + edx * 4]

			cmp esi, edi
			je .found_in_second

			inc edx
			cmp edx, sn
			jne .cmp_with_rest
		; .not_found:
		jmp .not_in

		.found_in_second:

		inc ecx
		cmp ecx, fn
		jne .pick_el

	.in:
		mov eax, 1
	jmp .exit
	.not_in:
		mov eax, 0
	.exit:

	pop edx
	pop ecx
	pop edi
	pop esi

	%undef f_arr
	%undef s_arr
	%undef fn
	%undef sn

	mov esp, ebp
	pop ebp
	ret

; check_dub checks for dublicate elements in array
; returns 1 if there are dublicates, 0 otherwise
check_dub:
	push ebp
	mov ebp, esp

	%define arr_ptr [arg(1)]
	%define len [arg(2)]

	push ecx
	push esi
	push edi

	mov eax, 0

	; if len < 2: return
	cmp len, dword 1
	jbe .exit

	; for (i = 0; i < len - 1; i++)
	mov ecx, 0
	.pick_el:
		push ecx

		mov esi, arr_ptr
		mov esi, [esi + ecx * 4]

		; for (j = i + 1; j < len; j++)
		inc ecx
		.cmp_with_next_above:
			mov edi, arr_ptr
			mov edi, [edi + ecx * 4]

			cmp esi, edi
			je .found_dub

			inc ecx
			cmp ecx, len
			jne .cmp_with_next_above

		pop ecx
		inc ecx

		mov edi, len
		dec edi

		cmp ecx, edi
		jne .pick_el

	jmp .exit
	.found_dub:
		mov eax, 1
	.exit:

	pop edi
	pop esi
	pop ecx

	%undef arr_ptr
	%undef len

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

dublicate:
	push dubmsglen
	push dubmsg
	call print
	add esp, 8

	push 0x2        ; badinput exitcode
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