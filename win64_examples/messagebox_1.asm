format PE64 GUI 5.0 ; executable file format
entry start ; specify the entry point
include 'win64a.inc' ; include this for library, import macroses

section '.data' data readable writeable
        text db 'Hello world!',0

section '.code' code readable executable
start:  ; now rsp is 8 byte aligned, because when calling start return address (8bytes) pushed to stack (i.e rsp decreases by 8)
        ; if you don't align the stack by 16 bytes boundary this program won't work
        sub     rsp, 0x28 ; 0x28 = 0x20 + 0x8; so we reserve 32 bytes (0x28) for 'shadow space'. And subtract 8 bytes to make the rsp 16-byte aligned 
        mov     rcx, 0
        mov     rdx, text
        mov     r8, text
        mov     r9, 0
        call    [MessageBoxA]
        xor     rcx, rcx
        call [ExitProcess]

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL',\
        user32,'USER32.DLL'

import  kernel32,\
        ExitProcess, 'ExitProcess'

import  user32,\
        MessageBoxA,'MessageBoxA'