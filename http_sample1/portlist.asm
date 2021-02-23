format   pe console
entry    start
include 'win32ax.inc'
;----------
struct servent          ;// getservbyport (port, *proto)
   s_name       dd  0      ; ëèíê íà ñòðîêó ñ èìåíåì ñåðâèñà
   s_aliases    dd  0      ; ëèíê íà NULL-ìàññèâ àëüòåðíàòèâíûõ èì¸í
   s_port       dw  0      ; íîìåð ïîðòà
   s_zero       dw  0      ; ðåçåðâ
   s_proto      dd  0      ; ëèíê íà ñòðîêó ñ èìåíåì ïðîòîêîëà
ends 
;----------
.data
wsa        WSADATA
sPort      servent
wsaInfo    db  13,10,' %s         %s'
           db  13,10,' Sockets count.....: %d'
           db  13,10,' UDP-datagramm size: %d',0
hName      db  13,10,' Host name.........: %s',0
capt       db  13,10
           db  13,10,' Enum Host Port-name v0.1'
           db  13,10,' ============================',0
mes0       db  13,10,' Port  %05d  %s - %s',0
mesEnd     db  13,10,' ============================'
           db  13,10,' Total: %d ports',13,10,0
buff       db  64 dup(0)
count      dd  0
frmt       db  '%s',0
;----------
.code
start:
;// инициализация библиотеки WinSock, и вывод инфы о ней
         invoke  WSAStartup,0x0101,wsa       ;
         push    0 0                         ; обнулить регистры
         pop     ecx edx                     ; ^^^
         mov     eax,wsa.szDescription       ; версия WinSock
         mov     ebx,wsa.szSystemStatus      ; текущий статус
         mov     cx,[wsa.iMaxSockets]        ; всего сокетов в резерве
         mov     dx,[wsa.iMaxUdpDg]          ; макс.размер UDP-датаграммы
        cinvoke  printf,wsaInfo,eax,ebx,ecx,edx   ; выводим шапку

;// Получить имя своего узла
         invoke  gethostname,buff,64
        cinvoke  printf,hName,buff

;// Начало сканирования зарегистрированных портов
        cinvoke  printf,frmt,capt         ; выводим шапку
         mov     ecx,0xffff               ; всего портов 65535 (word)
         xor     eax,eax                  ; начинать с нулевого
@scan:   push    eax ecx                  ; запомнить номер порта и счётчик!
         invoke  htons,eax                ; переводим #порта в сетевой порядок (..s это Short)
         invoke  getservbyport,eax,0      ; заполняем структуру "servent" по номеру порта
         or      eax,eax                  ; если EAX=0 значит ошибка
         jz      @fuck                    ; пропустить..
         inc     [count]                  ; иначе: "servent" заполнена, и счётчик найденых +1
         xor     ebx,ebx                  ; очистить EBX (в EAX сейчас лежит указатель на "servent")
         mov     bx,word[eax+8]           ; BX = номер порта из структуры "servent"
         xchg    bh,bl                    ; поменять байты местами (из Net в Hex порядок)
         mov     edx,[eax+12]             ; EDX = указатель на имя протокола
         mov     ecx,[eax]                ; ECX = указатель на имя связанного с портом сервиса
        cinvoke  printf,mes0,ebx,edx,ecx  ; выводим инфу порта на экран
@fuck:   pop     ecx eax                  ; порт и счётчик на родину!
         inc     eax                      ; следующий номер порта..
         dec     ecx                      ; счётчик -1
         jnz     @scan                    ; повторить, если счётчик не нуль

;// Выводим кол-во найденных портов
        cinvoke  printf,mesEnd,[count]    ;
        cinvoke  scanf,frmt,frmt+5        ; ждём нажатия клавиши..
         invoke  ExitProcess,0            ; на выход!

;//--- Cекция импорта программы  ------
section '.idata' import data readable   ;
library  kernel32,'kernel32.dll',\      ; импортируемые библиотеки
         wsock32,'wsock32.dll',\        ;
         msvcrt,'msvcrt.dll'            ;
import   msvcrt,printf,'printf',scanf,'scanf'  ; эту FASM не знает, опишем вручную

include 'api\kernel32.inc'         ; остальные функции есть в инклудах фасма.
include 'api\wsock32.inc'          ;