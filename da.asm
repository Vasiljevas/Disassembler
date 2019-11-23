.model small		;DISASEMBLERIS {beliko aprasyti atpazinimo algoritmo proceduras (ir ju proceduras)
;nepamirsk visus komentarus istrinti pries atsiskaitant
rBufSize equ 400h   ;kiek simboliu per viena syki perskaito
wBufSize equ 40h 	;kiek simboliu per viena syki israso 
;PROBLEMOS: 
;
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
	byteNumber		db 0															;kiek baitu komanda uzima
	lineLength		db 0 															;spausdinamos eilutes ilgis, IP + 10 tarpu + enteris	
;eilutes isvedimui	
	newLine 		db 0Ah															;enteris	
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
	iPointer		dw 0100h
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
    mov cx, bufLength
algorithm:	
	mov bx, offset readBuf						 ;bx rodys duomenu buferio baito adresa
	mov di, offset writeBuf						 ;bp rodys rezultatu buferio baito adresa
	mov notFound, 0								 ;notFound parodo ar komanda yra neatpazinta
	mov lineLength, 0
	
afterPreFix:
	mov al, byte ptr[bx+si]						 ;i al irasom baito reiksme
	;dec bufLength								 ;for(int i=bufLength; i!=0; i--)
	inc si										 ;duomenu buferio poslinkio padidinimas
	
	call prefixCheck 		 				 	 ;paziuri ar baitas prefiksas ar ne, jei taip tai isveda
	cmp trueFalse, 1
	je write
	
	;call whatFormat  							 ;neaprasyta (suzinomas formatas)
	cmp notFound, 1
	je unknownCommand
	
	;call whatAttributes 						 ;neaprasyta (pagal formata nustatomi reikalingi pozymiai)

	;call mainFunction							 ;neaprasyta (suzinoma konkreti komanda ir irasoma i buferi)
	jmp write
	
unknownCommand:
	;call createUnknown 							 ;neaprasyta (sukuria neatpazintos komandos eilute)
;RASYMAS I FAILA
write:
	call writeToFile
	mov byteNumber, 0
	loop algorithm
	pop cx
	pop ax
	pop di
	pop dx
	pop bp
	pop bx	
;FAILU UZDARYMAS
closer:
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
		push si
		push cx
		push di
	look:
		mov cx, 2
		mov trueFalse, 1
		mov di, offset prefix
		cmp al, 26h
		je extraSegment
		cmp al, 2Eh
		je codeSegment
		cmp al, 36h
		je stackSegment
		cmp al, 3Eh
		je dataSegment
		mov trueFalse, 0
		pop di
	back:
		pop cx
		pop si
		ret
		
	extraSegment:
		mov si, offset preES
		jmp found		
	codeSegment:
		mov si, offset preCS
		jmp found
	stackSegment:
		mov si, offset preSS
		jmp found
	dataSegment:
		mov si, offset preDS
		jmp found
	
	found:
		inc byteNumber
		call rewrite
		pop di
		call writePrefix
		jmp back
prefixCheck endp

proc rewrite ;cx=simboliu kiekis, di=[op1], bp=[op2]
		push ax
	taking:
		mov al, byte ptr[si]
		mov byte ptr [di], al
		inc si
		inc di
		loop taking
		pop ax
		ret	
rewrite endp
proc writePrefix ;iPointer,colon,tab,al=masininis kodas,machineCode(tarpai),prefix,colon, 
		push si
	first:
		call inputPointer
		
		push ax
		xor ax, ax
		mov al, byteNumber
		add iPointer, ax		;IP = IP + byteNumber
		
		mov al, colon			;input :
		call input			
		mov al, tab				;input tab
		call input

		pop ax
		mov cx, 2
		call hexInput			;input machine code
		
		mov cl, 10
		sub cl, byteNumber
		mov si, offset machineCode
		call rewrite			;input spaces
	
		mov cl, 2
		mov si, offset prefix
		call rewrite 			;input segment
		add lineLength, cl
		
		mov al, colon
		call input
		mov al, newLine			;input \n
		call input
		
		add lineLength, 20
		pop si
		ret	
writePrefix endp

proc input
		mov byte ptr[di], al
		inc di
		ret
input endp

proc inputPointer
		push ax
		mov ax, iPointer
		mov cx, 4
		call hexInput
		pop ax
		ret
inputPointer endp
proc hexInput ; cx = kiek simboliu irasyt, ax = reiksme
		push dx
		push bx
		mov dx, 2424h
		push dx
		mov bx, 16
	divide:
		xor dx, dx
		div bx
		push dx
		loop divide
	inputStack:
		pop dx
		cmp dx, "$$"
		je emptyStack
		add dl, '0'
		mov byte ptr[di], dl
		inc di
		jmp inputStack
	emptyStack:
		pop dx
		pop bx
		ret
hexInput endp
proc whatFormat ;in progress
		push ax
		push cx
		xor cx, cx
		and al, 11110000b
	comparing:
		cmp al, cl
		je format0
		
whatFormat endp	

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
		jne relativeJump1
		jmp introduction						 ; isvesk intro
	relativeJump1:
		cmp al, 20h 							 ; ? al = space;
		je begin
		cmp ax, "?/"
		jne readName
		mov ax, es:[si]
		cmp ah, 0dh
		jne readName
		jmp introduction
		
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
	read:
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
	
	
	
