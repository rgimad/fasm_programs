format PE GUI 4.0
entry start
include 'win32a.inc'

  start:

        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,IDR_DIALOG,HWND_DESKTOP,DialogProc,0
  exit:
        invoke  ExitProcess,0

  proc  DialogProc hwnddlg,msg,wparam,lparam

        cmp     [msg],WM_INITDIALOG
        je      init
        cmp     [msg],WM_COMMAND
        je      wmcommand
        xor     eax,eax
        jmp     finish

  init:
        invoke  GetDlgItem,[hwnddlg],IDL_RESULTS
        mov     [hLB],eax
        invoke  GetDlgItem,[hwnddlg],IDB_STOP
        mov     [hStop],eax
        invoke  GetDlgItem,[hwnddlg],IDE_SCAN
        mov     [hScan],eax
        mov     eax,1
     ret

  wmcommand:
        mov     eax,[wparam]
        cmp     eax,IDCANCEL
        je      wmclose
        cmp     eax,IDB_START
        je      start_scan
        cmp     eax,IDB_STOP
        jz      stop_scan
        jmp     finish

  start_scan:

        invoke  GetDlgItemText,[hwnddlg],IDE_HOST,hostname,100
        invoke  GetDlgItemInt,[hwnddlg],IDE_BEGIN, result,0
        cmp     [result],0
        jnz     begin_success
        invoke  MessageBox,0,err_begin,err_capt,MB_ICONERROR + MB_OK
        jmp     finish

  begin_success:

        mov     [begin_port],eax
        invoke  GetDlgItemInt,[hwnddlg],IDE_END,result,0
        cmp     [result],0
        jnz     end_success
        invoke  MessageBox,0,err_end,err_capt,MB_ICONERROR + MB_OK
        jmp     finish

  end_success:

        mov     [end_port],eax
        invoke  EnableWindow,[hStop],1
        invoke  SendMessage,[hLB],LB_RESETCONTENT,0,0
        invoke  CreateThread,0,10000,Scan,0,0,ThreadId
        mov     [hThread],eax
        jmp     finish

  stop_scan:

        invoke  TerminateThread,[hThread],0
        invoke  GetDlgItem,[hwnddlg],IDB_STOP
        mov     [hStop],eax
        invoke  EnableWindow,eax,0
        jmp     finish

  wmclose:

        invoke  EndDialog,[hwnddlg],0

  processed:

        mov     eax,1

  finish:

        xor     eax,eax

     ret
  endp

;////////////////////////////////////////

  proc    Scan

        invoke  WSAStartup,0101h,wsadata
        test    eax,eax
        jz      wsa_ok
        invoke  MessageBox,0,wsa_err,err_capt,MB_ICONERROR

  wsa_ok:

        invoke  inet_addr,hostname
        cmp     eax,-1
        jnz     inet_ok
        invoke  gethostbyname,hostname
        test    eax,eax
        jnz     gethost_ok
        invoke  MessageBox,0,err_host,err_capt,MB_ICONERROR + MB_OK
        jmp     thread_exit

  gethost_ok:

        mov     eax,  [eax+HOSTENT_IP]
        mov     eax,  [eax]

  inet_ok:

        mov     [saddr.sin_addr],eax
        mov     [saddr.sin_family],AF_INET

  scan_loop:

        push    [begin_port]
        call    TestPort

        test    eax,eax
        jz      port_closed
        invoke  wsprintfA,output,format2,[begin_port]
        invoke  SendMessage,[hLB],LB_ADDSTRING,0,output

  port_closed:

        inc     [begin_port]
        mov     eax,[begin_port]
        cmp     [end_port],eax
        jae     scan_loop

  thread_exit:

        call    [WSACleanup]
        invoke  EnableWindow,[hStop],0
        invoke  SetWindowText,[hScan],szReady
        invoke  ExitThread,0
        ret     4
  endp

