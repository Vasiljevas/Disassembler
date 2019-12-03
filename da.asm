.model small 
.386	
rBufSize equ 400h   																
wBufSize equ 40h 																	 
.stack 100h 	
.data 	
	intro			db "Andrius Vasiljevas, 1 kursas, 2 grupe, programa:",10,13,"vercia masinini koda i assemblerio koda.",10,13,'$'
	openError		db "ivyko klaida atidarant faila",10,13,'$'					
	readError		db "ivyko klaida skaitant faila", 10,13,'$'
	closeError		db "ivyko klaida uzdarant faila", 10,13,'$'
	writeError		db "ivyko klaida rasant i faila", 10,13,'$'
	readBuf 		db rBufSize dup (0)												
	writeBuf		db wBufSize dup (0)											
	rFileName		db 12 dup (0)												
	wFileName		db 12 dup (0)													
	rHandle 		dw ?															
	wHandle			dw ?															
	bufLength		dw ?													     													
	byteNumber		db 0															
	lineLength		db ?														
	colon			db ":"
	comma			db ",", " "
	openBracket		db "["
	closeBracket	db "]"
	plus			db "+"		   
	tab				db "	"
	machineCode		db 13 dup (20h)												
	space			db " "
	badCommand 		db "N", "E", "S", "U", "P", "R", "A", "S", "T", "A"
	trueFalse		db ?
	preES			db "ES"
	preCS			db "CS"
	preSS			db "SS"
	preDS			db "DS"
	prefix 			db 2 dup (?)
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
	comRETF			db "RETF"
	comIRET			db "IRET"
	comJMP			db "JMP"
	comLOOP			db "LOOP"
	comINT			db "INT"
	comMAIN			db 4 dup (20h)
	comJO			db "JO " 	
	comJNO			db "JNO"		
	comJB			db "JB "			
	comJNB			db "JNB"	
	comJE			db "JE "			
	comJNE			db "JNE"		
	comJBE			db "JBE"		
	comJNBE			db "JNBE"		
	comJS			db "JS "		
	comJNS			db "JNS"		
	comJPE			db "JPE"	
	comJPO			db "JPO"		
	comJL			db "JL "			
	comJNL			db "JNL"		
	comJLE			db "JLE"		
	comJNLE			db "JNLE"	
	comJCXZ			db "JCXZ"	
	iPointer		dw 0100h
	w0array 		db "A","C","D","B","A","C","D","B"
	w1array	    	db "A","C","D","B","S","B","S","D"
	register		db 2 dup (?)
	rm0				db "B","X","+","S","I"
	rm1				db "B","X","+","D","I"
	rm2				db "B","P","+","S","I"
	rm3				db "B","P","+","D","I"
	rm4				db "S","I"
	rm5				db "D","I"
	rm6				db "B","P"
	rm7				db "B","X"
	segReg			db "E", "C", "S", "D"
	notFound		db ?
	attribute		db ?
	theFormat		db ?						
	dBit			db ?
	wBit			db ?
	abMod			db ?
	abReg			db ?
	abRM			db ?
	poslinkis		db 4 dup (0)
	operands		db 16 dup (0)
.code 
start:
	mov ax, @data
	mov ds, ax									
	mov si, 81h									
	mov di, offset rFileName
	call fileNameRead							 
	mov di, offset wFileName
	call fileNameRead
	mov dx, offset rFileName
	mov ah, 3dh
	mov al, 00
	call openFile 								
	mov rHandle, ax
	mov ah, 3ch
	mov cx, 0
	mov dx, offset wFileName
	call openFile
	mov wHandle, ax
	call readBuffer							
	push bx
	push bp
	push dx
	push di
	push ax
	push cx
	xor si, si								
    mov cx, bufLength						
	mov bx, offset readBuf
algorithm:
	xor ax, ax
	mov di, offset writeBuf	
	mov notFound, 0								
	mov al, byte ptr[bx+si]	
	inc si
	call prefixCheck 		 				 	 
	cmp trueFalse, 1
	je write	
		call whatFormat  						
		cmp notFound, 1
		je unknownCommand
			call whatAttributes 						
			cmp notFound, 1
			je unknownCommand
				call mainFunction						
				jmp write
