#!/bin/csh -f
# SET WHICH SEMESTER ARCHIVE CALIBRATION DATA TO USE
# 2011A if before  June 10, 2011, JD 2455722.50. 2011B Otherwise.  
#set SEMESTER = 2011A
set SEMESTER = 2011B
################################################################################
#             IMAGE BACKGROUND SUBTRACTION PARAMETERS                          #
################################################################################
set CLINE = 1            # SET LINEARITY FLAG, 0 for constant value, 1 for image map
set BORDER = 1           # INCLUDE A BORDER OF BAD PIXELS ( 1=yes | 0=no ).  The filters were not coated fully to the edge.
set TLATENT = 0.004      # 0-turn off latent image masking, otherwise time [days] to forward mask saturated sources.
			 #\default = 0.004 = 5.76 minutes   or  0.02 (worst cases) = 28.8min  
set FFACTOR = 5          # SATURATION FILL FACTOR.   0-ONLY MASKING OF CRATERED SATURATED SOURCES... ie COUNTS DROP BELOW BACKGROUND (NEGATIVE)
			 #\ fill in the trough between negative values and saturated values up to FFACTOR pixels.  default = 5. 
			 #\ N>0-MASK SOURCES ABOVE SATURATION THRESHOLD AND FILL IN THE ANNULUS BETWEEN THE CRATER AND SATURATION UP TO N PIXELS
			 #\ TOO SMALL AND MAY MISS SOME, TOO LARGE MAY CREATE MASK BETWEEN SATURATED STARS WITH N PIXELS.   
set CROSSTALK = 0        # 0-turn off | 1-turn-on fix potential crosstalk from saturated sources. | 2-simply mask crosstalk.  | 3-both. 
set TRANSIENT = 10        #( 0 | value ) value-ADD TRANSIENT MASK AND COSMIC RAY MASK TO IMAGE MASKS, 0-DON'T ADD EITHER MASK (faster),
			 #\sometimes this is a little unstable.  where value = sigma outlier detection threshold, 10 is good default, MAKE BIG (500) TO DO ONLY CR HITS.   
set TRANSIENT2 = $TRANSIENT
############################################ 
set ADVBACK = 1          # 0 | 1  Advanced background.  0 is faster, combines background frames.  1 subtracts low order variations, then combines to make sky.  
set NBACK = 9            # SET THE (MAX) NUMBER OF ADJACENT SKY FRAMES TO COMBINE (NEAREST IN TIME) MINIMUM OF 5, recommend Ndither  
set WEIGHT = 2           # SET THE WEIGHT OF THE BACKGROUND FRAMES. (0|1|2) 0=UNIFORM WEIGHT, 1=1/dt[mins], 2=1/dt[mins]/dr[degrees]
set SMODE = SCALE        # (ZERO | SCALE | NONE)  ZERO-APPLY AN ADDITIVE OFFSET TO THE SKY. SCALE-APPLY A SCALE FACTOR (MULTIPLICITIVE)
set CSCALE = NO          # USE A COMMON ZERO|SCALE FOR EACH CHIPS BACKGROUND (YES) or USE INDIVIDUAL FACTORS (NO).
			 #\AS FOR A/B BEAM SWITCHING WHEN THE SKIES MAY HAVE BEEN TAKEN AT DIFFERENT TIMES FOR SOME CHIPS 
set IOBJMASK = YES       # ( YES | NO ) INCLUDE KNOWN OBJECT MASKS? located in "FSRED/bin/mask.objects", add entries as desired (ra dec radius[arcsec])
			 # Currently only masks circular regions as described in "FSRED/bin/mask.objects" (xcenter, ycenter, radius)
			 # EFFECTS SKY CREATION
# HOW TO COMBINE SKY FRAMES - after masking.
if ( $NBACK <= 7 ) then
    set TBFLAG = 3         # 0.XX (Clip upper XX% of non-rejected pixels, average the rest) | N>=1 average with sigclip upper N-sigma  | 0 subtract a constant (mode).
else
    set TBFLAG = 0.5
endif


#set SURFIT = 0,0,0        # FOR DIFFUSE STRUCTURE, THIS IS THE SAFEST.  
#set SURFIT = 2,2,-1        # FOR DIFFUSE STRUCTURE, THIS IS THE SAFEST.  
set SURFIT = 3,3,-1      # WORKS WELL MOST OF THE TIME, MAY OVERSUBTRACT SOME EXTENDED DIFFUSE STRUCTURES.   
set OBJTHRESH = 10        # SURFIT THRESHOLD ABOVE BACKGROUND TO BE CONSIDERED OBJECT
set MINAREA = 0.3        # 0.3 DEFAULT MINIMUM GOOD FRACTION SURFACE AREA OF IMAGE TO FIT A SURFACE, ELSE FIT CONSTANT
#set SURFIT = 3,3,1      # SUBTRACT A SURFACE FIT TO THE SKY SUBTRACTED IMAGE, TRIES TO IGNORE OBJECTS.   
			 #\xorder,yorder,include crossterms | 1,1,0 = a | 2,2,0 = ax+by+0xy+d | 2,2,1 ax+by+cxy+d | 3,3,1 ax+by+cxy+d+ex^2+fy^2+gx^2y+hxy^2+ix^2y^2
			 #\| 2,2,2 same as 2,2,1 but generates diagnostic output images.
			 #\N,N,-1  subtract best guess mesh, uses NxN order polynomial to interpolate masked object regions
			 #\N,N,-2 same as N,N,-1 but generates disagnostic output images    | 0,0,0 = none 
			 #\Px,Py,-1 subtract best guess mesh.  Interpolate object grids with polynomial Px Py; e.g. 5,5,-1  
set WAVELET = 0          # PERFORM WAVELET TRANSFORM AND MASK UP TO n-low orders.  0-OFF.  
set SROWS = 1            # SUBTRACT A POLYNOMIAL OF "n"-ORDER FROM EACH ROW.
			 #\GOOD FOR NOISE/BACKGROUND SUBTRACTION FOR SPARSE FIELDS OR WHEN SKIES WERE TAKEN OFF TARGET.
set SCOLS = 1            # A Negative number will do a cubic spline using naxes/abs(n) spline points.  ONLY on second pass sky subtraction
			 #\0 = OFF | 1,2,4,8,16,32.  4 is usually good, if checker pattern, increase.
set SKYSUB = N           # SUBTRACT BACKGROUND IN SWARP BEFORE COMBINING
set BS = 64              # THE SIZE OF THE BACKGROUND MESH TO SUBTRACT IN SWARP BEFORE COMBINING.  64 | 2048 
set BFS = 2              # THE NUMBER OF BLOCKS TO SMOOTH OVER FOR BACKGROUND DETERMINATION         2 |    1
set FUDGE = 0            # compensate for crowded fields. A negative value applies at the final imcombine as a zero level correction.
			 #\positive value during the sky subtraction step.   a correction term applied as FUDGE*(mean - mode).
# HOW TO COMBINE SKY FRAMES - before masking. Need average to use weights.   
set SBFLAG = 0.5         # 0.XX (Clip upper XX% of non-rejected pixels, average the rest)
set NBACK2 = 9           # SET THE NUMBER OF ADJACENT SKY FRAMES TO COMBINE (NEAREST IN TIME) FIRSTPASS
#set SURFIT2 = 0,0,0     # 0,0,0  1,1,-2      IF THERE IS DIFFUSE STRUCTURE YOU CARE ABOUT, DONT USE SWARP BACKGROUND
#set SURFIT2 = 1,1,0     # 0,0,0  1,1,-2      IF THERE IS DIFFUSE STRUCTURE YOU CARE ABOUT, DONT USE SWARP BACKGROUND
set SURFIT2 = 3,3,-1    # 0,0,0  1,1,-2      IF THERE IS DIFFUSE STRUCTURE YOU CARE ABOUT, DONT USE SWARP BACKGROUND
set IOBJMASK2 = YES      # INCLUDE OBJECT MASK IN FIRST PASS SKY
set OBJTHRESH2 = 5       # SURFIT OBJECT THRESHOLD ABOVE/BELOW MESH BACKGROUND
set WAVELET2 = 0         # default 0, 32 will remove most diffuse structure if first pass mask is detecting sky. 
set SROWS2 = 0
set SCOLS2 = 0
set SKYSUB2 = N          #  SWARP BACKGROUND
set BS2 = 128             #  SWARP BACKGROUND / SURFIT MESH SIZE
set BFS2 = 2             #  SWARP BACKGROUND
set AREAGROW = 0.5       # default = 2, if crowded field, decrease to find some sky.
set HIDETECT = 2         # 1st PASS SOURCE DETECTION, SET -e flag to inspect object mask and vary AREAGROW & HIDETECT as desired.  

# CROWDED FIELDS BACKGROUND INTERPOLATING
set INTERPOLATION = 0    # default = 0 = none | 1-mimsurfit |  Interpolate sky frame regions with no data or where sources are still detected.
set HISIG = 5            # IF INTERPOLATION is non-zero.  set to a high value for sparse fields, set to a lower value, ie 5 for crowded fields.
			 #\Masks the sky image by replacing potential sources with a local average.  
################################################################################

############################# SCAMP FLAGS ######################################
set SNT = 10,100             # SN LIMITS 10,100 works well but sometimes slow, try 50,100 for faster performance.  
set CID = 0                 # 0 automatic | 2MASS CROSS-ID RADIUS (ARCSEC), 0.2-0.5 WORKS WELL.
			     #\Sometimes have to make this large in sparse fields. 
set ASTRCLIP_NSIGMA = 3.0    # REJECT STARS THAT ARE SPLIT 2MASS SOURCES OR THAT HAVE MOVED (HIGH PROPER MOTION), '
set PHOTCLIP_NSIGMA = 3.0    # REJECT STARS THAT ARE SPLIT 2MASS SOURCES OR THAT HAVE BLENDED PHOTOMETRY '
# DEFINE HOW TO SPLIT ASTROMETRIC SOLUTIONS.  NOTE DISTORTION IS IN SKY COORDINATES, SO DIFFERENT ROTATION ANGLES WILL HAVE A DIFFERENT SOLUTION.  
#set ASTRINSTRU_KEY = FILTER,ROTFLAG,DATE-OBS
set ASTRINSTRU_KEY = FILTER,ROTFLAG
set SCAMPI = PSC          # PSC, XWIN, NULL
#set ASTRINSTRU_KEY = FILTER,DATE-OBS
# SOMETIMES ONE SERVER WILL NOT RESPOND, TRY ANOTHER...
#set clients = ( cocat1.u-strasbg.fr axel.u-strasbg.fr vizier.hia.nrc.ca ) # vizier.hia.nrc.ca  blocks port 1660, only uses port 80, requires proxy server.
set clients = ( cocat1.u-strasbg.fr axel.u-strasbg.fr  )
foreach client ( $clients )
    setenv CDSCLIENT $client
#    if ( `ping -o -t 5 $client >>& /dev/null ; echo $status` == 0 ) then
    if ( `find2mass 0,0 >>& /dev/null ; echo $status` == 0 ) then
	echo setting CDSCLIENT to $client
	break
    else
	echo $client not responding
    endif
end
if ( ! $?CDSCLIENT ) then
    echo No CDSCLIENT available... Not able to do astrometric solution.  
    echo -n "Continue anyways? [y|n]: " ; set wait = $<
    if ( $wait == n ) then
	echo Exiting...
	exit 1
    endif
endif
################   1      2       3      4   #
set catalogs = ( 2MASS USNO-A2 USNO-B1 FILE ) 
set ASTREF_CATALOG = 1
set ASTREFCAT_NAME = "/Volumes/Data-3/FourStar/COSMOS.cat" 

set dwait = 1               #  [0|1]  IF DISTORTION NOT AUTOMATICALLY FOUND, PROMPT FOR ACTION BEFORE APPLYING DEFAULT?

# SOLVE DISTORTION, NO FOR VERY SPARSE FIELDS  
set SOLVEAST = Y             # SOLVE ASTROMETRIC DISTORTION (Y | N) FOR SPARSE FIELDS USE N (default distortion)
#set MOTYPE = FIX_FOCALPLANE  # FIND NEW OFFSET, ASSUME FOCAL PLANE IS FIXED     FIX_FOCALPLANE | SAME_CRVAL | UNCHANGED
set MOTYPE = FIX_FOCALPLANE
set STABILITY_TYPE = INSTRUMENT
#set STABILITY_TYPE = GROUP | INSTRUMENT | EXPOSURE
set DISTORT_DEGREES = 3      # number of terms for distortion correction, keep at 3 (RE-DERIVE all orders in header).
set FLAGS_MASK = 0x00f0      # SEXtractor flag mask, default is f0, ff flags saturated, crowded.  , fc, fe
# 1111 0000 = f0    # 1111 1100 = fc   # 1111 1101 = fd     # 1111 1110 = fe     # 1111 1111 = ff  
# FLAGS ARE 
# 1: bright neighbors
# 2: originally blended
# 4: At least one pixel near saturation
# 8: close to image boundary
# 16: aperture data is corrupt
# 32: isophotal data is corrupt
# 64: memory overflow during deblending
# 128: memory overflow during extraction

#  FOR ZEROPOINT DETERMINATION
set SEXFLAG = AAA             # 2MASS QUALITY FLAG TO USE, LEAVE "ALL" FOR ALL, or "AAA" FOR HIGH QUALITY

# SHOULD RARELY HAVE TO MODIFY SCAMP SETTINGS BELOW THIS LINE
set FGROUP_RADIUS = 0.30     # SCAMP GROUP RADIUS, IF CREATING A LARGE MOSAIC, INCREASE THIS ACCORDINGLY
set MATCH = Y                # MATCH TO 2MASS POSITION ON SKY?
# FIND RELATIVE OFFSETS - DONE AUTOMATICALLY
set MATCH_RESOL = 0         # MATCH RESOLUTION 0-AUTO, 1 FOR SPARSE FIELDS. ARCSEC/PIX 2D-HISTOGRAM RESOLUTION
set MATCH_NMAX = 0         # MAX NUMBER OF SOURCES, 0-DEFAULT starts at 2000.  
set POSITION_MAXERR = 1    # MAX POSITION ERROR FROM HEADER (ARCMIN), 1 = default.
set POSANGLE_MAXERR = 1      # 180 - ALLOW ARBITRARY POSITION ANGLES, OTHERWISE 1
set ASW = 1                  # ASTROMETRIC WEIGHT, KEEP AT 1.0,10.0 , IF fs_astref_1d.ps shows ripples, try increasing.   
#set DISTORT_KEYS = XWIN_IMAGE,YWIN_IMAGE
set DISTORT_KEYS = XPEAK_IMAGE,YPEAK_IMAGE
set DISTORT_GROUPS = 1,1
# TYPE OF HEADER TO PRODUCE
set HEADER_TYPE = NORMAL     # KEEP AT NORMAL
# GENERATE A NEW DISTORTION CORRECTION
# SET THRESHOLDS FOR FIRST PASS
set MATCH2 = $MATCH
set SNT2 = $SNT
set CID2 = $CID
set SOLVEAST2 = $SOLVEAST        
set MOTYPE2 = $MOTYPE
################################################################################

############################### SWARP FLAGS ####################################
set IMCOMBINE = YES           # YES - USE IRAF IMCOMBINE | NO - USE SWARP COMBINE
set CTYPE = WEIGHTED         # TYPE OF IMCOMBINE: MEDIAN | AVERAGE | WEIGHTED (AVERAGE AGAIN)    SWARP- AVERAGE | MEDIAN | WEIGHTED
set LWEIGHT = 0.0             # reject images from final combine if thier weight is less than this fraction of the upper quartile
			     #\0.0 = reject none, 0.5 = reject any frame if its weight is less than half the upper quartiles
set REJTYPE = avsigclip      # IRAF only | none | minmax | avsigclip | sigclip, none is best option, but only if all artifacts are masked.    
set WTYPE = MAP_WEIGHT       # TYPE OF WEIGHT MAP, NONE | MAP_WEIGHT
set RESAMP = LANCZOS2        # NEAREST,BILINEAR,LANCZOS2,LANCZOS3 or LANCZOS4 (1 per axis) DEFAULT = LANCZOS3
set RESAMPW = $RESAMP        # Resample the weight image using this. NEAREST tends to smear over bad pixels. DEFAULT = NEAREST 
set OVERSAMPLING = 0         # 0-auto | 1-none | 2=2x2, 3=3x3 |   IF OVERSAMPLED (BAD SEEING FWHM>2pixels)   
set PSCALE = 0.16            # THE DESIRED OUTPUT IMAGE SCALE OF COMBINED IMAGE.  
set force = 0                # force resample of images if they already exist or not.  
# SHOULD RARELY HAVE TO MODIFY SWARP SETTINGS BELOW THIS LINE
set BLANK_BADPIXELS = N      # FROM WHAT I CAN TELL THIS DOES NOTHING DURING RESAMPLING
set INTERPOLATE = N          # FROM WHAT I CAN TELL THIS DOES NOTHING DURING RESAMPLING
# FROM WHAT I CAN TELL SWARP *DOES NOT* ACTUALLY MULTIPLY BY THE SCALES UNTIL THE FINAL COMBINE...NOT DURING RESAMPLING, SO IMCOMBINE MUST DO IT.  
# IF YOU DON'T BELIEVE THE OFFSETS, TURN THEM OFF.  
#set FSCALEKEY = NONE        # DO NOT MULTIPLY BY THE PHOTOMETRIC OFFSET DETERMINED BY SCAMP.   
set FSCALEKEY = FLXSCALE     # APPLY PHOTOMETRIC SCALE FACTOR DETERMINED BY SCAMP.   
# FROM WHAT I CAN TELL SWARP *DOES NOT* APPLY THE ASTRO SCALE UNTIL THE FINAL COMBINE...NOT DURING RESAMPLING.  
set FCAL = VARIABLE          # NONE | FIXED | VARIABLE  APPLY ASTROMETRIC SCALE FACTOR TO IMAGE


set CENTYPE = ALL            # MANUAL, ALL or MOST
set CENTER = 00:00:00.0,-00:00:00.0   # Coordinates of the MANUAL image center
set IMAGE_SIZE = 0
#set CENTYPE = MANUAL
#set CENTER = 97.55226,-64.32798   # Coordinates of the MANUAL image center
#set IMAGE_SIZE = 2048,2048

#set CENTYPE = MANUAL
#set CENTER = 10:00:43.38,02:37:51.8
#set IMAGE_SIZE = 100,100

# SET THE PIXEL SCALE FOR THE FIRST PASS SKY, 0.35 is the default (faster).  Only used for detecting and masking sources... NOT SCIENCE.  
#set PSCALE2 = $PSCALE
set IMCOMBINE2 = YES
set PSCALE2 = 0.36
set autoscale = 0         #   automatically sets PSCALE2 to max(FWHM/2.5, PSCALE2) or else keep PSCALE2 if null or FWHM not found.  
set OVERSAMPLING2 = 0
set FCAL2 = $FCAL
set CTYPE2 = MEDIAN   #   DEFAULT = MEDIAN to get rid of spurious detections. 
set RESAMP2 = LANCZOS2
################################################################################




################################################################################
############# SYSTEM SPECIFIC SETTINGS #########################################
#
# SET FSRED LOCATION
set fsloc = $0:h:h/

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

# SET MACHINE DEPENDENCIES
set machine = `uname -sm`
if ( $machine[1] =~ Linux && ( $machine[2] =~ i386 || $machine[2] =~ i686 ) ) then
    set sedi = "$sed -i''"
    set irafarch = "linux"
    set NCPU = `grep -c processor /proc/cpuinfo`
else if ( $machine[1] =~ Linux && $machine[2] =~ x86_64 ) then
    set sedi = "$sed -i''"
    set irafarch = "linux"
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

################################################################################
#             GENERAL USER PARAMETERS                                          #
################################################################################
# RAW IMAGE NAME DETAIL, not implemented yet
set PREFIX = "fsr_" # raw filename prefix
set NPREFIX = "lfsr_" # desired processed filename prefix
set SUFFIX = ".fits" # raw/processed filename extension type 
set MINSIZE = 150000 # 2048x2048x(32/8/512)*4 number of 512-byte blocks needed for 4 32-bit images, times ~2 safety factor.
#set NFORM = ${PREFIX}"????_??_c?"${SUFFIX} # raw filename search format

