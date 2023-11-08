#!/bin/csh -f

set coadd = $1
set coaddw = $2
set PSCALE = $3
set fsast = $4
set fsbin = $5
set sm = $6
set SEXFLAG = $7
set group = $8

set clients = ( cocat1.u-strasbg.fr axel.u-strasbg.fr vizier.hia.nrc.ca )

# ZEROPOINTS FOR ELECTRONS/s  AT 0.16"/PIX

set filter = `gethead $coadd filter`
if ( $filter == J ) then
    set filtmass = J
    set REFPOS1 = 4
    set REFPOS2 = 4
    set OFFSET = 0
    set REFZP = 27.145
    set PEC = 0.10
    set VAB = 0.919
endif
if ( $filter == H ) then
    set filtmass = H
    set REFPOS1 = 6
    set REFPOS2 = 6
    set OFFSET = 0
    set REFZP = 26.841
    set PEC = 0.05
    set VAB = 1.364
endif
if ( $filter == Ks ) then
    set filtmass = K
    set REFPOS1 = 8
    set REFPOS2 = 8
    set OFFSET = 0
    set REFZP = 26.016
    set PEC = 0.05
    set VAB = 1.854
endif
if ( $filter == J1 ) then
    set filtmass = J
    set REFPOS1 = 4
    set REFPOS2 = 10
    set OFFSET = 0.21
    set REFZP = 26.662
    set PEC = 0.10
    set VAB = 0.677
endif
if ( $filter == J2 ) then
    set filtmass = J
    set REFPOS1 = 4
    set REFPOS2 = 12
    set OFFSET = 0.08
    set REFZP = 26.598
    set PEC = 0.107
    set VAB = 0.799
endif
if ( $filter == J3 ) then
    set filtmass = J
    set REFPOS1 = 4
    set REFPOS2 = 12
    set OFFSET = -0.15
    set REFZP = 26.563
    set PEC = 0.10
    set VAB = 0.984
endif
if ( $filter == Hs ) then
    set filtmass = H
    set REFPOS1 = 6
    set REFPOS2 = 16
    set OFFSET = -0.02
    set REFZP = 26.303
    set PEC = 0.05
    set VAB = 1.304
endif
if ( $filter == Hl ) then
    set filtmass = H
    set REFPOS1 = 6
    set REFPOS2 = 18
    set OFFSET = -0.13
    set REFZP = 26.159
    set PEC = 0.05
    set VAB = 1.447
endif
if ( $filter == NB-1.18 ) then
    set filtmass = J
    set REFPOS1 = 6
    set REFPOS2 = 20
    set OFFSET = 0.62
    set REFZP = 24.050
    set PEC = 0.05
    set VAB = 0.854
endif
if ( $filter == NB-2.09 ) then
    set filtmass = K
    set REFPOS1 = 6
    set REFPOS2 = 22
    set OFFSET = 0
    set REFZP = 26.145
    set PEC = 0.05
    set VAB = 1.810
endif

printf "\nFINDING $filter ZEROPOINT \n"
set coords = `gethead $coadd CRVAL1 CRVAL2 NAXIS1 NAXIS2 SCALE`
if ( ! -e 2MASS_${filter}_${group}.cat  ) then
    @ nser = 1