unknownCommand:
	call createUnknown 							
write:
	call findLineLength
	call writeToFile
	call resetBuffers
	loop algorithm
	pop cx
	pop ax
	pop di
	pop dx
	pop bp
	pop bx	
	mov bx, rHandle 
	call closeFile 								
	mov bx, wHandle
	call closeFile								 
finale: 									    
	mov ah, 4ch
	int 21h
introduction: 									
	mov dx, offset intro
	call printLine
	jmp finale
;------------------proceduros---------------------------------
proc prefixCheck
	push si
	push cx
	push di
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

proc rewrite
	push ax
	taking:
		call useTableMov
		inc si
		inc di
		loop taking
	pop ax
	ret	
rewrite endp

proc machineCodeInput
	push dx
	push cx
	xor cx, cx
	mov cl, byteNumber
	goAgain:
		push cx
		mov cx,2
		call hexInput			
		pop cx
		mov al, byte ptr[bx+si]
		inc si
		loop goAgain
	mov cl, 13
	mov dl, byteNumber
	add dl, dl
	sub cl, dl
	mov si, offset machineCode
	call rewrite				 
	pop cx
	pop dx  
	ret
machineCodeInput endp

proc writePrefix  
	push si	
	call IPandMC	
	mov cl, 2
	mov si, offset prefix
	call rewrite 			
	mov al, colon
	call input
	pop si
	ret	
writePrefix endp

proc input
	mov byte ptr[di], al
	inc di
	ret
input endp

proc IPandMC
	push cx
	push ax
	mov ax, iPointer
	mov cx, 4
	call hexInput
	xor ax, ax
	mov al, byteNumber
	add iPointer, ax		
	mov al, colon			
	call input			
	mov al, tab				
	call input
	pop ax
	pop cx
	call machineCodeInput
	ret
IPandMC endp

proc hexInput 
	push bx
	push dx
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
			ja greaterThan9
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

proc whatFormat 
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