################################################################################
# LOOK FOR A CONFIGURATION FILE WITH VALUE THAT WILL REPLACE THE DEFAULTS ABOVE 
################################################################################
set config = null
set tmpstar = ""
@ i = 0
while ( $i < $# )
    @ i += 1
    switch ( $argv[$i] )
	case -config
	    @ j = $i + 1
	    if ( ! -e $argv[$j] ) then
		echo config file not specified... exiting.
		exit 1
	    endif
	    set config = $argv[$j]
	    @ i += 1
	    breaksw
	default:
	    set tmpstar = `echo $tmpstar $argv[$i]`
    endsw
end
echo $config
if ( -e $config ) then
    printf "Found $config\n"
    set nlines = `cat $config | wc -l`
    @ i = 0
    while ( $i <= $nlines )
	@ i += 1
	set CMD = `awk '{if(NR == '$i' && $1 == "set" ){ print $1,$2,$3,$4}  }' $config `
	if ( "$CMD" != "" ) then
	    echo "    $CMD"
	    eval $CMD
	endif
    end
endif
#exit
################################################################################
################################################################################
#     fsred.csh FourStar REDuction C-shell script                              #
#     Created by Andy Monson, Carnegie Observatories, 2012-09-10               #
#     amonson@obs.carnegiescience.edu                                          #
################################################################################
################################################################################
set version = 1.103
################################################################################
################################################################################
#  REVISION HISTORY
# 1.0.0  CREATED
# 1.0.1  CHANGED .pl files to .pl.fits with extensions.  Readable by DS9 and CFITSIO and still small in size.  
# 1.0.2  ADDED custom imexpr C routine, faster than calling IRAF imexpr repeatedly at the beginning.  Also use IRAF rskysub to do 1st pass sky subtract, better than simply using swarps background algorithm.   
# 1.0.3  CHANGED 1st pass sky subtraction to call fsub.csh which has more control/stable than rskysub.  Eliminated the need for fistutil package in IRAF, now create mef files when creating background subtracted images...much faster.  Use custom C program mimsurfit to do masked image fitting for additional background subtraction.     
# 1.0.4  USE IMCOMBINE for final image co-addition, better control and output/understanding compared to SWARP, still use SWARP to resample images.     
# 1.0.5  Cleaned code, added some new parameters.   
# 1.0.6  added mimsurfit, transient detection, general cleaning, replaced $? with $status to resolve UBUNTU clash.  
# 1.0.7  fixed bug...Running SWARP on individual images which do not overlap create different CRVALs, which when combining causes an image shift.     
# 1.0.8  Added crosstalk mask.
# 1.0.9  Fixed sed and split machine dependencies.  Added custom "bin/mask.objects" to reject apriori known diffuse structures 
# 1.1    MINOR cleaning 
# 1.101  Fixed chip option, allow processing of a single chip, or 2 or 3 or all 4 (default)
# 1.102  Added new skycombine.c routine which subtracts the low order background before combining the skys(high order), then add the low orders back in weighted by distance in time and position.  This fixes a problem when IRAF imcombine scaling the background when it is not constant over the entire field.  
################################################################################
################################################################################
# SET INTERNAL VARIABLES
alias images $images
alias proto $proto
alias nproto $nproto
alias gethead $gethead
alias sethead $sethead
alias sex $sex
alias scamp $scamp
alias swarp $swarp
alias psfex $psfex
set PROCESS = "x_"
set fsiraf = $fsloc/IRAF/
set fsbin = $fsloc/bin/
set fsast = $fsloc/ASTROMATIC/
set darkloc = $fsloc/DARKS/
set lcloc = $fsloc/LINEARITY
set fsdist = ${fsloc}DISTORTION/$SEMESTER/
set bpmloc = ${fsloc}BPM/$SEMESTER/
set flatloc = ${fsloc}FLATS/$SEMESTER/
set ASTREF_CATALOG = $catalogs[$ASTREF_CATALOG]
printf "Using calibration semester: $SEMESTER \n"
if ( $ASTREF_CATALOG == "FILE") then
    printf "Using astrometric catalog: $ASTREF_CATALOG = $ASTREFCAT_NAME \n"
    if ( ! -e $ASTREFCAT_NAME  ) then
	printf "Error. File does not exist: $ASTREFCAT_NAME\n"
	exit 2
    endif
else
    set ASTREFCAT_NAME = "null" 
    printf "Using astrometric catalog: $ASTREF_CATALOG \n"
endif
################################################################################
################################################################################
# READ COMMAND LINE PREFERENCES
################################################################################
printf "\n"
#set input = `echo $0 $*`
#if ( $#argv < 1) then
#    goto help
#endif
set input = `echo $0 $tmpstar`
if ( $#tmpstar < 1) then
    goto help
endif

# ouv
#set temp = `getopt 1abcehijl:m:nqrwxyzg:f:k:d:p:t:s: $*`
set temp = `getopt 1abcehijl:m:nqrwxyzg:f:k:d:p:t:s: $tmpstar`
eval set argv=\($temp:q\)
#echo $temp
# define default parameters
set names = ( "FLATS" "SKYS" "TARGETS"  )
set pwd = `pwd`
set dpath = $pwd
set fpass = 0
set dest = "./"
set dome = 0
set flats = "null"
set flat = ""
set redo = n
set targets = "null"
set skys = "null"
set catskys = "null"
set fflag = 0
set xgrid = 0
set bflag = 0
set cflag = 0
set rflag = 0
set BPM2 = 0
set chips = "1-4"
set wait = ""
set skipcflag = 0
set pauseflag = 0
set passflag = 0
set inter = 0
set myverbose = 1
set astroscamp = 0
set astroswarp = 0
set psfex = 0
set wt = 0
set quick = 0
set notarget = 0
set sdirs = "null"
set DEBUG = no
set domag = 0
set check_sat = 1
# read command line parameters
while ( 1 )
#    echo $temp
#    echo $argv
#    echo $1 $2
    switch($1)
    case -1:
      set fpass = 1
      echo "Performing first pass sky only" ; shift;
      breaksw 
    case -a:
      set skipcflag = 1
      echo "skipping raw data check" ; shift;
      breaksw 
    case -e:
      set pauseflag = 1
      set DEBUG = yes
      echo "ENTERING DEBUG MODE... Pausing at select locations." ; shift;
      breaksw 
    case -x:
      set astroscamp = 1
      echo "astromatic scamp" ; shift;
      breaksw 
    case -g:
      set chips = $2
      echo "Using chips $chips"
      shift; shift;
      breaksw 
    case -i:
      set inter = 1
      echo "Interactive mode" ; shift;
      breaksw 
    case -j:
      set dome = 1
      echo "Treating flats as dome flats." ;shift;
      breaksw 
    case -n:
      set notarget = 1
      echo "Not processing Targets" ;shift;
      breaksw 
    case -m:
      set domag = 1
      if ( -e $pwd/$2:t ) then
	set magfile = $pwd/$2:t
      else if ( -e $2 ) then
      	set magfile = $2
      else
        printf "$2 does not exist."
	exit 1
      endif
      shift; shift
      breaksw 
    case -q:
      set quick = 1
      echo "Performing Quick Look Analysis -cwb " ;shift;
      set cflag = 1
      set wt = 1
      set bflag = $TBFLAG
      breaksw 
    case -y:
      set astroswarp = 1
      echo "astromatic swarp" ; shift;
      breaksw 
    case -z:
      set psfex = 1
      echo "astromatic psfex" ; shift;
      breaksw 
    case -r:
      set rflag = 1
      echo "remove temporary files" ; shift;
      breaksw 
    case -b:
      set bflag = $TBFLAG
      echo "Subtracting Background from Target Frames" ; shift;
      breaksw 
    case -c:
      set cflag = 1
      echo "Combining Loops first. The loops must still be explicitly listed in the input files." ; shift;
      breaksw 
    case -d:
      set dest = $2
      shift; shift
      breaksw 
    case -l:
      if ( ! -d $2 ) then
	  echo "$2 not found, exiting..." 
	  exit 1
      else
          set darkloc = $2
          echo Looking in $darkloc for processed darks: dark_XX_1.fits, dark_XX_2.fits, dark_XX_3.fits, dark_XX_4.fits.
          shift; shift
      endif
      breaksw 
    case -f:
      set fflag = 1
      if ( $2 == no ) then
        shift; shift
	set redo = yy
	breaksw
      endif
      if ( $2 == skip ) then
        shift; shift
	set redo = skip
	breaksw
      endif
      if ( -d $pwd/$2 ) then
	set flatloc2 = $pwd/$2
	echo Looking in $flatloc2 for processed flats: X_1.fits, X_2.fits, X_3.fits, X_4.fits.
	shift; shift
      else if ( -d $2 ) then
	set flatloc2 = $2
	echo Looking in $flatloc2 for processed flats: X_1.fits, X_2.fits, X_3.fits, X_4.fits.
	shift; shift
      else
	if ( "$2" =~ *,* ) then
	    cat `echo $2 | tr , " "` > $pwd/`echo $2 | tr , "+"`
	    set flats = $pwd/`echo $2 | tr , "+"`
	else if ( -e $pwd/$2 ) then
	    set flats = $pwd/$2
	else
	    echo NO $2 found, exiting...
	    exit 1
	endif
	echo flat list = $flats ; shift; shift
      endif
      breaksw 
    case -k:
      set fflag = 1
      if ( ! ("$2" =~ *,*) ) then
	echo Must provide 2 lists for -k option
	exit 1
      else
        set flats = `echo $2 | tr , " "`
	set flats[1] = $pwd/$flats[1]
	set flats[2] = $pwd/$flats[2]
	echo cold flats list = $flats[1]
	echo warm flats list = $flats[2]
	set fflag = $#flats
	shift; shift
      endif
      breaksw 
    case -p:
      if ( -d $2 ) then
	cd $2 ; set dpath = `pwd` ; cd $pwd
      else
	echo "$2 Not a directory.  Exiting..."
	exit 1
      endif
      echo "data path = $dpath" ; shift; shift
      breaksw 
    case -s:
	set tmpsky = $pwd/tmpsky.list
#	set tmpsky = $pwd/`echo $2 | tr , "+"`
      if ( "$2" =~ *,* ) then
          cat `echo $2 | tr , " "` > $tmpsky
	  if ( $status ) then
	    rm -f $tmpsky
	    echo FAILED TO CREATE SKY LIST... PLEASE CHECK.
	    exit 1
	  endif
	set skys = $tmpsky
      else if ( -e $pwd/$2 ) then
	set skys = $pwd/$2
      else if ( -e $2 ) then
	set skys = $2
      else
	echo NO $2 found, exiting...
	exit 1
      endif
      echo "sky list = $skys" ; shift; shift
      breaksw 
    case -t:
	set tmptar = $pwd/tmptar.list
#	set tmptar = $pwd/`echo $2 | tr , "+"`
      if ( "$2" =~ *,* ) then
          cat `echo $2 | tr , " "` > $tmptar
	  if ( $status ) then
	    rm -f $tmptar
	    echo FAILED TO CREATE TARGET LIST... PLEASE CHECK.
	    exit 1
	  endif
	set targets = $tmptar
      else if ( "$2" =~ *:* ) then
	set sdirs = `echo $2 | tr : " "`
	echo Searching these directories for data:
	foreach var ( $sdirs )
	    echo $var
	end
#	exit 0
      else if ( -e $pwd/$2 ) then
	set targets = $pwd/$2
      else if ( -e $2 ) then
	set targets = $2
      else
	echo NO $2 found, exiting...
	exit 1
      endif
      echo "object list = $targets" ; shift; shift
      breaksw 
    case -w:
      set wt = 1
      echo "Weighting by 1/(BACKGROUND*FWHM*FWHM)" ; shift;
      breaksw 
    case -h
help:
	echo "FSRED $version"
	echo "Usage" 
	echo "[-b] background subtract -t targets using the -s skies, otherwise subtract a constant modal background"
	echo "[-c] combine loops before linearization, faster.  Otherwise each image is linearized first and then integer pixel shifts within a loop sequence are found and applied in an average imcombine."
	echo "[-d] directory to place data."
	echo "[-e] pause after creating SKY files for inspection before continuing."
	echo "[-f xxx.list,xxx.list] flat field list(s),   Multiple lists can be comma separated.  Use these flats throughout the rest of the process.  "
	echo "[-fno -f xxx.list,xxx.list] same as above, but do not attemp to solve astrometry, still try to detect and mask objects though."
	echo "[-fskip -f xxx.list,xxx.list] same as above, but do not attemp to mask any sources, rely on rejection clipping."
	echo "[-f dir] flat field using previously created flat field located in dir."
	echo "[-g] egrep only chip N from the input list: 1 | 1,3 | 2-4 |  default = 1-4 "
	echo "[-j] treat flats as dome flats. ie, no dithers, no point sources. "
	echo "[-k cold.list,warm.list ] Create independent K flat field.  -k cold.list,warm.list.  "
	echo "[-l] directory path to existing dark data."
	echo "[-p] directory path to raw data if full path not specified in the input list(s)"
	echo "[-r] remove temporary/intermediate files"
	echo "[-s] sky field list(s), re-enter the target list here to use the adjacent targets frames as skies (sparse fields). Multiple lists can be comma separated."
	echo "[-t] target field list"
	echo "[-w] weight images by 1e8/(BACKGROUND*FWHM^2) before co-adding. "
	echo "[-x] run SCAMP on all TARGETS/*MEF.cat files in the -d directory"
	echo "[-i] interactively view SCAMP output, else output is created in postscript files."
	echo "[-y] run SWARP on all TARGETS/*MEF.fits files in the -d directory"
	echo "[-z] run PSFX on final co-added image in the -d directory"
	echo ""
	echo "Example: fsred.csh -cbrxiy -d M83/J -fno -f flat.list -s sky.list -t target.list -p path/to/raw/data"
	echo " 1: Create a flat from the files in flat.list by first combining them together, detect objects and de-register the object masks, then re-combine the original images using those masks. Finally normalize each flat by the average of all chips."
	echo " 2: Reduce the sky frames from the files in sky.list using the flat created from the -f option.  Combine loops first for speed (-c option)."
	echo " 3: Reduce the target frames from the files in target.list using the flat created from the -f option.  Combine loops first for speed (-c option).  If the sky list is the same as the target list then links are created which point to the already reduced sky versions."
	echo " 4: Subtract the background from the target frames averaging the NBACK nearest sky frames weighted by (1/dtime) as the background."
	echo " 5: Create multiextention fits files (mef) and mef weight maps.  The default weights are unity or null for bad pixels and guide probe intrusions. Run sextractor on mef files to produce FITS-LDAC catalogs for SCAMP."
	echo " 5: Run SCAMP (interactively -i option) on FITS-LDAC catalogs to find astrometric solution and produce auxiliary .ahead files"
	echo " 6: Run SWARP to co-add the mef files using the .ahead astrometric solutions."
	exit 0
    case --:
      shift
      break
    default:
	exit 0
    endsw
end

#exit 
################################################################################
############# QUICK LOOK SETTINGS ##############################################
if ( $quick == 1 ) then
    set SBFLAG = 0.5
    set TLATENT = 0
    set TRANSIENT = 0
    set CROSSTALK = 0
    set NBACK2 = 12
    set WEIGHT = 0
    set SROWS2 = 0
    set SCOLS2 = 0
    set WAVELET2 = 0
    set SURFIT2 = 0,0,0
    set OBJTHRESH2 = 5
    set SKYSUB2 = Y          #  SWARP BACKGROUND
    set BS2 = 128            #  SWARP BACKGROUND / SURFIT MESH SIZE
    set BFS2 = 2             #  SWARP BACKGROUND 
    set PSCALE2 = 0.3
    set OVERSAMPLING2 = 0
    set FCAL2 = VARIABLE
    set CTYPE2 = AVERAGE
    set RESAMP2 = LANCZOS2
endif
set PSCALE3 = $PSCALE2
set OBJTHRESH3 = $OBJTHRESH2
################   SET SHELL MEMORY LIMITS #####################################
if ( `limit | grep stacksize | wc -l ` != 0 ) then
    limit stacksize unlimited
endif
if ( `limit | grep descriptors | wc -l ` != 0 ) then
    limit descriptors 8192
else if ( `limit | grep openfiles | wc -l ` != 0 ) then
    limit openfiles 2048
else
    echo Cannot find file limit descriptor, continuing anyways.
endif
limit
echo "BACKGROUND JOBS = $BKJOBS"
#if ( $machine[1] =~ Darwin ) then
#    limit descriptors 1024
#else if ( $machine[1] =~ Linux ) then
#    limit openfiles 1024
#endif
################################################################################

################################################################################
#############      XGRID SETTINGS      #########################################
################################################################################
# IT IS NECESSARY TO EDIT /usr/share/sandbox/xgridagentd_task_nobody.sb
# Comment out the allow statements and add this one to allow write access to all
# (allow process* sysctl* mach* file-read* file-write* network*)
# fetch info from xgrid
# xgrid -h localhost -p 4star -job list
# xgrid -h localhost -p 4star -job results -id 12293
if ( $XGRID ) then
    set host = localhost
    set passwd = 4star
    xgrid -h $host -p $passwd -grid list >>& /dev/null
# check exit status (of last command)
    if ( $status == 0 ) then
	set BKJOBS = 64          # SET MAXIMUM NUMBER OF SIMULTANEOUS XGRID BACKGROUND JOBS 
	set PROCESS = xgrid
	echo "Found XGRID, NOTE: -d destination must be on /Volumes/FourStarSAN/ to be accessed by all Data-Red-[1-3]"
	set xgrid = 1
	alias xgridx "xgrid -h $host -p $passwd -job run "
	set xgridx =  "xgrid -h $host -auth Password -p $passwd -job run "
    #    alias xgridx "xgrid -h $host -auth Password -p $passwd -job submit "
    else
	echo "NO XGRID HOST FOUND"
	set xgrid = 0
    endif
endif

################################################################################
set t0 = `date +%s`
################################################################################
onintr bexit 
if ( 0 ) then
bexit:
    if ( 1 ) then
	echo "KILLING ALL $t0 FOURSTAR CSH processes"
	foreach jid (`ps -a | grep -v tcsh | grep -E '$t0' | awk '{print $1}'`)
	    echo killing id $jid
	    kill -9 $jid
	end
    endif
    if ( 0 ) then
	echo "KILLING ALL $PROCESS processes"
	foreach jid (`ps -a | grep -v -E 'x_system|x_tv' | grep $PROCESS | awk '{print $1}'`)
	    echo killing id $jid
	    kill -9 $jid
	end
    endif
exit 1
endif
################################################################################
################################################################################
set dest = `echo $dest |awk '{if(substr($0,length,1)=="/"){print substr($0,1,length-1)}else{print} }'`
if( ! -d $dest ) then
    mkdir -p -m 777 $dest
endif
# CHECK IF DESTINATION MADE IN LOCAL DIRECTORY
if( -d ./$dest ) then
    set dest = $pwd/$dest
endif
if ( -w $dest ) then
    echo "Destination = $dest"
else
    echo "Don't have write permissions to $dest"
    exit 1
endif
# SET UP TEMP DIR
set tempdir = $dest/tmp/
#set tempdir = ./
if ( ! -e $tempdir) then
    mkdir -m 777 $tempdir
endif
cd $dest

### UPDATE LOG FILE ############################################################
if ( 1 ) then
# JUST COPY THIS ENTIRE SCRIPT
    set log = "FSRED_"`date +"%F_%H-%M-%S"`".log"
    set log2 = "FSOUT_"`date +"%F_%H-%M-%S"`".log"
    cp `which $0` $log
    if ( -e $config ) then
	set nlines = `cat $config | wc -l`
	@ i = 0
	while ( $i <= $nlines )
	    @ i += 1
	    set CMD = `awk '{if(NR == '$i' && $1 == "set" ){ print $1,$2,$3,$4}  }' $config `
	    if ( "$CMD" != "" ) then
		echo "$CMD" >> $log2
	    endif
	end
    endif
endif
#exit 0
################################################################################

################################################################################
# IF NO LISTS, SKIP AHEAD
if ( $flats[1] == "null"  && $skys[1] == "null" && $targets[1] == "null" ) then
    echo "No input list provided, searching for existing data. "
    @ ilist = 1
    foreach list ( $flats $skys $targets )
	if ( -d $dest/$names[$ilist] ) then
	    ls $dest/$names[$ilist]/${NPREFIX}????_??_c[$chips].fits |& awk '/'$NPREFIX'/ {print}' | sed 's|_c[1-4].fits||' | sort | uniq > $dest/$names[$ilist]/zmef.txt
	    ls $dest/$names[$ilist]/${NPREFIX}????_??_c[$chips].fits |& awk '/'$NPREFIX'/ {print}' | sort | uniq > $dest/$names[$ilist]/zall.txt
	    if ( -z $dest/$names[$ilist]/zmef.txt ) then
		echo "No files found: $dest/$names[$ilist]/${NPREFIX}????_??_c[$chips].fits"
	    else
		echo "Found: $dest/$names[$ilist]/${NPREFIX}????_??"
		cat $dest/$names[$ilist]/zmef.txt
	    endif
        else
	    echo No $dest/$names[$ilist]  directory.
	endif
	if ( $#flats == 2 ) then
	    continue
	else
	    @ ilist ++
	endif
    end
else
############### LINEARIZE, DARK SUBTRACT AND FLAT FIELD ALL RAW DATA
    if ( $skys[1] != "null" ) then
	cat $skys | grep -E 'c['$chips']' > $tempdir/asky.list
	set skys = $tempdir/asky.list
    endif
    if ( $skys[1] != "null" && $targets[1] != "null" ) then
	rm -f $tempdir/new.list >>& /dev/null
	cat $skys $targets | sort -u > $tempdir/new.list
	set catskys = $tempdir/new.list
    else
	set catskys = $skys
    endif
    @ ilist = 1
    foreach list ( $flats $catskys $targets )
	printf "\n -----  STARTING $names[$ilist] -------- \n "
	if ( $ilist != 1 ) then
	    set dome = 0
	endif
	if ( $ilist == 3 && $notarget == 1 ) then
	    printf "\n Not Processing Targets. \n "
	    goto cleanup
#	    continue
	endif
	if ( $list:t == "null" ) then
	    printf "\n Nothing to do for $names[$ilist].\n"
	    @ ilist ++ # INCREMENT TO THE NEXT LIST
	    continue
	else
	    printf "\nPlacing chips: $chips from $list into $tempdir/atmp.list\n"
	    cat $list | grep -v \# | grep -E 'c['$chips']' > $tempdir/atmp.list
	    set list = $tempdir/atmp.list
	endif

	set dereg = 0
	set target = 0
#	printf "\n\n $list  $ilist $dereg \n"
	if ( -e $dest/$names[$ilist]/cflag.txt) then
	    set cflag = 1
	endif

	if ( $ilist == 1 && $list:t == "null" && $fflag == 0 ) then
	    printf "\n USING ARCHIVAL FLATS \n"
	    @ ilist ++ # INCREMENT TO THE NEXT LIST
	    continue
	else if ( $ilist == 1 && $list:t == "null" && $fflag == 1 ) then
	    printf "\n USING EXISTING FLATS\n"
	    @ ilist ++ # INCREMENT TO THE NEXT LIST
	    continue
	else if ( $ilist == 2 && ( -e $dest/$names[$ilist]/fs_scamp.txt ) ) then
#	else if ( $ilist == 2 && ( -e $dest/$names[$ilist]/fsgabgg_scamp.txt ) ) then
	    printf "\nfs_scamp.txt present.  Already processed SKYS. \n"
##	    @ ilist ++ # INCREMENT TO THE NEXT LIST
##	    continue
	    set dereg = 1
	    goto namelist
	else if ( $ilist == 3 && ( -e $dest/$names[$ilist]/fs_scamp.txt )   ) then
	    printf "\nfs_scamp.txt present.  Already processed TARGETS. \n "
	    set target = 1

	    goto namelist
	else
	    printf "\n\n %10s %s : %d  entries \n" $names[$ilist] $list `cat $list | wc -l`
################################################################################
	    if ( ! -d $dest/$names[$ilist] ) then
		mkdir -p -m 777 $dest/$names[$ilist]
	    endif
# CREATE NAME LISTS
namelist:
######################
	    cd $dest/$names[$ilist]
#	    printf "\n%10s --> %s\n" $list:t `pwd`

	    rm -f zmef.txt zall.txt zsky.txt >>&/dev/null
	    if ( $list != "null" ) then
		if ( $cflag == 1 && $ilist != 1 ) then
		    cat $list | awk -F_ '\!/#/ && /'$PREFIX'/ {sub("'$PREFIX'","'$NPREFIX'"); $3 = "00";OFS="_"; print "'$dest/$names[$ilist]/'"$1,$2,$3 }' | sort -u > zmef.txt
		    cat $list | awk -F_ '\!/#/ && /'$PREFIX'/ {sub("'$PREFIX'","'$NPREFIX'"); $3 = "00";OFS="_"; print "'$dest/$names[$ilist]/'"$1,$2,$3,$4 }' | sort -u > zall.txt
		    if ( $ilist == 2 ) then
			cat $skys | awk -F_ '\!/#/ && /'$PREFIX'/ {sub("'$PREFIX'","'$NPREFIX'"); $3 = "00";OFS="_"; print "'$dest/$names[$ilist]/'"$1,$2,$3,$4 }' | sort -u > zsky.txt

		    endif
		else
		    cat $list | awk -F_ '\!/#/ && /'$PREFIX'/ {sub("'$PREFIX'","'$NPREFIX'"); OFS="_";print "'$dest/$names[$ilist]/'"$1,$2,$3 }' | sort -u > zmef.txt
		    cat $list | awk '\!/#/ && /'$PREFIX'/ {sub("'$PREFIX'","'$NPREFIX'");print "'$dest/$names[$ilist]/'"$0 }' | uniq > zall.txt
		    if ( $ilist == 2 ) then
			cat $skys | awk '\!/#/ && /'$PREFIX'/ {sub("'$PREFIX'","'$NPREFIX'");print "'$dest/$names[$ilist]/'"$0 }' | uniq > zsky.txt
		    endif
		endif
	    endif
	    # REMOVE .fz or .gz SUFFIX IF PRESENT
     	    sedi 's|.[f-g]z||' zall.txt
     	    sedi 's|.[f-g]z||' zsky.txt >>& /dev/null

	    if ( -e fs_done.txt ) then
		echo fs_done.txt already exists, continuing...
		@ ilist ++
		continue
	    endif

	    if ( $dereg == 1 ) then
		goto dereg
	    else if ( $target == 1 ) then
		goto target
	    else if ( $passflag == 1 ) then
		set passflag = 0 
		goto secpass
	    endif
#########################################################################
	#BREAK LIST INTO CHUNKS FOR MULTIPLE CPUS
	# REMOVE OLD TEMP LISTS
	    rm -f $tempdir/aaxx* >>& /dev/null
	    rm -f $tempdir/bbxx* >>& /dev/null
	# CREATE A LIST FOR EACH RUN WHICH WILL CONTAIN ALL LOOPS, AND ALL CHIPS
	    set first = `echo $chips | cut -b 1`
	    if ( $machine[1] =~ Darwin ) then
		split -p "_01_c$first" $list $tempdir/aaxx
	    else
		awk 'BEGIN{i=0} /_01_c'$first'/{i++}{print $0 > "'$tempdir'aaxx"i }' $list
	    endif
	# HOW MANY WERE THERE	    
	    set NUNIQ = `ls $tempdir/aaxx* | wc -l`

	# HOW MANY GO TO EACH CPU
	    set UNUM = `echo "$NUNIQ / $NCPU + 1" | bc `
	    echo Number of RUNS = $NUNIQ
	    echo Number of CPUS = $NCPU
	    echo Number of RUNS per CPU = $UNUM
	# CREATE LISTS FOR EACH CPU WITH UNUM ENTRIES.
	    ls $tempdir/aaxx* | split -l $UNUM - $tempdir/bbxx
	    foreach name ( `ls $tempdir/bbxx*` )
		foreach name2 ( `cat $name` )
		    # sort in reverse order so that the last image in a loop is the reference image...contains the correct guide probe positions. 
		    sort -r $name2 >> $name.txt
		end
	    end
#########################################################################
	    foreach newinput ( `ls $tempdir/bbxx*.txt` )
		foreach chip ( 1 2 3 4 )
		    rm -f $newinput.$chip.list >>& /dev/null
		    set numloops = 0
		    foreach namein (`cat $newinput | grep c$chip`)
			@ numloops ++

		    # CHECK/ADD FILE NAMES TO INCLUDE GLOBAL PATH
		    # CHECK IF IN RUN DIRECTORY
			if ( -e $pwd/$namein:t ) then
			    set namein = $pwd/$namein:t
		    # CHECK IF ITS A GLOBAL PATH
			else if ( -e $namein ) then
			    set namein = $namein
		    # CHECK IF IN DESIGNATED PATH
			else if ( -e $dpath/$namein ) then
			    set namein = $dpath/$namein
			else if ( $skipcflag == 1 ) then
			    echo "skipping raw data check..."
			    goto check
			else
			    echo File not found: $dpath/$namein or ./$namein
			    printf "Try setting the raw data path using the -p option \n\n"
			    exit 1
			endif
check:
		    # CHECK IF IMAGE IS COMPRESSED
			if ( $namein:e == fits ) then
			    set fform = fits
			    set nameout = `echo $dest/$names[$ilist]/$namein:t | sed 's|'$PREFIX'|'$NPREFIX'|'`
			else if ( $namein:e == fz) then
			    set fform = fpack
			    set nameout = `echo $dest/$names[$ilist]/$namein:t:r | sed 's|'$PREFIX'|'$NPREFIX'|'`
			else if ( $namein:e == gz ) then
			    set fform = gzip
			    set nameout = `echo $dest/$names[$ilist]/$namein:t:r | sed 's|'$PREFIX'|'$NPREFIX'|'`
			endif

		    # ONLY COMBINE SKYS AND TARGETS. IF FLATS WERE LOOPED DURING TWILIGHT THE LEVELS WERE CHANGING
			if ( $cflag == 1 && $ilist != 1 ) then
			    set namegrep = `echo $namein:t | awk -F_ '{OFS="_"; $3="..";print $0}'`
			    set nameout = $nameout:h/`echo $nameout:t | awk -F_ '{OFS="_"; $3="00";print $0}'`
			endif

		    # CHECK IF FILE ALREADY PROCESSED.
			if ( ($ilist == 1 && -e $nameout) || (-e $nameout && ( -e $nameout.pl.fits || -e $nameout.1.pl.fits || -e $nameout:t.pl.fits ) ) || ( $cflag == 1 && -e $tempdir/z$nameout:t.parc ) ) then
			    if ( ! -e $nameout.pl.fits ) then
				echo Could not find $nameout.pl.fits
				if ( -e $nameout.1.pl.fits ) then
				    echo Copying $nameout.1.pl.fits
				    cp $nameout.1.pl.fits $nameout.pl.fits
				else
				    echo Could not find $nameout.1.pl.fits either... Exiting.
				    exit 1
				endif
			    endif
			    echo "$namein already processed!"
			    continue
		    # SKYS, CHECK FLATS SINCE THOSE WERE FLAT FIELDED, CAN ALSO CHECK IF TARGETS WERE DONE IN SKYS
#			else if ( -e $dest/$names[1]/$nameout:t && -e $dest/$names[1]/$nameout:t.pl.fits ) then
#			    echo "$nameout:t already processed in $names[1].  Creating link to file."
#			    ln -s $dest/$names[1]/$nameout:t $nameout 
#			    ln -s $dest/$names[1]/$nameout:t.pl.fits $nameout.pl.fits 
#			    continue
			else if ( -e $dest/$names[2]/$nameout:t && -e $dest/$names[2]/$nameout:t.pl.fits ) then
			    echo "$nameout:t already processed in $names[2].  Creating link to file."
			    ln -s $dest/$names[2]/$nameout:t $nameout 
			    ln -s $dest/$names[2]/$nameout:t.pl.fits $nameout.pl.fits 
			    continue
			# JUST IN CASE ONE PROCESS DID NOT COMPLETE.  TRY AGAIN		
			else
			    rm -f $nameout
			    rm -f $nameout.pl.fits
			    rm -f $nameout.1.pl.fits
			# WRITE FILES THAT HAVE NOT BEEN PROCESSED TO NEW TEMP FILE
			    printf "%s\n" $namein >> $newinput.$chip.list
			endif
		    end # foreach name

		# CHECK IF LIST WAS CREATED FOR THIS CHIP
		    if( -e $newinput.$chip.list ) then
#		        echo $newinput.$chip.list  created with  `cat $newinput.$chip.list | wc -l ` entries
		    else
			continue
		    endif

		# GET CHIP LIST PROPERTIES
		    if ( $fform == gzip ) then
			set attrib = `gzcat $namein | gethead -u stdin filter chip gain mjd`
		    else
			set attrib = `gethead -u $namein filter chip gain mjd`
		    endif
		    set filter = $attrib[1]
		    set chip = $attrib[2]
		    set gain = $attrib[3]
		    if ( $attrib[4] == "___" ) then
			if ( $SEMESTER == 2011A ) then
			    echo Using semester: $SEMESTER 
			else
			    echo -n "Semester $SEMESTER selected, but no MJD found in header, are you sure you want to continue\? " ; set wait = $<
			    if ( $wait == n || $wait == no ) then
				exit 0
			    endif
			endif
		    else if ( `echo "$attrib[4] < 55722.50" | bc` ) then
			if ( $SEMESTER == 2011A ) then
			    echo Using semester: $SEMESTER 
			else
			    echo -n "Semester $SEMESTER selected, but MJD suggests this is 2011A, are you sure you want to continue? " ; set wait = $<
			    if ( $wait == n || $wait == no ) then
				exit 0
			    endif
			endif
		    else
			echo Using semester: $SEMESTER 
		    endif

		    printf " $nameout " | tee -a $log2
		# FIND THE GAIN MODE
		    if( $gain == "FullWell" ) then
			set gain = "fw"
		    else if ( $gain == "LoNoise" ) then
			set gain = "ln"
		    else
			echo "GAIN KEYWORD NOT FOUND. Exiting..."
			exit 1
		    endif
		# USE CONSTANT LINEARITY
		    if ( $CLINE == 0 ) then 
#			if ( $chip == 1 ) then 
#			    set lc = 1.0e-8
#			else if ( $chip == 2 ) then
#			    set lc = 1.3e-8
#			else if ( $chip == 3 ) then
#			    set lc = 1.1e-8
#			else if ( $chip == 4 ) then
#			    set lc = 1.2e-8
#			endif
			set lccor = ( 1.0e-8 1.3e-8 1.1e-8 1.2e-8 )
		        set lc = $lccor[$chip]   # NO LINEARITY CORRECTION
#		        set lc = 0.0   # NO LINEARITY CORRECTION
#			set lc = 2.5e-8   # TOO MUCH LINEARITY CORRECTION
		# USE IMAGE LINEARITY (PIXEL BY PIXEL)
		    else
			set lc = ${lcloc}/lc_${gain}_${chip}.fits
		    endif
		    if ( $lc == "" ) then
		        echo "Cant find Linearity... exitting"
			exit 1
		    else
			printf "\n  Linearity: $lc  " >> $log2
		    endif
		# USE ARCHIVAL FLAT OR FLAT SPECIFIED WITH -f OPTION 
		    if ( $fflag == 0 || ! $?flatloc2 ) then
			set flatloc2 = $flatloc
		    endif
		    if ( $fflag == 1 && $ilist != 1 && $flatloc2 == $flatloc  ) then
			set flatloc2 = $dest/$names[1]
		    endif

		    set flat = ${flatloc2}/${filter}_${chip}.fits
		    if ( ! -e $flat ) then
			printf "No $flat found, exiting...\n\n"
			exit 1
		    endif
		    if ( $flat == "" ) then
		        echo "Cant find Flat... exitting"
			exit 1
		    else
			printf "\n  Flat: $flat  " >> $log2
		    endif
		# USE ARCHIVAL DARK
		    if ( 1 ) then
			set dark = ${darkloc}/dark_${gain}_${chip}.fits
			if ( ! -e $dark ) then
			    printf "No $dark found, exiting...\n\n"
			    exit 1			
			endif
		    else
			set dark = 0
		    endif
		    printf "\n  Dark: $dark  " >> $log2
		# USE BAD PIXEL MASK
		    set bpm = ${bpmloc}/bp_${chip}.pl.fits
		    printf "\n  BPM: $bpm  " >> $log2


		# ACTUALLY PROCESS THE DATA
		# ONLY ALLOW NUMBER OF BACKGROUND JOBS
		    set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv' | grep -E 'x_|sed' | wc -l`
		    while ( $numbkjobs > $BKJOBS  )
			set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv' | grep -E 'x_|sed' | wc -l`
			printf "\r$numbkjobs  waiting..."
			sleep 1
		    end
		# DEFINE BAD PIXEL MASK BORDER 
		    if ( $ilist == 1 ) then
#			set BORDER2 = 0
			set BORDER2 = $BORDER
			set cflag2 = 0
			set CROSSTALK2 = 0
		    else
			set BORDER2 = $BORDER
			set cflag2 = $cflag
			set CROSSTALK2 = $CROSSTALK
		    endif
		    
		    set celect = 1    # CONVERT TO ELECTRONS
		    set vimexpr = 0   # set verbosity of x_imexpr
		# FINALLY RUN IMEXPR
		    if ( $xgrid == 0 ) then
			$fsiraf/x_imexpr -v $vimexpr -c $cflag2 -e $celect -i $newinput.$chip.list -d ${dest}/$names[$ilist]/ -l ${lc} -k ${dark} -f ${flat} -b ${bpm} -g $FFACTOR -p $BORDER2 -a $CROSSTALK2 &
		    else
			xgridx $fsiraf/x_imexpr -c $cflag2 -e $celect -i $newinput.$chip.list -d ${dest}/$names[$ilist]/ -l ${lc} -k ${dark} -f ${flat} -b ${bpm} -g $FFACTOR -p $BORDER2 -a $CROSSTALK2 &
		    endif
		# INCREASE ISLEEP IF COMPUTER BECOMES TOO BOGGED DOWN DURING INITIAL IMEXP
		    sleep $isleep
		    if ( $DEBUG == 'yes' && $wait != 'Y' ) then
			wait
			echo ""
			echo -n "go on to next image ([y|Y]):" ; set wait = $<
		    endif
		# START THE NEXT CHIP
		end # foreach chip
	    # START THE NEXT RUN 
	    end # foreach newfile
################################################################################
	    wait

# SATURATION REJECT

	    if ( $check_sat == 1 ) then
		@ nsat = 0
		set check_sat = 0
		foreach image ( `cat zall.txt` )
		    set satflag = `gethead -u $image SATURATE BAVE | awk '{print $2/$1}'`
		    echo -n $image $satflag
		    if ( `echo "$satflag > 0.8" | bc -l ` ) then
			echo " saturated..."
			@ nsat ++
		    else
			echo "  "
		    endif
		end
#		goto namelist
	    endif
	    if ( $nsat > 0 ) then
		echo "There are $nsat saturated frames in the list.  Remove them before continuing or they will adversely affect the reduction..."
		set wait = n
		echo -n "Continue anyways [n|y]" ; set wait = $<
		# ONLY IF y 
		if ( $wait == y ) then
		    echo Continuing...
		else
		    exit 1
		endif

	    endif

#            exit 0
################################################################################
################################################################################
secpass:
	    set namein = `head -n1 zall.txt`
	    set attrib = `gethead -u $namein filter chip gain`
#	    endif
	    set filter = $attrib[1]
	    set chip = $attrib[2]
	    set gain = $attrib[3]
	    # MAKE SECOND PASS OBJECT REJECTION MASKS FOR FLATS AND SKYS
	    # propogate saturated sources to next image. mod 1 is bad pixel, mod 2 is saturated, mod 4 is probe,  mod 8 is now previously saturated.   
	    if ( ($TLATENT != 0) && ( $ilist == 1 || $ilist == 2 || $ilist == 3 ) && $dome == 0 ) then
		if ( -e ../SKYS/1dflag.txt ) then
		    echo 1dflag.txt exists, already masked saturated sources.
		else if ( -e ../FLATS/1dflag.txt && $ilist == 1 ) then
		    echo 1dflag.txt exists, already masked saturated sources.
		else
		    echo MASKING SATURATED SOURCES | tee 1dflag.txt
		    set omlist = $fsbin/mask.objects
		    set omlist2 = $fsbin/mask2.objects
		    awk '\!/#/ {print $1,$2,$3,$4,$5}' $omlist > $omlist2
		    foreach chip ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
			if ( `ls *_c$chip.fits >>& /dev/null ; echo $status` ) then
			    echo "No files found for chip $chip."
			    continue
			endif
			awk '{print}' <<EOF > $tempdir/asat_${chip}_$t0.csh
#!/bin/csh
cd `pwd`
foreach name ( \`ls *_c$chip.fits\` )
    set timezero = \`gethead \$name MJD\`
#    if ( $IOBJMASK == YES ) then
    if ( 1 ) then
#	echo "Searching for existing object masks."
	rm -fr \$name.obj
	set naxis = \`gethead \$name NAXIS1 NAXIS2\`
	if ( -e $omlist2 ) then
	    sky2xy \$name \@$omlist2 | paste $omlist2 - | awk ' \! /offscale/ {if( (\$10>-\$4 && \$10<\$4+'\$naxis[1]') && (\$11>-\$4 && \$11<\$4+'\$naxis[2]') ){printf "# %s \ncircle (%f, %f, %f) \n",\$5,\$10,\$11,\$4/0.16}}' >> \$name.obj
#amsk_${filter}_${group}.obj
	endif
	if ( -e \$name.obj ) then
	    if ( ! -z \$name.obj ) then
#		printf "\nMasking known object(s) at:\n        X    Y    RAD  \n"
		printf "Found Objects in $omlist for \$name \n"
		cat \$name.obj
		mv \$name.obj \$name.obj.old
		awk ' \! /#/ {print}' \$name.obj.old > \$name.obj ; rm \$name.obj.old
		rm -fr \${name}.obj.pl \${name}.plorg.fits >>& /dev/null
		mv \${name}.pl.fits \${name}.plorg.fits
		cp $fsiraf/mskregions.par $tempdir/\$name.par
		$sedi 's|mskregions.regions = |mskregions.regions = \"'\$name'.obj\"|' $tempdir/\$name.par
		$sedi 's|mskregions.masks = \"\"|mskregions.masks = \"'\${name}'.obj.pl\"|' $tempdir/\$name.par
		$sedi 's|mskregions.verbose = yes|mskregions.verbose = no|' $tempdir/\$name.par
		$sedi 's|mskregions.regval = 2|mskregions.regval = 128|' $tempdir/\$name.par
		$sedi 's|mskregions.refimages = \"\"|mskregions.refimages = \"'\${name}'\"|' $tempdir/\$name.par
		cp $fsiraf/imexpr.par $tempdir/\${name}_2.par
		$sedi 's|imexpr.expr =|imexpr.expr = \"( a + b )\"|' $tempdir/\${name}_2.par
		$sedi 's|imexpr.a =|imexpr.a = \"'\${name}'.plorg.fits[1]\"|' $tempdir/\${name}_2.par
		$sedi 's|imexpr.b =|imexpr.b = \"'\${name}'.obj.pl\"|' $tempdir/\${name}_2.par
		$sedi 's|imexpr.output =|imexpr.output = \"'\${name}'.pl.fits[type=mask]\"|' $tempdir/\${name}_2.par
		$proto mskregions \@$tempdir/\${name}.par >>& /dev/null
		$images imexpr \@$tempdir/\${name}_2.par >>& /dev/null
		rm -fr \${name}.plorg.fits \${name}.obj.pl \${name}.obj  >>& /dev/null
	    else
		printf "No Objects provided in $omlist for \$name \n"
	    endif
	else
	    printf "No Object list found \$name.obj \n"
	endif
    endif

    foreach name2 ( \`ls *_c$chip.fits\` )
	set timefin = \`gethead \$name2 MJD\`
	if ( \`echo " \$timefin - \$timezero <= 0 " | bc\` ) then
	    continue
	else if ( \`echo " \$timefin - \$timezero > $TLATENT " | bc\` ) then
	    break
	endif
	mv -f \$name2.pl.fits \$name2.pl.tmp.fits
	cp $fsiraf/imexpr.par $tempdir/z\$name.par
	$sedi 's|imexpr.expr =|imexpr.expr = \"( (a \& 2) ? b+8 : b)\"|' $tempdir/z\$name.par
	$sedi 's|imexpr.a =|imexpr.a = \"'\$name'.pl.fits[1]\"|' $tempdir/z\$name.par
	$sedi 's|imexpr.b =|imexpr.b = \"'\$name2'.pl.tmp.fits[1]\"|' $tempdir/z\$name.par
	$sedi 's|imexpr.output =|imexpr.output = \"'\$name2'.pl.fits[type=mask]\"|' $tempdir/z\$name.par
	$images imexpr \@$tempdir/z\$name.par >>& /dev/null 
	wait
    end
    jobs
    wait
end
wait
exit 0
EOF
			chmod 777 $tempdir/asat_${chip}_$t0.csh
			$tempdir/asat_${chip}_$t0.csh &
		    end
		endif
	    endif


################################################################################
	    wait
#	    exit 0
################################################################################
################################################################################
	    set wait = ""
#	    echo -n waiting for input: ; set wait = $<
	    if ( $ilist == 1 || $ilist == 2 ) then
		if ( $ilist == 1 ) then
		    echo "Not interpolating Flat field data.  "
		    set interpolation2 = 0
		    echo "Not fitting background with surface.   "
		    set WAVE2 = 0
		    set SURF2 = 0,0,0
		    echo "Not Subtracting columns.   "
		    set SCOLS2 = 0
		    set SN2 = 10,100             # SN LIMITS 10,100 works well but sometimes slow, try 50,100 for faster performance.  
		    set CD2 = 2  
		    echo "Setting background combine flag to avsigclip 3-sigmareject upper 50 percent.  "
		    set bflag2 = 0.5
		    set ADVBACK2 = 2
		endif
		if ( $ilist == 2 ) then
		    set interpolation2 = $INTERPOLATION
		    set WAVE2 = $WAVELET2
		    set SURF2 = $SURFIT2
		    set SCOLS2 = $SCOLS2
		    set SN2 = $SNT2
		    set CD2 = $CID2
		    set bflag2 = $SBFLAG
		    set ADVBACK2 = $ADVBACK
		endif
		#############################################
		if ( $dome != 0 ) then
		    echo Dome flats.  Not creating object masks or performing astrometric distortion correction.
		    goto flats
		else
		    echo getting sky data
#		    foreach ch ( 1 2 3 4 )
		    foreach ch ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
			if ( $ilist == 1 ) then
			    cat $dest/$names[1]/zall.txt | grep c$ch > $tempdir/ztmp.txt
			endif
			if ( $ilist == 2 ) then
			    cat $dest/$names[2]/zsky.txt | grep c$ch > $tempdir/ztmp.txt
			endif
			if ( ! -e $tempdir/ztmp.txt || -z  $tempdir/ztmp.txt ) then
			    echo Failure for chip $ch, no assigned sky frames.  
			    echo Cannot access $tempdir/ztmp.txt , or its empty.
			    echo -n "Continue[y|n]:" ; set wait = $<
			    if ( $wait == n ) then
				exit 1
			    else
				continue
			    endif
			endif
			gethead -p @$tempdir/ztmp.txt MJD RA DEC FILTER > $tempdir/MJD_$ch.cat
		    end
		endif
		#############################################
		set DISKSP = `df $dest | awk '{if(NR==2) print $4}'`
	        set NIMG = `cat zmef.txt | wc -l`
		set MINSIZE2 = `echo "$MINSIZE * $NIMG" | bc`
		echo "Diskspace |  Number of images  | est. space needed"
 		echo $DISKSP         $NIMG              $MINSIZE2
		if ( `expr $DISKSP \< $MINSIZE2` ) then
		    echo Need $MINSIZE2 on destination disk, currently $DISKSP, exiting.
		    exit 1
		endif
		######################################## foreach
		foreach name (`cat zmef.txt`)
		    if ( -e ${name}_mef.cat && -e ${name}_mef.fits && -e ${name}_mef.weight.fits  ) then
			echo "${name}_mef.cat already exists!"
			continue
		    endif

		    set vflag = 1
		    rm -f $name*mef* >>& /dev/null 
		    set minarea2 = $MINAREA
		    set tBKJOBS = `awk 'BEGIN {print 1*'$BKJOBS'} '`
#		    set tBKJOBS = 24
		    if ( $xgrid == 0 || 0 ) then
			if ( 1 ) then
			    set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv|tcsh' | grep -E '${PROCESS}|sed|fsub.csh|mimsurfit' | wc -l`
#			    set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv|tcsh' | grep -E 'fsub.csh' | wc -l`
			    while ( $numbkjobs > $tBKJOBS )
				set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv|tcsh' | grep -E '${PROCESS}|sed|fsub.csh|mimsurfit' | wc -l`
    			        set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv|tcsh' | grep -E 'fsub.csh' | wc -l`
				printf "\rFSRED $numbkjobs current processes,  waiting for open slot..."
#				printf "\rFSRED $numbkjobs current fsub processes,  waiting for open slot..."
				sleep 5
			    end
			endif
			printf "First Pass Background Subtracting: %s  " $name
			$fsbin/fsub.csh `pwd` $tempdir $fsiraf $images $proto $name $bflag2 $NBACK2 $CSCALE $BKJOBS $gethead $xgrid $vflag $SMODE $SROWS2 $SCOLS2 $SURF2 $sex $WEIGHT $wt $WAVE2 $nproto $interpolation2 0 $HISIG $DEBUG $t0 $OBJTHRESH3 $BS2 $SEMESTER "$chips" $IOBJMASK2 $ADVBACK2 $minarea2 >& $name.sublog &
		    else
			xgridx $fsbin/fsub.csh `pwd` $tempdir $fsiraf $images $proto $name $bflag2 $NBACK2 $CSCALE $BKJOBS $gethead $xgrid $vflag $SMODE $SROWS2 $SCOLS2 $SURF2 $sex $WEIGHT $wt $WAVE2 $nproto $interpolation2 0 $HISIG $DEBUG $t0 $OBJTHRESH3 $BS2 $SEMESTER "$chips" $IOBJMASK2 $ADVBACK2 $minarea2 >& $name.sublog  &  
		    endif

		    sleep 0.25

		    if ( $DEBUG == 'yes' && $wait != 'Y' ) then
			wait
			echo ""
			echo -n "go on to next image ([y|Y]):" ; set wait = $<
		    endif
		end
		######################################## end
		set wait = ""
		wait
dereg:
		if ( $redo == skip ) then
		    set redo = n
		    goto flats
		endif

		cd $dest/$names[$ilist]
		if ( $ilist == 1 ) then
		    set HIDETECT2 = 10
		else if ( $ilist == 2) then
		    set HIDETECT2 = $HIDETECT
		endif
		wait

#		if (  $fpass == 1  && $ilist == 2  ) then
#		    printf "\nNot creating object masks, moving on to final combine.  \n"
#		    set PSCALE2 = $PSCALE
##		    goto finfp
		if ( 0 ) then

		else
		    printf "\nCreating 1st pass \n"
		    set INTER = $SCAMPI
		    set name = `head -n1 zall.txt`
		    set filter = `gethead $name filter`

		    if ( $filter == J || $filter == J1 || $filter == J2 || $filter == J3 || $filter == NB-1.18 ) then
			set AFILT = J
		    else if ( $filter == H || $filter == Hs || $filter == Hl ) then
			set AFILT = H
		    else if ( $filter == Ks || $filter == NB-2.09 ) then
			set AFILT = Ks
		    else
			echo Filter $filter not recognized using 2MASS J for reference photometry.  
			set AFILT = J
		    endif
#		    set AFILT = J
		    if ( $ASTREF_CATALOG == FILE )  then
			set AFILT = BLUEST
		    else if ( $ASTREF_CATALOG != 2MASS ) then
			set AFILT = REDDEST
		    endif


		    rm -f scamp.ahead >>&/dev/null
		    printf "\n  Solve Astrometry = $SOLVEAST2 : Catalog = $ASTREF_CATALOG : Filter = $AFILT : Output = $INTER \n"
		    set wcold = 0
		    sed 's|$|_mef.fits|' zmef.txt > ztmp.txt
		########################################
		    if ( -e fs_scamp.txt ) then
			echo fs_scamp.txt exists...
		    else
			$sed 's|$|_mef.cat|' zmef.txt > zcat.txt
#			$cat zcat.txt
			if ( $CD2 == 0 ) then
			    set CD2 = `$gethead -u @ztmp.txt FWHM_AVE | awk '{if($0 !~ "___"){ave=(ave*n+$2)/(n+1);n++}}END{if(ave>0.2 && n>3 ){printf "%5.2f\n",ave}else{print '$CID2'}}'`
			endif

			# REINITIALIZE REDO FOR SKYS AND TARGETS.
			if ( $ilist != 1 ) then
			    set redo = n
			endif
SCAMP1:
			echo Changing CID2 to $CD2 > fs_scamp.txt
			echo Starting Scamp... Groups within $FGROUP_RADIUS degrees. >> fs_scamp.txt
			set SOLVEAST3 = $SOLVEAST2
			set MOTYPE3 = $MOTYPE2
			set MATCH3 = $MATCH2
			if ( $redo == y ) then
			    set SOLVEAST3 = N
			endif
			if ( $redo == yy ) then
			    set SOLVEAST3 = N
			    set MATCH3 = N
			endif

			if ( $SOLVEAST3 == Y ) then
			    echo SOLVING DISTORTION USING SCAMP >> fs_scamp.txt
			else
			    echo USING ARCHIVE DISTORTION >> fs_scamp.txt
			endif
		    # IN EITHER CASE USE ARCHIVE SOLUTION AS INITIAL GUESS.   
			if ( ! -e $fsdist/distort_$filter.cat ) then
			    echo "No Archive Distortion found $fsdist/distort_$filter.cat  Exiting..."
			    exit 1
			else
			    @ dneflag = 0
			    foreach name  ( `cat zcat.txt` )
				echo -n "$name ... "
				if ( -e $name ) then
				    echo "  exists"  
				else
				    echo "  dne"
  				    @ dneflag ++
				endif
				set name = $name:s/.cat//
				rm -fr $name.ahead >>& /dev/null
				foreach chip ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` ) 
				    printf "CHIP    = $chip \n" >> $name.ahead
				    if ( 0 ) then
					printf "CRPIX1  = %g\nCRPIX2  = %g\nCRVAL1  = %g\nCRVAL2  = %g\nCD1_1   = %g\nCD1_2   = %g\nCD2_1   = %g\nCD2_2   = %g\n"\
					`gethead -x $chip $name.fits CRPIX1 CRPIX2 CRVAL1 CRVAL2 CD1_1 CD1_2 CD2_1 CD2_2` >> $name.ahead
					if ( $DISTORT_DEGREES == 3 ) then
					    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'CRPIX|A_|B_' >> $name.ahead
					endif
					if ( $DISTORT_DEGREES == 2 ) then
					    echo "A_ORDER = 2" >> $name.ahead
					    echo "B_ORDER = 2" >> $name.ahead
					    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'CRPIX|A_|B_' | grep -v -E '_2_1|_1_2|_3_0|_0_3|_ORDER' >> $name.ahead
					endif
				    else
					printf "CRPIX1  = %g\nCRPIX2  = %g\nCRVAL1  = %g\nCRVAL2  = %g\nCD1_1   = %g\nCD1_2   = %g\nCD2_1   = %g\nCD2_2   = %g\n"\
					`gethead -x $chip $name.fits CRPIX1 CRPIX2 CRVAL1 CRVAL2 CD1_1 CD1_2 CD2_1 CD2_2` >> $name.ahead
					if ( $DISTORT_DEGREES == 3 ) then
					    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'A_|B_' >> $name.ahead
					endif
					if ( $DISTORT_DEGREES == 2 ) then
					    echo "A_ORDER = 2" >> $name.ahead
					    echo "B_ORDER = 2" >> $name.ahead
					    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'A_|B_' | grep -v -E '_2_1|_1_2|_3_0|_0_3|_ORDER' >> $name.ahead
					endif
				    endif
				    printf "END             \n" >> $name.ahead
				end
				mv $name.ahead $name.aaa
				$fsdist:h:h/pvsip -f $name.aaa -v 2 > $name.ahead
				rm -f $name.aaa >>& /dev/null 
			    end
			    if ( $dneflag != 0 ) then
				echo "Some mef.cat files do not appear to exist.   Exiting.  "
				exit 1
			    endif
			endif


			$scamp @zcat.txt -c $fsast/scamp.config -FGROUP_RADIUS $FGROUP_RADIUS -MATCH $MATCH3 -SOLVE_ASTROM $SOLVEAST3 -SOLVE_PHOTOM Y -ASTREF_BAND $AFILT -SN_THRESHOLDS $SN2 -ASTREF_WEIGHT $ASW -CROSSID_RADIUS $CD2 -MOSAIC_TYPE $MOTYPE3 -STABILITY_TYPE $STABILITY_TYPE -DISTORT_KEYS $DISTORT_KEYS -DISTORT_GROUPS $DISTORT_GROUPS -DISTORT_DEGREES $DISTORT_DEGREES -CHECKPLOT_DEV $INTER -REF_SERVER $CDSCLIENT -POSITION_MAXERR $POSITION_MAXERR -POSANGLE_MAXERR $POSANGLE_MAXERR -ASTRCLIP_NSIGMA $ASTRCLIP_NSIGMA -PHOTCLIP_NSIGMA $PHOTCLIP_NSIGMA -FLAGS_MASK $FLAGS_MASK -ASTRINSTRU_KEY $ASTRINSTRU_KEY -ASTREF_CATALOG $ASTREF_CATALOG -ASTREFCAT_NAME $ASTREFCAT_NAME -VERBOSE_TYPE FULL >>& fs_scamp.txt &
# -VERBOSE_TYPE FULL
		# PSC NULL XWIN

		# BLUE CROSSES = DETECTED SOURCES
		# RED SQUARES = REFERENCE CATALOG: NOT USED
		# GREEN DIAMONDS = REFERENCE CATALOG: MATCHED
		# BLACK DOTS =?? DETECTED SOURCES - REJECTED ??
		# FILLED BLACK DOTS =?? DETECTED SOURCES - REJECTED ??
			   
			set lbid = $! # last job ID
			echo $lbid
			printf "\n\n\n\n-------------------------------------------------\n\n"
			sleep 2
			while ( `ps -c | grep $lbid` != "" )
			    set wc = `cat  fs_scamp.txt | wc -l`
			    tail -n `echo "$wc - $wcold" | bc` fs_scamp.txt
			    set wcold = $wc
			    sleep 1
			end
			wait
			set wc = `cat  fs_scamp.txt | wc -l`
			tail -n `echo "$wc - $wcold" | bc` fs_scamp.txt
			if ( `grep WARNING fs_scamp.txt | grep -v "WARNING: All sources have non-zero flags" | grep -v "WARNING: No valid source found" | grep -v "WARNING: FLAGS parameter not found" | wc -l ` > 0 || `grep Error fs_scamp.txt | wc -l ` > 0 ) then
			    echo Cannot Find Distortion, too few sources.   Continuing without distortion. 
			    if ( $inter || $dwait ) then
				echo -n "Continue Anyways? ([y|n|redo]):" ; set wait = $<
			    else
				if ( $redo == n ) then
				    set wait = redo
				else
				    set redo = n
				    set wait = y
				endif
			    endif

			    if ( $wait == 'n' ) then
				rm -f fs_scamp.txt
				echo Exiting
				exit 1
			    else if ( $wait == 'redo' ) then
				printf "Setting SOLVEAST3 = N \n"
				set redo = y
				goto SCAMP1
			    else if ( $wait == 'redo2' ) then
				printf "Setting SOLVEAST3 = N \n"
				set redo = yy
				goto SCAMP1
			    endif
			    mv fs_scamp.txt fs_scamp.bak
			    echo "----- 1 field group found:" > fs_scamp.txt
			    echo " Group  1: 0 fields" >> fs_scamp.txt
			endif
		    endif
		########################################
		# Combine images for each group detected
		    set ngroups = `awk '{if($0 ~ "field" && $0 ~ "group" && $0 ~ "found" ) print $2}' fs_scamp.txt`
		    set nphot = `awk '{if($0 ~ "instrument" && $0 ~ "found" && $0 ~ "photometry" ) print $2}' fs_scamp.txt`
#		    echo "nfilters = $nphot"
#		    echo "ngroups = $ngroups"
		    set phot = 0
		    while ( $phot < $nphot ) 
			@ phot ++
			set filter = `grep -A1 "Instrument P$phot" fs_scamp.txt | grep FILTER | cut -d"'" -f2`
			echo "filter = $filter"
			set group = 0
			while ( $group < $ngroups ) 
			    @ group ++

			    set coadd = fs_mask_${filter}_${group}.tile.mos.fits
			    set coadde = fs_mask_${filter}_${group}.tile.exp.pl.fits
			    set coaddw = fs_mask_${filter}_${group}.tile.exp.fits
			    set coaddm = fs_mask_${filter}_${group}.tile.msk.fits
			    set coadds = fs_mask_${filter}_${group}.tile.sig.fits
			    set coaddb = fs_mask_${filter}_${group}.tile.bpm.pl.fits

			    if ( -e $coadd ) then
				echo $coadd exists...
				goto qphot
			    endif

			    rm -f zcat_${filter}_${group}.txt >>& /dev/null
			    rm -f zcata_${filter}_${group}.txt >>& /dev/null
			    rm -f $tempdir/amask_${filter}_${group}.weight.txt
			    set nfields = `awk '\! /\^/ {sub(":","",$2);if($1 ~ "Group" && $2 == "'$group'" && $4 ~ "fields" ) print $3}' fs_scamp.txt`

			    printf "\nGroup ${group}: $nfields fields \n"

			    if ( $nfields != 0 ) then
				foreach mef ( `awk '\! /\^/ {sub(":","",$2);if($1 ~ "Group" && $2 == "'$group'" && $4 ~ "fields" ){ num = $3;i=NR}else{if(NR-i <= num && $3 == "P'$phot'" ){ print $1 }}}' fs_scamp.txt`)
				    ls ${mef:r}.fits >> zcat_${filter}_${group}.txt
				    ls ${mef:r:s/_mef/_/}c?.fits.sub.fits >> zcata_${filter}_${group}.txt
				end
			    else
				ls *mef.fits > zcat_${filter}_${group}.txt
				ls *c?.fits.sub.fits > zcata_${filter}_${group}.txt
			    endif
			    set nobs = `cat zcat_${filter}_${group}.txt | wc -l`
			    printf "FILTER P$phot nobs = $nobs\n"
#exit 0

			# XGRID DOES NOT WORK WELL WITH SWARP, JUST RUN ON SINGLE MACHINE. 
			    if ( $ilist == 1 ) then
				set PSCALE3 = 0.35
				set RESAMP3 = BILINEAR
				set FSCALEKEY3 = $FSCALEKEY
				set OVER3 = 0
				set FCAL3 = FIXED  # equal to unity
				set SKYSUB3 = Y
				set TRANSIENT2 = 10  # look for satellite trails.  
			    else
				if ( $autoscale ) then
				    set PSCALE3 = `echo "scale=2; $CD2 / 2.5" | bc -l`
				    if ( `echo "$PSCALE3 <= 0.16" | bc` ) then
					set PSCALE3 = $PSCALE2 
				    endif
				endif
				set RESAMP3 = $RESAMP2
				set FSCALEKEY3 = $FSCALEKEY
				set OVER3 = $OVERSAMPLING2
				set FCAL3 = $FCAL2
				set SKYSUB3 = $SKYSUB2
				set TRANSIENT2 = $TRANSIENT
			    endif

#			    set CENTYPE = MANUAL
#			    set CENTER = 3.528856,-30.38927
#			    set IMAGE_SIZE = 0


			    if ( -e fs_swarp_${filter}_${group}.txt ) then
				echo Ran Swarp already on group $group, remove fs_swarp_${filter}_${group}.txt file to re-run resampling.  
			    else
				echo RAN SWARP ON GROUP $group > fs_swarp_${filter}_${group}.txt
				$swarp @zcat_${filter}_${group}.txt -c $fsast/swarp.config -WEIGHT_TYPE MAP_WEIGHT -RESCALE_WEIGHTS N -COMBINE N -COMBINE_TYPE $CTYPE2 -SUBTRACT_BACK $SKYSUB3 -BACK_SIZE $BS2 -BACK_FILTERSIZE $BFS2 -PIXEL_SCALE $PSCALE3 -CENTER_TYPE $CENTYPE -CENTER $CENTER -IMAGE_SIZE $IMAGE_SIZE -DELETE_TMPFILES N -BLANK_BADPIXELS N -RESAMPLE Y -RESAMPLING_TYPE $RESAMP3 -PROJECTION_TYPE TAN -CELESTIAL_TYPE NATIVE -FSCALASTRO_TYPE $FCAL3 -INTERPOLATE N -OVERSAMPLING $OVER3 -FSCALE_KEYWORD $FSCALEKEY3 -IMAGEOUT_NAME $coadd -WEIGHTOUT_NAME $coaddw -VERBOSE_TYPE FULL >>& fs_swarp_${filter}_${group}.txt
			    endif
			
			# MAKE WEIGHT/ZERO LIST
			    if ( $ilist == 1 ) then
				set wt2 = 0
			    else
				set wt2 = $wt
			    endif

			    echo Setting/getting individual image information...
			# CREATE INPUT LISTS FOR IMCOMBINE
			    rm -fr zcatb_${filter}_${group}.txt >>& /dev/null
			    foreach var ( `cat zcat_${filter}_${group}.txt` )
				ls ${var:t:r}*resamp.fits | tee -a  zcatb_${filter}_${group}.txt > $var.list
				if ( $status ) then
				    echo Could not create list for $var
				    exit 1
				endif
				echo Weight flag: $wt2
				$gethead -p -u @$var.list MODE FWHM_AVE EFFGAIN FLXSCALE FLASCALE
#				$sethead @$var.list GWEIGHT=`$gethead -p -u @$var.list MODE FWHM_AVE EFFGAIN FLXSCALE | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1 || $5<0.1 || $5>10 ){a=a}else{a=a+$4/$5*10000000/($2*$3*$3);i++}}END{if(i==0){print 4000}else{print a/i} }'`
				$sethead @$var.list GWEIGHT=`$gethead -p -u @$var.list MODE FWHM_AVE EFFGAIN FLXSCALE STDDEV2 | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1  ){a=a}else{a=a+10000000/($5*$6*$6*$3*$3);i++}}END{if(i==0){print 4000}else{print a/i} }'`

#				rm -fr $var.list >>& /dev/null
			    end
			# SET CORRECT BPM
			    foreach name2 ( `cat zcatb_${filter}_${group}.txt` )
#				$sethead $name2 WEIGHT=`$gethead -p -u $name2 MODE FWHM_AVE EFFGAIN FLXSCALE | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1 || $5<0.1 || $5>10 ){print 4000}else{print $4/$5*10000000/($2*$3*$3)}}'`
				$sethead $name2 WEIGHT=`$gethead -p -u $name2 MODE FWHM_AVE EFFGAIN FLXSCALE STDDEV2 | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1  ){print 4000}else{print 10000000/($5*$6*$6*$3*$3)}}'`
				$sethead $name2 BPM="$name2:s/.fits/.weight.fits/"
			    end



			# IF FLXSCALE IS FAR FROM UNITY SET IT TO ZERO (WEIGHT WILL ALSO BE SET TO ZERO)
			#  DONT CARE ABOUT WEIGHT SINCE FIRST PASS IS A MEDIAN.  
			    $gethead -p -u @zcatb_${filter}_${group}.txt MJDAVE MEAN MODE STDDEV FWHM_AVE WEIGHT GWEIGHT SATURATE FLXSCALE FLASCALE CHIP | awk '{$10=($10<0.1||$10>10)?1:$10;print}' > $tempdir/$coadd.weight_${filter}_${group}.txt

			# UPDATE .sub.fits HEADERS TO INCLUDE NEW SCALE FACTOR for remap and diff construction. 
			    @ num = 1
			    foreach name2 ( `cat zcata_${filter}_${group}.txt` ) 
				if ( $ilist == 1 ) then
				    $sethead $name2 FLXSCALE=`cat $tempdir/$coadd.weight_${filter}_${group}.txt | awk '{if(NR=='$num'){print 1.0}}'`
				else
				    $sethead $name2 FLXSCALE=`cat $tempdir/$coadd.weight_${filter}_${group}.txt | awk '{if(NR=='$num'){print $10*$11}}'`
				endif
				@ num ++
			    end
			# set weight to zero any image whose weight is less than half the average upper fourth.
			    if ( 0 ) then
				set LWEIGHT2 = $LWEIGHT
			    else
				set LWEIGHT2 = 0.0     # DON'T THROW OUT ANY IMAGES DURING 1ST PASS.   THEY ARE NEEDED FOR FULL FIELD DETECTION AND MASKING OUT TO THE EDGES.
			    endif
			    set num = `cat $tempdir/$coadd.weight_${filter}_${group}.txt | wc -l`
			    set num = `echo "$num / 4 + 1" | bc`
			    set avew = `sort -k8 -gr $tempdir/$coadd.weight_${filter}_${group}.txt | head -n $num | awk '{rave = ( (NR-1)*rave + $8 ) / (NR) }END{print rave}'`
			    printf "\n\naverage weight of upper quartile = $avew , lower limit = $LWEIGHT2 \n"
			    awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print $1} }' $tempdir/$coadd.weight_${filter}_${group}.txt > zcatb_${filter}_${group}.txt
			    awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print $7} }' $tempdir/$coadd.weight_${filter}_${group}.txt > $tempdir/$coadd.weight2_${filter}_${group}.txt
			    if ( $ilist == 1 ) then
				awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print 1.0} }' $tempdir/$coadd.weight_${filter}_${group}.txt > $tempdir/$coadd.scale2_${filter}_${group}.txt
			    else
				awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print $10} }' $tempdir/$coadd.weight_${filter}_${group}.txt > $tempdir/$coadd.scale2_${filter}_${group}.txt
			    endif
			    awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print '$FUDGE'*($3-$4)} }' $tempdir/$coadd.weight_${filter}_${group}.txt > $tempdir/$coadd.zero2_${filter}_${group}.txt
			    awk '{if( $8 <  '$LWEIGHT2'*'$avew' ){printf "%s rejected, weight = %10.0f \n",$1,$8 } }' $tempdir/$coadd.weight_${filter}_${group}.txt
			    printf "\n----------------------\n"

			    set fwhmtxt = fs_fwhm_${group}_${filter}_0_0.txt
			    echo "Getting Image information for $fwhmtxt"
			    awk '{print }' $tempdir/$coadd.weight_${filter}_${group}.txt > $fwhmtxt
			    if ( -e $sm ) then
				$fsbin/fssm_fwhm.csh $avew $LWEIGHT2 `pwd` $fwhmtxt  #>>& /dev/null
			    endif 
			# IF FLAT FIELD USE IMCOMBINE.   
			    if ( $ilist == 1 || $IMCOMBINE2 == YES ) then
				cp $fsiraf/imcombine.par $tempdir/$coadd.par
				sedi 's|imcombine.input =|imcombine.input = \"\@'`pwd`/zcatb_${filter}_${group}.txt'\"|' $tempdir/$coadd.par
				sedi 's|imcombine.output =|imcombine.output = \"'$coadd'\"|' $tempdir/$coadd.par
				sedi 's|imcombine.expmasks = \"\"|imcombine.expmasks = \"'$coadde'[type=mask]\"|' $tempdir/$coadd.par
				sedi 's|imcombine.bpmasks = \"\"|imcombine.bpmasks = \"'$coaddb'[type=mask]\"|' $tempdir/$coadd.par
				sedi 's|imcombine.sigmas = \"\"|imcombine.sigmas = \"'$coadds'\"|' $tempdir/$coadd.par
			    # USE AVERAGE, BETTER AT FIRST MOMENT MEASUREMENT, USE MEDIAN TO CLIP TRANSIENTS.
				sedi 's|imcombine.combine =|imcombine.combine = \"median\"|' $tempdir/$coadd.par
				sedi 's|imcombine.reject = \"none\"|imcombine.reject = \"none\"|' $tempdir/$coadd.par
				sedi 's|imcombine.nlow = 2|imcombine.nlow = 0.25|' $tempdir/$coadd.par
				sedi 's|imcombine.nhigh = 2|imcombine.nhigh = 0.25|' $tempdir/$coadd.par
				sedi 's|imcombine.nkeep = 1|imcombine.nkeep = 3|' $tempdir/$coadd.par
				sedi 's|imcombine.masktype = \"none\"|imcombine.masktype = \"\!BPM badvalue\"|' $tempdir/$coadd.par
				sedi 's|imcombine.maskvalue = \"0\"|imcombine.maskvalue = \"0\"|' $tempdir/$coadd.par
				sedi 's|imcombine.offsets = \"none\"|imcombine.offsets = \"wcs\"|' $tempdir/$coadd.par
				if ( $wt == 1) then
				    sedi 's|imcombine.weight = \"none\"|imcombine.weight = \"\@'$tempdir''$coadd'.weight2'_${filter}_${group}'.txt\"|' $tempdir/$coadd.par
				endif
			    # FOR EXPOSURE MAP, USE EFFGAIN (ORIGEXP*NLOOPS*GAIN).   NO, use exposure
				sedi 's|imcombine.expname = \"\"|imcombine.expname = \"exposure\"|' $tempdir/$coadd.par
				sedi 's|imcombine.zero = \"none\"|imcombine.zero = \"\@'$tempdir''$coadd'.zero2'_${filter}_${group}'.txt\"|' $tempdir/$coadd.par
			    # need to scale here, SWARP does NOT do it during the resampling process.
