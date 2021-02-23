format PE64 console
entry start
include 'win64a.inc'

section '.data' data readable writeable
    res  dq  ?

section '.text' code readable executable
start:
    mov rax, 55
    cmp rax, 55
    pushf
    pop [res]
    and [res], 0x40
    shr [res], 6
    cinvoke printf, "res = %d", [res]
    cinvoke _getch
    invoke ExitProcess, 0

section '.idata' import data readable writeable
library kernel32, 'kernel32.dll',\
        msvcrt, 'msvcrt.dll'

import kernel32,\
       ExitProcess, 'ExitProcess'

import msvcrt,\
       _getch, '_getch',\
       printf, 'printf'