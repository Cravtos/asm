;
; Prints all cesar rotations of a string
;

%define arg(n) ebp+(4*n)+4
%define local(n) ebp-(4*n)

; oneline call macro
%macro pcall 1-*
	%rep %0 - 1
		%rotate -1
			push dword %1
	%endrep
	%rotate -1
		call %1
		add esp, (%0 - 1) * 4
%endmacro

%define SYS_CALL 0x80
%define SYS_WRITE 0x4
%define SYS_READ 0x3
%define SYS_EXIT 0x1

%define STDOUT 0x1
%define STDIN 0x0

%define EOF 0x0

%define ABC_POWER 26
%define BUFSIZE 200


section .data
	endl db 0xA  ; '\n'

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

			; push dword [plain_text_len]
			; push ecx 	;(key)
			; push plain_text
			; push rotated_text
			; call rot
			; add esp, 0x12

			pcall rot, rotated_text, plain_text, ecx, [plain_text_len]

			; push rotated_text
			; push plain_text_len
			; call print
			; add esp, 0x8

			pcall print, plain_text_len, rotated_text

		loop .rot26

		xor eax, eax
		mov edi, plain_text
		mov ecx, BUFSIZE
		rep stosb 				; Clears buffer
		mov edi, rotated_text
		mov ecx, BUFSIZE
		rep stosb

	loop .read_cycle
	
	.exit:
		mov eax, SYS_EXIT	;
		xor ebx, ebx		; terminate
		int SYS_CALL		;
		
 
; arg4 -- len
; arg3 -- rotation
; arg2 -- plaintext
; arg1 -- place for rotated text
rot:
	%define dst arg(1)
	%define src arg(2)
	%define rotation arg(3)
	%define len arg(4)

	push ebp
	mov ebp, esp
	sub esp, 0x4		; used for saving char

	pushad

	mov edi, [dst]
	mov esi, [src]
 
	mov ecx, [len]
	.cycle:
		push ecx
		lodsb

		; push eax
		; call detect_case	; EBX -> 'a' (lower) | 'A' (upper) | '0' (not a letter)
		; add esp, 0x4

		pcall detect_case, eax

		cmp ebx, '0'
		jz .skip

		.shift:
			; eax = 'A' + (eax - 'A' + key) % 26
			sub eax, ebx
			add eax, [rotation]
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
		%undef len
		
		popad

		add esp, 0x4
		pop ebx
		ret

; arg1 -- char
; Returns case indicator in EBX
; 'A' for upper
; 'a' for lower
; '0' for not-a-letter
detect_case:
	push ebp
	mov ebp, esp

	%define char arg(1)

	mov eax, [char]

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


; arg2 -- str
; arg1 -- len
print:
	push ebp
	mov ebp, esp

	%define str arg(2)
	%define len arg(1)

	push eax
	push ebx
	push ecx
	push edx

	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, [str]
	mov edx, [len]
	int SYS_CALL

	%undef str
	%undef len

	pop edx
	pop ecx
	pop ebx
	pop eax

	pop ebp
	ret