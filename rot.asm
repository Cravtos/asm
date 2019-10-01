section .data
	plain_text db "helloworden", 0x00
	PLAIN_TEXT_LEN equ ($ - plain_text)
	endl db 0xA
	key dd 0x3
 
section .bss
	cipher_text resb PLAIN_TEXT_LEN
	decrypted_text resb PLAIN_TEXT_LEN
  
section .text
	global _start
_start:
	push plain_text
	push cipher_text
	call encrypt
	sub esp, 0x8
 
	push cipher_text
	push decrypted_text
	call decrypt
	sub esp, 0x8
 
	push cipher_text
	push decrypted_text
	push PLAIN_TEXT_LEN
	call print
	sub esp, 0x12
 
	; -- EXIT --
	mov eax, 0x1
	xor ebx, ebx
	int 0x80

print:
	push ebp
	mov ebp, esp

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

	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, [ebp+16]
	mov edx, [ebp+8]
	int 0x80

	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, endl
	mov edx, 0x1
	int 0x80

	pop ebp
	ret

; al -> char
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
	mov eax, 0x1
	jmp .exit
.upper:
	mov eax, 0x2
	jmp .exit
.not_a_letter:
	xor eax, eax
.exit:
	pop ebp
	ret
 
; [ebp+12] -> plaintext
; [ebp+8] -> place for encrypted str
encrypt:
	push ebp
	mov ebp, esp
	sub esp, 0x4

	mov edi, [ebp+8]
	mov esi, [ebp+12]
 
	; HERE MUST BE ENCRYPTION PROCCESS
	; if char in abc/ABC => encrypt by key
.cycle:
	cmp [esi], byte 0x00
	je .exit
	lodsb
	mov [ebp-4], eax
	call detect_case
	test eax, eax
	jz .not_a_letter
	cmp eax, 1
	je .encrypt_lower

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
	jmp .skip

.not_a_letter:
	mov eax, [ebp-4]
.skip:
	stosb
	jmp .cycle
.exit:
	add esp, 0x4
	pop ebx
	ret
 
; [ebp+12] -> ciphertext
; [ebp+8] -> place for decrypted str
decrypt:
	push ebp
	mov ebp, esp
	sub esp, 0x4

	mov edi, [ebp+8]
	mov esi, [ebp+12]
 
	; HERE MUST BE ENCRYPTION PROCCESS
	; if char in abc/ABC => encrypt by key
.cycle:
	cmp [esi], byte 0x00
	je .exit
	lodsb
	mov [ebp-4], eax
	call detect_case
	test eax, eax
	jz .not_a_letter
	cmp eax, 0x1
	je .decrypt_lower

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
	jmp .skip

.not_a_letter:
	mov eax, [ebp-4]
.skip:
	stosb
	jmp .cycle
.exit:
	add esp, 0x4
	pop ebp
	ret