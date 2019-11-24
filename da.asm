.model small ;DISASEMBLERIS PAGAL EMU8086
;nepamirsk visus komentarus istrinti pries atsiskaitant
.386 ;Tai leidzia naudot procesoriaus 80386 komandu rinkini, kuriame apibreztas didesnis jumpu intervalas
rBufSize equ 400h   																;kiek simboliu per viena syki perskaito
wBufSize equ 40h 																	;kiek simboliu per viena syki israso 
;PROBLEMOS/IDEJOS: 
;galbut reikes proceduros, kuri tiesiog nauja baita ikelia i al (144 eilute), kad sutaupyt vietos
;beliko parasyt mainFunction procedura
.stack 100h 	
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
	badCommand 		db "N", "E", "S", "U", "P", "R", "A", "S", "T", "A"
;registrai
	regAX			db "AX"
	regBX			db "BX"
	regCX			db "CX"
	regDX			db "DX"
	regAH			db "AH"
	regAL			db "AL"
	regBH			db "BH"
	regBL			db "BL"
	regCH			db "CH"
	regCL			db "CL"
	regDH			db "DH"
	regDL			db "DL"
	regSP			db "SP"
	regBP			db "BP"
	regSI			db "SI"
	regDI			db "DI"
;prefixam 
	trueFalse		db ?
	preES			db "ES"
	preCS			db "CS"
	preSS			db "SS"
	preDS			db "DS"
	prefix 			db 2 dup (?)
;komandos
	comMOV			db "MOV"
	comPUSH			db "PUSH"
	comPOP			db "POP"
	comADD			db "ADD"
	comINC			db "INC"
	comSUB			db "SUB"
	comDEC			db "DEC"
	comCMP			db "CMP"
	comMUL			db "MUL"
	comDIV			db "DIV"
	comCALL			db "CALL"
	comRET			db "RET"
	comJMP			db "JMP"
	comLOOP			db "LOOP"
	comINT			db "INT"
;salyginiai suoliai (17)
	comJO			db "JO" 		;jo
	comJNO			db "JNO"		;jno
	comJB			db "JB"			;jnae, jb, jc
	comJNB			db "JNB"		;jae, jnb, jnc
	comJE			db "JE"			;je, jz
	comJNE			db "JNE"		;jne, jnz
	comJBE			db "JBE"		;jbe, jnae
	comJNBE			db "JNBE"		;ja, jnbe
	comJS			db "JS"			;js
	comJNS			db "JNS"		;jns
	comJPE			db "JPE"		;jp, jpe
	comJPO			db "JPO"		;jnp, jpo
	comJL			db "JL"			;jl, jnge
	comJNL			db "JNL"		;jge, jnl
	comJLE			db "JLE"		;jle, jng
	comJNLE			db "JNLE"		;jg, jnle
	comJCXZ			db "JCXZ"		;jcxz (format E.14)
;formatui
	notFound		db ?
	theFormat		db ?						 ;galimybiu sritis: [0,5]v[7,F]
;spausdinimui
	iPointer		dw 0100h
	command			db 4 dup (20h)
;atpazinimui
	attribute		db ?
	
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
	inc si										 ;duomenu buferio poslinkio padidinimas
	
	call prefixCheck 		 				 	 ;paziuri ar baitas prefiksas ar ne, jei taip tai isveda
	cmp trueFalse, 1
	je write
	
	call whatFormat  							 ;suzinomas formatas (theFormat) , NEZINAU AR VEIKIA, turbut veikia
	cmp notFound, 1
	je unknownCommand
	
	call whatAttributes 						 ;pagal formata nustatomi reikalingi pozymiai
	cmp notFound, 1
	je unknownCommand
	
	;call mainFunction							 ;NEAPRASYTA (suzinoma konkreti komanda ir irasoma i buferi)
	jmp write
	
unknownCommand:
	call createUnknown 							 ;sukuria neatpazintos komandos eilute
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

