# FSRED
Repository for the FSRED FourStar data reduction pipeline. This pipeline was
originally authored by Andy Monson and is now maintained by the Carnegie
Observatories software support group.

## Required software

FSRED requires the following to be in working order on your computer:

 - GCC C compiler
 - [IRAF](https://iraf-community.github.io/)
 - [Source Extractor](https://www.astromatic.net/software/sextractor/)
 - [SCAMP](https://www.astromatic.net/software/scamp/)
 - [SWarp](https://www.astromatic.net/software/swarp/)
 - [WCSTools](http://tdc-www.harvard.edu/wcstools/)
 - [GSL Libraries](https://www.gnu.org/software/gsl/)
 - [CFITSIO Libraries](https://heasarc.gsfc.nasa.gov/fitsio/)

There is an install script in the distribution which will try to install
versions of the above, but they are out of date for modern operating 
systems. Best to use your OS' package tool (e.g., homebrew for MacOS, 
dnf for RedHat-based systems, etc).