#			    sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"\!'$FSCALEKEY'\"|' $tempdir/$coadd.par
				sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"\@'$tempdir''$coadd'.scale2'_${filter}_${group}'.txt\"|' $tempdir/$coadd.par
				sedi 's|imcombine.lthreshold = INDEF|imcombine.lthreshold = -65000|' $tempdir/$coadd.par
				sedi 's|imcombine.hthreshold = INDEF|imcombine.hthreshold = 650000|' $tempdir/$coadd.par
#				setenv imcombine_maxmemory 250000000   # default IRAF  250MB
#				setenv imcombine_maxmemory 1000000000   # default IRAF  1GB
				setenv imcombine_maxmemory 55000000000   # default IRAF  1GB
				setenv imcombine_option 1
				echo Running imcombine... memory: $imcombine_maxmemory $imcombine_option nimages: `cat zcata_${filter}_${group}.txt | wc -l `
#				echo Running imcombine... memory: $imcombine_maxmemory
				# NOTE IN IRAF: to see what imcombine actually sets as memory:
				#  edit file /iraf/iraf/pkg/images/immatch/src/imcombine/src/icombine.x 
				# to include at line 314:
#	    call printf("maxmemory is: %10d\n")
#	    	 call pargi(maxmemory)
#
#	    call printf("memory is: %10d\n")
#	    	 call pargi(memory)
#
#	    call printf("buffer is: %10d\n")
#	    	 call pargi(bufsize)
#
#	    call printf("Fudge is: %10.1f\n")
#	    	 call pargr(FUDGE)
				# and recompile imcombine using:
				# cd $iraf
				# mkpkg macintel
				# cd $iraf/pkg
				# mkpkg

				rm -fr $coaddb $coadde $coaddw >>& /dev/null
				$images imcombine \@$tempdir/$coadd.par

				if ( $status || ! -e $coadd ) then
				    echo "Failed... Exiting"
				    exit 1
				endif
				wait

			    # CORRECT FOR ZP, IRAF SCALES TO FIRST INPUT IMAGE, SO MUST MULTIPLY BY THE FIRST SCALE TO GET ON COMMON ZP. 
				if ( 1 && $ilist != 1 ) then
				    echo Correcting for ZP shift `gethead $coadd FLXSCALE | awk '{printf "%5.2f\n",$1}'` and astrometric resampling `gethead $coadd FLASCALE | awk '{printf "%5.2f\n",$1}'`
				    cp $fsiraf/imexpr.par $tempdir/$coadd.par2
				    mv $coadd ztmp.fits
				    sedi 's|imexpr.expr =|imexpr.expr = \"a*a.FLXSCALE*a.FLASCALE\"|' $tempdir/$coadd.par2
				    sedi 's|imexpr.a =|imexpr.a = \"ztmp.fits\"|' $tempdir/$coadd.par2
				    sedi 's|imexpr.output =|imexpr.output = \"'$coadd'\"|' $tempdir/$coadd.par2
				    $images imexpr \@$tempdir/$coadd.par2
				    rm -fr ztmp.fits
				endif

				echo deleting un-needed header keywords
				foreach key ( SOFTNAME SOFTVERS SOFTDATE SOFTAUTH SOFTINST COMBINET COMIN1 COMIN2 FLXSCALE FLASCALE BACKMEAN ORIGFILE INTERPF BACKSUBF BACKTYPE BACKSIZE BACKFSIZ WCSDIM CDELT1 CDELT2 LTM1_1 LTM2_2 WAT0_001 WAT1_001 WAT2_001 ) 
				    if ( `gethead -u $coadd $key` != ___ ) then
					delhead $coadd $key
				    endif
				end
			    # MAKE WEIGHT IMAGE
				if ( ! -e $coaddw  && 1 ) then
				    echo making weight image
				    cp $fsiraf/imexpr.par $tempdir/$coadd.par2
				    if ( `gethead -u $coadde MASKSCAL` != ___ ) then
					sedi 's|imexpr.expr =|imexpr.expr = \"a * a.MASKSCAL + a.MASKZERO \"|' $tempdir/$coadd.par2
				    else
					sedi 's|imexpr.expr =|imexpr.expr = \"a \"|' $tempdir/$coadd.par2
				    endif
				    sedi 's|imexpr.a =|imexpr.a = \"'$coadde'[1]\"|' $tempdir/$coadd.par2
				    sedi 's|imexpr.output =|imexpr.output = \"'$coaddw'\"|' $tempdir/$coadd.par2
				    $images imexpr \@$tempdir/$coadd.par2
				endif
			    else
				$swarp @zcat_${filter}_${group}.txt -c $fsast/swarp.config -WEIGHT_TYPE MAP_WEIGHT -RESCALE_WEIGHTS N -COMBINE Y -COMBINE_TYPE $CTYPE2 -SUBTRACT_BACK $SKYSUB3 -BACK_SIZE $BS2 -BACK_FILTERSIZE $BFS2 -PIXEL_SCALE $PSCALE3 -CENTER_TYPE $CENTYPE -CENTER $CENTER -IMAGE_SIZE $IMAGE_SIZE -DELETE_TMPFILES N -BLANK_BADPIXELS N -RESAMPLE Y -RESAMPLING_TYPE $RESAMP3 -PROJECTION_TYPE TAN -CELESTIAL_TYPE NATIVE -FSCALASTRO_TYPE $FCAL3 -INTERPOLATE N -OVERSAMPLING $OVER3 -FSCALE_KEYWORD $FSCALEKEY3 -IMAGEOUT_NAME $coadd -WEIGHTOUT_NAME $coaddw -VERBOSE_TYPE QUIET
				if ( ( ! -e $coadde || ! -e $coaddb ) && $quick == 0  ) then
				    echo CREATING MASKS FOR DETECT...
				    rm -fr $coadde
				    rm -fr $coaddb
				    cp $fsiraf/imexpr.par $tempdir/$coadd.par
