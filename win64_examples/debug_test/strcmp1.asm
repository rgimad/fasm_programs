format PE CONSOLE
include 'WIN32AX.INC'

section '.data' data readable writeable

        string1: times 256 db 0
        string2: times 256 db 0

        len1 dd 0
        len2 dd 0

section '.code' code readable executable

entry start

start:
        cinvoke puts, <"Enter string1: ">
        cinvoke gets, string1

        cinvoke puts, <"Enter string2: ">
        cinvoke gets, string2

        ;cinvoke strlen, string1
        ;mov dword [len1], eax

        ;cinvoke strlen, string2
        ;mov dword [len2], eax

        cinvoke strcmp, string1, string2
        test eax, eax
        jnz .str_dif

        .str_eq:
                cinvoke puts, <"Strings are equal",13,10,0>
                jmp .end_cmp
        .str_dif:
                cinvoke puts, <"Strings are NOT equal",13,10,0>
        .end_cmp:

        cinvoke _getch
        invoke ExitProcess,0

section '.idata' import data readable writeable

library kernel,'kernel32.dll',\
msvcrt,'msvcrt.dll'

import kernel,\
ExitProcess,'ExitProcess'

import msvcrt,\
puts,'puts',\
gets, 'gets',\
_getch, '_getch',\
strcmp, 'strcmp'