proc whatAttributes
	push ax
	and al, 00001111b
	cmp theFormat, 0
	je format0
	cmp theFormat, 1
	je format1
	cmp theFormat, 2
	je format2
	cmp theFormat, 3
	je format3
	cmp theFormat, 4
	je attribute3
	cmp theFormat, 5
	je attribute3
	cmp theFormat, 7
	je attribute14
	cmp theFormat, 8
	je format8
	cmp theFormat, 9
	je attribute16
	cmp theFormat, 10
	je formatA
	cmp theFormat, 11
	je attribute13
	cmp theFormat, 12
	je formatC
	cmp theFormat, 14
	je formatE
	jmp formatF		
	format0:	
		cmp al, 0Eh
		jae attribute11
		cmp al, 8
		jae veryBadByte
		cmp al, 6
		jae attribute11
		cmp al, 4
		jae attribute2
		jmp attribute1		
	format1:
		cmp al, 0Eh
		jae attribute11
		cmp al, 7
		ja veryBadByte
		cmp al, 6
		jb veryBadByte
		jmp attribute11	
	format2:
		cmp al, 7
		jbe veryBadByte
		cmp al, 0Bh
		jbe attribute1
		cmp al, 0Eh
		jb attribute2
		jmp veryBadByte	
	format3:
		cmp al, 7
		jbe veryBadByte
		cmp al, 0Bh
		jbe attribute1
		cmp al, 0Eh
		jb attribute2
		jmp veryBadByte
	format8:
		cmp al, 3
		jbe attribute4
		cmp al, 8
		je attribute1
		cmp al, 0Ah
		je attribute1
		cmp al, 0Ch
		jb veryBadByte
		cmp al, 0Dh
		jbe attribute5
		cmp al, 0Eh
		je veryBadByte
		jmp attribute6
	formatA:
		cmp al, 3
		jbe attribute12
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
		jb veryBadByte
		cmp al, 7
		jbe attribute7
		cmp al, 0Eh
		jb veryBadByte
		cmp al, 0Eh
		je attribute7
		mov al, byte ptr[bx+si]
		cmp al, 0Fh
		jb veryBadByte
		cmp al, 37h
		jbe attribute6
		cmp al, 40h
		jb veryBadByte
		cmp al, 47h
		jbe attribute7
		cmp al, 50h
		jb veryBadByte
		cmp al, 57h
		jbe attribute6
		cmp al, 60h
		jb veryBadByte
		cmp al, 77h
		jbe attribute6
		cmp al, 80h
		jb veryBadByte
		cmp al, 87h
		jbe attribute7
		cmp al, 90h
		jb veryBadByte
		cmp al, 97h
		jbe attribute6
		cmp al, 0A0h
		jb veryBadByte
		cmp al, 0B7h
		jbe attribute6
		cmp al, 0C0h
		jb veryBadByte
		cmp al, 0C7h
		jbe attribute7
		cmp al, 0D0h
		jb veryBadByte
		cmp al, 0D7h
		jbe attribute6
		cmp al, 0E0h
		jb veryBadByte
		cmp al, 0F7h
		jbe attribute6
		jmp veryBadByte	
		attribute1:
			mov attribute, 1
			pop ax
			ret
		attribute2:
			mov attribute, 2
			pop ax
			ret
		attribute3:
			mov attribute, 3
			pop ax
			ret
		attribute4:
			mov attribute, 4
			pop ax
			ret
		attribute5:
			mov attribute, 5
			pop ax
			ret
		attribute6:
			mov attribute, 6
			pop ax
			ret
		attribute7:
			mov attribute, 7
			pop ax
			ret
		attribute8:
			mov attribute, 8
			pop ax
			ret
		attribute9:
			mov attribute, 9
			pop ax
			ret
		attribute10:
			mov attribute, 10
			pop ax
			ret	
		attribute11:
			mov attribute, 11
			pop ax
			ret
		attribute12:
			mov attribute, 12
			pop ax
			ret
		attribute13:
			mov attribute, 13
			pop ax
			ret
		attribute14:
			mov attribute, 14
			pop ax
			ret
		attribute15:
			mov attribute, 15
			pop ax
			ret
		attribute16:
			mov attribute, 16
			pop ax
			ret	
	veryBadByte:
		mov notFound, 1
		inc byteNumber
		pop ax
		ret
whatAttributes endp

proc createUnknown 
	push cx
	push si
	call IPandMC				
	mov cx, 10
	mov si, offset badCommand
	call rewrite		
	pop si
	pop cx
	ret
createUnknown endp

proc getEverything
	call getDbit
	call getWbit
	call getMod
	call getReg
	call getRM
	ret
getEverything endp