tryagain:
    setenv CDSCLIENT $clients[$nser]
    echo "CDSCLIENT = $CDSCLIENT"
    printf "Downloading 2MASS data for $coords :\n"   
    # reports 3E-2 convert to 3e-2 for find2mass
    set coords[1] = $coords[1]:l
    set coords[2] = $coords[2]:l
    set radius = `echo " sqrt($coords[3]*$coords[3] + $coords[4]*$coords[4]) * 0.50 * $coords[5] / 60.0 " | bc`
    echo "find2mass $coords[1],$coords[2] -r $radius -eb -l${filtmass} 8,20 -m10000000"
    find2mass $coords[1],$coords[2] -r $radius -eb -l${filtmass} 8,20 -m10000000 > 2MASS_${filter}_${group}.cat
    if ( $status != 0 || `cat 2MASS_${filter}_${group}.cat | wc -l` <= 3 ) then
	if ( $nser == $#clients ) then
	    echo "DID NOT FIND 2MASS STARS... SERVER DOWN?"
	    rm -fr 2MASS_${filter}_${group}.cat
	    exit 1
	endif
	@ nser ++
	goto tryagain
	exit 1
    endif
endif


set TEMPENV = `gethead $coadd tempenv`
set MJD = `gethead $coadd mjd`
set PIXS = $coords[5]
set FWHM = `gethead $coadd FWHM_AVE`
set FWHM = `awk 'BEGIN {fwhm = ('$FWHM'<=0) ? 1 : '$FWHM' ;print fwhm }'`
set EXP = `gethead $coadd exptime`
set EFFRN = `gethead $coadd effrn`
set BACK = `gethead $coadd backgnd`
set BACKSIG = `gethead $coadd backsig`
set AIRMASS = `gethead $coadd airmass`
set AIRMASS = `printf "%5.3f" $AIRMASS`
set GAIN = `gethead $coadd gain`
set CORR = `awk 'BEGIN {print 5*log('$PIXS' / 0.16)/log(10) }'`
set CORR = 0
echo group \= $group
echo 2MASS OFFSET \= $OFFSET
echo CORR \= $CORR


if ( -e 2coadd_${filter}_${group}.coo && ! -z 2coadd_${filter}_${group}.coo ) then
    echo 2coadd_${filter}_${group}.coo already exist...
else
    if ( $SEXFLAG == ALL ) then
	grep -v \# 2MASS_${filter}_${group}.cat | cut -d "|" -f1-5 | tr "|" " " > 2MASS_${filter}_${group}.tmp
    else
	grep $SEXFLAG 2MASS_${filter}_${group}.cat | cut -d "|" -f1-5 | tr "|" " " > 2MASS_${filter}_${group}.tmp
    endif

    mv 2MASS_${filter}_${group}.tmp 2MASS_${filter}_${group}.tmp.orig
    awk '{gsub("---","0.1",$0); print}' 2MASS_${filter}_${group}.tmp.orig > 2MASS_${filter}_${group}.tmp
    rm -fr 2MASS_${filter}_${group}.tmp.orig

    sky2xy $coadd @2MASS_${filter}_${group}.tmp > 2MASS_${filter}_${group}.dat
    paste 2MASS_${filter}_${group}.tmp 2MASS_${filter}_${group}.dat | awk ' ! /off/ {print NR,$1,$2,$(NF-1),$NF,$('$REFPOS1'),$('$REFPOS1'+1)}' > 2MASS_${filter}_${group}.coo
    # NOTE: USING FLUX_AUTO and MAG_AUTO 
    sex $coadd -c $fsast/sex3.config -PARAMETERS_NAME $fsast/sex3.param -FILTER_NAME $fsast/default.conv -STARNNW_NAME $fsast/default.nnw -ASSOC_NAME 2MASS_${filter}_${group}.coo -ASSOC_PARAMS 4,5 -ASSOC_RADIUS 2.0 -ASSOC_TYPE NEAREST -ASSOC_DATA 0 -CATALOG_TYPE ASCII -CATALOG_NAME 2coadd_${filter}_${group}.coo -CHECKIMAGE_TYPE NONE -VERBOSE_TYPE QUIET -WEIGHT_TYPE MAP_WEIGHT -WEIGHT_GAIN N -WEIGHT_IMAGE ${coaddw} -BACK_SIZE 128 -BACK_FILTERSIZE 4 -SATUR_KEY SATURATE -PIXEL_SCALE $PIXS -GAIN $GAIN -GAIN_KEY GAIN

endif

printf "\nFound %d $SEXFLAG 2MASS sources\n" `cat 2MASS_${filter}_${group}.coo | wc -l`

set REFZP2 = `echo "scale=3;$REFZP - $PEC * $AIRMASS" | bc -l`
set TMASSERR = 0.2
set RANGE = 1.0
set SEXFLAG = 1
set stellarity = 0.01

# FIND INITIAL AVERAGE ZP FROM ALL FIELD 2MASS STARS (with AAA rating) 
set scale = 0.8
set FWHM = `echo $FWHM | awk '{printf "%5.2f\n",$1}'`
set SATURATE = `gethead $coadd SATURATE | awk '{printf "%8.2f\n",$1}'`
printf "image = $coadd,    satlevel = $SATURATE, FWHM = $FWHM, scale = $PIXS \n"
iphot:

set SATURATE2 = `echo $SATURATE | awk '{printf "%8.2f\n",$1*'$scale'}'`
printf "image = $coadd, sexsatlevel = $SATURATE2, FWHM = $FWHM, scale = $PIXS \n"


# I LOOK AT TOTAL FLUX AND SCALE TO PREDICTED PEAK FLUX.   PROBLEM WITH SATURATED SOURCES... THE CORES ARE ZERO.   
if ( $SEXFLAG ) then
    set AVE1 = `awk 'BEGIN {ave=0;sig=0;i=0}{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' && $18==0  ){ave=ave+($6-$16+'$CORR'+'$OFFSET')/($7)^2;sig=sig+1/($7)^2;i++}}END{if(i>0){printf "%7.3f %7.3f %d\n",ave/sig,sqrt(1/sig),i}else{print 0,0,0}}' 2coadd_${filter}_${group}.coo`
echo $AVE1[1]
    set nmed = `awk 'BEGIN{ print int('$AVE1[3]'/2)}'`
    set AVE1[1] = `awk '{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' && $18==0  ){print ($6-$16+'$CORR'+'$OFFSET')}}' 2coadd_${filter}_${group}.coo | sort -n | head -n $nmed | sort -nr | head -n 1 `

echo $AVE1[1]
# {ave=ave+($4-$6)/($5^2+$7^2);sig=sig+1/($5^2+$7^2);i++}}END{print ave/sig,sqrt(1/sig),i}
else
#    set AVE1 = `awk 'BEGIN {ave=0;sig=0;i=0}{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' ){ave=ave+($6-$16)+'$CORR'+'$OFFSET';sig=sig+($6-$16)^2;i++}}END{if(i>0){printf "%7.3f %7.3f %d\n",ave/i,sqrt(sqrt((i*sig-ave^2)^2))/i,i}else{print 0,0,0}}' 2coadd_${filter}_${group}.coo`
    set AVE1 = `awk 'BEGIN {ave=0;sig=0;i=0}{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' ){ave=ave+($6-$16+'$CORR'+'$OFFSET')/($7)^2;sig=sig+1/($7)^2;i++}}END{if(i>0){printf "%7.3f %7.3f %d\n",ave/sig,sqrt(1/sig),i}else{print 0,0,0}}' 2coadd_${filter}_${group}.coo`
#
#    awk '{printf "%9.2f  %9.2f %5.2f \n",($13*0.88*('$PIXS'/'$FWHM')**2,'$SATURATE2',$20) }' 2coadd_${filter}_${group}.coo
#    awk '{printf "%9.2f  %9.2f %5.2f \n",$13*0.88*('$PIXS'/'$FWHM')**2,'$SATURATE2',$20 }' 2coadd_${filter}_${group}.coo



endif
set AVE2 = `echo "scale=3;$AVE1[1] - ($OFFSET)" | bc -l`
printf "Initial guess for %10s = %7.3f - (%5.3f*%5.3f) = %7.3f \n" $filter ${REFZP} ${PEC} ${AIRMASS} $REFZP2
printf "2MASS AVERAGE for %10s = %7.3f + (%5.3f)       = $AVE1 \n\n" $filtmass $AVE2 $OFFSET 
#  Reject half outliers.
set num = $AVE1[3]
set num2 = `awk 'BEGIN {printf "%5.0f\n",'$num'*0.85+1}'`
echo "Cutting $num sources to $num2"
while ( $num > $num2 || $num < 3 ) 
    set num = $AVE1[3]
    if ( `echo "$scale > 2.0" | bc` ) then
	printf "WARNING: CANT FIND 2MASS STARS AT $scale SATURATION, BREAKING LOOP...\n"
	break
    endif
    if ( `echo "$num < 3" | bc` ) then  # set the saturation limit a little higher
	set scale = `echo "scale=3; $scale * 1.05" | bc`
	if ( `echo "$scale > 1.0" | bc` ) then
	    printf "WARNING: INCREASING SATURATION LIMIT TO $scale x $SATURATE, ZERO-POINT MAY BE WRONG\n"
	endif
	goto iphot		
    endif
    set num = `echo "scale=0; $num * 0.5 + 1 " | bc`
    set num = `printf "%5.0f\n" $num`
# TAKE LOG OF DIFFERENCE SQUARED, SMALL DIFFERENCE RETURN 1E-2 AND SORT DOES NOT LIKE E.   
    if ( $SEXFLAG ) then
	awk '{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' && $18==0 ){printf "%f %f %f %f %f\n",((($6-$16+'$CORR'+'$OFFSET')-'$AVE1[1]')^2),$6,$7,$16,$6-$16}}' 2coadd_${filter}_${group}.coo | sort -n | head -n $num | cut -d\  -f 2,3,4,5 > 2coadd_${filter}_${group}.tmp
    else
	awk '{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' ){printf "%9.8f %9.5f %9.5f %9.5f %9.5f\n",((($6-$16+'$CORR'+'$OFFSET')-'$AVE1[1]')^2),$6,$7,$16,$6-$16}}' 2coadd_${filter}_${group}.coo | sort -n | head -n $num | cut -d\  -f 2,3,4,5 > 2coadd_${filter}_${group}.tmp
    endif
    set AVE1 = `awk 'BEGIN {ave=0;sig=0;i=0}{if($2>0){ave=ave+$4/$2^2;sig=sig+1/$2^2;i++}}END{if(i>0){printf "%7.3f %7.3f %d\n",ave/sig+'$CORR'+'$OFFSET',sqrt(1/sig),i}else{print 0,0,0}}' 2coadd_${filter}_${group}.tmp`
    printf "Iterative guess = $AVE1\n"
