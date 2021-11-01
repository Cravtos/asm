all: task1 task2 task3 task4 task5

task1: clean_task1
	nasm -f elf task1.asm -o task1.o -g
	ld -m elf_i386 task1.o -o task1

task2: clean_task2
	nasm -f elf task2.asm -o task2.o -g
	ld -m elf_i386 task2.o -o task2

task3: clean_task3
	nasm -f elf task3.asm -o task3.o -g
	ld -m elf_i386 task3.o -o task3

task4: clean_task4
	nasm -f elf task4.asm -o task4.o -g
	ld -m elf_i386 task4.o -o task4

task5: clean_task5
	nasm -f elf task5.asm -o task5.o -g
	ld -m elf_i386 task5.o -o task5

clean: clean_task1 clean_task2 clean_task3 clean_task4 clean_task5

clean_task1:
	rm -f task1.o task1

clean_task2:
	rm -f task2.o task2

clean_task3:
	rm -f task3.o task3

clean_task4:
	rm -f task4.o task4

clean_task5:
	rm -f task5.o task5

test_task5: task5
	-./task5 0 0 # should be math error
	./task5 0 1
	./task5 1 1
	./task5 -1 1
	./task5 -1 2
	./task5 1 2
	./task5 1 0
	./task5 2 1
	./task5 2 0
	./task5 2 2
	./task5 2 9
	-./task5 2 -1 # should say power need to be positive
	./task5 -2 1
	./task5 -2 2
	./task5 -2 9
	./task5 -5 4
	-./task5 1 4294967296 # should say overflow
	./task5 -2147483648 1
	-./task5 -2147483649 1 # should say overflow
	-./task5 2147483648 1 # should say overflow
	./task5 2147483647 1
	./task5 1 4294967295
