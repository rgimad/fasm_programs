org 7C00h  ; all the addresses of program will be calculated relative to 7C00h
use16  ; 16-bit code

cli  ; disable interrupts
; null segment registers
mov ax, 0
mov es, ax
mov ds, ax
mov ss, ax
mov sp, 7C00h  ; set up stack pointer (note: stack grows downwards)
sti  ; enable interrupts

mov ax, 0003h  ; set up videomode to show text
int 10h  ; call bios interrupt 10h

mov ax, 1301h  ; function number
mov bp, string1  ; string1 address
mov dx, 0000h  ; row and column where the text is outputed
mov cx, word [string1_len]  ; string1 length
mov bx, 000Eh  ; 00 - page number, 0E - font color and background color
int 10h

jmp $  ; its like infinite loop, jumps to itself

string1 db 'Hello World, MBR loaded!'  ; define our string
string1_len dw ($ - string1)  ; calculate string1 length
; now we need to fill up the program to 512 bytes
times 510 - ($ - $$) db 0  ; $ means address of current instruction, $$ there is 7C00h (cause in the beginning org 7C00h)
db 0x55, 0xAA  ; last two bytes must be these cause of magic