#!/bin/csh -f

set fsred = $0:h
set prefix = /usr/local

# SET WHICH GCC TO USE, IF MULTIPLE ENTRIES EXIST USE THE FIRST VALID ENTRY FOUND.
set dgcc = ( /usr/bin/gcc /usr/local/bin/gcc /opt/local/bin/gcc )
#set dgcc = ( /opt/local/bin/gcc )



# IF RUNNING INSTALL SCRIPT FROM THE CURRENT DIRECTORY ( ./install.csh )
# SET THE ABSOLUTE PATH.  
if ( $fsred == . ) then
    set fsred = `pwd`
endif
set install_dir = $fsred/FSRED_SUP1

# CHECK DEFAULT GCC OPTIONS
foreach tgcc ( $dgcc )
    if ( `$tgcc -v >>& /dev/null ; echo $status` ) then
	echo $tgcc Not Found
    else
	if ( 0 ) then

	else
	    echo Using $tgcc 
	    awk '{if($0 ~ "gcc ="){print "gcc = '$tgcc'"}else{print}}' $fsred/src/Makefile.orig > $fsred/src/Makefile
	    break
	endif
    endif
end
if (  `$tgcc -v >>& /dev/null ; echo $status` ) then
    echo No Valid gcc found.  Exiting
    exit 1
endif

# IF IRAF IS NOT INSTALLED...
set irafprefix = /iraf/iraf/
set firaf = ftp://iraf.noao.edu/iraf/v216/PCIX
# AS FAR AS I CAN TELL, EVERYTHING BELOW IS FREELY RE-DISTRIBUTABLE UNDER THE GNU LICENSE
set gcc = gcc-4.7-bin.tar.gz               #  http://hpc.sourceforge.net/
set mport = MacPorts-2.1.2.tar.gz          #  http://www.macports.org/install.php
set atlas = atlas3.10.3.tar.bz2            #  http://math-atlas.sourceforge.net/  ||  http://sourceforge.net/projects/math-atlas/files/    
set lapack = lapack-3.4.1.tgz              #  http://www.netlib.org/lapack/
set fftw = fftw-3.3.2.tar.gz               #  http://www.fftw.org/download.html
set plot = plplot-5.9.9.tar.gz             #  http://plplot.sourceforge.net/      ||  http://sourceforge.net/projects/plplot/files/
set wcstools = wcstools-3.8.5.tar.gz       #  http://tdc-www.harvard.edu/wcstools/
set cfitsio = cfitsio3310.tar.gz           #  http://heasarc.gsfc.nasa.gov/fitsio/
set gsl = gsl-1.15.tar.gz                  #  http://www.gnu.org/software/gsl/
set cdsclient = cdsclient-3.71.tar.gz      #  http://cdsarc.u-strasbg.fr/doc/cdsclient.html
#set sex = sextractor-trunk.r302.tar.gz     #  http://www.astromatic.net/software/sextractor
set sex = sextractor-2.28.0.tar.gz
set scamp = scamp-2.10.0.tar.gz        #  http://www.astromatic.net/software/scamp
set swarp = swarp-2.41.5.tar.gz        #  http://www.astromatic.net/software/swarp
set psfex = psfex-trunk.r184.tar.gz        #  http://www.astromatic.net/software/psfex



set machine = `uname -sm`
set sed = `which \sed`
if ( $machine[1] =~ Linux && ( $machine[2] =~ i386 || $machine[2] =~ i686 ) ) then
    set sedi = "$sed -i''"
    set irafarch = "linux"
    set option = 4
    set bflag = 32
    set NCPU = `grep -c processor /proc/cpuinfo`
else if ( $machine[1] =~ Linux && $machine[2] =~ x86_64 ) then
    set sedi = "$sed -i''"
    set irafarch = "linux"
    set option = 3
    set bflag = 64
    set NCPU = `grep -c processor /proc/cpuinfo`
else if ( $machine[1] =~ Darwin && ( $machine[2] =~ i386 || $machine[2] =~ 6386 ) ) then
    set sedi = "$sed -i ''"
    set irafarch = "macosx"
    set option = 2
    set bflag = 32
    set NCPU = `sysctl -n hw.ncpu` 
