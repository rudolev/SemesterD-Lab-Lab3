# Variables
CC = gcc
AS = nasm
LD = ld

CFLAGS = -m32 -Wall -ansi -c -nostdlib -fno-stack-protector
ASFLAGS = -f elf32
LDFLAGS = -m elf_i386

# Targets
all: task2

task2: start.o main.o util.o
	$(LD) $(LDFLAGS) start.o main.o util.o -o task2

start.o: start.s
	$(AS) $(ASFLAGS) start.s -o start.o

util.o: util.c
	$(CC) $(CFLAGS) util.c -o util.o

main.o: main.c
	$(CC) $(CFLAGS) main.c -o main.o

# Clean up build files
clean:
	rm -f *.o task2