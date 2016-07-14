data segment
; obsluga bledow
dollar                  db '$'
errptr                  dw [dollar]

; komunikaty
err_no_args             db "err: brak argumentow$"
err_not_enough_args     db "err: za malo argumentow$"
warn_unnecessary_args   db "warn: niepotrzebne argumenty$"
err_fopen               db "err: nie udalo sie otworzyc pliku$"
err_fcreate             db "err: nie udalo sie utworzyc pliku$"
err_fclose              db "err: nie udalo sie zamknac pliku$"
err_fread               db "err: nie udalo sie odczytac z pliku$"
err_write               db "err: nie udalo sie zapisac do pliku$"

rep_heading             db "Raport z pliku o nazwie ",0
rep_colon_space         db ": ",0
rep_endl                db 13,10,0

; nazwy plikow na ktorych operujemy
; maksymalna nazwa pliku w FAT32 to 255 znakow.
in_filename             db 256 dup(0)
out_filename            db 256 dup(0)

; tablica licznikow bajtow
; FAT32 pozwala na pliki o rozmiarze do 4GB,
; wiec potrzebujemy dd, aby to zmiescic
stat_table              dd 256 dup(0)

; bufor
buffer                  db 4096 dup(0) ; 4kb
data ends


code segment
assume CS:code
    ; ponizszy kod ustawia poczatkowy stan programu
    ; a nastepnie przekazuje kontrole do procedury `Main`
start:
    ; kopiujemy argumenty programu do [buffer]
    ; ustaw ES na polozenie segmentu danych
    ; (narazie nie ruszamy DS, zeby miec dostep do argumentow)
    mov AX, seg data
    mov ES, AX ; ES - extra segment

    ; CX = ilosc znakow
    xor CX, CX
    mov CL, byte ptr DS:[080h]
    inc CX ; CR na koncu nie jest wliczany

    ; bedziemy kopiowac z [081h] do [buffer]
    lea SI, DS:[081h]
    lea DI, ES:[buffer]

    ; kopiujemy
    ; movsb: DS:SI -> ES:DI
    rep movsb

    ; teraz ustaw DS na polozenie segmentu danych
    ; (zeby potem nie musiec sie nimi przejmowac)
    mov AX, seg data
    mov DS, AX ; DS - data segment

    ; inicjalizacja stosu
    mov AX, seg stack_top
    mov SS, AX               ; SS - stack segment
    lea SP, SS:[stack_top]   ; SP - stack pointer

    ; wywolaj main'a
    call Main

error:
    ; wypisz wiadomosc bledu
    mov AH, 9
    mov DX, DS:[errptr]
    int 21h

    ; wyjdz do systemu
    mov AX, 4C00h ; 21h,04Ch - wychodzenie do DOS; w AL kod wyjscia
    int 21h

;; procedury

; Main()
; Glowna procedura programu
Main proc
    push BX ; BX jest ustawiany przez procedury operujace na plikach
    push DX

    ; przetworz argumenty
    call ParseArgv

    ; przeczytaj plik wyjsciowy
    lea DX, DS:[in_filename]
    call FOpen
    call AnalyseInput
    call FClose

    ; wygeneruj raport
    lea DX, DS:[out_filename]
    call FCreate
    call WriteReport
    call FClose

    pop DX
    pop BX
    ret
Main endp

; ParseArgv([buffer]) -> [in_filename], [out_filename]
;
; Przetwarza argumenty linii polecen.
; Format: in_filename out_filename
ParseArgv proc
    push AX
    push DX
    push SI
    push DI

    lea SI, DS:[buffer]

    ; sprawdzamy czy uzytkownik nie podal zadnych argumentow
    mov AL, DS:[SI]
    cmp AL, 13 ; 13 - CR
    jne @@has_args

    ; rzuc bledem
    lea AX, DS:[err_no_args]
    mov DS:[errptr], AX
    jmp error

@@has_args:
    call ConsumeWhiteSpace

    lea DI, ES:[in_filename]
    call ConsumeFileName

    call ConsumeWhiteSpace

    ; sprawdzamy czy uzytkownik nie podal drugiego argumentu
    mov AL, DS:[SI]
    cmp AL, 13 ; 13 - CR
    jne @@has_second_arg

    ; rzuc bledem
    lea AX, DS:[err_not_enough_args]
    mov DS:[errptr], AX
    jmp error

