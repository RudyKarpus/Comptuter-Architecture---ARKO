program = mandelbrot

OBJECTS = main.o mandelbrot.o

CC = gcc
NASM = nasm

CFLAGS = -c -g -Wall -Wextra -I src/include/SDL2

LDFLAGS = -L src/include/lib -lSDL2main -lSDL2 -lm -ldinput8 -ldxguid -lole32 -lsetupapi -lwinmm -limm32

NASMFMT = -f win64
NASMOPT = -w all

all: $(program)

$(program): $(OBJECTS)
	$(CC) -o $(program) $(OBJECTS) $(LDFLAGS)

main.o: main.c mandelbrot.h
	$(CC) $(CFLAGS) main.c -o main.o

mandelbrot.o: mandelbrot.s mandelbrot.h
	$(NASM) $(NASMFMT)  $(NASMOPT) mandelbrot.s -o mandelbrot.o

clean:
	del  /Q *.o $(program).exe