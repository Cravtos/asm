all: task1 task2 task3 task4 task5 task6 task7 task8 task9 task10

clean:
	rm -f *.o
	ls | grep -P "^task\d+$$" | xargs -d"\n" -r rm 

task1: task1.o
	ld -m elf_i386 task1.o -o task1

task1.o:
	nasm -f elf task1.asm -o task1.o -g

task2: task2.o
	ld -m elf_i386 task2.o -o task2

task2.o:
	nasm -f elf task2.asm -o task2.o -g

task3: task3.o
	ld -m elf_i386 task3.o -o task3

task3.o:
	nasm -f elf task3.asm -o task3.o -g

task4: task4.o
	ld -m elf_i386 task4.o -o task4

task4.o:
	nasm -f elf task4.asm -o task4.o -g

task5: task5.o
	ld -m elf_i386 task5.o -o task5

task5.o:
	nasm -f elf task5.asm -o task5.o -g

task6: task6.o
	ld -m elf_i386 task6.o -o task6

task6.o:
	nasm -f elf task6.asm -o task6.o -g

task7: task7.o
	ld -m elf_i386 task7.o -o task7

task7.o:
	nasm -f elf task7.asm -o task7.o -g

task8: task8.o
	ld -m elf_i386 task8.o -o task8

task8.o:
	nasm -f elf task8.asm -o task8.o -g

task9: task9.o
	ld -m elf_i386 task9.o -o task9

task9.o:
	nasm -f elf task9.asm -o task9.o -g

task10: task10.o
	ld -m elf_i386 -dynamic-linker /lib/ld-linux.so.2 -o task10 -lc task10.o

task10.o:
	nasm -f elf task10.asm -o task10.o -g