else if ( $machine[1] =~ Darwin && $machine[2] =~ x86_64 ) then
    set sedi = "$sed -i ''"
    set irafarch = "macintel"
    set option = 1
    set bflag = 64
    set NCPU = `sysctl -n hw.ncpu` 
else
    set sedi = "$sed -i ''"
    set irafarch = "macosx"
    set bflag = 32
    set NCPU = 1
endif
printf "%s %s CPU's: %d\n" $machine[1] $machine[2] $NCPU
alias sedi $sedi

if ( $machine[1] =~ Darwin ) then
    set VERSION = `sw_vers | grep ProductVersion | awk '{print $2}'`
    set xcode = `xcode-select --print-path`
    if ( $status ) then
	printf "XCODE not Found.  Install XCODE first then continue.   Exiting... \n"
	exit 1
    else
	printf "XCODE found: $xcode.\n"
    endif
else
    set VERSION = 0
endif



# INSTALL XCODE 4.4.1 (or latest avilable for platform) for MAC's.  
# On LION & M. LION, with XCode 4.x you will need to download the command-line tools as an additional step. You will find the option to download the command-line tools in XCode's Preferences.
# install command line tools from within Xcode -> Preferences -> Downloads, Components.  
# includes things like, make, gcc, etc.
syst:
foreach var1 ( csh gcc make install libtool cmake wget awk automake )
    set found = 1
    foreach var2 ( /usr/bin/ /usr/local/bin/ /bin/ /opt/local/bin/ ) 
	set var = $var2$var1
	ls $var >>& /dev/null
	if ( $status == 0 ) then
	    printf "%-60s %10s\n" $var FOUND
	    set found = 0
	    break
	else
	    printf "%-60s %10s\n" $var NOT-FOUND
	endif
    end
    if ( $found ) then
        echo $var1 not found.
	rehash
	if ( 0 ) then
	    if ( `which $var1 >>& /dev/null ; echo $status` == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		continue
	    endif
	    if ( $machine[1] =~ Darwin) then
		echo suggest installing $var1 via macports...
		if ( `which port >>$ /dev/null ; echo $status` ) then
		    printf "Install MacPorts in /opt/local/ [n|y]: "
		    set input = $<
		    if ( $input == y || $input == yes ) then
			printf "Installing Macports...\n"
			mkdir -p $install_dir/macports
			tar -zxf $install_dir/$mport -C $install_dir/macports
			cd $install_dir/macports/MacPorts*
			./configure && make && sudo make install
			sudo port -v selfupdate
		    else
			printf "Continuing without installing Macports...\n"
		    endif
		else
		    printf "Install $var1 in /opt/local/bin/ [n|y]: "
		    set input = $<
		    if ( $input == y || $input == yes ) then
			sudo port install $var1
		    else
			printf "Not installing $var1.\n"
		    endif
		endif
	    else
		printf "Install $var1 using your favorite package manager then continue...exiting."
		exit 1
	    endif
	    goto syst
	else
	    printf "Install $var1 using your favorite package manager then continue...exiting."
	    exit 1
        endif
#	exit 1
    endif
end
#exit 0


# INSTALL HPC C-compilers from http://hpc.sourceforge.net/
hpc:
if ( 0 ) then
if ( -e /usr/local/bin/gcc ) then
    printf "Using /usr/local/bin/gcc \n"    
    # set CC environment variable, make sure it is the gcc pointed that was installed from the HPC earlier (/usr/local/bin).   NOT (/usr/bin) the default MAC gcc. 
    setenv CC "/usr/local/bin/gcc"
    $CC -v
else if ( ( $machine[1] =~ Darwin && ( `echo $VERSION | grep 10.7` != "" || `echo $VERSION | grep 10.8` != "" )) ) then
    # INSTALLS EVERYTHING IN /usr/local
    printf "Install HPC gcc in /usr/local/bin [n|y]: "
    set input = $<
    if ( $input == y || $input == yes ) then
	sudo tar -zxvf $install_dir/$gcc -C /.
	goto hpc
    else
	printf "Continuing without installing HPC gcc...\n"
#	exit 1
    endif
else if ( 0 && -e /opt/local/bin/gcc-mp-4.5 ) then
    setenv CC "/opt/local/bin/gcc-mp-4.5"
    $CC -v
else
    which gcc
    if ( $status ) then
	printf "No gcc found.  Exiting...\n"
	exit 1
    endif
endif
endif

#exit 0


# IRAF
iraf:
set found = 1
which mkiraf >>& /dev/null
if ( $status == 0 ) then
    set found = 0
    set mkiraf = `which mkiraf`
    set iraf =  `ls -la $mkiraf | awk '{print $NF}'`
    set iraf = $iraf:h:h:h
    foreach var1 ( x_images.e x_proto.e x_nproto.e  )
	set found = 1
	foreach var2 ( $iraf/bin/ $iraf/noao/bin/ $iraf/bin.macosx/ $iraf/noao/bin.macosx/ $iraf/bin.macintel/ $iraf/noao/bin.macintel/ $iraf/bin.linux/ $iraf/noao/bin.linux/ $iraf/bin.redhat/ $iraf/noao/bin.redhat/ ) 
	    set var = $var2$var1
	    ls $var >>& /dev/null
	    if ( $status == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		set found = 0
		break
	    else
		printf "%-60s %10s\n" $var NOT-FOUND
	    endif
	end
    end
endif
if ( $found ) then
    cd $install_dir
    set giraf = `pwd`
#    set option = 0
    printf "IRAF not installed.  Try installing from:   http://iraf.noao.edu/  \n"
    printf "Select which IRAF to download and install...\n 1. MACOSX 64-bit\n 2. MACOSX 32-bit\n 3. LINUX 64-bit\n 4. LINUX 32-bit\n\nselection [ $option ]: "
    set option2 = $<
    if ( $option2 != "" && $option2 != $option ) then
	set option = $option2
    endif
    switch( $option ) 
	case 1:
#	    set giraf = iraf.macx.x86_64.tar.gz
	    set giraf = iraf-macosx.tar.gz
	    breaksw 
	case 2:
#	    set giraf = iraf.macx.uni.tar.gz
	    set giraf = iraf-macosx.tar.gz
	    breaksw 
	case 3:
#	    set giraf = iraf.lnux.x86_64.tar.gz
	    set giraf = iraf-linux.tar.gz
	    breaksw 
	case 4:
#	    set giraf = iraf.lnux.x86.tar.gz
	    set giraf = iraf-linux.tar.gz
	    breaksw 
	default:
	    printf "No Choice Selected...\n"
	    breaksw
    endsw
    if ( ! -e $giraf ) then
	wget $firaf/$giraf
    endif
    if ( -e $giraf && $giraf != `pwd` ) then
	printf "Install IRAF in $irafprefix [n|y]\n"
	set input = $<
	if ( $input == y || $input == yes ) then
	    setenv iraf $irafprefix
	    sudo mkdir -p $iraf
	    sudo tar -zxf $giraf -C $iraf
	    cd $iraf/unix/hlib
	    sudo chmod 777 $iraf
	    sudo ./install
	    cd $iraf/extern
	    sudo ./configure
#	    sudo make ctio
#	    sudo make xdimsum
#	    sudo make fitsutil
	else
	    printf "Continuing without installing IRAF...\n"
	endif
    endif

endif

#exit 0


# WCSTOOLS
wcstools:
which gethead >>& /dev/null
if ( $status == 0 ) then
    printf "%s\n" `gethead -version`
else
    if ( 0 && -d $install_dir/wcstools ) then
	printf "Already tried and failed to install wcstools.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install wcstools in $prefix/wcstools [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing wcstools...\n"
	mkdir -p $install_dir/wcstools
	tar -zxf $install_dir/$wcstools -C $install_dir/wcstools
	cd $install_dir/wcstools/wcstools*
	make all
	if ( $status == 0 ) then
	    sudo mkdir -p $prefix/wcstools
	    sudo cp -R $install_dir/wcstools/wcstools*/bin $prefix/wcstools
	    foreach var ( `ls $prefix/wcstools/bin` )
		sudo ln -s $prefix/wcstools/bin/$var $prefix/bin/$var
 	    end
	endif
	goto wcstools
    else
	printf "Continuing without installing wcstools...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/wcstools
#exit 0



# CFITSIO
cfitsio:
foreach var1 ( libcfitsio.a )
    set found = 1
    foreach var2 ( /usr/lib/ /usr/lib64/ /usr/local/lib/ ) 
	set var = $var2$var1
	ls $var >>& /dev/null
	if ( $status == 0 ) then
	    printf "%-60s %10s\n" $var FOUND
	    set found = 0
	    break
	else
	    printf "%-60s %10s\n" $var NOT-FOUND
	endif
    end
end
if ( $found == 0 ) then
    foreach var1 ( fitsio.h )
	set found = 1
	foreach var2 ( /usr/local/include/ ) 
	    set var = $var2$var1
	    ls $var >>& /dev/null
	    if ( $status == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		set found = 0
		break
	    else
		printf "%-60s %10s\n" $var NOT-FOUND
	    endif
	end
    end
endif
if ( $found ) then
    if ( -d $install_dir/cfitsio ) then
	printf "Already tried and failed to install cfitsio.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install cfitsio in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing cfitsio...\n"
	mkdir -p $install_dir/cfitsio
	tar -zxf $install_dir/$cfitsio -C $install_dir/cfitsio
	cd $install_dir/cfitsio/cfitsio*
	./configure --prefix=$prefix --enable-reentrant
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto cfitsio
    else
	printf "Continuing without installing cfitsio...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/cfitsio
#exit 0



# GSL
gsl:
foreach var1 ( libgsl.a  )
    set found = 1
    foreach var2 ( /usr/lib/ /usr/lib64/ /usr/local/lib/ /usr/local/gsl/lib/ ) 
	set var = $var2$var1
	ls $var >>& /dev/null
	if ( $status == 0 ) then
	    printf "%-60s %10s\n" $var FOUND
	    set found = 0
	    break
	else
	    printf "%-60s %10s\n" $var NOT-FOUND
	endif
    end
end
if ( $found == 0 ) then
    foreach var1 ( gsl_blas.h )
	set found = 1
	foreach var2 ( /usr/local/include/ /usr/local/include/gsl/ ) 
	    set var = $var2$var1
	    ls $var >>& /dev/null
	    if ( $status == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		set found = 0
		break
	    else
		printf "%-60s %10s\n" $var NOT-FOUND
	    endif
	end
    end
endif
#set found = 1
if ( $found ) then
    if ( -d $install_dir/gsl ) then
	printf "Already tried and failed to install gsl.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install gsl in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing gsl...\n"
	mkdir -p $install_dir/gsl
	tar -zxf $install_dir/$gsl -C $install_dir/gsl
        cp $install_dir/config.guess $install_dir/gsl/gsl*
	cd $install_dir/gsl/gsl*
	./configure --prefix=$prefix 
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto gsl
    else
	printf "Continuing without installing gsl...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/gsl
#exit 0

# CDSCLIENT
cdsclient:
which \aclient >>& /dev/null
if ( $status == 0 ) then
    printf "%-60s %10s\n" `which \aclient` FOUND
else
    if ( -d $install_dir/cdsclient ) then
	printf "Already tried and failed to install cdsclient.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install cdsclient in $prefix/cdsclient [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing cdsclient...\n"
	mkdir -p $install_dir/cdsclient/bin
	tar -zxf $install_dir/$cdsclient -C $install_dir/cdsclient
	cd $install_dir/cdsclient/cdsclient*
	./configure --prefix=$install_dir/cdsclient
	make && make install
	if ( $status == 0 ) then
	    sudo mkdir -p $prefix/cdsclient
	    sudo cp -R $install_dir/cdsclient/bin $prefix/cdsclient
	    foreach var ( `ls $prefix/cdsclient/bin` )
		sudo rm -fr $prefix/bin/$var
		sudo ln -s $prefix/cdsclient/bin/$var $prefix/bin/$var
 	    end
	endif
	goto cdsclient
    else
	printf "Continuing without installing cdsclient...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/cdsclient
#exit 0


printf "\n ------------------------------------------------ \n"
printf "          MAKING CUSTOM C EXECUTABLES                 "
printf "\n ------------------------------------------------ \n"

echo Using $tgcc
cd $fsred/src
foreach var ( imexpr skycombine fsimsurfit mimsurfit pvsip )
    make $var
    if ( $status ) then
	echo Something went wrong... Exiting.
	exit 1
    endif
end




which sex >>& /dev/null
if ( $status == 0 ) then
    echo "Found SExtractor: `which sex` `sex -v` "
else

endif

# ATLAS
atlas:
foreach var1 ( libatlas.a liblapack.a )
    set found = 1
    foreach var2 ( /usr/local/atlas/lib/ /usr/local/lib/  ) 
	set var = $var2$var1
	ls $var >>& /dev/null
	if ( $status == 0 ) then
	    printf "%-60s %10s\n" $var FOUND
	    if ( $var1 == liblapack.a ) then
		set lapa = $var2/$var1
	    endif
	    set found = 0
	    break
	else
	    printf "%-60s %10s\n" $var NOT-FOUND
	endif
    end

end
if ( $found == 0 ) then
    foreach var1 ( cblas.h clapack.h )
	set found = 1
	foreach var2 ( /usr/local/atlas/include/ /usr/local/include/ /usr/include /usr/include/atlas ) 
	    set var = $var2$var1
	    ls $var >>& /dev/null
	    if ( $status == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		set atlasl = $var2:h:h/lib
		set atlasi = $var2
		set found = 0
		break
	    else
		printf "%-60s %10s\n" $var NOT-FOUND
	    endif

	end
    end
endif
#set atlasl = /usr/local/atlas/include
#set atlasl = /usr/local/atlas/lib
#set atlasi = /usr/include/atlas
if ( $found ) then
    if ( -d $install_dir/atlas/test_111 ) then
	printf "Already tried and failed to install ATLAS.  Try manual install.  Exiting...\n"
	if ( $machine[2] =~ Darwin ) then
	    printf "Try: sudo port install atlas\n"
	else if ( $machine[2] =~ Linux ) then
	    printf "Try: sudo apt-get libatlas-base-dev \n"
	endif
	exit 1
    endif
    printf "Install atlas in $prefix/atlas [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing lapack...\n"
	mkdir -p $install_dir/lapack
	tar -xf $install_dir/$lapack -C $install_dir/lapack
#	cd $install_dir/$lapack/lapack*
#	cp make.inc.example make.inc
#	sedi 's|RANLIB   = ranlib|RANLIB   = echo|' make.inc
#	sedi 's|BLASLIB      = ../../librefblas.a|BLASLIB      = '$BLASLIB'|' make.inc
#	make f2clib
#	sudo make

	printf "Installing atlas...\n"
	mkdir -p $install_dir/atlas/test_111
	tar -jxf $install_dir/$atlas -C $install_dir/atlas
	cd $install_dir/atlas/test_111
#sudo /usr/bin/cpufreq-selector -g performance
#	set cflag = "-b $bflag -t $NCPU -Fa alg -fPIC"
	set cflag = "-b $bflag "
#	set cflag = "-b 32 -t 24 -Fa alg -fPIC"
#	set cflag = ""
	set cflag = "-C acg $tgcc"
#	echo -n enter input; set wait = $<
#	$install_dir/atlas/ATLAS/configure $cflag --with-netlib-lapack-tarfile=$install_dir/$lapack
	$install_dir/atlas/ATLAS/configure --with-netlib-lapack-tarfile=$install_dir/$lapack
#	echo -n enter input; set wait = $<
	if ( $status == 0 ) then
	    make >>& $install_dir/atlas_install.log
	    make check >>& $install_dir/atlas_check.log
	    make ptcheck >>& $install_dir/atlas_ptcheck.log
	    make time >>& $install_dir/atlas_time.log
	    sudo make install
	endif
	goto atlas
    else
	printf "Continuing without installing atlas...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/atlas
#exit 0


# FFTW1
fftw1:
foreach var1 ( libfftw3.a  )
    set found = 1
    foreach var2 ( /usr/local/lib/ ) 
	set var = $var2$var1
	ls $var >>& /dev/null
	if ( $status == 0 ) then
	    printf "%-60s %10s\n" $var FOUND
	    set fftwl = $var2
	    set fftwi = $var2:h:h/include
	    set found = 0
	    break
	else
	    printf "%-60s %10s\n" $var NOT-FOUND
	endif
    end
end
if ( $found == 0 ) then
    foreach var1 ( fftw3.h )
	set found = 1
	foreach var2 ( /usr/local/include/ ) 
	    set var = $var2$var1
	    ls $var >>& /dev/null
	    if ( $status == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		set found = 0
		break
	    else
		printf "%-60s %10s\n" $var NOT-FOUND
	    endif

	end
    end
endif
if ( $found ) then
    if ( -d $install_dir/fftw ) then
	printf "Already tried and failed to install fftw.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install fftw (double) in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing fftw...\n"
	mkdir -p $install_dir/fftw
	tar -zxf $install_dir/$fftw -C $install_dir/fftw
	cd $install_dir/fftw/fftw*
#	$install_dir/fftw/fftw*/configure -h
	$install_dir/fftw/fftw*/configure --prefix=$prefix --enable-threads
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto fftw1
    else
	printf "Continuing without installing fftw...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/fftw
#exit 0

# FFTW1
fftw2:
foreach var1 ( libfftw3f.a  )
    set found = 1
    foreach var2 ( /usr/local/lib/ ) 
	set var = $var2$var1
	ls $var >>& /dev/null
	if ( $status == 0 ) then
	    printf "%-60s %10s\n" $var FOUND
	    set fftwl = $var2
	    set fftwi = $var2:h:h/include
	    set found = 0
	    break
	else
	    printf "%-60s %10s\n" $var NOT-FOUND
	endif
    end
end
if ( $found == 0 ) then
    foreach var1 ( fftw3.h )
	set found = 1
	foreach var2 ( /usr/local/include/ ) 
	    set var = $var2$var1
	    ls $var >>& /dev/null
	    if ( $status == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		set found = 0
		break
	    else
		printf "%-60s %10s\n" $var NOT-FOUND
	    endif

	end
    end
endif
if ( $found ) then
    if ( -d $install_dir/fftw ) then
	printf "Already tried and failed to install fftw.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install fftw (single) in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing fftw...\n"
	mkdir -p $install_dir/fftw
	tar -zxf $install_dir/$fftw -C $install_dir/fftw
	cd $install_dir/fftw/fftw*
	$install_dir/fftw/fftw*/configure --prefix=$prefix --enable-threads --enable-single
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto fftw2
    else
	printf "Continuing without installing fftw...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/fftw
#exit 0

# PLPLOT 
plplot:
foreach var1 ( libplplotd.so )
    set found = 1
    foreach var2 ( /usr/lib/ /usr/lib64/ /usr/local/lib/ ) 
	set var = $var2$var1
	ls $var >>& /dev/null
	if ( $status == 0 ) then
	    printf "%-60s %10s\n" $var FOUND
	    set found = 0
	    break
	else
	    printf "%-60s %10s\n" $var NOT-FOUND
	endif
    end
end
if ( $found == 0 ) then
    foreach var1 ( plplot.h )
	set found = 1
	foreach var2 ( /usr/local/include/ /usr/local/include/plplot/ ) 
	    set var = $var2$var1
	    ls $var >>& /dev/null
	    if ( $status == 0 ) then
		printf "%-60s %10s\n" $var FOUND
		set found = 0
		break
	    else
		printf "%-60s %10s\n" $var NOT-FOUND
	    endif

	end
    end
endif
if ( $found ) then
    if ( -d $install_dir/plplot ) then
	printf "Already tried and failed to install plplot.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install plplot in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing plplot...\n"
	mkdir -p $install_dir/plplot
	tar -zxf $install_dir/$plot -C $install_dir/plplot
	cd $install_dir/plplot/plplot*
	mkdir test_111; cd test_111
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DDEFAULT_NO_BINDINGS=ON -DDEFAULT_NO_DEVICES=ON -DPLD_aqt=OFF -DENABLE_tk=OFF ../
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto plplot
    else
	printf "Continuing without installing plplot...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/plplot
#exit 0


# SExtractor
sex:
which \sex >>& /dev/null
if ( $status == 0 ) then
    printf "%-60s %10s\n" `which \sex` FOUND
    sex -v
else
    if ( -d $install_dir/sex ) then
	printf "Already tried and failed to install sextractor.  Try manual install.  Exiting...\n"
#	exit 1
    endif
    printf "Install sextractor in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing sextractor...\n"
	mkdir -p $install_dir/sex
	tar -zxf $install_dir/$sex -C $install_dir/sex
	cd $install_dir/sex/*
#	autoreconf -fiv
        sh autogen.sh
	sedi 's|-llapack|'$lapa'|' configure
	sedi 's|-lcblas|/usr/local/atlas/lib/libcblas.a /usr/local/atlas/lib/libf77blas.a|' configure
	sedi 's|-latlas|/usr/local/atlas/lib/libatlas.a|' configure
	sedi 's|-lptcblas|/usr/local/atlas/lib/libptcblas.a /usr/local/atlas/lib/libptf77blas.a|' configure
	if ( $NCPU == 1 ) then
	    echo disabling threads
	    ./configure --prefix=$prefix --disable-threads --enable-static --disable-dynamic --with-fftw-libdir=$fftwl --with-fftw-incdir=$fftwi --with-atlas-libdir=$atlasl --with-atlas-incdir=$atlasi
	else
	    ./configure --prefix=$prefix --enable-threads=$NCPU --enable-static --disable-dynamic --with-fftw-libdir=$fftwl --with-fftw-incdir=$fftwi --with-atlas-libdir=$atlasl --with-atlas-incdir=$atlasi
	endif
	sedi 's|-llapack|'$lapa'|' configure
	sedi 's|-lcblas|/usr/local/atlas/lib/libcblas.a /usr/local/atlas/lib/libf77blas.a|' configure
	sedi 's|-latlas|/usr/local/atlas/lib/libatlas.a|' configure
	sedi 's|-lptcblas|/usr/local/atlas/lib/libptcblas.a /usr/local/atlas/lib/libptf77blas.a|' configure

	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto sex
    else
	printf "Continuing without installing sextractor...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/sex
#exit 0



# SCAMP
scamp:
which \scamp >>& /dev/null
if ( $status == 0 ) then
    printf "%-60s %10s\n" `which \scamp` FOUND
    scamp -v
else
    if ( -d $install_dir/scamp ) then
	printf "Already tried and failed to install scamp.  Try manual install.  Exiting...\n"
#	exit 1
    endif
    printf "Install scamp in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing scamp...\n"
	mkdir -p $install_dir/scamp
	tar -zxf $install_dir/$scamp -C $install_dir/scamp
	cd $install_dir/scamp/*
	autoreconf -fiv
#	sedi 's|-llapack|'$lapa'|' configure
#	sedi 's|-llapack|-lf77blas|' configure
#	sedi 's|-latlas|-latlas -lf77blas|' configure
#	./configure --prefix=$prefix --enable-threads=$NCPU --with-fftw-libdir=$fftwl --with-fftw-incdir=$fftwi --with-atlas-libdir=$atlasl --with-atlas-incdir=$atlasi
#	./configure -h
#	echo -n Enter input: ;set wait = $<
	./configure --prefix=$prefix --enable-best-link --enable-threads=$NCPU --with-fftw-libdir=$fftwl --with-fftw-incdir=$fftwi --with-atlas-libdir=$atlasl --with-atlas-incdir=$atlasi
#	./configure --prefix=$prefix --enable-best-link --build=x86_64-apple-darwin11.4.0 --with-fftw-libdir=$fftwl --with-fftw-incdir=$fftwi --with-atlas-libdir=$atlasl --with-atlas-incdir=$atlasi
#	sedi 's|-llapack|'$lapa'|' configure
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto scamp
    else
	printf "Continuing without installing scamp...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/scamp
#exit 0


# SWARP
swarp:
which \swarp >>& /dev/null
if ( $status == 0 ) then
    printf "%-60s %10s\n" `which \swarp` FOUND
    swarp -v
else
    if ( -d $install_dir/swarp ) then
	printf "Already tried and failed to install swarp.  Try manual install.  Exiting...\n"
	exit 1
    endif
    printf "Install swarp in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing swarp...\n"
	mkdir -p $install_dir/swarp
	tar -zxf $install_dir/$swarp -C $install_dir/swarp
	cd $install_dir/swarp/*
	./configure --prefix=$prefix --enable-threads=$NCPU
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto swarp
    else
	printf "Continuing without installing swarp...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/swarp
#exit 0


# PSFEX
psfex:
which \psfex >>& /dev/null
if ( $status == 0 ) then
    printf "%-60s %10s\n" `which \psfex` FOUND
    psfex -v
else
    if ( -d $install_dir/psfex ) then
	printf "Already tried and failed to install psfex.  Try manual install.  Exiting...\n"
#	exit 1
    endif
    printf "Install psfex in $prefix [n|y]: " > /dev/stderr
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Installing psfex...\n"
	mkdir -p $install_dir/psfex
	tar -zxf $install_dir/$psfex -C $install_dir/psfex
	cd $install_dir/psfex/*
	sedi 's|-llapack|'$lapa'|' configure
	autoreconf -fiv
	./configure --prefix=$prefix --enable-threads=$NCPU --with-fftw-libdir=$fftwl --with-fftw-incdir=$fftwi --with-atlas-libdir=$atlasl --with-atlas-incdir=$atlasi
	make
	if ( $status == 0 ) then
	    sudo make install
	endif
	goto psfex
    else
	printf "Continuing without installing psfex...\n"
#	exit 1
    endif
endif
rm -fr $install_dir/psfex
#exit 0



# SM
sm:
ls /usr/local/bin/sm >>& /dev/null
if ( $status == 0 ) then
    printf "%-60s %10s\n" /usr/local/bin/sm FOUND
else if ( `which \sm >>& /dev/null ; echo $status` == 0 ) then
    printf "%-60s %10s\n" `which \sm` FOUND
    printf "FSRED calls /usr/local/bin/sm \n"
    printf "Shall I create a symbolic link for you now? [n|y]: "
    set input = $<
    if ( $input == y || $input == yes ) then
	printf "Linking %s to /usr/local/bin/sm\n" `which \sm`
	if ( ! -e /usr/local/bin ) then
	    sudo mkdir -p /usr/local/bin	
	endif
	sudo ln -s `which \sm` /usr/local/bin/sm
	goto sm
    else
	printf "Continuing without linking SM, some plots will not be created in FSRED...\n"
    endif
else
    printf "%-60s %10s\n" SUPERMONGO NOT-FOUND
    printf "Cannot distribute sm, you will have to get your own copy; sorry. \n"
    printf "It is not necessary for FSRED to work, but it does make some diagnostic plots. \n"
endif
#exit 0

printf "\nFetching the Calibraion data\n"
cd $fsred
wget https://users.obs.carnegiescience.edu/cburns/shared/FSRED_CALIB.tgz
tar -zxf FSRED_CALIB.tgz
rm -f FSRED_CALIB.tgz

printf "\n ------------------------------------------------ \n"
printf " FINISHED... No guarantees, but try fsred.csh         "
printf "\n ------------------------------------------------ \n"


exit 0
