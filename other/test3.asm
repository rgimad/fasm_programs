

    format ELF
    section '.text' executable
    public start
    public start as '_start'
    ;extrn mf_init
    extrn main
    ;include 'debug2.inc'
    __DEBUG__=0
     
    ;start_:
    virtual at 0
            db 'MENUET01' ; 1. Magic number (8 bytes)
            dd 0x01       ; 2. Version of executable file
            dd start       ; 3. Start address
            dd 0x0        ; 4. Size of image
            dd 0x100000   ; 5. Size of needed memory
            dd 0x100000   ; 6. Pointer to stack
    hparams dd 0x0        ; 7. Pointer to program arguments
    hpath   dd 0x0        ; 8. Pointer to program path
    end virtual
     
    start:
    ;DEBUGF 'Start programm\n'
        ;init heap of memory
        mov eax,68
        mov ebx,11
        int 0x40
     
    ;DEBUGF ' path "%s"\n params "%s"\n', .path, .params
    ; check for overflow
    ;; that not work
    ;    mov  al, [path+buf_len-1]
    ;    or  al, [params+buf_len-1]
    ;    jnz   .crash
    ; check if path written by OS
            mov  [argc], 0
        mov  eax, [hparams]
        test eax, eax
        jz   .without_path
        mov  eax, path
        cmp  word ptr eax, 32fh  ; '/#3'  UTF8
        jne  .without_path
        mov  word ptr eax, 12fh  ; '/#1'  fix to CP866
    .without_path:
        mov  esi, eax
        call push_param
    ; retrieving parameters
        mov  esi, params
        xor  edx, edx  ; dl - шф╕Є ярЁрьхЄЁ(1) шыш ЁрчфхышЄхыш(0)
                       ; dh - ёшьтюы ё ъюЄюЁюую эрўрыё  ярЁрьхЄЁ (1 ърт√ўъш, 0 юёЄры№эюх)
        mov  ecx, 1    ; cl = 1
                       ; ch = 0  яЁюёЄю эюы№
    .parse:
        lodsb
        test al, al
        jz   .run
        test dl, dl
        jnz  .findendparam
                         ;{хёыш с√ы ЁрчфхышЄхы№
        cmp  al, ' '
        jz   .parse  ;чруЁєцхэ яЁюсхы, уЁєчшь ёыхфє■∙шщ ёшьтюы
        mov  dl, cl  ;эрўшэрхЄё  ярЁрьхЄЁ
        cmp  al, '"'
        jz   @f      ;чруЁєцхэ√ ърт√ўъш
        mov  dh, ch     ;ярЁрьхЄЁ схч ърт√ўхъ
        dec  esi
        call push_param
        inc  esi
        jmp  .parse
     
      @@:  
        mov  dh, cl     ;ярЁрьхЄЁ т ърт√ўхърї
        call push_param ;хёыш эх яЁюсхы чэрўшЄ эрўшэрхЄё  ъръющ Єю ярЁрьхЄЁ
        jmp  .parse     ;хёыш с√ы ЁрчфхышЄхы№}
     
    .findendparam:
        test dh, dh
        jz   @f ; схч ърт√ўхъ
        cmp  al, '"'
        jz   .clear
        jmp  .parse
      @@:  
        cmp  al, ' '
        jnz  .parse
     
    .clear:
        lea  ebx, [esi - 1]
        mov  [ebx], ch
        mov  dl, ch
        jmp  .parse
     
    .run:
    ;DEBUGF 'call main(%x, %x) with params:\n', [argc], argv
    if __DEBUG__ = 1
        mov  ecx, [argc]
      @@:
        lea  esi, [ecx * 4 + argv-4]
        DEBUGF '0x%x) "%s"\n', cx, [esi]
        loop @b
    end if
        push argv
        push [argc]
        call main
    .exit:
    ;DEBUGF 'Exit from prog\n';
        xor  eax,eax
        dec  eax
        int  0x40
        dd   -1
    .crash:
    ;DEBUGF 'E:buffer overflowed\n'
        jmp  .exit
    ;============================
    push_param:
    ;============================
    ;parameters
    ;  esi - pointer
    ;description
    ;  procedure increase argc
    ;  and add pointer to array argv
    ;  procedure changes ebx
        mov  ebx, [argc]
        cmp  ebx, max_parameters
        jae  .dont_add
        mov  [argv+4*ebx], esi
        inc  [argc]
    .dont_add:    
        ret
    ;==============================
    public argc as '__argc'
    public params as '__argv'
    public path as '__path'
     
    section '.bss'
    buf_len = 0x400
    max_parameters=0x20
    argc     rd 1
    argv     rd max_parameters
    path     rb buf_len
    params   rb buf_len
     
    ;section '.data'
    ;include_debug_strings ; ALWAYS present in data section
     

