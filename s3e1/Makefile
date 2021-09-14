all: clean task1 task2

task1:
	nasm -f elf task1.asm -o task1.o -g
	ld -m elf_i386 task1.o -o task1

task2:
	nasm -f elf task2.asm -o task2.o -g
	ld -m elf_i386 task2.o -o task2

clean:
	rm -f task1.o task1
	rm -f task2.o task2