proc mainFunction
	push cx 
	push si 
	push ax 
	push di 
	mov di, offset operands
	cmp attribute, 1
	je A1
	cmp attribute, 2
	je A2
	cmp attribute, 3
	je A3
	cmp attribute, 4
	je A4
	cmp attribute, 5
	je A5
	cmp attribute, 6
	je A6
	cmp attribute, 7
	je A7
	cmp attribute, 8
	je A8
	cmp attribute, 9
	je A9
	cmp attribute, 10
	je A10
	cmp attribute, 11
	je A11
	cmp attribute, 12
	je A12
	cmp attribute, 13
	je A13
	cmp attribute, 14
	je A14
	cmp attribute, 15
	je A15
	jmp lastAttribute
	A1:
		add byteNumber, 2
		call getEverything
		cmp dBit, 1
		je toRegfromRM
			call inputRM
			call theComma
			call findRegwithAbReg
			call findReg
			call inputRegister
			jmp A1more
		toRegfromRM:
			call findRegwithAbReg
			call findReg
			call inputRegister
			call theComma
			call inputRM
			A1more:
				pop di
				pop ax
				call IPandMC
				mov cx, 3		
				cmp theFormat, 0
				je A1F0
				cmp theFormat, 2
				je A1F2
				cmp theFormat, 3
				je A1F3
					mov si, offset comMOV
				call rewrite
				jmp A1finish
				A1F0:	
					mov si, offset comADD
					call rewrite
					jmp A1finish
				A1F2:
					mov si, offset comSUB
					call rewrite
					jmp A1finish
				A1F3:			
					mov si, offset comCMP
					call rewrite	
				A1finish:
					call inputOperandLine
					jmp mainFunctionOver
	A2:
		mov cx, 3
		inc byteNumber
		call getWbit
		call findAkum
		add di, 2
		call theComma
		call betarpOperand	
		pop di
		pop ax
		call IPandMC
		mov cx, 3
		cmp theFormat, 0
		je A2F0
		cmp theFormat, 2
		je A2F2
			mov si, offset comCMP
			call rewrite
			jmp A2finish
		A2F0:
			mov si, offset comADD
			call rewrite
			jmp A2finish
		A2F2:
			mov si, offset comSUB
			call rewrite
			A2finish:
				call inputOperandLine
				jmp mainFunctionOver
	A3:
		inc byteNumber
		and al, 00000111b
		mov cx, ax
		mov wBit, 1
		call findReg
		mov si, offset register
		mov cx, 2
		call rewrite
		pop di
		pop ax
		push ax
		call IPandMC
		pop ax
		and al, 00001000b
		mov cx, 3
		cmp theFormat, 5
		je A3F5
			cmp al, 0
			je A3inc
				mov si, offset comDEC
				jmp A3finish
			A3inc:
				mov si, offset comINC
				jmp A3finish
		A3F5:
			cmp al, 0
			je A3F5push
				mov si, offset comPOP
				jmp A3finish
			A3F5push:
				mov si, offset comPUSH
				inc cx
				A3finish:
					call rewrite
					call inputOperandLine
					jmp mainFunctionOver
	A4:
		add byteNumber, 2
		call getEverything
		call inputRM
		call theComma	
		push si
		mov al, byteNumber
		sub al, 1
		add si, ax
		cmp dBit, 1
		je A4S1
			call betarpOperand
			jmp A4finish
		A4S1:
			cmp wBit, 1
			je A4S1W1
				mov wBit, 1
				call betarpOperand
				jmp A4finish
			A4S1W1:
				mov al, byte ptr[bx+si]
				call expandRule
				inc byteNumber
				mov cx, 4
				mov si, offset poslinkis
				call rewrite
				A4finish:
					pop si
					pop di
					pop ax
					call IPandMC
					mov cx, 3
					cmp abReg, 0
					je A4ADD
					cmp abReg, 7
					je A4CMP
						mov si, offset comSUB
						jmp A4finishfinish
					A4CMP:
						mov si, offset comCMP
						jmp A4finishfinish
					A4ADD:
						mov si, offset comADD
						A4finishfinish:
						call rewrite
						call inputOperandLine
						jmp mainFunctionOver
	A5:		
		add byteNumber, 2
		call getEverything
		push di
		call findSegment 
		call theComma
		call inputRM
		pop di
		pop ax
		call IPandMC
		mov si, offset comMOV
		mov cx, 3
		call rewrite
		call inputOperandLine
		jmp mainFunctionOver
	A6:
		add byteNumber, 2
		call getEverything
		call inputRM
		pop di
		pop ax
		call IPandMC
		mov cx, 3
		cmp theFormat, 8
		jne A6notPop
			mov si, offset comPOP
			jmp A6finish
		A6notPop:
			cmp abReg, 110b
			je A6push
			cmp abReg, 100b
			jae A6jmp
				mov si, offset comCALL
				inc cx
				jmp A6finish
			A6push:
				mov si, offset comPUSH
				inc cx
				jmp A6finish
			A6jmp:
				mov si, offset comJMP
				A6finish:
					call rewrite
					call inputOperandLine
					jmp mainFunctionOver
	A7:
		add byteNumber, 2
		call getEverything
		call inputRM
		pop di
		pop ax
		call IPandMC
		cmp abReg, 0
		je A7inc
		cmp abReg, 1
		je A7dec
		cmp abReg, 4
		je A7mul
			mov si, offset comDIV
			jmp A7finish
		A7inc:
			mov si, offset comINC
			jmp A7finish
		A7dec:
			mov si, offset comDEC
			jmp A7finish
		A7mul:
			mov si, offset comMUL
			A7finish:
				mov cx, 3
				call rewrite
				call inputOperandLine
				jmp mainFunctionOver
	A8:
		add byteNumber, 2
		call getEverything
		call inputRM
		call theComma
		call betarpOperand
		pop di
		pop ax
		call IPandMC
		mov si, offset comMOV
		mov cx, 3
		call rewrite
		call inputOperandLine
		jmp mainFunctionOver
	A9:
		pop di
		call IPandMC
		mov wBit, 1
		push di
		mov di, offset operands
		call betarpOperand
		pop di
		pop ax
		cmp al, 0CAh
		je A9retf
			mov cx, 3
			mov si, offset comRET
			call rewrite
			jmp A9finish
		A9retf:
			mov cx, 4
			mov si, offset comRETF
			call rewrite
			A9finish:
				call inputOperandLine
				jmp mainFunctionOver
	A10:
		inc byteNumber
		mov wBit, 0
		call betarpOperand
		pop di
		pop ax
		call IPandMC
		mov cx, 3
		mov si, offset comINT
		call rewrite
		call inputOperandLine
		jmp mainFunctionOver
	A11:
		inc byteNumber
		pop di
		call IPandMC
		mov cx, 3
		pop ax
		cmp theFormat, 0
		je A11F0
		cmp theFormat, 1
		je A11F1
			cmp al, 0CBh
			je A11RETF
			cmp al, 0CFh
			je A11IRET
				mov si, offset comRET
				jmp A11final
			A11RETF:
				inc cx
				mov si, offset comRETF
				jmp A11final
			A11IRET:
				inc cx
				mov si, offset comIRET
				jmp A11final
		A11F0:
			cmp al, 0Fh
			je A11POPCS
			cmp al, 0Eh
			je A11PUSHCS
			cmp al, 7h
			je A11POPES
				inc cx
				mov si, offset comPUSH
				A11ES:
					call rewrite
					mov cx, 2
					mov si, offset preES
					jmp A11final
			A11POPCS:
				mov si, offset comPOP
				jmp A11CS
			A11PUSHCS:
				inc cx
				mov si, offset comPUSH
				A11CS:
					call rewrite
					mov cx, 2
					mov si, offset preCS
					jmp A11final
			A11POPES:
				mov si, offset comPOP
				jmp A11ES
		A11F1:
			cmp al, 6h
			je A11PUSHSS
			cmp al, 0Fh
			je A11POPDS
			cmp al, 7h
			je A11POPSS
				inc si
				mov si, offset comPUSH
				inc cx
				A11DS:
					call rewrite
					mov cx,2
					mov si, offset preDS
					jmp A11final
			A11PUSHSS:
				inc si
				mov si, offset comPUSH
				A11SS:
					call rewrite
					mov cx, 2
					mov si, offset preSS
					jmp A11final
			A11POPDS:
				mov si, offset comPOP
				jmp A11DS
			A11POPSS:
				mov si, offset comPOP
				jmp A11SS
				A11final:
					mov al, tab
					call input
					call rewrite
					jmp mainFunctionOver
	A12:
		add byteNumber, 3
		call getDbit
		call getWbit
		push si
		cmp dBit, 1
		je A12D1
			call findAkum
			add di, 2
			call theComma
			mov al, openBracket
			call input
			call directAddress
			mov si, offset poslinkis
			mov cx, 4
			call rewrite
			mov al, closeBracket
			call input
			jmp A12finish
		A12D1:
			mov al, openBracket
			call input
			call directAddress
			mov si, offset poslinkis
			mov cx, 4
			call rewrite
			mov al, closeBracket
			call input
			call theComma
			call findAkum
			A12finish:
				pop si
				pop di
				pop ax
				call IPandMC
				mov cx, 3
				mov si, offset comMOV
				call rewrite
				call inputOperandLine
				jmp mainFunctionOver
	A13:
		inc byteNumber
		push ax
		and al, 00001000b
		shr al, 3
		mov wBit, al
		pop ax
		push ax
		and al, 00000111b
		mov cx, ax
		pop ax
		call findReg 
		call inputRegister
		call theComma
		call betarpOperand
		pop di
		pop ax
		call IPandMC
		mov cx,3
		mov si, offset comMOV
		call rewrite
		call inputOperandLine
		jmp mainFunctionOver
	A14:
		add byteNumber, 2
		xor cx, cx
		mov cl, byte ptr[bx+si]
		cmp cl, 80h
		jb A14dontExpand
			mov ch, 0FFh
		A14dontExpand:
			call findJump
			pop di
			call IPandMC
			pop ax
			cmp theFormat, 0Eh
			je A14E	
				mov cx, 3
				cmp al, 71h
				je A14jno
				cmp al, 72h
				je A14jb
				cmp al, 73h
				je A14jnb
				cmp al, 74h
				je A14je
				cmp al, 75h
				je A14jne
				cmp al, 76h
				je A14jbe
				cmp al, 77h
				je A14jnbe
				cmp al, 78h
				je A14js
				cmp al, 79h
				je A14jns
				cmp al, 7Ah
				je A14jpe
				cmp al, 7Bh
				je A14jpo
				cmp al, 7Ch
				je A14jl
				cmp al, 7Dh
				je A14jnl
				cmp al, 7Eh
				je A14jle
				cmp al, 7Fh
				je A14jnle
					mov si, offset comJO
					jmp A14finish
				A14jno:
					mov si, offset comJNO
					jmp A14finish
				A14jb:
					mov si, offset comJB
					jmp A14finish
				A14jnb:
					mov si, offset comJNB
					jmp A14finish
				A14je:
					mov si, offset comJE
					jmp A14finish
				A14jne:
					mov si, offset comJNE
					jmp A14finish
				A14jbe:
					mov si, offset comJBE
					jmp A14finish
				A14jnbe:
					mov si, offset comJNBE
					inc cx
					jmp A14finish
				A14js:
					mov si, offset comJS
					jmp A14finish
				A14jns:
					mov si, offset comJNS
					jmp A14finish
				A14jpe:
					mov si, offset comJPE
					jmp A14finish
				A14jpo:
					mov si, offset comJPO
					jmp A14finish
				A14jl:
					mov si, offset comJL
					jmp A14finish
				A14jnl:
					mov si, offset comJNL
					jmp A14finish
				A14jle:
					mov si, offset comJLE
					jmp A14finish
				A14jnle:
					mov si, offset comJNLE
					inc cx
					jmp A14finish
			A14E:
				mov cx, 3
				cmp al, 0E3h
				je A13jcxz
				cmp al, 0E2h
				je A13loop
					mov si, offset comJMP
					jmp A14finish
				A13jcxz:
					mov si, offset comJCXZ
					inc cx
					jmp A14finish
				A13loop:
					mov si, offset comLOOP
					inc cx
					A14finish:
						call rewrite
						call inputOperandLine
						jmp mainFunctionOver
	A15:
		add byteNumber, 3
		push si
		mov cl, byte ptr[bx+si]
		inc si
		mov ch, byte ptr[bx+si]
		pop si
		call findJump
		pop di
		call IPandMC
		pop ax
		mov cx, 3
		mov si, offset comJMP
		cmp al, 0E9h
		je A15finish
			mov si, offset comCALL
			inc cx
		A15finish:
			call rewrite
			call inputOperandLine
			jmp mainFunctionOver
	lastAttribute:
		add byteNumber, 5
		push si
		inc si
		mov ah, byte ptr[bx+si]
		dec si
		mov al, byte ptr[bx+si]
		mov cx, 4
		call hexInput
		mov al, colon
		call input
		add si, 3
		mov ah, byte ptr[bx+si]
		dec si
		mov al, byte ptr[bx+si]
		mov cx,4
		call hexInput
		pop si
		pop di
		pop ax
		call IPandMC
		mov cx, 3
		cmp theFormat, 9
		je laCall
			mov si, offset comJMP
			jmp laFinish
		laCall:
			mov si, offset comCALL
			inc cx
			laFinish:
				call rewrite
				call inputOperandLine
						mainFunctionOver:
							pop si
							pop cx
							ret
