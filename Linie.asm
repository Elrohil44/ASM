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
err1	db "Niepoprawne dane wejsciowe, [+|-]{0-9}[.][0-9] expected!",13,10,"Maksymalnie 7 znakow!"
		db "Max/min liczba: +/- 3276.7",13,10
		db "Maksymalnie 1 miejsce po kropce!$"
OX		db 25 dup ("# "),">$"
skala	dw 1
skala2c	db 15 dup ('$')
skala2u	db 15 dup ('$')
uuu		dw 12
dze		dw 10
reszta	dw 0
calk	dw 0
dlcalk	dw 0
dot		db ".$"
testmsg	db 13,10,"Cyk$"
oo		db "Miejsce zerowe: $"
skalaa	db "Skala: # = "
errorr	db 0
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
	
	mov ax,word ptr ds:[a1]
	mov bx,word ptr ds:[b1]
	cmp ax,0
	jne dziel
	cmp bx,3276
	ja foll
	mov ax,word ptr ds:[a1re]
	push ax
	mov ax,bx
	call mul10
	mov bx,ax
	pop ax
	add bx,word ptr ds:[b1re]
	
	cmp bx,0
	je foll
	cmp ax,0
	je foll
	jmp cont
dziel:
	cmp bx,0
	jne cont
	cmp ax,3276
	ja foll
	mov bx, word ptr ds:[b1re]
	call mul10
	add ax,word ptr ds:[a1re]
	cmp ax,0
	je foll
cont:
	push ax
	mov ax,bx
	pop bx
	idiv bx
	jns foll1
	neg ax
foll1:
	test dx,dx
	jns yu
	neg dx
yu:
	call ITOA
	push ax
	push dx
	mov ah,9h
	mov dx, offset skala2c
	int 21h
	mov dx, offset dot
	int 21h
	mov dx, offset skala2u
	int 21h
	xor ax,ax
	int 16h
	pop dx
	pop ax
	mov word ptr ds:[iloraz],ax
foll:	
	cmp word ptr ds:[iloraz],0
	jne max	
	cmp word ptr ds:[a1],0
	jne bzero
;	cmp 
	mov word ptr cs:[xp],29
	mov word ptr cs:[yp],24
	mov word ptr cs:[xk],79
	mov word ptr cs:[yk],0
	cmp word ptr ds:[signa],1
	je ry
	mov word ptr cs:[yp],0
	mov word ptr cs:[yk],24
ry:
	call prosta
	call danee
bzero:
	jmp koniec				; ------------------- niedokonczone
	
max:
	mov word ptr ds:[pot],1
	test bx,bx
	jns rown
	neg bx
	mov word ptr ds:[pot],-1
rown:
	cmp word ptr ds:[iloraz],bx
	ja zerowe
zerowe:
	xor dx,dx
	push bx
	mov bx,word ptr ds:[uuu]
	idiv bx
	call ITOA
	pop bx

koniec:
	xor ax,ax
	int 16h
	mov ah,04ch
	int 21h
	
ATOI:
	mov word ptr ds:[bx],0
	mov word ptr ds:[bx-2],0
	mov word ptr ds:[bx-4],1
	mov word ptr ds:[bx-6],1
	cmp ds:[czytam+1],7
	ja error1
	xor cx,cx
	mov cl,ds:[czytam+1]
	push cx
	mov si,2
	mov di,2
prz:
	mov al,byte ptr ds:[czytam+si]
	mov byte ptr ds:[bx + di],al
	inc si
	inc di
	loop prz
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
	jb goahead
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
	jmp h

	
	
ITOA:
	
	call wydolar
	push ax
	push ax
	mov al,'0'
	mov byte ptr ds:[skala2c],al
	pop ax
	test ax,ax
	jns plus
	neg ax
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
	;push bx
	;mov bx,5
	;mul bx
	;pop bx
	;div bx
	;shl dx,1
	;shl ax,1
	;cmp dx,bx
	;jb ok
	;sub dx,bx
	;inc ax
	call mul10
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
	

pisztest:
	push ax
	push dx
	mov dx,offset testmsg
	mov ah,9h
	int 21h
	xor ax,ax
	int 16h
	pop dx
	pop ax
	ret

rysujosie:
	push dx
	push ax
	push cx
	push bx
	mov al,3
	mov ah,0
	int 10h
	
	mov dl,29d
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
;flag	dw 0

;------------------------------------
	
prosta:
push ax
push bx
push cx
push dx
	mov word ptr cs:[mx],2
	mov word ptr cs:[my],160
	mov bx,word ptr cs:[xk]
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
	cmp ax,bx
	jge p3
p1:
	jmp create
p2:
	neg ax
	mov word ptr cs:[my],-160
	jmp create
p3:
	xchg ax,bx
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
	jl delxbelow0
	mov di,cx
	;cmp word ptr cs:[flag],0
	;jne skip
	mov al,byte ptr cs:[kolor]
	mov byte ptr es:[di],'+'
	mov byte ptr es:[di+1],al
	skip:
	;mov word ptr cs:[flag],0
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
	;mov word ptr cs:[flag], 1
jump:
	mov ax,cx
	add ax,word ptr cs:[mx]
	mov cx,ax
	mov ax,word ptr cs:[di1]
	mov word ptr cs:[d_i],ax
	dec word ptr cs:[delx]
	jmp notu
delxbelow0:
	xor ax,ax
	int 16h
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
	xor dx,dx
	div bx
	mov cx,word ptr ds:[a1-6]
	cmp word ptr ds:[b1-6],cx
	je skipp
	jb divi
	push dx
	mul word ptr ds:[a1-6]
	pop dx
	push ax
	mov ax,dx
	mul word ptr ds:[a1-6]
	cmp ax,bx
	jb todobrze
	push dx
	xor dx,dx
	div bx
	pop cx
	
todobrze:	
divi:
	
skipp:
	
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
	
	
	
	
	
	
code ends



stos1 segment stack
		dw 256 dup (?)
w_stosu	dw ?
stos1 ends

end	start1