@@has_second_arg:
    lea DI, ES:[out_filename]
    call ConsumeFileName

    call ConsumeWhiteSpace

    ; sprawdzamy czy uzytkownik nie podal zbednych argumentow
    mov AL, DS:[SI]
    cmp AL, 13 ; 13 - CR
    je @@end

    ; wypisz ostrzezenie
    lea DX, DS:[warn_unnecessary_args]
    mov AH, 9
    int 21h

@@end:
    pop DI
    pop SI
    pop DX
    pop AX
    ret
ParseArgv endp

; ConsumeWhiteSpace(DS:SI) -> DS:SI
; Przesuwa wskaznik na tekst tak, aby pominac biale znaki.
ConsumeWhiteSpace proc
    push AX

    @@loop:
        ; pobierz obecny znak do AL
        mov AL, DS:[SI]

        ; if DS:[SI] = '\r': break
        ; linia argumentow jest zakonczona znakiem CR
        cmp AL, 13
        je @@end

        ; if DS:[SI] > ' ': break
        ; spacja to ostatni bialy znak w tabeli ASCII
        cmp AL, 32
        ja @@end

        ; wpp idziemy dalej
        inc SI
        jmp @@loop

@@end:
    pop AX
    ret
ConsumeWhiteSpace endp

; ConsumeFileName(DS:SI, ES:DI) -> DS:SI, ES:DI
; Pobiera nazwe pliku z DS:SI, przesuwajac go, do ES:DI.
ConsumeFileName proc
    push AX

    @@loop:
        ; pobierz obecny znak do AL
        mov AL, DS:[SI]

        ; if DS:[SI] <= ' ': break
        ; spacja to ostatni bialy znak w tabeli ASCII
        cmp AL, 32
        jbe @@end

        ; wpp kopiujemy i idziemy dalej
        movsb
        jmp @@loop

@@end:
    pop AX
    ret
ConsumeFileName endp

; FOpen(DS:DX) -> BX
; Otwiera plik w trybie do odczytu i zwraca jego handle.
FOpen proc
    push AX
    mov AX, 3D00h ; 21h,3Dh - otwiera plik; AL - access code:
                  ;     0 - r, 1 - w, 2 - rw
    int 21h
    jc @@error
    mov BX, AX
    pop AX
    ret

@@error:
    ; rzuc bledem
    lea AX, DS:[err_fopen]
    mov DS:[errptr], AX
    jmp error
FOpen endp

; FCreate(DS:DX) -> BX
; Tworzy plik i zwraca jego handle.
FCreate proc
    push AX
    push CX
    xor CX, CX
    mov AH, 3Ch ; 21h,3Ch - tworzy plik; CL - atrybuty
    int 21h
    jc @@error
    mov BX, AX
    pop CX
    pop AX
    ret

@@error:
    ; rzuc bledem
    lea AX, DS:[err_fcreate]
    mov DS:[errptr], AX
    jmp error
FCreate endp

; FClose(BX)
; Zamyka plik.
FClose proc
    push AX
    mov AH, 3Eh ; 21h,3Eh - zamyka plik
    int 21h
    jc @@error
    pop AX
    ret

@@error:
    ; rzuc bledem
    lea AX, DS:[err_fclose]
    mov DS:[errptr], AX
    jmp error
FClose endp

; FRead(BX, DS:DX, CX) -> AX
; BX - handle pliku
; CX - ilosc bajtow do wczytania
; DS:DX - adres bufora
; -> AX - ilosc wczytanych bajtow
;
; Buforowane czytanie z pliku.
FRead proc
    mov AH, 3Fh  ; 21h,3Fh - buforowane wczytywanie pliku
                 ; BX = handle pliku
                 ; CX = ilosc bajtow do wczytania
                 ; DS:DX = adres bufora
                 ; -> AX - ilosc wczytanych bajtow
    int 21h
    jc @@error
    ret

@@error:
    ; rzuc bledem
    lea AX, DS:[err_fread]
    mov DS:[errptr], AX
    jmp error
FRead endp

; CopyString(DS:SI, ES:DI) -> CX
; Kopiuje string zakonczony \0 z DS:SI do ES:DI.
; Zwraca ilosc skopiowanych znakow, oraz przesuwa indeksy na koniec stringa.
CopyString proc
    push AX

    xor CX, CX

@@loop:
        ; if DS:[SI] = 0: break
        mov AL, DS:[SI]
        cmp AL, 0
        je @@end

        movsb
        inc CX
        jmp @@loop

@@end:
    ; skopiujmy jeszcze \0
    movsb
    inc CX
    pop AX
    ret
