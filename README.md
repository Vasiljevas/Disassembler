# Disassembler
A disassembler is a program that converts machine code into assembly language instructions. Below is more information on how it works and its requirements:

## What is a Disassembler?
A disassembler performs the reverse operation of an assembler compiler. It translates machine code back into assembly language. For example, the machine code bytes "8A CF" translate to the assembly command "MOV cl, bh". The disassembler reads these bytes and identifies the corresponding command and registers.

## Key Points
Commands can vary in length, from one to six bytes.
The length of a command can only be determined by reading and recognizing it.
## Example
The machine code for "CMP [bx+0105], 0804" is "81 BF 05 01 04 08". After reading the first byte "81", the disassembler knows it's a command with an immediate operand of two bytes. After reading the next byte "BF", it calculates the total command length: 6 bytes.

## Requirements for the Disassembler
When run with the argument "/?", it should display the author's name, course, group, and a brief program description.
All parameters should be provided via command line, not through keyboard input. For example: disasm prog.com prog.asm.
The output should be written to a file.
If run without parameters or with incorrect parameters, it should display a help message similar to the one shown with "/?".
It should handle input/output errors, such as a non-existent file, by displaying a help message and exiting.
The buffer size for reading/writing files must be at least 10 bytes, even if the file size exceeds this buffer.
## Commands to be Recognized
Segment override prefixes
All variants of MOV (6)
All variants of PUSH (3)
All variants of POP (3)
All variants of ADD (3)
All variants of INC (2)
All variants of SUB (3)
All variants of DEC (2)
All variants of CMP (3)
MUL
DIV
All variants of CALL (4)
All variants of RET (4)
All variants of JMP (5)
All conditional jump commands (17)
LOOP
INT
## Additional Information
If a byte is unrecognizable, it should be skipped (noted in the result file) and the next byte should be attempted.
The first command in a .com file starts at an offset of 100h from the segment's start. The output should include the offset from the code segment's start, the machine code of the command, and the command itself.

## Provided Files
A test .com file and its assembly code in an .asm file should be included with the program.