#				    sedi 's|imexpr.expr =|imexpr.expr = \"( int(1000*a) )\"|' $tempdir/$coadd.par
				    sedi 's|imexpr.expr =|imexpr.expr = \"( int(1*a) )\"|' $tempdir/$coadd.par
				    sedi 's|imexpr.a =|imexpr.a = \"'$coaddw'\"|' $tempdir/$coadd.par
				    sedi 's|imexpr.output =|imexpr.output = \"'$coadde'[type=mask]\"|' $tempdir/$coadd.par
				    $images imexpr \@$tempdir/$coadd.par
				    cp $fsiraf/imexpr.par $tempdir/$coadd.par2
#				    sedi 's|imexpr.expr =|imexpr.expr = \"( int(1000*a)==0 ? 1 : 0 )\"|' $tempdir/$coadd.par2
				    sedi 's|imexpr.expr =|imexpr.expr = \"( int(1*a)==0 ? 1 : 0 )\"|' $tempdir/$coadd.par2
				    sedi 's|imexpr.a =|imexpr.a = \"'$coaddw'\"|' $tempdir/$coadd.par2
				    sedi 's|imexpr.output =|imexpr.output = \"'$coaddb'[type=mask]\"|' $tempdir/$coadd.par2
				    $images imexpr \@$tempdir/$coadd.par2
				    if ( $status ) then
					echo Something went wrong with creating MASKS.   Exiting...
					exit 1
				    endif
				endif
			    endif
			# UPDATE HEADER KEYWORDS
			    echo Finding image parameters for $coadd
			    set EXP = `gethead $coadd EXPOSURE`
			    set FLXSCALE = `gethead -u $coadd FLXSCALE`
			    if ( $FLXSCALE == ___ ) then
				set FLXSCALE = 1.0
			    endif
			    set FWHM = `awk 'BEGIN {ave=0;i=0}{{if( $8 >= '$LWEIGHT2'*'$avew'){ave=ave+($6);i++}}}END{if(i>0){print ave/i}else{print 0}}' $fwhmtxt `
			    set BACK = `awk 'BEGIN {ave=0;i=0}{{if( $8 >= '$LWEIGHT2'*'$avew'){ave=ave+($4);i++}}}END{if(i>0){print ave/i/'$EXP'*('$PSCALE3'/0.16)**2}else{print 0}}' $fwhmtxt `
			    set BACKSIG = `awk 'BEGIN {ave=0;i=0}{{if( $8 >= '$LWEIGHT2'*'$avew'){ave=ave+($5);i++}}}END{if(i>0){print ave/i*('$PSCALE3'/0.16)**1}else{print 0}}' $fwhmtxt `
			    set SATURATE = `awk 'BEGIN {ave=0;i=0}{{if( $8 >= '$LWEIGHT2'*'$avew'){ave=ave+($9);i++}}}END{if(i>0){print ave/i}else{print 0}}' $fwhmtxt `
			    set MJDAVE = `awk 'BEGIN {ave=0;i=0}{{if( $8 >= '$LWEIGHT2'*'$avew'){ave=ave+($2*$8);i=i+$8}}}END{if(i>0){printf "%11.5f\n",ave/i}else{print 0}}' $fwhmtxt `
			    echo Setting image header keywords
			    sethead $coadd SCALE=$PSCALE3 / "Arc-seconds per pixel"
			    sethead $coadd BACKGND=$BACK / "Average Background Rate [ADU/s] native pixels"
			    sethead $coadd BACKSIG=$BACKSIG / "STDEV of Background [ADU/s] native pixels"
			    sethead $coadd SATURATE=$SATURATE / "[ADU/s] resampled pixels"
			    sethead $coadd FWHM_AVE=$FWHM 
			    sethead $coadd MJDAVE=$MJDAVE / "Weighted MJD"
qphot:
#			end # FOREACH GROUP
#		    end # FOREACH PHOT


#		endif # FIRST PASS
		if ( 1 ) then
		    echo "Removing all resampled images..."
		    rm -fr *resamp* >>& /dev/null
		endif
	    ########################################  create mask
	    ######################################## mask.pl
detect:
#		set phot = 0
#		set group = 0
#		while ( $phot < $nphot ) 
#		    @ phot ++
#		    while ( $group < $ngroups ) 
#			@ group ++

			set coadd =  fs_mask_${filter}_${group}.tile.mos.fits
			set coaddo = fs_mask_${filter}_${group}.tile.mos.pl.fits
			set coadde = fs_mask_${filter}_${group}.tile.exp.pl.fits
			set coaddw = fs_mask_${filter}_${group}.tile.exp.fits
			set coaddm = fs_mask_${filter}_${group}.tile.msk.fits
			set coaddb = fs_mask_${filter}_${group}.tile.bpm.pl.fits

			if ( -e $coaddo ) then
			    printf "\n$coaddo already exists\n"
			    goto masko
#			    continue
			endif

			printf "\nCreating $coaddo\n"
			if ( $ilist == 1) then
			    set agrow = 2.5
			else if ( $filter == J || $filter == J1 || $filter == J2 || $filter == J3 || $filter == NB-1.18 ) then
			    set agrow = $AREAGROW
			else if ( $filter == H || $filter == Hs || $filter == Hl ) then
			    set agrow = $AREAGROW
			else if ( $filter == Ks || $filter == NB-2.09 ) then
			    set agrow = $AREAGROW
			else
			    set agrow = $AREAGROW
			endif
			awk '{print}' <<EOF > $tempdir/zmask_${group}_$t0.csh
#!/bin/csh
    cd `pwd`
    $cp $fsiraf/detect.par $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.images = \"\"|detect.images = \"'${coadd}'\"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.objmasks = \"\"|detect.objmasks = \"'${coaddo}'[type=mask]\"|' $tempdir/zdet_${filter}_${group}.par
# comment exps out if experience arithmetic exceptions.
    $sedi 's|detect.exps = \"\"|detect.exps = \"'${coadde}'[1]\"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.masks = \"\"|detect.masks = \"'${coaddb}'[1]\"|' $tempdir/zdet_${filter}_${group}.par
    rm -f fs_mask_${filter}_${group}.bsky.fits
    rm -f fs_mask_${filter}_${group}.bsig.fits
    $sedi 's|detect.ngrow = 2|detect.ngrow = 32|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.agrow = 2.|detect.agrow = $agrow|' $tempdir/zdet_${filter}_${group}.par
# DETECTION PARAMETERS
    $sedi 's|detect.skytype = \"fit\"|detect.skytype = \"block\"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.fitxorder = 2|detect.fitxorder = 1|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.fityorder = 2|detect.fityorder = 1|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.convolve = \"bilinear 5 5\"|detect.convolve = \"gauss 3 3 1 1 \"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.minpix = 6|detect.minpix = 4|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.hsigma = 1.5|detect.hsigma = $HIDETECT2|' $tempdir/zdet_${filter}_${group}.par
# NO REASON TO LOOK FOR NEGATIVE FEATURES
    if ( 0 ) then
	$sedi 's|detect.ldetect = no|detect.ldetect = yes|' $tempdir/zdet_${filter}_${group}.par
	$sedi 's|detect.lsigma = 10.|detect.lsigma = $HIDETECT2|' $tempdir/zdet_${filter}_${group}.par
    endif

    $nproto detect @$tempdir/zdet_${filter}_${group}.par