CopyString endp

; Strlen(DS:SI) -> CX
; Zwraca dlugosc stringa zakonczonego \0
Strlen proc
    push AX
    push SI

    xor CX, CX

@@loop:
        ; if DS:[SI] = 0: break
        mov AL, DS:[SI]
        cmp AL, 0
        je @@end

        inc SI
        inc CX
        jmp @@loop

@@end:
    pop SI
    pop AX
    ret
Strlen endp

; WriteBuffer(BX, DS:SI)
; Zapisuje linijke zakonczona \0 z bufora do pliku.
WriteBuffer proc
    push AX
    push CX
    push DX

    mov DX, SI
    call Strlen

    mov AH, 40h ; 21h,40h - zapisuje blok do pliku
                ; BX - handle pliku
                ; CX - ilosc bajtow do zapisania
                ; DS:DX - adres bufora
    int 21h

    jc @@error
    ; jezeli AX < CX, to mamy pelny dysk
    cmp AX, CX
    jb @@error

    pop DX
    pop CX
    pop AX
    ret

@@error:
    ; rzuc bledem
    lea AX, DS:[err_write]
    mov DS:[errptr], AX
    jmp error
WriteBuffer endp

; AnalyseInput(BX) -> [stat_table]
; BX - uchwyt na plik
; Analizuje plik wejsciowy.
AnalyseInput proc
    push AX
    push CX
    push DX
    push SI

    ; wrzuc adres bufora do DX dla DOSa i SI dla nas
    lea DX, DS:[buffer]
    mov SI, DX
    mov CX, 4096 ; tylu bajtowe bloki bedziemy wczytywac

@@loop:
        ; wczytaj CX bajtow z pliku
        call FRead

        ; przeanalizuj je
        push CX
        mov CX, AX
        call AnalyseBuffer
        pop CX

        ; jezeli AX >= CX to znaczy ze mamy jeszcze cos do wczytania
        cmp AX, CX
        jae @@loop

@@end:
    pop SI
    pop DX
    pop CX
    pop AX
    ret
AnalyseInput endp

; AnalyseBuffer([buffer], CX) -> [stat_table]
; CX - ilosc znakow w buforze
; Analizuje bufor.
AnalyseBuffer proc
    push BX
    push CX
    push SI
    push DI

    mov BX, 0004h

@@loop:
        ; if CX = 0: break
        cmp CX, 0
        je @@end

        ; ladujemy obecny bajt do AL
        xor AX, AX
        mov AL, DS:[SI]

        ; wyliczymy indeks w [stat_table]
        lea DI, DS:[stat_table]
        mul BL ; element w tablicy zajmuje 4 bajty
        add DI, AX

        ; inkrementujemy pozycje w [stat_table]
        ;
        ; poniewaz komorka w tablicy jest podwojnym slowem, nie mozemy uzyc inc
        ;
        ; najpierw zwiekszamy mlodszy bajt o 1, a nastepnie korzystajac z adc
        ; kontynuujemy dla starszego bajtu (pamietajmy o przechowywaniu odwrotnym)
        ;
        ; adc ma sygnaturke: Dest:=Dest+Source+CF
        ;
        ; wiecej: http://stackoverflow.com/a/30179974
        add word ptr DS:[DI], 1
        adc word ptr DS:[DI + 2], 0

        ; idziemy dalej
        inc SI
        dec CX
        jmp @@loop

@@end:
    pop DI
    pop SI
    pop CX
    pop BX
    ret
AnalyseBuffer endp

; WriteReport(BX)
; Generuje raport i zapisuje do pliku.
WriteReport proc
    push AX
    push CX
    push SI
    push DI

    ; wpisz naglowek do bufora
    lea DI, ES:[buffer]

    lea SI, DS:[rep_heading]
    call CopyString

    dec DI

    lea SI, DS:[in_filename]
    call CopyString

    dec DI

    lea SI, DS:[rep_colon_space]
    call CopyString

    dec DI

    lea SI, DS:[rep_endl]
    call CopyString

    dec DI

    lea SI, DS:[rep_endl]
    call CopyString

    dec DI

    ; teraz iterujemy po kazdym bajcie
    xor AL, AL
    push BX
    lea BX, DS:[stat_table]
