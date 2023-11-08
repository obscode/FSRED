#!/bin/csh -f 

set BTYPE = MODE  #  set the background type,  MODE | MIDPT | MEAN

##########################################################

set pwd = $1
cd $pwd
set tempdir = $2
set fsiraf = $3
alias images $4
set images = $4
alias proto $5
set proto = $5
set name2 = $6
set bflag = $7
set NBACK = $8
set CSCALE = $9
set BKJOBS = $10
alias gethead $11
set gethead = $11
set xgrid = $12
set myverbose = $13
set smode = $14
set srows = $15
set scols = $16
set surfit = `echo $17 | tr , " "` 
set sex = $18
set weight = $19
set wt = $20
set wavelet = $21
set nproto = $22
alias nproto $22
set interpolation = $23
#set wt = 1
set cmd = ""
set cmd2 = ""
set HISIG = $25
set DEBUG = $26
set t0 = $27
set OBJT = $28
set BS = $29
set sem = $30
set chips = "$31"
set IOBJMASK = $32
set ADVBACK = $33
set fsflat = "$fsiraf:h:h/FLATS/$sem/"
# APPROXIMATE FLAT FIELD CORRECTIONS FOR EACH CHIP
set FFCOR = ( 0.93 0.99 1.05 1.02 )
set lccor = ( 1.0e-8 1.3e-8 1.1e-8 1.2e-8 )

set REDO = 0

set xaxis = 2048
set yaxis = 2048


# COMPENSATE FOR CROWDED FIELDS WHERE BACKGROUND IS OVER-ESTIMATED. ADDITIONAL fudge*(MEAN-MODE) FACTOR SUBTRACTED FROM MODE.  
set fudge = $24  #  0 | any real number. | 0.25 works well for globular clusters.  


cd $fsiraf 
cd ../BPM/2011B
set bpmloc = `pwd`
cd $pwd

cd $fsiraf
cd ../ASTROMATIC
set fsast = `pwd`
cd $pwd

cd $fsiraf
cd ../bin
set fsbin = `pwd`
cd $pwd

if ( -d "../SKYS" ) then
    cd ../SKYS
    set skys = `pwd`
    cd $pwd
else
    set skys = `pwd`
endif

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

alias sethead `echo $11 | sed 's|get|set|'`
set sethead = `echo $11 | sed 's|get|set|'`
alias delhead `echo $11 | sed 's|get|del|'`

beginning:
set tryflag = 0
startloop:
    foreach ch ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
start:
	set name = ${name2:t}_c$ch.fits
	if ( ! -e $name ) then
	    echo "$name not processed, skipping..."
	    if ( $ch == 4 ) then
		continue
#		exit 0
	    else
		continue
	    endif
	endif

	if ( -e $name.sub.fits && $REDO == 0 ) then
	    echo  "$name.sub.fits already exists"
	    if ( $ch == 4 ) then
		goto fit
	    else
		continue
	    endif
	endif

	if ( $tryflag == 1 ) then
	    if ( $bflag == 0 ) then
		if ( -e $name ) then
		    set TBACK = `gethead -u $name $BTYPE`
		    if ( $TBACK != "___" ) then
			echo  "$name          $BTYPE = $TBACK "
			continue
		    endif
		endif
	    else
		if ( -e $name && -e $name.sky.fits ) then
		    set TBACK = `gethead -u $name $BTYPE`
		    set TBACK2 = `gethead -u $name.sky.fits $BTYPE`
		    if ( $TBACK != "___" && $TBACK2 != "___" ) then
			echo  "$name          $BTYPE = $TBACK "
			echo  "$name.sky.fits $BTYPE = $TBACK2 "
			continue
		    endif
		endif
	    endif
	endif

#	else
# PREPARE TO DO STATS ON TARGET IMAGE
	    echo $name
	    cp $fsiraf/mimstat.par $tempdir/z$name.parc
	    sedi 's|mimstatistics.images =|mimstatistics.images = \"'$name'\"|' $tempdir/z$name.parc
	    sedi 's|mimstatistics.imasks = |mimstatistics.imasks = \"'$name'.pl.fits[1]\"|' $tempdir/z$name.parc
	    sedi 's|mimstatistics.fields =|mimstatistics.fields = \"npix,mean,midpt,mode,stddev,skew,kurtosis,min,max\"|' $tempdir/z$name.parc
	    sedi 's|mimstatistics.nclip = 0|mimstatistics.nclip = 2|' $tempdir/z$name.parc
	    sedi 's|mimstatistics.lsigma = 3|mimstatistics.lsigma = 2|' $tempdir/z$name.parc
	    sedi 's|mimstatistics.usigma = 3|mimstatistics.usigma = 2|' $tempdir/z$name.parc
	    sedi 's|mimstatistics.lower = INDEF|mimstatistics.lower = -60000|' $tempdir/z$name.parc
	    sedi 's|mimstatistics.upper = INDEF|mimstatistics.upper = 60000|' $tempdir/z$name.parc
#	    sedi 's|mimstatistics.format = no|mimstatistics.format = yes|' $tempdir/z$name.parc
# CHECK BFLAG STATUS
	    if ( $bflag == 0 ) then
		echo "BACKGROUND FLAG OFF" 
		set CSCALE = NO
		goto imstat
	    endif
# CHECK IF SKY FRAME EXISTS
	    if ( -e $name.sky.fits && $REDO == 0 ) then
		echo "$name.sky.fits, Already Created"
		goto imstat
#		continue
	    else if ( -e ../SKYS/$name.sky.fits && 0 ) then
