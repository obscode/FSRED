#!/bin/csh -f

# TURN OFF SHELL EXPANSION (ie * )
set noglob
set pi = `awk 'BEGIN{print atan2(0,-1)}'`
awk 'BEGIN { print '$*' } \
function log10(x)	{ return log(x)/log(10) } \
function abs(x)		{ if(x~"-"){ return -x } else { return x }} \
function sign(x)	{ if(x~"-"){ return -1 } else { return 1 }} \
function asin(x)	{ return atan2(x,(1.-x^2)^0.5) } \
function acos(x)	{ return atan2((1.-x^2)^0.5,x) } \
function atan(x)	{ return atan2(x,1) } \
function frac(x)        { return x-int(x) } \
function nint(x)        { return sign(x)*int(abs(x)+0.5) } \
function r2d(x)         { return x*180/'$pi' } \
function d2r(x)         { return x*'$pi'/180 } \
function s2d(x)         { if(x~":"){split(x,a,":");return sign(a[1])*(abs(a[1])+a[2]/60+a[3]/3600) } else { return x} }  \
function s2t(x)         { if(x~":"){split(x,a,":");return 15*(a[1]+a[2]/60+a[3]/3600) } else { return x } }  \
function d2s(x)         { printf "%s:%s:%s", int(x),int(frac(x)*60),frac( frac(x)*60 )*60  }  \
function ads(r1,d1,r2,d2){ return r2d(acos( (sin(d2r(s2d(d1)))*sin(d2r(s2d(d2)))) +cos(d2r(s2d(d1)))*cos(d2r(s2d(d2)))*cos(d2r(s2t(r1)-s2t(r2))) ))  } \
'

# s2d is (s)exigesimal (2)to (d)ecimal.  sexigesimal coordinated must be encased in quotes (treated as string). If no ":" delimiter is found the inpur is treated as already being in decimal format.  

# ads is (a)stronomical (d)istance on a (s)phere where d1 and d2 are the decliniations of 2 objects and r1 and r2 are the right ascensions of the 2 objects.  
#/Users/amonson/software/FSRED/bin/calc.csh 'ads("03:32:45","-87:54:38","03:32:45","87:54:38")'

exit $status
