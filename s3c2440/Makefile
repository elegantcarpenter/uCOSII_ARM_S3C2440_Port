first:start.o main.o

start.o:start.s
	arm-linux-gcc -O0 -g3 -c start.s -o start.o
main.o: main.c
	#arm-linux-gcc -fPIC -c main.c -o main.o
	arm-linux-gcc -O0 -g3 -c main.c -o main.o


clean:
	rm -f *.o
