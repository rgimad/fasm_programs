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
        ;;sub rsp, 8
        ; int __getmainargs(int * _Argc, char *** _Argv, char *** _Env, int _DoWildCard, _startupinfo * _StartInfo);
        cinvoke __getmainargs, argc, argv, envp, 0, sinfo
        mov rax, [argv] ; rax = *argv;  so rax becomes like argv in C programs, here below we use it as in C
        cinvoke printf, <"argv[1] = %s",13,10>, qword [rax + 8]  ;; i.e printf("argv[1] = %s\n", argv[1]);
        cinvoke printf, <"argc = %d">, qword [argc] ;; i.e printf("argc = %d")
        cinvoke _getch
        invoke ExitProcess, 0

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