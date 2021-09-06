section .data
	src db 'hello', 0
	mat db 'h?*?***', 0
	suc db 'MATCH', 10
	slen equ $-suc
section .text
	global _start
_start:
	push dword mat
	push dword src
	call match	
	add esp, 8
	
	test eax, eax
	jz exit
	
	mov eax, 4
	mov ebx, 1
	mov ecx, suc
	mov edx, slen
	int 0x80
 
exit:
	mov eax, 1
	xor ebx, ebx
	int 0x80

match:
	push ebp
	mov ebp, esp
	sub esp, 4
	
	push esi
	push edi
	mov esi, [ebp+8]	; string
	mov edi, [ebp+12]	; mask
.again:
	cmp byte [edi], 0
	jne .not_end
	cmp byte [esi], 0
	jne near .false
	jmp .true
.not_end:
	cmp byte [edi], '*'
	jne .not_star

	mov dword [ebp-4], 0	;  used for str shift
.star_loop:
	mov eax, edi
	inc eax
	push eax

	mov eax, esi
	add eax, [ebp-4]
	push eax

	call match

	add esp, 8
	test eax, eax
	jnz .true

	add eax, [ebp-4]
	cmp byte [esi+eax], 0
	je .false
	inc dword [ebp-4]
	jmp .star_loop

.not_star:
	mov al, [edi]
	cmp al, '?'
	je .quest
	cmp al, [esi]
	jne .false
	jmp .goon

.quest:
	cmp byte [esi], 0
	jz .false
.goon:	
	inc esi
	inc edi
	jmp .again

.false:
	xor eax, eax
	jmp .exit
.true:
	mov eax, 1
.exit:
	pop edi
	pop esi	
	mov esp, ebp
	pop ebp
	ret

