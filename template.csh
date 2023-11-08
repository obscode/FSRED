#!/bin/csh

# DEFAULT LOCATIONS
set pwd = `pwd`
set config = $pwd/$0:r:t.config
set raw = /Volumes/FourStarSAN/Raw
#set data = /Users/fourstar/Data
set data = /Volumes/FourStarSAN/Red
set redo = 0

# WHICH DATES TO LOOK AT:
set dates = ( 2013_05_21 ) 

# WHICH FILTERS TO LOOK FOR:
set filters = ( J H Ks )
#set filters = ( Ks )

# 1  Initial reduction in each filter
# 2  common astrometry across all filters
# 3  final combine
# 4  copy files to $name/$filter
# 5  remove intermediate files
set array = ( 1 1 1 1 1 )



# 0  Does nothing
# 1  Combine individual macro sets
# 2  Combine all observations from a single night.  
# 3  Combine all observations over multiple nights for a sigle "objname"
set stack = 2
# Minimum number of dithers in a sequence to be considered a group
set minnum = 3
# reject sequences that were aborted ( 0=no | 1=yes ), still must meet minnum criterion.
set abort = 0


# NAME OF INNER FOLDER
set name = "${0:r:t}_DATA"

# LOOK FOR SPECIFIC OBJECT NAMES ( "" for everything )
set objname = ""
# EXPLICITY DISALLOW THESE OBJECT NAMES FROM THE TARGET LIST
set excludetar = "dark|twiflat"

# LOOK FOR SPECIFIC SKY NAMES ( "" for everything )
set skyname = ""
# EXPLICITY DISALLOW THESE OBJECT NAMES FROM THE SKY LIST
set excludesky = "dark|twiflat"

# LOOK FOR SPECIFIC FLAT NAMES ( "null" for archival )
#set flatname = "twiflat"
set flatname = "null"
# EXPLICITY DISALLOW THESE FLAT NAMES FROM THE FLAT LIST
set excludeflat = "null"




