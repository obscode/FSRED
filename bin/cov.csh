#!/bin/csh -f

set pwd = `pwd`
###############################################
set scriptpath = $0:h/      # LOCATION OF THIS SCRIPT.
if ( $scriptpath == "./" ) then
    set scriptpath = $pwd
endif
# INITIALIZE DEFAULTS
set mask = $scriptpath:h:h/BPM/amask.fits
set output = cov.fits
set RA = 0
set DEC = 0
set ROT = 0
set macro = $scriptpath:h:h/macros/dice5r30_26a.macro
set filter = J
set iraf = "/iraf/iraf/"   # THIS IS CORRECT FOR (MOST)
#set irafarch = "macintel"  # THIS IS CORRECT FOR (MOST)MACS
set irafarch = "macosx"  # THIS IS CORRECT FOR (MOST)MACS
alias sedi "sed -i '' "    # THIS IS CORRECT FOR MACS

while ( 1 )
    switch($1)
	case -mask
	    if ( "$2" =~ "" ) then
		echo no mask specified... exiting.
		exit 1
	    endif
	    if ( ! -e $2 ) then
		echo $2 does not exist... exiting.
		exit 1
	    endif
	    set mask = $2 ; shift; shift
	    breaksw
	case -out
	    if ( "$2" =~ "" ) then
		echo no output specified... exiting.
		exit 1
	    endif
	    if ( -e $2 ) then
		echo $2 already exists... exiting.
		exit 1
	    endif
	    set output = $2 ; shift; shift
	    breaksw
	case -filter
	    if ( "$2" =~ "" ) then
		echo no filter specified... exiting.
		exit 1
	    endif
	    if ( ! ( $2 == J || $2 == J1 || $2 == J2 || $2 == J3 || $2 == H || $2 == Hs || $2 == Hl || $2 == Ks ) ) then
		echo $2 not an option... Please specify J, J1, J2, J3, H, Hs, Hl, Ks.   Exiting.
		exit 1
	    endif
	    set filter = $2 ; shift; shift
	    breaksw
	case -ra
	    if ( "$2" =~ "" ) then
		echo no ra specified... exiting.
		exit 1
	    endif
	    set RA = "$2" ; shift; shift
	    breaksw
	case -dec
	    if ( "$2" =~ "" ) then
		echo no dec specified... exiting.
		exit 1
	    endif
	    set DEC = "$2" ; shift; shift
	    breaksw
	case -rot
	    if ( "$2" =~ "" ) then
		echo no rot specified... exiting.
		exit 1
	    endif
	    set ROT = "$2" ; shift; shift
	    breaksw
	case -macro
	    if ( "$2" =~ "" ) then
		echo no macro specified... exiting.
		exit 1
	    endif
	    if ( -e $2 ) then
		set macro = "$2" ; shift; shift
	    else if ( -e $scriptpath:h:h/macros/"$2" ) then
		set macro = "$scriptpath:h:h/macros/$2" ; shift; shift
	    else
		printf "$2 not found.  Exiting.\n"
		exit 1
	    endif

	    breaksw
	case -iraf
	    if ( "$2" =~ "" ) then
		echo no irafpath specified... exiting.
		exit 1
	    endif
	    set iraf = "$2" ; shift; shift
	    breaksw
	case -irafarch
	    if ( "$2" =~ "" ) then
		echo no irafarch specified... exiting.
		exit 1
	    endif
	    set irafarch = $2 ; shift; shift
	    breaksw
	default:
	    break
    endsw
end

###############################################
# alias PROGRAM EXECUTABLES
alias images $iraf/bin.$irafarch/x_images.e
###############################################
#echo $RA $DEC
set DEC = `awk 'BEGIN {x="'$DEC'";if(x~":"){split(x,a,":");print (1*a[1]>0?1:-1)*((1*a[1]>0?a[1]:-1*a[1])+a[2]/60+a[3]/3600) } else { print x} }'`
set RA = `awk 'BEGIN {x="'$RA'";if(x~":"){split(x,a,":");print 15*(1*a[1]+a[2]/60+a[3]/3600) } else { print x } }'`
#echo $RA $DEC
#exit
echo "Mask = $mask"
echo "Macro = $macro"
echo "Filter = $filter"
echo "COORDS = $RA $DEC $ROT"
set LATITUDE = -29.0

if ( `awk 'BEGIN { print ('$DEC' > '$LATITUDE') ? 1 : 0 }'` ) then
    echo Rotator automatically flips 180 degrees at this DEC.  
    set ROT = `awk 'BEGIN {print '$ROT' + 180}'` 
    if ( `awk 'BEGIN { print ('$ROT' > 360) ? 1 : 0 }'` ) then
	set ROT = `awk 'BEGIN {print '$ROT' - 360}'`
    endif
endif

if ( $filter == J || $filter == J1 || $filter == J2 || $filter == J3 || $filter == H || $filter == Hs || $filter == Hl ) then
    set scale = 0.159
