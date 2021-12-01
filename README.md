**Programs written to learn NASM**
===

## **WARNING: not properly tested bad code, do not copy**  
  


To compile and run:  

```bash
nasm -f elf foo.asm -o foo.o
ld -m elf_i386 foo.o -o foo
./foo
```
