format PE console
entry main
include 'win32ax.inc'

section '.data' data readable writeable
        msg     db "hello world!",0
        ;p       db "pause>nul",0
        funcaddr dd ?
        tmp     dd ?

section '.text' code readable executable

OS_BASE equ 0x80000000
;REGION1_BASE equ 0x7FFFFFFF; 0x80000000 - 128 + 0;0xFFFFFFFF;0x80000000 - 128 + 1
;REGION1_LEN  equ 0xFFFFFFFF;128

REGION1_BASE equ 0xFFFFFFFF
REGION1_LEN  equ 0

;REGION1_BASE equ OS_BASE;
;REGION1_LEN  equ 1;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:
        push    ebp
        mov     ebp, esp
        sub     ebp, 4

        stdcall is_region_userspace, REGION1_BASE, REGION1_LEN 
        jz .addr_error  

        cinvoke printf, <"region [%x, %x + %u) is USER SPACE", 13, 10, 0>, REGION1_BASE, REGION1_BASE, REGION1_LEN

        jmp     .finish

.addr_error:
        cinvoke printf, <"region [%x, %x + %u) is KERNEL SPACE", 13, 10, 0>, REGION1_BASE, REGION1_BASE, REGION1_LEN

.finish:
        ;mov    dword [esp],p
        ;call   [system]
        mov     dword [esp],0
        call    [exit]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; check if given memory region lays in lower 2gb (userspace memory) or not
align 4
proc is_region_userspace stdcall, base:dword, len:dword
; in:
;      base = base address of region
;      len = lenght of region
; out: ZF = 1 if region in userspace memory
;      ZF = 0 otherwise
        push    eax ebx
        mov     eax, [base]

        ;DEBUGF  1, "base = %x, len = %d\n", [base], [len]

        cmp     eax, OS_BASE
          ;pusha
          ;mov [tmp], eax
          ;cinvoke printf, <"eax =  %x", 13, 10, 0>, dword [tmp]
          ;popa
        ja     @f

        mov     ebx, 0xFFFFFFFF
        sub     ebx, [base]
        inc     ebx             ; ebx = max possible len of black with this base
          ;pusha
          ;mov [tmp], ebx
          ;cinvoke printf, <"ebx =  %x", 13, 10, 0>, dword [tmp]
          ;popa
        cmp     [len], ebx
        ja      @f

        add     eax, [len]
        cmp     eax, OS_BASE
        ja      @f

        mov     eax, 1
        ;DEBUGF  1, "region in userspace\n\n"
        jmp     .ret
@@:
        xor     eax, eax
        ;DEBUGF  1, "base = %x, len = %d\n", [base], [len]
        ;DEBUGF  1, "region in kernelspace\n\n"
.ret:
        test    eax, eax
        pop     ebx eax
        ret 
endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section '.idata' import data readable
library msvcrt, 'msvcrt.dll',\ 
        kernel32, 'kernel32'

import msvcrt,\
       printf,'printf',\
       system,'system',\
       exit,'exit'