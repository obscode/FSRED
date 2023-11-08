#!/bin/csh -f

set coadd = $1
set coaddw = $2
set fsast = $3
set list = $4

set array = `gethead $coadd FILTER MJD SATURATE SCALE`
set mzp = `gethead $coadd MAGZP MAGZPE MAGZPN`

set CORR = `awk 'BEGIN {print 5*log('$array[4]' / 0.16)/log(10) }'`
#set CORR = 0
echo CORR \= $CORR

awk '{print $1,$2,$3}' $list > atmp.txt
sky2xy $coadd @atmp.txt > 4mag.dat
paste $list 4mag.dat |  awk ' ! /off/ {print NR,$1,$2,$(NF-1),$NF,0,0,$3}' > 4star_mags.coo
rm -fr atmp.txt
rm -fr 4mag.txt
# may need to edit this if astrometry is not good enough
set assoc_rad = 20
if ( ! -z 4star_mags.coo ) then
    set STD = `awk '{print $NF}' 4star_mags.coo`
    rm -f 4star.coo >>& /dev/null
    set MAP_WEIGHT = NONE
    sex $coadd -c $fsast/sex3.config -PARAMETERS_NAME $fsast/sex3.param -FILTER_NAME $fsast/default.conv -STARNNW_NAME $fsast/default.nnw -ASSOC_NAME 4star_mags.coo -ASSOC_PARAMS 4,5 -ASSOC_RADIUS $assoc_rad -ASSOC_TYPE NEAREST -ASSOC_DATA 0 -CATALOG_TYPE ASCII -CATALOG_NAME 4star.coo -CHECKIMAGE_TYPE NONE -VERBOSE_TYPE QUIET -WEIGHT_TYPE $MAP_WEIGHT -WEIGHT_GAIN Y -WEIGHT_IMAGE $coaddw -BACK_SIZE 128 -BACK_FILTERSIZE 4 -MAG_ZEROPOINT 0 
    if ( ! -z 4star.coo ) then
	set MAG = `awk '{ave=$16+('$mzp[1]'-'$CORR');sig=sqrt($17^2+'$mzp[2]'^2);printf "%7.3f %7.3f %10f\n",ave,sig,$15}' 4star.coo`
	set SN = ""
	if (  `echo "$MAG[3] >= $array[3]" | bc -l`  ) then
	    set NOTE = "SATURATED"
	else
	    set NOTE = "NOT-SATURATED"
	endif
	printf " ------------------------------------\n"
	printf "%20s %10.5f %8s %7.3f %5.3f    %20s \n" $STD $array[2] $array[1] $MAG[1] $MAG[2] $NOTE | tee -a $list
	printf " ------------------------------------\n"
    else
	printf "Something went wrong \n"
    endif
endif

exit 0
