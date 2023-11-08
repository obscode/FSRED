#!/bin/csh -f

set pwd = `pwd`
###############################################
set scriptpath = $0:h:h      # LOCATION OF THIS SCRIPT.
if ( $scriptpath == "./" ) then
    set scriptpath = $pwd
endif
#echo $scriptpath
#exit
# INITIALIZE DEFAULTS
set iraf = "/iraf/iraf/"   # THIS IS CORRECT FOR (MOST)
#set irafarch = "macintel"  # THIS IS CORRECT FOR (MOST)MACS
set irafarch = "macosx"  # THIS IS CORRECT FOR (MOST)MACS
alias sedi "sed -i '' "    # THIS IS CORRECT FOR MACS

###############################################
# alias PROGRAM EXECUTABLES
alias images ${iraf}/bin.${irafarch}/x_images.e
set proto = ${iraf}/bin.${irafarch}/x_proto.e
alias proto  ${proto}
###############################################
set coaddm = ""
set coadd = $1
if ( $2 != "" ) then
    set coaddm = $2
endif
#echo $coaddm
set upper = INDEF
set lower = INDEF
set nclip = 3
set temp = $pwd/tempmimstat
cat - <<XEOF > $temp.par
mimstatistics.images = "${coadd}"
mimstatistics.imasks = "${coaddm}"
mimstatistics.omasks = ""
mimstatistics.fields = npix,mean,stddev
mimstatistics.lower = $lower
mimstatistics.upper = $upper
mimstatistics.nclip = $nclip
mimstatistics.lsigma = 3.
mimstatistics.usigma = 3.
mimstatistics.binwidth = 0.1
mimstatistics.format = no
mimstatistics.cache = yes
mimstatistics.mode = "ql"
# EOF
XEOF
#cat $temp.par
set BACKSIG = `proto mimstatistics \@$temp.par`
#echo $BACKSIG
#rm -f $temp.par >>& /dev/null

#echo "determining un-correlated (true) background noise"
rm -f ${temp}_000.dat >>& /dev/null
set xaxis = `gethead $coadd NAXIS1`
set yaxis = `gethead $coadd NAXIS2`
set xgridm = 10
set ygridm = 10

# BIG CHUNKS
if ( 0 ) then
    set xgrid = 10
    set ygrid = 10
    @ xgridinc = 1
    @ ygridinc = 1
    @ xstep = $xaxis / $xgrid
    @ ystep = $yaxis / $ygrid
# A NUMBER OF LITTLE CHUNKS 
else
    set xstep = 9
    set ystep = 9
    @ xgrid = $xaxis / $xstep
    @ ygrid = $yaxis / $ystep
    @ xgridinc = $xgrid / $xgridm
    @ ygridinc = $ygrid / $ygridm
endif
#echo $xgrid $ygrid $xstep $ystep $xgridinc $ygridinc
@ cid = 0
@ y = 0
#set upper = `awk 'BEGIN {print '$BACKSIG[1]' + 5*'$BACKSIG[2]'}'`
#set lower = `awk 'BEGIN {print '$BACKSIG[1]' - 5*'$BACKSIG[2]'}'`
set upper = INDEF
set lower = INDEF
#echo $upper $lower
set nclip = 3
while ( $y < $ygrid )
    @ x = 0
    while ( $x < $xgrid )
	set cid = `awk 'BEGIN {printf "%03d",'$cid'+1}' `
	@ x1 = $x * $xstep + 1
	@ x2 = $x * $xstep + $xstep
	@ y1 = $y * $ystep + 1
	@ y2 = $y * $ystep + $ystep
#	echo $xaxis $xgrid $xstep $x $x1 $x2 
#	echo $yaxis $ygrid $ystep $y $y1 $y2 
#	set coaddm1 = "${coaddm}[${x1}:${x2},${y1}:${y2}]"
#	set coaddm1 = "${coaddm}"
	set coaddm1 = ""
	cat - <<XEOF > ${temp}_$cid.par
mimstatistics.images = "${coadd}[${x1}:${x2},${y1}:${y2}]"
mimstatistics.imasks = "${coaddm1}"
mimstatistics.omasks = ""
mimstatistics.fields = npix,mean,stddev,skew,max
mimstatistics.lower = $lower
mimstatistics.upper = $upper
mimstatistics.nclip = $nclip
mimstatistics.lsigma = 3.
mimstatistics.usigma = 3.
mimstatistics.binwidth = 0.1
mimstatistics.format = no
mimstatistics.cache = yes
mimstatistics.mode = "ql"
# EOF
XEOF
#cat ${temp}_$cid.par
#exit 
#	( exec $proto mimstatistics \@${temp}_$cid.par | awk '{if($0!=INDEF && $1!=0. && $2!=0. && $4**2<=0.1 ){print $2,$3/sqrt($1),$1,$4,$5}}' >> ${temp}_000.dat & )
#	( exec $proto mimstatistics \@${temp}_$cid.par | awk '{if($0!=INDEF && $1!=0. && $2!=0. ){print $2,$3/sqrt($1),$1,$4,$5}}' >> ${temp}_000.dat & )
#	( exec $proto mimstatistics \@${temp}_$cid.par & )
	$proto mimstatistics \@${temp}_$cid.par | awk '{if($0!=INDEF && $1>0.75('$xstep'*'$ystep') && $2!=0. ){print $2,$3,$1,$4,$5}}' >> ${temp}_000.dat &