#		echo "Linking $name.sky.fits to first pass sky..."
#		ln -s ../SKYS/$name.sky.fits $name.sky.fits
#		ln -s ../SKYS/$name.sky.pl.fits $name.sky.pl.fits
#		ln -s ../SKYS/$name.sky.fits.stats $name.sky.fits.stats
#		goto imstat
		echo "Linking $name.sub.fits to first pass sky..."
		ln -s ../SKYS/$name.sub.fits $name.sub.fits
		ln -s $name.pl.fits $name.sky.pl.fits
		if ( $ch == 4 ) then
		    goto fit
		else
		    continue
		endif
	    else
		set array = `gethead -p $name MJD RA DEC FILTER LOOP CHIP`
		# place RA and DEC in decimal format get rid of scientific notation, bc cant handle it. 
		if ( `echo $array[3] | grep :` != "" ) then
		    set tmpa = $array[3]
		    set tmpb = $array[4]
		    set array[3] = `echo $tmpa | awk -F: '{printf "%10.6f\n",15*($1+$2/60+$3/3600)}'`      
		    set array[4] = `echo $tmpb | awk -F: '{a=1;if($1~/-/){sub("-","",$1);a=-1} printf "%10.6f\n",a*($1+$2/60+$3/3600)}'`
		endif
		set loop = `awk 'BEGIN {printf "%02d\n",'$array[6]'}'`
		set nameloop = `echo $name:t:r | cut -d_ -f3 `
		if ( 1 ) then
		    # INCLUDE CURRENT FRAME BUT SET WEIGHT TO ZERO.  ALLOWS IMCOMBINE TO SCALE FRAME TO IT. 
		    set tzero = 0
		else
		    # DO NOT INCLUDE current frame
		    set tzero = 10000
		endif
		echo $loop $nameloop
		set loop = $nameloop
	    # FIND NBACK NEAREST (in time) SKY FRAMES AND WEIGHT BY 1/(dt), IGNORE COMMENTED OUT LINES 
		if ( $weight == 1 ) then
		    echo "weight = $weight"
		    awk ' \!/#/ {if($1 ~ "_'$loop'_c'$array[7]'"  && $5 == "'$array[5]'"){a=('$array[2]'-$2);b=a<0?-a:a;if(a\!= 0 ){ print $1,b,0,1/b} else {print $1,'$tzero',0,0} } }'\
		    $tempdir/MJD_$ch.cat | sort -n -k2 | head -n $NBACK > $tempdir/z$name.dat
	    # FIND NBACK NEAREST (in time) SKY FRAMES AND WEIGHT BY 1/(dt*dr), IGNORE COMMENTED OUT LINES 
		else if ( $weight == 2 ) then
		    awk ' \!/#/ {if($1 ~ "_'$loop'_c'$array[7]'"  && $5 == "'$array[5]'") \
		    a=('$array[2]'-$2);b=a<0?-a:a;f=3.1415926/180.;\
		    if($3~":"){split($3,d,":");$3=15*(d[1]+d[2]/60+d[3]/3600)}else{$3=15*$3};\
		    if($4~":"){split($4,d,":");s=1;if(d[1]<0){d[1]=-d[1];s=-1};$4=s*(d[1]+d[2]/60+d[3]/3600)};\
		    c=acos(sin('$array[4]'*f)*sin($4*f)+cos('$array[4]'*f)*cos($4*f)*cos(('$array[3]'-$3)*f));\
		    if(a\!= 0){ print $1,b,c,1/(b*(1+c)),(b*(1+c))} else {print $1,'$tzero',0,0,0};\
		    } function acos(x) {return atan2(sqrt(1-x^2),x)/f};\
		    ' $tempdir/MJD_$ch.cat | sort -n -k2 | head -n $NBACK > $tempdir/z$name.dat
	    # FIND NBACK NEAREST (in time) UNIFORM WEIGHTING, INCLUDES CURRENT FRAME.  
		else
		    awk ' \!/#/ {if($1 ~ "_'$loop'_c'$array[7]'"  && $5 == "'$array[5]'")\
		    a=('$array[2]'-$2);b=a<0?-a:a;if(a\!= 0){ print $1,b,0,1} else {print $1,b,0,1}}'\
		    $tempdir/MJD_$ch.cat | sort -n -k2 | head -n $NBACK > $tempdir/z$name.dat
		endif
		cat $tempdir/z$name.dat
	    # THROW AWAY LOW WEIGHTS
		if ( 1 ) then
		    mv $tempdir/z$name.dat $tempdir/z$name.dat.tmp
#		    set avew = `awk 'BEGIN{ave=0;i=0}{ave=ave+$4;i++}END{if(i>0){print ave/i}else{print 0}}'`
#		    set avew = ( 100 50 0 )  # EMPIRICAL
		    set avew =  `awk '{max = $NF>max ? $NF : max } END{print max/10,max/20,0 }' $tempdir/z$name.dat.tmp`
		    @ aven = 1
		    echo "Setting lower weight to $avew[$aven]."
throw:
		    awk '{if($4 >'$avew[$aven]' || $4==0){print}}' $tempdir/z$name.dat.tmp > $tempdir/z$name.dat
		    set bnum = `cat $tempdir/z$name.dat | wc -l`
		    if ( `echo "$bnum < 5" | bc`  ) then
			@ aven ++
			echo "Not enough high weight background frames.  Setting lower weight to $avew[$aven]."
			goto throw
		    endif
		endif

# FIND BACKGROUND IN THE TARGET FRAME, MASKING OBJECTS IN SKY AND TARGET
		if ( ! -z $tempdir/z$name.dat ) then
		    printf "\n     BACKGROUND IMAGES FOUND:      \n"
		    printf "%8s %8s %9s %30s\n" dt dr wght image
		    awk '{printf "%8.5f %8.5f %9.2f %30s \n",$2*1440,$3,$4,$1 }' $tempdir/z$name.dat
		    awk '{print $4}' $tempdir/z$name.dat > $tempdir/z$name.data  # WEIGHTS
		    awk '{print $1}' $tempdir/z$name.dat > $tempdir/z$name.datb  # IMAGE NAMES

# CREATE SKY FROM NEARBY FRAMES WEIGHTED BY TIME FROM THE TARGET FRAME
		    cp $fsiraf/imcombine.par $tempdir/z$name.para
		    cp $fsiraf/imcombine.par $tempdir/z$name.para2
		    if ( `echo "$bflag < 1" | bc` ) then
			sedi 's|imcombine.combine =|imcombine.combine = \"average\"|' $tempdir/z$name.para
			sedi 's|imcombine.combine =|imcombine.combine = \"average\"|' $tempdir/z$name.para2
			sedi 's|imcombine.reject = \"none\"|imcombine.reject = \"minmax\"|' $tempdir/z$name.para
			sedi 's|imcombine.nlow = 2|imcombine.nlow = 0|' $tempdir/z$name.para
			sedi 's|imcombine.nhigh = 2|imcombine.nhigh = '$bflag'|' $tempdir/z$name.para
		    else 
			sedi 's|imcombine.combine =|imcombine.combine = \"average\"|' $tempdir/z$name.para
			sedi 's|imcombine.combine =|imcombine.combine = \"average\"|' $tempdir/z$name.para2
			sedi 's|imcombine.reject = \"none\"|imcombine.reject = \"avsigclip\"|' $tempdir/z$name.para
#			sedi 's|imcombine.nkeep = 1|imcombine.nkeep = '$bflag'|' $tempdir/z$name.para
#			sedi 's|imcombine.mclip = yes|imcombine.mclip = yes|' $tempdir/z$name.para
#			sedi 's|imcombine.lsigma = 3|imcombine.lsigma = 2|' $tempdir/z$name.para
			sedi 's|imcombine.hsigma = 3|imcombine.hsigma = '$bflag'|' $tempdir/z$name.para
		    endif
		    sedi 's|imcombine.weight = \"none\"|imcombine.weight = \"\@'$tempdir''z$name'.data\"|' $tempdir/z$name.para
		    sedi 's|imcombine.weight = \"none\"|imcombine.weight = \"\@'$tempdir''z$name'.data\"|' $tempdir/z$name.para2
		# THE DEFAULT LOCATION FOR THE MASK IS THE BPM HEADER KEYWORD
		    sedi 's|imcombine.masktype = \"none\"|imcombine.masktype = \"\badbits\"|' $tempdir/z$name.para
		# 2048 - border
		# 128 - custom obj mask.  
		# 64 - no sky
		# 32 - objects
		# 16 - transient
		# 8 - latent   <--- leave in, since it is present in the background.
		# 4 - probes
		# 2 - saturated
		# 1 - bad pixels - PLUS CR's.  
		# 32+16+8+4+2+1 = 63
		# 32+16+ +4+2+1 = 55
		#    16+ +4+2+1 = 23
		    set BADBITS = 55   
		    if ( $IOBJMASK == YES ) then
			set BADBITS = `awk 'BEGIN{print '$BADBITS'+128 }'`
		    endif
		    sedi 's|imcombine.maskvalue = \"0\"|imcombine.maskvalue = \"'$BADBITS'\"|' $tempdir/z$name.para
		# MUST SET 
		    sedi 's|imcombine.lthreshold = INDEF|imcombine.lthreshold = \"-65000\"|' $tempdir/z$name.para
		    sedi 's|imcombine.hthreshold = INDEF|imcombine.hthreshold = \"65000\"|' $tempdir/z$name.para
		    if ( $smode == "SCALE" ) then
			sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"mode\"|' $tempdir/z$name.para
		    endif
		    if ( $smode == "ZERO" ) then
			sedi 's|imcombine.zero = \"none\"|imcombine.zero = \"mode\"|' $tempdir/z$name.para
		    endif
		# APPLIES ONLY TO REJECTION ALGORITHM, NOT MASKS
		    sedi 's|imcombine.grow = 0.|imcombine.grow = 0.|' $tempdir/z$name.para

