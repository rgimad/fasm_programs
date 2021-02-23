format PE64
entry start
include 'win64a.inc'

section '.data' data readable writeable
        capt1   db 'Enter A: ',0
        capt2   db 'Enter B: ',0
        capt3   db 'A + B = %lf',0
        fmt     db '%lf',0
        a       dq ?
        b       dq ?
        s       dq ?

section '.code' code readable executable
start:
        sub     rsp, 0x28  ; alloc shadow space (32 bytes) and align up to 16 byte boundary (remaining 8 bytes)

        lea     rcx, [capt1]
        call    [printf]
        lea     rcx, [fmt]
        lea     rdx, [a]
        call    [scanf]

        lea     rcx, [capt2]
        call    [printf]
        lea     rcx, [fmt]
        lea     rdx, [b]
        call    [scanf]

        ; s = a + b
        movq    xmm0, qword [a]
        addsd   xmm0, qword [b]
        movq    qword [s], xmm0

        lea     rcx, [capt3]
        mov     rdx, [s] ; by win64 abi, for vararg functions is neccesary to duplicate floating point args both in general and xmm regs
        movq    xmm0, qword [s]
        call    [printf]

        call    [_getch]   ; wait for pressing any key

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
        _getch, '_getch'
