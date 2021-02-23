format PE64 Console 5.0
entry _main
 
include 'C:\Program Files (x86)\fasmw17322\INCLUDE\win64a.inc'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.text' code readable executable
 
_main:
  mov rbp, rsp; for correct debugging

  ; for printf, scanf etc. we use cinvoke (__cdecl), invoke is used for __stdcall functions
  ;mov [x_dec], rsp
  ;cinvoke printf, <"Enter a decimal positive number: rsp = %d",13,10>, [x_dec]

  cinvoke printf, "Enter a decimal positive number: "
  cinvoke scanf, <"%d">, x_dec
  ;cinvoke printf, <"x_dec = %d", 13, 10>, [x_dec]

  push x_bin
  push [x_dec]
  ;cinvoke printf, "vchdcfuygc"
  ;mov rax, qword [rsp]
  ;mov [tmp], rax
  ;cinvoke printf, "aa %d", [tmp]   
  call dec_to_bin
  add esp, 16

  ;mov [x_dec], rsp
  ;cinvoke printf, <"x_bin = %d", 13, 10>, x_bin

  cinvoke printf, <"Result dec to bin: %d = %s", 13, 10, 13, 10>, [x_dec], x_bin

  ;cinvoke getchar ; first getchar will read \n
  ;cinvoke getchar

  jmp _main
  
Exit: ; exit from program
  invoke  ExitProcess, 0

;;;;;;;;;;;;;;;;;;;;;;;;
dec_to_bin:  ; void dec_to_bin(int x, char *str)
  push rbp
  mov rbp, rsp

  ;mov rax, qword [rbp + 24]
  ;mov [tmp], rax
  ;cinvoke printf, <"x_bin = %d",13,10>, [tmp]

  xor rcx, rcx
  mov ecx, 32 ; len = 32
  while1:
    mov eax, 1

    mov ebx, ecx
    sub ebx, 1 ; ebx = len - 1

    push rcx
    mov ecx, ebx
    shl eax, cl  ; eax = 1 << (len - 1)
    pop rcx

    mov rbx, [rbp + 16] ; rbx = x
    and eax, ebx
    cmp eax, 0
    jne end_while1
    cmp ecx, 1
    jbe end_while1

    dec ecx
    jmp while1

  end_while1:

  mov rax, [rbp + 24]
  mov byte [rax + rcx], 0

  xor rdx, rdx ; i = 0
  ;mov edx, 0 ; i = 0
  while2:
    cmp edx, ecx
    jae end_while2

    mov eax, 1
    mov ebx, ecx
    sub ebx, edx
    sub ebx, 1

    push rcx
    mov ecx, ebx
    shl eax, cl
    pop rcx

    mov rbx, [rbp + 16]
    and eax, ebx
    cmp eax, 0
    jne .append1
    .append0:
      mov rax, [rbp + 24]
      mov byte [rax + rdx], 48
      jmp .endif1
    .append1:
      mov rax, [rbp + 24]
      mov byte [rax + rdx], 49
    .endif1:

    inc edx
    jmp while2
  end_while2:

  ;leave
  mov rsp, rbp
  pop rbp
  ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.data' data readable writeable
  ; db - reserve byte, dw - reserve word, dd - reserve dword, dq - reserve qword

  x_dec    dq   ?        ; int x_dec
  x_bin    db   30 dup(?)  ; char x_bin[30];
  tmp      dq   ?


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
    system,'system',\
    exit,'exit'