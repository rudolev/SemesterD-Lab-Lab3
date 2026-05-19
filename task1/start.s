section .data
    newline: db 10          ; Constant for newline character (ASCII 10)
    infile: dd 0            ; Variable to store input file descriptor (default: 0 / stdin)
    outfile: dd 1           ; Variable to store output file descriptor (default: 1 / stdout)
    v_key: dd 0             ; Pointer to the Vigenere key string (from +V flag)
    v_key_len: dd 0         ; Length of the Vigenere key string
    v_idx: dd 0             ; Current index/position within the Vigenere key

section .bss
    char_buf: resb 1        ; Reserve 1 byte for the read/write buffer (uninitialized)

section .text
global _start               ; Entry point for the linker
global system_call          ; Exported symbol for syscalls
extern strlen               ; Extern function to calculate string length (from util.c)

_start:
    pop    ecx              ; Pop argc (argument count) from the stack into ECX
    mov    esi, esp         ; Move the address of argv (argument vector) into ESI
    push   esi              ; Push argv back onto stack to prepare for main() call
    push   ecx              ; Push argc back onto stack for main() call
    call   main             ; Transfer control to main function
    mov    ebx, eax         ; Move the return value of main into EBX (exit code)
    mov    eax, 1           ; Load system call number 1 (SYS_EXIT) into EAX
    int    0x80             ; Trigger interrupt to exit the program

main:
    push   ebp              ; Standard prologue: save old base pointer
    mov    ebp, esp         ; Set base pointer to current stack pointer
    mov    ecx, [ebp+8]     ; Get argc from the stack
    mov    esi, [ebp+12]    ; Get argv pointer from the stack

.arg_loop:
    push   ecx              ; Preserve remaining argc on the stack
    push   esi              ; Preserve current argv pointer on the stack
    
    mov    edi, [esi]       ; Load the address of the current argument string into EDI

    ; --- Task 1.A: Debug print to stderr ---
    push   edi              ; Push string address for strlen
    call   strlen           ; Calculate length of the current argument
    add    esp, 4           ; Clean up stack after function call
    
    mov    edx, eax         ; Move length (from EAX) to EDX for write syscall
    mov    ecx, edi         ; Move string address to ECX for write syscall
    mov    ebx, 2           ; Set file descriptor to 2 (stderr)
    mov    eax, 4           ; Load system call number 4 (SYS_WRITE)
    int    0x80             ; Execute syscall: print argument to stderr
    
    ; Print \n
    mov    eax, 4           ; Reset EAX to 4 (SYS_WRITE)
    mov    ebx, 2           ; Target stderr
    mov    ecx, newline     ; Buffer points to the newline character constant
    mov    edx, 1           ; Length is 1 byte
    int    0x80             ; Execute syscall: print newline to stderr

    ; --- Task 1.C: Parse Flags ---
    ; Check for +V (Vigenere)
    cmp    byte [edi], '+'  ; Check if argument starts with '+'
    jne    .check_minus     ; If not, skip to checking for '-' flags
    cmp    byte [edi+1], 'V' ; Check if second character is 'V'
    jne    .check_minus     ; If not, skip to checking for '-' flags
    add    edi, 2           ; Increment pointer past "+V" to the key itself
    mov    [v_key], edi     ; Store the key string pointer in v_key
    push   edi              ; Push key string for strlen
    call   strlen           ; Calculate key length
    add    esp, 4           ; Clean stack
    mov    [v_key_len], eax ; Store key length in v_key_len
    jmp    .next_arg        ; Move to processing the next argument

.check_minus:
    cmp    byte [edi], '-'  ; Check if argument starts with '-'
    jne    .next_arg        ; If not, it's an unknown format; skip
    
    ; Check for -i (Input file)
    cmp    byte [edi+1], 'i' ; Check if second character is 'i'
    jne    .check_out       ; If not 'i', check if it is 'o'
    add    edi, 2           ; Move pointer past "-i" to the filename
    mov    eax, 5           ; Load system call number 5 (SYS_OPEN)
    mov    ebx, edi         ; EBX = filename string pointer
    mov    ecx, 0           ; ECX = 0 (O_RDONLY mode)
    int    0x80             ; Execute syscall: open input file
    mov    [infile], eax    ; Store the returned file descriptor in infile
    jmp    .next_arg        ; Move to next argument

