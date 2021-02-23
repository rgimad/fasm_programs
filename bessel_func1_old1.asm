format PE64 Console 5.0
entry main
 
include 'C:\Program Files (x86)\fasmw17322\INCLUDE\win64a.inc'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.text' code readable executable
 
main:

  ; for printf, scanf etc. we use cinvoke (__cdecl), invoke is used for __stdcall functions

  cinvoke printf, msg_enter_x
  cinvoke scanf, x_read_fmt, x

  mov [s], 0.0 ; for double values we must write .0 always.
  mov rax, 1.0 ; 64bit mode allows only signed 32bit immediates. Only instruction that can take 64bit immediate is "mov rax, imm64"
  mov [p], rax
  mov [n], 0

  while_1:
    ; check if abs(p) >= eps. if false break
    movq xmm0, [p]
    pslld  xmm0, 1
    psrld  xmm0, 1
    comisd xmm0, [eps]
    jc while_1_end ; if abs(p) < eps then break

    movq xmm1, [s]
    addsd xmm1, [p]
    movq [s], xmm1

    inc [n]

    cvtsi2sd xmm1, [n] ; convert int to double. ~ xmm1 = (double)n;
    mulsd xmm1, xmm1 ; now xmm1 = n^2
    mov rax, 4.0
    movq xmm4, rax
    mulsd xmm1, xmm4 ; now xmm1 = 4*(n^2)

    movq xmm0, [x]
    mulsd xmm0, xmm0 ; now xmm0 = x^2
    mov rax, -1.0
    movq xmm4, rax
    mulsd xmm0, xmm4 ; now xmm0 = -(x^2)

    movq xmm3, [p]
    mulsd xmm3, xmm0
    divsd xmm3, xmm1

    movq [p], xmm3

    jmp while_1

  while_1_end:

  ;cinvoke printf, format1, 1337
  ;cinvoke printf, <'a = %s', 13, 10, 'b = %s', 13, 10>, 'apple', 'boy'
  ;cinvoke printf, "num = %x", 2227

  ;cinvoke printf, "var1 = %.11lf", [var1]
  ;movq xmm0, [var1] ; load from memory
  ;addsd xmm0, xmm0 ; *=2
  ;mulsd xmm0, xmm0

  ; 1st way to get absolute value of for example xmm0
  ;mov rax, 0
  ;movq xmm1, rax
  ;subsd xmm1, xmm0
  ;movq xmm0, xmm1

  ; 2nd way to get abs of xmm register
  ;pslld  xmm0, 1
  ;psrld  xmm0, 1

  ;movq [var1], xmm0
  ;cinvoke printf, " var1 = %.11lf", [var1]

  ;inc [n]
  ;inc [n]
  ;cvtsi2sd xmm1, [n]
  ;movq [p], xmm1

  cinvoke printf, "J0(%f) = %f", [x], [s]

  cinvoke getchar ; first getchar will read \n
  cinvoke getchar

  jmp main
  ;cinvoke system, cmd

Exit: ; exit from program
  invoke  ExitProcess, 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.data' data readable writeable
  ; db - reserve byte, dw - reserve word, dd - reserve dword, dq - reserve qword

  eps      dq   0.000001 ; double eps = 0.000001; // epsilon
  x        dq   ?        ; double x; // x value
  n        dd   ?        ; int n; // step counter
  s        dq   ?        ; double s; // current sum
  p        dq   ?        ; double p; // current member of series

  msg_enter_x db 'Enter x: ', 13, 10, 0
  x_read_fmt  db '%lf', 0
  ;cmd         db 'mspaint.exe', 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;section '.bss' readable writeable ; statically-allocated variables that are not explicitly initialized to any value
;  readBuf  db ?


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.idata' import data readable
 
  library msvcrt,'MSVCRT.DLL',\
          kernel,'KERNEL32.DLL'
 
  import kernel,\
    ExitProcess, 'ExitProcess'
    ;SetConsoleTitleA, 'SetConsoleTitleA',\
    ;GetStdHandle, 'GetStdHandle',\
    ;WriteConsoleA, 'WriteConsoleA',\
    ;ReadConsoleA, 'ReadConsoleA'

    import msvcrt,\
    puts,'puts',\
    scanf,'scanf',\
    printf,'printf',\
    getchar,'getchar',\
    system,'system',\
    exit,'exit'