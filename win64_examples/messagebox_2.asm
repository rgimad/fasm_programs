format PE64 GUI 5.0
entry start
include 'win64a.inc'

section '.data' data readable writeable
text db 'Hello world!',0

section '.code' code readable executable
start:
        sub     rsp, 8 ; without this aligmnent it won't work. for MessageBoxA stack aligmnent is important
        invoke  MessageBoxA, 0, text, text, 0
        invoke  ExitProcess, 0

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL',\
        user32,'USER32.DLL'

import  kernel32,\
        ExitProcess, 'ExitProcess'

import  user32,\
        MessageBoxA,'MessageBoxA'