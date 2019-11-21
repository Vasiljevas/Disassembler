.model small		;DISASEMBLERIS {beliko aprasyti atpazinimo algoritmo proceduras (ir ju proceduras)
;nepamirsk visus komentarus istrinti pries atsiskaitant
rBufSize equ 400h   ;kiek simboliu per viena syki perskaito
wBufSize equ 40h 	;kiek simboliu per viena syki israso 

.stack 100h 		;stekas = 256
.data 	
;darbui su failu
	intro			db "Andrius Vasiljevas, 1 kursas, 2 grupe, programa:",10,13,"vercia masinini koda i assemblerio koda.",10,13,'$'
	openError		db "ivyko klaida atidarant faila",10,13,'$'						;skaitymo klaidos zinute
	readError		db "ivyko klaida skaitant faila", 10,13,'$'
	closeError		db "ivyko klaida uzdarant faila", 10,13,'$'
	writeError		db "ivyko klaida rasant i faila", 10,13,'$'
	readBuf 		db rBufSize dup (0)												;skaitymo buferis
	writeBuf		db wBufSize dup (0)												;rasymo buferis
	rFileName		db 12 dup (0)													;skaitymo parametro vardas
	wFileName		db 12 dup (0)													;rasymo parametro vardas
	rHandle 		dw ?															;skaitymo deskriptorius
	wHandle			dw ?															;rasymo deskriptorius
	bufLength		dw ?													     	;buferio ilgis													
	lineLength		db 0															;spausdinamos eilutes ilgis
;eilutes isvedimui	
	newLine 		db 13,10														;enteris	
	colon			db ":"
	comma			db ", "
	openBracket		db "["
	closeBracket	db "]"
	plus			db "+"		   
	tab				db "	"
	machineCode		db 10 dup (20h)													;10 tarpu masininiui kodui
	space			db " "
;disasembliavimui
	;prefixam 
	trueFalse		db ?
	preES			db "ES"
	preCS			db "CS"
	preSS			db "SS"
	preDS			db "DS"
	prefix 			db 2 dup (?)
	;formatui
	notFound		db ?
	;spausdinimui
	iPointer		db 0100h
	commandLength	db 0
	
.code ;---kodas:
start:
	mov ax, @data
	mov ds, ax									 ;i data segment'a kintamuosius irasom

	mov si, 81h									 ;extra segment = 0081h, si = es;
	mov di, offset rFileName
	call fileNameRead							 ;parametru vardus irasom
	mov di, offset wFileName
	call fileNameRead
	
	mov dx, offset rFileName
	mov ah, 3dh
	mov al, 00
	call openFile 								 ;atidarom duomenis
	mov rHandle, ax
	
	mov ah, 3ch
	mov cx, 0
	mov dx, offset wFileName
	call openFile
	mov wHandle, ax

	call readBuffer								 ;skaito i buferi
;PAGRINDINIS ALGORITMAS
	push bx
	push bp
	push dx
	push di
	push ax
	push cx
	xor si, si									 ;si bus duomenu buferio poslinkis (pozicijos pointeris)
algorithm:	
	mov bx, offset prefix
	mov byte ptr[bx], 0	
	mov bx, offset readBuf						 ;bx rodys duomenu buferio baito adresa
	mov bp, offset writeBuf						 ;bp rodys rezultatu buferio baito adresa
	xor di, di									 ;di bus rezultatu buferio poslinkis (pozicijos pointeris)

afterPreFix:	
	mov al, byte ptr[bx+si]						 ;i al irasom baito reiksme
	dec bufLength								 ;for(int i=bufLength; i!=0; i--)
	inc si										 ;duomenu buferio poslinkio padidinimas
	
	call prefixCheck 		 				 	 ;paziuri ar baitas prefiksas ar ne
	cmp trueFalse, 1
	je afterPreFix
	
	call whatFormat  							 ;neaprasyta (suzinomas formatas)
	cmp notFound, 1
	je unknownCommand
	
	call whatAttributes 						 ;neaprasyta (pagal formata nustatomi reikalingi pozymiai)

	call mainFunction							 ;neaprasyta (suzinoma konkreti komanda, irasoma i buferi)
	jmp write
	
unknownCommand:
	call createUnknown 							 ;neaprasyta (sukuria neatpazintos komandos eilute)
;RASYMAS I FAILA
write:
	pop cx
	pop ax
	pop di
	pop dx
	pop bp
	pop bx
	mov lineLength, dl							 ;dl pasako kiek simboliu isvesti
	call writeToFile
	cmp bufLength, 0
	jne algorithm	
;FAILU UZDARYMAS
closer:
	pop bx
	pop ax
	mov bx, rHandle 
	call closeFile 								 ;uzdarom skaitymo faila
	
	mov bx, wHandle
	call closeFile								 ;uzdarom rasymo faila

finale: 									     ;programos pabaiga
	mov ah, 4ch
	int 21h
;--ISVEDIMAS I EKRANA
introduction: 									 ;"/?" pagalbos isvedimas
	mov dx, offset intro
	call printLine
	jmp finale
;PREFIXO ISSIASKINIMAS
proc prefixCheck
		push di
		push cx
		push bx
	look:
		mov cx, 0
		mov trueFalse, 1
		mov bx, offset prefix
		cmp al, 26h
		je extraSegment
		cmp al, 2Eh
		je codeSegment
		cmp al, 36h
		je stackSegment
		cmp al, 3Eh
		je dataSegment
		mov trueFalse, 0
		
	back:
		pop bx
		pop cx
		pop di
		ret
		
	extraSegment:
		mov di, offset preES
		call rewrite
		jmp back
	codeSegment:
		mov di, offset preCS
		call rewrite
		jmp back
	stackSegment:
		mov di, offset preSS
		call rewrite
		jmp back
	dataSegment:
		mov di, offset preDS
		call rewrite
		jmp back
prefixCheck endp

proc rewrite
		push ax
	taking:
		mov ax, word ptr[di]
		mov word ptr [bx], ax
		inc di
		inc bx
		loop taking
		pop ax
		ret
rewrite endp

proc whatFormat
	
proc printLine
	mov ah, 09h
	int 21h
	ret
printLine endp
;DARBAS SU PARAMETRAIS IR FAILAIS
proc fileNameRead ;iraso parametro varda
		push ax
	begin:
		mov ax, es:[si]
		inc si
		cmp al, 0dh 							 ; ? al = enter;
		je introduction							 ; isvesk intro
		cmp al, 20h 							 ; ? al = space;
		je begin
		cmp ax, "?/"
		jne readName
		mov ax, es:[si]
		cmp ah, 0dh
		je introduction
		
	readName:
		mov byte ptr[di], al
		inc di
		mov ax, es:[si]
		inc si
		cmp al, 0
		je enough
		cmp al, 0dh
		je enough
		cmp al, 20h
		jne readName
		
	enough:
		pop ax
		ret
fileNameRead endp
proc openFile ;atidaro faila
	open:
		int 21h
		jc oError ; isvesk openError if cf = 1
		ret
	oError:
		mov dx, offset openError
		call printLine
		jmp finale
openFile endp	
proc readBuffer
		push dx
		push cx
		push bx
	read: ; "Simple" skaitymo budas
		mov bx, rHandle
		mov dx, offset readBuf
		mov ah, 3fh
		mov cx, rBufSize
		int 21h
		jc readingError
		
	readingEnd:
		mov bufLength, ax
		pop bx
		pop cx
		pop dx
		ret
		
	readingError:
		mov dx, offset readError
		call printLine
		mov ax, 0
		jmp finale
readBuffer endp
proc closeFile
		push ax
	close:
		mov ah, 3eh
		int 21h
		jc closingError
	closeFileEnd:
		pop ax
		ret
	
	closingError:
		mov dx, offset closeError
		call printLine
		jmp finale
closeFile endp
proc writeToFile
		push bx
		push dx
		push ax
		push cx
		xor cx, cx
	startWriting:
		mov bx, wHandle
		mov dx, offset writeBuf
		mov cl, lineLength
		mov ah, 40h
		int 21h
		jc writingError
		
	doneWriting:
		pop cx
		pop ax
		pop dx
		pop bx
		ret
		
	writingError:
		mov dx, offset writeError
		call printLine
		jmp doneWriting	
writeToFile endp	
end start
	
	
	
