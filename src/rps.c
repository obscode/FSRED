/* File rps.c
 * Apr 02, 2012
 * By Andy Monson
 */

#define USEAVE
#undef USEAVE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <fitsio.h>
#include <gsl/gsl_sort.h>
#include <gsl/gsl_statistics.h>

static void PrintUsage();
static char *RevMsg = "rps 0.0, 10 April 2012, Andy Monson (monson.andy@gmail.com)";
static int version_only = 0;		/* If 1, print only program name and version */


void printerror( int status);

int main(int argc, char *argv[])
    {
      int verbose = 0;		/* verbose/debugging flag */
      fitsfile *infptr1, *outfptr1;  /* pointer to the FITS files */
      char *str=NULL, *name=NULL, *outname=NULL;
      char card[FLEN_CARD];
      /* char name[256], outname[256]; */
      int status = 0, nkeys, naxis, bitpix, hdunum, hdupos, hdutype, tstatus; /* MUST initialize status */
      /* int single=0; /\* MUST initialize status *\/ */
      int nulval = 0, anyval;
      int ii, kk, xnum, n, t=1, r=2, f=2, x, y, dx, dy, chip, ref_top, ref_bot;  
      long naxes[3]={0,0,0}, fpixel[3], inc[3];

      double *inpix=NULL;
      int Cmed[32];
      int topmed=0, botmed=0;
      double top=0, bot=0, C[32], D ;
      double data[2048/32*4];
      double keep = 0.25; /* # fraction of pixels to average, low/high reject the others.   */

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


      case 't':       /* type -  1 reverse |  2 forward | 3 reverse then forward */
	t = atoi(*(argv+1));
	/* printf("%s\n",list); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'r':       /* reverse average (default 2 on each side ie 5 wide) */
	r = atoi(*(argv+1));
	/* printf("%s\n",fimg); */
	if (argc < 2)
	  PrintUsage (str);
	argc--;
	argv++;
	break;

      case 'f':       /* forward average (default 2 ) */
	f = atoi(*(argv+1));
	/* printf("%s\n",fimg); */
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

  
  /* Copy only a single HDU if a specific extension was given */ 
  /* if (hdupos != 1 || strchr(name, '[') || hdunum == 1 ) single = 1; */
  
  /* fits_get_img_dim(infptr1, &naxis, &status); */
  /* fits_get_img_size(infptr1, 3, naxes, &status); */
  
  /* allocate memory */
  inpix = (double *) malloc(xnum * sizeof(double)); /* memory for 2d image */
  
  /* READ IN IMAGE */
  inc[0] = inc[1] = inc[2] = 1;
  fpixel[0] = 1;
  fpixel[1] = 1;
  fpixel[2] = 1;
  
  /* Some fourstar fits files were not padded with zeroes to fill in the nbytes%2880 fits standard, 2048*2048/2880=1456.355 standard cards.  so cfitsio expects 1457 cards which means there needs to be 1856 additional bytes added to the fits file to conform to the fits standard.   Some fourstar fits file did not have these extra bytes added and are not readable by cfitsio.   To get around this easily I will just read 1456 cards, that is, omit the the last 1024 bytes which are on the reference pixels anyways.  */
  /* xnum = 4193280; */
  if (fits_read_pix(infptr1, TDOUBLE, fpixel, xnum, &nulval, inpix, &anyval, &status)){
    if ( status == 107) {
      if ( verbose )
	printf("Error 107, does not conform to fits standard. This is a known bug, it is OK.  \n");
      status = 0;
    } else if (status == 108) {
      if ( verbose )
	printf("Error 108, does not conform to fits standard. This is a known bug, it is OK.  \n");
      status = 0;
    } else {
      printerror(status);   /* jump out of loop on error */
    }
  }
 

  fits_read_key(infptr1, TINT, "CHIP", &chip, NULL, &status);
  if ( verbose )
    printf("%s --> %s chip = %d \n",name,outname, chip);

  /* create output file */
  if ( outname != NULL ) {
    if ( fits_create_file(&outfptr1, outname , &status) )
      printerror( status );
    for (; !status; hdupos++) {
      fits_get_hdu_type(infptr1, &hdutype, &status);
      if (hdutype == IMAGE_HDU) {
#ifdef USEAVE
	bitpix = FLOAT_IMG;
#else
	bitpix = SHORT_IMG;
#endif
      }
      if (hdutype != IMAGE_HDU || naxis == 0 || xnum == 0) { 
	/* just copy tables and null images */
	fits_copy_hdu(infptr1, outfptr1, 0, &status);
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
      }
      fits_movrel_hdu(infptr1, 1, NULL, &status);  /* try to move to next HDU */
    }
  }

  ref_top = 1;
  ref_bot = 1;
  
  switch(chip){
  case 1:
    
    break;
  case 2:
    
    break;
  case 3:
    
    break;
  case 4:
    ref_top = 0;
    break;
    
  default:
    break;
  }
  

  if ( verbose )
    printf("Finding channel offsets\n");
  /* FIND CHANNEL OFFSETS */
  for (ii=0; ii<32; ii++){
    if ( ref_bot ){
      botmed = bot = 0; n=0;
      for (x=0;x<4;x++){
	for (y=0;y<64;y++) {
	  data[n] = inpix[x+naxes[0]*(y+ii*64)]; n+=1;
	  /* bot += inpix[x+naxes[0]*(y+ii*64)]; n+=1; */
	}
      }

      gsl_sort (data, 1, n);
      /* bot = gsl_stats_median_from_sorted_data (data, 1, n); */
      botmed = (n%2) ? data[n/2] : (data[n/2]+data[n/2-1])/2;
#ifdef USEAVE 
      bot = gsl_stats_mean ( &data[(int)(n*(1-keep)/2)], 1, n*keep);  /* reject min and max */
      /* bot = (bot / (double)n); */
#endif
      if ( 0 )
	printf("bot = %5d %5.3f\n",botmed,bot);
    }
    if ( ref_top ){
      top = 0; n=0;
      for (x=2048-4;x<2048;x++){
	for (y=0;y<64;y++) {
	  data[n] = inpix[x+naxes[0]*(y+ii*64)]; n+=1;
	  /* top += inpix[x+naxes[0]*(y+ii*64)]; n+=1; */
	}
      }

      gsl_sort (data, 1, n);
      /* bot = gsl_stats_median_from_sorted_data (data, 1, n); */
      topmed = (n%2) ? data[n/2] : (data[n/2]+data[n/2-1])/2;
#ifdef USEAVE
      top = gsl_stats_mean ( &data[(int)(n*(1-keep)/2)], 1, n*keep);  /* reject min and max */
      /* top = (top / (double)n); */
#endif
      if ( 0 )
	printf("top = %5d %5.3f\n",topmed, top);

    }
    Cmed[ii] = (ref_bot && ref_top) ? (topmed+botmed)/2.0 : ( ref_top ? (topmed) : ( ref_bot ? (botmed) : 0 ) ) ;
#ifdef USEAVE
    C[ii] = (ref_bot && ref_top) ? (top+bot)/2.0 : ( ref_top ? (top) : ( ref_bot ? (bot) : 0 ) ) ;
#endif

    if ( verbose )
      printf(" Channel %3d offset= %4d %7.3f \n",ii,Cmed[ii],C[ii] );
    
  }
  

  if ( t & 1 ){
    if ( verbose )
      printf("Finding reverse solution for dy = %d\n",r);
    for (x = 0+4; x < naxes[0]-4; x++) {
      D = n = 0;
      for (dx = -r; dx <=r; dx++ ) {
	for (dy = 0; dy<4; dy++){
	  data[n] = inpix[(x+dx)+naxes[0]*dy] - Cmed[0]; n++;
	  /* D += inpix[(x+dx)+naxes[0]*dy] - Cmed[0] ; n++; */
	}
	for (dy = naxes[1]-4; dy<naxes[1]; dy++){
	  data[n] = inpix[(x+dx)+naxes[0]*dy] - Cmed[31]; n++;
	  /* D += inpix[(x+dx)+naxes[0]*dy] - Cmed[31]; n++; */
	}
      }

      if ( 1 ) {
	gsl_sort (data, 1, n);
	D = (n%2) ? data[n/2] : (int)((data[n/2]+data[n/2-1])/2.0 + 0.5);
      } else {
	D = gsl_stats_mean ( &data[(int)(n*(1-keep)/2)], 1, n*keep);  /* reject min and max */
	/* D = D / n; */
      }

      if ( 0 )
	printf("x=%6d n=%6d D=%6f  \n",x,n,D);
      for (y = 0+4; y < naxes[1]-4; y++) {  
	kk = x+naxes[0]*(y);
	inpix[kk] += Cmed[y/64] + D;
	if (inpix[kk] < -1000){
	  /* printf("Min Value Found\n"); */
	  inpix[kk] = -1000;
	}
	/* if ( x == 2043 && y == 2043 ) */
	/*   printf("pix=%8.3f \n",inpix[kk]); */
      }
    }
  }

  if ( t & 2 ){
#ifndef USEAVE
    for ( ii = 0; ii<32; ii++){
      C[ii] = (double)(Cmed[ii]);
    }
#endif
    if ( verbose )
      printf("Finding forward solution for dy = %d\n",f);
    for (x = 0+4; x < naxes[0]-4; x++) {
      D = n = 0;
      if (f < 0) {
	D=0;
      } else {
	for (dx = -f; dx <=f; dx++ ) {
	  for (dy = 0; dy<4; dy++){
	    data[n] = inpix[(x+dx)+naxes[0]*dy] - C[0]; n++;
	    /* D += inpix[(x+dx)+naxes[0]*dy] - C[0] ; n++; */
	  }
	  for (dy = naxes[1]-4; dy<naxes[1]; dy++){
	    data[n] = inpix[(x+dx)+naxes[0]*dy] - C[31]; n++;
	    /* D += inpix[(x+dx)+naxes[0]*dy] - C[31]; n++; */
	  }
	}
      }
      gsl_sort (data, 1, n);
#ifndef USEAVE
      D = (n%2) ? data[n/2] : (int)((data[n/2]+data[n/2-1])/2.0+0.5);
#else
      D = gsl_stats_mean ( &data[(int)(n*(1-keep)/2)], 1, n*keep );  /* reject min and max */
      /* D = D / n; */
#endif	


      if ( 0 )
	printf("x=%6d  C=%6.3f D=%6f  \n",x,C[y/64],D);
      for (y = 0+4; y < naxes[1]-4; y++) {  
	kk = x+naxes[0]*(y);
	inpix[kk] -= (C[y/64] + D);
      }
    }
  }
  


  if ( verbose )
    printf("Writing File\n");
  if ( outname != NULL ) {
    if ( verbose )
      printf("Updating Header\n");
    fits_write_comment(outfptr1, "RPS modified ", &status);
    if ( 1 ) {
      fits_delete_key(outfptr1, "DATASUM", &status );
      status =0;
      fits_delete_key(outfptr1, "BSCALE", &status);
      status =0;
      fits_delete_key(outfptr1, "BZERO", &status);
      status =0;
    }
    if (fits_write_pix(outfptr1, TDOUBLE, fpixel, xnum, inpix, &status) )
      printerror( status );
    if ( fits_close_file(outfptr1, &status) )
      printerror( status );
  } else {
    if (fits_write_pix(infptr1, TDOUBLE, fpixel, xnum, inpix, &status) )
      printerror( status );
  }
  if ( fits_close_file(infptr1, &status) )
    printerror( status );
  
  /* free memory */
  free(inpix);
  
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
    fprintf (stderr,"Not yet Documented.\n");


    exit (1);
}


// April 10 2011	New program
