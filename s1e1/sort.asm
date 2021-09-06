section .data
	arr db 'kak3ae6n4db0l0:'
	len equ $-arr
	endl db 0xA
section .text
	global _start
_start:
	lea esi, [arr]
	mov ecx, len
	dec ecx	
	sortf:
		mov edi, esi
		push ecx		
		
		sorts:
			add edi, 1
			mov al, [edi]
			cmp [esi], al
			jg swap
		bsorts:	loop sorts
		
		pop ecx
		add esi, 1
		loop sortf

	jmp print	

swap:
	mov bl, [esi]
	mov [edi], bl
	mov [esi], al
	jmp bsorts

print:
	mov eax, 4
	mov ebx, 1
	mov ecx, arr
	mov edx, len
	int 0x80
	
	mov eax, 4
	mov ebx, 1
	mov ecx, endl
	mov edx, 0x1
	int 0x80
exit:
	mov eax, 1
	xor ebx, ebx
	int 0x80  
