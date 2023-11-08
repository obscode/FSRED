#!/bin/csh -f

set array = "null"
set tarr = $0.tmp
@ niter = 0
set verb = 0
set hisig = 3
set losig = 3

while ( 1 )
    switch ( $1 )
	case -v
	    set verb = 1 ; shift
	    breaksw
	case -o
	    if ( "$2" =~ "" ) then
		echo output not specified... exiting.
		exit 1
	    endif
	    set tarr = $2 ; shift ; shift
	    breaksw
	case -hisig
	    if ( "$2" =~ "" ) then
		echo hisig not specified... exiting.
		exit 1
	    endif
	    set hisig = $2 ; shift ; shift
	    breaksw
	case -losig
	    if ( "$2" =~ "" ) then
		echo losig not specified... exiting.
		exit 1
	    endif
	    set losig = $2 ; shift ;shift
	    breaksw
	case -f
	    if ( "$2" =~ "" ) then
		echo data file not specified... exiting.
		exit 1
	    endif
	    set array = $2 ; shift; shift
	    breaksw
	case -niter
	    if ( "$2" =~ "" ) then
		echo number of rejection iteration not specified... exiting.
		exit 1
	    endif
	    @ niter = $2 ; shift; shift
	    breaksw
	case -test
	    set array = $tarr.tmp ; shift
	    echo Diagnostic Statistics
#	    awk 'BEGIN{srand();for(i=1;i<=10;i++)print rand(),1 }' > $array
	    awk 'BEGIN{for(i=1;i<=10;i++)print i }' > $array
	    breaksw
	default:
	    break
    endsw
end

if ( $array == "null" ) then
    if ( $verb == 1 ) then
	echo "Nothing to do...  Exiting"
    endif
    exit 1
endif

sort -g $array > $tarr
set STATS = ( 0 0 0 0 0 0 0 0 0 ) # number min max med ave sig sn-1 wave wsig 

if ( $verb == 1 && 0 ) then
    cat $tarr
endif    

set STATS = `awk 'BEGIN {ave=0;sig=0;wave=0;wsig=0;i=0}{a=$1;s=(NF>1)?$2:1;wave=wave+(a)/(s)^2;wsig=wsig+1/(s)^2;ave=ave+a;sig=sig+a*a;i++}END{if(i>0){ave=ave/i;sig=sqrt(sig/i-(ave)**2);printf "%d 0 0 0 %g %g %g %g %g \n",i,ave,sig,sig*sqrt(i/(i-1)),wave/wsig,sqrt(1/wsig)}else{print 0,0,0,0,0,0,0,0,0}}' $tarr`
set STATS[2] = `head -n1 $tarr | cut -d " " -f 1 `
set STATS[3] = `tail -n1 $tarr | cut -d " " -f 1 `
set NUM = `awk 'BEGIN{print int('$STATS[1]'/2) }'`
set STATS[4] = `head -n $NUM $tarr | sort -gr | head -n1 | cut -d " " -f 1 `

@ n = 0
if ( $verb == 1 ) then
    echo 
    echo
    echo "# iteration number min max med ave sig(n) sig(n-1) wave wsig "
    printf "%2d %6d %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e \n" $n $STATS
endif

set usestat = 4   #  4 for the median;  5 for the average 
set usesig = 6   #  6 | 7 | 8
while ( $n < $niter ) 
    @ n ++
    mv -f $tarr $tarr.tmp
    awk '{if( ( $1 < ('$STATS[$usestat]'+'$hisig'*'$STATS[$usesig]')) && ( $1 > ('$STATS[$usestat]'-'$losig'*'$STATS[$usesig]')) ){print $0 }}' $tarr.tmp > $tarr
    if ( -z $tarr ) then
	if ( $verb == 1 ) then
	    echo Empty array
	endif
	break
    endif

    if ( $verb == 1 && 0 ) then
	cat $tarr
    endif

    set STATS = `awk 'BEGIN {ave=0;sig=0;wave=0;wsig=0;i=0}{a=$1;s=(NF>1)?$2:1;wave=wave+(a)/(s)^2;wsig=wsig+1/(s)^2;ave=ave+a;sig=sig+a*a;i++}END{if(i>0){ave=ave/i;sig=sqrt(sig/i-(ave)**2);printf "%d 0 0 0 %g %g %g %g %g \n",i,ave,sig,sig*sqrt(i/(i-1)),wave/wsig,sqrt(1/wsig)}else{print 0,0,0,0,0,0,0,0,0}}' $tarr`
    set STATS[2] = `head -n1 $tarr | cut -d " " -f 1 `
    set STATS[3] = `tail -n1 $tarr | cut -d " " -f 1 `
    set NUM = `awk 'BEGIN{print int('$STATS[1]'/2) }'`
    set STATS[4] = `head -n $NUM $tarr | sort -gr | head -n1 | cut -d " " -f 1 `
    if ( $verb == 1 ) then
	printf "%2d %6d %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e \n" $n $STATS
    endif
end

if ( $verb == 1 ) then
    echo 
    echo
    echo "# number min max med ave sig(n) sig(n-1) wave wsig "
endif
printf "%6d %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e \n" $STATS


rm -fr $tarr.tmp >>& /dev/null
# ONLY REMOVE TEMP FILE IF OUTPUT WAS NOT SPECIFIED
if ( $tarr == $0.tmp ) then
    rm -fr $tarr >>& /dev/null
endif

exit $status
