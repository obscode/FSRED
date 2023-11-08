#! /bin/csh
#
#    specify time on screen and select models
set wait = $1
set fsloc = $2
set input = $3
set psfile = $2/fs_ps.ps
set ctype = black
########################################################################
#   Start SM
#
sm -S << FIN
define wait $wait

# do not alter the code above this line

# The following line outputs checks if the user has enetered a 'wait' time >1
# if the 'wait' time from the command line is 0, then the output is sent to a file
#
# to output to gif rather than postscript, uncomment the second line and 
# comment out the first line
if (\$wait) {device x11} else {dev postencap $psfile}   # output to .ps

#  Type your sm commands here. An example is provided
!pwd


    data "$input"
    read {xpsf 1.f ypsf 2.f xepsf 3.f yepsf 4.f rapsf 5.f decpsf 6.f raepsf 7.f decepsf 8.f fpsf 9.f fepsf 10.f mpsf 11.f mepsf 12.f niter 13 chi2 14.f}
    read {xwin 15.f ywin 16.f xewin 17.f yewin 18.f rawin 19.f decwin 20.f raewin 21.f decewin 22.f fauto 23.f feauto 24.f mauto 25.f meauto 26.f}
    read {fmax 27 frad 28 elong 29 fwhm 30 class 31 flag 32}

    ctype $ctype

    window 1 1 1 1 # define a window which is 2 in x, 1 in y 
    ticksize 0 0 0 0
    ptype 1 1  # sides | 1-closed 2-skeletal 3-open
    lweight 1.
    limits 15 25 0 0.4
    box 1 2 0 0 # label all of the axis except the RHS y-axis
    expand 2.0 # make the points twice the size
    points mauto meauto # draw the points in x and y
    ctype red
    points mpsf mepsf # draw the points in x and y
    ctype $ctype
    expand 1.0 # set the rest of the plot back to normal size
    ltype 1 # change the line type
    toplabel MAG vs. MAGERR  # add a label, starting at 250 8.5e7
    expand 0.8  # label the x and y axis
    xlabel MAG
    ylabel MAGERR
    expand 1.0

    page 

    window 1 1 1 1 # define a window which is 2 in x, 1 in y 
    ticksize 0 0 0 0
    ptype 1 1  # sides | 1-closed 2-skeletal 3-open
    lweight 1.
    limits 15 25 -2 2
    box 1 2 0 0 # label all of the axis except the RHS y-axis
    expand 2.0 # make the points twice the size
    points mpsf (mpsf-mauto) # draw the points in x and y
    expand 1.0 # set the rest of the plot back to normal size
    ltype 1 # change the line type
    toplabel MAG_PSF vs MAG_AUTO  # add a label, starting at 250 8.5e7
    expand 0.8  # label the x and y axis
    xlabel MAG_PSF
    ylabel MAG_PSF - MAG_AUTO
    expand 1.0

    page 
    
    window 1 1 1 1 # define a window which is 2 in x, 1 in y 
    ticksize 0 0 0 0
    ptype 1 1  # sides | 1-closed 2-skeletal 3-open
    lweight 1.
    limits 0 15 25 15
    box 1 2 0 0 # label all of the axis except the RHS y-axis
    expand 2.0 # make the points twice the size
    points fwhm mauto # draw the points in x and y
    ctype red
    points fwhm mpsf # draw the points in x and y
    ctype $ctype
    expand 1.0 # set the rest of the plot back to normal size
    ltype 1 # change the line type
    toplabel FWHM vs MAG_AUTO   # add a label, starting at 250 8.5e7
    expand 0.8  # label the x and y axis
    xlabel FWHM [pixels]
    ylabel MAG
    expand 1.0

    page 

    window 1 1 1 1 # define a window which is 2 in x, 1 in y 
    ticksize 0 0 0 0
    ptype 1 1  # sides | 1-closed 2-skeletal 3-open
    lweight 1.
    limits 0 15 0 1
    box 1 2 0 0 # label all of the axis except the RHS y-axis
    expand 2.0 # make the points twice the size
    points fwhm class # draw the points in x and y
    expand 1.0 # set the rest of the plot back to normal size
    ltype 1 # change the line type
    toplabel FWHM vs. CLASS # add a label, starting at 250 8.5e7
    expand 0.8  # label the x and y axis
    xlabel FWHM 
    ylabel CLASS
    expand 1.0

# do not alter below this line

!sleep \$wait
FIN

exit