wait
exit 0
EOF
			chmod 777 $tempdir/zmask_${group}_$t0.csh
			if ( $xgrid == 0 ) then
			    $tempdir/zmask_${group}_$t0.csh
			else
			    xgridx $tempdir/zmask_${group}_$t0.csh
			endif
			if ( ! -e $coaddo ) then
			    echo Something went wrong during DETECT... Exiting.
			    exit 1
			endif
# ADD CUSTOM OBJECT MASK
#			if ( $IOBJMASK == YES ) then
			if ( 1 ) then
			    echo "Searching for existing object masks."
			    rm -fr amsk_${filter}_${group}.obj
			# off image not good enough, if slightly offset would still like to mask edge of object. 
			    set naxis = `gethead $coadd NAXIS1 NAXIS2`
			    set omlist = $fsbin/mask.objects
			    set omlist2 = $fsbin/mask2.objects
			    awk '\!/#/ {print $1,$2,$3,$4,$5}' $omlist > $omlist2

			    if ( -e $omlist2 ) then
				sky2xy $coadd @$omlist2 | paste $omlist2 - | awk ' ! /offscale/ {if( ($10>-$4 && $10<$4+'$naxis[1]') && ($11>-$4 && $11<$4+'$naxis[2]') ){printf "# %s \ncircle (%f, %f, %f) \n",$5,$10,$11,$4/'$PSCALE3'}}' >> amsk_${filter}_${group}.obj
			    endif
			    if ( -e amsk_${filter}_${group}.obj ) then
				if ( ! -z amsk_${filter}_${group}.obj ) then
				    printf "\nMasking known object(s) at:\n        X    Y    RAD  \n"
				    cat amsk_${filter}_${group}.obj
				    mv amsk_${filter}_${group}.obj amsk_${filter}_${group}.obj.old
				    awk ' \! /#/ {print}' amsk_${filter}_${group}.obj.old > amsk_${filter}_${group}.obj ; rm amsk_${filter}_${group}.obj.old
				    rm -fr fsorg_mask_${filter}_${group}.tile.pl.fits fsreg_mask_${filter}_${group}.tile.pl >>& /dev/null
				    mv $coaddo fsorg_mask_${filter}_${group}.tile.pl.fits
				    cp $fsiraf/mskregions.par $tempdir/mask_${filter}_${group}.par
				    sedi 's|mskregions.regions = |mskregions.regions = \"amsk'_${filter}_${group}'.obj\"|' $tempdir/mask_${filter}_${group}.par
				    sedi 's|mskregions.masks = \"\"|mskregions.masks = \"fsreg_mask'_${filter}_${group}'.tile.pl\"|' $tempdir/mask_${filter}_${group}.par
				    # 2^23 = 8388608  bits 24-27 are reserved for detect.  hopefully there will not be more than 2^23 sources detected.    
				    sedi 's|mskregions.regval = 2|mskregions.regval = 8388608|' $tempdir/mask_${filter}_${group}.par
				    sedi 's|mskregions.refimages = \"\"|mskregions.refimages = \"'$coadd'\"|' $tempdir/mask_${filter}_${group}.par
				    cp $fsiraf/imexpr.par $tempdir/mask2_${filter}_${group}.par
				    sedi 's|imexpr.expr =|imexpr.expr = \"( a + b )\"|' $tempdir/mask2_${filter}_${group}.par
				    sedi 's|imexpr.a =|imexpr.a = \"fsorg_mask'_${filter}_${group}'.tile.pl.fits[1]\"|' $tempdir/mask2_${filter}_${group}.par
				    sedi 's|imexpr.b =|imexpr.b = \"fsreg_mask'_${filter}_${group}'.tile.pl\"|' $tempdir/mask2_${filter}_${group}.par
				    sedi 's|imexpr.output =|imexpr.output = \"'${coaddo}'[type=mask]\"|' $tempdir/mask2_${filter}_${group}.par
				    $proto mskregions \@$tempdir/mask_${filter}_${group}.par
				    $images imexpr \@$tempdir/mask2_${filter}_${group}.par
				else
				    printf "No Objects found in $omlist \n"
				endif
			    else
				printf "No Object list found \n"
			    endif
			endif
masko:
			    if ( -e $coaddm ) then
				echo $coaddm already exists
			    else
				echo making mask image
				cp $fsiraf/imstat.par $tempdir/z$filter.par
				sedi 's|imstatistics.images =|imstatistics.images = \"'$coaddw'\"|' $tempdir/z$filter.par
				sedi 's|imstatistics.fields =|imstatistics.fields = \"max\"|' $tempdir/z$filter.par
				sedi 's|imstatistics.nclip = 3.|imstatistics.nclip = 0|' $tempdir/z$filter.par
				set MAXEXP = `$images imstatistics \@$tempdir/z$filter.par`
#				set MAXEXP = `awk 'BEGIN{printf "%10.3f\n",'$MAXEXP'/1000.0}'`
				set EFFRN = `gethead $coadd EFFRN`
				set EXPOSURE = `gethead $coadd EXPOSURE`
				set NCOMBINE = `awk 'BEGIN{printf "%8.2f\n",'$MAXEXP'/'$EXPOSURE'}'`
				echo Original Exposure time per input frame: $EXPOSURE
				echo Original Read noise per input frame: $EFFRN
				echo Number of Overlapping frames: $NCOMBINE
				set EFFRN = `awk 'BEGIN{printf "%6.2f\n",'$EFFRN'/sqrt('$NCOMBINE')}'`
				set EFFGAIN = `gethead $coadd EFFGAIN`
				echo Final Exposure time: $MAXEXP
				echo Final Read Noise: $EFFRN

				sethead $coadd EFFRN=$EFFRN / "Final Read-Noise [e-/pix]"
				sethead $coadd EXPOSURE=$MAXEXP  / "Maximum Exposure time [s]"
				sethead $coadd NCOMBINE=$NCOMBINE  / "Maximum number of overlapping Frames."
				sethead $coadd GAIN=$EFFGAIN / "Final Gain"
				rm -fr $coaddm
				cp $fsiraf/imexpr.par $tempdir/$coadd.par3
#				sedi 's|imexpr.expr =|imexpr.expr = \"(a>0.33*'$MAXEXP') ? 0 : 1 \"|' $tempdir/$coadd.par3
				sedi 's|imexpr.expr =|imexpr.expr = \"(a>0.33*'$MAXEXP') ? b : 1 \"|' $tempdir/$coadd.par3
				sedi 's|imexpr.a =|imexpr.a = \"'$coadde'[1]\"|' $tempdir/$coadd.par3
				sedi 's|imexpr.b =|imexpr.b = \"'$coaddo'[1]\"|' $tempdir/$coadd.par3
				sedi 's|imexpr.output =|imexpr.output = \"'$coaddm'\"|' $tempdir/$coadd.par3
				$images imexpr \@$tempdir/$coadd.par3
			    endif


		    # EXPLICITLY FIND THE BACKGROUND NOISE  
			if ( 1 ) then
			    echo re-determining background noise
			    echo "OLD BACKSIG                    all pixels          = `gethead $coadd BACKSIG`"
			    $fsbin/backsig.csh $coadd $coaddm >& tmp.cat
			    set BACKSIG = `tail -n2  tmp.cat`
			    echo "NEW BACKSIG: $BACKSIG[1] pixels                        = $BACKSIG[2]"
			    echo "NEW BACKSIG: $BACKSIG[3] uncorrelated groups of pixels = $BACKSIG[4]"
			    sethead $coadd BACKSIG=$BACKSIG[2] / "Num = $BACKSIG[1]"
			    sethead $coadd BACKSIGC=$BACKSIG[4] / "Num = $BACKSIG[3]"
			endif
		    # ADD ZEROPOINT TO HEADER	
			if ( $ilist != 1 ) then
			    $fsbin/fsred_zp.csh $coadd $coaddw $PSCALE3 $fsast $fsbin $sm $SEXFLAG $group
			endif
			if ( $domag == 1 && 1 ) then
			    echo Performing custom photometry on $magfile
			    $fsbin/fsred_mag.csh $coadd $coaddw $fsast $magfile
			endif

		    end # group while
		end # phot while


		endif # FIRST PASS
	    ######################################## mask.pl

		if ( $pauseflag == 1 || $DEBUG == 'yes' ) then
		    echo Pausing for inspection. Enter \"y\" to continue or \"redo\" to reset parmeters and redo:
		    set nvar = $<
		    if ( $nvar == "redo" ) then
			echo "AREAGROW: ($AREAGROW)"
			set var = $<
			if ( $var != "" && $var != $AREAGROW ) then
			    set AREAGROW = $var
			endif
			echo "HIDETECT2: ($HIDETECT2)"
			set var = $<
			if (  $var != "" && $var != $HISIG ) then
			    set HIDETECT2 = $var
			endif
			echo "Using Detect parameters: HIDETECT2=$HIDETECT2  and AREAGROW=$AREAGROW"
			rm -fr fs_mask_*.tile.pl.fits
			goto detect
		    else if ( $nvar == "y" ) then
			echo Continuing...
		    else
			echo Exiting....
			exit 0
		    endif
		endif
		wait
		set tf = `date +%s`
		printf "Time elapsed: %6.2f min. \n" `echo "($tf-$t0)/60" | bc -l`

		if ( $quick == 1 ) then
		    printf "\n\nDone with Quick Pass. Exiting..."
		    set tf = `date +%s`
		    printf "Time elapsed: %6.2f min. \n" `echo "($tf-$t0)/60" | bc -l`
		    exit 0
		endif
		if ( $fpass == 1 ) then
		    printf "\n\nDone with First Pass. Exiting..."
		    set tf = `date +%s`
		    printf "Time elapsed: %6.2f min. \n" `echo "($tf-$t0)/60" | bc -l`
		    exit 0
		endif


	    ####################### deregister masks
		printf "\n ---------------------\n Deregistering masks  \n ---------------------\n\n"
		#exit 
	    ######################################## foreach 
		set group = 0
		while ( $group < $ngroups ) 
		    @ group ++

		    set coadd =  fs_mask_${filter}_${group}.tile.mos.fits
		    set coaddo = fs_mask_${filter}_${group}.tile.mos.pl.fits
		    set coadde = fs_mask_${filter}_${group}.tile.exp.pl.fits
		    set coaddw = fs_mask_${filter}_${group}.tile.exp.fits
		    set coaddm = fs_mask_${filter}_${group}.tile.msk.fits
		    set coaddb = fs_mask_${filter}_${group}.tile.bpm.pl.fits

#		    set imnum = 0
		    if ( $TRANSIENT == 0 ) then
			set BACKTRAN = 24
		    else
			set BACKTRAN = 12
		    endif
		    foreach name (`cat zcata_${filter}_${group}.txt`)
#			@ imnum ++
			set name = $name:s/.sub.fits//

			if ( -e $name.obj.pl ) then
			    echo $name.obj.pl exists
			    continue
			else if ( ! -e $coaddo ) then
			    echo no $coaddo file
			    exit 1
			else
			    echo $name
			    if ( $DEBUG == 'yes' && $wait != 'Y' ) then
				wait
				echo ""
				echo -n "go on to next image ([y|Y]):" ; set wait = $<
			    endif
			    rm -f $name.diff.fits $name.diff.pl.fits $name.cr.pl.fits $name.remap.fits $name.remap.pl.fits $name.diffsky.fits $name.diffsig.fits $tempdir/$name:t.dat  >>& /dev/null
#			    rm -f $name.diff.fits >>& /dev/null
#			    rm -f $name.diff.pl.fits >>& /dev/null
#			    rm -f $name.cr.pl.fits >>& /dev/null
#			    rm -f $name.remap.fits >>& /dev/null
#			    rm -f $name.remap.pl.fits >>& /dev/null
#			    rm -f $name.diffsky.fits >>& /dev/null
#			    rm -f $name.diffsig.fits >>& /dev/null
#			    rm -f $tempdir/$name:t.dat >>&/dev/null
			# UPDATE ORIGINAL HEADER WITH CORRECT OFFSETS/ROTATION/SCALE/DISTORTION
			    sedi 's_END_|_g' `echo $name | sed 's|_c[1-4].fits|_mef.head|'`
#			    @ i = 1
#			    foreach ch ( 1 2 3 4 )
#				if ( `ls *c${ch}.fits >>& /dev/null ; echo $status` ) then
#				    sedi ''$i'i\\
#					|\
#					' `echo $name | sed 's|_c[1-4].fits|_mef.head|'`
#				    @ i += 1
#				else
#				    @ i += 48
#				endif
#			    end
#exit 0
			    awk 'BEGIN{RS="|"}{if(NR=='`$gethead $name CHIP`') print $0 }' `echo $name | sed 's|_c[1-4].fits|_mef.head|'` | grep -E 'CRVAL|CRPIX|CD|PV' > $tempdir/$name:t.dat

#			    set STDDEV = `gethead $name.sub.fits STDDEV`
			    set STDDEV = `gethead $name STDDEV`
# IRAF wcsxymatch does not know about PV polynomial terms, WCStools 3.4 does, however, remap in WCStools does not operate on .pl files which is done faster in IRAF.  GEOTRAN does not know about type=mask, have to use .pl files for now, ok becuase use imexp to combine masks.  
#			    awk '{print}' <<EOF > $tempdir/az$name:t_$t0.csh
			    cat - <<EOF > $tempdir/az$name:t_$t0.csh
#!/bin/csh
cd `pwd`
$sethead $name @$tempdir/$name:t.dat
$rm -f $name.obj.*  >>& /dev/null
set TMPFILE = \`mktemp $tempdir/$name.db.XXXX\`

$cp $fsiraf/geomap.par $tempdir/$name.rev.par
$cp $fsiraf/geotran.par $tempdir/$name.3a.par
$cp $fsiraf/geotran.par $tempdir/$name.3b.par
#$cp $fsiraf/imarith.par $tempdir/$name.3c.par
$cp $fsiraf/imexpr.par $tempdir/$name.3c.par
$cp $fsiraf/imexpr.par $tempdir/$name.3ccc.par
$cp $fsiraf/detect.par $tempdir/$name.3d.par
$cp $fsiraf/detect.par $tempdir/$name.3dd.par
$cp $fsiraf/imexpr.par $tempdir/$name.4b.par
$cp $fsiraf/imreplace.par $tempdir/$name.4r.par

if ( -e $name.1.pl.fits ) then
    set impl = $name.1.pl.fits
    rm -f $name.pl.fits
else
    if ( -e $name.pl.fits ) then
	$mv -f $name.pl.fits $name.1.pl.fits
	set impl = $name.1.pl.fits
    else
	set impl = $bpmloc/bp_`$gethead $name chip`.pl.fits
    endif
endif
echo Using mask \$impl

$sedi 's|geomap.input = \"\"|geomap.input = \"'$name'.obj.rev.dat\"|' $tempdir/$name.rev.par
$sedi 's|geomap.database = \"\"|geomap.database = \"'\$TMPFILE'\"|' $tempdir/$name.rev.par
$sedi 's|geomap.transforms = \"\"|geomap.transforms = \"reverse\"|' $tempdir/$name.rev.par

$sedi 's|geotran.input = \"\"|geotran.input = \"'$coaddo'[1]\"|' $tempdir/$name.3a.par
$sedi 's|geotran.output = \"\"|geotran.output = \"'$name'.obj.pl\"|' $tempdir/$name.3a.par
$sedi 's|geotran.database = \"\"|geotran.database = \"'\$TMPFILE'\"|' $tempdir/$name.3a.par
$sedi 's|geotran.transforms = \"\"|geotran.transforms = \"reverse\"|' $tempdir/$name.3a.par
$sedi 's|geotran.interpolant = \"linear\"|geotran.interpolant = "nearest"|' $tempdir/$name.3a.par
$sedi 's|geotran.fluxconserve = yes|geotran.fluxconserve = no|' $tempdir/$name.3a.par

$sedi 's|geotran.input = \"\"|geotran.input = \"'$coadd'\"|' $tempdir/$name.3b.par
$sedi 's|geotran.output = \"\"|geotran.output = \"'$name'.remap.fits\"|' $tempdir/$name.3b.par
$sedi 's|geotran.database = \"\"|geotran.database = \"'\$TMPFILE'\"|' $tempdir/$name.3b.par
$sedi 's|geotran.transforms = \"\"|geotran.transforms = \"reverse\"|' $tempdir/$name.3b.par
$sedi 's|geotran.interpolant = \"linear\"|geotran.interpolant = "nearest"|' $tempdir/$name.3b.par
$sedi 's|geotran.fluxconserve = yes|geotran.fluxconserve = no|' $tempdir/$name.3b.par

#$sedi 's|imarith.operand1 = |imarith.operand1 = \"'$name'.sub.fits\"|' $tempdir/$name.3c.par
#$sedi 's|imarith.op = |imarith.op = \"-\"|' $tempdir/$name.3c.par
#$sedi 's|imarith.operand2 = |imarith.operand2 = \"'$name'.remap.fits\"|' $tempdir/$name.3c.par
#$sedi 's|imarith.result = |imarith.result = \"'$name'.diff.fits\"|' $tempdir/$name.3c.par

$sedi 's|imexpr.a =|imexpr.a = \"'$name'.sub.fits\"|' $tempdir/$name.3c.par
$sedi 's|imexpr.b =|imexpr.b = \"'$name'.remap.fits\"|' $tempdir/$name.3c.par
$sedi 's|imexpr.output = |imexpr.output = \"'$name'.diff.fits\"|' $tempdir/$name.3c.par
$sedi 's|imexpr.expr = |imexpr.expr = \"(a-a.NEWSKY) - b/a.FLXSCALE \"|' $tempdir/$name.3c.par

$sedi 's|imexpr.a =|imexpr.a = \"'$name'.remap.fits\"|' $tempdir/$name.3ccc.par
$sedi 's|imexpr.b =|imexpr.b = \"'$name'.1.pl.fits[1]\"|' $tempdir/$name.3ccc.par
$sedi 's|imexpr.output = |imexpr.output = \"'$name'.remap.pl.fits[type=mask]\"|' $tempdir/$name.3ccc.par
$sedi 's|imexpr.refim = \"auto\"|imexpr.refim = \"b\"|' $tempdir/$name.3ccc.par

cp $fsiraf/mimstat.par $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.images =|mimstatistics.images = \"'$name'.diff.fits\"|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.imasks = |mimstatistics.imasks = \"'$name'.1.pl.fits[1]\"|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.fields =|mimstatistics.fields = \"npix,mean,midpt,mode,stddev,skew,kurtosis,min,max\"|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.nclip = 0|mimstatistics.nclip = 1|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.lsigma = 3|mimstatistics.lsigma = 5|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.usigma = 3|mimstatistics.usigma = 5|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.lower = INDEF|mimstatistics.lower = -100|' $tempdir/$name.3cccc.par
$sedi 's|mimstatistics.upper = INDEF|mimstatistics.upper = 100|' $tempdir/$name.3cccc.par

# DETECTION PARAMETERS (LARGE SCALE OR SATELLITE npix>1000 )
$sedi 's|detect.images = \"\"|detect.images = \"'$name'.diff.fits\"|' $tempdir/$name.3d.par
$sedi 's|detect.objmasks = \"\"|detect.objmasks = \"'$name'.diff.pl.fits[type=mask]\"|' $tempdir/$name.3d.par
$sedi 's|detect.masks = \"\"|detect.masks = \"'$name'.remap.pl.fits[1]\"|' $tempdir/$name.3d.par
#$sedi 's|detect.ngrow = 2|detect.ngrow = 64|' $tempdir/$name.3d.par
#$sedi 's|detect.agrow = 2.|detect.agrow = 2|' $tempdir/$name.3d.par
$sedi 's|detect.ngrow = 2|detect.ngrow = 0|' $tempdir/$name.3d.par
$sedi 's|detect.agrow = 2.|detect.agrow = 0|' $tempdir/$name.3d.par
$sedi 's|detect.minpix = 6|detect.minpix = 500|' $tempdir/$name.3d.par
$sedi 's|detect.hsigma = 1.5|detect.hsigma = $TRANSIENT2|' $tempdir/$name.3d.par
$sedi 's|detect.ldetect = no|detect.ldetect = yes|' $tempdir/$name.3d.par
$sedi 's|detect.lsigma = 10.|detect.lsigma = $TRANSIENT2|' $tempdir/$name.3d.par
$sedi 's|detect.logfiles = \"STDOUT\"|detect.logfiles = \"\"|' $tempdir/$name.3d.par

# USE IMREPLACE RADIUS TO EXPAND MASK BY SOME EXTENT.  DETECT.grow DOES NOT FILL IN PIXELS WHICH ARE MASKED.  
$sedi 's|imreplace.images = |imreplace.images = \"'$name'.diff.pl.fits[1]\"|' $tempdir/$name.4r.par

# CR DETECTION PARAMETERS
$sedi 's|detect.images = \"\"|detect.images = \"'$name'.diff.fits\"|' $tempdir/$name.3dd.par
$sedi 's|detect.objmasks = \"\"|detect.objmasks = \"'$name'.cr.pl.fits[type=mask]\"|' $tempdir/$name.3dd.par
$sedi 's|detect.masks = \"\"|detect.masks = \"'$name'.remap.pl.fits[1]\"|' $tempdir/$name.3dd.par
$sedi 's|detect.ngrow = 2|detect.ngrow = 1|' $tempdir/$name.3dd.par
$sedi 's|detect.agrow = 2.|detect.agrow = 9|' $tempdir/$name.3dd.par
$sedi 's|detect.convolve = \"bilinear 5 5\"|detect.convolve = \"\"|' $tempdir/$name.3dd.par
$sedi 's|detect.minpix = 6|detect.minpix = 1|' $tempdir/$name.3dd.par
$sedi 's|detect.hsigma = 1.5|detect.hsigma = 20|' $tempdir/$name.3dd.par
$sedi 's|detect.ldetect = no|detect.ldetect = yes|' $tempdir/$name.3dd.par
$sedi 's|detect.lsigma = 10.|detect.lsigma = 20|' $tempdir/$name.3dd.par
$sedi 's|detect.logfiles = \"STDOUT\"|detect.logfiles = \"\"|' $tempdir/$name.3dd.par

$sedi 's|imexpr.output =|imexpr.output = \"'$name'.pl.fits[type=mask]\"|' $tempdir/$name.4b.par
$sedi 's|imexpr.a =|imexpr.a = \"'$name'.obj.pl\"|' $tempdir/$name.4b.par
$sedi 's|imexpr.b =|imexpr.b = \"'\$impl'[1]\"|' $tempdir/$name.4b.par
$sedi 's|imexpr.refim = \"auto\"|imexpr.refim = \"b\"|' $tempdir/$name.4b.par
# b \& (\~128) IRAF (AND NOT 128), ignore object mask from first pass.  
if ( $TRANSIENT2 == 0 ) then
#    $sedi 's|imexpr.expr =|imexpr.expr = \" ((b \& (\~128))+( (a>10 \&\& a<8388608) ? 32 : 0) + ( (a \& 8388608 ) ? 128 : 0)  ) \"|' $tempdir/$name.4b.par
    $sedi 's|imexpr.expr =|imexpr.expr = \" ((b \& (\~128))+( mod(a,8388608)>10 ? 32 : 0) + ( (a >= 8388608 ) ? 128 : 0)  ) \"|' $tempdir/$name.4b.par
else
    $sedi 's|imexpr.c =|imexpr.c = \"'$name'.diff.fits\"|' $tempdir/$name.4b.par
    $sedi 's|imexpr.d =|imexpr.d = \"'$name'.remap.fits\"|' $tempdir/$name.4b.par
    $sedi 's|imexpr.e =|imexpr.e = \"'$name'.diff.pl.fits[1]\"|' $tempdir/$name.4b.par
    $sedi 's|imexpr.f =|imexpr.f = \"'$name'.cr.pl.fits[1]\"|' $tempdir/$name.4b.par
#    $sedi 's|imexpr.expr =|imexpr.expr = \" ((b \& (\~128))+( (a>10 \&\& a<8388608) ? 32 : 0) + ( (a \& 8388608 ) ? 128 : 0) +  ((e>10) ? 16 : 0) + ((f>10) ? 1 : 0) ) \"|' $tempdir/$name.4b.par
    $sedi 's|imexpr.expr =|imexpr.expr = \" ((b \& (\~128))+( mod(a,8388608)>10 ? 32 : 0) + ( (a >= 8388608 ) ? 128 : 0) +  ((e>10) ? 16 : 0) + ((f>10) ? 1 : 0) ) \"|' $tempdir/$name.4b.par
endif

# Compute the control points.  # xpix ypix --> RA DEC J2000 xpix ypix
$xy2sky $name \@$fsiraf/grid.dat > $tempdir/$name.1.grid

# RA DEC J2000 xpix ypix --> RA DEC J2000 -> ximg yimg 
$sky2xy $coadd \@$tempdir/$name.1.grid > $tempdir/$name.2.grid

# RA DEC J2000 xpix ypix RA DEC J2000 -> ximg yimg 
$paste $tempdir/$name.1.grid $tempdir/$name.2.grid | awk '\! /off/{printf "%11s %11s %11s %11s %11s %11s\n",\$4,\$5,\$(NF-1),\$NF,\$1,\$2}' > $name.obj.rev.dat

if ( -z $name.obj.rev.dat  ) then
    echo "Error $name.obj.rev.dat did not get created.   Astrometry problem?  Exiting. "
    exit 1
endif


# Compute the transformation.
echo computing transformation
$images geomap @$tempdir/$name.rev.par

# Register the images.
echo registering image
$images geotran @$tempdir/$name.3a.par
if( $TRANSIENT2 == 0 ) then
    echo TRANSIENT DETECTION OFF $name....
else
    $images geotran @$tempdir/$name.3b.par
#    $images imarith @$tempdir/$name.3c.par
    $images imexpr @$tempdir/$name.3c.par
    set AVERAGE = \`$proto mimstatistics \@$tempdir/$name.3cccc.par\`
    echo    $name    BACKGROUND = \$AVERAGE[2]     STDDEV = \$AVERAGE[5]
    if ( 1 ) then
	$sedi 's|detect.skys = \"\"|detect.skys = \"'$name'.diffsky.fits\"|' $tempdir/$name.3d.par
	$sedi 's|detect.sigmas = \"\"|detect.sigmas = \"'$name'.diffsig.fits\"|' $tempdir/$name.3d.par
	$sedi 's|detect.fitxorder = 2|detect.fitxorder = 5|' $tempdir/$name.3d.par
	$sedi 's|detect.fityorder = 2|detect.fityorder = 5|' $tempdir/$name.3d.par
    else
	$sedi 's|detect.skys = \"\"|detect.skys = \"'\$AVERAGE[2]'\"|' $tempdir/$name.3d.par
	$sedi 's|detect.sigmas = \"\"|detect.sigmas = \"'\$AVERAGE[5]'\"|' $tempdir/$name.3d.par
    endif
    if ( 0 ) then
	$sedi 's|imexpr.expr = |imexpr.expr = \" ( a > 10 \|\| b>0 ) ? 1 : 0  \"|' $tempdir/$name.3ccc.par
    else
# 1+4+8 = 13
	$sedi 's|imexpr.expr = |imexpr.expr = \" ( (a > '\$AVERAGE[2]'+5*'\$AVERAGE[5]') \|\| (b \& 13) ) ? 1 : 0  \"|' $tempdir/$name.3ccc.par
    endif
    $images imexpr @$tempdir/$name.3ccc.par >>& /dev/null

    echo TRANSIENT DETECTION FOR $name....
    $nproto detect @$tempdir/$name.3d.par
    if ( 1 ) then
	set reprad = 10
	echo EXPANDING TRANSIENT DETECTIONS FOR $name by \$reprad pixels.  
	$sedi 's|imreplace.radius = 0.|imreplace.radius = '\$reprad'|' $tempdir/$name.4r.par
	$sedi 's|imreplace.value = 100.|imreplace.value = 100.|' $tempdir/$name.4r.par
	$sedi 's|imreplace.lower = 10|imreplace.lower = 10|' $tempdir/$name.4r.par
	$sedi 's|imreplace.upper = INDEF|imreplace.upper = INDEF|' $tempdir/$name.4r.par
	$images imreplace @$tempdir/$name.4r.par >>& /dev/null
    endif
    echo COSMIC RAY DETECTION FOR $name....
    $nproto detect @$tempdir/$name.3dd.par >>& /dev/null
endif

# OR the .pl maks.
echo combining pixel masks
$images imexpr @$tempdir/$name.4b.par >>& /dev/null
printf "Finished with ${name}.obj.pl.fits\n"
if ( 1 ) then
    rm -fr ${name}.diff* >>& /dev/null
    rm -fr ${name}.remap* >>& /dev/null
    rm -fr ${name}.cr* >>& /dev/null
endif
wait
exit 0
EOF
			    chmod 777 $tempdir/az$name:t_$t0.csh
			endif
			if ( $xgrid == 0 ) then
			    set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv' | grep -E '${PROCESS}|sed|_$t0.csh' | wc -l`
