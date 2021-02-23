format PE64 Console 5.0   ; консольная 64 битная EXE программа
entry main  ; точкой входа будет main
 
include 'win64a.inc'  ; подключаем стандартные макросы
 
section '.text' code readable executable  ; секция кода программы
 
main:  ; метка main
 cinvoke printf, <"%s",10>, message  ; выводим строку message и \n
 cinvoke getchar   ; чтобы окно не закрылось сразу, ждем нажатия
 invoke ExitProcess, 0  ; выходим из программы
 
section '.data' data readable writeable  ; секция данных
 message db 'Hello World!',0  ; db означает define byte. 
 
section '.idata' import data readable  ; секция импорта
 
 library msvcrt,'MSVCRT.DLL',\  ; какие сист. библиотеки нужны
         kernel,'KERNEL32.DLL'
 
 import kernel,\  ; из kernel32.dll импорируем ExitProcess
   ExitProcess, 'ExitProcess'

 import msvcrt,\  ; из msvcrt.dll импортируем printf и getchar
   printf,'printf',\
   getchar,'getchar'