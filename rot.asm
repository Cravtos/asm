ection .data
    ABC_LOWER db 'abcdefghijklmnopqrstuvwxyz', 0
    ABC_UPPER db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0
    plain_text db "Hello, world!", 0
    PLAIN_TEXT_LEN equ ($ - plain_text)
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
 
    ; HERE MUST BE PRINTING PROC
 
    ; -- EXIT --
    mov eax, 1
    xor ebx, ebx
    int 0x80
 
; [ebp+12] -> string
; [ebp+8] -> char
; Returns 1 if string contains specified char
find:
    push ebp
    mov ebp, esp
    push esi
 
    mov esi, [ebp+12]
    mov al, [ebp+8]
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
    push esi
    push edi
    push ecx
 
    mov ecx, [ebp+8]
    mov edi, [ebp+12]
    mov esi, [ebp+16]
 
    ; HERE MUST BE ENCRYPTION PROCCESS
 
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
    push esi
    push edi
    push ecx
 
    mov ecx, [ebp+8]
    mov edi, [ebp+12]
    mov esi, [ebp+16]
 
    ; HERE MUST BE DECRYPTION PROCCESS
 
    pop ecx
    pop esi
    pop edi
    pop ebp
    ret
