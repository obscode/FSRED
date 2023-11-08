/* File fft.c
 * Apr 02, 2012
 * By Andy Monson
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
// To use CFITSIO
#include <fitsio.h>
// To use FFTW3
#include <fftw3.h>
// To use GSL
#include <gsl/gsl_wavelet.h>
#include <gsl/gsl_wavelet2d.h>
#include <gsl/gsl_sort.h>
#include <gsl/gsl_multifit.h>
#include <gsl/gsl_statistics.h>

static void PrintUsage();
static char *RevMsg = "fft 0.0, 10 April 2012, Andy Monson (monson.andy@gmail.com)";
static int version_only = 0;		/* If 1, print only program name and version */


void printerror( int status);

int main(int argc, char *argv[])
    {
      fitsfile *infptr1, *outfptr1;  /* pointer to the FITS files */
      char *str=NULL, *name=NULL, *outname=NULL;
      char *type=NULL;
      char card[FLEN_CARD];
      long naxes[3]={0,0,0}, fpixel[3], inc[3];
      int status = 0, nkeys, naxis, xnum, bitpix, hdunum, hdupos, hdutype, tstatus; /* MUST initialize status */
      long naxesout[3]={0,0,0};
      int naxisout;
      int nulval = 0, anyval;
      int verbose = 0;		/* verbose/debugging flag */
      /* int single=0; /\* MUST initialize status *\/ */
      /* char name[256], outname[256]; */
      double maxval = 1.e33;
      double minval = -1.e33;


      int ii, jj, kk, _i, _j, _k, x, y, z, dir=0, nx, ny, filter=0, fparam=0, shift=0;  
      double *inpix=NULL;
      double *tmppix=NULL;



      //      fftw_complex *data=NULL;
      fftw_plan plan_forward = NULL;
      fftw_plan plan_backward = NULL;

      gsl_wavelet *wave;
      gsl_wavelet_workspace *wave_work; 

/* Check for help or version command first */
  str = *(argv+1);
  if (!str || !strcmp (str, "help") || !strcmp (str, "-help"))
    PrintUsage(str);
  /* if (!strcmp (str, "-t")) */
  /*   printf("Must specify -t option  1 | 2 | 3   \n"); */
  /*   PrintUsage(str); */
  if (!strcmp (str, "version") || !strcmp (str, "-version")) {
    version_only = 1;
    PrintUsage(str);
  }
/* Decode arguments */
  for (argv++; --argc > 0 && *(str = *argv) == '-'; argv++) {
    char c;
    while ((c = *++str))
      switch (c) {
	
      case 'v':	/* more verbosity */
	verbose++;
	printf("Verbose output\n");
	break;

      case 'i':       /* input image */
	name = *(argv+1);
	/* printf("%s\n",list); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'o':       /* output image */
	outname = *(argv+1);
	/* printf("%s\n",list); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'f':       /* filter image */
	filter = atoi(*(argv+1));
	fparam = atoi(*(argv+2));
	if ( verbose )
	  printf("Filtering using case %d, param=%d \n",filter, fparam);
	if (argc < 3)
	  PrintUsage (str);
	argc-=2;
	argv+=2;
	break;

      case 's':       /* shift image quadrants */
	shift++;
	/* printf("%s\n",list); */
	break;

      case 'd':       /* direction -  1 reverse |  2 forward | 3 reverse then forward */
	dir = atoi(*(argv+1));
	/* printf("%s\n",list); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;
	
      case 't':       /* type -  fft | wave */
	type = (*(argv+1));
	if ( verbose )
	  printf("type = %s\n",type);
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;


      case 'a':       /* minval */
	minval = atof(*(argv+1));
	if ( verbose )
	  printf("minval = %f\n",minval);
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'b':       /* maxval */
	maxval = atof(*(argv+1));
	if ( verbose )
	  printf("maxval = %f\n",maxval);
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;


      default:
	/* printf("%s\n",*(argv+1)); */
	PrintUsage(str);
	break;
      }
  }
  
  
  /*  open image  */
  if ( fits_open_file(&infptr1, name, READWRITE, &status) ) 
    printerror( status );
  fits_get_num_hdus(infptr1, &hdunum, &status);
  fits_get_img_param(infptr1, 9, &bitpix, &naxis, naxes, &status);
  if ( hdunum > 1)
    fits_movrel_hdu(infptr1, 1, NULL, &status);  /* try to move to next HDU */
  fits_get_hdu_num(infptr1, &hdupos);
  xnum = naxes[0] * naxes[1];

  if (verbose)
    printf("Number of HDU's: %d Current HDU: %d \nNAXES=%d x=%ld y=%ld z=%ld totpix=%d bitpix=%d\n",hdunum,hdupos,naxis,naxes[0],naxes[1],naxes[2],xnum,bitpix);

  
  /* allocate memory */
  inpix = (double *) malloc(xnum * sizeof(double)); /* memory for 2d image */
  tmppix = (double *) malloc(xnum * sizeof(double)); /* memory for 2d image */
  nx = naxes[0];
  ny = naxes[1];
  //  ny = naxes[1]/2 +1;
  //  data = (fftw_complex *) fftw_malloc( nx*ny * sizeof(fftw_complex)); /* memory for 2d image */
  
  /* READ IN IMAGE */
  inc[0] = inc[1] = inc[2] = 1;
  fpixel[0] = 1;
  fpixel[1] = 1;
  fpixel[2] = 1;
  
  /* Some fourstar fits files were not padded with zeroes to fill in the nbytes%2880 fits standard, 2048*2048/2880=1456.355 standard cards.  so cfitsio expects 1457 cards which means there needs to be 1856 additional bytes added to the fits file to conform to the fits standard.   Some fourstar fits file did not have these extra bytes added and are not readable by cfitsio.   To get around this easily I will just read the fits file and ignore any read errors.  */

  fits_read_pix(infptr1, TDOUBLE, fpixel, xnum, &nulval, inpix, &anyval, &status);
  if ( status == 107) {
    if ( verbose )
      printf("Error 107, does not conform to fits standard. This is a known bug, it is OK.  \n");
    status = 0;
  } else if (status == 108) {
    if ( verbose )
      printf("Error 108, does not conform to fits standard. This is a known bug, it is OK.  \n");
    status = 0;
  } else if ( status ) {
    printerror(status);   /* jump out of loop on error */
  }
 
  if ( verbose )
    printf("%s --> %s\n",name,outname);

  /* create output file */
  if ( outname != NULL ) {
    if ( fits_create_file(&outfptr1, outname , &status) )
      printerror( status );
    for (; !status; hdupos++) {
      fits_get_hdu_type(infptr1, &hdutype, &status);
      if (hdutype == IMAGE_HDU) {
	bitpix = FLOAT_IMG;
      }
      if (hdutype != IMAGE_HDU || naxis == 0 || xnum == 0) { 
	/* just copy tables and null images */
	fits_copy_hdu(infptr1, outfptr1, 0, &status);
      } else {
	/* Explicitly create new image, to support compression */
	naxisout = naxis;
	for (ii=0;ii<3;ii++){
	  naxesout[ii] = naxes[ii];
	}

	if (fits_create_img(outfptr1, bitpix, naxisout, naxesout, &status) )
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
      }
      fits_movrel_hdu(infptr1, 1, NULL, &status);  /* try to move to next HDU */
    }
  }

/* SET BAD PIXELS TO ZERO */
  if ( 1 ) {
    for (kk=0;kk<xnum;kk++){
      inpix[kk] =  ( inpix[kk] > maxval || inpix[kk] < minval ) ? 0 : inpix[kk];
    }
  }

/* WAVELET OPTION */
  wave = gsl_wavelet_alloc(gsl_wavelet_haar,2);
  wave_work = gsl_wavelet_workspace_alloc(naxes[0]); 
  if ( !strcmp(type,"wave") ){
    if ( dir & 1 ){
      if ( verbose )
	printf("Finding forward wavelet for %s\n",name);
      gsl_wavelet2d_nstransform_forward(wave,inpix,1*naxes[0],naxes[0],naxes[1],wave_work);
      if ( filter ) {
	if ( verbose)
	  printf("Filtering %s\n",name);
	switch (filter){

	case 1:
	  for (ii=1;ii<nx*ny;ii++) {
	    inpix[ii] = inpix[ii];
	  }
	  break;

	case 2:
	for (ii=fparam; ii<=(naxes[0]/2); ii=ii*2) {
	  for (jj=1; jj<=3; jj++){
	    if (jj==1)
	      kk = ii;
	    if (jj==2)
	      kk = ii*naxes[0];
	    if (jj==3)
	      kk = ii + ii*naxes[0];
	    if ( verbose )
	      printf("Basis = %d:%d  %d\n",ii,jj,kk);
	    for (y=0; y<ii; y++) {
	      for (x=0; x<ii; x++) {
		z = kk+x+naxes[0]*y; 
		/* inpix[z] = inpix[z]; */
		inpix[z] = 0;
	      }
	    }	    

	  } /* change basis sub-block */
	} /* change basis */
	break;

	default:
	  break;
	}
      }
    }
    if ( dir & 2 ){
      if ( verbose )
	printf("Finding reverse wavelet for %s\n",name);
      gsl_wavelet2d_nstransform_inverse(wave,inpix,1*naxes[0],naxes[0],naxes[0],wave_work);
    }
  }
/* END TYPE WAVE */


/* FFT OPTION */
  if ( !strcmp(type,"fft") ){
    if ( dir & 1 ){
      if ( verbose )
	printf("Finding forward fft for %s\n",name);
      //    plan_forward = fftw_plan_dft_r2c_2d(naxes[0], naxes[1], inpix, data, FFTW_ESTIMATE );
      /* plan_forward = fftw_plan_r2r_2d(naxes[0], naxes[1], inpix, inpix, FFTW_REDFT10, FFTW_REDFT10, FFTW_ESTIMATE ); */
      plan_forward = fftw_plan_r2r_2d(naxes[0], naxes[1], inpix, tmppix, FFTW_R2HC, FFTW_R2HC, FFTW_ESTIMATE );
      fftw_execute(plan_forward);
      /* MASK PIXELS */
      if ( filter ) {
	if ( verbose )
	  printf("Filtering %s\n",name);
	/* SKIP ii=0, that is the image sum */
	for (ii=1;ii<nx*ny;ii++) {
	  tmppix[ii] = fabs(tmppix[ii]) > nx*ny/2 ? 0 : tmppix[ii];
	}
      }
      /* SHIFT THE QUADRANTS FOR BETTER VISUALIZATION */
      if ( shift ) {
	if ( verbose )
	  printf("Shifting %s\n",name);
	for ( kk=0; kk<4; kk++ ){
	  switch (kk){
	  case 0:
	    _i = 0 ; _j = nx*ny/2+nx/2;
	    break;
	  case 1:
	    _i = nx/2 ; _j = nx*ny/2;
	    break;
	  case 2:
	    _i = nx*ny/2 ; _j = nx/2;
	    break;
	  case 3:
	    _i = nx*ny/2+nx/2 ; _j = 0;
	    break;
	  default:
	    break;
	  }
	  /* printf("%d %d %d\n",kk,_i,_j); */
	  for (ii=0; ii<nx/2; ii++ ){
	    for (jj=0; jj<ny/2; jj++){
	      inpix[_i+ii+jj*nx] = tmppix[_j+ii+jj*nx];
	    }
	  }
	}
      } else {
	for ( kk=0;kk<xnum ;kk++) {
	  inpix[kk] = tmppix[kk];
	}
      }
    }    
    if ( dir & 2 ){
      if ( verbose )
	printf("Finding inverse fft for %s\n",name);
      /* SHIFT THE QUADRANTS FOR BETTER VISUALIZATION */
      if ( shift ) {
	if ( verbose )
	  printf("UN-Shifting %s\n",name);
	for ( kk=0; kk<4; kk++ ){
	  switch (kk){
	  case 0:
	    _i = 0 ; _j = nx*ny/2+nx/2;
	    break;
	  case 1:
	    _i = nx/2 ; _j = nx*ny/2;
	    break;
	  case 2:
	    _i = nx*ny/2 ; _j = nx/2;
	    break;
	  case 3:
	    _i = nx*ny/2+nx/2 ; _j = 0;
	    break;
	  default:
	    break;
	  }
	  /* printf("%d %d %d\n",kk,_i,_j); */
	  for (ii=0; ii<nx/2; ii++ ){
	    for (jj=0; jj<ny/2; jj++){
	      tmppix[_i+ii+jj*nx] = inpix[_j+ii+jj*nx]/(xnum);
	    }
	  }
	}
      }
      //    plan_backward = fftw_plan_dft_c2r_2d(naxes[0], naxes[1], data, inpix, FFTW_ESTIMATE);
      /* plan_backward = fftw_plan_r2r_2d(naxes[0], naxes[1], tmppix, inpix, FFTW_REDFT01, FFTW_REDFT01, FFTW_ESTIMATE); */
      plan_backward = fftw_plan_r2r_2d(naxes[0], naxes[1], tmppix, inpix, FFTW_HC2R, FFTW_HC2R, FFTW_ESTIMATE);
      fftw_execute(plan_backward);
    }
  }
/* END IF TYPE = FFT */


  if ( outname != NULL ) {
    if ( verbose )
      printf("Updating Header\n");
    if ( 1 ) {
      fits_delete_key(outfptr1, "DATASUM", &status );
      status =0;
      fits_delete_key(outfptr1, "BSCALE", &status);
      status =0;
      fits_delete_key(outfptr1, "BZERO", &status);
      status =0;
    }
    if ( verbose )
      printf("Writing File\n");
    if ( dir == 1 ){
      //      if (fits_write_pix(outfptr1, TDOUBLE, fpixel, 2*nx*ny, data, &status) )
      if (fits_write_pix(outfptr1, TDOUBLE, fpixel, xnum, inpix, &status) )
	printerror( status );
    } else {
      if (fits_write_pix(outfptr1, TDOUBLE, fpixel, xnum, inpix, &status) )
	printerror( status );
    }

    if ( fits_close_file(outfptr1, &status) )
      printerror( status );
  } else {
    if (fits_write_pix(infptr1, TDOUBLE, fpixel, xnum, inpix, &status) )
      printerror( status );
  }
  if ( fits_close_file(infptr1, &status) )
    printerror( status );
  



  /* free memory */
  fftw_destroy_plan ( plan_forward );
  fftw_destroy_plan ( plan_backward );
  gsl_wavelet_free(wave);
  gsl_wavelet_workspace_free(wave_work);
  free(inpix);
  free(tmppix);
  //  fftw_free(data);
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

    exit( status );       /* terminate the program, returning error status */
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
    fprintf (stderr,"x_fft -v -i image -o output -t wave -d [1|2|3] -f 1 2 .\n");


    exit (1);
}


// April 10 2011	New program