#			    while ( $numbkjobs > $BKJOBS )
			    while ( $numbkjobs > $BACKTRAN )
				set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv' | grep -E '${PROCESS}|sed|_$t0.csh' | wc -l`
				echo  "$numbkjobs > $BACKTRAN"
#				echo Sleeepy...
				sleep 1
			    end
#			    ( exec $tempdir/az$name:t_$t0.csh >>& $tempdir/register.log & )
			    $tempdir/az$name:t_$t0.csh >>& $tempdir/register.log & 
			else
			    xgridx $tempdir/az$name:t_$t0.csh &
			endif
			#sleep $isleep
			if ( `grep Error $tempdir/register.log ; echo $status` == 0 ) then
			    echo "Deregistering failed; see $tempdir/register.log.  Stopping here to prevent further havoc."
			    exit 1
			endif
		    end # foreach file
		    if ( `grep Error $tempdir/register.log ; echo $status` == 0 ) then
			echo "Deregistering failed; see $tempdir/register.log.  Stopping here to prevent further havoc."
			exit 1
		    endif

		end # while group loop
	    ######################################## end 
		wait
		echo done with masks for $names[$ilist]
	    endif   # list 1 or 2
	    #  END MASK
	    #exit 
################################################################################
################################################################################
################################################################################
#exit 0
	    wait
flats:
########################## FLATS ###############################################
# NOTE they all get normalized to the same value, so each set of chip should be taken at the same time/light level.  If one frame gets rejected, reject all chips.
	    if ( $ilist == 1 && $list != "null" ) then
		echo Creating Flats
	    # if the number flat lists is 2, they did not get merged, assume they are K cold and warm.   
	    # COMBINE DATA TO MAKE FLATS
		cd $dest/FLATS
		set name = `head -n1 zall.txt`
		set filter = `gethead $name filter`
		if ( -e ${filter}_1.fits && -e ${filter}_2.fits && -e ${filter}_3.fits && -e ${filter}_4.fits  ) then
		    echo Already normalized
		else
		    foreach chip ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
			echo Combining data for chip $chip
			if ( $name == "" ) then
			    echo Error: line 1727
			    exit 1
			else
			    if ( -e ${filter}_${chip}.diff.fits ) then
				echo ${filter}_${chip}.diff.fits already exists
				continue
			    else
				cat zall.txt | grep _c$chip > $tempdir/$chip.txt
#				awk '{print}' <<EOF > $tempdir/flat_${chip}_$t0.csh
				cat - <<EOF > $tempdir/flat_${chip}_$t0.csh
#!/bin/csh
    cd `pwd`
    cp $fsiraf/imcombine.par $tempdir/$chip.par
# NOTE CANT HAVE 2 BACKSLASHES 
    $sedi 's|imcombine.input =|imcombine.input = \"\@'$tempdir$chip.txt'\"|' $tempdir/$chip.par
    $sedi 's|imcombine.output =|imcombine.output = \"'$filter'_'$chip'.diff.fits\"|' $tempdir/$chip.par
# USE AVERAGE, BETTER AT FIRST MOMENT MEASUREMENT
    $sedi 's|imcombine.combine =|imcombine.combine = \"average\"|' $tempdir/$chip.par
    $sedi 's|imcombine.reject = \"none\"|imcombine.reject = \"minmax\"|' $tempdir/$chip.par
# SCALE BY BACKGROUND, IT IS VARYING (NOT LINEAR WITH EXPTIME), SOURCE COUNTS DON'T MATTER, THEY GET MASKED.
    $sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"mode\"|' $tempdir/$chip.par
    $sedi 's|imcombine.statsec = \"\"|imcombine.statsec = \"[5:2044,5:2044]\"|' $tempdir/$chip.par
# FOR AVSIGCLIP
#  lsigma and hsigma do not like to be too different from each other! keep at 3 and 3 (default)
#    $sedi 's|imcombine.lsigma = 3|imcombine.lsigma = 5|' $tempdir/$chip.par
#    $sedi 's|imcombine.hsigma = 3|imcombine.hsigma = 1|' $tempdir/$chip.par
# FOR MINMAX
    $sedi 's|imcombine.nlow = 2|imcombine.nlow = 0.1|' $tempdir/$chip.par
    $sedi 's|imcombine.nhigh = 2|imcombine.nhigh = 0.1|' $tempdir/$chip.par
    $sedi 's|imcombine.nkeep = 1|imcombine.nkeep = 3|' $tempdir/$chip.par
#    $sedi 's|imcombine.masktype = \"none\"|imcombine.masktype = \"goodvalue\"|' $tempdir/$chip.par
    $sedi 's|imcombine.masktype = \"none\"|imcombine.masktype = \"\badbits\"|' $tempdir/$chip.par
    set BADBITS = 63   
    $sedi 's|imcombine.maskvalue = \"0\"|imcombine.maskvalue = \"'\$BADBITS'\"|' $tempdir/$chip.par
    $images imcombine \@$tempdir/$chip.par
wait
exit 0
EOF
				chmod 777 $tempdir/flat_${chip}_$t0.csh
			    endif
			    if ( $xgrid == 0 ) then
				$tempdir/flat_${chip}_$t0.csh &
			    else
				xgridx $tempdir/flat_${chip}_$t0.csh &
			    endif
			endif
		    end
		    wait # wait for imcombines to finish 
################################################################################
		    if ( $fflag == 2 ) then
			set fflag = 1
			mkdir cold
			mv fs* cold
