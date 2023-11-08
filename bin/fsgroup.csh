#!/bin/csh -f

# SET SED USAGE
if ( `uname` =~ Linux ) then
#    printf "Found Linux\n"
    set sedi = "sed -i''" 
else if ( `uname` =~ Darwin ) then
#    printf "Found MacOSX\n"
    set sedi = "sed -i ''"
else
    set sedi = "sed -i ''"
endif
alias sedi $sedi

set pwd = `pwd`

set DIST = 0.2      # SEPARATION (DEGREES) BETWEEN GROUPS||  0.05 = 3"  ||  0.1 = 6"  ||  0.2 = 12"
set DT = 5         # TIME SINCE LAST IMAGE (MINUTES) AFTER WHICH TO CONSIDER A NEW GROUP (ie PAUSED FOR CLOUDS, SEEING) 
set PREFIX = "fsr_" # raw filename prefix
set SUFFIX = ".fits" # raw filename extension type
if ( $#argv < 1) then
    goto help
endif
set temp = `getopt ahifvp:c:s:t: $*`
eval set argv=\($temp:q\)
set ignoreobj = 0
set ignorecor = 0
set verb = 0
set flag = 1
set tflatflag = 1
set DIR = `pwd`
set CHIP = 1 
set doall = 1
while ( 1 )
    switch($1)
    case -a:  
      echo "Ignoring new object coordinates." ; shift;
      set ignorecor = 1
      breaksw 
    case -f:
	echo "Ignoring Obstype=tflat, dflat, test, dark in fianl efficiency rating."
	set tflatflag = 11
	shift
	breaksw
    case -p:
      if ( -d $2 ) then
	cd $2 ; set DIR = `pwd` ; cd $pwd
      else
	echo "$2 Not a directory.  Exiting..."
	exit 1
      endif
      shift ; shift;
      breaksw 
    case -c:
      set CHIP = $2
      set doall = 0
      shift ; shift;
      breaksw 
    case -s:  
      set DIST = $2
      shift ; shift;
      breaksw 
    case -t:  
      set DT = $2
      shift ; shift;
      breaksw 
    case -i:  
      echo "Ignoring new object names." ; shift;
      set ignoreobj = 1
      breaksw 
    case -v:  
      echo "Showing logical reason for group change" ; shift;
      set verb = 1
      breaksw 
    case -h
help:
	echo "Usage:"
	echo "fsgroup.csh [-d path -s search_rad -i -c chip]"
	echo " -a make lists using object names. Ignore changes in object coordinates (BUG in no guider wait option if preview was used )."
	echo " -p path.  The default path is the current working directory."
	echo " -f ignore obstype = test, tflat, dflat or dark in final efficiency rating."
	echo " -s search radius in degrees, the default is 0.2.  "
	echo " -t dead ime in minutes before considering a new group. ie paused macro for cloud  "
	echo " -i make lists using objects with cone radius.  (i)gnore changes in object names and multiple similar macro executions."
	echo " -c chip, values 1-4 are accepted.  If specified only this chip will be considered, default is all four"
	echo " -v print descriptions of logical group change.  "
	exit 0
    case --:
      shift
      break
    default:
	exit 0
    endsw
end

set NFORM = ${PREFIX}"????_??_c"${CHIP}""${SUFFIX}"*" # raw filename search format, here only scan chip 1 headers...faster, then add chips 2,3,4 to list.   
set ADIR = `cd $DIR ; pwd` 
echo Searching $ADIR
echo Searching within cone radius of $DIST degrees.
echo Considering a new group after $DT min interrupt. 
echo Searching for chip $CHIP
if ( $doall ) then
    echo Doing chips 1-4
endif

set d2r = `echo "3.1415926535897/180" | bc -l`
set DIST = `echo "c($DIST*$d2r)" | bc -l`
#rm -f 0_groups.list 0_header.list
# CHECK if 0_groups.list already exist, start where it left off..
if ( -e 0_groups.list && ! -z 0_groups.list ) then
    echo "Found existing 0_groups.list file, continuing from last entry (redoing last entry in case of new frames):"
    set refrun = `tail -n1 0_groups.list | awk '{print $10}'`
    set reffilt = `tail -n1 0_groups.list | awk '{print $12}'`
    set refexp = `tail -n1 0_groups.list | awk '{print $13}'`
    set refobj = `tail -n1 0_groups.list | awk '{print $9}'`
    set refobs = `tail -n1 0_groups.list | awk '{print $11}'`
    set refmac = `tail -n1 0_groups.list | awk '{print $14}'`
    set refloop = `tail -n1 0_groups.list | awk '{print $16}'`
    set refdith = `tail -n1 0_groups.list | awk '{print $15}'`
    set refgain = `tail -n1 0_groups.list | awk '{print $7}'`
    set refmode = `tail -n1 0_groups.list | awk '{print $8}'`
    set refsti = 0
    set lastst = 0
    set refstf = 9999
    set tflag = 0
# SUBTRACT THE HEADER AND THE LAST ENTRY
    @ ngroups = `cat 0_groups.list | wc -l` - 2
    @ i = 0
# REMOVE THE LAST ENTRY AND UPDATE IT IN CASE NEW FILES NEED TO BE ADDED TO IT.
    sedi '$d' 0_groups.list

    
    cat 0_groups.list
else
    set refrun = "fits"
    set refgain = ""
    set refmode = ""
    set reffilt = "XX"
    set refexp = "0.00"
    set refobj = "AstroFish"
    set refobs = ""
    set refmac = "___"
    set refloop = 0
    set refsti = 0
    set lastst = 0
    set refstf = 9999
    set tflag = 0
    @ ngroups = 0
    @ i = 0
#    printf "%6s %25s %5s %4s %20s %10s %8s %8s %8s %8s %6s %10s %10s %10s %12s %10s %6s %9s %4s %4s %6s\n" RUN MACRO NDITH LOOP OBJECT OBSTYPE FILTER GAIN RMODE EXPTIME AIRMAS RA DEC MJD UT-DATE UT-TIME NUM DT\(MIN\) TEXP  EFF  DTL | tee -a 0_groups.list
     printf "%12s %9s %11s %11s %10s %7s %8s %8s %25s %6s %8s %8s %8s %20s %4s %4s %4s %8s %6s %4s %6s\n" UT-DATE UT-TIME MJD RA DEC AIRMAS GAIN RMODE OBJECT RUN OBSTYPE  FILTER EXPTIME MACRO DITH LOOP NUM DT\(MIN\) TEXP  EFF  DTL | tee -a 0_groups.list
endif


foreach file ( `ls $DIR/$NFORM | grep -A10000 $refrun` )

# define how to parse filename to get the counter number.  
    set run = `echo $file:t | cut -d_ -f2`

# IF FPACKED not a problem, IF GZIPPED MUST UNZIP FIRST.
    unset array
    if ( $file:e == gz ) then
	set array = `gzcat $file | gethead -u -b stdin macrofil ndithers dither nloops loop filter exptime airmass ra dec mjd obstype gain readmode ut-date ut-time object`
    else
	set array = `gethead -u -b $file macrofil ndithers dither nloops loop filter exptime airmass ra dec mjd obstype gain readmode ut-date ut-time object`
    endif
#    echo "$array"
# REPLACE ___ WITH 0
    set array = `echo "$array" | awk '{gsub("___","0",$0); print }'`

# set array of header keywords to examine for changes.
#    if ( `echo "$#array > 17" | bc ` ) then # OBJECT NAME CONTAINS WHITESPACE
#	@ index = 18
#	while ( $index <= $#array ) 
#	    set array[17] = $array[17]_$array[$index]
#	    @ index += 1
#	end
#    endif

# place RA and DEC in decimal format get rid of scientific notation, bc cant handle it. 
    if ( `echo $array[9] | grep :` != "" ) then
	set tmpa = $array[9]
	set tmpb = $array[10]
	set array[9] = `echo $tmpa | awk -F: '{printf "%10.6f\n",15*($1+$2/60+$3/3600)}'`      
	set array[10] = `echo $tmpb | awk -F: '{a=1;if($1~/-/){sub("-","",$1);a=-1} printf "%10.6f\n",a*($1+$2/60+$3/3600)}'`
    endif

# set RA and DEC and time ref position if first group detection. 
    if ( $i == 0 ) then
	set refra = $array[9]
	set refdec = $array[10]
	set refsti = $array[11]
    endif

# look for a change from the reference position
    set nmac = `expr "$array[1]" != "$refmac"`
    set ndith = `expr "$array[3]" = 1`
    set ndith2 = `expr "$array[5]" = 1`
    set nloop = `expr "$array[4]" != "$refloop"`
    set nfilt = `expr "$array[6]" != "$reffilt"`
    set nexp = `expr "$array[7]" != "$refexp"`
    set nobs = `expr "$array[12]" != "$refobs"`
    set ngain = `expr "$array[13]" != "$refgain"`
    set nmode = `expr "$array[14]" != "$refmode"`
    set nobj = `expr "$array[17]" != "$refobj"`
    set dr = `echo "s($array[10]*$d2r)*s($refdec*$d2r)+c($array[10]*$d2r)*c($refdec*$d2r)*c(($array[9]-($refra))*$d2r)" | bc -l`
# Comparing the cosines, bc cant do arc-cosines!
    set npos = `echo "$dr < $DIST" | bc`
#    set dt = `echo "($array[11]-$refsti)*1440" | bc -l`
    set dt = `echo "($array[11]-$refsti)*1440" | bc -l`
# (dt) time since (l)ast exposure.
    set dtl = `echo "($array[11]-$lastst)*1440 - $refexp/60" | bc -l`
    set lastst = $array[11]
    set longtime = `echo "$dtl > $DT" | bc`

    if ( $ignoreobj == 1 ) then
	set nobj = 0
	set ndith = 0
    endif
    if ( $ignorecor == 1 ) then
	set npos = 0
    endif
    if ( "$array[6]" == "dark"  ) then
	set ndith = 0
    endif

# If there is a change set new group parameters
    if ( $nfilt || $nexp || ( "$array[6]" != "dark" && $npos ) || $nobj || $nmac || ($ndith && $ndith2 ) || $nloop || $longtime || ( $nobs && `echo $nmac | grep ext_` != "" )  || $ngain || $nmode  ) then
	# If there was a previous group print stats at end of line.
last:
	if ( $i != 0 ) then
	    if ( $refdith == 0 ) then
		@ nexpect = $refloop
	    else
		@ nexpect = $refloop * $refdith
	    endif
	    set texp = `echo "scale=2;($i * $refexp)/60" | bc -l`
	    set ttot = `echo "scale=2;($refstf-$refsti)*1440 + $refexp/60 " | bc -l `
	    if ( `echo "$ttot > 0" | bc -l` ) then
		set eff = `echo "($texp / $ttot)" | bc -l`
	    else
		set eff = 1
	    endif
	    if ( $i == $nexpect ) then
		printf "%4s %8.2f %6.2f %4.2f %6.2f\n" "${i}" $ttot $texp $eff $dtl | tee -a 0_groups.list
	    else
		printf "%4s %8.2f %6.2f %4.2f %6.2f\n" "${i}-" $ttot $texp $eff $dtl | tee -a 0_groups.list
	    endif
	    @ i = 0
	    if ( $flag == 0 ) then
		goto finish
	    endif
	endif

	set refrun = $run
	set refmac = $array[1]
	set refdith = $array[2]
	set refloop = $array[4]
	set reffilt = $array[6]
	set refexp = $array[7]
	set refair = $array[8]
	set refra = $array[9]
	set refdec = $array[10]
	set refsti = $array[11]
	set refobs = $array[12]
	set refgain = $array[13]
	set refmode = $array[14]
	set refutd = $array[15]
	set refutt = $array[16]
	set refobj = "$array[17]"

	if  ( $i == 0 ) then
	    if ( $verb == 1 ) then
		echo  ""
		if ( $nfilt ) echo new filter \= $reffilt
		if ( $nexp ) echo new exptime \= $refexp
		if ( $npos ) echo new position \= $dr
		if ( $longtime ) echo longtime passed \= $dt
		if ( $nobj ) echo new object \= $refobj
		if ( $ngain ) echo new gain \= $refgain
		if ( $nmode ) echo new read mode \= $refmode
		if ( ( $nobs && `echo $nmac | grep ext_` != "" ) ) echo new obstype \= $refobs
		if ( $nmac ) echo new macro \= $refmac
		if ( $nloop ) echo new loop count \= $refloop
		if ( $ndith && $ndith2  ) echo new macro execution \= $array[3] of $refdith
		echo ""
	    endif
#	    printf "%6s %25s %5s %4s %20s %10s %8s %8s %8s %8s %6s %10.4f %10.5f %10.4f %12s %10s : " $refrun $refmac $refdith $refloop $refobj $refobs $reffilt $refgain $refmode $refexp $refair $refra $refdec $refsti $refutd $refutt | tee -a 0_groups.list
	    printf "%12s %9s %11s %11s %10s %7s %8s %8s %25s %6s %8s %8s %8s %20s %4s %4s " $refutd $refutt $refsti $refra $refdec $refair $refgain $refmode "$refobj" $refrun $refobs $reffilt $refexp $refmac $refdith $refloop       | tee -a 0_groups.list


	    @ ngroups ++
	    @ i ++
	endif
# remove if list already exists to prevent duplicate entries.  
	rm -f $refrun.list >>& /dev/null
# ADD other chips to list since only searching through first chip for unique positions
	foreach ch ( 1 2 3 4)
	    if ( $doall ) then
		if ( -e `echo $file | awk '{sub("_c[1-9]","_c"'$ch');print}'` ) then
		    echo $file:t | awk '{sub("_c[1-9]","_c"'$ch');print}' >> $refrun.list
		endif
	    endif
	end
#	echo $file:t | awk '{for(i=1;i<=4;i++){sub("_c[1-9]","_c"i);print}}' >> $refrun.list


# FOUND ANOTHER MATCH TO REFERENCE
    else
	@ i ++
# ADD other chips to list since only searching through first chip for unique positions
	foreach ch ( 1 2 3 4 )
	    if ( $doall ) then
		if ( -e `echo $file | awk '{sub("_c[1-9]","_c"'$ch');print}'` ) then
		    echo $file:t | awk '{sub("_c[1-9]","_c"'$ch');print}' >> $refrun.list
		endif
	    endif
	end
#	echo $file:t | awk '{for(i=1;i<=4;i++){sub("_c[1-9]","_c"i);print}}' >> $refrun.list
    endif
# SET FINAL TIME OF GROUP
    set refstf = $array[11]
end

if ( $flag == 1 ) then
    set flag = 0
    goto last
endif

finish:
printf "\nnumber of groups found = $ngroups \n\n"

############################################################################


awk 'BEGIN {a=0.001;b=0.001;c=0.001}{if($'$tflatflag'!="dark" && $'$tflatflag'!="tflat" && $'$tflatflag'!="dflat" && $'$tflatflag'!="test"){a=a+$NF+$(NF-3);b=b+$(NF-3);c=c+$(NF-2)}}END{printf "Total Time = %7.2f min.\nObserving Time = %7.2f min.\nSlew/Acquire/Focus Time  = %7.2f min.\nExptime    = %7.2f min.\nDither Eff = %5.2f\nTotal Eff  = %5.2f\n\n",a,b,a-b,c,c/b,c/a}' 0_groups.list

parse:
#BREAK INTO SUBGROUPS
foreach filter ( J H Ks J1 J2 J3 Hl Hs )
    awk '{if ($7 == "'$filter'" && $13 > 2 ) print }' 0_groups.list > 0_groups_$filter.list
    if ( -z 0_groups_$filter.list ) then
	rm 0_groups_$filter.list
    else
	echo created list for $filter filter
    endif
end








exit 0