end


printf " ------------------------------------\n"
printf "         MJD   =   %10.4f \n" $MJD
printf "      FILTER   =   %s\n" $filter
printf "     AIRMASS   =   %5.3f\n" $AIRMASS
printf "ENV TEMPERATUR = %7.2f [C]\n" $TEMPENV
printf "    BACKGROUND = %7.2f+-%5.2f per second\n" $BACK $BACKSIG
#printf "    READ NOISE = %7.2f per input frame\n" $EFFRN
printf "AVERAGE SEEING = %7.2f arc-seconds\n" $FWHM
printf "FINAL GAIN     = %7.2f e-/s \n" $GAIN
printf " ------------------------------------\n"


# Have to use log function (actually ln in awk) to get rid of numbers printed in scientific format (1e-8) which sort does not handle
if ( $SEXFLAG ) then
    awk '{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' && $18==0 ){print log((($6-$16+'$CORR'+'$OFFSET')-'$AVE1[1]')**2),$6,$7,$16,$6-$16}}' 2coadd_${filter}_${group}.coo | sort -n | head -n $num | cut -d\  -f 2,3,4,5 > 2coadd_${filter}_${group}.mag
else
    awk '{if( ($13*0.88*('$PIXS'/'$FWHM')**2 < '$SATURATE2') && $20 > '$stellarity' ){print log((($6-$16+'$CORR'+'$OFFSET')-'$AVE1[1]')**2),$6,$7,$16,$6-$16}}' 2coadd_${filter}_${group}.coo | sort -n | head -n $num | cut -d\  -f 2,3,4,5 > 2coadd_${filter}_${group}.mag
