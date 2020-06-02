all: clean build

build: main.c pow.o
	gcc -m32 main.c pow.o

pow.o: pow.asm
	nasm -g -f elf -o pow.o pow.asm

clean:
	rm -f a.out
	rm -f pow.o