all:
	gcc dpi.c -I/usr/include/python2.6 -I/home/leat/cadence/installs/INCISIV132/tools.lnx86/include/ -fpic -shared -o libdpi.so
	irun -64 dpi.sv -I/usr/include/python2.6

compile:
	gcc -c dpi.c -I/home/leat/cadence/installs/INCISIV132/tools.lnx86/include/ -I/usr/include/python2.6 -I/usr/include/python2.6 -fno-strict-aliasing -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -D_GNU_SOURCE -fPIC -fwrapv -DNDEBUG -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -D_GNU_SOURCE -fPIC -fwrapv
	gcc dpi.o -lpthread -ldl -lutil -lm -lpython2.6 -shared -o libdpi.so

custom:
	irun -64 dpi.c dpi.sv