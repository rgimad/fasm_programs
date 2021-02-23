format PE64 Console 5.0
entry Start
 
include 'C:\Program Files (x86)\fasmw17322\INCLUDE\win64a.inc'
 
section '.text' code readable executable
 
Start:
  invoke SetConsoleTitleA, conTitle
  test eax, eax  ; compare eax with 0
  jz Exit ; if eax == 0 then exit
 
  invoke GetStdHandle, [STD_OUTP_HNDL] ; get console output handle. Result will be in eax
  mov [hStdOut], eax ; move return value of GetStdHandle to hStdOut variable (defined below in .data section)
 
  invoke GetStdHandle, [STD_INP_HNDL] ; similiar
  mov [hStdIn], eax
 
  invoke WriteConsoleA, [hStdOut], mes, mesLen, chrsWritten, 0 ; write hello world
  ; for printf, scanf etc. we use cinvoke (__cdecl), invoke is used for __stdcall functions
  cinvoke printf, format1, 1337
  cinvoke printf, <'a = %s', 13, 10, 'b = %s', 13, 10>, 'apple', 'boy'
  ;cinvoke printf, "num = %x", 2227

  cinvoke printf, "var1 = %.11lf", [var1]
  movq xmm0, [var1] ; load from memory
  addsd xmm0, xmm0 ; *=2
  ;mulsd xmm0, xmm0

  ; 1st way to get absolute value of for example xmm0
  ;mov rax, 0
  ;movq xmm1, rax
  ;subsd xmm1, xmm0
  ;movq xmm0, xmm1

  ; 2nd way to get abs of xmm register
  pslld  xmm0, 1
  psrld  xmm0, 1

  movq [var1], xmm0
  cinvoke printf, " var1 = %.11lf", [var1]
 
  invoke ReadConsoleA, [hStdIn], readBuf, 1, chrsRead, 0 ; pause console :)
 
Exit: ; exit from program
  invoke  ExitProcess, 0
 
section '.data' data readable writeable
  ; db - reserve byte, dw - reserve word, dd - reserve dword, dq - reserve qword

  conTitle    db 'Console', 0
  mes         db 'Hello World!', 0dh, 0ah, 0
  mesLen      = $-mes ; address of current line minus adress of mes
  format1 db '%d', 0ah, 0

  var1        dq -1.75

  hStdIn      dd 0
  hStdOut     dd 0
  chrsRead    dd 0
  chrsWritten dd 0
 
  STD_INP_HNDL  dd -10
  STD_OUTP_HNDL dd -11
 
section '.bss' readable writeable ; statically-allocated variables that are not explicitly initialized to any value
 
  readBuf  db ?
 
section '.idata' import data readable
 
  library msvcrt,'MSVCRT.DLL',\
          kernel,'KERNEL32.DLL'
 
  import kernel,\
    SetConsoleTitleA, 'SetConsoleTitleA',\
    GetStdHandle, 'GetStdHandle',\
    WriteConsoleA, 'WriteConsoleA',\
    ReadConsoleA, 'ReadConsoleA',\
    ExitProcess, 'ExitProcess'

    import msvcrt,\
    puts,'puts',\
    scanf,'scanf',\
    printf,'printf',\
    exit,'exit'