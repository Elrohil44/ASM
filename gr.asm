dane1 segment
;x1		dw 0
;y 		dw 0
ile 	db 0
arg		db 26 dup('a'),'$'
ddd		dw 0
nr		dw 0
nr2		db 1
znak	dw 11011001100b,11001101100b,11001100110b,10010011000b,10010001100b,10001001100b
		dw 10011001000b,10011000100b,10001100100b,11001001000b,11001000100b,11000100100b
		dw 10110011100b,10011011100b,10011001110b,10111001100b,10011101100b,10011100110b
		dw 11001110010b,11001011100b,11001001110b,11011100100b,11001110100b,11101101110b
		dw 11101001100b,11100101100b,11100100110b,11101100100b,11100110100b,11100110010b
		dw 11011011000b,11011000110b,11000110110b,10100011000b,10001011000b,10001000110b
		dw 10110001000b,10001101000b,10001100010b,11010001000b,11000101000b,11000100010b
		dw 10110111000b,10110001110b,10001101110b,10111011000b,10111000110b,10001110110b
		dw 11101110110b,11010001110b,11000101110b,11011101000b,11011100010b,11011101110b
		dw 11101011000b,11101000110b,11100010110b,11101101000b,11101100010b,11100011010b
		dw 11101111010b,11001000010b,11110001010b,10100110000b,10100001100b,10010110000b
		dw 10010000110b,10000101100b,10000100110b,10110010000b,10110000100b,10011010000b
		dw 10011000010b,10000110100b,10000110010b,11000010010b,11001010000b,11110111010b
		dw 11000010100b,10001111010b,10100111100b,10010111100b,10010011110b,10111100100b
		dw 10011110100b,10011110010b,11110100100b,11110010100b,11110010010b,11011011110b
		dw 11011110110b,11110110110b,10101111000b,10100011110b,10001011110b,10111101000b
		dw 10111100010b,11110101000b,11110100010b,10111011110b,10111101110b,11101011110b,11110101110b
aadt	db ?,'$','$'		
startB	dw 11010010000b
stop	dw 1100011101011b
err		db "Zla liczba znakow$"
valid2	db "Niepoprawne dane$"
suma	dw 104
x1		db 0
dane1 ends

code1 segment

