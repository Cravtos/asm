**Programs written to learn NASM**
===

To compile:  
```bash
nasm -f elf program.asm -o program.o
ld -m elf_i386 program.o -o program
```
