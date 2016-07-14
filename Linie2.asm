dane segment
czytam	db 255
		db 256 dup ('$')
pota	dw 1
signa	dw 1
a1re	dw 0
a1		dw 0
a2		db 8 dup ('$')
potb	dw 1
signb	dw 1
b1re 	dw 0
b1		dw 0
b2		db 8 dup ('$')
iloraz	dw 0
a		db 13,10,"a = $"
b		db 13,10,"b = $"
pot		dw 1
head	db "Jestem wysoce zaawansowanym programem do tworzenia wykresu funkcji liniowej$"
autor 	db "Autor: Wieslaw Stanek$"
header  db "Podaj wspolczynniki a i b$"
header2 db "do wzoru: y = ax + b",13,10,'$'
err1	db "Niepoprawne dane wejsciowe, [+|-]{0-9}[.][0-9] expected!",13,10
		db "Max/min liczba: +/- 3276.7",13,10
		db "Maksymalnie 1 miejsce po kropce!    Koniec - Press Q$"
OX		db 21 dup (" #"),">$"
skala	dw 1
bdivskala	dw ?,?
xzero	db "x = $"
skala2c	db 15 dup ('$')
skala2u	db 15 dup ('$')
uuu		dw 6
dze		dw 10
reszta	dw 0
calk	dw 0
dlcalk	dw 0
dot		db ".$"
testmsg	db 13,10,"Cyk$"
oo		db "Miejsce zerowe: $"
skalaa	db "Skala: # = $"
errorr	db 0
brak	db "Brak miejsc zerowych!$"
infi	db "Nieskonczenie wiele miejsc zerowych!$"
minus	db " - $"
czter	dw 8
dane ends

code segment

start1:
	mov ax, seg w_stosu
	mov ss,ax
	mov sp,offset w_stosu
	
	mov ax,seg czytam
	mov ds,ax
	mov ah, 0
	mov al, 3
	int 10h
h:	
	xor bx,bx
	mov ah,2
	mov dh,0
	mov dl,3
	int 10h
	mov dx, offset head
	mov ah,9h
	int 21h
	mov ah,2
	mov dh,1
	mov dl,29
	int 10h
	mov dx, offset autor
	mov ah,9h
	int 21h
	
	mov ah,2
	mov dh,3
	mov dl,27
	int 10h
	mov dx, offset header
	mov ah,9h
	int 21h
	mov ah,2
	mov dh,5
	mov dl,30
	int 10h
	mov dx, offset header2
	mov ah,9h
	int 21h
	mov dx, offset a
	mov ah,9h
	int 21h
again:
	mov ah,2
	mov dh,7
	mov dl,4
	int 10h
	
	mov dx, offset czytam
	mov ah,0Ah
	int 21h
	cmp byte ptr ds:[czytam+1],0
	je again
	mov bx, offset a1
	call ATOI
	
	
	xor bx,bx
	mov ax,00203h
	mov dh,8
	mov dl,0
	int 10h
	
	mov dx, offset b
	mov ah,9h
	int 21h
	xor bx,bx
again2:
	mov ax,00203h
	mov dh,9
	mov dl,4
	int 10h
	mov dx, offset czytam
	
	mov ah,0Ah
	int 21h
	cmp byte ptr ds:[czytam+1],0
	je again2
	
	mov bx, offset b1
	call ATOI
	
	xor dx,dx
	xor bx,bx
	call rysujosie
	call danee
