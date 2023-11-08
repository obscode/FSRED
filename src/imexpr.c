/* File imexpr.c
 * Apr 02, 2012
 * By Andy Monson
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <fitsio.h>
#include <gsl/gsl_multifit.h>
#include <gsl/gsl_errno.h> 
#include <gsl/gsl_interp.h> 
#include <gsl/gsl_spline.h>  
#include <gsl/gsl_blas.h> 
#include <gsl/gsl_statistics_double.h>
#include <gsl/gsl_statistics.h>
#include <gsl/gsl_sort.h>


static void PrintUsage();
static char *RevMsg = "imexpr 0.0, 10 April 2012, Andy Monson (monson.andy@gmail.com)";
static int version_only = 0;		/* If 1, print only program name and version */


void printerror( int status);

int main(int argc, char *argv[])
    {
      int verbose = 0;		/* verbose/debugging flag */
      fitsfile *infptr1=NULL, *infptr2=NULL, *infptr3=NULL, *infptr4=NULL, *infptr5=NULL, *outfptr1=NULL, *outfptr2=NULL;  /* pointer to the FITS files */
      char *str=NULL, *odir=NULL, *list=NULL, *limg=NULL, *dimg=NULL, *fimg=NULL, *bimg=NULL;
      int cflag = 0, hdrflag = 0;
      char card[FLEN_CARD],rmode[FLEN_CARD]; 
      char line[256], name[256], aname[256]="", bname[256]="", hname[256], hrname[256], outname[256], outname2[256], outname3[256];
      int status = 0,  nkeys, naxis, tstatus, single=0, bitpix, hdunum, hdutype, hdupos; /* MUST initialize status */
      int nulval = 0, anyval;
      int ii, jj, kk, xnum, totpix, chip, endloop=0;  
      double ncoadd = 0;
      long naxes[3], fpixel[3], lpixel[3], inc[3];
      double *outtmp=NULL, *outpix=NULL, *lpix=NULL, *dpix=NULL, *fpix=NULL, exptime = 1.0, tsb = 1.0, saturate;
      double pr1x, pr1y, pr2x, pr2y, rpr1x, rpr1y, rpr2x, rpr2y, epoch, equinox=2000.0, ra, dec, lat, rot;
      double dx, dy, dr=0, cd11, cd12, cd21, cd22, scale, rn, egain, gain, again=1, pi, tmpvar;
      int *bpix=NULL, *bout=NULL;
      double *inpix=NULL;
      double limgval=0.;
      int nback = 0, pborder=0;
      double back = 0, backsig = 0, backt = 0;
      int ni,nj,ngrow,stride,tsize;
      int crosstalk = 0;
      int celect  = 0;
      int FOWL = 1;   /* FOR ALL CDS IMAGES */
      double mjdave = 0, mjd;

      limg = "0";
      dimg = "0";
      fimg = "1";
      bimg = "0";


      ngrow = 10; /* default maximum crater size */
      scale = 0.16/3600.0;
      pi = 4.0*atan(1);
      naxis = 2;
      naxes[0] = naxes[1] = 2048;
      xnum = naxes[0]*naxes[1];

/* Check for help or version command first */
  str = *(argv+1);
  if (!str || !strcmp (str, "help") || !strcmp (str, "-help"))
    PrintUsage(str);
  if (!strcmp (str, "version") || !strcmp (str, "-version")) {
    version_only = 1;
    PrintUsage(str);
  }
/* Decode arguments */
  for (argv++; --argc > 0 && *(str = *argv) == '-'; argv++) {
    char c;
    while ((c = *++str))
      switch (c) {
	
      case 'a':	/* crosstalk masking */
	crosstalk = atoi(*(argv+1));
	/* printf("%s\n",cflag); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'b':       /* bad pixel mask */
	bimg = *(argv+1);
	/* printf("%s\n",bimg); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'c':	/* combine beforehand */
	cflag = atoi(*(argv+1));
	/* printf("%s\n",cflag); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'd':       /* output directory */
	if (argc < 2)
	  PrintUsage (str);
	odir = *(argv+1);
	if ( verbose ) printf("Output dir:  %s\n",odir);
	argc--;
	argv++;
	break;

      case 'e':       /* convert to electrons */
	if (argc < 2)
	  PrintUsage (str);
	celect = atoi(*(argv+1));
	if ( verbose ) printf("Converting image to electrons: %d\n",celect);
	argc--;
	argv++;
	break;


      case 'f':       /* flat frame */
	if (argc < 2)
	  PrintUsage (str);
	fimg = *(argv+1);
	if ( verbose ) printf("flat image:     %s\n",fimg);
	argc--;
	argv++;
	break;

      case 'g':       /* grow limit for saturated stars */
	if (argc < 2)
	  PrintUsage (str);
	ngrow = atoi(*(argv+1));
	if ( verbose ) printf("SATURATION grow size: %d\n",ngrow);
	argc--;
	argv++;
	break;
	
      case 'i':       /* input image list */
	list = *(argv+1);
	/* printf("%s\n",list); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'k':       /* dark image */
	if (argc < 2)
	  PrintUsage (str);
	dimg = *(argv+1);
	if ( verbose ) printf("dark image:     %s\n",dimg);
	argc--;
	argv++;
	break;

      case 'l':       /* linearity image */
	if (argc < 2)
	  PrintUsage (str);
	limg = *(argv+1);
	if ( verbose ) printf("linearity image:%s\n",limg);
	argc--;
	argv++;
	break;

      case 'p':       /* picture frame around border */
	if (argc < 2)
	  PrintUsage (str);
	pborder = atoi(*(argv+1));
	if ( verbose ) printf("Include border: %d\n",pborder);
	argc--;
	argv++;
	break;

      case 'v':	/* more verbosity */
	if (argc < 2)
	  PrintUsage (str);
	verbose = atoi(*(argv+1));
	if ( verbose ) printf("Verbose output\n");
	argc--;
	argv++;
	break;

      default:
	/* printf("%s\n",*(argv+1)); */
	PrintUsage(str);
	break;
      }
  }


  /*  open linearization images  */
  if ( ! strstr(limg,".fits")) {
    limgval = atof(limg);
    if ( verbose ) printf("Using constant linearity: %8.3e \n",limgval);
  } else {
    if ( fits_open_file(&infptr2, limg, READONLY, &status) )
      printerror( status );
    /* get image dimension from one of the calibration images */
    fits_get_img_param(infptr2, 3, &bitpix, &naxis, naxes, &status );
    xnum = naxes[0] * naxes[1];
  }
  
  /*  open dark image if supplied  */
  if ( ! strstr(dimg,".fits")) {
    printf("Not subtracting dark \n");
  } else {
    if ( fits_open_file(&infptr3, dimg, READONLY, &status) )
      printerror( status );
    if(fits_read_key(infptr3, TDOUBLE, "EXPTIME", &tsb, NULL, &status)){
      tsb = 1.0;
      status = 0;
    }
  }
  /* force exptime to unity since I know the calibration darks were normalized to 1s */
  if ( 0 ) {
    tsb = 1.0;
  }
  /*  open flat images  */
  if ( ! strstr(fimg,".fits")) {
    printf("Not applying flat \n");
  } else {
    if ( fits_open_file(&infptr4, fimg, READONLY, &status) )
      printerror( status );
  }
  /*  open bpm images  */
  if ( ! strstr(bimg,".fits")) {
    printf("Not using BPM \n");
  } else {
    if ( fits_open_file(&infptr5, bimg, READONLY, &status) )
      printerror( status );
  }


      if (verbose) printf("%d %ld %ld %ld %d\n",naxis,naxes[0],naxes[1],naxes[2],xnum);
      /* allocate memory */
      inpix = (double *) malloc(xnum * sizeof(double)); /* memory for 2d image */
      bpix = (int *) malloc(xnum * sizeof(int)); /* memory for 2d image */
      bout = (int *) malloc(xnum * sizeof(int)); /* memory for 2d image */
      outtmp = ( double *) malloc(xnum * sizeof(double)); /* memory for 2d mask */
      outpix = ( double *) malloc(xnum * sizeof(double)); /* memory for 2d mask */
      lpix = (double *) malloc(xnum * sizeof(double)); /* memory for output 2d image */
      dpix = (double *) malloc(xnum * sizeof(double)); /* memory for output 2d image */
      fpix = (double *) malloc(xnum * sizeof(double)); /* memory for output 2d image */
      if (inpix == NULL || outpix == NULL || lpix == NULL || dpix == NULL || fpix == NULL || bpix == NULL || bout == NULL || outtmp==NULL ) {
	printf("Memory allocation error\n");
	return(1);
      }
/* READ IN LINEARITY WHICH IS THE SECOND PLANE OF A 3D IMAGE CUBE */
      inc[0] = inc[1] = inc[2] = 1;
      fpixel[0] = 1;
      fpixel[1] = 1;
      fpixel[2] = 2;
      lpixel[0] = naxes[0];
      lpixel[1] = naxes[1];
      lpixel[2] = 2;
      if ( infptr2 == NULL ) {
	for (ii=0;ii<xnum;ii++){
	  lpix[ii] = (float)limgval;
	}
	/* ONLY FOR CHAR */
	/* memset(lpix,limgval,xnum); */
      } else {
	if (fits_read_subset(infptr2, TDOUBLE, fpixel, lpixel, inc, &nulval, lpix, &anyval, &status))
	  printerror(status);   /* jump out of loop on error */
	if ( fits_close_file(infptr2, &status) )
	  printerror( status );
      }
/* READ THE REMAINING CALIBRATION IMAGES */
      fpixel[0] = 1;
      fpixel[1] = 1;
      fpixel[2] = 1;
      lpixel[0] = naxes[0];
      lpixel[1] = naxes[1];
      lpixel[2] = 1;
/* DARK */
      if ( ! strcmp(dimg,"0") ) {
	printf("Dark is zero \n");
/* 	memset(dpix,0,xnum); */
      } else {
	if (fits_read_subset(infptr3, TDOUBLE, fpixel, lpixel, inc, &nulval, dpix, &anyval, &status))
	  printerror(status);   /* jump out of loop on error */
	if ( fits_close_file(infptr3, &status) )
	  printerror( status );
      }
/* FLAT */
      if ( ! strcmp(fimg,"1") ) {
	printf("FLAT is unity \n");
	/* memset(fpix,1,xnum); */
	for (ii = 0; ii < xnum; ii++) {
	  fpix[ii] = 1;
	}
      } else {
	if (fits_read_subset(infptr4, TDOUBLE, fpixel, lpixel, inc, &nulval, fpix, &anyval, &status))
	  printerror(status);   /* jump out of loop on error */
	if ( fits_close_file(infptr4, &status) )
	  printerror( status );
      }
/* BPM */
      if ( ! strcmp(fimg,"1") ) {
	printf("NO BPM \n");
      } else {
	fits_get_num_hdus(infptr5, &hdunum, &status);
	if ( hdunum > 1)
	  fits_movrel_hdu(infptr5, 1, NULL, &status);  /* try to move to next HDU */
	if (fits_read_pix(infptr5, TINT, fpixel, xnum, &nulval, bpix, &anyval, &status))
	  printerror(status);   /* jump out of loop on error */
	if ( fits_close_file(infptr5, &status) )
	  printerror( status );     
      }
/* loop over images */
      /* printf("STARTING THE LOOP \n"); */
      FILE *input = fopen(list,"r");
      while (fgets(line,100,input) !=NULL){
	if(line[0]=='#') continue;
	if(sscanf(line,"%s",name)!=1) continue;
	strncpy( hname, strstr(name,"fsr_") ,8);
	hdrflag = 0;
	if( strcmp(hname, hrname) ) {
	  if (verbose) printf("New Run\n");
	  strcpy(hrname,hname);	  
	  hdrflag = 1;
	}

	if ( cflag == 1 ) {
	  strncpy( aname, strstr(name,"fsr_") ,8);
	} else {
	  strncpy( aname, strstr(name,"fsr_") ,11);
	}
	if ( verbose ) printf("%s %s \n",name, aname);
/* If different name OR not combining and already processed a frame then write the previous one  */
	if ( ncoadd > 0 && ( strcmp(aname, bname)  ) ) {    
	  goto endloop;
	}
/*  Else open next input image  */
/* ################################################################## */
      newloop:
	if ( fits_open_file(&infptr1, name, READONLY, &status) ) 
	  printerror( status );
	fits_get_num_hdus(infptr1, &hdunum, &status);
	if ( hdunum > 1)
	  fits_movrel_hdu(infptr1, 1, NULL, &status);  /* try to move to next HDU */
	fits_get_hdu_num(infptr1, &hdupos);
	if ( verbose ) printf("Number of HDU's: %d    Current HDU: %d\n",hdunum,hdupos);
	/* Copy only a single HDU if a specific extension was given */ 
	if (hdupos != 1 || strchr(name, '[') || hdunum == 1 ) single = 1;

	/* get image dimension from one of the calibration images */
	/* fits_get_img_param(infptr1, 3, &bitpix, &naxis, naxes, &status ); */

	/* Some fourstar fits files were not padded with zeroes to fill in the nbytes%2880 fits standard, 2048*2048/2880=1456.355 standard cards.  so cfitsio expects 1457 cards which means there needs to be 1856 additional bytes added to the fits file to conform to the fits standard.   Some fourstar fits file did not have these extra bytes added and are not readable by cfitsio.   To get around this easily I will just read 1456 cards, that is, omit the the last 1024 bytes which are on the reference pixels anyways.  */
	/* xnum = 4193280; */
	if (fits_read_pix(infptr1, TDOUBLE, fpixel, xnum, &nulval, inpix, &anyval, &status)){
	  if ( status == 107) {
	    if ( verbose ){ printf("Error 107, does not conform to fits standard. This is a known bug, it is OK.  \n");}
	    status = 0;
	  } else if (status == 108) {
	    if ( verbose ){ printf("Error 108, does not conform to fits standard. This is a known bug, it is OK.  \n");}
	    status = 0;
	  } else {
	    printf("Line 312 \n");
	    printerror(status);   /* jump out of loop on error */
	  }
	}
	fits_read_key(infptr1, TDOUBLE, "EXPTIME", &exptime, NULL, &status);
	fits_read_key(infptr1, TDOUBLE, "MJD", &mjd, NULL, &status);
/* running average of MJD */
	mjdave = (mjdave*ncoadd + mjd + (exptime/86400.0)/2.0)/(ncoadd + 1.0);
/* IF FIRST IMAGE OF NEW LOOP */
	if (ncoadd == 0) {
	  if ( verbose ) printf("New loop\n");
	  strcpy(bname,aname);
	  fits_read_key(infptr1, TINT, "CHIP", &chip, NULL, &status);
	  fits_read_key(infptr1, TDOUBLE, "EGAIN", &egain, NULL, &status);
	  fits_read_key(infptr1, TDOUBLE, "ENOISE", &rn, NULL, &status);
	  /* fits_read_keyword(infptr1, "READMODE", rmode, NULL, &status); */
	  fits_read_key(infptr1, TSTRING, "READMODE", rmode, NULL, &status);
	  
	  if( ! strncmp(rmode,"Multi ",6))
	    FOWL = atoi(rmode+6);

	  if ( verbose ) {printf("%s %d %f %f\n",rmode,FOWL,egain,again);}
	  /* ALREADY NORMAILIZE CHIP TO CHIP GAIN DIFFERENCES THROUGH THE FLATS, USE 2.5 and 1.3 HERE */
	  egain  = (egain > 2) ? 2.50 : 1.25 ;  /* CONVERT TO ELECTRONS */
	  if ( celect ) { 
	    again  = (egain > 2) ? 2.50 : 1.25 ;  /* CONVERT TO ELECTRONS */
	  } else {
	    again = 1.0;   /* KEEP UNITS IN NATIVE ADU */
	  }



	  if ( cflag == 1 ) {
	    snprintf(outname, sizeof(outname), "!%sl%s_00_c%1d.fits",odir, bname, chip);
	    snprintf(outname2, sizeof(outname2), "!%sl%s_00_c%1d.fits.pl.fits[compress PLIO]",odir, bname, chip);
	    snprintf(outname3, sizeof(outname3), "l%s_00_c%1d.fits.pl.fits[1]", bname, chip);
	  } else {
	    snprintf(outname, sizeof(outname), "!%sl%s_c%1d.fits",odir, bname, chip);
	    snprintf(outname2, sizeof(outname2), "!%sl%s_c%1d.fits.pl.fits[compress PLIO]",odir, bname, chip);
	    snprintf(outname3, sizeof(outname3), "l%s_c%1d.fits.pl.fits[1]", bname, chip);
	  }

	  if ( verbose ) {printf("%s --> %s + %s\n",name,outname,outname2);}

	  /* initialize image to first image in loop*/
	  for (ii = 0; ii < xnum; ii++) {
	    outtmp[ii] = inpix[ii];
	    bout[ii] = bpix[ii];
	  }
	  /* create output file */
	  if ( fits_create_file(&outfptr1, outname, &status) ) {
	    printf("Line 410 \n");
	    printerror( status );
	  }
	  /* create output file */
	  if ( fits_create_file(&outfptr2, outname2, &status) ) {
	    printf("Line 415 \n");
	    printerror( status );
	  }
	  for ( ; !status; hdupos++) {
	    fits_get_hdu_type(infptr1, &hdutype, &status);
	    if (hdutype == IMAGE_HDU) {
	      fits_get_img_param(infptr1, 9, &bitpix, &naxis, naxes, &status);
	      totpix = naxes[0] * naxes[1];
	      bitpix = FLOAT_IMG;
	    }
	    if (hdutype != IMAGE_HDU || naxis == 0 || totpix == 0) { 
	      /* just copy tables and null images */
	      if (fits_copy_hdu(infptr1, outfptr1, 0, &status) ) {
		printf("Line 363 %d \n",status);
		printerror( status );
	      }
	    } else {
	      /* Explicitly create new image, to support compression */
	      if (fits_create_img(outfptr1, bitpix, naxis, naxes, &status) )
		printerror( status );
	      if (fits_is_compressed_image(outfptr1, &status)) {
		/* write default EXTNAME keyword if it doesn't already exist */
		tstatus = 0;
		fits_read_card(infptr1, "EXTNAME", card, &tstatus);
		if (tstatus) {
		  strcpy(card, "EXTNAME = 'COMPRESSED_IMAGE'   / name of this binary table extension");
		  fits_write_record(outfptr1, card, &status);
		}
	      }
	      /* copy all the user keywords (not the structural keywords) */
	      fits_get_hdrspace(infptr1, &nkeys, NULL, &status); 	    
	      for (ii = 1; ii <= nkeys; ii++) {
		fits_read_record(infptr1, ii, card, &status);
		if (fits_get_keyclass(card) > TYP_CMPRS_KEY){
		  fits_write_record(outfptr1, card, &status);
		}
	      }
	      /* IF THE FIRST IMAGE READ IN A LOOP, TAKE GDRPR AND RA,DEC KEYWORDS */
	      if ( hdrflag == 1 ) {
		if (fits_read_key(outfptr1, TDOUBLE, "GDRPR1-X", &rpr1x, NULL, &status)) { rpr1x = 0 ;}
		if (fits_read_key(outfptr1, TDOUBLE, "GDRPR1-Y", &rpr1y, NULL, &status)) { rpr1y = 0 ;}
		if (fits_read_key(outfptr1, TDOUBLE, "GDRPR2-X", &rpr2x, NULL, &status)) { rpr2x = 0 ;}
		if (fits_read_key(outfptr1, TDOUBLE, "GDRPR2-Y", &rpr2y, NULL, &status)) { rpr2y = 0 ;}
		status = 0;
		fits_read_key(outfptr1, TDOUBLE, "RA", &ra, NULL, &status);
		fits_read_key(outfptr1, TDOUBLE, "DEC", &dec, NULL, &status);
		/* ELSE SET KEYWORDS TO THE REFERENCE VALUE */
	      } else {
		fits_update_key(outfptr1, TDOUBLE, "GDRPR1-X", &rpr1x, NULL, &status);
		fits_update_key(outfptr1, TDOUBLE, "GDRPR1-Y", &rpr1y, NULL, &status);
		fits_update_key(outfptr1, TDOUBLE, "GDRPR2-X", &rpr2x, NULL, &status);
		fits_update_key(outfptr1, TDOUBLE, "GDRPR2-Y", &rpr2y, NULL, &status);
		status = 0;
		fits_update_key(outfptr1, TDOUBLE, "RA", &ra, NULL, &status);
		fits_update_key(outfptr1, TDOUBLE, "DEC", &dec, NULL, &status);
	      }
	      if (fits_read_key(outfptr1, TDOUBLE, "GDRPR1-X", &pr1x, NULL, &status)) { pr1x = 0 ;}
	      if (fits_read_key(outfptr1, TDOUBLE, "GDRPR1-Y", &pr1y, NULL, &status)) { pr1y = 0 ;}
	      if (fits_read_key(outfptr1, TDOUBLE, "GDRPR2-X", &pr2x, NULL, &status)) { pr2x = 0 ;}
	      if (fits_read_key(outfptr1, TDOUBLE, "GDRPR2-Y", &pr2y, NULL, &status)) { pr2y = 0 ;}
	      status = 0;
	      fits_read_key(outfptr1, TDOUBLE, "RA", &ra, NULL, &status);
	      fits_read_key(outfptr1, TDOUBLE, "DEC", &dec, NULL, &status);
	      fits_read_key(outfptr1, TDOUBLE, "EPOCH", &epoch, NULL, &status);
	      fits_read_key(outfptr1, TDOUBLE, "SITELAT", &lat, NULL, &status);
	      if( fits_read_key(outfptr1, TDOUBLE, "ROTANGLE", &rot, NULL, &status))
		rot = dec < lat ? 0.0 : 180.0 ;
	      status = 0;
	      fits_update_key(outfptr1, TSTRING, "BPM", outname3, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "TELEPOCH", &epoch, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "EPOCH", &equinox, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "EQUINOX", &equinox, NULL, &status);
	      fits_update_key(outfptr1, TSTRING, "CTYPE1", "RA---TAN", NULL, &status);
	      fits_update_key(outfptr1, TSTRING, "CTYPE2", "DEC--TAN", NULL, &status);
	      fits_update_key(outfptr1, TSTRING, "CUNIT1", "deg", NULL, &status);
	      fits_update_key(outfptr1, TSTRING, "CUNIT2", "deg", NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CRVAL1", &ra, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CRVAL2", &dec, NULL, &status);
	      fits_delete_key(outfptr1, "CHECKSUM", &status);
	      status =0;
	      fits_delete_key(outfptr1, "DATASUM", &status);
	      status =0;
	      fits_delete_key(outfptr1, "BSCALE", &status);
	      status =0;
	      fits_delete_key(outfptr1, "BZERO", &status);
	      status =0; 
#define pxoff1 3    /* making more positive will shift mask to the right for chips 2 and 3 */
#define pyoff1 117  /* making more positive will mask farther into the field for chips 2 and 3 */
#define pxoff2 -13  /* making more positive will shift mask to the right for chips 1 and 4 */
#define pyoff2 -2  /* making more negative will mask farther into the field for chips 1 and 4 */
	      switch(chip){
	      case 1:
		pr1x = -1000;
		pr1y = -1000;
		tmpvar = pr2x;
		pr2x = pr2y == 0 ? -1000 : (18*(0+pxoff2+pr2y));
		pr2y = tmpvar == 0 ? 10000 : (18*(pyoff2+tmpvar));
		dx = -77.09;
		dy = -76.29;
		dr = 0.3;
		break;
	      case 2:
		tmpvar = pr1x;
		pr1x = pr1y == 0 ? -1000 : (18*(0+pxoff1+pr1y));
		pr1y = tmpvar == 0 ? -1000 : (18*(pyoff1+tmpvar));
		pr2x = -1000;
		pr2y = 10000;
		dx = -71.02;
		dy = 2133.08;
		dr = 0.22;
		break;
	      case 3:
		tmpvar = pr1x;
		pr1x = pr1y == 0 ? -1000 : (18*(120+pxoff1+pr1y));
		pr1y = tmpvar == 0 ? -1000 : (18*(pyoff1+tmpvar));
		pr2x = -1000;
		pr2y = 10000;
		dx = 2119.82;
		dy = 2126.92;
		dr = 0.17;
		break;
	      case 4:
		pr1x = -1000;
		pr1y = -1000;
		tmpvar = pr2x;
		pr2x = pr2y == 0 ? -1000 : (18*(120+pxoff2+pr2y));
		pr2y = tmpvar == 0 ? 10000 : (18*(pyoff2+tmpvar));
		dx = 2124.16;
		dy = -82.42;
		dr = 0.12;
		break;
	      default:
		break;
	      }
	      cd11 = -cos(pi/180.0*(-rot+dr))*scale;
	      cd21 = -sin(pi/180.0*(-rot+dr))*scale;
	      cd12 = -sin(pi/180.0*(-rot+dr))*scale;
	      cd22 =  cos(pi/180.0*(-rot+dr))*scale;
	      rot = fmod(round(rot+360.),360);
	      fits_update_key(outfptr1, TDOUBLE, "ROTFLAG", &rot, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CRPIX1", &dx, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CRPIX2", &dy, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CD1_1", &cd11, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CD1_2", &cd12, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CD2_1", &cd21, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "CD2_2", &cd22, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "PR1X", &pr1x, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "PR1Y", &pr1y, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "PR2X", &pr2x, NULL, &status);
	      fits_update_key(outfptr1, TDOUBLE, "PR2Y", &pr2y, NULL, &status);
	    }	    if (single) break;  /* quit if only copying a single HDU */
	    fits_movrel_hdu(infptr1, 1, NULL, &status);  /* try to move to next HDU */
	  }
/* IF NEXT IMAGE IN THE LOOP AND CO_ADDING  */
	} else {
	  if ( verbose ) printf("%s co-adding to: %s\n",name,outname);
	  for (ii = 0; ii < xnum; ii++) {
	    /* outtmp[ii] = ( ncoadd*outtmp[ii] + inpix[ii]) / (ncoadd + 1.0)   ; */
	    outtmp[ii] = outtmp[ii] + inpix[ii]  ;
	  }
	}
	ncoadd++;
	if ( fits_close_file(infptr1, &status) ){
	  printf("Line 505 \n");
	  printerror( status );
	}
	continue;
/* ################################################################## */
      endloop:
	/* DIVIDE BY NUMBER OF FRAMES */
	if ( ncoadd > 1 ) {
	  for (ii = 0; ii < xnum; ii++) {
	    outtmp[ii] = outtmp[ii] / ncoadd ;
	  }
	}

	saturate = 50000.0 * again / (exptime + (2*FOWL-1)*1.4555);  /* IN ELECTRONS per second */
	double sat2 = 6/5*saturate;
	/* gain = exptime / again; */

	stride = 8;
	tsize = naxes[0]*naxes[1]/stride/stride;
	gsl_vector *backvec = gsl_vector_alloc (tsize);
	/* FIND AVERAGE BACKGROUND, MAKE FASTER BY DOING EVERY STRIDE PIXELS */
	nback = 0;
	back = 0;
	backsig = 0;
	for (ii = 0; ii < naxes[0]; ii+=stride) {
	  for (jj = 0; jj < naxes[1]; jj+=stride) {  
	    kk = ii+naxes[0]*(jj);
	    if ( bpix[kk] == 0 && outtmp[kk] > 0 ) {
	      backt = (outtmp[kk]*(1.0 + lpix[kk]*pow((outtmp[kk]),1.50)) - dpix[kk]*(exptime/tsb) ) / (fpix[kk] * exptime / again ) ;
	      if ( backt < 65536. ) {
		nback++;
		gsl_vector_set(backvec,ii/stride*naxes[0]/stride+jj/stride, backt );
	      } else {
		gsl_vector_set(backvec,ii/stride*naxes[0]/stride+jj/stride,1.e33);
	      }
	    } else {
	      gsl_vector_set(backvec,ii/stride*naxes[0]/stride+jj/stride,1.e33);
	    }
	  }
	}
	/* set threshold to look for cratering in saturated source */
	/* back = back/nback; */
	if ( nback > 0 ) {
	  gsl_sort(backvec->data,1,tsize);
	  back = gsl_stats_mean(backvec->data,1,nback) ;
	  backsig = gsl_stats_sd(backvec->data,1,nback) ;
	  gsl_vector_free (backvec); 
	}
	backt = 0.25*back;
/* UPDATE BAD PIXEL MASK */
	for (ii = 0; ii < naxes[0]; ii++) {
	  for (jj = 0; jj < naxes[1]; jj++) {  
	    kk = ii+naxes[0]*(jj);
/* # electrons / second  OR ADU/second if celect==0 */


	    /* if bad flat value, set output to 0 to avoid NaN and set bad pixel flag */
	    if (fpix[kk] == 0 ) {
	      outpix[kk] = 0;
	      bout[kk] = 1;
	    } else {
	      outpix[kk] = (outtmp[kk] <= 0) ? 0 : ( outtmp[kk]*(1.0 + lpix[kk]*pow((outtmp[kk]),1.50)) - dpix[kk]*(exptime/tsb) ) / (fpix[kk] * exptime / again ) ;
	    }

	    /* outpix[kk] = (outtmp[kk] <= 0) ? 0 : ( outtmp[kk]*(1.0 + lpix[kk]*pow(outtmp[kk],1.50))  ) ; */

	    bout[kk] = ( (bpix[kk]==0 || bpix[kk]==2048) ? 0 : 1 );
	    /* pborder = 1; */
	    if ( pborder==1 ) {
	      bout[kk] = bout[kk] + ( bpix[kk]&2048 );
	    }


	    /* MASK SATURATED PIXELS */
	    /* bout[kk] += (  (bpix[kk]==0 || bpix[kk]==2048 ) && ( (outpix[kk] > saturate && ngrow > 0) || (outtmp[kk] < backt && bpix[kk] == 0) ) ? 2 : 0 ); */
	    bout[kk] += (  (bpix[kk]==0 || bpix[kk]==2048 ) && ( (outpix[kk] > saturate && ngrow > 0) || (outpix[kk] < backt && bpix[kk] == 0) ) ? 2 : 0 );

	    /* bout[kk] += ( (outpix[kk] > saturate && ngrow > 0) ? 2 : 0 ); */
	    /* bout[kk] += ( ( (outpix[kk] > saturate ) ) ? 2 : 0 ); */
	    /* MASK GUIDE PROBES IF THEY ARE IN THE FIELD */
	    bout[kk] += (( (pow((ii-pr1x),2)+pow((jj-pr1y),2)<360000) || (jj-pr1y-200)<0|| (pow((ii-pr2x),2)+pow((jj-pr2y),2)<360000) || (jj-pr2y+200)>0  ) ? 4 : 0 ) ;

	  }
	}


/* FILL IN SATURATED SOURCES */
	if ( ngrow > 0 ) {
	  ni = ngrow;
	  for (jj = 0; jj < naxes[1]; jj++) {
	    for (ii = 0; ii < naxes[0]; ii++) {  
	      kk = ii+naxes[0]*(jj);
	      /* update bad pixel mask for saturated cores */
	      if ( bout[kk]&2 ) {
		/* MASK EVERYTHING BEFORE RIGHT EDGE OF CRATER UP TO THE LEFT EDGE  */
		ni = ni < 0 ? ngrow : ni ;
		for (nj = 1; nj <= ngrow-ni ; nj++ ) {
		  bout[kk-nj] = bout[kk-nj]+2;
		}
		/* DETECT LEFT EDGE OF CRATER */
		ni = ngrow;
	      } else {
		ni--;
	      }
	      
	    }
	  }
	  
	  ni = ngrow;
	  for (ii = 0; ii < naxes[0]; ii++) {  
	    for (jj = 0; jj < naxes[1]; jj++) {
	      kk = ii+naxes[0]*(jj);
	      /* update bad pixel mask for saturated cores */
	      if ( bout[kk]&2 ) {
		/* MASK EVERYTHING BEFORE RIGHT EDGE OF CRATER UP TO THE LEFT EDGE  */
		ni = ni < 0 ? ngrow : ni ;
		for (nj = 1; nj <= ngrow-ni ; nj++ ) {
		  bout[kk-nj*naxes[0]] = bout[kk-nj*naxes[0]]+2;
		}
		/* DETECT LEFT EDGE OF CRATER */
		ni = ngrow;
	      } else {
		ni--;
	      }
	      
	    }
	  }
	  
	}

/* UPDATE IMAGE PIXELS, REPLACE CRATERED VALUES WITH SATURATED PIXELS, AESTHETICS ONLY  */
	if ( 1 ) {
	  for (ii = 0; ii < naxes[0]; ii++) {
	    for (jj = 0; jj < naxes[1]; jj++) {  
	      kk = ii+naxes[0]*(jj);
	      /* outpix[kk] = ( bout[kk]&2 ) ? saturate+gsl_max(0,saturate-outpix[kk]) : outpix[kk] ; */
	      outpix[kk] = ( bout[kk]&2 ) ? outpix[kk]>saturate ? sat2 : sat2+(sat2-outpix[kk]) : outpix[kk] ;
	      /* outpix[kk] = ( bout[kk]&2 ) ? 1.25*saturate : outpix[kk] ; */
	    }
	  }
	  /* interpolate over saturation */
	  if ( 1 ) {
	    int ns, _i, _j, _k;
	    double ave, _w;
	    int nsmooth = 2;
	    /* printf("Interpolating saturated image pixels... \n"); */
	    for ( ii=0;ii<naxes[0];ii++){
	      for ( jj=0;jj<naxes[1];jj++) {
		kk = ii + naxes[0]*jj;
		if ( bout[kk] & 2 ) {
		  ave = 0.0;
		  _w = 0.0;
		  _k = 0;
		  ns = nsmooth;
		interp:
		  for (ni = -ns; ni <= ns; ni++) {
		    _i = (ii+ni) < 0 ? 9999 : (ii+ni)>=naxes[0] ? 9999 : ii+ni ;
		    if ( _i == 9999) continue;
		    for ( nj = -ns; nj <= ns ; nj++){
		      _j = (jj+nj) < 0 ? 9999 : (jj+nj)>=naxes[1] ? 9999 : jj+nj ;
		      if ( _j == 9999) continue;
		      if ( bout[_i + naxes[0]*_j] & 1 ) continue;
		      _w = _w + outpix[_i+naxes[0]*(_j)];
		      ave = ave + outpix[_i+naxes[0]*(_j)]*outpix[_i+naxes[0]*(_j)];
		      _k++;
		    }
		  }
		  if ( _k <= 0 ) {
		    ns = nsmooth*2;
		    goto interp;
		  }
		  outpix[kk] = ave/_w ;
		  /* printf("%d %d %f\n",ii,jj,outpix[kk]); */
		}
	      }
	    }
	  }

	}








/* MASK CROSSTALK PIXELS FROM SATURATED */
/* exponentially decays the farther from the original saturation.  Really only affects the nearest +-5 channels.   */
	if ( crosstalk > 0 ) {
	  double ctf = 0;
	  double cf = 100000./50000.*saturate;
	  if ( egain > 2 ) {
	    ctf = 0.0017;
	  } else {
	    ctf = 0.001;
	  }
	  for (ii = 0; ii < naxes[0]; ii++) {
	    for (jj = 0; jj < naxes[1]; jj++) {  
	      kk = ii+naxes[0]*(jj);
	      /* IF PIXEL IS FLAGGED AS SATURATED */
	      if ( bout[kk]&2 ) {
	      /* if ( bout[kk]&2 && outpix[kk] < saturate ) { */
	      /* if ( outpix[kk] > cf  && bpix[kk] == 0 ) { */
		/* check that at least 4 neighboring pixels are also flagged, otherwise it is a bad pixel */
		tmpvar = 0;
		for (ni=-1;ni<=1;ni++) {
		  if (ni < 0 || ni > naxes[0]  ) continue;
		  for (nj=-1;nj<=1;nj++) {
		    if (nj < 0 || nj > naxes[1]  ) continue;
		    if ( bout[(ii+ni)+naxes[0]*((jj+nj))] ) tmpvar++ ;
		  }
		}
		if ( tmpvar < 4 )  continue;
		/* check the +-7 adjacent channels */
		for (ni=-7 ; ni<=7 ; ni++) {
		  /* 2048/32 = 64. However, apparently crosstalk affects only every other channel: 128 pixels  */
		  nj = ii+naxes[0]*(jj + ni*128);
		  /* if (nj < 0 || nj > xnum || nj == kk ) continue; */
		  if (nj > 0 && nj <= xnum ) {
		    if ( crosstalk & 2 ) {
		      bout[nj] += 8;
		    }
		    if ( crosstalk & 1 ) {
		      /* outpix[nj] = outpix[nj]*( 1. + pow(outpix[kk]/cf,1)*ctf*exp(-abs(ni)) ) ; */
		      outpix[nj] = outpix[nj]*( 1. + pow(outpix[kk]/cf,1)*ctf*exp(-abs(ni)) ) ;
		    }
		  }
		  if ( 1 ) {   /* INCLUDE MIRROR IMAGE ON ADJACENT CHANNEL */
		    nj = ii+naxes[0]*(jj + ni*128 + 2*(64-jj%64) );
		    if (nj > 0 && nj <= xnum  ) {
		      if ( crosstalk & 2 ) {
			bout[nj] += 8;
		      }
		      if ( crosstalk & 1 ) {
			outpix[nj] = outpix[nj]*( 1. + pow(outpix[kk]/cf,1)*ctf*exp(-abs(ni)) ) ;
		      }
		    }
		  }

		}

	      }
	    }
	  }
	}


	/* gain = ncoadd * gain * egain; */
	if ( celect ) {
	  /* fits_update_key(outfptr1, TDOUBLE, "EFFGAIN", &gain, "[(e-)/(e-/s)]|EXPORG*NCOADD", &status); */
	  again  = 1 ;
	  fits_update_key(outfptr1, TDOUBLE, "EFFGAIN", &again, "[e-/s]", &status);
	} else {
	  /* fits_update_key(outfptr1, TDOUBLE, "EFFGAIN", &gain, "[(e-)/(ADU/s)]|EXPORG*NCOADD*EGAIN", &status); */
	  again  = (egain > 2) ? 2.50 : 1.25 ;
	  fits_update_key(outfptr1, TDOUBLE, "EFFGAIN", &again, "[ADU/s]", &status);
	}
	fits_update_key(outfptr1, TDOUBLE, "EXPORG", &exptime, "Original exposure time", &status);

	back = roundf(back*10)/10.0;
	backsig = roundf(backsig*10)/10.0;
	fits_update_key(outfptr1, TDOUBLE, "BAVE", &back, "Raw/flat frame background", &status);
	fits_update_key(outfptr1, TDOUBLE, "BSIG", &backsig, "Raw/flat frame back sigma", &status);


	/* FOR SUMMING EFFRN = RN*sqrt(N), FOR AVERAGE, DIVIDE BY N, net RESULT / sqrt(N)  Since I am dividing the image by exptime, the variance decreases by this factor as well.  */   
	rn = roundf(rn/sqrt(FOWL*ncoadd)/exptime*10)/10.0;
	fits_update_key(outfptr1, TDOUBLE, "EFFRN", &rn, "[e-] RN/sqrt(NCOADD*FOWL)/EXPORG", &status);
	/* exptime = exptime / exptime ; */
	exptime = exptime*ncoadd ;
	saturate = roundf(saturate*10)/10.0;
	fits_update_key(outfptr1, TDOUBLE, "EXPOSURE", &exptime, "Actual Exposure Time", &status);
	fits_update_key(outfptr1, TDOUBLE, "MJDAVE", &mjdave, "average midpoint of exposure loop", &status);
	exptime = 1.0;
	fits_update_key(outfptr1, TDOUBLE, "EXPTIME", &exptime, "Exptime [units of image are per second]", &status);
	fits_update_key(outfptr1, TDOUBLE, "SATURATE", &saturate, "Saturation level", &status);
	fits_update_key(outfptr1, TDOUBLE, "NCOADD", &ncoadd, "Number of Averaged Frames", &status);
	
	/* write image */
	fpixel[0] = 1;
	fpixel[1] = 1;
	fpixel[2] = 1;
	lpixel[0] = naxes[0];
	lpixel[1] = naxes[1];
	lpixel[2] = 1;
	if (fits_write_pix(outfptr1, TDOUBLE, fpixel, xnum, outpix, &status) )
	  printerror( status );
      
	/* fits_copy_hdu(outfptr1, outfptr2, 0, &status); */
	fits_set_compression_type(outfptr2, PLIO_1 , &status);
	if (fits_create_img(outfptr2, LONG_IMG, naxis, naxes, &status) )
	  printerror( status );
	if (fits_write_pix(outfptr2, TINT, fpixel, xnum, bout, &status) )
	  printerror( status );
      
	if ( fits_close_file(outfptr1, &status) )
	  printerror( status );
	if ( fits_close_file(outfptr2, &status) )
	  printerror( status );

	ncoadd = 0;
	if ( endloop == 0)
	  goto newloop;
	if ( endloop == 1)
	  goto finish;
      }
/* FINISH READING IN FILES */
      endloop = 1;
      goto endloop;
/* free memory */
    finish:
      fclose(input);
      free(inpix);
      free(outpix);
      free(outtmp);
      free(lpix);
      free(bpix);
      free(bout);
      free(dpix);
      free(fpix);


      exit(0);
    }

/*--------------------------------------------------------------------------*/
void printerror( int status)
{
    /*****************************************************/
    /* Print out cfitsio error messages and exit program */
    /*****************************************************/

    char status_str[FLEN_STATUS], errmsg[FLEN_ERRMSG];
  
    if (status)
      fprintf(stderr, "\n*** Error occurred during program execution ***\n");

    fits_get_errstatus(status, status_str);   /* get the error description */
    fprintf(stderr, "\nstatus = %d: %s\n", status, status_str);

    /* get first message; null if stack is empty */
    if ( fits_read_errmsg(errmsg) ) 
    {
         fprintf(stderr, "\nError message stack:\n");
         fprintf(stderr, " %s\n", errmsg);

         while ( fits_read_errmsg(errmsg) )  /* get remaining messages */
             fprintf(stderr, " %s\n", errmsg);
    }

    //    exit( status );       /* terminate the program, returning error status */
}


/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
static void
PrintUsage (command)char *command;
{
    fprintf (stderr,"%s\n",RevMsg);
    if (version_only)
	exit (-1);
    if (command != NULL) {
	if (command[0] == '*')
	    fprintf (stderr, "%s\n", command);
	else
	    fprintf (stderr, "* Missing argument for command: %c\n", command[0]);
	exit (1);
	}
    fprintf (stderr,"Not yet Documented.\n");


    exit (1);
}


// April 10 2011	New program
