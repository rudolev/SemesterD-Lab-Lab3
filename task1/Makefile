# Variables
CC = gcc
AS = nasm
LD = ld

CFLAGS = -m32 -Wall -ansi -c -nostdlib -fno-stack-protector
ASFLAGS = -f elf32
LDFLAGS = -m elf_i386

# Targets
all: task1

task1: start.o util.o
	$(LD) $(LDFLAGS) start.o util.o -o task1

start.o: start.s
	$(AS) $(ASFLAGS) start.s -o start.o

util.o: util.c
	$(CC) $(CFLAGS) util.c -o util.o

# Clean up build files
clean:
	rm -f *.o task1