proc machineCodeInput ;cx = kiek simboliu irasyt
		push dx
		call hexInput			;input machine code
		mov cl, 10
		mov dl, byteNumber
		add dl, dl
		sub cl, dl
		mov si, offset machineCode
		call rewrite			;input spaces  
		pop dx
        ret
machineCodeInput endp

proc writePrefix ;iPointer,colon,tab,al=masininis kodas,machineCode(tarpai),prefix,colon, 
		push si
		
	first:
		call inputPointer
		push ax
		
		mov al, colon			;input :
		call input			
		mov al, tab				;input tab
		call input

		pop ax
		mov cx, 2
		call machineCodeInput
	
		mov cl, 2
		mov si, offset prefix
		call rewrite 			;input segment
		
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
		xor ax, ax
		mov al, byteNumber
		add iPointer, ax		;IP = IP + byteNumber
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
		cmp dl, '9'
		jg greaterThan9
	mainInput:
		mov byte ptr[di], dl
		inc di
		jmp inputStack
	emptyStack:
		pop dx
		pop bx
		ret
	greaterThan9:
		add dl, 7h
		jmp mainInput
hexInput endp

proc whatFormat ;theFormat rodo surasta komandos formata
		push ax
		push cx
		xor cx, cx
		shr al, 4
		cmp al, 6h
		je badByte
		cmp al, 0Dh
		je badByte
	comparing:
		cmp al, cl
		je formating
		inc cl
		jmp comparing
		
	formating:
		mov theFormat, cl
		
	stopFormating:
		pop cx
		pop ax
		ret
		
	badByte:
		mov notFound, 1
		inc byteNumber
		jmp stopFormating
whatFormat endp	

