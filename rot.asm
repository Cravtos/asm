;
; Prints all cesar rotations of a string
;

section .data
	endl db 0xA
	
	SYS_CALL equ 0x80
	SYS_WRITE equ 0x4
	SYS_READ equ 0x3
	SYS_EXIT equ 0x1
	ABC_POWER equ 26
	STDOUT equ 0x1
	STDIN equ 0x0
	EOF equ 0x0
	BUFSIZE equ 200

section .bss
	rotated_text resb BUFSIZE
	plain_text resb BUFSIZE
	plain_text_len resd 1
  
section .text
	global _start
_start:

	.read_cycle:
		mov eax, SYS_READ
		mov ebx, STDIN
		mov ecx, plain_text
		mov edx, BUFSIZE
		int SYS_CALL

		cmp eax, 1		; only \n char
		je .exit

		dec eax
		mov [plain_text_len], eax

		mov ecx, ABC_POWER
		.rot26:

			push dword [plain_text_len]
			push ecx			; all rotations (because we're in cycle)
			push plain_text
			push rotated_text
			call rot
			add esp, 0x12
		
			push rotated_text
			push plain_text_len
			call print
			add esp, 0x8

		loop .rot26
	loop .read_cycle
	
	.exit:
		mov eax, SYS_EXIT	;
		xor ebx, ebx		; terminate
		int SYS_CALL		;
		
 
; arg_3 -- len
; arg_2 -- rotation
; arg_1 -- plaintext
; arg_0 -- place for rotated
rot:
	%define dst [ebp+8]
	%define src [ebp+12]
	%define rotation [ebp+16]
	%define len [ebp+20]


	push ebp
	mov ebp, esp
	sub esp, 0x4		; used for saving char

	pushad

	mov edi, dst
	mov esi, src
 
	mov ecx, len
	.cycle:
		push ecx
		lodsb

		push eax
		call detect_case	; EBX -> 'a' (lower) | 'A' (upper) | '0' (not a letter)
		add esp, 0x4

		cmp ebx, '0'
		jz .skip

		.shift:
			; eax = 'A' + (eax - 'A' + key) % 26
			sub eax, ebx
			add eax, rotation
			xor edx, edx		;
			mov ecx, ABC_POWER	; getting
			div ecx				; remainder
			mov eax, edx		;
			add eax, ebx
			
		.skip:
			stosb
			pop ecx
			loop .cycle
	
	.exit:

		%undef src
		%undef dst
		%undef rotation
		
		popad

		add esp, 0x4
		pop ebx
		ret

; arg_0 -- char
; Returns case indicator in EBX
; 'A' for upper
; 'a' for lower
; '0' for not-a-letter
detect_case:
	push ebp
	mov ebp, esp

	%define char [ebp+8]

	mov eax, char

	cmp al, 'A'
	jb .not_a_letter
	cmp al, 'z'
	ja .not_a_letter
	cmp al, 'Z'
	jbe .upper
	cmp al, 'a'
	jae .lower

	.not_a_letter:
		mov ebx, '0'
		jmp .exit
	.lower:
		mov ebx, 'a'
		jmp .exit
	.upper:
		mov ebx, 'A'
	.exit:
		%undef char
		pop ebp
		ret


; arg_1 -- str
; arg_0 -- len
print:
	push ebp
	mov ebp, esp

	%define str [ebp+12]
	%define len [ebp+8]

	push eax
	push ebx
	push ecx
	push edx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, str
	mov edx, len
	int SYS_CALL

	%undef str
	%undef len

	pop edx
	pop ecx
	pop ebx
	pop eax

	pop ebp
	ret