return:
	call yodxp
	call yodxk
	mov bx,word ptr cs:[xp]
	cmp bx,word ptr cs:[xk]
	jne ehehe
	cmp word ptr ds:[signa],1
	je dwa
	mov word ptr cs:[yp],0
	dec word ptr cs:[xp]
	dec word ptr cs:[xk]
	inc word ptr cs:[yk]
	call prosta
	inc word ptr cs:[xp]
	inc word ptr cs:[xk]
	dec word ptr cs:[yk]				;Przypadki, gdy miałaby wyjsc pionowa linia, żeby widać było monotonicznosć i przecięcie z OY
	mov ah,2
	mov dh,byte ptr cs:[yk]
	mov dl,byte ptr cs:[xk]
	int 10h
	mov ah,9h
	mov cx,1
	xor dx,dx
	mov al,'*'
	mov bl,00001010b
	xor bh,bh
	int 10h
	inc word ptr cs:[xp]
	inc word ptr cs:[xk]
	dec word ptr cs:[yk]
	mov ax,word ptr cs:[yk]
	mov word ptr cs:[yp],ax
	mov word ptr cs:[yk],25
	call prosta
	jmp koniec
dwa:
	mov word ptr cs:[yp],25
	dec word ptr cs:[xp]
	dec word ptr cs:[xk]
	inc word ptr cs:[yk]
	call prosta
	inc word ptr cs:[xp]
	inc word ptr cs:[xk]
	dec word ptr cs:[yk]
	mov ah,2
	mov dh,byte ptr cs:[yk]
	mov dl,byte ptr cs:[xk]
	int 10h
	mov ah,9h
	mov cx,1
	mov al,'*'
	mov bl,00001010b
	xor bh,bh
	int 10h
	inc word ptr cs:[xp]
	inc word ptr cs:[xk]
	dec word ptr cs:[yk]
	mov ax,word ptr cs:[yk]
	mov word ptr cs:[yp],ax
	mov word ptr cs:[yk],0
	call prosta
	jmp koniec
ehehe:
	call prosta
	cmp word ptr cs:[xp],34
	jbe nast
	cmp word ptr cs:[yp],12
	jb ala
	cmp word ptr cs:[yp],25				;Jeżeli linia nie jest poprowadzona przez cały układ to ręcznie kreślimy jej pozostalosci
	je nast
	push word ptr cs:[yp]
	dec word ptr cs:[xp]
	push word ptr cs:[xk]
	push word ptr cs:[yk]
	mov ax,word ptr cs:[yp]
	inc ax
	mov word ptr cs:[yk],ax
	mov ax,word ptr cs:[xp]
	mov word ptr cs:[yp],25
	mov word ptr cs:[xk],ax
	call prosta
	pop word ptr cs:[yk]
	pop word ptr cs:[xk]
	pop word ptr cs:[yp]
	nast:
	cmp word ptr cs:[xk],74
	jae koniec
	cmp word ptr cs:[yk],0
	je koniec
	mov ax,word ptr cs:[yk]
	dec ax
	mov word ptr cs:[yp],ax
	inc word ptr cs:[xk]
	push word ptr cs:[xk]
	pop word ptr cs:[xp]
	mov word ptr cs:[yk],0
	call prosta
	jmp koniec
	ala:
	cmp word ptr cs:[xp],34
	jbe nast2
	cmp word ptr cs:[yk],25
	je nast2
	push word ptr cs:[yk]
	inc word ptr cs:[xk]
	push word ptr cs:[xp]
	push word ptr cs:[yp]
	mov ax,word ptr cs:[yk]
	inc ax
	mov word ptr cs:[yp],ax
	mov ax,word ptr cs:[xk]
	mov word ptr cs:[yk],25
	mov word ptr cs:[xp],ax
	call prosta
	pop word ptr cs:[yp]
	pop word ptr cs:[xp]
	pop word ptr cs:[yk]
	nast2:
	cmp word ptr cs:[xp],74
	jae koniec
	cmp word ptr cs:[yp],0
	je koniec
	mov ax,word ptr cs:[yp]
	dec ax
	mov word ptr cs:[yk],ax
	dec word ptr cs:[xp]
	push word ptr cs:[xp]
	pop word ptr cs:[xk]
	mov word ptr cs:[yp],0
	call prosta

koniec:
	mov ah,2
	mov dh,23
	mov dl,0
	int 10h
	xor ax,ax
	int 16h
	mov ah,04ch
	int 21h
	
