# FSRED
Repository for the FSRED FourStar data reduction pipeline. This pipeline was
originally authored by Andy Monson and is now maintained by the Carnegie
Observatories software support group.

## Required software

FSRED requires the following to be in working order on your computer (the versions
in parentheses are those known to work with the current version):

 - GCC C compiler
 - [IRAF](https://iraf-community.github.io/) (2.17)
 - [Source Extractor](https://www.astromatic.net/software/sextractor/) (2.28.0)
 - [SCAMP](https://www.astromatic.net/software/scamp/) (2.10.0)
 - [SWarp](https://www.astromatic.net/software/swarp/) (2.41.5)
 - [WCSTools](http://tdc-www.harvard.edu/wcstools/) (3.9.7)
 - [GSL Libraries](https://www.gnu.org/software/gsl/) (1.15)
 - [CFITSIO Libraries](https://heasarc.gsfc.nasa.gov/fitsio/) (4.3.0)
 - [FSRED Calibration Files](https://users.obs.carnegiescience.edu/cburns/FSRED/FSRED_calib.tgz)
   These should be extracted into the base FSRED folder.

There is an install script in the distribution which will try to install
versions of the above, but they are out of date for modern operating 
systems. Best to use your OS' package tool (e.g., homebrew for MacOS, 
dnf for RedHat-based systems, etc).