# BREAK IMAGE INTO CHUNKS... USEFUL IF SKY VARIATIONS ARE ON SIZE SCALES SMALLER THAN A SINGLE ARRAY.
		    set xgrid = 1
		    set ygrid = 1
		    printf "     CREATING SKY FRAME: $name.sky.fits   \n"
		    set cmd = "cd $skys"   # MUST BE IN DIRECTORY WHERE ALL SKY MASKS ARE. 
 		    rm -fr $pwd/$name.sky.exp.pl.fits >>& /dev/null
 		    rm -fr $pwd/$name.sky.pl.fits >>& /dev/null
		    if ( $xgrid == 1 && $ygrid == 1 ) then
			if ( $ADVBACK == 1 ) then
			    if ( 0 ) then
			    # EACH SKY HAS A DIFFERENT SLOPE/SHAPE, ADD A SURFACE FIT TO GET IT CLOSE TO THE SKY WE ARE TRYING TO MATCH.  
				rm -fr $tempdir/z$name.datbb >>& /dev/null
				rm -fr $pwd/$name.sky.cp.fits >>& /dev/null
				rm -fr $pwd/$name.sky.fits >>& /dev/null
				rm -fr $pwd/$name.sky1.fits >>& /dev/null
				rm -fr $pwd/$name.sky2.fits >>& /dev/null
				rm -fr $pwd/$name:t:r >>& /dev/null
				mkdir -p $pwd/$name:t:r			
#			    set skynameref = `cat $tempdir/z$name.dat | sort -k 4 -nr | head -n1 | awk '{print $1}'`
				foreach skyname ( `cat $tempdir/z$name.datb` )
				    set skynameo = $pwd/$name:t:r/$skyname:t
				    set skynameo1 = $skynameo:s/.fits/.2d.fits/
				    set skynameo2 = $skynameo:s/.fits/.2do.fits/
				    rm -fr $skynameo1 >>& /dev/null
				    rm -fr $skynameo2 >>& /dev/null
				    echo $skynameo1 >> $tempdir/z$name.datbb
				    echo $skynameo2 >> $tempdir/z$name.datbb2
				    set maxval = 65000
				# DURING FIRST PASS THE BACKGROUND IS TAKEN FROM THE PRE-REDUCTION WHICH IS NOT CORRECTED FOR LINEARITY OR FLAT FIELDING, MAKE FIRST ORDER CORRECTION:
				    set maxval = `gethead -u $skyname BAVE BSIG | awk '{if($0 ~ /___/ ){print 65000}else{print $1+3*$2 }}'`
				    echo "setting maxval = $maxval"
#				    $fsiraf/x_mimsurfit -i "$skyname" -m "$skyname.pl.fits" -o "$skynameo1" -x "$skynameo2" -c 0 -r 0 -p -1000 -q $maxval -l 5 -h 5 -n 0 -g 0 -v 1 -t 3 -s 3 3 -1 -w 0 
#				    sleep 0.25
				    set cmd2 = "$cmd2 ; $fsiraf/x_mimsurfit -i "$skyname" -m "$skyname.pl.fits" -o "$skynameo1" -x "$skynameo2" -c 0 -r 0 -p -1000 -q $maxval -l 5 -h 5 -n 0 -g 0 -v 1 -t 3 -s 3 3 -1 -w 0  "
				end
#				echo waiting
#				wait
#				echo continuing
				sedi 's|imcombine.input =|imcombine.input = \"\@'$tempdir''z$name'.datbb\"|' $tempdir/z$name.para
				sedi 's|imcombine.output =|imcombine.output = \"'$pwd/$name'.sky1.fits\"|' $tempdir/z$name.para
				sedi 's|imcombine.expmasks = \"\"|imcombine.expmasks = \"'$pwd/$name.sky.exp.pl.fits'[type=mask]\"|' $tempdir/z$name.para

				sedi 's|imcombine.input =|imcombine.input = \"\@'$tempdir''z$name'.datbb2\"|' $tempdir/z$name.para2
				sedi 's|imcombine.output =|imcombine.output = \"'$pwd/$name'.sky2.fits\"|' $tempdir/z$name.para2
				set cmd = "$cmd ; $cmd2 ; echo waiting ; wait ; echo continuing ; rm -fr $pwd/$name.sky.exp.pl.fits >>& /dev/null ; $pwd/$name.sky.pl.fits >>& /dev/null ; images imcombine \@$tempdir/z$name.para ; images imcombine \@$tempdir/z$name.para2 "
				cp $fsiraf/imexpr.par $tempdir/z$name.paraaa
#				sedi 's|imexpr.a =|imexpr.a = \"'$pwd/$name'.sky.cp.fits\"|' $tempdir/z$name.paraaa
#				sedi 's|imexpr.b =|imexpr.b = \"'$pwd/$name:t:r/$skynameref:t'\"|' $tempdir/z$name.paraaa
				sedi 's|imexpr.a =|imexpr.a = \"'$pwd/$name'.sky1.fits\"|' $tempdir/z$name.paraaa
				sedi 's|imexpr.b =|imexpr.b = \"'$pwd/$name'.sky2.fits\"|' $tempdir/z$name.paraaa
				sedi 's|imexpr.output =|imexpr.output = \"'$pwd/$name'.sky.fits\"|' $tempdir/z$name.paraaa
				sedi 's|imexpr.expr =|imexpr.expr = \"( a+b )\"|' $tempdir/z$name.paraaa
#				set cmd = "$cmd ; mv $pwd/$name.sky.fits $pwd/$name.sky.cp.fits ; images imexpr \@$tempdir/z$name.paraaa  "			    
				set cmd = "$cmd ; images imexpr \@$tempdir/z$name.paraaa  "			    
			  #  REMOVE FOLDER WHEN DONE.    
				if ( 0 ) then
				    set cmd = "$cmd ; rm -fr $pwd/$name:t:r "
				endif
			    else
#				$fsiraf/x_skycombine -i "$tempdir/z$name.datb" -m ".pl.fits" -o "$pwd/$name.sky.fits" -b "$pwd/$name.sky.exp.pl.fits" -p -1000 -q BAVE -l 5 -h 5 -v 1 -s 3 3 -1 -z "$tempdir/z$name.data" -y $BADBITS -n 0 -x $bflag
				set cmd = "$cmd ; $fsiraf/x_skycombine -i "$tempdir/z$name.datb" -m ".pl.fits" -o "$pwd/$name.sky.fits" -b "$pwd/$name.sky.exp.pl.fits" -p -1000 -q BAVE -l 5 -h 5 -v 1 -s 3 3 -1 -z "$tempdir/z$name.data" -y $BADBITS -n 0 -x $bflag "
			    endif
			else
			    sedi 's|imcombine.input =|imcombine.input = \"\@'$tempdir''z$name'.datb\"|' $tempdir/z$name.para
			    sedi 's|imcombine.output =|imcombine.output = \"'$pwd/$name'.sky.fits\"|' $tempdir/z$name.para
			    sedi 's|imcombine.expmasks = \"\"|imcombine.expmasks = \"'$pwd/$name.sky.exp.pl.fits'[type=mask]\"|' $tempdir/z$name.para
			    set cmd = "$cmd ; $cmd2 ; wait ; rm -fr $pwd/$name.sky.exp.pl.fits $pwd/$name.sky.pl.fits >>& /dev/null ; images imcombine \@$tempdir/z$name.para"
			endif
		    else
			@ xstep = $xaxis / $xgrid
			@ ystep = $yaxis / $ygrid
			@ cid = 0
			@ y = 0
			cd $skys
			while ( $y != $ygrid )
			    @ x = 0
			    while ( $x != $xgrid )
				echo "x = $x"