#			mv fs_mask_1.tile.fits fs_mask_1.cold.fits >>& /dev/null
#			mv fs_mask_1.tile.pl.fits fs_mask_1.cold.pl.fits >>& /dev/null
#			rm -fr fs_scamp_1.txt >>& /dev/null
#			rm -fr fs_swarp_1.txt >>& /dev/null
#			rm -fr fs_mask_1.tile*.fits >>& /dev/null
			foreach chip (1 2 3 4)
			    mv ${filter}_${chip}.diff.fits ${filter}_${chip}.cold.fits >>& /dev/null
			end
			printf "\n ----- Starting Warm Flats ----- \n"
			continue
		    else if ( $#flats == 2 ) then
			mkdir warm
			mv fs* warm
#			mv fs_mask_1.tile.fits fs_mask_1.warm.fits >>& /dev/null
#			mv fs_mask_1.tile.pl.fits fs_mask_1.warm.pl.fits >>& /dev/null
			foreach chip ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
			    mv ${filter}_${chip}.diff.fits ${filter}_${chip}.warm.fits >>& /dev/null
			    cp $fsiraf/imarith.par $tempdir/z$filter.$chip.par
			    sedi 's|imarith.operand1 =|imarith.operand1 = \"'${filter}'_'${chip}'.warm.fits\"|' $tempdir/z$filter.$chip.par
			    sedi 's|imarith.op =|imarith.op = \"-\"|' $tempdir/z$filter.$chip.par
			    sedi 's|imarith.operand2 =|imarith.operand2 = '${filter}'_'${chip}'.cold.fits|' $tempdir/z$filter.$chip.par
			    sedi 's|imarith.result =|imarith.result = \"'${filter}'_'${chip}'.diff.fits\"|' $tempdir/z$filter.$chip.par
			    $images imarith \@$tempdir/z$filter.$chip.par &
			end
		    else

		    endif
		    wait
################################################################################
		    ls ${filter}_?.diff.fits
		    ls ${filter}_?.diff.fits > $tempdir/zflat_${filter}.list
		    if (  -z $tempdir/zflat_${filter}.list  ) then
			echo "Nothing to normalize, but I thought there was, exiting"
			exit 1
		    else
			rm -f ${filter}_?n.fits >>& /dev/null
			cp $fsiraf/mimstat.par $tempdir/z$filter.par
			sedi 's|mimstatistics.images =|mimstatistics.images = \"\@'$tempdir''zflat_$filter'.list\"|' $tempdir/z$filter.par
			sedi 's|mimstatistics.imasks =|mimstatistics.imasks = \"'$bpmloc'/bp_?.pl.fits[1]\"|' $tempdir/z$filter.par
			sedi 's|mimstatistics.fields =|mimstatistics.fields = \"mean\"|' $tempdir/z$filter.par
			sedi 's|mimstatistics.nclip = 0|mimstatistics.nclip = 2|' $tempdir/z$filter.par
			sedi 's|mimstatistics.lsigma = 3|mimstatistics.lsigma = 3|' $tempdir/z$filter.par
			sedi 's|mimstatistics.usigma = 3|mimstatistics.usigma = 3|' $tempdir/z$filter.par
			sedi 's|mimstatistics.lower = INDEF|mimstatistics.lower = 0|' $tempdir/z$filter.par
			$proto mimstatistics \@$tempdir/z$filter.par | tee $tempdir/a$filter.stats
			set average = `awk 'BEGIN{a=0}{a=($1+a)}END{print a/NR}' $tempdir/a$filter.stats `
			printf "The normalization factor is: %8.2f\n" $average

			foreach ch ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
			    cp $fsiraf/imexpr.par $tempdir/z$filter.$ch.par
			    # PUT BACK THE ORIGINAL FLAT I REMOVED DURING PRE-REDUCTION IN x_imexpr.
			    sedi 's|imexpr.expr =|imexpr.expr = \"(a*b/c)\"|' $tempdir/z$filter.$ch.par
			    sedi 's|imexpr.a =|imexpr.a = \"'$filter'_'$ch'.diff.fits\"|' $tempdir/z$filter.$ch.par
			    sedi 's|imexpr.b =|imexpr.b = \"'$flatloc''$filter'_'$ch'.fits\"|' $tempdir/z$filter.$ch.par
			    sedi 's|imexpr.c =|imexpr.c = \"'$average'\"|' $tempdir/z$filter.$ch.par
			    sedi 's|imexpr.output =|imexpr.output = \"'$filter'_'$ch'.fits\"|' $tempdir/z$filter.$ch.par
			    $images imexpr \@$tempdir/z$filter.$ch.par &
			end
		    endif
		    wait
################################################################################
		    set tf = `date +%s`
		    printf "Time elapsed: %6.2f min.  FLATS DONE, CONTINUING...\n" `echo "($tf-$t0)/60" | bc -l` 
		endif
	    endif # FLAT
###################### END CREATE FLATS ########################################
finfp:
	    wait # FOR THIS LIST TO FINISH IN CASE THE NEXT LIST HAS DEPENDENCIES
	    if ( $rflag ) then
		rm -f $tempdir/z*  >>& /dev/null
	    endif
	    printf "\n Cleaning $tempdir files \n"
	    rm -f $tempdir/*parc  >>& /dev/null #must delete these or SKY frames will assume they are done and not link to TARGETS
#	    rm -f $tempdir/* >>& /dev/null
	    printf " $names[$ilist]  $list done \n" | tee fs_done.txt
	endif # LIST NOT EMPTY
	@ ilist ++ # INCREMENT TO THE NEXT LIST
    end # INPUT LIST FOR LOOP
    wait # FOR PRE-PROCESSING TO FINISH
    set wait = ""
    cd $dest
################################################################################
################################################################################
#exit 0

################################################################################
################################################################################
#  PROCEED WITH TARGET REDUCTION 
################################################################################
################################################################################
    if ( $targets == "null" ) then # SUBTRACT BACKGROUND 
	echo "NO TARGETS TO SKY SUBTRACT"
    else
	if ( $bflag == 0 ) then
	    printf "\n\nNOT SUBTRACTING BACKGROUND, SUGGEST SETTING SWARP BACKGROUND FLAG TO YES OR RE-RUN WITH THE -b OPTION.\n\n"
	endif
	if ( 1 ) then
	# COMBINE SKY FRAMES...IF YOU WANT TO USE THE TARGET FRAMES THEN SPECIFY THEM IN THE SKY LIST.
	# create skys from the sky directory but place them in the targets directory, get past IRAF bpm path limitation.  
	### MAKE SKY SUBTRACTED FILES   #########################################
	    cd $dest/$names[3]
	    if ( $skys == "null"  ) then
		printf "\nNO SKY FILE: SUBTRACTING CONSTANT MODE SKY LEVEL\n"
		set bflag = 0
	    endif
	    if ( 1 ) then
		printf "\nCREATING SKY SUBTRACTED FRAMES\n"
		if ( -z zmef.txt ) then
		    echo "Stopping. zmef.txt empty, not creating .sub images "
		    exit 1
		endif
		if ( $bflag != 0 ) then
		    echo getting sky data for targets
		    foreach ch ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` )
			cat $dest/$names[2]/zsky.txt | grep c$ch > $tempdir/ztmp.txt
			if ( ! -e $tempdir/ztmp.txt || -z  $tempdir/ztmp.txt ) then
			    echo Failure for chip $ch, no assigned sky frames.  
			    echo Cannot access $tempdir/ztmp.txt , or its empty.
			    continue
			endif
			gethead -p @$tempdir/ztmp.txt MJD RA DEC FILTER > $tempdir/MJD_$ch.cat
			if ( $status ) then
			    echo something went wrong with gethead.   
			    exit 2
			endif
		    end
		endif

		set DISKSP = `df $dest | awk '{if(NR==2) print $4}'`
	        set NIMG = `cat $dest/$names[3]/zmef.txt | wc -l`
		set MINSIZE2 = `echo "$MINSIZE * $NIMG" | bc`
 		echo $DISKSP $NIMG $MINSIZE2
		if ( `expr $DISKSP \< $MINSIZE2` ) then
		    echo Need $MINSIZE2 on destination disk, currently $DISKSP, exiting.
		    exit 1
		endif


		set nerror = 0
		rm -fr *.sublog >>& /dev/null
		foreach name (`cat $dest/$names[3]/zmef.txt`)
		    if ( -e ${name}_mef.cat && -e ${name}_mef.fits && -e ${name}_mef.weight.fits ) then
			echo "${name}_mef.cat already exists!" | tee $name.sublog
			continue
		    endif
		    if ( $fpass == 1 && (-e $dest/$names[2]/${name:t}_mef.cat && -e $dest/$names[2]/${name:t}_mef.fits && -e $dest/$names[2]/${name:t}_mef.weight.fits ) ) then
			echo "first pass ${name}_mef.cat already exists is SKYS...linking files!"
			ln -s $dest/$names[2]/${name:t}_mef.cat ${name}_mef.cat
			ln -s $dest/$names[2]/${name:t}_mef.fits ${name}_mef.fits
			ln -s $dest/$names[2]/${name:t}_mef.weight.fits ${name}_mef.weight.fits
			continue
		    endif
		    set minarea2 = $MINAREA
		    set tBKJOBS = `awk 'BEGIN {print 1*'$BKJOBS'} '`
		    if ( $xgrid == 0 || 0 ) then
			set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv|tcsh' | grep -E '${PROCESS}|sed|fsub.csh|mimsurfit' | wc -l`
			while ( $numbkjobs > $tBKJOBS )
			    set numbkjobs = `ps -a | grep -v -E 'x_system|x_tv|tcsh' | grep -E '${PROCESS}|sed|fsub.csh|mimsurfit' | wc -l`
			    printf "\rFSRED $numbkjobs current processes,  waiting for open slot..."
			    sleep 5
			end
			printf "Second Pass Background Subtracting: %s  " $name
			$fsbin/fsub.csh $dest/$names[3] $tempdir $fsiraf $images $proto $name $bflag $NBACK $CSCALE $BKJOBS $gethead $xgrid $myverbose $SMODE $SROWS $SCOLS $SURFIT $sex $WEIGHT $wt $WAVELET $nproto $INTERPOLATION $FUDGE $HISIG $DEBUG $t0 $OBJTHRESH $BS $SEMESTER "$chips" $IOBJMASK $ADVBACK $minarea2 >& $name.sublog &
		    else
			xgridx $fsbin/fsub.csh $dest/$names[3] $tempdir $fsiraf $images $proto $name $bflag $NBACK $CSCALE $BKJOBS $gethead $xgrid $myverbose $SMODE $SROWS $SCOLS $SURFIT $sex $WEIGHT $wt $WAVELET $nproto $INTERPOLATION $FUDGE $HISIG $DEBUG $t0 $OBJTHRESH $BS $SEMESTER "$chips" $IOBJMASK $ADVBACK $minarea2 >& $name.sublog &
		    endif
#		    jobs
		    sleep 1
		    
		#################
		    # TRY TO CATCH ERRORS AS THEY MIGHT OCCUR
		    foreach name ( `cat $dest/$names[3]/zmef.txt` )
			if ( -e $name.sublog ) then
			    if ( `grep -E 'ERROR|Error' $name.sublog | wc -l` != 0 ) then
				grep -E 'ERROR|Error' $name.sublog
				@ nerror ++
				echo something went wrong with fsub... $name     $nerror Errors.  Exiting.
				exit 1
			    endif
			endif
		    end
		#################
		    if ( $DEBUG == 'yes' && $wait != 'Y' ) then
			wait ; echo -n "go on to next image ([y|Y]):" ; set wait = $<
		    endif
		end
		# CHECK FOR ERRORS WHILE THE SCRIPT ARE RUNNING IN THE BACKGROUND
		while (  `jobs | wc -l` > 0  )
#		    jobs -l
		    foreach name ( `cat $dest/$names[3]/zmef.txt` )
			if ( `grep -E 'ERROR|Error' $name.sublog | wc -l` != 0 ) then
			    grep -E 'ERROR|Error' $name.sublog
			    @ nerror ++
			    echo something went wrong with fsub... $name     $nerror Errors.  Exiting.
			    exit 1
			endif
		    end
		    sleep 5
		end
		wait
		set wait = ""
		#################
		#  FIND ANY MISSED ERRORS
		set nerror = 0
		foreach name ( `cat $dest/$names[3]/zmef.txt` )
		    if ( `grep -E 'ERROR|Error' $name.sublog | wc -l` != 0 ) then
			grep -E 'ERROR|Error' $name.sublog
			echo something went wrong with fsub... $name
			@ nerror ++
		    endif
		end
		if ( $nerror != 0 ) then
		    echo something went wrong with fsub... $nerror Errors.  Exiting.
		    exit 1
		endif

	    endif
	endif
    endif
    wait
################################################################################
    set tf = `date +%s`
    printf "Time elapsed: %6.2f min.  BACKGROUND SUBTRACTION DONE, CONTINUING...\n" `echo "($tf-$t0)/60" | bc -l` 
################################################################################
################################################################################
#exit 0
################################################################################
endif # END CHECK TO SKIP AHEAD
target:

    cd $dest/$names[3]
################################################################################
################################################################################
    if( $astroscamp == 0 ) then
	echo "Not Running SCAMP"
    else if ( -e fs_scamp.txt ) then
	echo Already Ran SCAMP, remove fs_scamp.txt to re-run.
    else
	set checkplot = $SCAMPI
	if($inter == 1) then
	   set checkplot = XWIN
	    if ( -e ztmp.cat && ! -z ztmp.cat ) then
		echo ztmp.cat already exists, remove it if you want to regenerate it.  
	    else
		if ( -e zmef.txt && ! -z zmef.txt ) then
		    sed 's|$|_mef.cat|' zmef.txt > ztmp.cat
		else
		    echo looking for mef.cat files
  		    ls ../*/TARGETS/*mef.cat > ztmp.cat
		endif
	    endif
	   emacs ztmp.cat
	else
	    if ( ! -e zmef.txt || -z zmef.txt ) then
		if ( ! -e fs_ztmp.cat || -z fs_ztmp.cat ) then
		    echo looking for mef.cat files
		    if (  $sdirs[1] != "null" ) then
			rm -fr ztmp.cat
			echo Searching Following Directories:
			foreach var ( $sdirs )
			    echo $var
#			    cp -f $var/SKYS/*mef.cat $var/TARGETS
			    ls $var/TARGETS/*mef.cat >> ztmp.cat
			    if ( $status ) then
				echo No files found in $var... Exiting. 
				exit 1
			    endif
			end
		    else
			echo Searhing this Directory:
			ls ../*/TARGETS/*mef.cat > ztmp.cat
		    endif
		else
		    echo using existing fs_ztmp.cat file
		    cp fs_ztmp.cat ztmp.cat
		endif
	    else
		sed 's|$|_mef.cat|' zmef.txt > ztmp.cat
	    endif
	endif

    # set default filter
	set name = `head -n1 ztmp.cat | sed 's|.cat|.fits|'`
	if ( ! -e $name ) then
	    echo $name did not get created, Exiting...
	    exit 1
	endif
	set filter = `gethead $name filter`
	set RADEC = `gethead $name RA DEC`
	if ( $filter == "" ) then
	    echo "name = $name ; filter = $filter "
	    echo Something is wrong...
	    exit 1
	endif


	set ASTREF = "NONE"

	if ( $ASTREF != "NONE" ) then
	    set ACAT = FILE
	    set AFILT = 1
	else
	    set ACAT = 2MASS
	    if ( $filter == J || $filter == J1 || $filter == J2 || $filter == J3 || $filter == NB-1.18 ) then
		set AFILT = J
	    else if ( $filter == H || $filter == Hs || $filter == Hl ) then
		set AFILT = H
	    else if ( $filter == Ks || $filter == NB-2.09 ) then
		set AFILT = Ks
	    else
		echo Filter $filter not recognized using 2MASS J for reference photometry.  
		set AFILT = J
	    endif
	endif
	if ( $ASTREF_CATALOG == FILE )  then
	    set AFILT = BLUEST
	else if ( $ASTREF_CATALOG != 2MASS ) then
	    set AFILT = REDDEST
	endif

	rm -f ./scamp.ahead  >>& /dev/null
	sed 's|.cat|.fits|' ztmp.cat > ztmp.txt


	if ( $CID == 0 ) then
	    if ( -e ztmp.txt ) then
		set CID = `$gethead -u @ztmp.txt FWHM_AVE | awk '{if($0 !~ "___"){ave=(ave*n+$2)/(n+1);n++}}END{if(ave>0.2 && n>3 ){printf "%5.2f\n",ave}else{print '$CID'}}'`
	    else
		echo ztmp.txt does not exist... using default CID setting.  
		set CID = 0.5
	    endif
	endif

	if ( $CID == 0 ) then
	    echo Cannot Run SCAMP with CID\=0, exiting...
	    exit 1
	endif

	set redo = n
	set SOLVEAST3 = $SOLVEAST
SCAMP2:
	echo Changing CID to $CID > fs_scamp.txt
#	printf "\n  Solve Astrometry = $SOLVEAST3 : Filter = $AFILT : Output = $checkplot \n"
	printf "\n  Solve Astrometry = $SOLVEAST3 : Output = $checkplot \n"
	echo Starting Scamp... Groups within $FGROUP_RADIUS degrees. >> fs_scamp.txt
	if ( $redo == y ) then
	    set SOLVEAST3 = N
	endif
	if ( $redo == yy ) then
	    set SOLVEAST3 = N
	    set MATCH3 = N
	endif
	if ( $SOLVEAST3 == Y ) then
	    echo SOLVING DISTORTION USING SCAMP >> fs_scamp.txt
	else
	    echo USING ARCHIVE DISTORTION >> fs_scamp.txt
	endif
    # FIND INITIAL DISTORTION REGARDLESS.
	if ( ! -e $fsdist/distort_$filter.cat ) then
	    echo "No Archive Distortion found.  Exiting..."
	    exit 1
	else
	    @ index = 0000
	    rm -fr ztmp2.cat >>& /dev/null
	    foreach name  ( `cat ztmp.cat` )
		@ index ++
		set name = $name:s/.cat//
		echo $name $index
#		echo $name:h/$index.cat >> ztmp2.cat
#		cp -f $name.cat $name:h/$index.cat
#		cp -f $name.fits $name:h/$index.fits
		set filter = `gethead $name.fits filter`
		rm -fr $name.ahead $name.head >>& /dev/null
		foreach chip ( `awk 'BEGIN{for(i=1;i<=4;i++)print i}' | grep "[$chips]" | awk '{printf "%s ",$1 }' ` ) 
		    printf "CHIP    = $chip \n" >> $name.ahead
		    if ( 0 ) then
			printf "CRPIX1  = %g\nCRPIX2  = %g\nCRVAL1  = %g\nCRVAL2  = %g\nCD1_1   = %g\nCD1_2   = %g\nCD2_1   = %g\nCD2_2   = %g\n"\
			`gethead -x $chip $name.fits CRPIX1 CRPIX2 CRVAL1 CRVAL2 CD1_1 CD1_2 CD2_1 CD2_2` >> $name.ahead
			if ( $DISTORT_DEGREES == 3 ) then
			    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'CRPIX|A_|B_' >> $name.ahead
			endif
			if ( $DISTORT_DEGREES == 2 ) then
			    echo "A_ORDER = 2" >> $name.ahead
			    echo "B_ORDER = 2" >> $name.ahead
			    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'CRPIX|A_|B_' | grep -v -E '_2_1|_1_2|_3_0|_0_3|_ORDER' >> $name.ahead
			endif
#			grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'CRPIX|A_|B_' >> $name.ahead
		    else
			printf "CRPIX1  = %g\nCRPIX2  = %g\nCRVAL1  = %g\nCRVAL2  = %g\nCD1_1   = %g\nCD1_2   = %g\nCD2_1   = %g\nCD2_2   = %g\n"\
			`gethead -x $chip $name.fits CRPIX1 CRPIX2 CRVAL1 CRVAL2 CD1_1 CD1_2 CD2_1 CD2_2` >> $name.ahead
			if ( $DISTORT_DEGREES == 3 ) then
			    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'A_|B_' >> $name.ahead
			endif
			if ( $DISTORT_DEGREES == 2 ) then
			    echo "A_ORDER = 2" >> $name.ahead
			    echo "B_ORDER = 2" >> $name.ahead
			    grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'A_|B_' | grep -v -E '_2_1|_1_2|_3_0|_0_3|_ORDER' >> $name.ahead
			endif
#			grep -A 24 "CHIP    = $chip" $fsdist/distort_$filter.cat | grep -E 'A_|B_' >> $name.ahead
		    endif
		    printf "END             \n" >> $name.ahead
#		    echo $name.fits $chip $filter
		end
		mv $name.ahead $name.aaa
		$fsdist:h:h/pvsip -f $name.aaa -v 2 > $name.ahead
#		cp $name.ahead $name:h/$index.ahead
		if ( 0 ) then
		    echo -n "Hit any key to continue: " ; set wait = $<
		endif
		rm -f $name.aaa >>& /dev/null
	    end
	endif

	$scamp @ztmp.cat -c $fsast/scamp.config -FGROUP_RADIUS $FGROUP_RADIUS -MATCH $MATCH -SOLVE_ASTROM $SOLVEAST3 -SOLVE_PHOTOM Y -ASTREF_BAND $AFILT -SN_THRESHOLDS $SNT -ASTREF_WEIGHT $ASW -CROSSID_RADIUS $CID -MOSAIC_TYPE $MOTYPE -STABILITY_TYPE $STABILITY_TYPE -DISTORT_KEYS $DISTORT_KEYS -DISTORT_GROUPS $DISTORT_GROUPS -DISTORT_DEGREES $DISTORT_DEGREES -CHECKPLOT_DEV $checkplot -REF_SERVER $CDSCLIENT -POSITION_MAXERR $POSITION_MAXERR -POSANGLE_MAXERR $POSANGLE_MAXERR -ASTRCLIP_NSIGMA $ASTRCLIP_NSIGMA -PHOTCLIP_NSIGMA $PHOTCLIP_NSIGMA -FLAGS_MASK $FLAGS_MASK -ASTRINSTRU_KEY $ASTRINSTRU_KEY -ASTREF_CATALOG $ASTREF_CATALOG -ASTREFCAT_NAME $ASTREFCAT_NAME -VERBOSE_TYPE FULL >>& fs_scamp.txt &


	set wcold = 0 
	set lbid = $! # last job ID
	echo $lbid
	printf "\n\n\n\n-------------------------------------------------\n\n"
	while ( `ps -c | grep $lbid` != "" )
	    set wc = `cat  fs_scamp.txt | wc -l`
	    tail -n `echo "$wc - $wcold" | bc` fs_scamp.txt
	    set wcold = $wc
	    sleep 1
	end
	wait
	if ( $sdirs[1] != "null"  ) then
	    foreach var ( $sdirs )
		cp fs_scamp.txt $var/TARGETS/
	    end
	endif
	set wc = `cat  fs_scamp.txt | wc -l`
	tail -n `echo "$wc - $wcold" | bc` fs_scamp.txt
	if ( `grep WARNING fs_scamp.txt | grep -v "WARNING: All sources have non-zero flags" | grep -v "WARNING: No valid source found" | grep -v "WARNING: FLAGS parameter not found" | wc -l ` > 0 || `grep Error fs_scamp.txt | wc -l ` > 0 ) then
	    echo Cannot Find Distortion, too few sources.   Continuing without distortion. 
	    if ( $inter || $dwait ) then
		echo -n "Continue Anyways? ([y|n|redo]):" ; set wait = $<
	    else
		if ( $redo == n ) then
		    set wait = redo
		else
		    set redo = n
		    set wait = y
		endif
	    endif
	    if ( $wait == 'n' ) then
		rm -f fs_scamp.txt
		echo Exiting
		exit 1
	    else if ( $wait == 'redo' ) then
		printf "Setting SOLVEAST3 = N \n"
		set redo = y
		goto SCAMP2
	    endif
	    mv fs_scamp.txt fs_scamp.bak
	    echo "----- 1 field group found:" > fs_scamp.txt
	    echo " Group  1: 0 fields" >> fs_scamp.txt
	endif
    endif

################################################################################
# Combine images for each group detected
    cd $dest/$names[3]
    if ( ! -e fs_scamp.txt ) then
	echo no fs_scamp.txt found. 
	set ngroups = 0
	set nphot = 0
    else
	set ngroups = `awk '{if($0 ~ "field" && $0 ~ "group" && $0 ~ "found" ) print $2}' fs_scamp.txt`
	set nphot = `awk '{if($0 ~ "instrument" && $0 ~ "found" && $0 ~ "photometry" ) print $2}' fs_scamp.txt`
    endif
    echo "ngroups = $ngroups, nphot = $nphot"
    set phot = 0

    while ( $phot < $nphot ) 
	@ phot ++
	set filter = `grep -A1 "Instrument P$phot" fs_scamp.txt | grep FILTER | cut -d"'" -f2`
	set group = 0
	echo "----------------"
	echo "filter = $filter"
	while ( $group < $ngroups ) 
	    @ group ++
	    rm -f zcat_${filter}_${group}.txt >>& /dev/null
	    rm -f zcata_${filter}_${group}.txt >>& /dev/null
	    rm -f zcat2_${filter}_${group}.txt >>& /dev/null
	    set nfields = `awk '\! /\^/ {sub(":","",$2);if($1 ~ "Group" && $2 == "'$group'" && $4 ~ "fields" ){sub("\47","",$10);print $3,$6,$7,1.0*$10/60 }}' fs_scamp.txt`
	    set DIST = $nfields[4]

	    printf "\nGroup ${group}: $nfields, FILTER = $filter, DIST = $DIST \n"

	    if ( $astroswarp == 1 || $psfex == 1 ) then
		if ( $inter == 1 ) then
		    if ( -e zcat_${filter}_${group}.txt && ! -z zcat_${filter}_${group}.txt ) then
			echo zcat_${filter}_${group}.txt already exists, remove it if you want to regenerate it.  
		    else
			if ( $nfields[1] != 0 ) then
			    foreach mef (`awk '\! /\^/ {sub(":","",$2);if($1 ~ "Group" && $2 == "'$group'" && $4 ~ "fields" )){ num = $3;i=NR}else{if(NR-i <= num) print $1 }}' fs_scamp.txt`)
				ls ${mef:r}.fits >> zcat_${filter}_${group}.txt
			    end
			else
			    ls *mef.fits > zcat_${filter}_${group}.txt
			endif
		    endif
		    emacs zcat_${filter}_${group}.txt
		else
		    if ( $sdirs[1] != "null" ) then
			rm -fr zcat_${filter}_${group}.txt
			rm -fr zmef.txt
			echo Searching Following Directories:
			foreach var ( $sdirs )
			    echo $var
			    ls $var/TARGETS/*mef.fits | sed 's|_mef.fits||' >> zmef.txt
			    if ( $status ) then
				echo No files found in $var... Exiting. 
				exit 1
			    else
#				cat zmef.txt
			    endif
			end
		    endif
#exit 
		    if ( $nfields[1] != 0 ) then
			foreach input ( `cat zmef.txt` )
			    foreach mef ( `awk '\! /\^/ {sub(":","",$2);if($1 ~ "Group" && $2 == "'$group'" && $4 ~ "fields" ){ num = $3;i=NR}else{if(NR-i <= num && $3 == "P'$phot'" ){ print $1 }}}' fs_scamp.txt`)
# fs_scamp only prints filename, not path, so there is some ambiguity if files have the same name over mutiple nights.
# only continue if scamp mef file is present in this directory
				# CHECK ALL MATCHES
				if ( ${input:t}_mef == $mef:r ) then
				    if ( ! -e  ${input}_mef.fits ) then
					echo DNE
					continue
				    endif
				    if ( `grep ${input}_mef.fits zcat_${filter}_${group}.txt >>& /dev/null ; echo $status` == 0 ) then
					echo ${mef:r}.fits Already found for this date
#					exit 5
					continue
				    endif
			    # IF COORDINATES DONT MATCH GROUP, MOVE ON.  
				    set RADEC = `gethead ${input}_mef.fits CRVAL1 CRVAL2 FILTER`
				    echo $input $RADEC
				    set dr = `$fsbin/calc.csh 'ads("'$nfields[2]'","'$nfields[3]'","'$RADEC[1]'","'$RADEC[2]'")'`
				    echo $dr $DIST
#				    if ( `echo "$dr > $DIST" | bc` ) then
				    if ( `awk 'BEGIN {a=('$dr'>'$DIST')?1:0 ;print a }'` ) then
					echo ${input}_mef.fits too far from center
					continue
				    endif
				    if ( $RADEC[3] != $filter ) then
					echo "filter does not match... $RADEC[3] != $filter"
					continue
				    endif
				    ls ${input:h}/${mef:r}.fits >> zcat_${filter}_${group}.txt
				endif
			    end
			end
		    else
			ls *mef.fits > zcat_${filter}_${group}.txt
		    endif
		endif

		if ( ! -e zcat_${filter}_${group}.txt ) then
		    echo zcat_${filter}_${group}.txt did not get created.  Nothing to do for group $group filter $filter
		    continue
		endif
		cat zcat_${filter}_${group}.txt
#continue
#	    exit 0

		set name = `head -n1 zcat_${filter}_${group}.txt `
#		echo name is $name
#		set RDIR = $name:h
		set RDIR = `pwd`
		if ( $name == "" ) then
		    set coadd = *${CTYPE}.fits
		    set coaddw = *${CTYPE}.weight.fits
		else if ( ! -e $name ) then
		    set coadd = *${CTYPE}.fits
		    set coaddw = *${CTYPE}.weight.fits    
		else
		    set filter = `gethead $name filter`
		    set date = `gethead $name date-obs`
		    set MJD = `gethead $name MJD | sed 's|\.|_|'`
		    set obj = `gethead $name object | sed 's| |_|g' | awk '{gsub("\\52","");print}' `

		    set obj = ${obj}"_c"${chips}

		    if ($wt == 1) then
			set wtt = "w"
		    else
			set wtt = "nw"
		    endif

		    set coadd =  "${date}_${filter}_${obj}_${MJD}.mos.fits"
		    set coaddo = "${date}_${filter}_${obj}_${MJD}.mos.pl.fits"
		    set coadde = "${date}_${filter}_${obj}_${MJD}.exp.pl.fits"
		    set coaddw = "${date}_${filter}_${obj}_${MJD}.exp.fits"
		    set coaddm = "${date}_${filter}_${obj}_${MJD}.msk.fits"
		    set coaddr = "${date}_${filter}_${obj}_${MJD}.rms.fits"
		    set coadds = "${date}_${filter}_${obj}_${MJD}.sig.fits"
		    set coaddb = "${date}_${filter}_${obj}_${MJD}.bpm.pl.fits"

		endif
#		echo name is $name
	    endif
	################
#	    if ( -e $coadd ) then
#		echo "$coadd already exists..."
#		goto weight
#	    endif

	    if ( $astroswarp == 0 ) then
		echo "Not Running SWARP"
	    else
		echo "Running SWARP..."
		rm -f $tempdir/$coadd.weight_${filter}_${group}.txt >>& /dev/null
imcombine:
		if ( $IMCOMBINE == YES || 1 ) then
		    if ( -e fs_swarp_$MJD.txt ) then
			echo "Already ran swarp on group $group, epoch(MJD) $MJD."
			if ( $inter ) then
			    printf "Re-Run?[n|y]" ; set input = $<
			    if ( $input == y ) then
				rm -fr fs_swarp_$MJD.txt
				goto imcombine
			    endif
			else
#			    continue

#			    rm -fr fs_swarp_$MJD.txt
#			    goto imcombine
			    goto weight
#			    goto addzp

			endif
		    else 
			echo RAN SWARP > fs_swarp_$MJD.txt
		    # make resampled weight maps, if the input uses the same resampling, makes that also.

			rm -fr zcata_${filter}_${group}.txt >>& /dev/null
			foreach var ( `cat zcat_${filter}_${group}.txt` )
			    # COPY SKY WCS HEADER TO TARGET WCS HEADER
			    if ( 0 ) then
				cp $var:h:h/SKYS/$var:t:r.head $var:h/$var:t:r.head
			    endif
			    ls ${var:r}*resamp_$RESAMP.fits >>& /dev/null
			    if ( ! $status ) then
				ls ${var:r}*resamp_$RESAMP.fits | head -n4 >> zcata_${filter}_${group}.txt
			    endif
			end

			if ( -e zcata_${filter}_${group}.txt ) then
			    set num1 = `cat zcata_${filter}_${group}.txt | wc -l`
			    set num2 = `cat zcat_${filter}_${group}.txt | wc -l`
			    switch($chips)
				case 1-4:
				    @ num2 = $num2 * 4
				    breaksw
				default:
				    breaksw
			    endsw
			    echo $num1 $num2 $chips
			    if ( $num1 == $num2 ) then
				set RES = N
			    else
				echo "Not enough resampled image found"
				set RES = Y
			    endif
			else
			    echo "No resampled image found"
			    set RES = Y
			endif

			
			if ( $force ) then
			    set RES = Y
			endif
			echo "Resample = $RES"

#			set RES = N
			cat zcat_${filter}_${group}.txt
#			exit 0

			if ( $IMCOMBINE == NORES && $RES == Y ) then
			    echo Not resampling zcat_${filter}_${group}.txt.  Copying mef extension $chips to $RESAMP.fits extensions and copying header to image.  
			    foreach image ( `cat zcat_${filter}_${group}.txt` )
				set image2 = $image:s/.fits/.weight.fits/
				foreach chip ( 1 2 3 4 )
				    set chip2 = `echo $chip | awk '{printf "%04d\n",$1}'`
				    eval set imcopy = $image:s/mef.fits/mef.$chip2.resamp_$RESAMP.fits/
				    eval set imcopy2 = $imcopy:s/.fits/.weight.fits/
				    cp $fsiraf/imcopy.par $tempdir/$imcopy:t:r.par
				    cp $fsiraf/imcopy.par $tempdir/$imcopy2:t:r.par
				    sedi 's|imcopy.input =|imcopy.input = \"'$image'['$chip']\"|' $tempdir/$imcopy:t:r.par
				    sedi 's|imcopy.output =|imcopy.output = \"'$imcopy'\"|' $tempdir/$imcopy:t:r.par
				    sedi 's|imcopy.input =|imcopy.input = \"'$image2'['$chip']\"|' $tempdir/$imcopy2:t:r.par
				    sedi 's|imcopy.output =|imcopy.output = \"'$imcopy2'\"|' $tempdir/$imcopy2:t:r.par
				    rm -f $imcopy
				    rm -f $imcopy2

				    awk '{sub("END","|");print}' $image:s/.fits/.head/ > $image:s/.fits/.head2/
				    awk 'BEGIN{RS="|"}{if(NR=='$chip') print $0 }' $image:s/.fits/.head2/ | grep -E 'CRVAL|CRPIX|CD|PV|FLX' > $tempdir/$imcopy:t:r.dat
				    echo "FLASCALE=   1.0" >> $tempdir/$imcopy:t:r.dat

				    $images imcopy \@$tempdir/$imcopy:t:r.par ; $sethead $imcopy @$tempdir/$imcopy:t:r.dat &
				    $images imcopy \@$tempdir/$imcopy2:t:r.par &
				end
			    end
			    wait
			else
			    echo resampling zcat_${filter}_${group}.txt with: $RESAMPW with weight map, bad pixels may get exagerrated
			    $swarp @zcat_${filter}_${group}.txt -c $fsast/swarp.config -WEIGHT_TYPE MAP_WEIGHT -WEIGHT_SUFFIX ".weight.fits" -RESCALE_WEIGHTS N -COMBINE N -SUBTRACT_BACK N  -PIXEL_SCALE $PSCALE -CENTER_TYPE $CENTYPE -CENTER $CENTER -IMAGE_SIZE $IMAGE_SIZE -DELETE_TMPFILES N -RESAMPLE $RES -RESAMPLING_TYPE $RESAMPW -RESAMPLE_DIR $RDIR -RESAMPLE_SUFFIX ".resamp_$RESAMPW.fits" -PROJECTION_TYPE TAN -CELESTIAL_TYPE NATIVE -FSCALASTRO_TYPE $FCAL -INTERPOLATE $INTERPOLATE -OVERSAMPLING $OVERSAMPLING -FSCALE_KEYWORD $FSCALEKEY -VERBOSE_TYPE FULL >>& fs_swarp_$MJD.txt
		    # make resampled images (if resampling is different from weight resampling)
		    # NOTE IF WEIGHT_TYPE = NONE then SWARP creates its own weight map.  
			    if ( $RESAMP != $RESAMPW ) then
				echo resampling $name with: $RESAMP with no weight map, ignoring bad pixels
				$swarp @zcat_${filter}_${group}.txt -c $fsast/swarp.config -WEIGHT_TYPE NONE -RESCALE_WEIGHTS N -COMBINE N -SUBTRACT_BACK N  -PIXEL_SCALE $PSCALE -CENTER_TYPE $CENTYPE -CENTER $CENTER -IMAGE_SIZE $IMAGE_SIZE -DELETE_TMPFILES N -RESAMPLE $RES -RESAMPLING_TYPE $RESAMP -RESAMPLE_DIR $RDIR -RESAMPLE_SUFFIX ".resamp_$RESAMP.fits" -PROJECTION_TYPE TAN -CELESTIAL_TYPE NATIVE -FSCALASTRO_TYPE $FCAL -INTERPOLATE $INTERPOLATE -OVERSAMPLING $OVERSAMPLING -FSCALE_KEYWORD $FSCALEKEY -VERBOSE_TYPE FULL >>& fs_swarp_$MJD.txt
			    endif
			endif
		    endif

		# MAKE WEIGHT/ZERO LIST
weight:
#		    if ( -e $coadd ) then
#			echo moving to add zero-point 
##			goto addzp
#			goto addmjd
#		    endif
		    if ( $ilist == 1 ) then
			set wt2 = 0
		    else
			set wt2 = $wt
		    endif
		# CREATE INPUT LISTS FOR IMCOMBINE, note there is a charcter limit (line limit set by "limit descriptors"), so dont use full paths
		    rm -fr zcata_${filter}_${group}.txt >>& /dev/null
		    rm -fr zcatb_${filter}_${group}.txt >>& /dev/null
		    echo re-organizing SWARP output.  Moving files to their respective directories.  
#		    foreach var ( `cat zcat_${filter}_${group}.txt` )
		    foreach var ( `cat zcat_${filter}_${group}.txt` )
			# SWARP PLACES RESAMPLED OUTPUT IN CURRENT DIRECTORY, MOVE RESAMPLED IMAGE BACK TO REPESCTIVE DIRECTORIES.
			echo -n $var:h:r == $RDIR
			if ( $var:h == $RDIR ) then
			    echo " no need to move $var:h:r "
			else
			    # tricky.   _mef_v2  if multiple version exist they start as _mef.0001 then _mef_v2.0001
			    set tries =  (  ".000" "_v2.000" "_v3.000" "_v4.000" )  
			    foreach try ( $tries )
				if ( `ls $RDIR/$var:t:r${try}* >>& /dev/null ; echo $status` == 0 ) then
				    echo found $RDIR/$var:t:r${try}
				    ls $RDIR/$var:t:r$try*
				    echo " moving $RDIR/$var:t:r$try* to $var:h "
				    mv $RDIR/${var:t:r}${try}* $var:h
				    break
				else
				    echo no $RDIR/$var:t:r${try}
				endif
			    end
			    
			endif

			ls ${var:r}*resamp_$RESAMP.fits | grep 000"[$chips]".resamp | tee -a zcata_${filter}_${group}.txt > $var.list

			if ( $status ) then
			    echo Could not create list for $var
			    exit 1
			endif
#			$sethead @$var.list GWEIGHT=`$gethead -p -u @$var.list MODE FWHM_AVE EFFGAIN FLXSCALE | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1 ){a=a}else{a=a+$4/$5*10000000/($2*$3*$3);i++}}END{if(i==0){print 4000}else{print a/i} }'`
			$sethead @$var.list GWEIGHT=`$gethead -p -u @$var.list MODE FWHM_AVE EFFGAIN FLXSCALE STDDEV2 | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1 ){a=a}else{a=a+10000000/($5*$6*$6*$3*$3);i++}}END{if(i==0){print 4000}else{print a/i} }'`
#			rm -fr $var.list >>& /dev/null
		    end
#		    exit 0
		# SET CORRECT BPM PATH AND WEIGHT
		    foreach name2 ( `cat zcata_${filter}_${group}.txt` )
#			$sethead $name2 WEIGHT=`$gethead -p -u $name2 MODE FWHM_AVE EFFGAIN FLXSCALE | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1 ){print 4000}else{print $4/$5*10000000/($2*$3*$3)}}'`
			$sethead $name2 WEIGHT=`$gethead -p -u $name2 MODE FWHM_AVE EFFGAIN FLXSCALE STDDEV2 | awk '{if($0 ~ "___" || '$wt2' == 0 || $3<=0.1 ){print 4000}else{print 10000000/($5*$6*$6*$3*$3)}}'`
			if ( $RESAMP != $RESAMPW ) then
			    eval set name3 = `echo $name2 | awk '{sub("'$RESAMP'","'$RESAMPW'.weight"); print}'`
			else
			    set name3 = $name2:s/.fits/.weight.fits/
			endif
			# INITILIZE NAMES TO CURRENT NAMES
			set name4 = $name3
			set name5 = $name2
			if ( `pwd` != $name3:h ) then
			    @ new = 0
checkdup:
			    # IF THESE NAMES ARE ALREADY TAKEN (ie FROM ANOTHER NIGHT) CHANGE THE NAME.
			    if ( -e $name4:t || -l $name4:t ) then
				@ new ++
				set name4 = ${name3:r}_$new.${name3:e}
				set name5 = ${name2:r}_$new.${name2:e}
				goto checkdup
			    endif
			    # LINK NEW NAME TO ORIGINAL FILE.  
			    ln -s $name3 $name4:t
			    ln -s $name2 $name5:t
			endif
			echo $name5:t >> zcatb_${filter}_${group}.txt
			$sethead $name5:t BPM="$name4:t"
		    end


		    rm -f $tempdir/$coadd.weight0.txt >>& /dev/null
		    rm -f $tempdir/$coadd.zero.txt >>& /dev/null
		    $gethead -u @zcatb_${filter}_${group}.txt MJDAVE MEAN MODE STDDEV2 FWHM_AVE WEIGHT GWEIGHT SATURATE FLXSCALE FLASCALE CHIP | awk '{print}' > $tempdir/$coadd.weight_${filter}_${group}.txt
		# set weight to zero any image whose gweight is less than half the average upper fourth.
addmjd:
		    if ( 1 ) then
			set LWEIGHT2 = $LWEIGHT
		    else
			set LWEIGHT2 = 0.0     # DON'T THROW OUT ANY IMAGES DURING 1ST PASS.   THEY ARE NEEDED FOR FULL FIELD DETECTION AND MASKING OUT TO THE EDGES.
		    endif
		    set num = `cat $tempdir/$coadd.weight_${filter}_${group}.txt | wc -l`
		    set num = `echo "$num / 4 + 1" | bc`
		    set avew = `sort -k8 -gr $tempdir/$coadd.weight_${filter}_${group}.txt | head -n $num | awk '{rave = ( (NR-1)*rave + $8 ) / (NR) }END{print rave}'`
		    printf "\n\naverage weight of upper quartile = $avew , lower limit = $LWEIGHT2 \n"
		    awk '{if( $8 >= '0.000000'*'$avew' ){print $1} }' $tempdir/$coadd.weight_${filter}_${group}.txt > zcatb_${filter}_${group}.txt
		    awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print $1} }' $tempdir/$coadd.weight_${filter}_${group}.txt > zcata_${filter}_${group}.txt
		    awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print $7} }' $tempdir/$coadd.weight_${filter}_${group}.txt > $tempdir/$coadd.weight2_${filter}_${group}.txt
		    set TWEIGHT = `awk 'BEGIN {sum=0;i=0} {sum=sum+$1;i++} END{print sum/i}' $tempdir/$coadd.weight2_${filter}_${group}.txt `
		    printf "Average of input weights = $TWEIGHT \n"
		    awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print $10} }' $tempdir/$coadd.weight_${filter}_${group}.txt > $tempdir/$coadd.scale2_${filter}_${group}.txt
		    awk '{if( $8 >= '$LWEIGHT2'*'$avew' ){print '$FUDGE'*($3-$4)} }' $tempdir/$coadd.weight_${filter}_${group}.txt > $tempdir/$coadd.zero2_${filter}_${group}.txt
		    awk '{if( $8 <  '$LWEIGHT2'*'$avew' ){printf "%s rejected, weight = %10.0f \n",$1,$8 } }' $tempdir/$coadd.weight_${filter}_${group}.txt
		    printf "\n----------------------\n"

		    set fwhmtxt = fs_fwhm_${date}_${obj}_${MJD}_${filter}.txt
		    echo "Getting Image information for $fwhmtxt"
		    awk '{print }' $tempdir/$coadd.weight_${filter}_${group}.txt > $fwhmtxt
		    if ( -e $sm ) then
			$fsbin/fssm_fwhm.csh $avew $LWEIGHT2 `pwd` $fwhmtxt #>>& /dev/null
		    endif 
		    if ( -e $coadd ) then
			echo moving to add zero-point 
			goto addzp
		    endif
		    
		    cp $fsiraf/imcombine.par $tempdir/$coadd.par
		    sedi 's|imcombine.input =|imcombine.input = \"\@'`pwd`/zcata_${filter}_${group}.txt'\"|' $tempdir/$coadd.par
		    sedi 's|imcombine.output =|imcombine.output = \"'$coadd'\"|' $tempdir/$coadd.par
		    sedi 's|imcombine.expmasks = \"\"|imcombine.expmasks = \"'$coadde'[type=mask]\"|' $tempdir/$coadd.par
		    sedi 's|imcombine.bpmasks = \"\"|imcombine.bpmasks = \"'$coaddb'[type=mask]\"|' $tempdir/$coadd.par
		    sedi 's|imcombine.sigmas = \"\"|imcombine.sigmas = \"'$coadds'\"|' $tempdir/$coadd.par
		# USE AVERAGE, BETTER AT FIRST MOMENT MEASUREMENT
		    if ( $CTYPE == AVERAGE || $CTYPE == WEIGHTED ) then
			set ctype = average
		    else if ( $CTYPE == MEDIAN ) then
			set ctype = median
		    else
			set ctype = average
		    endif
		    sedi 's|imcombine.combine =|imcombine.combine = \"'$ctype'\"|' $tempdir/$coadd.par
		    sedi 's|imcombine.reject = \"none\"|imcombine.reject = \"'$REJTYPE'\"|' $tempdir/$coadd.par
#	            sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"mode\"|' $tempdir/$coadd.par
#	            sedi 's|imcombine.statsec = \"\"|imcombine.statsec = \"[5:2044,5:2044]\"|' $tempdir/$coadd.par
                    #    FOR REJTYPE
	            # FOR AVSIGCLIP
		    sedi 's|imcombine.lsigma = 3|imcombine.lsigma = 5|' $tempdir/$coadd.par
		    sedi 's|imcombine.hsigma = 3|imcombine.hsigma = 5|' $tempdir/$coadd.par
	            # FOR MINMAX
		    sedi 's|imcombine.nlow = 2|imcombine.nlow = 1|' $tempdir/$coadd.par
		    sedi 's|imcombine.nhigh = 2|imcombine.nhigh = 1|' $tempdir/$coadd.par
		    sedi 's|imcombine.nkeep = 1|imcombine.nkeep = 3|' $tempdir/$coadd.par
	            # FOR BPM
		    if ( 1 ) then
			if ( $BPM2 == 0 ) then
			    sedi 's|imcombine.masktype = \"none\"|imcombine.masktype = \"\!BPM badvalue\"|' $tempdir/$coadd.par
			else
			    sedi 's|imcombine.masktype = \"none\"|imcombine.masktype = \"\!BPM2 badvalue\"|' $tempdir/$coadd.par
			endif
			sedi 's|imcombine.maskvalue = \"0\"|imcombine.maskvalue = \"0\"|' $tempdir/$coadd.par
		    endif
		    sedi 's|imcombine.offsets = \"none\"|imcombine.offsets = \"wcs\"|' $tempdir/$coadd.par
		    if ( $wt == 1) then
			sedi 's|imcombine.weight = \"none\"|imcombine.weight = \"\@'$tempdir''$coadd'.weight2'_${filter}_${group}'.txt\"|' $tempdir/$coadd.par
		    endif
                    #  FOR EXPOSURE MAP, IF NOTHING, EXPOSURE MAP WILL BE THE NUMBER OF EXPOSURES.  IF EXPOSURES NOT THE SAME EXPTIME, USELESS, USE EFFGAIN (ORIGEXP*NLOOPS*GAIN)
		    sedi 's|imcombine.expname = \"\"|imcombine.expname = \"exposure\"|' $tempdir/$coadd.par
#		    sedi 's|imcombine.expname = \"\"|imcombine.expname = \"effgain\"|' $tempdir/$coadd.par
		    if ( 0 ) then
			sedi 's|imcombine.zero = \"none\"|imcombine.zero = \"mode\"|' $tempdir/$coadd.par
		    else
			sedi 's|imcombine.zero = \"none\"|imcombine.zero = \"\@'$tempdir''$coadd'.zero2'_${filter}_${group}'.txt\"|' $tempdir/$coadd.par
		    endif
	            # need to scale here, SWARP does NOT do it during the resampling process.
#		    sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"\@'$tempdir''$coadd'.scale2'_${filter}_${group}'.txt\"|' $tempdir/$coadd.par
#		    sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"\!iflxscale\"|' $tempdir/$coadd.par
		    sedi 's|imcombine.scale = \"none\"|imcombine.scale = \"\!'$FSCALEKEY'\"|' $tempdir/$coadd.par
		    sedi 's|imcombine.lthreshold = INDEF|imcombine.lthreshold = -65000|' $tempdir/$coadd.par
		    sedi 's|imcombine.hthreshold = INDEF|imcombine.hthreshold = 650000|' $tempdir/$coadd.par
	            # FOR SUBREGION
#		    sedi 's|imcombine.outlimits = \"\"|imcombine.outlimits = \"1 200\"|' $tempdir/$coadd.par

		else # IF SWARP COMBINE
		    rm -fr zcata_${filter}_${group}.txt
		    foreach var ( `cat zcat_${filter}_${group}.txt` )
			ls ${var:t:r}*resamp_$RESAMP.fits >> zcata_${filter}_${group}.txt
		    end
		endif # IMCOMBINE

	    # ACTUALLY COMBINE THE IMAGES
		if ( -e $coadd ) then
		    echo $coadd already exists!
		else
		    echo Creating: $coadd
		    if ( $IMCOMBINE == NORES ) then
			echo NOT COMBINING IMAGES... EXITING.
			exit 0
		    endif
		    if ( $IMCOMBINE == YES ) then
#			setenv imcombine_maxmemory 1000000000   # default IRAF  1GB
			setenv imcombine_maxmemory 55000000000   # default IRAF  1GB
			setenv imcombine_option 1
			echo Running imcombine... memory: $imcombine_maxmemory $imcombine_option nimages: `cat zcata_${filter}_${group}.txt | wc -l `
			rm -fr $coadd $coadde >>& /dev/null
			$images imcombine \@$tempdir/$coadd.par
			if ( $status || ! -e $coadd ) then
			    echo "Failed... Exiting"
			    exit 1
			endif
			
		    # CORRECT FOR ZP, IRAF SCALES TO FIRST INPUT IMAGE, SO MUST MULTIPLY BY THE FIRST SCALE TO GET ON COMMON ZP. 
			if ( 1 ) then
			    echo Correcting for ZP shift `gethead $coadd FLXSCALE | awk '{printf "%5.2f\n",$1}'` and astrometric resampling `gethead $coadd FLASCALE | awk '{printf "%5.2f\n",$1}'`
			    cp $fsiraf/imexpr.par $tempdir/$coadd.par2
			    mv $coadd ztmp.fits
			    sedi 's|imexpr.expr =|imexpr.expr = \"a*a.FLXSCALE*a.FLASCALE\"|' $tempdir/$coadd.par2
			    sedi 's|imexpr.a =|imexpr.a = \"ztmp.fits\"|' $tempdir/$coadd.par2
			    sedi 's|imexpr.output =|imexpr.output = \"'$coadd'\"|' $tempdir/$coadd.par2
			    $images imexpr \@$tempdir/$coadd.par2
			    rm -fr ztmp.fits
			endif
			
			wait
			echo deleting un-needed header keywords
			foreach key ( SOFTNAME SOFTVERS SOFTDATE SOFTAUTH SOFTINST COMBINET COMIN1 COMIN2 BACKMEAN ORIGFILE INTERPF BACKSUBF BACKTYPE BACKSIZE BACKFSIZ WCSDIM CDELT1 CDELT2 LTM1_1 LTM2_2 WAT0_001 WAT1_001 WAT2_001 ) 
			    if ( `gethead -u $coadd $key` != ___ ) then
				delhead $coadd $key
			    endif
			end
			foreach link ( `ls *weight*.fits` )
			    if ( -l $link ) then
				rm $link
			    endif
			end
		    else
			echo Running SWARP combine...
			set RES = Y
			$swarp @zcat_${filter}_${group}.txt -c $fsast/swarp.config -WEIGHT_TYPE $WTYPE -RESCALE_WEIGHTS Y -COMBINE Y -COMBINE_TYPE $CTYPE -SUBTRACT_BACK $SKYSUB -BACK_SIZE $BS -BACK_FILTERSIZE $BFS -PIXEL_SCALE $PSCALE -CENTER_TYPE $CENTYPE -CENTER $CENTER -IMAGE_SIZE $IMAGE_SIZE -DELETE_TMPFILES N -BLANK_BADPIXELS $BLANK_BADPIXELS -RESAMPLE $RES -RESAMPLING_TYPE $RESAMP -PROJECTION_TYPE TAN -CELESTIAL_TYPE NATIVE -FSCALASTRO_TYPE $FCAL -INTERPOLATE $INTERPOLATE -OVERSAMPLING $OVERSAMPLING -FSCALE_KEYWORD $FSCALEKEY -IMAGEOUT_NAME $coadd -WEIGHTOUT_NAME $coaddw
		    endif
		endif # if coadd dne
		wait
addzp:
		if ( ! -e $coadd ) then
		    echo Failed to create $coadd, exiting...
		    exit 1
		endif

		# UPDATE HEADER KEYWORDS
		echo Finding image parameters for $coadd
#		set avew = `sort -k8 -gr $tempdir/$coadd.weight_${filter}_${group}.txt | head -n $num | awk '{rave = ( (NR-1)*rave + $8 ) / (NR) }END{print rave}'`
#		set fwhmtxt = fs_fwhm_${date}_${obj}_${MJD}_${filter}.txt
		set EXP = `gethead $coadd EXPOSURE`
		set FLXSCALE = `gethead -u $coadd FLXSCALE`
		if ( $FLXSCALE == ___ ) then
		    set FLXSCALE = 1.0
		endif
		set FWHM = `awk 'BEGIN {ave=0;i=0}{{if($8 >= '$LWEIGHT'*'$avew'){ave=ave+($6);i++}}}END{if(i>0){print ave/i}else{print 0}}' $fwhmtxt `
		set BACK = `awk 'BEGIN {ave=0;i=0}{{if($8 >= '$LWEIGHT'*'$avew'){ave=ave+($4);i++}}}END{if(i>0){print ave/i/'$EXP'*('$PSCALE'/0.16)**2}else{print 0}}' $fwhmtxt `
		set BACKSIG = `awk 'BEGIN {ave=0;i=0}{{if($8 >= '$LWEIGHT'*'$avew'){ave=ave+($5);i++}}}END{if(i>0){print ave/i/sqrt(i)*('$PSCALE'/0.16)**1}else{print 0}}' $fwhmtxt `
		set SATURATE = `awk 'BEGIN {ave=0;i=0}{{if($8 >= '$LWEIGHT'*'$avew'){ave=ave+($9);i++}}}END{if(i>0){print (ave/i)}else{print 0}}' $fwhmtxt `
		set MJDAVE = `awk 'BEGIN {ave=0;i=0}{{if( $8 >= '$LWEIGHT2'*'$avew'){ave=ave+($2*$8);i=i+$8}}}END{if(i>0){printf "%11.5f\n",ave/i}else{print 0}}' $fwhmtxt `
		echo Setting image header keywords
		sethead $coadd SCALE=$PSCALE / "Arc-seconds per pixel"
		sethead $coadd BACKGND=$BACK / "Average Background Rate [e-/s] native pixels"
		sethead $coadd BACKSIG=$BACKSIG / "STDEV of Background [e-/s] native pixels"
		sethead $coadd SATURATE=$SATURATE / "[e-/s] resampled pixels"
		sethead $coadd FWHM_AVE=$FWHM 
		sethead $coadd MJDAVE=$MJDAVE / "Weighted MJD"

		# MAKE WEIGHT IMAGE
		if ( ! -e $coaddw  && 1 ) then
		    echo making weight image
		    cp $fsiraf/imexpr.par $tempdir/$coadd.par2
		    if ( `gethead -u $coadde MASKSCAL` != ___ ) then
			sedi 's|imexpr.expr =|imexpr.expr = \"a * a.MASKSCAL + a.MASKZERO \"|' $tempdir/$coadd.par2
		    else
			sedi 's|imexpr.expr =|imexpr.expr = \"a \"|' $tempdir/$coadd.par2
		    endif
		    sedi 's|imexpr.a =|imexpr.a = \"'$coadde'[1]\"|' $tempdir/$coadd.par2
		    sedi 's|imexpr.output =|imexpr.output = \"'$coaddw'\"|' $tempdir/$coadd.par2
		    $images imexpr \@$tempdir/$coadd.par2
#		    rm -fr $coadde
		endif
		
		if ( -e $coaddo ) then
		    printf "\n$coaddo already exists\n"
		    goto maskob
		endif

		printf "\nCreating $coaddo\n"
		if ( $ilist == 1) then
		    set agrow = 2.5
		else if ( $filter == J || $filter == J1 || $filter == J2 || $filter == J3 || $filter == NB-1.18 ) then
		    set agrow = $AREAGROW
		else if ( $filter == H || $filter == Hs || $filter == Hl ) then
		    set agrow = $AREAGROW
		else if ( $filter == Ks || $filter == NB-2.09 ) then
		    set agrow = $AREAGROW
		else
		    set agrow = $AREAGROW
		endif
		awk '{print}' <<EOF > $tempdir/zmask_${group}_$t0.csh
#!/bin/csh
    cd `pwd`
    $cp $fsiraf/detect.par $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.images = \"\"|detect.images = \"'${coadd}'\"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.objmasks = \"\"|detect.objmasks = \"'${coaddo}'[type=mask]\"|' $tempdir/zdet_${filter}_${group}.par
# comment exps out if experience arithmetic exceptions.
    $sedi 's|detect.exps = \"\"|detect.exps = \"'${coadde}'[1]\"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.masks = \"\"|detect.masks = \"'${coaddb}'[1]\"|' $tempdir/zdet_${filter}_${group}.par
    rm -f fs_mask_${filter}_${group}.bsky.fits
    rm -f fs_mask_${filter}_${group}.bsig.fits
    $sedi 's|detect.ngrow = 2|detect.ngrow = 32|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.agrow = 2.|detect.agrow = $agrow|' $tempdir/zdet_${filter}_${group}.par
# DETECTION PARAMETERS
    $sedi 's|detect.skytype = \"fit\"|detect.skytype = \"block\"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.fitxorder = 2|detect.fitxorder = 1|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.fityorder = 2|detect.fityorder = 1|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.convolve = \"bilinear 5 5\"|detect.convolve = \"gauss 3 3 1 1 \"|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.minpix = 6|detect.minpix = 4|' $tempdir/zdet_${filter}_${group}.par
    $sedi 's|detect.hsigma = 1.5|detect.hsigma = $HIDETECT|' $tempdir/zdet_${filter}_${group}.par
# NO REASON TO LOOK FOR NEGATIVE FEATURES
    if ( 0 ) then
	$sedi 's|detect.ldetect = no|detect.ldetect = yes|' $tempdir/zdet_${filter}_${group}.par
	$sedi 's|detect.lsigma = 10.|detect.lsigma = $HIDETECT|' $tempdir/zdet_${filter}_${group}.par
    endif

    $nproto detect @$tempdir/zdet_${filter}_${group}.par
wait
exit 0
EOF
		chmod 777 $tempdir/zmask_${group}_$t0.csh
		if ( $xgrid == 0 ) then
		    $tempdir/zmask_${group}_$t0.csh
		else
		    xgridx $tempdir/zmask_${group}_$t0.csh
		endif
		if ( ! -e $coaddo ) then
		    echo Something went wrong during DETECT... Exiting.
		    exit 1
		endif
# ADD CUSTOM OBJECT MASK
		if ( 1 ) then
		    echo "Searching for existing object masks."
		    rm -fr amsk_${filter}_${group}.obj
		# off image not good enough, if slightly offset would still like to mask edge of object. 
		    set naxis = `gethead $coadd NAXIS1 NAXIS2`
		    set omlist = $fsbin/mask.objects
		    set omlist2 = $fsbin/mask2.objects
		    awk '\!/#/ {print $1,$2,$3,$4,$5}' $omlist > $omlist2

		    if ( -e $omlist2 ) then
			sky2xy $coadd @$omlist2 | paste $omlist2 - | awk ' ! /offscale/ {if( ($10>-$4 && $10<$4+'$naxis[1]') && ($11>-$4 && $11<$4+'$naxis[2]') ){printf "# %s \ncircle (%f, %f, %f) \n",$5,$10,$11,$4/'$PSCALE3'}}' >> amsk_${filter}_${group}.obj
		    endif
		    if ( -e amsk_${filter}_${group}.obj ) then
			if ( ! -z amsk_${filter}_${group}.obj ) then
			    printf "\nMasking known object(s) at:\n        X    Y    RAD  \n"
			    cat amsk_${filter}_${group}.obj
			    mv amsk_${filter}_${group}.obj amsk_${filter}_${group}.obj.old
			    awk ' \! /#/ {print}' amsk_${filter}_${group}.obj.old > amsk_${filter}_${group}.obj ; rm amsk_${filter}_${group}.obj.old
			    rm -fr fsorg_mask_${filter}_${group}.tile.pl.fits fsreg_mask_${filter}_${group}.tile.pl >>& /dev/null
			    mv $coaddo fsorg_mask_${filter}_${group}.tile.pl.fits
			    cp $fsiraf/mskregions.par $tempdir/mask_${filter}_${group}.par
			    sedi 's|mskregions.regions = |mskregions.regions = \"amsk'_${filter}_${group}'.obj\"|' $tempdir/mask_${filter}_${group}.par
			    sedi 's|mskregions.masks = \"\"|mskregions.masks = \"fsreg_mask'_${filter}_${group}'.tile.pl\"|' $tempdir/mask_${filter}_${group}.par
			    # 2^23 = 8388608  bits 24-27 are reserved for detect.  hopefully there will not be more than 2^23 sources detected.    
			    sedi 's|mskregions.regval = 2|mskregions.regval = 8388608|' $tempdir/mask_${filter}_${group}.par
			    sedi 's|mskregions.refimages = \"\"|mskregions.refimages = \"'$coadd'\"|' $tempdir/mask_${filter}_${group}.par
			    cp $fsiraf/imexpr.par $tempdir/mask2_${filter}_${group}.par
			    sedi 's|imexpr.expr =|imexpr.expr = \"( a + b )\"|' $tempdir/mask2_${filter}_${group}.par
			    sedi 's|imexpr.a =|imexpr.a = \"fsorg_mask'_${filter}_${group}'.tile.pl.fits[1]\"|' $tempdir/mask2_${filter}_${group}.par
			    sedi 's|imexpr.b =|imexpr.b = \"fsreg_mask'_${filter}_${group}'.tile.pl\"|' $tempdir/mask2_${filter}_${group}.par
			    sedi 's|imexpr.output =|imexpr.output = \"'${coaddo}'[type=mask]\"|' $tempdir/mask2_${filter}_${group}.par
			    $proto mskregions \@$tempdir/mask_${filter}_${group}.par
			    $images imexpr \@$tempdir/mask2_${filter}_${group}.par
			else
			    printf "No Objects found in $omlist \n"
			endif
		    else
			printf "No Object list found \n"
		    endif
		endif

maskob:
		if ( -e $coaddm ) then
		    echo $coaddm already exists
		else
		    echo making mask image
		    cp $fsiraf/imstat.par $tempdir/z$filter.par
		    sedi 's|imstatistics.images =|imstatistics.images = \"'$coaddw'\"|' $tempdir/z$filter.par
		    sedi 's|imstatistics.fields =|imstatistics.fields = \"max\"|' $tempdir/z$filter.par
		    sedi 's|imstatistics.nclip = 3.|imstatistics.nclip = 0|' $tempdir/z$filter.par
		    set MAXEXP = `$images imstatistics \@$tempdir/z$filter.par`
		    set EFFRN = `gethead $coadd EFFRN`
		    set EXPOSURE = `gethead $coadd EXPOSURE`
		    set NCOMBINE = `awk 'BEGIN{printf "%8.2f\n",'$MAXEXP'/'$EXPOSURE'}'`
		    echo Original Exposure time per input frame: $EXPOSURE
		    echo Original Read noise per input frame: $EFFRN
		    echo Number of Overlapping frames: $NCOMBINE
		    set EFFRN = `awk 'BEGIN{printf "%6.2f\n",'$EFFRN'/sqrt('$NCOMBINE')}'`
		    set EFFGAIN = `gethead $coadd EFFGAIN`
		    echo Final Exposure time: $MAXEXP
		    echo Final Read Noise: $EFFRN
		    sethead $coadd EFFRN=$EFFRN / "Final Read-Noise [e-/pix]"
		    sethead $coadd EXPOSURE=$MAXEXP  / "Maximum Exposure time [s]"
		    sethead $coadd NCOMBINE=$NCOMBINE  / "Maximum number of overlapping Frames."
		    sethead $coadd GAIN=$EFFGAIN / "Final Gain"
		    sethead $coadd TWEIGHT=$TWEIGHT / "Average weight of input images"
		    sethead $coaddw TWEIGHT=$TWEIGHT / "Average weight of input images"

		    rm -fr $coaddm
		    cp $fsiraf/imexpr.par $tempdir/$coadd.par3
		    sedi 's|imexpr.expr =|imexpr.expr = \"(a>0.33*'$MAXEXP') ? b : 1 \"|' $tempdir/$coadd.par3
		    sedi 's|imexpr.a =|imexpr.a = \"'$coadde'[1]\"|' $tempdir/$coadd.par3
		    sedi 's|imexpr.b =|imexpr.b = \"'$coaddo'[1]\"|' $tempdir/$coadd.par3
		    sedi 's|imexpr.output =|imexpr.output = \"'$coaddm'\"|' $tempdir/$coadd.par3
		    $images imexpr \@$tempdir/$coadd.par3
		endif

		# EXPLICITLY FIND THE BACKGROUND NOISE  
		if ( 1 ) then
		    echo re-determining background noise
		    echo "OLD BACKSIG                    all pixels          = `gethead $coadd BACKSIG`"
		    $fsbin/backsig.csh $coadd $coaddm >& tmp.cat
		    set BACKSIG = `tail -n2  tmp.cat`
		    echo "NEW BACKSIG: $BACKSIG[1] pixels                        = $BACKSIG[2]"
		    echo "NEW BACKSIG: $BACKSIG[3] uncorrelated groups of pixels = $BACKSIG[4]"
		    sethead $coadd BACKSIG=$BACKSIG[2] / "Num = $BACKSIG[1]"
		    sethead $coadd BACKSIGC=$BACKSIG[4] / "Num = $BACKSIG[3]"
		endif
	    
	    endif # if swarp
#######################################
	# ADD ZEROPOINT TO HEADER	
	    if ( ($astroswarp == 1 || $psfex == 1) ) then
		$fsbin/fsred_zp.csh $coadd $coaddw $PSCALE $fsast $fsbin $sm $SEXFLAG $MJD
		if ( $domag == 1 && -e $coadd ) then
		    echo Performing custom photometry on $magfile
		    $fsbin/fsred_mag.csh $coadd $coaddw $fsast $magfile
		endif
	    endif
	# RUN PSFEX
	    if ( $psfex == 0 ) then
		echo Not Running PSFEX
	    else if ( `which psfex >>&/dev/null ; echo $status`) then
		echo PSFEX not found
	    else
		echo Running `sex -v`
		
		set MZP = `gethead -u -f $coadd MAGZPSTD MAGZPERR`
		if ( $MZP[1] == "___" ) then
		    set MZP = `gethead -u -f $coadd MAGZP MAGZPE`
		endif
		
# extract sources in final image from which to construct a PSF model
# NOTE: USING FLUX_AUTO and MAG_AUTO 
		sex $coadd -c $fsast/sex4.config -PARAMETERS_NAME $fsast/sex4.param -FILTER_NAME $fsast/default.conv -STARNNW_NAME $fsast/default.nnw -CATALOG_TYPE FITS_LDAC -CATALOG_NAME $coadd.cat -WEIGHT_TYPE MAP_WEIGHT -WEIGHT_GAIN Y -WEIGHT_IMAGE $coaddw -BACK_SIZE 32 -BACK_FILTERSIZE 4 -CHECKIMAGE_TYPE NONE -CHECKIMAGE_NAME $coadd.obj.fits -MAG_ZEROPOINT $MZP[1]
		set checkplot = $SCAMPI
		if($inter == 1) then
		    set checkplot = XWIN
		endif
# create PSF model from sources
# NOTE: USING FLUX_AUTO and MAG_AUTO
		echo Running `psfex -v`
		psfex $coadd.cat  -c $fsast/psfex.config -CHECKPLOT_DEV $checkplot
# use PSF model to re-extract sources
# NOTE: USING FLUX_AUTO and MAG_AUTO 
		echo Running `sex -v`
		sex $coadd -c $fsast/sex5.config -PARAMETERS_NAME $fsast/sex5.param -PSF_NAME $coadd.psf -FILTER_NAME $fsast/gauss_1.5_3x3.conv -STARNNW_NAME $fsast/default.nnw -CATALOG_TYPE ASCII -CATALOG_NAME $coadd.dat -WEIGHT_TYPE MAP_WEIGHT -WEIGHT_IMAGE $coaddw -BACK_SIZE 32 -BACK_FILTERSIZE 4 -CHECKIMAGE_TYPE "NONE" -CHECKIMAGE_NAME $coadd.nobj.fits -MAG_ZEROPOINT $MZP[1]

		if ( -e $sm ) then
		    $fsbin/fssm_psf.csh 0 `pwd` $coadd.dat
		endif
	    endif
	end # MULTIPLE GROUPS
    end # MULTIPLE PHOT (FILTERS)
################################################################################
    wait
    set tf = `date +%s`
    printf "Time elapsed: %6.2f min.  DONE.  \n" `echo "($tf-$t0)/60" | bc -l`
################################################################################

cleanup:
cd $dest
if ( $rflag ) then
    echo `pwd`

    printf "\nRemoving Intermediate data products\n"
    foreach chip ( 1 2 3 4 )
    foreach folder ( FLATS SKYS ) 
#	rm -f $folder/${NPREFIX}*_c[$chip]*.fits >>& /dev/null
#	rm -f $folder/${NPREFIX}*_c[$chip].fits.pl.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip].fits.pl.tmp.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip].fits.sky*.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip].fits.cr.pl.fits >>& /dev/null
#	rm -f $folder/${NPREFIX}*_c[$chip].fits.1.pl.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits.b1.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits.b1.fits.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits.b1.fits.fits.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.remap.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.remap.pl.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.diff.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.diff.pl.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.diffsig.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.diffsky.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.obj.pl >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.stats >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.dat >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sex >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sex1 >>& /dev/null
	rm -f $folder/${NPREFIX}*mef*000[$chip]*resamp* >>& /dev/null
	rm -f $folder/${NPREFIX}*mef.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*mef.mask.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*mef.weight.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*mef.cat >>& /dev/null
    end

    foreach folder ( TARGETS ) 
	rm -f $folder/${NPREFIX}*_c[$chip].fits.sky*.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits.b1.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits.b1.fits.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sub.fits.b1.fits.fits.fits >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.stats >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.dat >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sex >>& /dev/null
	rm -f $folder/${NPREFIX}*_c[$chip]*.sex1 >>& /dev/null
	rm -f $folder/${NPREFIX}*mef*000[$chip]*resamp* >>& /dev/null
	rm -f $folder/${NPREFIX}*mef.mask.fits >>& /dev/null
    end
    end

    rm -fr tmp >>& /dev/null

endif

exit 0

