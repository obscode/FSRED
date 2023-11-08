#! /bin/csh
#
#    specify time on screen and select models
set wl = $1
set ll = $2
set fsloc = $3
set file = $4
set psfile = "$3/$4:r.ps"
set ctype = black
set wait = 0
########################################################################
#   Start SM
#
#sm -S << FIN
/usr/local/bin/sm -S << FIN

define wait $wait

# do not alter the code above this line

# The following line outputs checks if the user has enetered a 'wait' time >1
# if the 'wait' time from the command line is 0, then the output is sent to a file
#
# to output to gif rather than postscript, uncomment the second line and 
# comment out the first line # output to .ps
if (\$wait) {device x11} else {dev postencap $psfile}   

#  Type your sm commands here. An example is provided
#!pwd

    add_ctype gray1		 200 200 200

    if ( 1 ) {
    data "$file"
    read {name 1.s mjd 2 mean 3 mode 4 stddev 5 fwhm 6 weight 7 gweight 8 sat 9 scale 10 ascale 11 chip 12.s }
    set chips = atof(chip)
    vecminmax chips _min _max
    set name2 = substr(name,5,4) if(chip == '\$_min' )

    set fwhm = (fwhm <= 0) ? 1 : fwhm
#    set weight = (gain/scale*10000000/(mode*fwhm**2))
    set off = int(mjd[0])
    set mjd = mjd - off


    set corr = int(mjd/50)
    
#    print {mjd corr }
    set mjd = abs(mjd) < 2 ? mjd : mjd - int(mjd) + corr


    set mjd2 = mjd if(chip == '\$_min' )

    toplabel FOURSTAR CONDITIONS: $file  # add a label, starting at 250 8.5e7



    window -1 -5 1 5 # define a window which is 2 in x, 1 in y 
    ticksize 0 0 0 0
#    ptype 2 1  # sides | 1-closed 2-skeletal 3-open
    ptype chip
    lweight 1.

    limits mjd fwhm
    ctype black
    box 4 2 0 0 # label all of the axis except the RHS y-axis
    ylabel FWHM arc-sec
    expand 1.0 # make the points twice the size
    ctype black
#    ptype 3 3 
    ptype chip
    points mjd fwhm # draw the points in x and y


    window -1 -5 1 4
    ctype black
    expand 1
    limits mjd mode
    box 4 2 0 0 
    ylabel "MODE e-/s"
    expand 1.0 # make the points twice the size
    ctype black
#    ptype 4 3
    ptype chip
    points  mjd mode # draw the points in x and y

    window -1 -5 1 3
    ctype black
    expand 1
    limits mjd stddev
    box 4 2 0 0 
    ylabel "STDDEV"
    expand 1.0 # make the points twice the size
    ctype black
#    ptype 4 3
    ptype chip
    points  mjd stddev # draw the points in x and y



    window -1 -5 1 2
    expand 1 
    limits mjd weight
    box 0 2 0 0
    ylabel WEIGHT
#    xlabel MJD - \$(off[0])

    expand 1
#    ptype 30 3  # sides | 0-open 1-skeletal 2-starred 3-solid
    ptype chip
    points mjd weight

    expand 3
    lweight 3
    ptype 4 1
#    ptype chip
    points mjd weight if (weight < $wl*$ll )
    expand 1
    lweight 1

    ltype 1 # change the line type
    relocate -100 $wl
    draw 100 $wl
    relocate -100 \$($wl*$ll)
    draw 100 \$($wl*$ll)

    expand 1.0


    window -1 -5 1 1
    expand 1 
    limits mjd 0 3
#    box 1 2 0 0
#    ylabel WEIGHT
    ptype name2
    angle 90
    set nameloc = 0,dimen(name2)-1
    set nameloc = (nameloc % 5) - 1.5
#    print {mjd2 nameloc}
    points mjd2 nameloc

#    xlabel MJD - \$(off[0])


    }


# do not alter below this line

!sleep \$wait
FIN

exit

