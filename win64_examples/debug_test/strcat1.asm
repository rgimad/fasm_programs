format MS COFF ;PE CONSOLE
public start ; if ms coff
;include 'WIN32AX.INC'

section '.data' data readable writeable

        string1: times 256 db 0
        string2: times 256 db 0
        azazalolkek dd 55

        ;len1 dd 0
        ;len2 dd 0

section '.code' code readable executable
start:
        mov eax, eax
        ret
