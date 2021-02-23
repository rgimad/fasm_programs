;формат exe файла
format PE GUI 4.0
;точка входа программы
entry start
;включаем файлы API процедур (должна быть установлена переменная окружения "fasminc")
include '%fasminc%\win32a.inc'
;констант OpenGL
include 'include\opengl_const.inc'
;и макросов
include 'include\opengl_macros.inc'
;начало программы
start:
;обнулим ebx. Т.к. он не изменяется API процедурами то будем использывать push ebx вместо push 0, для оптимизации
xor ebx,ebx
;спрячим курсор
invoke ShowCursor,ebx
;поместим в стек 4-е "0" для процедуры "CreateWindowEx"
push ebx
push ebx
push ebx
push ebx
;получим текущее разрешение по вертикали
invoke GetSystemMetrics,SM_CYSCREEN
;поместим его в стек для процедуры "CreateWindowEx"
push eax
;и по горизонтали
invoke GetSystemMetrics,ebx
;и его в стек
push eax
;вычислим соотношение резрешений экрана по горизонтали и вертикали
fild dword [esp]
fidiv dword [esp+4]
;и сохраним его в ratio
fstp [ratio]
;создадим окно размером с экран с предопределенным классом "edit" (т.к. его регистрировать ненадо, то это позволяет избавиться от не нужного кода)
invoke CreateWindowEx,WS_EX_TOPMOST,szClass,szTitle,WS_VISIBLE+WS_POPUP,ebx,ebx
;получим контекст окна
invoke GetDC,eax
;сохраним его в ebp
xchg ebp,eax
;инициализируем дескриптор формата пикселей OpenGL (поддержку OpenGL и двойной буферизации)
mov [pfd.dwFlags],PFD_DRAW_TO_WINDOW+PFD_SUPPORT_OPENGL+PFD_DOUBLEBUFFER
;тип пикселей RedGreenBlueAlpha
mov [pfd.iPixelType],PFD_TYPE_RGBA
;глубину цвета
mov [pfd.cColorBits],32
;плоскость отображения
mov [pfd.dwLayerMask],PFD_MAIN_PLANE
;выберем его
invoke ChoosePixelFormat,ebp,pfd
;и установим его
invoke SetPixelFormat,ebp,eax,pfd
;преобразуем контекст окна в контекст OpenGL
invoke wglCreateContext,ebp
;и сделаем его текущим
invoke wglMakeCurrent,ebp,eax

;включим режим отсечения не лицевых граней (z-буфер)
invoke glEnable,GL_DEPTH_TEST
;включим источник света GL_LIGHT0 (используя значения по умолчанию)
invoke glEnable,GL_LIGHT0
;включим освещение
invoke glEnable,GL_LIGHTING
;включим изменение свойств материала взависимости от его цвета, иначе все будет тупо чернобелое
invoke glEnable,GL_COLOR_MATERIAL

;выберем режим вычисления перспективных преобразований (наилучший)
invoke glHint,GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST
;выберем для преобразований матрицу перспективной проекции
invoke glMatrixMode,GL_PROJECTION
;умножим ее на матрицу перспективы, т.е. попросту включим ее (используем макрос glcall т.к. параметры передаются в виде 8 байтов)
glcall gluPerspective,90.0,ratio,0.1,100.0
;выберем для преобразований матрицу изображения
invoke glMatrixMode,GL_MODELVIEW


;основной цикл
.draw:
;получаем текущее значение счетчика начала работы Windows (для синхронизации)
invoke GetTickCount
;сравним его с сохраненным значением
cmp eax,[msec]
;если оно не изменилось то ждем
jz .draw
;если значение поменялось сохраним его
mov [msec],eax
invoke glClear,GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT
;обнулим текущую матрицу (матрицу изображения)
invoke glLoadIdentity

;отодвинем объекты в глубь экрана
invoke glTranslatef, 0.0, 0.0, -1.5
;последовательно умножим матрицу изображения на матрицы поворота (повернем все объекты сцены на угол theta относительно векторов x,y,z соответственно)
invoke glRotatef,[theta], 1.0, 0.0, 0.0
invoke glRotatef,[theta], 0.0, 1.0, 0.0
invoke glRotatef,[theta], 0.0, 0.0, 1.0

invoke glBegin, GL_POLYGON
invoke glNormal3f, 0.0, -0.5, -0.5
invoke glColor3f, 1.0, 0.0, 0.0
invoke glVertex3f, 0.5, 0.5, -0.5       
invoke glVertex3f, 0.0, 0.0, 0.0     
invoke glVertex3f, -0.5, 0.5, -0.5      
invoke glEnd

invoke glBegin, GL_POLYGON
invoke glNormal3f, 0.0, 0.5, -0.5
invoke glColor3f, 1.0,  1.0, 0.0 
invoke glVertex3f, 0.5, 0.5, 0.5 
invoke glVertex3f, 0.0,  0.0, 0.0 
invoke glVertex3f, -0.5,  0.5, 0.5 
invoke glEnd

invoke glBegin, GL_POLYGON
invoke glNormal3f, 0.5, -0.5, 0.0
invoke glColor3f, 1.0,  0.5,  1.0
invoke glVertex3f, 0.5, 0.5, 0.5 
invoke glVertex3f, 0.0,  0.0, 0.0
invoke glVertex3f, 0.5,  0.5, -0.5
invoke glEnd


invoke glBegin, GL_POLYGON
invoke glNormal3f, 0.5, 0.5, 0.0
invoke glColor3f,  1.0,  0.0,  0.3 
invoke glVertex3f, -0.5, 0.5,  0.5 
invoke glVertex3f, 0.0,  0.0,  0.0 
invoke glVertex3f, -0.5,  0.5, -0.5 
invoke glEnd


invoke glBegin, GL_POLYGON
invoke glNormal3f, 0.0, 1.0, 0.0
invoke glColor3f, 0.8,  0.2,  0.0 
invoke glVertex3f, 0.5,  0.5,  0.5 
invoke glVertex3f, 0.5,  0.5, -0.5 
invoke glVertex3f, -0.5,  0.5, -0.5 
invoke glVertex3f, -0.5,  0.5,  0.5 
invoke glEnd


;отобразим буфер на экран
invoke SwapBuffers,ebp

;загрузим значение угла theta
fld [theta]
;увеличим его на значение delta
fadd [delta]
;и запишем обратно
fstp [theta]

;проверим на нажатие клавиши ESC
invoke GetAsyncKeyState,VK_ESCAPE
;если она не нажата
test eax,eax
;то продолжим цикл
jz .draw
;выход из программы
invoke ExitProcess,ebx
;заголовок окна
szTitle db 'OpenGL tutorial by Tyler Durden - Simple',0
;имя предопределенного класса окна
szClass db 'edit',0
;включим файл с описанием импорта
data import
include 'include\imports.inc'
end data
;описание ресурсов
data resource
directory RT_ICON,icons,RT_GROUP_ICON,group_icons
resource icons,1,LANG_NEUTRAL,icon_data
resource group_icons,1,LANG_NEUTRAL,icon
icon icon,icon_data,'resources\icons\simple.ico'
end data
;счетчик тиков таймера
msec dd ?
;угол поворота
theta dd ?
;значение приращения угла поворота
delta dd 0.3
;соотношение резрешений экрана по горизонтали и вертикали
ratio dq ?
;дескриптор пиксельного формата
pfd PIXELFORMATDESCRIPTOR