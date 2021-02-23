format PE64 GUI 5.0
entry start
; from chapter 5 of Ruslan Ablyazovs book
include 'win64a.inc'

section '.data' data readable writeable

main_hwnd       dq ?
msg             MSG
wc              WNDCLASS
        
hInst           dq ?
szTitleName     db 'Window work sample Win64',0
szClassName     db 'ASMCLASS32',0

button_class    db 'BUTTON',0
AboutTitle      db 'About',0
AboutText       db 'First win64 window program',0;
ExitTitle       db 'Exit',0

AboutBtnHandle  dq ?
ExitBtnHandle   dq ?

section '.code' code executable readable

start:
        sub rsp, 8*5           ; align stack and alloc space for 4  parameters

        xor rcx, rcx
        call [GetModuleHandle]

        mov [hInst], rax
        mov [wc.style], CS_HREDRAW + CS_VREDRAW + CS_GLOBALCLASS
        mov rbx, WndProc
        mov [wc.lpfnWndProc],  rbx
        mov [wc.cbClsExtra], 0
        mov [wc.cbWndExtra], 0
        mov [wc.hInstance], rax

        mov rdx, IDI_APPLICATION
        xor rcx, rcx
        call [LoadIcon]
        mov     [wc.hIcon], rax

        mov rdx, IDC_ARROW
        xor rcx, rcx
        call [LoadCursor]
        mov [wc.hCursor], rax

        mov [wc.hbrBackground], COLOR_BACKGROUND+1
        mov qword [wc.lpszMenuName], 0
        mov rbx, szClassName
        mov qword [wc.lpszClassName], rbx

        mov rcx, wc
        call [RegisterClass]

        sub rsp, 8*8    ; alloc place in stack for 8 parameters

        xor rcx, rcx
        mov rdx, szClassName
        mov r8, szTitleName
        mov r9, WS_OVERLAPPEDWINDOW
        mov qword [rsp+8*4], 50
        mov qword [rsp+8*5], 50
        mov qword [rsp+8*6], 300
        mov qword [rsp+8*7], 250
        mov qword [rsp+8*8], rcx
        mov qword [rsp+8*9], rcx
        mov rbx, [hInst]
        mov [rsp+8*10], rbx
        mov [rsp+8*11], rcx
        call [CreateWindowEx]
        mov [main_hwnd], rax

        xor rcx, rcx
        mov rdx, button_class
        mov r8, AboutTitle
        mov r9, WS_CHILD
        mov qword [rsp+8*4], 50
        mov qword [rsp+8*5], 50
        mov qword [rsp+8*6], 200
        mov qword [rsp+8*7], 50
        mov rbx, [main_hwnd]
        mov qword [rsp+8*8], rbx
        mov qword [rsp+8*9], rcx
        mov rbx, [hInst]
        mov [rsp+8*10], rbx
        mov [rsp+8*11], rcx
        call [CreateWindowEx]
        mov [AboutBtnHandle], rax


        xor rcx, rcx
        mov rdx, button_class
        mov r8, ExitTitle
        mov r9, WS_CHILD
        mov qword [rsp+8*4], 50
        mov qword [rsp+8*5], 150
        mov qword [rsp+8*6], 200
        mov qword [rsp+8*7], 50
        mov rbx, [main_hwnd]
        mov qword [rsp+8*8], rbx
        mov qword [rsp+8*9], rcx
        mov rbx, [hInst]
        mov [rsp+8*10], rbx
        mov [rsp+8*11], rcx
        call [CreateWindowEx]

        mov [ExitBtnHandle], rax

        add rsp, 8*8             ; free place in stack

        mov rdx, SW_SHOWNORMAL
        mov rcx, [main_hwnd]
        call [ShowWindow]

        mov rcx, [main_hwnd]
        call [UpdateWindow]

        mov rdx, SW_SHOWNORMAL
        mov rcx, [AboutBtnHandle]
        call [ShowWindow]

        mov rdx, SW_SHOWNORMAL
        mov rcx, [ExitBtnHandle]
        call [ShowWindow]

  msg_loop:
        xor r9, r9
        xor r8, r8
        xor rdx, rdx
        mov rcx, msg
        call  [GetMessage]

        cmp     rax,1
        jb      end_loop
        jne     msg_loop

        mov rcx,  msg
        call [TranslateMessage]
        mov rcx,  msg
        call [DispatchMessage]
        jmp     msg_loop

  end_loop:
        xor rcx, rcx
        call [ExitProcess]

proc WndProc hwnd, wmsg, wparam, lparam  ; proc macro contains prologue (push rbp; mov rbp, rsp) etc. 
        ;
        ; rdx = wmsg
        ; r8  = wparam
        ; r9  = lparam
        ; stack aligned! because code that calls WndProc, uses 16-byte aligned stack
        ; when call return addr (8bytes) pushed, and after that prologue of WndProc pushes (rbp)
        ; and stack becomes 16-byte aligned again
        sub rsp, 8*4  ;  alloc space for 4  parameters

        cmp rdx, WM_DESTROY
        je  .wmdestroy
        cmp rdx, WM_COMMAND
        jne .default
        mov rax, r8
        shr rax, 16
        cmp rax, BN_CLICKED
        jne .default
        cmp r9, [AboutBtnHandle]
        je  .about
        cmp r9, [ExitBtnHandle]
        je  .wmdestroy

.default:
        call [DefWindowProc]
        jmp .finish

.about:
        xor rcx, rcx
        mov rdx, AboutText
        mov r8, AboutTitle
        xor r9, r9
        call [MessageBox]
        jmp .finish

.wmdestroy:
        xor rcx, rcx
        call [ExitProcess]
.finish:
        add rsp, 8*4  ; restore stack
        ret
endp

section '.relocs' fixups readable writeable

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL'

  import kernel,\
         GetModuleHandle,'GetModuleHandleA',\
         ExitProcess,'ExitProcess'

  import user,\
         RegisterClass,'RegisterClassA',\
         CreateWindowEx,'CreateWindowExA',\
         DefWindowProc,'DefWindowProcA',\
         GetMessage,'GetMessageA',\
         TranslateMessage,'TranslateMessage',\
         DispatchMessage,'DispatchMessageA',\
         LoadCursor,'LoadCursorA',\
         LoadIcon,'LoadIconA',\
         ShowWindow,'ShowWindow',\
         UpdateWindow,'UpdateWindow',\
         MessageBox,'MessageBoxA'