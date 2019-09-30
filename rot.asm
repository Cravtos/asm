section .data
	ABC_LOWER db 'abcdefghijklmnopqrstuvwxyz', 0
	ABC_UPPER db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0
	plain_text db "Hello, world!", 0
	PLAIN_TEXT_LEN equ ($ - plain_text)
	endl db 0xA
	key dd 3
 
section .bss
	cipher_text resb PLAIN_TEXT_LEN
	decrypted_text resb PLAIN_TEXT_LEN
  
section .text
	global _start
_start:
	push plain_text
	push cipher_text
	call encrypt
	sub esp, 8
 
	push cipher_text
	push decrypted_text
	call decrypt
	sub esp, 8
 
	push cipher_text
	push decrypted_text
	push PLAIN_TEXT_LEN
	call print
	sub esp, 12
 
	; -- EXIT --
	mov eax, 1
	xor ebx, ebx
	int 0x80

print:
	mov ebp, esp

	mov eax, 4
	mov ebx, 1
	mov ecx, [ebp+12]
	mov edx, [ebp+8]
	int 0x80

	mov eax, 4
	mov ebx, 1
	mov ecx, endl
	mov edx, 1
	int 0x80

	mov eax, 4
	mov ebx, 1
	mov ecx, [ebp+16]
	mov edx, [ebp+8]
	int 0x80

	mov eax, 4
	mov ebx, 1
	mov ecx, endl
	mov edx, 1
	int 0x80

	ret

; [ebp+8] -> string
; al -> char
; Returns 1 if string contains specified char
find:
	push ebp
	mov ebp, esp
	push esi
 
	mov esi, [ebp+8]
.cycle:
	cmp [esi], byte 0
	je .not_found
	cmp al, [esi]
	je .found
	inc esi
	jmp .cycle
 
.found:
	mov eax, 1
	jmp .exit
.not_found:
	xor eax, eax
.exit:
	pop esi
	pop ebp
	ret
 
; [ebp+16] -> plaintext
; [ebp+12] -> place for encrypted str
encrypt:
	push ebp
	mov ebp, esp
	sub esp, 4

	mov edi, [ebp+8]
	mov esi, [ebp+12]
 
	; HERE MUST BE ENCRYPTION PROCCESS
	; if char in abc/ABC => encrypt by key
.cycle:
	lodsb
	push ABC_LOWER
	mov [ebp-4], eax
	call find
	test eax, eax
	jnz .encrypt_lower

	mov eax, [ebp-4]
	push ABC_UPPER
	mov [ebp-4], eax
	call find
	test eax, eax
	jz .skip
.encrypt_upper:
	mov eax, [ebp-4]
	; eax = 'A' + (eax - 'A' + key) % 26
	sub eax, 'A'
	add eax, [key]
	xor edx, edx
	mov ecx, 26
	div ecx
	mov eax, edx
	add eax, 'A'
	stosb

	jmp .skip
.encrypt_lower:
	mov eax, [ebp-4]
	sub eax, 'a'
	add eax, [key]
	xor edx, edx
	mov ecx, 26
	div ecx
	mov eax, edx
	add eax, 'a'
	stosb

.skip:
	cmp esi, 0
	je .exit
	jmp .cycle
.exit:

	add esp, 4
	pop ebx
	ret
 
; [ebp+12] -> ciphertext
; [ebp+8] -> place for decrypted str
decrypt:
	push ebp
	mov ebp, esp
	sub esp, 4

	mov edi, [ebp+8]
	mov esi, [ebp+12]
 
	; HERE MUST BE ENCRYPTION PROCCESS
	; if char in abc/ABC => encrypt by key
.cycle:
	lodsb
	push ABC_LOWER
	mov [ebp-4], eax
	call find
	test eax, eax
	jnz .decrypt_lower

	mov eax, [ebp-4]
	push ABC_UPPER
	mov [ebp-4], eax
	call find
	test eax, eax
	jz .skip
.decrypt_upper:
	mov eax, [ebp-4]
	; eax = 'A' + (26 + eax - 'A' - key) % 26  
	sub eax, 'A'
	add eax, 26
	sub eax, [key]
	xor edx, edx
	mov ecx, 26
	div ecx
	mov eax, edx
	add eax, 'A'
	stosb

	jmp .skip
.decrypt_lower:
	mov eax, [ebp-4]
	sub eax, 'a'
	sub eax, [key]
	add eax, 26
	xor edx, edx
	mov ecx, 26
	div ecx
	mov eax, edx
	add eax, 'a'
	stosb

.skip:
	cmp esi, 0
	je .exit
	jmp .cycle
.exit:

	add esp, 4
	pop ebp
	ret