mainFunction endp

proc findJump ; cx = poslinkis
	push ax
	mov ax, iPointer
	add al, byteNumber
	add ax, cx
	mov cx, 4
	call hexInput
	pop ax
	ret
findJump endp

proc findSegment
	push ax
	push si
	xor ax, ax
	mov al, abReg
	mov si, offset segReg
	add si, ax
	mov al, byte ptr[si]
	mov byte ptr[di], al
	inc di
	mov byte ptr[di], "S"
	inc di
	pop si
	pop ax
	ret
findSegment endp

proc betarpOperand
	push si
	push cx
	mov al, byte ptr[bx+si]
	cmp wBit, 1
	je bow1
		inc byteNumber
		mov cx,2
		jmp boMore
	bow1:
		add byteNumber,2
		inc si
		mov ah, byte ptr[bx+si]
		mov cx,4
		boMore:
			call hexInput
			pop cx
			pop si
			ret
betarpOperand endp

proc findAkum 
	push si
	cmp wBit, 1
	je words
		mov si, "LA"
		jmp findAkumOver
	words:
		mov si, "XA"
		findAkumOver:
			mov word ptr[di], si
			pop si
			ret	
findAkum endp

proc inputRM
	cmp abMod, 11b
	je useRegisterslmao
		push si
		mov al, openBracket
		call input
		cmp abRM, 110b
		je takeAddress
		justSkip:
		cmp abRM,0
		je firstRM
		cmp abRM,1
		je secndRM
		cmp abRM,2
		je thirdRM
		cmp abRM,3
		je forthRM
		cmp abRM,4
		je fifthRM
		cmp abRM,5
		je sixthRM
		cmp abRM,6
		je svnthRM
			mov si, offset rm7
			call rmcl2
			jmp rmPartTwo
		firstRM:
			mov si, offset rm0
			call rmcl5
			jmp rmPartTwo
		secndRM:
			mov si, offset rm1
			call rmcl5
			jmp rmPartTwo
		thirdRM:
			mov si, offset rm2
			call rmcl5
			jmp rmPartTwo		
		forthRM:
			mov si, offset rm3
			call rmcl5
			jmp rmPartTwo	
		fifthRM:
			mov si, offset rm4
			call rmcl2
			jmp rmPartTwo
		sixthRM:
			mov si, offset rm5
			call rmcl2
			jmp rmPartTwo	
		svnthRM:
			mov si, offset rm6
			call rmcl2
		rmPartTwo:
		pop si
		cmp abMod, 00b
		je bePoslinkio
			push si
			mov al, plus
			call input
			inc si
			mov al, byte ptr[bx+si]
			cmp abMod, 01b
			je expandByte
				call directAddress
				call suPoslinkiu
				add byteNumber,2
				pop si
				ret
			expandByte:
				call expandRule 
				call suPoslinkiu
				inc byteNumber
				pop si
				ret
		bePoslinkio:
			mov al, closeBracket
			call input
			ret
		takeAddress:
			cmp abMod, 00b
			jne justSkip
			add byteNumber, 2
			inc si
			call directAddress
			call suPoslinkiu
			pop si
			ret
	useRegisterslmao:
		xor ax, ax
		mov al, abRM
		mov cx, ax
		call findReg
		call inputRegister
		ret
