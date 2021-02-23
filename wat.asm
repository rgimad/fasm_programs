; wat, the coreutils spin off of cat, for Windows.

Format PE Console
include 'win32a.inc'
entry start

section '.data' data readable writable
szMsgHelp db "Usage: wat [filename]", 0xA, 0
szFile db "%s", 0xA, 0

section '.bss' readable writable
nSizeOfFile dd ?
hFile dd ?
lpBytesRead dd ?
hHeap dd ?
pHeapData dd ?
nArgc dd ?
cArgv dd ?
cEnv dd ?
sInfo STARTUPINFO

section '.text' code readable writable executable
showHelp:
        cinvoke printf, szMsgHelp
        invoke ExitProcess, 0
start:

        cinvoke __getmainargs, nArgc, cArgv, cEnv, 0, sInfo
        cmp [nArgc], 2 ; Must have 2 arguments
        jne showHelp

        mov eax, [cArgv]
        mov eax, [eax]
        cinvoke strlen, eax ; Length of first argument
        inc eax ; Add 1 byte for null (0x00) at the end of the first string
        add ecx, eax ; Points to second arguemnt string

        invoke CreateFile, ecx, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        mov [hFile], eax
        invoke GetFileSize, [hFile], 0
        inc eax ; We need +1 Byte (0x00) for newline
        mov [nSizeOfFile], eax
        invoke GetProcessHeap ; Create a heap for our file's contents
        mov [hHeap], eax
        invoke HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, [nSizeOfFile]
        mov [pHeapData], eax
        invoke ReadFile, [hFile], [pHeapData], [nSizeOfFile], lpBytesRead, 0 ; Read data from our heap

        cinvoke printf, szFile, [pHeapData]
        invoke HeapFree, [hHeap] ; No memory leaks
        invoke ExitProcess, 0


section '.idata' import readable writable
library kernel32, 'kernel32.dll',\
        msvcrt, 'msvcrt.dll'

include 'api\kernel32.inc'
import msvcrt,\
       printf, 'printf',\
       __getmainargs, '__getmainargs',\
       strlen, 'strlen'
