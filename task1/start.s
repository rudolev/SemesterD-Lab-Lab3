section .data
    newline: db 10
    infile: dd 0            ; Default: stdin
    outfile: dd 1           ; Default: stdout
    v_key: dd 0
    v_key_len: dd 0
    v_idx: dd 0

section .bss
    char_buf: resb 1        ; Buffer for reading 1 byte

section .text
global _start
global system_call
extern strlen

_start:
    pop    ecx              ; argc
    mov    esi, esp         ; argv
    push   esi              
    push   ecx              
    call   main
    mov    ebx, eax         ; exit code
    mov    eax, 1           ; SYS_EXIT
    int    0x80

main:
    push   ebp
    mov    ebp, esp
    mov    ecx, [ebp+8]     ; argc
    mov    esi, [ebp+12]    ; argv pointer

.arg_loop:
    push   ecx              ; Save remaining argc
    push   esi              ; Save current argv pointer
    
    mov    edi, [esi]       ; edi = current argument string (argv[i])

    ; --- Task 1.A: Debug print to stderr ---
    push   edi
    call   strlen           ; util.c function
    add    esp, 4
    
    mov    edx, eax         ; length
    mov    ecx, edi         ; buffer
    mov    ebx, 2           ; stderr
    mov    eax, 4           ; SYS_WRITE
    int    0x80
    
    mov    eax, 4
    mov    ebx, 2
    mov    ecx, newline
    mov    edx, 1
    int    0x80

    ; --- Task 1.C: Parse Flags ---
    ; Check for +V (Vigenere)
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
    
    ; Check for -i (Input file)
    cmp    byte [edi+1], 'i'
    jne    .check_out
    add    edi, 2           ; filename
    mov    eax, 5           ; SYS_OPEN
    mov    ebx, edi         ; pointer to filename string
    mov    ecx, 0           ; O_RDONLY
    int    0x80
    mov    [infile], eax    ; Store returned fd
    jmp    .next_arg

.check_out:
    ; Check for -o (Output file)
    cmp    byte [edi+1], 'o'
    jne    .next_arg
    add    edi, 2
    mov    eax, 5           ; SYS_OPEN
    mov    ebx, edi
    mov    ecx, 0x241       ; O_WRONLY | O_CREAT | O_TRUNC
    mov    edx, 0644h       ; Permissions
    int    0x80
    mov    [outfile], eax

.next_arg:
    pop    esi              ; Restore argv pointer
    pop    ecx              ; Restore argc counter
    add    esi, 4           ; Move to next arg
    
    dec    ecx              ; Manually decrement argc counter
    jne    .arg_loop        ; Jump if ecx is not zero (Standard jump has larger range)

    ; --- Task 1.B: Encoding Loop ---
.encode_loop:
    ; Read 1 byte
    mov    eax, 3           ; SYS_READ
    mov    ebx, [infile]    ; Use file descriptor from -i or stdin
    mov    ecx, char_buf
    mov    edx, 1
    int    0x80
    
    cmp    eax, 0           ; EOF or error
    jle    .finish

    ; Apply Vigenere
    cmp    dword [v_key], 0
    je     .write_out
    
    mov    al, [char_buf]
    mov    edi, [v_key]
    mov    ebx, [v_idx]
    mov    cl, [edi + ebx]
    sub    cl, '0'          ; Convert '1' to 1
    add    al, cl
    mov    [char_buf], al
    
    ; Increment and wrap key index
    inc    ebx
    cmp    ebx, [v_key_len]
    jne    .save_v_idx
    xor    ebx, ebx
.save_v_idx:
    mov    [v_idx], ebx

.write_out:
    mov    eax, 4           ; SYS_WRITE
    mov    ebx, [outfile]   ; Use file descriptor from -o or stdout
    mov    ecx, char_buf
    mov    edx, 1
    int    0x80
    jmp    .encode_loop

.finish:
    mov    esp, ebp
    pop    ebp
    ret