#				@ cid = $cid + 1
				set cid = `awk 'BEGIN {printf "%03d",'$cid'+1}' `
				echo $cid
				@ x1 = $x * $xstep + 1
				@ x2 = $x * $xstep + $xstep
				@ y1 = $y * $ystep + 1
				@ y2 = $y * $ystep + $ystep
				echo $xaxis $xgrid $xstep $x $x1 $x2 
				echo $yaxis $ygrid $ystep $y $y1 $y2 
				awk '{print $1"['$x1':'$x2','$y1':'$y2']"}' $tempdir/z$name.dat > $tempdir/z$name.$cid.datb  # IMAGE NAMES
				cp $tempdir/z$name.para $tempdir/z$name.$cid.para
				sedi 's|imcombine.input =|imcombine.input = \"\@'$tempdir''z$name.$cid'.datb\"|' $tempdir/z$name.$cid.para
				sedi 's|imcombine.output =|imcombine.output = \"'$pwd/$name.$cid'.sky.fits\"|' $tempdir/z$name.$cid.para
				sedi 's|imcombine.expmasks = \"\"|imcombine.expmasks = \"'$pwd/$name.$cid.sky.exp.pl.fits'[type=mask]\"|' $tempdir/z$name.$cid.para
				rm -f $tempdir/zz$name.$cid.pl.fits $pwd/$name.$cid.sky.exp.pl.fits $pwd/$name.$cid.sky.fits >>& /dev/null
				images imcombine \@$tempdir/z$name.$cid.para &
				@ x++
			    end
			    echo "y = $y"
			    @ y++
			end
			wait
			cd $pwd
			rm -f $tempdir/zz$name.pl.fits $name.sky.exp.pl.fits $name.sky.pl.fits $name.sky.fits >>& /dev/null
			# STITCH SUBRASTERS TOGETHER
			cp $fsiraf/imcombine.par $tempdir/z$name.tile.para
			sedi 's|imcombine.input =|imcombine.input = \"'$pwd/$name'.*.sky.fits\"|' $tempdir/z$name.tile.para
			sedi 's|imcombine.output =|imcombine.output = \"'$pwd/$name'.sky.fits\"|' $tempdir/z$name.tile.para
			sedi 's|imcombine.combine =|imcombine.combine = \"sum\"|' $tempdir/z$name.tile.para
			sedi 's|imcombine.offsets = \"none\"|imcombine.offsets = \"grid '$xgrid' '$xstep' '$ygrid' '$ystep'\"|' $tempdir/z$name.tile.para
#			images imcombine \@$tempdir/z$name.tile.para ; rm -fr $pwd/$name.*.sky.fits &
#			set cmd = "$cmd ; images imcombine \@$tempdir/z$name.tile.para ; rm -fr $pwd/$name.*.sky.fits  "
			set cmd = "$cmd ; images imcombine \@$tempdir/z$name.tile.para  "
			cp $fsiraf/imcombine.par $tempdir/z$name.tile2.para
			sedi 's|imcombine.input =|imcombine.input = \"'$pwd/$name'.*.sky.exp.pl.fits[1]\"|' $tempdir/z$name.tile2.para
			sedi 's|imcombine.output =|imcombine.output = \"'$pwd/$name'.sky.exp.pl.fits\"|' $tempdir/z$name.tile2.para
			sedi 's|imcombine.combine =|imcombine.combine = \"sum\"|' $tempdir/z$name.tile2.para
			sedi 's|imcombine.offsets = \"none\"|imcombine.offsets = \"grid '$xgrid' '$xstep' '$ygrid' '$ystep'\"|' $tempdir/z$name.tile2.para
#			images imcombine \@$tempdir/z$name.tile2.para ; rm -fr $pwd/$name.*.sky.exp.pl.fits &
			set cmd = "$cmd ; images imcombine \@$tempdir/z$name.tile2.para ; rm -fr $pwd/$name.*.sky.exp.pl.fits  "
			wait
		    endif
#		    cd $pwd
		    set cmd = "$cmd ; cd $pwd"
#exit 0


# SMOOTH SKY IMAGE
		    set smooth = 0
		    if ( $smooth == 1) then
			cp $fsiraf/median.par $tempdir/med$name.par
			sedi 's|median.input =|median.input = \"'${name}'\"|' $tempdir/med$name.par
			sedi 's|median.output =|median.output = \"'${name}'\"|' $tempdir/med$name.par
			sedi 's|median.xwindow = |median.xwindow = 3|' $tempdir/med$name.par
			sedi 's|median.ywindow = |median.ywindow = 3|' $tempdir/med$name.par
			sedi 's|median.zloreject = INDEF|median.zloreject = 1  |' $tempdir/med$name.par
			sedi 's|median.zhireject = INDEF|median.zhireject = 60000  |' $tempdir/med$name.par
		    endif

# COMBINE SKY AND TARGET OBJECT MASKS BEFORE FINDING BACKGROUND
		    cp $fsiraf/imexpr.par $tempdir/z$name.parb
		    sedi 's|imexpr.a =|imexpr.a = \"'$name'.pl.fits[1]\"|' $tempdir/z$name.parb
		    sedi 's|imexpr.output =|imexpr.output = \"'$name'.sky.pl.fits[type=mask]\"|' $tempdir/z$name.parb 
#		    sedi 's|imexpr.b =|imexpr.b = \"'$tempdir'/'zz$name'.pl.fits[1]\"|' $tempdir/z$name.parb
#		    sedi 's|imexpr.expr =|imexpr.expr = \"( (b*64)\|a )\"|' $tempdir/z$name.parb
		    if ( $xgrid == 1 && $ygrid == 1 ) then
			sedi 's|imexpr.b =|imexpr.b = \"'$name'.sky.exp.pl.fits[1]\"|' $tempdir/z$name.parb
		    else
			sedi 's|imexpr.b =|imexpr.b = \"'$name'.sky.exp.pl.fits\"|' $tempdir/z$name.parb
		    endif
		    sedi 's|imexpr.expr =|imexpr.expr = \"( (b==0 ? 64 : 0)+a )\"|' $tempdir/z$name.parb
# FIND BACKGROUND IN THE SKY FRAME MASKING OBJECTS IN SKY AND TARGET
		    cp $fsiraf/mimstat.par $tempdir/z$name.pard
		    sedi 's|mimstatistics.images = |mimstatistics.images = \"'$name'.sky.fits\"|' $tempdir/z$name.pard
		    sedi 's|mimstatistics.imasks = |mimstatistics.imasks = \"'$name'.sky.pl.fits[1]\"|' $tempdir/z$name.pard
		    sedi 's|mimstatistics.fields = |mimstatistics.fields = \"npix,mean,midpt,mode,stddev,skew,kurtosis,min,max\"|' $tempdir/z$name.pard
		    sedi 's|mimstatistics.nclip = 0|mimstatistics.nclip = 2|' $tempdir/z$name.pard
		    sedi 's|mimstatistics.lsigma = 3|mimstatistics.lsigma = 2|' $tempdir/z$name.pard
		    sedi 's|mimstatistics.usigma = 3|mimstatistics.usigma = 2|' $tempdir/z$name.pard
		    sedi 's|mimstatistics.lower = INDEF|mimstatistics.lower = -60000|' $tempdir/z$name.pard
		    sedi 's|mimstatistics.upper = INDEF|mimstatistics.upper = 60000|' $tempdir/z$name.pard
#		    sedi 's|mimstatistics.format = no|mimstatistics.format = yes|' $tempdir/z$name.pard
		    sedi 's|.pl.fits|.sky.pl.fits|' $tempdir/z$name.parc

		    set cmd = "$cmd ; images imexpr \@$tempdir/z$name.parb"

