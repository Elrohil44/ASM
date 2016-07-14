dane1 segment
	kolor	db 13
	yy		dw 0
	xx		dw 0
	x		dw 0
	y 		dw 0
dane1 ends

code1 segment
assume ds:dane1
start1:
	mov ax,seg stos1
	mov ss, ax
	mov sp,offset w_stosu
	mov ah,00
	mov al, 13h
	int 10h
	mov cl,200
p1: push cx
	mov cx,320
p2: push cx	
	call putpixel
	inc xx
	pop cx
	loop p2
	inc yy
	sub xx,320
	pop cx
	loop p1
	;mov cx,16000
	;mov al,kolor
	;mov bl,al
	;mov ah,al
	;shl eax,16
	;mov al,bl
	;mov ah,al
	;mov bx, 0A000h
	;mov es,bx
	;xor di,di
	;cld
	;rep stosd
	mov ah,4ch
	int 21h
	
	putpixel:
        mov ax, 0A000H
		mov es,ax
		MOV Ax,yy      ; do AX pozycje Y pixela
        CMP Ax,0           ; jeśli AX mniejsze od 0
        JL putpixel_end    ; to skocz do etykiety nie_rysuj
        CMP Ax,200         ; jeśli AX większe lub równe 200
        JAE putpixel_end   ; to skocz do etykiety nie_rysuj
        MOV BX,xx         ; do BX pozycje X pixela
        CMP bx,0           ; jeśli BX mniejsze od 0
        JL putpixel_end    ; to skocz do etykiety nie_rysuj
        CMP bx,320         ; jeśli BX większe lub równe 320
        JAE putpixel_end   ; to skocz do etykiety nie_rysuj
        mov di,320
		mul di
		add ax,xx
		mov di,ax
		mov al,kolor
		mov byte ptr es:[di],al
		ret
putpixel_end:              ; koncowa etykieta
code1 ends

stos1 segment stack
			dw 200 dup(?)
	w_stosu dw ?
stos1 ends

end start1