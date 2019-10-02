; Prints all rotations of a string

section .data
	plain_text db "helloworden", 0x00
	plain_text_len equ ($ - plain_text)
	endl db 0xA
 
section .bss
	rotated_text resb plain_text_len
  
section .text
	global _start
_start:

	mov ecx, 26		; alphabet power

.rot26:

	push dword ecx
	push plain_text
	push rotated_text
	call rot
	sub esp, 0x12
 
	push rotated_text
	push plain_text_len
	call print
	sub esp, 0x8

	loop .rot26

	mov eax, 0x1	;
	xor ebx, ebx	; terminate
	int 0x80		;
	
 
; arg_2 -- rotation
; arg_1 -- plaintext
; arg_0 -- place for rotated
rot:
	push ebp
	mov ebp, esp
	sub esp, 0x4		; used for saving char

	pushad

	mov edi, [ebp+8]	; rotated
	mov esi, [ebp+12]	; plain
 
.cycle:
	cmp [esi], byte 0x0
	je .exit

	lodsb

	call detect_case	; EBX -> 'a' (lower) | 'A' (upper) | '0' (not a letter)

	cmp ebx, '0'
	jz .skip

.shift:
	; eax = 'A' + (eax - 'A' + key) % 26
	sub eax, ebx
	add eax, [ebp+16]
	xor edx, edx	;
	mov ecx, 26		; getting
	div ecx			; remainder
	mov eax, edx	;
	add eax, ebx
	
.skip:
	stosb
	jmp .cycle
.exit:
	popad

	add esp, 0x4
	pop ebx
	ret

; AL -> char
; Returns case indicator in EBX
; 'A' for upper
; 'a' for lower
; '0' for not-a-letter
detect_case:
	push ebp
	mov ebp, esp

	cmp al, 'A'
	jb .not_a_letter
	cmp al, 'z'
	ja .exit
	cmp al, 'Z'
	jbe .upper
	cmp al, 'a'
	jae .lower
	
.lower:
	mov ebx, 'a'
	jmp .exit
.upper:
	mov ebx, 'A'
	jmp .exit
.not_a_letter:
	mov ebx, '0'
.exit:
	pop ebp
	ret


; arg_1 -- str
; arg_0 -- len
print:
	push ebp
	mov ebp, esp

	pushad

	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, [ebp+12]
	mov edx, [ebp+8]
	int 0x80

	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, endl
	mov edx, 0x1
	int 0x80

	popad

	pop ebp
	ret