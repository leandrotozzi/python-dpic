PYINC=-I/usr/include/python2.7 -I/usr/include/x86_64-linux-gnu/python2.7
LIBS=-L/usr/lib/python2.7/config-x86_64-linux-gnu -L/usr/lib -lpython2.7 -lpthread -ldl  -lutil -lm  -Xlinker -export-dynamic -Wl,-O1 -Wl,-Bsymbolic-functions
OPTS=-fno-strict-aliasing -Wdate-time -D_FORTIFY_SOURCE=2 -g -fstack-protector-strong -Wformat -Werror=format-security  -DNDEBUG -g -fwrapv -O2 -Wall -Wstrict-prototypes
PROGRAMS=pystring pyinfo pyreverse pycelsius
all: $(PROGRAMS)

pyinfo: pyinfo.o
	gcc pyinfo.o $(LIBS) -o pyinfo
pyinfo.o: pyinfo.c
	gcc pyinfo.c -c $(PYINC) $(OPTS)

pystring: pystring.o
	gcc pystring.o $(LIBS) -o pystring
pystring.o: pystring.c
	gcc pystring.c -c $(PYINC) $(OPTS)

pyreverse: pyreverse.o
	gcc pyreverse.o $(LIBS) -o pyreverse
pyreverse.o: pyreverse.c
	gcc pyreverse.c -c $(PYINC) $(OPTS)

pycelsius: pycelsius.o
	gcc pycelsius.o $(LIBS) -o pycelsius
pycelsius.o: pycelsius.c
	gcc pycelsius.c -c $(PYINC) $(OPTS)

clean:
	rm -f $(PROGRAMS) *.o *.pyc core
