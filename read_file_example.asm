format PE64 Console 5.0
entry start
 
include 'C:\Program Files (x86)\fasmw17322\INCLUDE\win64a.inc'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.text' code readable executable

SEEK_SET equ 0
SEEK_CUR equ 1
SEEK_END equ 2
 
start:

  ; for printf, scanf etc. we use cinvoke (__cdecl), invoke is used for __stdcall functions
  cinvoke fopen, file_name, mode
  cmp rax, 0
  jne .endif1
  .file_not_found:
    cinvoke printf, <"[-] File %s was not found", 13, 10>, file_name
    jmp Exit
  .endif1:
  mov [hfile], rax

  cinvoke fseek, [hfile], 0, SEEK_END
  cinvoke ftell, [hfile]
  ;inc rax
  mov [file_size], rax
  cinvoke printf, <"Size of %s = %d bytes",13,10,13,10>, file_name, [file_size]
  cinvoke rewind, [hfile]

  ;sub rsp, 20h  ; withount it works
  ;mov rcx, file_name
  ;call [printf] ; [] are important, othrewise will crash
  ;add rsp, 20h ; withount it works
  ;cinvoke printf, file_name

  mov rcx, [file_size]  ; rcx - first parameter for cdecl x64, second in rdx, then r8, r9, and in stack. Its for int types
  inc rcx
  call [malloc]
  ;cinvoke malloc, [file_size]
  mov [buf_ptr], rax


  cinvoke fread, [buf_ptr], 1, [file_size], [hfile] ; read [file_size] chars (i.e 1 is size of each element)
  mov rax, [buf_ptr]
  mov rbx, [file_size]
  mov byte [rax + rbx + 1], 0
  cinvoke printf, <"File contents:",13,10,13,10,"%s">, [buf_ptr]



Exit: ; exit from program
  ;cinvoke getchar ; first getchar will read \n
  cinvoke getchar
  invoke  ExitProcess, 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.data' data readable writeable
  ; db - reserve byte, dw - reserve word, dd - reserve dword, dq - reserve qword

  file_name db 'dec_bin_c.txt', 0 ; char file_name[] = "sometext.txt";
  mode      db 'r+', 0 ; char mode[] = "r+";
  hfile     dq ? ; FILE* hfile;
  file_size dq ?
  buf_ptr       dq ?



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;section '.bss' readable writeable ; statically-allocated variables that are not explicitly initialized to any value

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.idata' import data readable
 
  library msvcrt,'MSVCRT.DLL',\
          kernel,'KERNEL32.DLL'
 
  import kernel,\
    ExitProcess, 'ExitProcess'

    import msvcrt,\
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
    getchar,'getchar',\
    system,'system',\
    exit,'exit'