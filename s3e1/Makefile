all: clean task1 task2 task3

task1:
	nasm -f elf task1.asm -o task1.o -g
	ld -m elf_i386 task1.o -o task1

task2:
	nasm -f elf task2.asm -o task2.o -g
	ld -m elf_i386 task2.o -o task2

task3:
	nasm -f elf task3.asm -o task3.o -g
	ld -m elf_i386 task3.o -o task3


task4:
	nasm -f elf task4.asm -o task4.o -g
	ld -m elf_i386 task4.o -o task4

clean:
	rm -f task1.o task1
	rm -f task2.o task2
	rm -f task3.o task3
	rm -f task4.o task4