ATOI:
	mov word ptr ds:[bx],0
	mov word ptr ds:[bx-2],0
	mov word ptr ds:[bx-4],1
	mov word ptr ds:[bx-6],1
	xor cx,cx
	mov cl,byte ptr ds:[czytam+1]
	mov si,2
	mov di,2
prz:
	mov al,byte ptr ds:[czytam+si]
	cmp al,' '
	je tutez
	mov byte ptr ds:[bx + di],al
	inc di
	jmp tylkosi
tutez:
	dec byte ptr ds:[czytam+1]
tylkosi:
	inc si
	
	loop prz
	xor cx,cx
	mov cl,byte ptr ds:[czytam+1]
	push cx
	mov di,2
	cmp byte ptr ds:[bx + di],'-'
	jne czyplus
	mov word ptr ds:[bx-4],-1
	inc di
	pop cx
	dec cx
	jz error1
	push cx
	jmp numbers
czyplus:
	mov word ptr ds:[bx-4],1
	cmp byte ptr ds:[bx + di],'+'
	jne numbers
	inc di
	pop cx
	dec cx
	jz error1
	push cx
numbers:
	pop cx
	cmp cx,2
	jbe krop
	dec cx
	dec cx
convert:
	xor ax,ax
	mov al,byte ptr ds:[bx+di]
	cmp al,'9'
	ja error1
	cmp al,'0'
	jb error1
	sub al,'0'
	push ax
	mov ax,word ptr ds:[bx]
	call mul10
	mov word ptr ds:[bx],ax
	pop ax
	xor ah,ah
	add word ptr ds:[bx],ax
	jo error1
	inc di
	loop convert
	inc cx
	inc cx
krop:
	cmp cx,1
	je last
	mov al,byte ptr ds:[bx+di]
	cmp al,'.'
	jne liczbamoze
	push ax
	mov ax,word ptr ds:[bx-6]
	call mul10
	mov word ptr ds:[bx-6],ax
	pop ax
	inc di
	jmp last
liczbamoze:
	cmp al,'9'
	ja error1
	cmp al,'0'
	jb error1
	sub al,'0'
	push ax
	mov ax,word ptr ds:[bx]
	call mul10
	mov word ptr ds:[bx],ax
	pop ax
	xor ah,ah
	add word ptr ds:[bx],ax
	jo error1
	inc di
last:
	mov al,byte ptr ds:[bx+di]
	cmp al,'9'
	ja error1
	cmp al,'0'
	jb error1
	sub al,'0'
	push ax
	mov ax,word ptr ds:[bx]
	call mul10
	mov word ptr ds:[bx],ax
	pop ax
	xor ah,ah
	add word ptr ds:[bx],ax
	jo error1
	mov ax,word ptr ds:[bx]
	xor dx,dx
	mov word ptr ds:[bx],ax
	mov word ptr ds:[bx-2],dx
	cmp word ptr ds:[bx],3276
	jbe goahead
	cmp word ptr ds:[bx-6],10
	jne error1
goahead:
	ret
	
error1:
	mov sp,offset w_stosu
	mov ah, 0
	mov al, 3
	int 10h
	xor bx,bx
	
	mov dl,0d
	mov dh,13d
	mov ah,2h
	int 10h
	mov dx,offset err1
	mov ah,9h
	int 21h
	xor ax,ax
	int 16h
	cmp ah,16
	je koniec
	jmp h

	
	
ITOA:
	
	call wydolar
	push ax
	push ax
	mov al,'0'
	mov byte ptr ds:[skala2c],al
	pop ax
plus:
	xor di,di
next:
	cmp ax,0
	je tru
tru3:
	push dx
	xor dx,dx
	div word ptr ds:[dze]
	mov ds:[reszta],dx
	mov ds:[calk],ax
	mov ax,ds:[reszta]
	add ax,'0'
	pop dx
	push ax
	mov ax,ds:[calk]
	inc di
	jmp next
