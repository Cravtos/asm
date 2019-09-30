section .data
	ABC_LOWER db 'abcdefghijklmnopqrstuvwxyz', 0
	ABC_UPPER db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0
	plain_text db "Hello, world!", 0
	PLAIN_TEXT_LEN equ ($ - plain_text)
	endl db 0xA
	KEY equ 3
 
section .bss
	cipher_text resb PLAIN_TEXT_LEN
	decrypted_text resb PLAIN_TEXT_LEN
  
section .text
	global _start
_start:
	push plain_text
	push cipher_text
	push KEY
	call encrypt
	sub esp, 12
 
	push cipher_text
	push decrypted_text
	push KEY
	call decrypt
	sub esp, 12
 
	push cipher_text
	push decrypted_text
	push PLAIN_TEXT_LEN
	call print
	sub esp, 8
 
	; -- EXIT --
	mov eax, 1
	xor ebx, ebx
	int 0x80

print:
	pushad
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

	popad
	ret

; [ebp+12] -> string
; al -> char
; Returns 1 if string contains specified char
find:
	push ebp
	mov ebp, esp
	push esi
 
	mov esi, [ebp+12]
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
; [ebp+8] -> key
encrypt:
	push ebp
	mov ebp, esp
	sub esp, 4
	push esi
	push edi
	push ecx
	push eax

	mov ecx, [ebp+8]
	mov edi, [ebp+12]
	mov esi, [ebp+16]
 
	; HERE MUST BE ENCRYPTION PROCCESS
	; if char in abc/ABC => encrypt by key
.cycle:
	lodsb
	push abc
	mov [ebp-4], eax
	call find
	test eax, eax
	jnz .encrypt

	mov eax, [ebp-4]
	push ABC
	mov [ebp-4], eax
	call find
	test eax, eax
	jz .skip
.encrypt: ; SPLIT INTO ENCRYPT_UPPER AND ENCRYPT_LOWERT
	mov eax. [ebp-4]
.skip:
	cmp esi, 0
	je .exit
	jmp .cycle
.exit:

	add esp, 4
	pop eax
	pop ecx
	pop esi
	pop edi
	pop ebp
	ret
 
; [ebp+16] -> ciphertext
; [ebp+12] -> place for decrypted str
; [ebp+8] -> key
decrypt:
	push ebp
	mov ebp, esp
	sub esp, 4
	push esi
	push edi
	push ecx
	push eax

	mov ecx, [ebp+8]
	mov edi, [ebp+12]
	mov esi, [ebp+16]
 
	; HERE MUST BE DECRYPTION PROCCESS
	; if char in abc/ABC => decrypt by key
.cycle:
	lodsb
	push abc
	mov [ebp-4], eax
	call find
	test eax, eax
	jnz .encrypt

	mov eax, [ebp-4]
	push ABC
	mov [ebp-4], eax
	call find
	test eax, eax
	jz .skip
.decrypt:
	mov eax. [ebp-4]
	
.skip:
	cmp esi, 0
	je .exit
	jmp .cycle
.exit:

	add esp, 4
	pop eax
	pop ecx
	pop esi
	pop edi
	pop ebp
	ret