endif


if ( `echo "$num < 3" | bc` ) then
    printf "WARNING: NOT ENOUGH 2MASS STARS TO DETERMINE INDEPENDENT ZERO-POINT, USING HISTORIC VALUE, ZERO-POINT MAY BE WRONG\n"
    set MZP = `echo $REFZP2 | awk '{print $1,0.05,0}'`
else
    set MZP = `awk 'BEGIN {ave=0;sig=0;i=0}{if($2>0){ave=ave+($4/$2^2);sig=sig+1/($2)^2;i++}}END{if(i>0){printf "%7.3f %7.3f %d\n",ave/sig+'$CORR'+'$OFFSET',sqrt(1/sig),i}else{print 0,0,0}}' 2coadd_${filter}_${group}.mag`
endif

set BACKMAG = `echo "scale=3 ; -2.5*l($BACK / $PIXS / $PIXS)/l(10) + $MZP[1] " | bc -l`
set DEPTH = `awk 'BEGIN {printf "%7.3f\n",-2.5*log(5*'$BACKSIG'*3.1415926*((('$FWHM'/1)/2)/('$PIXS'))**2)/log(10) + '$MZP[1]' }'`
printf " ------------------------------------\n"
printf "%20s: %7.3f+-%5.3f, n=%d\n" "2MASS after clipping" $MZP[1] $MZP[2] $MZP[3]
printf "%20s= %7.3f [mag per sq-arcsecond]\n" "SKY BACKGROUND" $BACKMAG
printf "%20s= %7.3f [1-arcsecond aperture]\n " "5-sigma DEPTH" $DEPTH
printf " ------------------------------------\n"
sethead $coadd MAGZP\=$MZP[1] / "2MASS Zero-point "
sethead $coadd MAGZPE\=$MZP[2] / "2MASS zp stddev"
sethead $coadd MAGZPN\=$MZP[3] / "2MASS number of stars used"
sethead $coadd BACKMAG\=$BACKMAG / "SKY LEVEL [mag per sq-arcsecond]"
sethead $coadd DEPTH\=$DEPTH / "5-sigma depth [1-arcsec aperture]"