@@loop:
        call RenderByte

        dec DI

        lea SI, DS:[rep_colon_space]
        call CopyString

        dec DI

        push AX
        push DX
            mov AX, DS:[BX]
            mov DX, DS:[BX + 2]
            call RenderDword
        pop DX
        pop AX

        dec DI

        lea SI, DS:[rep_endl]
        call CopyString

        dec DI

        ; if AL >= 255: break
        cmp AL, 255
        jae @@end_loop

        ; nastepny bajt
        inc AL
        add BX, 4
        jmp @@loop

@@end_loop:
    pop BX
    ; zapisz bufor do pliku
    lea SI, DS:[buffer]
    call WriteBuffer

    pop DI
    pop SI
    pop CX
    pop AX
    ret
WriteReport endp

; RenderByte(AL, ES:DI)
; Zapisuje bajt z AL do ES:DI w formacie 000.
RenderByte proc
    push AX
    push BX

    xor AH, AH
    xor BH, BH

    ; setki
    mov BL, 100
    div BL
    add AL, '0'
    mov ES:[DI], AL
    inc DI

    ; dziesiatki
    mov AL, AH
    cbw ; AL -> AX
    mov BL, 10
    div BL
    add AL, '0'
    mov ES:[DI], AL
    inc DI

    ; jednosci
    mov AL, AH
    add AL, '0'
    mov ES:[DI], AL
    inc DI

    ; dodajmy \0 na koniec
    mov AL, 0
    mov ES:[DI], AL
    inc DI

    pop BX
    pop AX
    ret
RenderByte endp

; RenderDword(DX:AX, ES:DI)
; Zapisuje dwuslowo z DX:AX do ES:DI w formacie dziesietnym.
RenderDword proc
    push AX
    push BX
    push CX
    push DX

    ; jezeli DX:AX = 0, to wypiszmy 0 i skonczmy wczesniej
    cmp DX, 0
    jne @@not_zero
    cmp AX, 0
    jne @@not_zero

    ; wstawiamy '0' i pomijamy petle
    mov AL, '0'
    mov ES:[DI], AL
    inc DI

    jmp @@end

@@not_zero:
    xor BX, BX
    xor CX, CX

    ; wyciagamy cyfry dziesietne z liczby i wrzucamy na stos
@@extract_loop:
        ; if DX = 0 and AX = 0: break
        cmp DX, 0
        jne @@extract_loop_work
        cmp AX, 0
        je @@extract_loop_end

    @@extract_loop_work:
        ; dzieliemy DX:AX przez 10, wynik -> DX:AX, reszta -> BX
        call BigDivBy10
        push BX
        inc CX
        jmp @@extract_loop

@@extract_loop_end:

    ; wrzucamy cyfry do bufora
@@render_loop:
        ; if CX = 0: break
        cmp CX, 0
        je @@end

        ; sciagamy cyfre ze stosu, konwertujemy na ASCII, i wrzucamy do bufora
        pop AX
        add AL, '0'
        mov ES:[DI], AL
        inc DI

        loop @@render_loop

@@end:
    ; dodajmy \0 na koniec
    mov AL, 0
    mov ES:[DI], AL
    inc DI

    pop DX
    pop CX
    pop BX
    pop AX
    ret
RenderDword endp

; BigDivBy10(DX:AX) -> DX:AX, BX
; Dzieli nieujemna liczbe 32-bitowa reprezentowana przez pare DX:AX przez 10,
; zapisujac wynik dzielenia do DX:AX, a reszte do BX.
BigDivBy10 proc
    push CX

    mov BX, 10   ; dzielnik
    push AX      ; odkladamy mlodsza czesc na pozniej
    mov AX, DX   ; na razie bedziemy sie zajmowac tylko starszym slowem
    xor DX, DX   ; zerujemy DX zeby dzielenie wyszlo
    div BX       ; pierwsze dzielenie
    mov CX, AX   ; wynik tego dzielenia to bedzie starsze slowo calosci
                 ; natomiast reszta w DX to starsze slowo drugiego dzielenia
    pop AX       ; teraz zajmujemy sie mladsza czescia
    div BX       ; teraz dzielimy STARSZA_RESZTA:MLODSZE_SLOWO przez 10
                 ; w AX mamy mlodsze slowo wyniku
    mov BX, DX   ; natomiast w DX reszte ostatecznego wyniku
    mov DX, CX   ; teraz przywracamy starsze slowo wyniku

    pop CX
    ret
BigDivBy10 endp

code ends


stack segment stack
            dw  63 dup(?)   ; 63 + 1 = 64
stack_top   dw  ?           ; tylu elementowy stos deklarujemy
stack ends


end start
