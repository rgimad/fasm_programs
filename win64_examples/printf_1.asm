format PE64

entry start

include 'win64a.inc'

section '.code' code readable executable
start:
    sub rsp, 40   ; allocate shadow space and alignment (32+8)
    mov rcx, hello
    mov rdx, [rsp]
    call [printf]

    call [getchar]

    ;mov rcx, hello
    ;mov rdx, [rsp]
    ;call [printf]

    ;call [getchar]

    ;sub rsp, 9    ; make rsp not 16 byte aligned - for proof that function below in this case won't work
    ;mov     rcx, 0
    ;mov     rdx, hello
    ;mov     r8, hello
    ;mov     r9, 0
    ;call    [MessageBoxA]

    xor rcx, rcx
    call [ExitProcess]

section '.rdata' data readable
    hello db 'Hello world! %x', 10, 0

section '.idata' import data readable writeable
    library kernel, 'KERNEL32.DLL', \
        msvcrt, 'msvcrt.dll',\
        user32, 'user32.dll'

    import kernel,\
        ExitProcess,'ExitProcess'

    import msvcrt,\
        printf, 'printf',\
        getchar, 'getchar'

    import user32,\
        MessageBoxA,'MessageBoxA'