#	( exec $proto mimstatistics \@${temp}_$cid.par | awk '{if($0!=INDEF && $1!=0. && $2!=0. ){print $2,$3,$1,$4,$5}}' >> ${temp}_000.dat  )
#	sleep 0.0005
	@ x += $xgridinc
    end
    @ y += $ygridinc
end
wait

rm -f ${temp}_*.par >>& /dev/null
#cat ${temp}_000.dat
if ( ! -z ${temp}_000.dat ) then
    set array = ${temp}_000.dat
    set tarr = ${temp}_001.dat
    sort -g $array > $tarr
    set STATS = ( 0 0 0 0 0 0 0 0 0 ) # number min max med ave sig sn-1 wave wsig 
    set STATS = `awk 'BEGIN {ave=0;sig=0;wave=0;wsig=0;i=0}{a=$1;s=(NF>1)?$2:1;wave=wave+(a)/(s)^2;wsig=wsig+1/(s)^2;ave=ave+a;sig=sig+a*a;i++}END{if(i>0){ave=ave/i;sig=sqrt(sig/i-(ave)**2);printf "%d 0 0 0 %g %g %g %g %g \n",i,ave,sig,sig*sqrt(i/(i-1)),wave/wsig,sqrt(1/wsig)}else{print 0,0,0,0,0,0,0,0,0}}' $tarr`
    set STATS[2] = `head -n1 $tarr | cut -d " " -f 1 `
    set STATS[3] = `tail -n1 $tarr | cut -d " " -f 1 `
    set NUM = `awk 'BEGIN{print int('$STATS[1]'/2) }'`
    set STATS[4] = `head -n $NUM $tarr | sort -gr | head -n1 | cut -d " " -f 1 `

    set usestat = 4   #  4 for the median;  5 for the average 
    set usesig = 6   #  6 | 7 | 8
    set hisig = 2
    set losig = 3
    set niter = 3
    set verb = 0
    @ n = 0
    if ( $verb == 1 ) then
	printf "%2d %6d %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e \n" $n $STATS
    endif
    while ( $n < $niter ) 
	@ n ++
	mv -f $tarr $tarr.tmp
	awk '{if( ( $1 < ('$STATS[$usestat]'+'$hisig'*'$STATS[$usesig]')) && ( $1 > ('$STATS[$usestat]'-'$losig'*'$STATS[$usesig]')) ){print $0 }}' $tarr.tmp > $tarr
	if ( -z $tarr ) then
	    break
	endif
	set STATS = `awk 'BEGIN {ave=0;sig=0;wave=0;wsig=0;i=0}{a=$1;s=(NF>1)?$2:1;wave=wave+(a)/(s)^2;wsig=wsig+1/(s)^2;ave=ave+a;sig=sig+a*a;i++}END{if(i>0){ave=ave/i;sig=sqrt(sig/i-(ave)**2);printf "%d 0 0 0 %g %g %g %g %g \n",i,ave,sig,sig*sqrt(i/(i-1)),wave/wsig,sqrt(1/wsig)}else{print 0,0,0,0,0,0,0,0,0}}' $tarr`
	set STATS[2] = `head -n1 $tarr | cut -d " " -f 1 `
	set STATS[3] = `tail -n1 $tarr | cut -d " " -f 1 `
	set NUM = `awk 'BEGIN{print int('$STATS[1]'/2) }'`
	set STATS[4] = `head -n $NUM $tarr | sort -gr | head -n1 | cut -d " " -f 1 `
    end
    if ( $verb == 1 ) then
	printf "%2d %6d %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e %10.3e \n" $n $STATS
    endif
#    set BACKSIGC = `awk 'BEGIN {printf "%8.4f\n%8.4f\n",'$STATS[5]','$STATS[7]'*sqrt('$xstep'*'$ystep')}' `
    set BACKSIGC = `awk 'BEGIN {printf "%d\n%8.4f\n%8.4f\n",'$STATS[1]','$STATS[5]','$STATS[7]'*sqrt('$xstep'*'$ystep')}' `
else
    set BACKSIGC = ( $BACKSIG )
endif
#rm -f ${temp}_*.dat* >>& /dev/null
#printf "$BACKSIG" >>& /dev/stderr
#printf "$STATS" >>& /dev/stderr
#printf "$BACKSIGC" >>& /dev/stderr
printf "%09d %10.5f\n%09d %10.5f\n" $BACKSIG[1] $BACKSIG[3] $BACKSIGC[1] $BACKSIGC[3]
exit 0

