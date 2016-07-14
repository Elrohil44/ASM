dane segment
count	db 1,13,10,'$'
arg 	db 256 dup (0)
plik1	db 100 dup (0),'$'
dlplik	dw 7
raport	db "Raport z pliku o nazwie "
pl1		db 100 dup (0),'$'
entery	db ':',13,10,13,10,13,10
wart	db 13,10
wart2	db "000:",9
a		db 11 dup (0),0,'$'
plik2	db 100 dup (0),'$'
bajty	dw 512 dup (0)
buf		db 4096 dup('$')
len		dw 0,0
mess	db "Unknown error!$"
testa	db "test",10,13,'$'
dze		dw 10d
dz48	dw '0'
reszta	dw 0
calk	dw 0
reszta2 dw 0
Error2  db "File not found!$"
Error3  db "Path not found!$"
Error4  db "Too many open files!$"
Error5	db "Access denied or not accepted size (MAX 4GB)!$"
Error80	db "Destination file already exists!",13,10
		db "Sprawdz czy plik o skroconej nazwie juz nie istnieje",13,10
		db "(np. 123456789.txt zostaje skrocony do 12345678.txt",13,10
		db "tylko 8 znakow przed kropka)$"
warn	db "Niepotrzebne argumenty!",13,10,'$'
er		db "2 arguments expected!",13,10,'$'
chw		dw ?
dane ends

code segment

start1:
	mov ax, seg w_stosu
	mov ss,ax
	mov sp,offset w_stosu
	
	mov ax,seg buf
	mov es,ax
	xor cx,cx
	mov cl,byte ptr ds:[080h]
	cmp cl,0
	jbe sru
	dec cl
	
	xor di,di
	xor si,si
argi:
	mov al,byte ptr ds:[082h+si]
	mov byte ptr es:[arg+di], al
	cmp al,' '
	jne dalej
	inc byte ptr es:[count]
args:
	mov al,byte ptr ds:[082h+si+1]	;pomijamy wiele spacji
	cmp al,' '
	jne dalej
	inc si
	loop args
dalej:
	inc si
	inc di
	loop argi
sru:
	mov ax,seg buf
	mov ds,ax
	cmp byte ptr ds:[count],1
	je malo
	cmp byte ptr ds:[count],2
	je cont
	lea dx,ds:[warn]
	mov ah,9h
	int 21h
	jmp cont
malo:
	lea dx, ds:[er]
	mov ah,9h
	int 21h
	jmp here
cont:	
	
	
	call argumenty			;przepisujemy pierwsze 2 argumenty
	
	mov dx, offset plik1
	mov ax,3d00h			;otwieramy plik1
	int 21h
	jc error
	
	mov word ptr ds:[chw],ax			;zapisujemy uchwyt
	
	mov dx,offset plik2		;otwieramy drugi i sprawdzamy czy istnieje
	mov cx,0
	mov ah,05Bh
	int 21h
	jc error
	push ax
	
	 
	mov bx,word ptr ds:[chw]			;pobieramy uchwyt
	
	mov cx,0
	mov dx,0
	mov ax, 4202h			;idziemy na koniec pliku, wiemy wtedy jaka jest dlugość
	int 21h
	mov word ptr ds:[len], dx
	mov word ptr ds:[len+2],ax
	
	mov cx,0
	mov dx,0
	mov ax,4200h			;wracamy na początek
	int 21h
	
czytamy:
	mov dx,word ptr ds:[len]
	mov ax,word ptr ds:[len+2]
	cmp ax,0
	jne lul
	cmp dx,0
	je lel
lul:
	cmp dx,0
	ja tutaj2
	cmp ax,4096
	jb tutaj
tutaj2:
	mov dx, offset buf
	mov cx, 4096
	push cx
	mov ah,3fh						;wczytujemy 4kB do bufora
	int 21h
	pop cx
	mov di,0
	
ink:
	xor ax,ax
	mov al,byte ptr ds:[buf+di]
	mov si,ax
	shl si,1
	shl si,1
	inc word ptr ds:[bajty+si+2]	;inkrementujemy liczniki bajtów
	jnz jj1
	inc word ptr ds:[bajty+si]
jj1:
	inc di
	loop ink
	mov ax, word ptr ds:[len+2]
	push ax
	mov ax,4096
	mov word ptr ds:[reszta2],ax
	pop ax
	cmp ax,4096
	jae trutu
	push bx
	mov bx,4096
	sub bx,ax
	dec bx
	mov word ptr ds:[reszta2],bx
	pop bx
	mov ax,0FFFFh
	dec word ptr ds:[len]
trutu:
	sub ax,word ptr ds:[reszta2]
	mov word ptr ds:[len+2],ax
	jmp czytamy
tutaj:
	mov ax,word ptr ds:[len+2]
	mov cx,ax
	push cx
	mov dx, offset buf
	mov ah,3fh						;wczytujemy do bufora 4kB
	int 21h
	pop cx
	mov di,0
ink2:
	xor ax,ax
	mov al, byte ptr ds:[buf+di]	
	mov si,ax
	shl si,1
	shl si,1
	inc word ptr ds:[bajty+si+2]	;inkrementujemy liczniki bajtów
	jnz jj
	inc word ptr ds:[bajty+si]
jj:
	inc di
	loop ink2