# PROCESS THE DATA
################################################
if ( $array[1] ) then
    foreach date ( $dates )
	# MAKE FOLDER FOR DESIRED DATE 
	if ( ! -d $data/$date ) then
	    mkdir -p $data/$date
	endif
	cd $data/$date
	foreach filter ( $filters )
	# MAKE/UPDATE LOG OF OBSERVATIONS
	    if ( ! -e 0_groups.list || $redo == 1 ) then
		fsgroup -a -p $raw/$date
	    endif
	    printf "\nFLATS:\n"
            grep -v -E $excludeflat 0_groups.list | awk '{if($9~"'$flatname'" && $12=="'$filter'" && '$abort'*sub("-","",$17)==0 && $17*1>='$minnum' ){printf "%12s %9s %11s %11s %10s %7s %8s %8s %25s %6s %8s %8s %8s %20s %4s %4s %4s %8s %6s %4s %6s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21}}'
	    set flats = `grep -v -E $excludeflat 0_groups.list | \
		awk '{if($9~"'$flatname'" && $12=="'$filter'" && '$abort'*sub("-","",$17)==0 && $17*1>='$minnum' ) \
		{if(s==0){printf "%s",$10".list";s=1} else {printf ",%s",$10".list" }}}' `
	    printf "\nSKYS:\n"
            grep -v -E $excludesky 0_groups.list | awk '{if($9~"'$skyname'" && $12=="'$filter'" && '$abort'*sub("-","",$17)==0 && $17*1>='$minnum' ){printf "%12s %9s %11s %11s %10s %7s %8s %8s %25s %6s %8s %8s %8s %20s %4s %4s %4s %8s %6s %4s %6s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21}}'
	    set sky = `grep -v -E $excludesky 0_groups.list | \
		awk '{if($9~"'$skyname'" && $12=="'$filter'" && '$abort'*sub("-","",$17)==0 && $17*1>='$minnum' ) \
		{if(s==0){printf "%s",$10".list";s=1} else {printf ",%s",$10".list"}}}' `
	    printf "\nTARGETS:\n"
            grep -v -E $excludetar 0_groups.list | awk '{if($9~"'$objname'" && $12=="'$filter'" && '$abort'*sub("-","",$17)==0 && $17*1>='$minnum' ){printf "%12s %9s %11s %11s %10s %7s %8s %8s %25s %6s %8s %8s %8s %20s %4s %4s %4s %8s %6s %4s %6s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21}}'
	    set target = `grep -v -E $excludetar 0_groups.list | \
		awk '{if($9~"'$objname'" && $12=="'$filter'" && '$abort'*sub("-","",$17)==0 && $17*1>='$minnum' ) \
		{if(s==0){printf "%s",$10".list";s=1} else {printf ",%s",$10".list" }}}' `

	    set skys = $sky
	    # FORCE USE OF TARGETS TO CREATE SKY
	    #set skys = $target
		

	    if ( $#target == 1 && $#skys == 1 ) then
		if ( $#flats == 1 ) then
		    set cmd = `printf "fsred -d %s/%s -p %s/%s -fno %s -s %s -t %s -cwb \n" $name $filter $raw $date $flats $skys $target`
		else
		    set cmd = `printf "fsred -d %s/%s -p %s/%s -s %s -t %s -cwb \n" $name $filter $raw $date $skys $target`
		endif
		
		echo $cmd
		if ( 1 ) then
		    echo -n "Proceed with this? [y|n] " ; set input = $<
		    if ( $input == n ) then
			continue
		    endif
		endif

		rm -fr $name/$filter/tmp >>& /dev/null
		if ( 1 ) then
		  # REDO EVERYTHING
		    rm -fr $name/$filter
		    fsred -d $name/$filter -p $raw/$date -s $skys -t $target -cwb -r -config $config
		else
		  # REDO SECOND PASS TARGETS
#		    rm -fr $name/$filter/SKYS/fs_done.txt
#		    rm -fr $name/$filter/SKYS/*obj.pl
		    rm -fr $name/$filter/TARGETS
		    fsred -d $name/$filter -p $raw/$date -s $skys -t $target -cwb -r -config $config 
		endif
	    endif
	end
	echo ""
    end
endif
################################################
cd $data
if ( $array[2] ) then
    set tmp = ""
    foreach date ( $dates )
	foreach filter ( $filters )
	    if ( ! -d ${data}/${date}/${name}/$filter/TARGETS ) then
		continue
	    endif
	    set tmp = ${tmp}:$data/$date/$name/$filter
	end
    end
    echo $tmp
    rm -fr $pwd/$name/TARGETS
    mkdir -p $pwd/$name/TARGETS
    fsred -d $pwd/$name -x -t $tmp  -config $config
endif
################################################
cd $data
if ( $array[3] ) then
set test = 0
# MAKE STACK FOR EACH FILTER
    foreach filter ( $filters )
	foreach date ( $dates )
	    set tmp = ""
	    set tmp = ${tmp}:$data/$date/$name/$filter
	    echo -n $filter $date
	    if ( ! -d ${data}/${date}/${name}/$filter/TARGETS ) then
		echo " --NO"
		continue
	    endif
	    echo " --YES"
	    cd $data/$date
	    rm -fr $data/$date/$name/$filter/TARGETS/[2-4]* >>& /dev/null
	    rm -fr $data/$date/$name/$filter/TARGETS/fs* >>& /dev/null 
	    cp $pwd/$name/TARGETS/fs_scamp.txt $data/$date/$name/$filter/TARGETS/
	# MAKE STACK FOR EACH EPOCH/FILTER
	    if ( $stack == 1 ) then
		printf "\nMaking individual stacks. \n"
		set target = `grep -v -E $excludetar $data/$date/0_groups.list | awk '{if($9~"'$objname'" && $12=="'$filter'" && $17 !~ /-/){printf "%s",$10".list "} }' `
		foreach tar ( $target )
		    echo $tar
		    if ( $test == 0 ) then
			fsred -d $data/$date/$name/$filter -p $raw/$date -t $tar -cwy -config $config
		    endif
		end
	# MAKE STACK FOR EACH DATE/FILTER
	    endif
	    if ( $stack == 2 ) then
		printf "\nMaking nightly stacks. \n"
		echo $tmp
		if ( $test == 0 ) then
		    fsred -d $data/$date/$name/$filter -p $raw/$date -t $tmp -cwy -config $config
		endif
	    endif
	end

	if ( $stack == 3 ) then
	    set tmp = ""
	    printf "\nMaking total filter stack. \n"
	    foreach date ( $dates )
		echo -n $filter $date
		if ( ! -d ${data}/${date}/${name}/$filter/TARGETS ) then
		    echo " --NO"
		    continue
		endif
		echo " --YES"
		set tmp = ${tmp}:$data/$date/$name/$filter
	    end
	    rm -fr $pwd/$name/FINAL/$filter/TARGETS/ >>& /dev/null
	    rm -fr $pwd/$name/FINAL/$filter/tmp/ >>& /dev/null
	    rm -fr $pwd/$name/FINAL/$filter/FSRED* >>& /dev/null
	    mkdir -p $pwd/$name/FINAL/$filter/TARGETS
	    cp $pwd/$name/TARGETS/fs_scamp.txt $pwd/$name/FINAL/$filter/TARGETS
	    echo $tmp
	    if ( $test == 0 ) then
		fsred -d $pwd/$name/FINAL/$filter -t $tmp -cwy -config $config
		if ( $status ) then
		    echo exiting...
		    exit 1
		endif
		rm -fr $pwd/$name/FINAL/$filter/TARGETS/*resamp* >>& /dev/null
	    endif
	endif

    end
endif
################################################################
cd $data
if ( $array[4] ) then
    foreach date ( $dates )
	foreach filter ( $filters )
	    set npath = $pwd/$name/$date/$filter
	    ls $data/$date/$name/$filter/TARGETS/2coadd*.coo >>& /dev/null
	    if ( $status ) then
		continue
	    endif
	    echo "copying to $npath"
	    mkdir -p $npath
	    cp $data/$date/$name/$filter/TARGETS/2coadd*.coo $npath
	    cp $data/$date/$name/$filter/TARGETS/20??*${filter}*.fits $npath
	    cp $data/$date/$name/$filter/TARGETS/fs_*_${filter}* $npath
	end
    end
endif
################################################################
cd $data
if ( $array[5] ) then
    foreach date ( $dates )
	foreach filter ( $filters )
	    fsred -d $data/$date/$name/$filter -r
	end
    end
    if ( -d $pwd/$name/TARGETS ) then
	fsred -d $pwd/$name -r
    endif
endif

exit 0

