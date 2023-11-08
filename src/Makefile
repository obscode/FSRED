.c.o :
	$(CC) -c $*.c 
gcc = /usr/bin/gcc
CC = $(gcc) -g -O3 -Wall
#CC = gcc -g -O2 -Wall -DmacOSX -DNEED_SWAP
GSLLIBS = -I/usr/local/include -L/usr/local/lib -lgsl -lgslcblas
CFITSIO = -I/usr/local/include -L/usr/local/lib -lcfitsio -lpthread -lm
FFTW3 = -I/usr/local/include -L/usr/local/lib -lfftw3

liststruc: liststruc.c
	$(CC) liststruc.c -o liststruc $(CFITSIO)
mimsurfit: mimsurfit.c
	$(CC) mimsurfit.c -o ../IRAF/x_mimsurfit $(GSLLIBS) $(CFITSIO)
skycombine: skycombine.c
	$(CC) skycombine.c -o ../IRAF/x_skycombine $(GSLLIBS) $(CFITSIO)
fsimsurfit: mimsurfit.c
	$(CC) fsimsurfit.c -o ../IRAF/x_fsimsurfit $(GSLLIBS) $(CFITSIO)
test: test.c
	$(CC) test.c -o ../IRAF/x_test	 $(GSLLIBS) $(CFITSIO)
rps: rps.c
	$(CC) rps.c -o x_rps	 $(GSLLIBS) $(CFITSIO)
fft: fft.c
	$(CC) fft.c -o x_fft	 $(GSLLIBS) $(CFITSIO) $(FFTW3)
imexpr: imexpr.c
	$(CC) imexpr.c -o ../IRAF/x_imexpr $(GSLLIBS) $(CFITSIO)
imstat: imstat.c
	$(CC) imstat.c -o x_imstat $(GSLLIBS) $(CFITSIO)
pvsip: pvsip.c
	$(CC) pvsip.c -o ../DISTORTION/pvsip $(GSLLIBS) $(CFITSIO)
clean:
	rm ../IRAF/x_mimsurfit ../IRAF/x_imexpr ../IRAF/x_test
