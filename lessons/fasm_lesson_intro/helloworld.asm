format PE64 GUI 5.0
entry start
include 'win64a.inc'

section '.data' data readable writeable
    text db 'Hello world!',0
    caption db 'Privet mir!',0


section '.code' code readable executable
start:
    sub rsp, 0x28   ; 0x28 = 0x20 + 0x8 . 0x20 = 32 bytes.
    mov rcx, 0
    mov rdx, text
    mov r8, caption
    mov r9, 0
    call [MessageBoxA]
    xor rcx, rcx
    call [ExitProcess]

section '.idata' import data readable writeable

library kernel32, 'kernel32.dll',\
        user32, 'user32.dll'

import kernel32,\
       ExitProcess, 'ExitProcess'

import user32,\
       MessageBoxA, 'MessageBoxA'