# INTERPOLATE SKY IMAGE
		    if ( $interpolation == 1 ) then
			cp $fsiraf/imexpr.par $tempdir/z$name.parbb
			sedi 's|imexpr.a =|imexpr.a = \"'$name'.sky.pl.fits[1]\"|' $tempdir/z$name.parbb
			sedi 's|imexpr.output =|imexpr.output = \"'$name'.skyo.pl.fits[type=mask]\"|' $tempdir/z$name.parbb
# CHANGE BACK,   DONT INTERPOLATE OVER THE IMAGE BORDER FOR NOW
			sedi 's|imexpr.expr =|imexpr.expr = \"( ( a \& 65 ) ? 1 : 0  )\"|' $tempdir/z$name.parbb
#			sedi 's|imexpr.expr =|imexpr.expr = \"( ( a \& 64 ) ? 1 : 0  )\"|' $tempdir/z$name.parbb

			cp $fsiraf/detect.par $tempdir/zdet_$name.par
			sedi 's|detect.images = \"\"|detect.images = \"'{$pwd}/{$name}'.sky.fits\"|' $tempdir/zdet_$name.par
			sedi 's|detect.objmasks = \"\"|detect.objmasks = \"'{$pwd}/{$name}'.skyint.pl.fits[type=mask]\"|' $tempdir/zdet_$name.par
			sedi 's|detect.masks = \"\"|detect.masks = \"'{$pwd}/{$name}'.skyo.pl.fits[1]\"|' $tempdir/zdet_$name.par
			sedi 's|detect.skytype = \"fit\"|detect.skytype = \"block\"|' $tempdir/zdet_$name.par
#			sedi 's|detect.skys = \"\"|detect.skys = \"0\"|' $tempdir/zdet_$name.par
			sedi 's|detect.fitxorder = 2|detect.fitxorder = 9|' $tempdir/zdet_$name.par
			sedi 's|detect.fityorder = 2|detect.fityorder = 9|' $tempdir/zdet_$name.par
#			sedi 's|detect.convolve = \"bilinear 5 5\"|detect.convolve = \"block 3 3\"|' $tempdir/zdet_$name.par
			sedi 's|detect.convolve = \"bilinear 5 5\"|detect.convolve = \"gauss 3 3 1 1\"|' $tempdir/zdet_$name.par
			sedi 's|detect.ngrow = 2|detect.ngrow = 10|' $tempdir/zdet_$name.par
			sedi 's|detect.agrow = 2.|detect.agrow = 1.0|' $tempdir/zdet_$name.par
		    # DETECTION PARAMETERS
			sedi 's|detect.minpix = 6|detect.minpix =10|' $tempdir/zdet_$name.par
			sedi 's|detect.hsigma = 1.5|detect.hsigma = '$HISIG'|' $tempdir/zdet_$name.par
#			sedi 's|detect.bpval = INDEF|detect.bpval = 0|' $tempdir/zdet_$name.par
			sedi 's|detect.lsigma = 10.|detect.lsigma = 5.|' $tempdir/zdet_$name.par
#			sedi 's|detect.ldetect = no|detect.ldetect = yes|' $tempdir/zdet_$name.par
#			sedi 's|detect.hdetect = yes|detect.hdetect = no|' $tempdir/zdet_$name.par

			set xminval = 0
			set xmaxval = 1e8
			set xlosigrej = 10000
			set xhisigrej = 10000 # If too low cheackerboarding may appear where there are steep gradients.  Dont mask sinle pixels, they may just have higher dark counts and need to be subtracted from the data so dont interpolate them.   
			set xniter = 0
			set xngrow = 0
			set xvflag = 1
			set xtype = 2 # 0 | 1 | 2
			set xscols = 0
			set xsrows = 0
			set xwavelet = 0
	
			set cmd = "$cmd ; images imexpr \@$tempdir/z$name.parbb ; nproto detect \@$tempdir/zdet_$name.par ; mv {$pwd}/{$name}.sky.fits {$pwd}/{$name}.skyorg.fits ; $fsiraf/x_mimsurfit -i "{$pwd}/{$name}.skyorg.fits" -m "{$pwd}/${name}.skyint.pl.fits" -o \\!"{$pwd}/{$name}.sky.fits" -c $xscols -r $xsrows -p $xminval -q $xmaxval -l $xlosigrej -h $xhisigrej -n $xniter -g $xngrow -v $xvflag  -t $xtype -w $xwavelet"	
		    endif

		    if ( $smooth == 1 ) then
			set cmd = "$cmd ; images median \@$tempdir/med$name.par"
		    endif

		    set cmd = "$cmd ; cd $pwd ; proto mimstatistics \@$tempdir/z$name.pard | awk -f $fsbin/transpose.awk > $name.sky.fits.stats ; sethead $name.sky.fits @$name.sky.fits.stats"
################################################################################
		else
		    if ( tryflag == 0 ) then
			printf "\n\n       NO SKY IMAGES FOUND: GOING TO LOOK AGAIN  \n"
			sleep 2
			set tryflag = 1
			set REDO = 1
			goto start
		    else
			printf "         NO SKY IMAGES FOUND: SETTING BFLAG TO OFF \n\n"
			set bflag = 0
			set bflag = 8
			set CSCALE = NO
			set tryflag = 0
			set REDO = 0
		    endif
		    sedi 's|mimstatistics.imasks =|mimstatistics.imasks = \"'$name'.pl.fits[1]\"|' $tempdir/z$name.parc
		endif # NUM OF SKYS > 0
	    endif # .sky.fits NAME FILE EXISTS
imstat:
	    printf "\n  FINDING IMAGE STATISTICS FOR:  $name  \n"
	    echo $cmd
	    set cmd = "$cmd ; proto mimstatistics \@$tempdir/z$name.parc | awk -f $fsbin/transpose.awk > $name.stats ; sethead $name @$name.stats"
#	endif

	if ( xgrid == 0 ) then
	    set numbkjobs = `ps -a | grep -v -E 'x_sys|x_tv' | grep -E 'x_|sed|fsr' | wc -l`
	    while ( $numbkjobs > $BKJOBS )
	        set numbkjobs = `ps -a | grep -v -E 'x_sys|x_tv' | grep -E 'x_|sed|fsr' | wc -l`
	        printf "\rDetect waiting: $numbkjobs"
	        sleep 5
	    end
	endif

	eval $cmd &

    end # FOR EACH CHIP

    wait

# TRY A SECOND TIME, CHECK THAT THE $BTYPE KEYWORD WAS CREATED
    echo tryflag = $tryflag
    if ( $tryflag == 0 ) then
	set tryflag = 1
	goto startloop
    else
	set tryflag = 0
    endif
    printf "\n  Waiting for image statistics to finish  \n"
    wait # FOR ALL CHIP STATISTICS TO FINISH
#################################################
    if ( $myverbose > 0 ) then
	if ( $bflag != 0 ) then
	    echo ""
	    echo "SKY STATS: ${name2:t}_c?.fits.sky.fits"
	    paste ${name2:t}_c?.fits.sky.fits.stats
	endif
	echo ""
	echo "TARGET STATS: ${name2:t}_c?.fits"
	paste ${name2:t}_c?.fits.stats
	echo ""
    endif
#################################################
# SCALE ALL THE BACKGROUNDS USING THE MINIMUM SCALE OF ALL OF THEM TO ELIMINATE CASES IF THE TARGET FRAME HAS HIGH COUNTS. 

    echo "FINDING AVERAGE TARGET BACKGROUND OF ALL CHIPS"
    gethead -f `echo $name | sed 's/c[1-4]/c?/' ` $BTYPE > $tempdir/z$name.zobj.txt
    if ( 0 ) then
# AVERAGE
	set aveobj = `cat $tempdir/z$name.zobj.txt | awk '{a=(a*(NR-1)+$1)/NR}END{print a}'`
