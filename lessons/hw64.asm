format PE64 Console 5.0   ; ���������� 64 ������ EXE ���������
entry main  ; ������ ����� ����� main
 
include 'win64a.inc'  ; ���������� ����������� �������
 
section '.text' code readable executable  ; ������ ���� ���������
 
main:  ; ����� main
 cinvoke printf, <"%s",10>, message  ; ������� ������ message � \n
 cinvoke getchar   ; ����� ���� �� ��������� �����, ���� �������
 invoke ExitProcess, 0  ; ������� �� ���������
 
section '.data' data readable writeable  ; ������ ������
 message db 'Hello World!',0  ; db �������� define byte. 
 
section '.idata' import data readable  ; ������ �������
 
 library msvcrt,'MSVCRT.DLL',\  ; ����� ����. ���������� �����
         kernel,'KERNEL32.DLL'
 
 import kernel,\  ; �� kernel32.dll ���������� ExitProcess
   ExitProcess, 'ExitProcess'

 import msvcrt,\  ; �� msvcrt.dll ����������� printf � getchar
   printf,'printf',\
   getchar,'getchar'