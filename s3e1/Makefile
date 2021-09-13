all: clean task1

task1:
	nasm -f elf task1.asm -o task1.o
	ld -m elf_i386 task1.o -o task1

clean:
	rm -f task1.o task1