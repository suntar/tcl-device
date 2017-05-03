CFLAGS = -O2 -Wall -fPIC

locktcl.so: locktcl.c locklib.h locklib.o
	$(CC) -shared $(CFLAGS) -o locktcl.so \
            locktcl.c locklib.o

locklib.o: locklib.c locklib.h

clean:
	rm -f *.o *.so