inputRM endp

proc findRegwithAbReg
	xor ax, ax
	mov al, abReg
	mov cx, ax
	ret
findRegwithAbReg endp

proc suPoslinkiu
	push si
	mov si, offset poslinkis
	mov cx, 4
	call rewrite
	mov al, closeBracket
	call input
	pop si
	ret
suPoslinkiu endp

proc expandRule 
	push di
	push ax
	mov di, offset poslinkis
	shr al, 7
	cmp al, 1
	je ones
		mov ax, "00"
		jmp ERfinish
	ones:
		mov ax, "FF"
	ERfinish:
		mov word ptr[di], ax
		pop ax
		add di, 2
		mov cx, 2
		call hexInput
		pop di
		ret
expandRule endp

proc rmcl5
	mov cx, 5
	call rewrite
	ret
rmcl5 endp

proc rmcl2
	mov cx, 2
	call rewrite
	ret
rmcl2 endp

proc theComma
	push si
	mov si, offset comma
	mov cx,2
	call rewrite
	pop si
	ret
theComma endp

proc inputRegister
	push si
	mov si, offset register
	mov cx, 2
	call rewrite
	pop si
	ret
inputRegister endp

proc findReg
	push di 
	push si
	mov di, offset register
	cmp wBit, 0
	je wIs0
		mov si, offset w1array
		add si, cx
		call useTableMov
		inc di
		cmp cx, 3
		jbe theLetterX
		cmp cx, 5
		jbe theLetterP
			mov byte ptr[di], "I"
			jmp frEnd
		theLetterP:
			mov byte ptr[di], "P"
			jmp frEnd
		theLetterX:
			mov byte ptr[di], "X"
			jmp frEnd
	wIs0:
		mov si, offset w0array
		add si, cx
		call useTableMov
		inc di
		cmp cx, 3
		ja theLetterH
			mov byte ptr[di], "L"
			jmp frEnd
		theLetterH:
			mov byte ptr[di], "H"
			jmp frEnd
	frEnd:
		pop si
		pop di
		ret
