dane1 segment
ile 	db 0
arg		db 266 dup('$')
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
		dw 10110111000b,10110001110b,10001101110b,10111011000b,10111000110b,10001110110b							;tablica wzorów dla poszczególnych znaków, 1 - czarna linia, 0 - biała linia
		dw 11101110110b,11010001110b,11000101110b,11011101000b,11011100010b,11011101110b
		dw 11101011000b,11101000110b,11100010110b,11101101000b,11101100010b,11100011010b
		dw 11101111010b,11001000010b,11110001010b,10100110000b,10100001100b,10010110000b
		dw 10010000110b,10000101100b,10000100110b,10110010000b,10110000100b,10011010000b
		dw 10011000010b,10000110100b,10000110010b,11000010010b,11001010000b,11110111010b
		dw 11000010100b,10001111010b,10100111100b,10010111100b,10010011110b,10111100100b
		dw 10011110100b,10011110010b,11110100100b,11110010100b,11110010010b,11011011110b
		dw 11011110110b,11110110110b,10101111000b,10100011110b,10001011110b,10111101000b
		dw 10111100010b,11110101000b,11110100010b,10111011110b,10111101110b,11101011110b,11110101110b		
startB	dw 11010010000b
stop	dw 1100011101011b
err		db "Zla liczba znakow$"
valid2	db "Niepoprawne dane$"
suma	dw 104
dane1 ends

code1 segment

