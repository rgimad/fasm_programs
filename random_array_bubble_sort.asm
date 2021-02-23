format PE64 Console 5.0
entry main
 
include 'C:\Program Files (x86)\fasmw17322\INCLUDE\win64a.inc'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.text' code readable executable
 
main:

  ; for printf, scanf etc. we use cinvoke (__cdecl), invoke is used for __stdcall functions

  cinvoke time, 0 ; eax = time(0)
  cinvoke srand, eax ; eax = srand(time(0))

  cinvoke printf, "Enter array size: "
  cinvoke scanf, "%d", n
  ;cinvoke printf, <"n = %d", 13, 10>, [n]

  cinvoke malloc, n*4
  mov [arr], rax

  ;cinvoke printf, <"n = %d", 13, 10>, [n]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  xor rcx, rcx
  mov ecx, 0
  while1:
    cmp ecx, [n]
    je while1_end

    push rcx

    cinvoke rand ; eax = rand()
    xor edx, edx
    mov ebx, 100
    div ebx ; in eax will be quotinent, in edx will be remainder

    pop rcx
    mov rax, [arr]
    mov dword [rax + 4*rcx], edx  ; dword means that we get 4 bytes from given address

    ;mov rax, [arr]
    ;mov eax, dword [rax + 4*rcx]
    ;mov [x], eax
    ;push rcx
    ;cinvoke printf, <"el = %d", 13, 10>, [x]
    ;pop rcx

    inc ecx
    jmp while1

  while1_end:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  cinvoke printf, "Random array = "

  xor rcx, rcx
  mov ecx, 0
  while2:
    cmp ecx, [n]
    je while2_end

    ;cinvoke printf, <"n = %d", 13, 10>, [n]

    ;pop rcx
    ;push rcx

    mov rax, [arr]
    mov eax, dword [rax + 4*rcx]
    mov [x], eax

    push rcx
    cinvoke printf, " %d ", [x]
    pop rcx

    inc ecx
    jmp while2

  while2_end:

;;;;;;;;;;;;;;;;;;;;;;;;;
  ;mov ebx, [n]
  ;sub ebx, 5
  ;mov [n], ebx

  xor rcx, rcx
  mov ecx, 0
  for1:
    mov ebx, [n]
    sub ebx, 1
    cmp ecx, ebx
    je for1_end

    xor rdx, rdx
    mov edx, 0
    for2:
      mov ebx, [n]
      sub ebx, ecx
      sub ebx, 1
      cmp edx, ebx
      je for2_end

      mov rax, [arr]
      mov ebx, [rax + 4*rdx]
      cmp ebx, [rax + 4*rdx + 4]
      jbe no_swap

      mov esi, [rax + 4*rdx + 4]
      mov [rax + 4*rdx + 4], ebx
      mov [rax + 4*rdx], esi

      no_swap:

      ;push rcx
      ;push rdx
      ;mov [x], ecx
      ;mov [y], edx
      ;cinvoke printf, <" ecx = %d, edx = %d", 13, 10>, [x], [y]
      ;pop rdx
      ;pop rcx

      inc edx
      jmp for2
    for2_end:

    inc ecx
    jmp for1

  for1_end:
;;;;;;;;;;;;;;;;;;;;;;;;;

  cinvoke printf, <13,10,"Sorted array = ">

  xor rcx, rcx
  mov ecx, 0
  while3:
    cmp ecx, [n]
    je while3_end

    ;cinvoke printf, <"n = %d", 13, 10>, [n]

    ;pop rcx
    ;push rcx

    mov rax, [arr]
    mov eax, dword [rax + 4*rcx]
    mov [x], eax

    push rcx
    cinvoke printf, " %d ", [x]
    pop rcx

    inc ecx
    jmp while3

  while3_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  cinvoke getchar
  cinvoke getchar

  ;mov [x], 55
  ;cinvoke printf, <"ecx = %d", 13, 10>, [x]   ; works good
  ;mov ecx, 777
  ;cinvoke printf, <"ecx = %d", 13, 10>, ecx   ; it will show garbage because ecx will be clobbered before cinvoke

;loop1:
;  cinvoke rand ; eax = rand()
;  mov [x], eax
;  xor edx, edx
;  mov ebx, 100
;  div ebx ; in eax will be quotinent, in edx will be remainder
;  mov [y], edx
;
;  cinvoke printf, <" %d mod 100 = %d", 13, 10>, [x], [y]
;
;  ;cinvoke getchar ; if scanf was before first getchar will read \n
;  cinvoke printf, <13, 10, "Press any key to get next...", 13, 10>
;  cinvoke getchar
;
;  jmp loop1

Exit: ; exit from program
  invoke  ExitProcess, 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section '.data' data readable writeable
  ; db - reserve byte, dw - reserve word, dd - reserve dword, dq - reserve qword

  arr     dq ? ; pointer to array
  n       dd ? ; array length
  x       dd ?
  y       dd ?
  i       dd ?

; arr - address of pointer to array
; [arr] - pointer to array

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