findReg endp

proc useTableMov
	mov al, byte ptr[si]
	mov byte ptr[di], al
	ret
useTableMov endp

proc inputOperandLine
	push cx
	mov al, tab
	call input
	mov cx, 16
	mov si, offset operands
	call rewrite
	pop cx
	ret
inputOperandLine endp

proc directAddress 
	push ax
	push di
	push cx
	inc si
	mov ah, byte ptr[bx+si] 
	dec si
	mov al, byte ptr[bx+si] 
	mov di, offset poslinkis
	mov cx, 4
	call hexInput
	inc si
	pop cx
	pop di
	pop ax
	ret
directAddress endp

proc getDbit
	push ax
	and al, 00000010b
	shr al, 1
	mov dBit, al
	pop ax
	ret
getDbit endp

proc getWbit
	push ax
	and al, 00000001b
	mov wBit, al
	pop ax
	ret
getWbit endp

proc getMod
	push ax
	mov al, byte ptr[bx+si] 
	and al, 11000000b
	shr al, 6
	mov abMod, al
	pop ax
	ret
getMod endp

proc getReg
	push ax
	mov al, byte ptr[bx+si]
	and al, 00111000b
	shr al, 3
	mov abReg, al
	pop ax
	ret
getReg endp

proc getRM
	push ax
	mov al, byte ptr[bx+si]
	and al, 00000111b
	mov abRM, al
	pop ax
	ret
