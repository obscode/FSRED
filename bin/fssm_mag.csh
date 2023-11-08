#! /bin/csh
#
#    specify time on screen and select models
set wait = $1
set fsloc = $2
set filter = $3
set SATURATE = $4
set PIXS = $5
set FWHM = $6
set MZP = $7
set MZE = $8
set MZN = $9
set group = $10
set psfile = $fsloc/fs_zp_${filter}_${group}.ps
set ctype = black
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
# comment out the first line
if (\$wait) {device x11} else {dev postencap $psfile}   # output to .ps

#  Type your sm commands here. An example is provided
!pwd

    add_ctype gray1		 200 200 200

#    set corr = -5*lg($PIXS/0.16)
    set corr = 0


    if ( 1 ) {
    data "2coadd_${filter}_${group}.coo"
    read {2mass_mag 6 2mass_err 7 4star_mag 16 4star_err 17 sexflag 18}
    set 4star_mag = 4star_mag + corr

    if ( $MZN > 0 ) {
	data "2coadd_${filter}_${group}.mag"
	read {2mass 1 2masse 2 4star 3 }
	set 4star = 4star + corr
	set temp2 = (2mass - 4star)
    }


    window 1 1 1 1 # define a window which is 2 in x, 1 in y 
    ticksize 0 0 0 0
    ptype 2 1  # sides | 1-closed 2-skeletal 3-open
    lweight 1.
    set temp = (2mass_mag - 4star_mag)

    define x1 8
    define x2 16.5

#    vecminmax temp y1 y2
    define y1 \$($MZP-1)
    define y2 \$($MZP+1)


    if ( 0 ) {

    if ( '$filter' == 'J' ){
	define y1 26
	define y2 28
    }
    if ( '$filter' == 'J1' ){
	define y1 25
	define y2 27
    }
    if ( '$filter' == 'J2' ){
	define y1 25
	define y2 27
    }
    if ( '$filter' == 'J3' ){
	define y1 25.7
	define y2 27.7
    }
    if ( '$filter' == 'H' ){
	define y1 26
	define y2 28
    }
    if ( '$filter' == 'Hs' ){
	define y1 26
	define y2 28
    }
    if ( '$filter' == 'Hl' ){
	define y1 26
	define y2 28
    }
    if ( '$filter' == 'Ks' ){
	define y1 25
	define y2 27
    }

    }

    limits \$x1 \$x2 \$y1 \$y2
    box 1 2 0 0 # label all of the axis except the RHS y-axis
    expand 1.0 # make the points twice the size
    ctype gray1
    ptype 4 1 


    points 2mass_mag temp # draw the points in x and y
#    error_x 2mass_mag temp 2mass_err
#    error_y 2mass_mag temp 2mass_err
    expand 2.0 # make the points twice the size
    ctype black
    ptype 30 3  # sides | 0-open 1-skeletal 2-starred 3-solid
    if ( $MZN > 0 ) {
	points 2mass temp2 # draw the points in x and y
	error_x 2mass temp2 2masse
	error_y 2mass temp2 2masse
    }


    ctype $ctype
    expand 1.0 # set the rest of the plot back to normal size
    ltype 1 # change the line type
    toplabel 2MASS ZEROPOINT  # add a label, starting at 250 8.5e7
    expand 0.8  # label the x and y axis
    xlabel 2MASS
    ylabel 2MASS - 4STAR
    expand 1.0

    if ( $MZN > 0 ){
#	set ONE = 1+0*2mass
#	set DESIGN = {ONE}
	set MEAS = 2mass - 4star
	set W = 1/2masse**2
#	linfit DESIGN MEAS A VARA
#	set ZP = \$(A[0])
#	set SIGA = sqrt(VARA)

	set ZPN = dimen(MEAS)
	set ZP = sum(MEAS*W)/sum(W)
	set SIGA = sqrt(1/sum(W))


    } else {
	set ZP = $MZP
	set SIGA = $MZE
	set ZPN = $MZN
    }



    relocate 0 \$(ZP[0])
    draw 100 \$(ZP[0])
    relocate (5000 5000)
    label ZP = \$(sprintf('%7.3f',\$(ZP[0])))+-\$(sprintf('%4.3f',\$(SIGA[0]))):n=\$(ZPN)

    set SATURATE = -2.5*lg($SATURATE/$PIXS/$PIXS)+ZP
    set SATURATE2 = -2.5*lg($SATURATE/0.88*( $FWHM / $PIXS )**2)+ZP
    ltype 2
#    relocate \$(SATURATE[0]) 0
#    draw \$(SATURATE[0]) 30
#    relocate (5000 20000) label Saturation



    ltype 3
    relocate \$(SATURATE2[0]) 0
    draw \$(SATURATE2[0]) 30


    
    }


# do not alter below this line

!sleep \$wait
FIN

exit

