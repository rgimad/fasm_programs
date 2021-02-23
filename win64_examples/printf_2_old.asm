format PE64
entry start
include 'win64a.inc'

section '.data' data readable writeable
        text1   db 'Privet mir!',0

section '.code' code readable executable
start:
        sub     rsp, 0x28
        lea     rcx, [text1]
        call    [printf]
        call    [getchar]
        xor     rcx, rcx
        call    [ExitProcess]

section '.idata' import data readable writeable

library kernel32, 'kernel32.dll',\
        msvcrt, 'msvcrt.dll'

import  kernel32,\
        ExitProcess, 'ExitProcess'

import  msvcrt,\
        printf, 'printf',\
        scanf, 'scanf',\
        getchar, 'getchar'