# MINIMUM
    else
	set aveobj = `cat $tempdir/z$name.zobj.txt | awk 'BEGIN{a=1e33}{a=$1<a?$1:a}END{print a}'`
    endif
    set avesky = $aveobj
    set scale = "1"
    set diff = "0"
    if ( $CSCALE == "YES" ) then
	if ( `ls ${name}.sky.fits | wc -l` != 0 ) then
	    echo "FINDING AVERAGE SKY BACKGROUND OF ALL CHIPS"
	    gethead -f `echo ${name}.sky.fits | sed 's/c[1-4]/c?/' ` mode > $tempdir/z$name.zsky.txt
	    set avesky = `cat $tempdir/z$name.zsky.txt | awk '{a=(a*(NR-1)+$1)/NR}END{print a}'`
#	    set scale = `paste $tempdir/z$name.zobj.txt $tempdir/z$name.zsky.txt | awk '{print $1/$2}' | sort -n | head -n 1`
#	    set diff = `paste $tempdir/z$name.zobj.txt $tempdir/z$name.zsky.txt | awk '{print $1-$2}' | sort -n | head -n 1`
	    set scale = `paste $tempdir/z$name.zobj.txt $tempdir/z$name.zsky.txt | awk '{a=(a*(NR-1)+$1/$2)/NR}END{print a}' | sort -n | head -n 1`
	    set diff = `paste $tempdir/z$name.zobj.txt $tempdir/z$name.zsky.txt | awk '{a=(a*(NR-1)+$1-$2)/NR}END{print a}' | sort -n | head -n 1`

	endif
    endif
################################################################################
	echo ""
	echo "AVEOBJ  AVESKY  SCALE  DIFF"
	echo $aveobj $avesky $scale $diff
	if ( $smode == "SCALE" ) then
	    echo "Scaling Background by SCALE"
	else
	    echo "Off-setting Background by DIFF"
	endif
	echo ""
################################################################################

    wait
subtract:
    foreach ch ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
	set name = ${name2:t}_c$ch.fits
	if ( ! -e $name ) then
	    echo "$name not processed, skipping..."
	    continue
	else if ( -e $name.sub.fits ) then
	    if ( $tryflag == 0 ) then
		printf "   $name.sub.fits already created, skipping...\n"
	    else
		printf "   $name.sub.fits created successfully   \n"
	    endif
	    if ( $ch == 4 ) then
		goto fit
	    else
		continue
	    endif
	else
	    cp $fsiraf/imexpr.par $tempdir/z$name.pare
	    sedi 's|imexpr.a =|imexpr.a = \"'$name'\"|' $tempdir/z$name.pare 
	    sedi 's|imexpr.output =|imexpr.output = \"'$name'.sub.fits\"|' $tempdir/z$name.pare
	    if ( -e $name.sky.fits ) then
		sedi 's|imexpr.b =|imexpr.b = \"'$name'.sky.fits\"|' $tempdir/z$name.pare 
	    else if ( $bflag == 0 ) then
#		cp $name $name.sub.fits
#		if ( $ch == 4 ) then
#		    goto fit
#		else
#		    continue
#		endif
	    else
		echo Could not find $name.sky.fits, something went wrong... exiting.
		exit 1
	    endif 

	    if ( $CSCALE == "YES" ) then
		if (  -e $name.sky.fits ) then
		    if ( $smode == "SCALE" ) then
			echo "a-b(<a.$BTYPE/b.$BTYPE>)"
			sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b*('$scale') )\"|' $tempdir/z$name.pare
			set a = `gethead $name $BTYPE`
			set b = `gethead $name.sky.fits $BTYPE`
			set c = `gethead $name.sky.fits SATURATE`
			set NEWSKY = `echo "$a - $b * $scale" | bc -l`
			set SATURATE = `echo "$c - $b * $scale" | bc -l`
		    else
			echo "a-b-(<a.$BTYPE-b.$BTYPE>)"
			sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b-('$diff') )\"|' $tempdir/z$name.pare
			set a = `gethead $name $BTYPE`
			set b = `gethead $name.sky.fits $BTYPE`
			set c = `gethead $name.sky.fits SATURATE`
			set NEWSKY = `echo "$a - $b - $diff" | bc -l`
			set SATURATE = `echo "$c - $b - $diff" | bc -l`
		    endif
		else
		    echo "a-<a.$BTYPE>"
		    sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-('$aveobj') )\"|' $tempdir/z$name.pare
		    set NEWSKY = 0
		    set a = `gethead $name $BTYPE`
		    set c = `gethead $name SATURATE`
		    set SATURATE = `echo "$c - $a" | bc -l`
		endif
	    else
		if (  $bflag != 0 && -e $name.sky.fits ) then
		    if ( $smode == "SCALE" ) then
#			echo "a-b(a.$BTYPE/b.$BTYPE)"
#			sedi 's|imexpr.expr =|imexpr.expr = \"(a-b*(a.$BTYPE\/b.$BTYPE) )\"|' $tempdir/z$name.pare
			if ( 1 ) then
			    echo "a-b(a.$BTYPE/b.$BTYPE)+${fudge}*(a.mean-a.mode)"
			    sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b*(a.'$BTYPE'\/b.'$BTYPE')+'$fudge'*(a.mean-a.mode) )\"|' $tempdir/z$name.pare
			    set a = `gethead $name $BTYPE`
			else
#			    echo "a-b($aveobj/b.$BTYPE)"
#			    sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b*('$aveobj'\/b.'$BTYPE')+'$fudge'*(a.mean-a.mode) )\"|' $tempdir/z$name.pare
#			    set a = $aveobj
			    echo "a-b((3*a.MIDPT-2*a.MEAN)/b.$BTYPE)"
			    sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b*((3*a.MIDPT-2*a.MEAN)\/b.'$BTYPE')+'$fudge'*(a.mean-a.mode) )\"|' $tempdir/z$name.pare
			    set a = $aveobj
			endif
			set c = `gethead $name.sky.fits SATURATE`
			set SATURATE = `echo "$c - $a" | bc -l`
			set NEWSKY = 0
		    else
#			echo "a-b-(a.$BTYPE-b.$BTYPE)"
#			sedi 's|imexpr.expr =|imexpr.expr = \"(a-b-(a.$BTYPE-b.$BTYPE) )\"|' $tempdir/z$name.pare
			if ( 1 ) then
			    echo "a-b-(a.$BTYPE-b.$BTYPE)+${fudge}*(a.mean-a.mode)"
			    sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b-(a.'$BTYPE'-b.'$BTYPE')+'$fudge'*(a.mean-a.mode) )\"|' $tempdir/z$name.pare
			    set a = `gethead $name $BTYPE`
			else
#			    echo "a-b-($aveobj-b.$BTYPE)"
#			    sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b-('$aveobj'-b.'$BTYPE')+'$fudge'*(a.mean-a.mode) )\"|' $tempdir/z$name.pare
#			    set a = $aveobj
			    echo "a-b-((3*a.MIDPT-2*a.MEAN)-b.$BTYPE)"
			    sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-b-((3*a.MIDPT-2*a.MEAN)-b.'$BTYPE')+'$fudge'*(a.mean-a.mode) )\"|' $tempdir/z$name.pare
			    set a = $aveobj

			endif
			set c = `gethead $name.sky.fits SATURATE`
			set SATURATE = `echo "$c - $a" | bc -l`
			set NEWSKY = 0
		    endif
		else
		    if ( 0 ) then
			echo "a-a.$BTYPE"
			sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-(a.'$BTYPE') )\"|' $tempdir/z$name.pare
			set a = `gethead $name $BTYPE`
		    else
			echo "a-$aveobj"
			sedi 's|imexpr.expr =|imexpr.expr = \"(a==0?0:a-('$aveobj') )\"|' $tempdir/z$name.pare
			set a = $aveobj
		    endif
		    set c = `gethead $name SATURATE`
		    set SATURATE = `echo "scale=2; $c - $a" | bc -l`
		    set NEWSKY = 0
		endif
	    endif