start1:
		mov ax,seg stos1														;Inicjacja stosu
		mov ss,ax
		mov sp,offset w_stosu
		
		
		xor cx,cx
		mov cl,byte ptr ds:[080h]												;ds:[080h] - ile znaków w argumentach wywołania programu
		dec cl																	;Pomniejszamy o 1, ostatni znak - znak specjalny
		cmp cl,0
		jbe error_mess															;Maksymalna liczba znaków to 24 (320 - 20 - 22 - 13)/11 == 265/11 == 24,...
		cmp cl,24
		ja error_mess
		mov ax,seg dane1
		mov es,ax
		mov byte ptr es:[ile],cl												;Przepisujemy ile jest znaków, będzie później potrzebne
		mov si,082h																;Rozpoczynamy przepisywanie argumentów do naszego segmentu danych
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
		mov cl,byte ptr ds:[ile]
		mov di,offset arg
		mov bx,104
	petla:
		push cx
		xor ax,ax
		mov al,byte ptr ds:[di]													;Liczymy sumę kontrolną i sprawdzamy jednocześnie czy znaki są obsługiwane
		cmp al,32
		jb invalid
		cmp al,126
		ja invalid
		sub al,32
		mov cl,byte ptr ds:[nr2]
		mul cl
		add bx,ax
		mov ax,bx
		mov bl,103
		div bl
		mov al,ah
		mov ah,0
		mov bx,ax
		inc ds:[nr2]
		inc di
		pop cx
		loop petla
		mov ax,bx
		mov bl,103
		div bl
		mov al,ah
		mov ah,0
		mov word ptr ds:[suma],ax												;Zapisujemy sumę w odpowiednim miejscu
		
		mov al,13h																; Włączamy tryb 13h karty graficznej za pomocą funkcji 00 przerwania 10h
		mov ah,00
		int 10h
		mov ax,0A000h															;Początek pamięci obrazu, każdy bajt opisuje jeden piksel
		mov es,ax																;Współrzędne (x,y) 0A000h + 320 * y + x
		call wybiel																;Malujemy ekran na biało
		mov al,byte ptr ds:[ile]
		mov bl,11
		mul bl
		add ax,35
		mov bx,ax
		mov ax,320
		sub ax,bx
		mov cl,1
		shr ax,cl
		mov si,ax																;SI - wskazuje nam współrzędną x obrazu, Kod wyśrodkowany
		mov di,word ptr ds:[startB]												;Rysujemy blok startu
		call rys_znak
		xor cx,cx
		mov cl,byte ptr ds:[ile]												;W ds:[ile] przechowujemy liczbę znaków do zakodowania, tyle będzie też przebiegów pętli
	rysuj:
		push cx
		push si
		lea di,arg
		add di,ds:[nr]
		xor si,si
		mov si,word ptr ds:[di]													;Aby załadować bajt do rejestru SI, stosuję maskę 00FFh
		and si,00FFh
		sub si,32
		mov cl,1
		shl si,cl
		mov di,word ptr ds:[znak+si]											;SI - przesunięcie w adresie logicznym względem offsetu znak
		pop si
		call rys_znak
		inc ds:[nr]
		pop cx
		loop rysuj
	
		mov ax,word ptr ds:[suma]
		push si
		mov si,ax
		mov cl,1
		shl si,cl
		mov di,word ptr ds:[znak+si]
		pop si
		call rys_znak															;Rysujemy blok końcowy
		call blokko
	
	czekaj_ESC:
		xor ax,ax																;AX=0, stosujemy przerwanie 16h z funkcją 0
		int 16h
		cmp ah,1																;Odczytujemy kod klawisza, ESC - 1, jeżeli to nie ESC to czekamy
		jne czekaj_ESC
		mov al,03h																;Wychodzimy z trybu graficznego
		mov ah,00h
		int 10h
		mov ah,4ch																;Wychodzimy
		int 21h
		
	czekaj:
		mov ah,0
		int 16h
		mov ah,4ch
		int 21h
	;-------------------------------------------------------------------	
	putline: push si
			 
	p1:	
		cmp si,0																;Sprawdzamy czy przypadkowo nie wyszliśmy poza obszar pamięci obrazu
		jb nic																	;Warunek końca pętli
		cmp si,64000
		jae nic
		mov byte ptr es:[si],bl													;BL - wartość koloru, 0 - czarny, 15 - biały
		add si,320																;zmieniamy tylko współrzędną y, aby narysować pionową linię
		jmp p1																	;brzydka pętla
	nic:
		pop si
		ret
	;---------------------------------------------------------------------
	wybiel:push cx
		push bx
		push si
		mov bl,15
		mov cx,320
		mov si,0
	ff:	
		call putline
		inc si
		loop ff
		pop si
		pop bx
		pop cx
		ret
	;-------------------------------------------------------------------------------	
	error_mess:
		mov ax,seg dane1														;Wypisany zostanie ciąg znaków od DS:DX
		mov ds,ax
		mov ax,offset err
		mov dx,ax
		mov ah,9h
		int 21h
		jmp czekaj
		;-----------------------------------------------------------
	invalid:
		mov ax,offset valid2
		mov dx,ax
		mov ah,9h
		int 21h
		jmp czekaj
		
	;----------------------------------------------------------------
	rys_znak:
		push cx
		mov word ptr ds:[ddd],10000000000b
		mov cx,11
		xor bl,bl																;BL ustawiamy na 0 - kolor czarny
	linie:
		mov ax,di
		
		and ax,word ptr ds:[ddd]												;Za pomocą odpowiedniej maski w każdym z 11 przebiegów pętli sprawdzamy czy powinnińsmy rysować linię czy nie
		cmp ax,0
		je nie_rysuj
		call putline
	nie_rysuj:
		shr word ptr ds:[ddd],1
		inc si
		loop linie
		pop cx
		ret
	;---------------------------------------------------------------------	
	blokko:
		push cx
		mov di,word ptr ds:[stop]
		mov cx,13
		xor bl,bl
		mov word ptr ds:[ddd],1000000000000b									;Analogicznie jw.
	linie3:
		mov ax,di
		and ax,word ptr ds:[ddd]
		cmp ax,0b
		je nie_rysuj3
		call putline
	nie_rysuj3:
		inc si
		shr word ptr ds:[ddd],1
		loop linie3
		pop cx
		ret
	
code1 ends

stos1 segment stack
	dw 255 dup(?)
w_stosu dw ?
stos1 ends

end start1