lel:
	
	mov ah,3eh
	int 21h
	pop bx
	push bx
	mov dx,offset raport
	mov cx, 15
	mov ah,40h
	int 21h
	mov dx, offset pl1
	mov cx,word ptr ds:[dlplik]
	mov ah,40h
	int 21h
	mov dx, offset entery			;zapisujemy w pliku czołówkę
	mov cx,7
	mov ah,40h
	int 21h
	mov cx,256
	xor si,si
cre:
	push cx
	push si
	shl si,1
	shl si,1
	mov ax,word ptr ds:[bajty+si+2]		;w pętli wypisujemy wszystkie liczniki
	mov dx,word ptr ds:[bajty+si]
	call atoi
	pop si
	mov dx,offset wart
	mov cx,word ptr ds:[dlplik]
	add cx,7
	mov ah,40h
	int 21h
	pop cx
	inc si
	inc byte ptr ds:[wart2+2]
	cmp byte ptr ds:[wart2+2],'9'
	jbe bru
	mov byte ptr ds:[wart2+2],'0'
	inc byte ptr ds:[wart2+1]
	cmp byte ptr ds:[wart2+1],'9'
	jbe bru
	mov byte ptr ds:[wart2+1],'0'
	inc byte ptr ds:[wart2]
bru:
	loop cre
	pop bx
	mov ah,3eh							;zamykamy plik
	int 21h
	mov ah, 04ch
	int 21h
	
	
	
	
atoi:
	call wydolar
	push ax
	push ax							;liczba=DX:AX
	mov al,'0'
	mov byte ptr ds:[a],al
	pop ax
	xor di,di
next:
	cmp ax,0
	ja tru3
	cmp dx,0
	je tru
tru3:
	push dx
	xor dx,dx
	div word ptr ds:[dze]
	mov word ptr ds:[reszta],dx
	mov word ptr ds:[calk],ax
	pop dx
	mov ax,dx
	cmp dx,0
	jbe explosion
	xor dx,dx
	div word ptr ds:[dze]
	push ax
	mov ax,dx
	push cx
	mov cl,10
	shl ax,cl
	pop cx
	xor dx,dx
	div word ptr ds:[dze]
	push cx
	mov cl,6
	shl ax,cl
	add word ptr ds:[calk],ax
	mov ax,dx
	shl ax,cl
	pop cx
	xor dx,dx
	div word ptr ds:[dze]
	add word ptr ds:[calk],ax
	add word ptr ds:[reszta],dx
	pop dx
	push dx
	xor dx,dx
	mov ax, word ptr ds:[reszta]
	div word ptr ds:[dze]
	add word ptr ds:[calk],ax
	mov ax,dx
	pop dx
	add ax,'0'
	push ax
	mov ax,word ptr ds:[calk]
	inc di
	jmp next
explosion:
	add word ptr ds:[reszta],'0'
	mov ax, word ptr ds:[reszta]
	push ax
	mov ax,word ptr ds:[calk]
	inc di
	jmp next
tru:
	mov cx,di
	mov word ptr ds:[dlplik],cx
	cmp cx,0
	jne kon2
	inc word ptr ds:[dlplik]
	jmp kon
kon2:
	xor di,di
bumum:
	pop ax
	mov byte ptr ds:[a+di],al
	inc di
	loop bumum
kon:
	pop ax
	ret
	
wydolar:
	push cx
	mov cx,12
	push si
	xor si,si
hehe:
	mov byte ptr ds:[a+si],0
	inc si
	loop hehe
	pop si
	pop cx
	ret


argumenty: 
	xor si,si
	xor di,di
tu:
	mov al, byte ptr ds:[arg+si]
	mov byte ptr ds:[plik1+di],al
	mov byte ptr ds:[pl1+di],al
	inc si
	inc di
	mov al,byte ptr ds:[arg+si]
	cmp al,0
	je tu3
	cmp al,' '
	jne tu
	mov word ptr ds:[dlplik],si
	inc si
	xor di,di
tu2:
	mov al, byte ptr ds:[arg + si]
	mov byte ptr ds:[plik2 + di],al
	inc si
	inc di
	mov al, byte ptr ds:[arg + si]
	cmp al,0
	je tu3
	cmp al,' '
	jne tu2
tu3:
	ret
	
	
error:
	push ax
	xor dx,dx
	call atoi
	mov dx,offset a
	mov ah,9h
	int 21h
	pop ax
	cmp ax,2h
	jne e3
	mov dx,offset Error2
	mov ah,9h
	int 21h
	jmp here
e3:
	cmp ax,3
	jne e4
	mov dx,offset Error3
	mov ah,9h
	int 21h
	jmp here
e4:
	cmp ax,4
	jne e5
	mov dx,offset Error4
	mov ah,9h
	int 21h
	jmp here
e5:
	cmp ax,5
	jne e80
	mov dx,offset Error5
	mov ah,9h
	int 21h
	jmp here
e80:
	cmp ax,80
	jne ue
	mov dx,offset Error80
	mov ah,9h
	int 21h
	jmp here
ue: 
	mov dx,offset mess
	mov ah,9h
	int 21h
here:
	xor ax,ax
	int 16h
	mov ah, 04ch
	int 21h
	
piszt:
	push dx
	push ax
	mov dx,offset warn
	mov ah,9h
	int 21h
	mov ax,0
	int 16h
	pop ax
	pop dx
	ret
	
code ends



stos1 segment stack
		dw 256 dup (?)
w_stosu	dw ?
stos1 ends

end	start1