#!/bin/csh -f

set offset = 70
set filter = J
set pvsip = /Users/amonson/software/FSRED/DISTORTION/pvsip
#set refdir = /Volumes/Data-3/FourStar/Data/2011_12_02/Region_E
set cal = TARGETS
set refdir = /Volumes/Data-3/FourStar/Data/2012_05_11/NGC6822
#set cal = SKYS

set odir = /Users/amonson/software/FSRED/DISTORTION/2011B/NGC6822/2012_05_11
set ofile = $odir/distort_$filter.cat


if ( ! -e $refdir/$filter/$cal ) then
    echo NO $refdir/$filter/$cal found.  
    exit 1
endif


set i = 0
foreach name ( `ls $refdir/$filter/$cal/lfsr_*.head ` )
    $pvsip -f $name -v 2 > $odir/distort_${filter}.cat.$i
    @ i ++
end

rm -fr $ofile >>& /dev/null
foreach chip ( 1 2 3 4  )

printf "CHIP    = %d \n" $chip >> $ofile

@ i = 2 + ($chip - 1) * $offset 
rm tmp.txt >>& /dev/null
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","CRPIX1  =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt >>& /dev/null
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","CRPIX2  =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i = $i + 3
rm tmp.txt >>& /dev/null
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","CD1_1   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i ++
rm tmp.txt >>& /dev/null
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","CD1_2   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i ++
rm tmp.txt >>& /dev/null
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","CD2_1   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i ++
rm tmp.txt >>& /dev/null
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","CD2_2   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile


printf "A_ORDER = 3  \n" >> $ofile
@ i = $i + 24
rm tmp.txt >>& /dev/null
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","A_0_2   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","A_0_3   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","A_1_1   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","A_1_2   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","A_2_0   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","A_2_1   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","A_3_0   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile


@ i++
printf "B_ORDER = 3  \n" >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","B_0_2   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","B_0_3   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","B_1_1   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","B_1_2   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","B_2_0   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","B_2_1   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile

@ i++
rm tmp.txt
foreach name ( `ls $odir/distort_${filter}.cat.*` )
	awk '{if(NR == '$i') printf "%g\n",$3 }' $name >> tmp.txt
end
awk 'BEGIN{ave=0;sig=0;i=0}{ave=ave+$1 ; sig=sig+$1^2; i++}END{printf "%s %g / %d %g\n","B_3_0   =",ave/i,i,sqrt(sig/i-(ave/i)^2) }' tmp.txt >> $ofile


printf "END     \n" >> $ofile

end


rm tmp.txt
rm $odir/distort_${filter}.cat.*

exit 0
