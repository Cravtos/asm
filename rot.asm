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
%define BUFSIZE 100


section .data
	of_msg db 'Overflow.', 0xA
	of_msg_len equ ($ - of_msg)
	endl db 0xA  ; '\n'
	plain_text_len dd 0

section .bss
	rotated_text resb BUFSIZE
	plain_text resb BUFSIZE
  
section .text
	global _start
_start:

	.read_cycle:
		pcall read, plain_text, BUFSIZE

		test eax, eax
		jz .exit

		mov [plain_text_len], eax

		mov ecx, ABC_POWER
		.rot26:

			pcall rot, rotated_text, plain_text, [plain_text_len], ecx ; ecx -- key
			pcall print, rotated_text, [plain_text_len]
			pcall print, endl, 0x1

		loop .rot26

	loop .read_cycle

	.exit:
		mov eax, SYS_EXIT	;
		xor ebx, ebx		; terminate
		int SYS_CALL		;

; arg1 -- exit_code	
err_overflow:
	push ebp
	mov ebp, esp
	%define exit_code arg(1)

	pcall print, of_msg, of_msg_len
	mov eax, SYS_EXIT
	mov ebx, [exit_code]
	int SYS_CALL

	%undef exit_code
	pop ebp
	ret

; arg4 -- rotation
; arg3 -- len
; arg2 -- plaintext
; arg1 -- place for rotated text
rot:
	%define dst arg(1)
	%define src arg(2)
	%define len arg(3)
	%define rotation arg(4)

	push ebp
	mov ebp, esp

	pushad

	mov edi, [dst]
	mov esi, [src]
 
	mov ecx, [len]
	.cycle:
		push ecx
		lodsb
		
		; EBX -> 'a' (lower) | 'A' (upper) | '0' (not a letter)
		pcall detect_case, eax ; eax -- char from plaintext (after lodsb)

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


	%define str arg(1)
	%define len arg(2)

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

; arg2 -- buf_len
; arg1 -- buf
read:
	push ebp
	mov ebp, esp
	sub esp, 0x4

	push edi

	%define buf arg(1) 
	; arg(1) -> buf -> '..'
	%define buf_len arg(2)
	%define place_left local(1)
	
	mov [place_left], dword BUFSIZE
	mov edi, [buf]

	.read_cycle:
		mov eax, SYS_READ
		mov ebx, STDIN
		mov ecx, [buf]
		mov edx, [place_left]
		int SYS_CALL

		test eax, eax
		jz .break

		add [buf], eax
		sub [place_left], eax
		cmp [place_left], dword 0x0
		jle .err_overflow
	jmp .read_cycle
	.err_overflow:
		pcall err_overflow, 0x1

	.break:
	mov eax, [buf]
	sub eax, edi	; ((buf+readed) - buf)
	
	%undef buf 
	%undef buf_len 
	%undef place_left

	pop edi
	add esp, 0x4
	pop ebp
	ret