# IF A KNOWN STANDARD FIELD
# DO std.objects last.  The last entry is what gets plotted.
foreach object ( ukirt.objects std.objects )
    if ( $object == std.objects ) then
	set STN = 1
	set REFPOS = $REFPOS2
    endif
    if ( $object == ukirt.objects ) then
	set STN = 2
	set REFPOS = $REFPOS1
    endif
    awk '{print $2,$3}' $fsbin/$object > atmp.txt
    sky2xy $coadd @atmp.txt > 4tmp.dat
    paste $fsbin/$object 4tmp.dat |  awk ' ! /off/ {print NR,$2,$3,$(NF-1),$NF,$('$REFPOS'),$('$REFPOS'+1),$1}' > 4star_stds.coo
    rm -fr atmp.txt
    rm -fr 4tmp.txt
# may need to edit this if astrometry is not good enough
set assoc_rad = 10
    if ( ! -z 4star_stds.coo ) then
	set STD = `awk '{print $NF}' 4star_stds.coo`
	rm -f 4star.coo >>& /dev/null
	sex $coadd -c $fsast/sex3.config -PARAMETERS_NAME $fsast/sex3.param -FILTER_NAME $fsast/default.conv -STARNNW_NAME $fsast/default.nnw -ASSOC_NAME 4star_stds.coo -ASSOC_PARAMS 4,5 -ASSOC_RADIUS $assoc_rad -ASSOC_TYPE NEAREST -ASSOC_DATA 0 -CATALOG_TYPE ASCII -CATALOG_NAME 4star.coo -CHECKIMAGE_TYPE NONE -VERBOSE_TYPE QUIET -WEIGHT_TYPE MAP_WEIGHT -WEIGHT_GAIN Y -WEIGHT_IMAGE $coaddw -BACK_SIZE 128 -BACK_FILTERSIZE 4
	set MZP = `awk 'BEGIN {ave=0;sig=0;i=0}{{ave=ave+($6-$16);sig=sqrt(sig^2+($7)^2+($17)^2);i++}}END{if(i>0){printf "%7.3f %7.3f %d\n",ave/i+'$CORR',sig/i,i}else{print 0,0,0}}' 4star.coo`
	set BACKMAG = `echo "scale=3 ; -2.5*l($BACK / $PIXS / $PIXS)/l(10) + $MZP[1] " | bc -l`
	set DEPTH = `awk 'BEGIN {printf "%7.3f\n",-2.5*log(5*'$BACKSIG'*3.1415926*((('$FWHM'/1)/2)/('$PIXS'))**2)/log(10) + '$MZP[1]' }'`
	printf " ------------------------------------\n"
	printf "%20s: %7.3f+-%5.3f \n" $STD $MZP[1] $MZP[2]
	printf "%20s= %7.3f [mag per sq-arcsecond]\n" "SKY BACKGROUND" $BACKMAG
	printf "%20s= %7.3f [1-arcsecond aperture]\n " "5-sigma DEPTH" $DEPTH
	printf " ------------------------------------\n"
	sethead $coadd MZPSTD_$STN\=$MZP[1] / "ZP "
	sethead $coadd MZPERR_$STN\=$MZP[2]
	sethead $coadd DEPTH_$STN\=$DEPTH / "5-sigma depth [1-arcsec aperture]"
	set MZP[3] = 0
    endif
end

if ( -e $sm ) then
    $fsbin/fssm_mag.csh 0 `pwd` $filter $SATURATE $PIXS $FWHM $MZP[1] $MZP[2] $MZP[3] $group  >>& /dev/null
endif



exit 0