tru:
	mov cx,di
	mov word ptr ds:[dlcalk],cx
	cmp cx,0
	je kon
kon2:
	xor di,di
bumum:
	pop ax
	mov ds:[skala2c+di],al
	inc di
	loop bumum
kon:
	pop ax
	call ulamk
	ret
	
ulamk:
	push ax
	push dx
	push cx
	mov byte ptr ds:[skala2u],'0'
	mov cx,7
	xor di,di
petla:
	mov ax,dx
	xor dx,dx
	call mul10v2
	div bx
	
	add al,'0'
	mov ds:[skala2u+di],al
	inc di
	loop petla
	pop cx
	pop dx
	pop ax
	ret
	
	
	
wydolar:
	push cx
	mov cx,15
	push si
	xor si,si
hehe:                                                          
	mov byte ptr ds:[skala2c+si],'$' 
	mov byte ptr ds:[skala2u+si],'$' 
	inc si
	loop hehe
	pop si
	pop cx
	ret
	
	
mul10:
	push bx
	push cx
	shl ax,1
	jo error1
	mov bx,ax
	shl bx,1
	jo error1
	shl bx,1
	jo error1
	add ax,bx
	jo error1
	pop cx
	pop bx
	ret
	
mul10v2:
	push bx
	push cx
	xor dx,dx
	shl ax,1
	mov bx,ax
	shl bx,1
	jnc took
	inc dx
took:
	
	shl dx,1
	shl bx,1
	jnc forward
	inc dx
forward:
	add ax,bx
	jnc tak
	inc dx
tak:
	pop cx
	pop bx
	ret

rysujosie:
	push dx
	push ax
	push cx
	push bx
	mov al,3
	mov ah,0
	int 10h
	
	mov dl,33d
	mov dh,12d
	mov ah,2h
	xor al,al
	int 10h
	
	mov dx,offset OX
	mov ah,9 
	int 21h
	mov ax,0b800h
	mov es,ax
	mov si,108
	mov byte ptr es:[si-2],'/'
	mov byte ptr es:[si+2],'\'
	mov cx,25
dalejzesz:
	mov byte ptr es:[si],'#'
	add si,160
	loop dalejzesz
	xor ax,ax
	int 16h
	pop bx
	pop cx
	pop ax
	pop dx
	ret
	

xp		dw ?
yp		dw ?
xk		dw ?
yk		dw ?
kolor 	db 00001010b
mx		dw ?
my		dw ?
rob		dw ?
dely	dw ?
di1		dw ?
d_i		dw ?
delx	dw ?

;------------------------------------
	
prosta:
push ax
push bx
push cx
push dx
	mov word ptr cs:[mx],2						;"Wartosc" jednego x i y
	mov word ptr cs:[my],160
	mov bx,word ptr cs:[xk]						;Wspolrzedne poczatkowe i koncowe
	sub bx,word ptr cs:[xp]
	mov ax,word ptr cs:[yk]
	sub ax,word ptr cs:[yp]
	jge delydod
	mov dx,ax
	neg dx
	cmp dx,bx
	jge p4
	jmp p2
delydod:
	cmp ax,bx									;algorytm bresenhama
	jge p3
p1:
	jmp create
p2:
	neg ax
	mov word ptr cs:[my],-160
	jmp create
p3:
	xchg ax,bx									;sprawdzam jakie sa katy, aby wiedziec jak zaczac rysowac
	mov word ptr cs:[my],2
	mov word ptr cs:[mx],160
	jmp create
p4:
	xchg ax,bx
	neg bx
	mov word ptr cs:[my],2
	mov word ptr cs:[mx],-160