getRM endp

proc printLine
	mov ah, 09h
	int 21h
	ret
printLine endp

proc fileNameRead 
	push ax
	begin:
		mov ax, es:[si]
		inc si
		cmp al, 0dh 							
		je introduction							
		cmp al, 20h 							 
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

proc openFile 
	int 21h
	jc oError 
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
	mov bx, rHandle
	mov dx, offset readBuf
	mov ah, 3fh
	mov cx, rBufSize
	int 21h
	jc readingError
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
	mov ah, 3eh
	int 21h
	jc closingError
		pop ax
		ret
	closingError:
		mov dx, offset closeError
		call printLine
		jmp finale
closeFile endp

proc findLineLength
	push si
	push cx
	xor cx, cx
	mov si, offset writeBuf
	notNewLine:
		inc cx
		inc si
		cmp byte ptr[si], 0
		je NLfound
		jmp notNewLine
	NLfound:
		mov byte ptr[si], 0Ah
		mov lineLength, cl
		inc lineLength
		pop cx
		pop si
		ret
findLineLength endp

proc writeToFile
	push bx
	push dx
	push ax
	push cx
	xor cx, cx
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

proc resetBuffers
	push cx
	push si
	xor cx, cx
	mov si, offset writeBuf
	mov cl, lineLength
	call zeroOut
	mov si, offset operands
	mov cl, 16
	call zeroOut
	pop si
	mov al, byteNumber
	dec ax
	add si, ax
	mov byteNumber, 0
	pop cx
	ret
endp resetBuffers

proc zeroOut
	loopityloop:
		mov byte ptr[si], 0
		inc si
		loop loopityloop
	ret		
zeroOut endp

end start