endif
if ( $filter == Ks ) then
    set scale = 0.1603
endif

if ( ! -e $mask ) then
    printf "$mask does not exist, exiting.\n"
    exit 1
endif


sethead $mask CRVAL1=$RA
sethead $mask CRVAL2=$DEC
#sethead $mask CD1_1=`awk 'BEGIN {print  -(cos('$ROT'*3.1415926/180) + sin('$ROT'*3.1415926/180))*'$scale'/3600   }'`
#sethead $mask CD2_2=`awk 'BEGIN {print  -(-cos('$ROT'*3.1415926/180) + sin('$ROT'*3.1415926/180))*'$scale'/3600   }'`
##echo `awk 'BEGIN {print  (cos('$ROT'*3.1415926/180) + sin('$ROT'*3.1415926/180))*'$scale'/3600   }'`
##echo `awk 'BEGIN {print  (-cos('$ROT'*3.1415926/180) + sin('$ROT'*3.1415926/180))*'$scale'/3600   }'`

sethead $mask CD1_1=`awk 'BEGIN {print  (cos('$ROT'*3.1415926/180))*'$scale'/3600   }'`
sethead $mask CD2_1=`awk 'BEGIN {print  (sin(-'$ROT'*3.1415926/180))*'$scale'/3600   }'`
sethead $mask CD1_2=`awk 'BEGIN {print  (sin(-'$ROT'*3.1415926/180))*'$scale'/3600   }'`
sethead $mask CD2_2=`awk 'BEGIN {print  -(cos('$ROT'*3.1415926/180))*'$scale'/3600   }'`

echo `awk 'BEGIN {print  (cos('$ROT'*3.1415926/180))*'$scale'/3600   }'`
echo `awk 'BEGIN {print  (sin(-'$ROT'*3.1415926/180))*'$scale'/3600   }'`
echo `awk 'BEGIN {print  (sin(-'$ROT'*3.1415926/180))*'$scale'/3600   }'`
echo `awk 'BEGIN {print  -(cos('$ROT'*3.1415926/180))*'$scale'/3600   }'`

set offsets = tmp.coo
set maskin = tmp.in

# MAKE FAKE IMAGE AT TELESCOPE CENTER WITH ZEROES TO FORCE IMAGE HEADER WCS.   
echo 0 0 > $offsets
echo $mask.zero.fits > $maskin
if ( ! `echo $macro | grep poisson >>& /dev/null ; echo $status` ) then
    echo Poisson Pattern: First image taken after first offset, final offset returns to original position.
    grep go -B1 $macro | grep move | awk 'BEGIN{dx=0;dy=0}{dx=dx+($(NF-1))/'$scale'; dy=dy+($NF)/'$scale';print dx,dy }' >> $offsets
else
    echo Generic Pattern: First image taken current position, final offset returns to original position.
#    grep move $macro | awk 'BEGIN{dx=0;dy=0}{dx=dx+$(NF-1)/'$scale'; dy=dy+$NF/'$scale';print dx,dy }' >> $offsets
    grep move $macro | awk 'BEGIN{dx=0;dy=0} \! /#/ {dx=dx-($2)/'$scale'; dy=dy+($3)/'$scale';print dx,dy,$4 }' | grep -v \# >> $offsets
endif
awk 'BEGIN{for(i=1;i<'`cat $offsets | wc -l`';i++){ print "'$mask'"}}' >> $maskin

cp -f $scriptpath:h:h/IRAF/imexpr.par cov.par
sedi 's|imexpr.expr = |imexpr.expr = \"a*0\"|' cov.par
sedi 's|imexpr.output = |imexpr.output = \"'$mask.zero.fits'\"|' cov.par
sedi 's|imexpr.a = |imexpr.a = \"'$mask'\"|' cov.par
rm -fr $mask.zero.fits >>& /dev/null
images imexpr \@cov.par
cp -f $scriptpath:h:h/IRAF/imcombine.par cov.par
sedi 's|imcombine.input = |imcombine.input = \"@'$maskin'\"|' cov.par
sedi 's|imcombine.output = |imcombine.output = \"'$output'\"|' cov.par
sedi 's|imcombine.combine = |imcombine.combine = \"sum\"|' cov.par
sedi 's|imcombine.outtype = \"real\"|imcombine.outtype = \"int\"|' cov.par
sedi 's|imcombine.offsets = \"none\"|imcombine.offsets = \"'$offsets'\"|' cov.par
#exit
images imcombine \@cov.par
delhead $output WCSDIM CDELT1 CDELT2 LTV1 LTV2 LTM1_1 LTM2_2 WAT0_001 WAT1_001 WAT2_001 >>& /dev/null
rm -f cov.par tmp.coo tmp.in >>& /dev/null
rm -fr $mask.zero.fits >>& /dev/null


exit 0