proc whatAttributes;surandama kokius pozymius reiks naudoti, theFormat = formatas,al = pirmas baitas
		push cx
		push ax
		xor cx, cx
		and al, 00001111b
	whichOne:
		cmp theFormat, cl
		je format0
		inc cl
		cmp theFormat, cl
		je format1
		inc cl
		cmp theFormat, cl
		je format2
		inc cl
		cmp theFormat, cl
		je format3
		inc cl
		cmp theFormat, cl
		je attribute3
		inc cl
		cmp theFormat, cl
		je attribute3
		add cl, 2
		cmp theFormat, cl
		je attribute14
		inc cl
		cmp theFormat, cl
		je format8
		inc cl
		cmp theFormat, cl
		je attribute16
		inc cl
		cmp theFormat, cl
		je formatA
		inc cl
		cmp theFormat, cl
		je attribute13
		inc cl
		cmp theFormat, cl
		je formatC
		add cl, 2
		cmp theFormat, cl
		je formatE
		jmp formatF
		
	format0:	
		cmp al, 0Eh
		jge attribute11
		cmp al, 8
		jge veryBadByte
		cmp al, 6
		jge attribute11
		cmp al, 4
		jge attribute2
		jmp attribute1		
	format1:
		cmp al, 0Eh
		jge attribute11
		cmp al, 7
		jg veryBadByte
		cmp al, 6
		jl veryBadByte
		jmp attribute11	
	format2:
		cmp al, 7
		jle veryBadByte
		cmp al, 0Bh
		jle attribute1
		cmp al, 0Eh
		jl attribute2
		jmp veryBadByte	
	format3:
		cmp al, 7
		jle veryBadByte
		cmp al, 0Bh
		jle attribute1
		cmp al, 0Eh
		jl attribute2
		jmp veryBadByte
	format8:
		cmp al, 3
		jle attribute4
		cmp al, 0Ch
		jl veryBadByte
		cmp al, 0Dh
		jle attribute5
		cmp al, 0Eh
		je veryBadByte
		jmp attribute6
	formatA:
		cmp al, 3
		jle attribute12
		jmp veryBadByte
	formatC:
		cmp al, 6
		je attribute8
		cmp al, 7
		je attribute8
		cmp al, 2
		je attribute9
		cmp al, 0Ah
		je attribute9
		cmp al, 0Dh
		je attribute10
		cmp al, 3
		je attribute11
		cmp al, 0Bh
		je attribute11
		cmp al, 0Fh
		je attribute11
		jmp veryBadByte
	formatE:
		cmp al, 2
		je attribute14
		cmp al, 3
		je attribute14
		cmp al, 0Bh
		je attribute14
		cmp al, 8
		je attribute15
		cmp al, 9
		je attribute15
		cmp al, 0Ah
		je attribute16
		jmp veryBadByte
	formatF:
		cmp al, 6
		jl veryBadByte
		cmp al, 7
		jle attribute7
		cmp al, 0Eh
		jl veryBadByte
		cmp al, 0Eh
		je attribute7
		mov al, byte ptr[bx+si]
		cmp al, 0C7h
		jle further
		
		further:
		cmp al, 10h
		jl veryBadByte
		cmp al, 37h
		jle attribute6
		cmp al, 40h
		jl veryBadByte
		cmp al, 47h
		jle attribute7
		cmp al, 50h
		jl veryBadByte
		cmp al, 57h
		jle attribute6
		cmp al, 60h
		jl veryBadByte
		cmp al, 77h
		jle attribute6
		cmp al, 80h
		jl veryBadByte
		cmp al, 87h
		jle attribute7
		cmp al, 90h
		jl veryBadByte
		cmp al, 97h
		jle attribute6
		cmp al, 0A0h
		jl veryBadByte
		cmp al, 0B7h
		jle attribute6
		cmp al, 0C0h
		jl veryBadByte
		cmp al, 0C7h
		jle attribute7
		cmp al, 0D0h
		jl veryBadByte
		cmp al, 0D7h
		jle attribute6
		cmp al, 0E0h
		jl veryBadByte
		cmp al, 0F7h
		jle attribute6
		jmp veryBadByte
			
	attribute1:
		mov attribute, 1
		pop ax
		pop cx
		ret
	attribute2:
		mov attribute, 2
		pop ax
		pop cx
		ret
	attribute3:
		mov attribute, 3
		pop ax
		pop cx
		ret
	attribute4:
		mov attribute, 4
		pop ax
		pop cx
		ret
	attribute5:
		mov attribute, 5
		pop ax
		pop cx
		ret
	attribute6:
		mov attribute, 6
		pop ax
		pop cx
		ret
	attribute7:
		mov attribute, 7
		pop ax
		pop cx
		ret
	attribute8:
		mov attribute, 8
		pop ax
		pop cx
		ret
	attribute9:
		mov attribute, 9
		pop ax
		pop cx
		ret
	attribute10:
		mov attribute, 10
		pop ax
		pop cx
		ret	
	attribute11:
		mov attribute, 11
		pop ax
		pop cx
		ret
	attribute12:
		mov attribute, 12
		pop ax
		pop cx
		ret
	attribute13:
		mov attribute, 13
		pop ax
		pop cx
		ret
	attribute14:
		mov attribute, 14
		pop ax
		pop cx
		ret
	attribute15:
		mov attribute, 15
		pop ax
		pop cx
		ret
	attribute16:
		mov attribute, 16
		pop ax
		pop cx
		ret	
		
	veryBadByte:
		mov notFound, 1
		inc byteNumber
		pop ax
		pop cx
		ret
whatAttributes endp

proc createUnknown ;neatpazintos komandos eilutes sukurimas
		push cx
		push si
		
		call inputPointer
		
		push ax
		mov al, colon			;input :
		call input
		
		mov al, tab				;input tab
		call input
		pop ax
		
		mov cx, 2
		call machineCodeInput	;input masininis kodas
		
		mov cx, 10
		mov si, offset badCommand
		call rewrite
		
		mov al, newLine			;input \n
		call input
		
		add lineLength, 27
		pop si
		pop cx
		ret
createUnknown endp
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
		;be .386 sitoj vietoj relative jump out of range
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
	
	
	
