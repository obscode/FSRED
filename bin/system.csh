# SET IRAF LOCATIONS
set irafloc = "/iraf/iraf/"
#set irafarch = "macosx"

# SET RELEVANT COMMANDS:
# full command paths must be specified when sending commands via XGRID
foreach var ( \rm \sed \cat \cp \mv \grep \paste \awk \wc \ps )
    set $var = `which $var`
    if ( $status == 1 ) then
	echo "command $var not found, exiting..."
	exit 1
    endif
end
set iraf = ${irafloc}
set machine = `uname -sm`
if ( $machine[1] =~ Linux && ( $machine[2] =~ i386 || $machine[2] =~ i686 ) ) then
    set sedi = "$sed -i''"
    set irafarch = "linux"
    set NCPU = `grep -c processor /proc/cpuinfo`
else if ( $machine[1] =~ Linux && $machine[2] =~ x86_64 ) then
    set sedi = "$sed -i''"
    set irafarch = "linux64"
    set NCPU = `grep -c processor /proc/cpuinfo`
else if ( $machine[1] =~ Linux && $machine[2] =~ aarch64 ) then
    set sedi = "$sed -i''"
    set irafarch = "linux64"
    set NCPU = `grep -c processor /proc/cpuinfo`
else if ( $machine[1] =~ Darwin && ( $machine[2] =~ i386 || $machine[2] =~ 6386 ) ) then
    set sedi = "$sed -i ''"
    set irafarch = "macosx"
    set NCPU = `sysctl -n hw.ncpu` 
else if ( $machine[1] =~ Darwin && $machine[2] =~ x86_64 ) then
    set sedi = "$sed -i ''"
    set irafarch = "macintel"
    set NCPU = `sysctl -n hw.ncpu` 
else if ( $machine[1] =~ Darwin && $machine[2] =~ arm64 ) then
    set sedi = "$sed -i ''"
    set irafarch = "mac64"
    set NCPU = `sysctl -n hw.ncpu` 
else
    set sedi = "$sed -i ''"
    set irafarch = "macosx"
    set NCPU = 1
endif
printf "%s %s CPU's: %d\n" $machine[1] $machine[2] $NCPU
alias sedi $sedi

#set BKJOBS = `echo "$NCPU * 2" | bc`      # SET MAXIMUM NUMBER OF SIMULTANEOUS BACKGROUND JOBS 
set BKJOBS = 12          # SET MAXIMUM NUMBER OF SIMULTANEOUS BACKGROUND JOBS 
# Initial sleep during imexp.  Set to 3-5 if you experience a lot of waiting messages during initial reduction.
#set isleep = 0.25
@ isleep = 5 / $NCPU    # empirical


# SET IRAF LOCATIONS TO EXECUTABLES
# x_images.e for imarith, imexpr, imcombine |  x_proto.e for mimstatistics |  x_nproto.e for detect 
set images = ${irafloc}bin.${irafarch}/x_images.e
set proto = ${irafloc}bin.${irafarch}/x_proto.e
set nproto = ${irafloc}noao/bin.${irafarch}/x_nproto.e
# x_nproto did not work for x86_64:  ERROR (501, "segmentation violation"), use 32 bit version instead.
if ( $machine[1] =~ Darwin && $machine[2] =~ x86_64 ) then
    echo -n "changing $nproto to "
    set nproto = ${irafloc}noao/bin.macosx/x_nproto.e
    echo "$nproto"
endif
if ( $machine[1] =~ Linux && $machine[2] =~ x86_64 ) then
    echo -n "changing $nproto to "
    set nproto = ${irafloc}noao/bin.linux64/x_nproto.e
    echo "$nproto"
endif

foreach var ( $images $proto $nproto )
    if ( ! -e $var ) then
	echo "$var does not exist, check IRAF location in FSRED.csh script. Currently irafloc is set to: $irafloc "  
    endif
end

# SET WCSTOOLS AND ASTROMATIC EXECUTABLE PATHS IF THEY ARE ALREADY IN THE PATH...
# THE FULL PATHS ARE NECESSARY FOR XGRID TO WORK PROPERLY, OR AT LEAST MY 
# IMPLEMENTATION OF IT.
if ( 1 ) then
    foreach var ( \gethead \sethead \delhead \cphead \xy2sky \sky2xy \sex \scamp \swarp \psfex )
	which $var >> /dev/null
	if ( $status == 0 ) then 
	    set $var = `which $var`
	else 
	    echo "$var not found in path"
	    exit 0
	endif
    end
else
#  OR SET EXPLICITY IF NOT IN PATH
# SET WCSTOOLS LOCATIONS TO EXECUTABLES, FOR GETHEAD and SETHEAD
    set gethead = "/Users/fourstar/software/wcstools-3.8.4/bin/gethead"
    set sethead = "/Users/fourstar/software/wcstools-3.8.4/bin/sethead"
    set delhead = "/Users/fourstar/software/wcstools-3.8.4/bin/delhead"
    set cphead = "/Users/fourstar/software/wcstools-3.8.4/bin/cphead"
    set xy2sky  = "/Users/fourstar/software/wcstools-3.8.4/bin/xy2sky"
    set sky2xy  = "/Users/fourstar/software/wcstools-3.8.4/bin/sky2xy"
    # SET ASTROMATIC LOCATIONS TO EXECUTABLES, FOR SExtractor SCAMP and SWARP
    set sex = "/usr/local/bin/sex"
    set scamp = "/usr/local/bin/scamp"
    set swarp = "/usr/local/bin/swarp"
    # OPTIONAL / EXPERIMENTAL -z option.  
    set psfex = "/usr/local/bin/psfex"
endif

set XGRID = 0            #  KEEP THIS OFF ( 0 ).   ONLY USED AT LCO, UNLESS YOU REALLY WANT TO PLAY WITH XGRID... NO GUARANTEES
set sm = "/usr/local/bin/sm"  # <--- must be this, or edit the sm.csh scripts. Only used for some diagnostic plots.  