create:
	mov word ptr cs:[dely],ax
	mov word ptr cs:[delx],bx
	shl ax,1
	sub ax,word ptr cs:[delx]
	mov word ptr cs:[d_i],ax
	mov ax,word ptr cs:[dely]
	sub ax,word ptr cs:[delx]
	mov bx,ax
	add ax,bx
	mov word ptr cs:[rob],ax
	mov ax,word ptr cs:[yp]
	mov cl,6
	shl ax,cl
	mov cx,ax
	shl ax,1
	shl ax,1
	add cx,ax
	sar cx,1
	add cx,word ptr cs:[xp]
	add cx,word ptr cs:[xp]
notu:
	cmp word ptr cs:[delx],0
	jl delxbelow0						;Jezeli d_i < 0 zmieniamy jedna wspolrzedna, wpp zmieniamy obie
	mov di,cx
	mov al,byte ptr cs:[kolor]
	mov byte ptr es:[di],'*'
	mov byte ptr es:[di+1],al
conti:
	cmp word ptr cs:[d_i],0
	jl d_ibelow0
	mov ax,word ptr cs:[d_i]
	add ax,word ptr cs:[rob]
	mov word ptr cs:[di1],ax
	mov ax,cx
	add ax,word ptr cs:[my]
	mov cx,ax
	jmp jump
d_ibelow0:
	mov ax,word ptr cs:[d_i]
	add ax,word ptr cs:[dely]
	add ax,word ptr cs:[dely]
	mov word ptr cs:[di1],ax
jump:
	mov ax,cx
	add ax,word ptr cs:[mx]
	mov cx,ax
	mov ax,word ptr cs:[di1]
	mov word ptr cs:[d_i],ax
	dec word ptr cs:[delx]
	jmp notu
delxbelow0:
	;xor ax,ax
	;int 16h
	pop dx
	pop cx
	pop bx
	pop ax
ret
	
danee:
	push ax
	push bx
	push cx
	push dx
	mov ax,word ptr ds:[b1]
	mov bx,word ptr ds:[a1]
	cmp bx,0
	je skippp
	xor dx,dx
	mov cx,word ptr ds:[pota]
	cmp word ptr ds:[potb],cx
	je skipp
	ja mula
	call mul10
	jmp skipp
mula:
	xchg ax,bx
	call mul10
	xchg ax,bx
	jmp skipp
skippp:
	push ax
	xor bx,bx
	mov ah,2
	mov dh,1
	mov dl,0
	int 10h
	xor bx,bx
	mov ah,9h
	mov dx,offset oo
	int 21h
	mov ah,2
	mov dh,1
	mov dl,17
	int 10h
	pop ax
	cmp ax,0
	je inf
	mov ah,9h
	mov dx,offset brak
	int 21h
	jmp skalalicz
inf:
	mov ah,9h
	mov dx,offset infi
	int 21h
	mov ax,0
	mov dx,ax
	jmp skalalicz
skipp:
	mov cx,bx
	shr cx,1
	xor dx,dx
	div bx
	mov word ptr ds:[iloraz],ax
	cmp cx,0
	je rey
	cmp dx,cx
	jb	rey
	inc word ptr ds:[iloraz]
rey:
	call ITOA
	xor bx,bx
	mov ah,2
	mov dh,1
	mov dl,0
	int 10h
	xor bx,bx
	mov ah,9h
	mov dx,offset oo
	int 21h
	xor bx,bx
	mov ah,2
	mov dh,1
	mov dl,17
	int 10h
	mov ah,9h
	mov dx,offset xzero
	int 21h
	mov cx,word ptr ds:[signa]
	cmp cx,word ptr ds:[signb]
	jne rys
	mov dx,offset minus
	int 21h
rys:
	mov dx,offset skala2c
	int 21h
	mov dx,offset dot
	int 21h
	mov dx,offset skala2u
	int 21h
skalalicz:
	xor dx,dx
	cmp word ptr ds:[iloraz],0
	jne szuk
	mov ax,word ptr ds:[b1]
	mov bx,word ptr ds:[uuu]
	cmp ax,0
	je malaska
	div bx
	jmp piszsk