.check_out:
    ; Check for -o (Output file)
    cmp    byte [edi+1], 'o' ; Check if second character is 'o'
    jne    .next_arg        ; If not, skip to next argument
    add    edi, 2           ; Move pointer past "-o" to the filename
    mov    eax, 5           ; Load system call 5 (SYS_OPEN)
    mov    ebx, edi         ; EBX = filename string pointer
    mov    ecx, 0x241       ; ECX = O_WRONLY | O_CREAT | O_TRUNC (Create/Overwrite)
    mov    edx, 0644h       ; EDX = File permissions (rw-r--r--)
    int    0x80             ; Execute syscall: open/create output file
    mov    [outfile], eax   ; Store the returned file descriptor in outfile

.next_arg:
    pop    esi              ; Restore the argv pointer from the stack
    pop    ecx              ; Restore the argc counter from the stack
    add    esi, 4           ; Increment argv pointer by 4 bytes (size of a pointer)
    
    dec    ecx              ; Decrement the argument counter
    jne    .arg_loop        ; If arguments remain (ECX != 0), loop back

    ; --- Task 1.B: Encoding Loop ---
.encode_loop:
    ; Read 1 byte
    mov    eax, 3           ; Load system call 3 (SYS_READ)
    mov    ebx, [infile]    ; Use stored input file descriptor (default stdin)
    mov    ecx, char_buf    ; Buffer to store the read byte
    mov    edx, 1           ; Number of bytes to read
    int    0x80             ; Execute syscall: read from file
    
    cmp    eax, 0           ; Check if return value <= 0 (EOF or Error)
    jle    .finish          ; If EOF or error, exit the loop

    ; Check if the character is a newline (ASCII 10)
    mov    al, [char_buf]   ; Load the read byte into AL register
    cmp    al, 10           ; Compare byte with newline (10)
    je     .write_out       ; If it's a newline, don't encode it; just write it

    ; Apply Vigenere
    cmp    dword [v_key], 0 ; Check if a Vigenere key was provided
    je     .write_out       ; If no key (+V flag missing), skip encoding
    
    ; AL already contains [char_buf]
    mov    edi, [v_key]     ; Load key string pointer into EDI
    mov    ebx, [v_idx]     ; Load current key index into EBX
    mov    cl, [edi + ebx]  ; Load current key character into CL

    ; --- UPPERCASE ONLY KEY LOGIC ---
    sub    cl, 'A'          ; Map 'A' -> 0, 'B' -> 1, 'C' -> 2, etc.

    add    al, cl           ; Add numeric key offset to the input character (encode)
    mov    [char_buf], al   ; Store encoded character back in buffer
    
    ; Increment and wrap key index
    inc    ebx              ; Increment the key index
    cmp    ebx, [v_key_len] ; Check if we reached the end of the key
    jne    .save_v_idx      ; If not at end, save the index
    xor    ebx, ebx         ; If at end, reset index to 0 (wrap around)
.save_v_idx:
    mov    [v_idx], ebx     ; Update the v_idx variable in memory

.write_out:
    mov    eax, 4           ; Load system call 4 (SYS_WRITE)
    mov    ebx, [outfile]   ; Use stored output file descriptor (default stdout)
    mov    ecx, char_buf    ; Buffer containing the character to write
    mov    edx, 1           ; Write 1 byte
    int    0x80             ; Execute syscall: write to file
    jmp    .encode_loop     ; Repeat for next character

.finish:
    mov    esp, ebp         ; Epilogue: restore stack pointer
    pop    ebp              ; Restore old base pointer
    ret                     ; Return to _start