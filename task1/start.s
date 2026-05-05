section .data
    newline: db 10
    stdin: dd 0
    stdout: dd 1
    stderr: dd 2
    infile: dd 0
    outfile: dd 1
    v_key: dd 0
    v_key_len: dd 0
    v_idx: dd 0

section .text
global _start
global system_call
extern strlen

_start:
    pop    ecx              ; argc
    mov    esi, esp         ; argv
    push   esi              ; push argv for main
    push   ecx              ; push argc for main
    call   main
    mov    ebx, eax         ; exit code from main
    mov    eax, 1           ; SYS_EXIT
    int    0x80

main:
    push   ebp
    mov    ebp, esp
    mov    ecx, [ebp+8]     ; argc
    mov    edx, [ebp+12]    ; argv

    ; Loop through arguments for flags
    xor    ebx, ebx         ; index i = 0
.arg_loop:
    cmp    ebx, ecx
    jge    .start_encoding
    mov    edi, [edx + ebx*4] ; edi = argv[i]

    ; Debug: Print each argument to stderr
    pushad
    push   edi
    call   strlen
    add    esp, 4
    mov    edx, eax         ; length
    mov    ecx, edi         ; buffer
    mov    ebx, 2           ; stderr
    mov    eax, 4           ; SYS_WRITE
    int    0x80
    mov    ecx, newline
    mov    edx, 1
    int    0x80
    popad

    ; Check for +V (Vigenere Key)
    cmp    byte [edi], '+'
    jne    .check_in
    cmp    byte [edi+1], 'V'
    jne    .check_in
    add    edi, 2
    mov    [v_key], edi
    push   edi
    call   strlen
    add    esp, 4
    mov    [v_key_len], eax
    jmp    .next_arg

.check_in:
    cmp    byte [edi], '-'
    jne    .next_arg
    cmp    byte [edi+1], 'i'
    jne    .check_out
    add    edi, 2           ; filename
    mov    eax, 5           ; SYS_OPEN
    mov    ebx, edi
    mov    ecx, 0           ; O_RDONLY
    int    0x80
    mov    [infile], eax
    jmp    .next_arg

.check_out:
    cmp    byte [edi+1], 'o'
    jne    .next_arg
    add    edi, 2
    mov    eax, 5           ; SYS_OPEN
    mov    ebx, edi
    mov    ecx, 101h        ; O_WRONLY | O_CREAT
    mov    edx, 0644h       ; Permissions
    int    0x80
    mov    [outfile], eax

.next_arg:
    inc    ebx
    jmp    .arg_loop

.start_encoding:
    sub    esp, 4           ; buffer for 1 char
.encode_loop:
    ; Read 1 byte
    mov    eax, 3           ; SYS_READ
    mov    ebx, [infile]
    lea    ecx, [ebp-4]
    mov    edx, 1
    int    0x80
    cmp    eax, 0           ; EOF
    jle    .finish

    ; Apply Vigenere if key exists
    cmp    dword [v_key], 0
    je     .write_out
    mov    al, [ebp-4]
    mov    edi, [v_key]
    mov    ebx, [v_idx]
    mov    cl, [edi + ebx]  ; get key char
    sub    cl, '0'          ; convert to value
    add    al, cl           ; encode
    mov    [ebp-4], al
    
    ; Increment key index
    inc    ebx
    cmp    ebx, [v_key_len]
    jne    .save_idx
    xor    ebx, ebx
.save_idx:
    mov    [v_idx], ebx

.write_out:
    mov    eax, 4           ; SYS_WRITE
    mov    ebx, [outfile]
    lea    ecx, [ebp-4]
    mov    edx, 1
    int    0x80
    jmp    .encode_loop

.finish:
    mov    esp, ebp
    pop    ebp
    ret