malaska:
	;push ax
	mov ax,15				;gdy b=0 i a=0
	mov bx,10
	xor dx,dx
	jmp piszsk
szuk:
	mov ax,ds:[b1]
	xor dx,dx
	div word ptr ds:[potb]
	mov bx,ax
	xor dx,dx
	cmp word ptr ds:[iloraz],bx
	jb bskala
	mov ax,word ptr ds:[iloraz]
	mov bx,word ptr ds:[uuu]
	div bx
	jmp piszsk
bskala:
	mov ax,bx
	mov bx,word ptr ds:[uuu]
	xor dx,dx
	div bx
piszsk:
	inc ax
	xor dx,dx
	mov bx,1
	call ITOA
nodalej:
	mov word ptr ds:[skala],ax
	xor bx,bx
	mov ah,2
	mov dh,2
	mov dl,0
	int 10h
	xor bx,bx
	mov ah,9h
	mov dx,offset skalaa
	int 21h
	mov dx,offset skala2c
	int 21h
	mov dx,offset dot
	int 21h
	mov dx,offset skala2u
	int 21h
endfu:
	xor dx,dx
	mov ax,word ptr ds:[b1]
	div word ptr ds:[potb]
	mov bx,word ptr ds:[b1]
	cmp bx,1
	jbe forr
	shr bx,1
	cmp dx,bx
	jb forr
forr:
	xor dx,dx
	div word ptr ds:[skala]
	mov word ptr ds:[bdivskala],ax
	mov word ptr ds:[bdivskala+2],dx
	mov bx,word ptr ds:[skala]
	cmp bx,1
	jbe ending
	shr bx,1
	cmp word ptr ds:[bdivskala+2],bx
	jbe ending
	inc word ptr ds:[bdivskala]
ending:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	;jmp return
	
yodxp:
	mov word ptr cs:[xp], 11
tryagain:							;y = -10 * a + bdivskala
	dec word ptr cs:[xp]									
	mov ax, word ptr ds:[a1]
	mul word ptr cs:[xp]
	div word ptr ds:[pota]
	cmp word ptr ds:[signa],-1
	je tumtum
	neg ax
tumtum:
	cmp word ptr ds:[signb],1
	je tamtam
	sub ax,word ptr ds:[bdivskala]
	jo tryagain
	jmp cmpy
tamtam:
	add ax,word ptr ds:[bdivskala]
	jo tryagain
cmpy:
	cmp ax,13
	jg tryagain
	cmp ax,-13
	jl tryagain
	sub ax,12
	neg ax
	mov word ptr cs:[yp],ax
	mov ax,word ptr cs:[xp]
	shl ax,1
	sub ax,54
	neg ax
	mov word ptr cs:[xp],ax
	ret

yodxk:
	mov word ptr cs:[xk], 11
tryagain2:							;y = -10 * a + bdivskala
	dec word ptr cs:[xk]									
	mov ax, word ptr ds:[a1]
	mul word ptr cs:[xk]
	div word ptr ds:[pota]
	cmp word ptr ds:[signa],1
	je tumtum2
	neg ax
tumtum2:
	cmp word ptr ds:[signb],1
	je tamtam2
	sub ax,word ptr ds:[bdivskala]
	jo tryagain2
	jmp cmpy2
tamtam2:
	add ax,word ptr ds:[bdivskala]
	jo tryagain2
cmpy2:
	cmp ax,13
	jg tryagain2
	cmp ax,-13
	jl tryagain2
	sub ax,12
	neg ax
	mov word ptr cs:[yk],ax
	mov ax,word ptr cs:[xk]
	shl ax,1
	add ax,54
	mov word ptr cs:[xk],ax
	ret	
	
	
code ends



stos1 segment stack
		dw 256 dup (?)
testy	dw 20 dup (0)
testy2	dw 20 dup (0)
testy3	dw 20 dup (0)
w_stosu	dw ?
stos1 ends

end	start1