start1:
		mov ax,seg stos1
		mov ss,ax
		mov sp,offset w_stosu
		
		
		xor cx,cx
		mov cl,byte ptr ds:[080h]
		dec cl
		cmp cl,0
		jbe error_mess
		cmp cl,24
		ja error_mess
		mov ax,seg dane1
		mov es,ax
		mov es:[ile],cl		
		mov si,082h
		mov di,offset arg
	pt:	push cx
		mov al,byte ptr ds:[si]
		mov byte ptr es:[di],al
		inc si
		inc di
		pop cx
		loop pt
		
		mov ax,seg dane1
		mov ds,ax
		xor cx,cx
		mov cl,ds:[ile]
		mov di,offset arg
		mov bx,104
	petla:
		xor ax,ax
		mov al,byte ptr ds:[di]
		cmp al,0
		jb invalid
		cmp al,135
		ja invalid
		cmp al,32
		jae tu
		
	tu:
		sub al,32
		push cx
		mov cl,ds:[nr2]
		mul cl
		pop cx
		;mov bx,ds:[suma]
		add bx,ax
		
		;and ax,1111111100000000b
		;push cx
		;mov cl,8
		;shr ax,cl
		;pop cx
		
		inc ds:[nr2]
		inc di
		loop petla
		mov ax,bx
		mov bl,103
		div bl
		mov al,ah
		mov ah,0
		;mov bx,ax
			mov ds:[suma],ax
			;xor ax,ax
			;mov di,1
			;mov di,offset arg
			;mov al,byte ptr ds:[di]
			;sub al,32
			;mul di
			;mov bl,4
			;div bl
			;mov ah,al
			;xor ah,ah
			;sub ax,1
			;mov ds:[suma],ax
			;mov ax,ds:[suma]
			;mov bl,103
			;div bl
			;mov al,ah
			;xor ah,ah
			;mov cl,8
			;and ax,1111111100000000b
			;mov ds:[suma],ax
		
		mov al,13h
		mov ah,00
		int 10h
		mov bx,0A000h
		mov es,bx
		call wybiel
		mov si,10
		mov di,ds:[startB]
		call rys_znak
		xor cx,cx
		mov cl,ds:[ile]
		add si,11
	rysuj:
		push cx
		push si
		mov cl,8
		mov di,ds:[nr]
		;lea di,arg
		;add di,ds:[nr]
		xor si,si
		mov si,word ptr ds:[arg + di]
		and si,0000000011111111b
		sub si,32
		mov cl,1
		shl si,cl
		;sub ax,32
		;shl ax,cl
		
		;mov si,2
		mov di,ds:[znak+si];word ptr ds:[znak+si]
		pop si
		call rys_znak
		inc ds:[nr]
		add si,11
		pop cx
		loop rysuj
		
		
		xor cx,cx
		mov cl,ds:[ile]
		dec cx
	
		mov ax,ds:[suma]
		push si
		mov si,ax
		push cx
		mov cl,1
		shl si,cl
		pop cx
		mov di,ds:[znak+si]
		pop si
		call rys_znak
		add si,11
		call blokko
	
	czekaj_ESC:
		;in al, 60h
		xor ax,ax
		int 16h
		cmp ah,1
		jne czekaj_ESC
		mov al,03h
		mov ah,00h
		int 10h
		mov ah,4ch
		int 21h
		
	czekaj:
		mov ah,0
		int 16h
		mov ah,4ch
		int 21h
	;-------------------------------------------------------------------	
	putline: push si
			 
	p1:	
		cmp si,0
		jb nic
		cmp si,64000
		jae nic
		mov es:[si],al
		add si,320
		jmp p1
	nic:
		pop si
		ret
	;---------------------------------------------------------------------
	wybiel:push cx
		push ax
		push si
		mov al,15
		mov cx,320
		mov si,0
	ff:	
		call putline
		inc si
		loop ff
		pop si
		pop ax
		pop cx
		ret
	;-------------------------------------------------------------------------------	
	error_mess:
		mov ax,seg dane1
		mov ds,ax
		mov ax,offset err
		mov dx,ax
		mov ah,9h
		int 21h
		mov ah,0
		int 16h
		mov ah,4ch
		int 21h
		;-----------------------------------------------------------
	invalid:
		mov ax,offset valid2
		mov dx,ax
		mov ah,9h
		int 21h
		mov ah,0
		int 16h
		mov ah,4ch
		int 21h
		
	;----------------------------------------------------------------
	rys_znak:
		push cx
		push si
		add si,11
		;mov di,ds:[nr]
		;xor ax,ax
		;mov al,byte ptr ds:[arg+di]
		;mov cl,1
		;shl ax,cl
		mov ds:[ddd],1b
		mov cx,11
		;sub ax,64
		;mov di,ds:[znak+ax]
		xor al,al
	linie:
		mov bx,di
		
		and bx,ds:[ddd]
		cmp bx,0
		je nie_rysuj
		call putline
	nie_rysuj:
		shl ds:[ddd],1
		dec si
		loop linie
	o:	pop si
		pop cx
		ret
	;---------------------------------------------------------------------	
	;blokst:
	;	push cx
	;	mov di,ds:[startB]
	;	add si,11
	;	mov cx,11
	;	xor al,al
	;	mov ds:[ddd],1b
	;linie2:	
	;	mov bx,di
	;	and bx,ds:[ddd]
	;	cmp bx,0b
	;	je nie_rysuj2
	;	call putline
	;	
	;nie_rysuj2:
	;	dec si
	;	shl ds:[ddd],1
	;	loop linie2
	;	pop cx
	;	ret
	;---------------------------------------------
	blokko:
		push cx
		mov di,ds:[stop]
		add si,13
		mov cx,13
		xor al,al
		mov ds:[ddd],1b
	linie3:
		mov bx,di
		and bx,ds:[ddd]
		cmp bx,0b
		je nie_rysuj3
		call putline
	nie_rysuj3:
		dec si
		shl ds:[ddd],1
		loop linie3
		pop cx
		ret
		
	
	
	
code1 ends

stos1 segment stack
	dw 255 dup(?)
w_stosu dw ?
stos1 ends

end start1