;///////////////////////////////////////////////

  proc TestPort   port:dword

        mov     eax,[port]
        invoke  wsprintf,szPort,format1,eax
        invoke  SetWindowText,[hScan], szPort

        invoke  socket,AF_INET,SOCK_STREAM,0
        cmp     eax,SOCKET_ERR
        je      close_sock
        mov     [socet],eax
        cmp     eax,-1
        jz      close_sock

        invoke  htons,[port]
        mov     [saddr.sin_port],ax
        invoke  connect,[socet],saddr,sizeof.sockaddr_in
        mov     ebx,1
        cmp     ax,SOCKET_ERR
        jnz     no_error
        mov     ebx,0

  no_error:

        push    ebx

  close_sock:

        invoke  closesocket,[socet]
        pop     eax

  proc_exit:

       ret
   endp

;//////////////////////////////////

  wsadata         WSADATA
  saddr           sockaddr_in
  HOSTENT_IP      = 10h
  SOCKET_ERR      = -1

;//////////////////////////////////

section '.rsrc' resource data readable


directory RT_DIALOG,dialogs

  resource dialogs,\
           IDR_DIALOG,LANG_ENGLISH+SUBLANG_DEFAULT,main

  dialog main, 'SCANER v 1.0',250,150,194,195, WS_CAPTION+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'LISTBOX','',IDL_RESULTS,8,84,177,103,LBS_HASSTRINGS+WS_VSCROLL+WS_TABSTOP+WS_EX_CLIENTEDGE+WS_VISIBLE
    dialogitem 'BUTTON','E&xit',IDCANCEL,137,50,42,11,BS_PUSHBUTTON+WS_VISIBLE
    dialogitem 'BUTTON','&Start',IDB_START,137,13,42,11,BS_PUSHBUTTON+WS_VISIBLE
    dialogitem 'BUTTON','S&top',IDB_STOP,137,32,42,11,BS_PUSHBUTTON+WS_VISIBLE+WS_DISABLED
    dialogitem 'STATIC','Host',-1,3,12,20,8,WS_VISIBLE
    dialogitem 'EDIT','',IDE_HOST,26,13,83,12,WS_EX_CLIENTEDGE+WS_VISIBLE+WS_BORDER
    dialogitem 'STATIC','Begin',-1,3,33,20,8,WS_VISIBLE
    dialogitem 'EDIT','',IDE_BEGIN,26,33,28,12,WS_EX_CLIENTEDGE+WS_VISIBLE+WS_BORDER+ES_NUMBER+WS_TABSTOP
    dialogitem 'STATIC','End',-1,65,33,20,8,WS_VISIBLE
    dialogitem 'EDIT','',IDE_END,82,33,28,12,WS_EX_CLIENTEDGE+WS_VISIBLE+WS_BORDER+ES_NUMBER+WS_TABSTOP
    dialogitem 'STATIC','Scaning',-1,3,55,28,11,WS_VISIBLE
    dialogitem 'EDIT','',IDE_SCAN,45,55,42,12,WS_EX_CLIENTEDGE+WS_VISIBLE+WS_BORDER+ES_READONLY+WS_DISABLED
  enddialog

  IDR_DIALOG      = 37
  IDE_HOST        = 1002
  IDE_BEGIN       = 1004
  IDE_END         = 1006
  IDL_RESULTS     = 1008
  IDB_START       = 1009
  IDB_STOP        = 1010
  IDE_SCAN        = 1012

  hLB             dd      ?
  hStop           dd      ?
  hScan           dd      ?
  result          dd      ?
  begin_port      dd      ?
  end_port        dd      ?
  ThreadId        dd      ?
  hThread         dd      ?
  socet           dd      ?

  hostname        db      100 dup(?)
  szPort          db      7 dup(?)
  output          db      256 dup(?)
  err_capt        db      "Error",0
  err_begin       db      "Begin port is not a number",0
  err_end         db      "End port is not a number",0
  wsa_err         db      "WSAStartup failure",0
  err_host        db      "Invalid host",0
  szReady         db      "DONE",0
  format2         db      '%d -port is open',0
  format1         db      '%d',0

;//////////////////////For Hackerpro.net ///////////////////////////

section '.idata' import data readable writeable
 library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',\
          wsock32,'WSOCK32.DLL'

  include 'api/kernel32.inc'
  include 'api/user32.inc'
  include 'api/wsock32.inc'