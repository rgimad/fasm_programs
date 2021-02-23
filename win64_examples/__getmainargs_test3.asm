format PE64
entry start
include 'win64a.inc'

;;section '.data' data readable writeable
        ;;;

section '.bss' readable writeable
        argc    dq ?
        argv    dq ?
        envp    dq ?
        sinfo   STARTUPINFO
section '.text' code readable executable
start:
        ; int __getmainargs(int * _Argc, char *** _Argv, char *** _Env, int _DoWildCard, _startupinfo * _StartInfo);
        ;cinvoke __getmainargs, argc, argv, envp, 0, sinfo
        ;mov rax, [argv] ; rax = *argv;  so rax becomes like argv in C programs, here below we use it as in C
        ;cinvoke printf, <"argv[1] = %s",13,10>, qword [rax + 8]  ;; i.e printf("argv[1] = %s\n", argv[1]);
        ;cinvoke printf, <"argc = %d">, qword [argc] ;; i.e printf("argc = %d")

        sub rsp, 0x30 ; 8(align) + 8(5th arg) + 32(shadow space)
        lea rcx, [argc]
        lea rdx, [argv]
        lea r8, [envp]
        mov r9, 0
        mov qword [rsp + 8*4], sinfo
        call [__getmainargs]

        mov rax, [argv]

        mov rcx, qword [argc]
        push rax rcx
        mov rbx, rcx
        cinvoke printf, <"argc = %d",13,10>, rbx
        pop rcx rax
        xor rbx, rbx
        @@:
            push rax rcx
            cinvoke printf, <"argv[%d] = %s",13,10>, rbx, qword [rax + rbx*8]
            pop rcx rax
            inc rbx
            cmp rbx, rcx
            jb @b

        call [_getch]
        xor rcx, rcx
        call [ExitProcess]

section '.idata' import data readable

library msvcrt,'msvcrt.dll',\
        kernel,'kernel32.dll'
 
import  kernel,\
        ExitProcess, 'ExitProcess'

import  msvcrt,\
        scanf,'scanf',\
        printf,'printf',\
        fopen,'fopen',\
        fclose,'fclose',\
        fseek,'fseek',\
        ftell,'ftell',\
        rewind,'rewind',\
        fread,'fread',\
        malloc,'malloc',\
        free,'free',\
        putchar,'putchar',\
        getchar,'getchar',\
        _getch,'_getch',\
        system,'system',\
        __getmainargs,'__getmainargs',\
        exit,'exit'