################################################################################
	    if ( xgrid == 0 ) then
		set numbkjobs = `ps -a | grep -v -E 'x_sys|x_tv' | grep -E 'x_|sed|fsr' | wc -l`
		while ( $numbkjobs > $BKJOBS )
		    set numbkjobs = `ps -a | grep -v -E 'x_sys|x_tv' | grep -E 'x_|sed|fsr' | wc -l`
		    printf "\rwaiting: $numbkjobs"
		    sleep 5
		end
	    endif
awk '{print}' <<EOF > $tempdir/${name}_$t0.csh
#!/bin/csh
cd `pwd`
# SUBTRACT SKY
cp $fsiraf/mimstat.par $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.images =|mimstatistics.images = \"'$name'.sub.fits\"|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.imasks = |mimstatistics.imasks = \"'$name'.pl.fits[1]\"|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.fields =|mimstatistics.fields = \"mode,stddev\"|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.nclip = 0|mimstatistics.nclip = 2|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.lsigma = 3|mimstatistics.lsigma = 2|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.usigma = 3|mimstatistics.usigma = 2|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.lower = INDEF|mimstatistics.lower = -60000|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.upper = INDEF|mimstatistics.upper = 60000|' $tempdir/$name.3cccc.par

	    echo subtracting sky frame
	    $images imexpr \@$tempdir/z$name.pare

	    if ( ! -e $name.sub.fits ) then
		echo Something went wrong... Exiting
		exit 1
	    endif
	    set AVERAGE = \`$proto mimstatistics \@$tempdir/$name.3cccc.par\`
	    $sethead $name.sub.fits NEWSKY\=\$AVERAGE[1]
	    $sethead $name.sub.fits STDDEV2\=\$AVERAGE[2]
	    $sethead $name.sub.fits SATURATE\=$SATURATE

	    echo done subtracting sky
#   FIT BOTH COLUMN AND/OR ROW
	    if ( -e $name.sky.pl.fits ) then
	        set bpmfit = $name.sky.pl.fits
	    else if ( -e $name.2.pl.fits ) then
	        set bpmfit = $name.2.pl.fits
	    else if ( -e $name.pl.fits ) then
	        set bpmfit = $name.pl.fits
	    else
	        cp $bpmloc/bp_${ch}.pl.fits $name.pl.fits
	        set bpmfit = $name.pl.fits
	    endif

	    echo Using mask: \$bpmfit
#	    cp -n \$bpmfit $name.sky.pl.fits
#	    set bpmfit = $name.sky.pl.fits

	    if ( $wt == 0 ) then
		set FWHM = ( 1 1 0 )
		$sethead $name.sub.fits FWHM_AVE\=\$FWHM[1]
		$sethead $name.sub.fits FWHM_NUM\=\$FWHM[3]
		$sethead $name FWHM_AVE\=\$FWHM[1]
		$sethead $name FWHM_NUM\=\$FWHM[3]
	    else if ( $wt == 1 ) then
		set FWHM = \`$gethead -u $name.sub.fits FWHM_AVE\`
		if ( \$FWHM != "___"  ) then
		    echo FWHM already found: \$FWHM
		else
		    cp $fsiraf/imexpr.par $tempdir/zzz$name.parb
		    $sedi 's|imexpr.a =|imexpr.a = \"'\$bpmfit'[1]\"|' $tempdir/zzz$name.parb
		    $sedi 's|imexpr.output =|imexpr.output = \"'\$bpmfit'.1.fits\"|' $tempdir/zzz$name.parb
		    $sedi 's|imexpr.expr =|imexpr.expr = \"( a==0 ? 1 : 0 )\"|' $tempdir/zzz$name.parb
		    $sedi 's|imexpr.outtype = \"real\"|imexpr.outtype = \"int\"|' $tempdir/zzz$name.parb

		    cp $fsiraf/imexpr.par $tempdir/zzzz$name.parb
		    $sedi 's|imexpr.a =|imexpr.a = \"'\$bpmfit'[1]\"|' $tempdir/zzzz$name.parb
		    $sedi 's|imexpr.output =|imexpr.output = \"'\$bpmfit'.2.fits\"|' $tempdir/zzzz$name.parb
		    $sedi 's|imexpr.expr =|imexpr.expr = \"( a==0 ? 0 : 1 )\"|' $tempdir/zzzz$name.parb
		    $sedi 's|imexpr.outtype = \"real\"|imexpr.outtype = \"int\"|' $tempdir/zzzz$name.parb

		    echo Running \`$sex -v\` 
		    $images imexpr \@$tempdir/zzz$name.parb
		    $images imexpr \@$tempdir/zzzz$name.parb
		    $sex $name.sub.fits -c $fsast/sex.config -PARAMETERS_NAME $fsast/sex.param -FILTER_NAME $fsast/default.conv -STARNNW_NAME $fsast/default.nnw -CATALOG_TYPE ASCII -CATALOG_NAME $name.sub.sex1 -VERBOSE_TYPE QUIET -WEIGHT_TYPE MAP_WEIGHT -WEIGHT_IMAGE \$bpmfit.1.fits -CHECKIMAGE_TYPE NONE -CHECKIMAGE_NAME $name.check.fits -BACK_SIZE 32 -BACK_FILTERSIZE 11 -FLAG_IMAGE \$bpmfit.2.fits
		    awk '{if( \$5 > 1 && \$6 > 1 && \$18 < 1 ){print}}' $name.sub.sex1 > $name.sub.sex

		    set crit = 13
		    set ellip = 0.4
		    set stell = 0
cut:
		    set FWHM = \`awk 'BEGIN{ave=0;sig=0;i=0}{if( \$4<0.2 && \$4>0.002 && \$8<'\$ellip' && \$10 <= 15 && \$12>'\$stell' && \$12<1 && \$'\$crit'*0.16>0.25 && \$'\$crit'*0.16<2 ){ave=ave+(\$'\$crit'*0.16);sig=sig+(\$'\$crit'*0.16)^2;i++}}END{if(i>3){print ave/i,sqrt(sqrt((i*sig-ave^2)^2))/i,i}else{print 1,1,0}}' $name.sub.sex \`

		    if ( \$FWHM[3] == 0 && \$stell != 0  ) then
			printf "No stars found, setting stellarity index to zero and trying again\n"
			set stell = 0 
			goto cut
		    endif
		    echo 1stPASS \$FWHM

# FIND MEDIANS
		    if ( 0 ) then
			set FWHMMED = \`awk '{if( \$4<0.2 && \$4>0.002 && \$8<'\$ellip' && \$10 <= 15 && \$12>'\$stell' && \$12<1 && \$'\$crit'*0.16>0.25 && \$'\$crit'*0.16<2 ){print \$'\$crit'*0.16 } }' $name.sub.sex \`
			set n2 = \`awk 'BEGIN{print int('\$FWHM[3]'/2) }'\`
			set FWHM[1] = \$FWHMMED[\$n2]
			echo 2ndPASS \$FWHM

			if ( \$n2 > 10 ) then
			    echo Finding median ellipticity
			    set ELLMED = \`awk '{if( \$4<0.2 && \$4>0.002 && \$8<'\$ellip' && \$10 <= 15 && \$12>'\$stell' && \$12<1 && \$'\$crit'*0.16>0.25 && \$'\$crit'*0.16<2 ){print \$8 } }' $name.sub.sex \`
			    set ellip = \$ELLMED[\$n2]
			endif
		    endif

		    echo ELLIP \$ellip
		    set sigclip = 2
		    set FWHM = \`awk 'BEGIN{ave=0;sig=0;i=0}{if( \$4<0.2 && \$4>0.002 && \$8<'\$ellip' && \$10 <= 15 && \$12>'\$stell' && \$12<1 && \$'\$crit'*0.16>'\$FWHM[1]'-2.0*'\$sigclip'*'\$FWHM[2]' && \$'\$crit'*0.16<'\$FWHM[1]'+1.0*'\$sigclip'*'\$FWHM[2]'){ave=ave+(\$'\$crit'*0.16);sig=sig+(\$'\$crit'*0.16)^2;i++}}END{if(i>3){print ave/i,sqrt(sqrt((i*sig-ave^2)^2))/i,i}else{print 1,1,0} }' $name.sub.sex \`
		    echo final \$FWHM

		    printf "Average FWHM = %5.2f +- %4.2f arcsec from %5d measurements.\n" \$FWHM[1]  \$FWHM[2]  \$FWHM[3]
		    $sethead $name.sub.fits FWHM_AVE\=\$FWHM[1]
		    $sethead $name.sub.fits FWHM_NUM\=\$FWHM[3]
		    $sethead $name FWHM_AVE\=\$FWHM[1]
		    $sethead $name FWHM_NUM\=\$FWHM[3]
		endif
	    endif
wait
exit 0
EOF
	    chmod 777 $tempdir/${name}_$t0.csh
	    $tempdir/${name}_$t0.csh &
#	    if ( $status != 0 ) then
#		goto beginning
#	    endif
	endif
    end

    printf "\nWaiting for initial SKY-SUBTRACTION TO FINISH \n"
    wait
    printf "\nInitial SKY-SUBTRACTION FINISHED \n"



    # CHECK THAT .SUB FILES WERE CREATED 
    if ( 1 && $tryflag == 0 ) then
	set tryflag = 1
	goto subtract
    endif
################################################################################
fit:
    printf "\nStarting higher order SKY CORRECTIONS.  \n"
    rm -f ${name2:t}_mef.fits >>& /dev/null
    rm -f ${name2:t}_mef.weight.fits >>& /dev/null
    rm -f ${name2:t}*b1*.fits >>& /dev/null
    rm -f ${name2:t}*w1*.fits >>& /dev/null
    ls $name2*_c?.fits > $tempdir/$name2:t.txt
    set filter = `gethead $name filter`
    if ( 1 || $srows > 0 || $scols > 0 || $srows < 0 || $scols < 0 ) then
	set niter = 0
	set ngrow = 0
	if ( $bflag == 9 || $bflag == 8 || $bflag == 7 ) then
	    set maxval = 1000
	    set minval = -1000
	    if ( $filter == J || $filter == J1 || $filter == J2 || $filter == J3 || $filter == NB-1.18 ) then
		set dlim = 0.05
	    else if ( $filter == H || $filter == Hs || $filter == Hl ) then
		set dlim = 0.05
	    else if ( $filter == Ks || $filter == NB-2.09 ) then
		set dlim = 0.015
		set ngrow = 1
	    else
		echo Filter $filter not recognized using defaults.    
		set dlim = 0.05
	    endif
	else
	    set dlim = 0.9
	    set maxval = 1000
	    set minval = -1000
	endif
# BE STRICTER WITH J AND H SINCE OBJECTS HAVE DIFFUSE BACKGROUND

	cat $tempdir/$name2:t.txt


    # I DID NOT INTERPOLATE SO MASK HERE BECAUSE THE SKY SUBTRACTION IS WRONG.  
	set vflag = 13
    # I INTERPOLATED THE BACKGROUND, SO DONT MASK HERE IN THE FINAL IMAGE
	if ( $interpolation == 1 ) then
	    set vflag = `awk 'BEGIN{print '$vflag' + 16}'`
	endif

	if ( $IOBJMASK == YES ) then
	    set vflag = `awk 'BEGIN{print '$vflag'+32 }'`
	endif

#	if ( $DEBUG == 'yes' ) then
	if ( 1 ) then
	    set vflag = `awk 'BEGIN{print '$vflag' + 64}'`
	endif

#	set vflag = 93  # FORCE THIS SINCE I NOW WRITE TO LOG RATHER THAN STDOUT
	# HARDCODED USE OF $name.fits.sky.pl.fits, copy current mask to this name...

	echo $vflag
	foreach name ( `cat $tempdir/$name2:t.txt` ) 
	    if ( ! -e $name.sky.pl.fits ) then
		if ( -e $name.pl.fits ) then
		    cp $name.pl.fits $name.sky.pl.fits
		else
		    cp $bpmloc/bp_${ch}.pl.fits $name.sky.pl.fits
		endif
	    endif
	end
	$fsiraf/x_fsimsurfit -i $tempdir/$name2:t.txt -f "${name2:t}_mef" -c $scols -r $srows -l $OBJT -h $OBJT -n $niter -g $ngrow -v $vflag  -t 1 -w $wavelet -s $surfit[1] $surfit[2] $surfit[3] -d $dlim -a $maxval -b $minval -x $BS -y $BS -p $fsflat
	if ( $status != 0 ) then
	    echo x_fsimsurfit failed... Exiting.
	    exit 1
	endif

# vflag options
# replace_bad_pix weight cancel_fit verbosity
# 0 0 0 0 0 0 0 = 0
# 0 0 0 0 0 0 1 = 1  verbosity
# 0 0 0 0 0 1 0 = 2  cancel line/column fit if too many are masked
# 0 0 0 0 1 0 0 = 4  make weight map
# 0 0 0 1 0 0 0 = 8  replace bad pixels by interpolating
# 0 0 1 0 0 0 0 = 16 dont mask regions with intepolated sky values 
# 0 1 0 0 0 0 0 = 32 mask custom objects.  
# 1 0 0 0 0 0 0 = 64 more verbosity
# BINARY AND
# 0 0 0 1 1 0 1 = 13 <-- replace bad pixels with nearby average --> helps avoid correlation errors when resampling.  
# 0 0 1 1 1 0 1 = 29 <-- dont mask interpolated sky values 
# 1 0 1 1 1 0 1 = 93 <-- dont mask interpolated sky values, more verbosity 

################################################################################

	wait

	printf "\nRunning SExtractor\n"
    # MAKE TARGET MEF SOURCE CATALOG FOR SCAMP
	if ( -e ${name2:t}_mef.cat  ) then
	    echo ${name2:t}_mef.cat already exists!
	else
	    printf "  Creating ${name2:t}_mef.cat   \n"
	    $sex ${name2:t}_mef.fits -c $fsast/sex2.config -PARAMETERS_NAME $fsast/sex2.param -FILTER_NAME $fsast/default.conv -STARNNW_NAME $fsast/default.nnw -CATALOG_TYPE FITS_LDAC -CATALOG_NAME ${name2:t}_mef.cat -VERBOSE_TYPE QUIET -WEIGHT_TYPE MAP_WEIGHT -WEIGHT_IMAGE ${name2:t}_mef.weight.fits -CHECKIMAGE_TYPE NONE -CHECKIMAGE_NAME ${name2:t}_mef.obj.fits -BACK_SIZE 64 -BACK_FILTERSIZE 4 -FLAG_IMAGE ${name2:t}_mef.mask.fits
    # NONE, BACKGROUND, BACKGROUND_RMS, MINIBACKGROUND, MINIBACK_RMS, -BACKGROUND, FILTERED, OBJECTS, -OBJECTS, SEGMENTATION, or APERTURES
	    if ( $status != 0 ) then
		printf " Something went wrong, Starting Over...  \n"
		goto beginning
	    else
		printf " Everything looks OK...  \n"
	    endif
	endif
    endif

exit 0
