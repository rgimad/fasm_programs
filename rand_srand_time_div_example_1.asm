format PE64 Console 5.0
entry main
 
include 'C:\Program Files (x86)\fasmw17322\INCLUDE\win64a.inc'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.text' code readable executable
 
main:

  ; for printf, scanf etc. we use cinvoke (__cdecl), invoke is used for __stdcall functions

  cinvoke time, 0 ; eax = time(0)
  cinvoke srand, eax ; eax = srand(time(0))

loop1:
  cinvoke rand ; eax = rand()
  mov [x], eax
  xor edx, edx
  mov ebx, 100
  div ebx ; in eax will be quotinent, in edx will be remainder
  mov [y], edx

  cinvoke printf, <" %d mod 100 = %d", 13, 10>, [x], [y]

  ;cinvoke getchar ; if scanf was before first getchar will read \n
  cinvoke printf, <13, 10, "Press any key to get next...", 13, 10>
  cinvoke getchar

  jmp loop1

Exit: ; exit from program
  invoke  ExitProcess, 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.data' data readable writeable
  ; db - reserve byte, dw - reserve word, dd - reserve dword, dq - reserve qword

  ;arr_ptr dq ? ; pointer to array
  x       dd ?
  y       dd ?


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;section '.bss' readable writeable ; statically-allocated variables that are not explicitly initialized to any value
;  readBuf  db ?


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.idata' import data readable
 
  library msvcrt,'MSVCRT.DLL',\
          kernel,'KERNEL32.DLL'
 
  import kernel,\
    ExitProcess, 'ExitProcess'

    import msvcrt,\
    puts,'puts',\
    scanf,'scanf',\
    printf,'printf',\
    getchar,'getchar',\
    malloc,'malloc',\
    free,'free',\
    rand,'rand',\
    srand,'srand',\
    time,'time',\
    system,'system',\
    exit,'exit'