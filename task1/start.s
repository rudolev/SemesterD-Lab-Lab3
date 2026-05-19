section .data
    newline: db 10
    infile: dd 0
    outfile: dd 1
    v_key: dd 0
    v_key_len: dd 0
    v_idx: dd 0

section .bss
    char_buf: resb 1

section .text
global _start
global system_call
extern strlen

; ==============================================================================
; PROGRAM ENTRY POINT
; ==============================================================================
_start:
    pop    ecx
    mov    esi, esp
    push   esi
    push   ecx
    call   main
    mov    ebx, eax
    mov    eax, 1
    int    0x80

; ==============================================================================
; MAIN ROUTINE: ARGUMENT PARSING
; ==============================================================================
main:
    push   ebp
    mov    ebp, esp
    mov    ecx, [ebp+8]
    mov    esi, [ebp+12]

.arg_loop:
    push   ecx
    push   esi
    
    mov    edi, [esi]

    push   edi
    call   strlen
    add    esp, 4
    
    mov    edx, eax
    mov    ecx, edi
    mov    ebx, 2
    mov    eax, 4
    int    0x80
    
    mov    eax, 4
    mov    ebx, 2
    mov    ecx, newline
    mov    edx, 1
    int    0x80

    cmp    byte [edi], '+'
    jne    .check_minus
    cmp    byte [edi+1], 'V'
    jne    .check_minus
    add    edi, 2
    mov    [v_key], edi
    push   edi
    call   strlen
    add    esp, 4
    mov    [v_key_len], eax
    jmp    .next_arg

.check_minus:
    cmp    byte [edi], '-'
    jne    .next_arg
    
    cmp    byte [edi+1], 'i'
    jne    .check_out
    add    edi, 2
    mov    eax, 5
    mov    ebx, edi
    mov    ecx, 0
    int    0x80
    mov    [infile], eax
    jmp    .next_arg

.check_out:
    cmp    byte [edi+1], 'o'
    jne    .next_arg
    add    edi, 2
    mov    eax, 5
    mov    ebx, edi
    mov    ecx, 0x241
    mov    edx, 0644h
    int    0x80
    mov    [outfile], eax

.next_arg:
    pop    esi
    pop    ecx
    add    esi, 4
    
    dec    ecx
    jne    .arg_loop

; ==============================================================================
; STREAM ENCODING LOOP (VIGENÈRE CIPHER)
; ==============================================================================
.encode_loop:
    mov    eax, 3
    mov    ebx, [infile]
    mov    ecx, char_buf
    mov    edx, 1
    int    0x80
    
    cmp    eax, 0
    jle    .finish

    mov    al, [char_buf]
    cmp    al, 10
    je     .write_out

    cmp    dword [v_key], 0
    je     .write_out
    
    mov    edi, [v_key]
    mov    ebx, [v_idx]
    mov    cl, [edi + ebx]

    sub    cl, 'A'
    add    al, cl
    mov    [char_buf], al
    
    inc    ebx
    cmp    ebx, [v_key_len]
    jne    .save_v_idx
    xor    ebx, ebx
.save_v_idx:
    mov    [v_idx], ebx

.write_out:
    mov    eax, 4
    mov    ebx, [outfile]
    mov    ecx, char_buf
    mov    edx, 1
    int    0x80
    jmp    .encode_loop

; ==============================================================================
; PROGRAM CLEANUP & EXIT
; ==============================================================================
.finish:
    mov    esp, ebp
    pop    ebp
    ret