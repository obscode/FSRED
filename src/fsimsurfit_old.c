/* File mimsurfit.c
 * Apr 02, 2012
 * By Andy Monson
 */

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <fcntl.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <fitsio.h>
#include <gsl/gsl_multifit.h>
#include <gsl/gsl_statistics_double.h>
#include <gsl/gsl_statistics.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_errno.h> 
#include <gsl/gsl_interp.h> 
#include <gsl/gsl_spline.h>  
#include <gsl/gsl_bspline.h>
#include <gsl/gsl_blas.h> 
#include <gsl/gsl_wavelet.h>
#include <gsl/gsl_wavelet2d.h>
#include <gsl/gsl_sort.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>

/* minimum fraction of good segments */
const double frac = 0.1;


static void PrintUsage();
static char *RevMsg = "mimsurfit 0.0, 10 April 2012, Andy Monson (monson.andy@gmail.com)";
static int version_only = 0;		/* If 1, print only program name and version */

void printerror( int status);

int main(int argc, char *argv[])
    {
      int verbose = 0;
      fitsfile *infptr1=NULL, *infptr2=NULL, *infptr4=NULL, *outfptr1=NULL, *outfptr2=NULL, *outfptr3=NULL;  /* pointer to the FITS files */
      char *ftype=NULL, *str=NULL, *list=NULL;
      char line[256], name[256], name2[256], name3[256], name4[256], outname[256], outname2[256], outname3[256], filter[10]; 
      int status = 0, bitpix, nkeys, axis, oaxis, fitn, fitr=0, fitc=0, ni, nj, ngrow=0, i, j, _i, _j, ii, jj, kk, naxis, niter=1, ntmp=1, size ,xnum, count;  /* MUST initialize status */
      long naxes[3], fpixel[3];
      double *pix=NULL, *tpix=NULL, *fit=NULL, *tmpfit=NULL, *flat=NULL, tmp, fwhm, fwhmn, back, back2, ave, bsig, sigma, rand, density, hisig=3, losig=3, hisig2, losig2, chisq;
      /* double maxval = 1.E33; */
      /* double minval = -1.E33; */
      double maxval = 65536.;
      double minval = -10000.;
      double minave=1.E33;
      double dlim = 0.02;
      double lweight = 0.1;
      double minarea = 0.5;
      double area, barea;
      int xsurf=0,ysurf=0,csurf=0,nxsurf=0,nysurf=0,ncsurf=0;
      int randno = 0;
      int *bpix=NULL, *tbpix=NULL;
      int xsmooth = 128;
      int ysmooth = 128;
      int stride = 1;
      int nsmooth, xgrid, ygrid, nfit, itype=0, waven=0, chip, bitmask=93, bitmask_ave=255;

      gsl_matrix *X=NULL, *cov=NULL, *backmat=NULL, *sigmat=NULL; 
      gsl_vector *x=NULL, *y=NULL, *w=NULL, *c=NULL, *xi=NULL; 

      gsl_interp_accel *acc=NULL;
      gsl_spline *spline=NULL;

      gsl_wavelet *wave=NULL;
      gsl_wavelet_workspace *wavework=NULL; 

      const gsl_rng_type * T=NULL;
      gsl_rng * r=NULL;
       gsl_rng_env_setup();
       T = gsl_rng_default;
       r = gsl_rng_alloc (T);


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
	    	    

	  case 'a':       /* max value reject */
	    maxval = atof(*(argv+1));
	    /* printf("%s\n",list); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'b':       /* min value reject */
	    minval = atof(*(argv+1));
	    /* printf("%s\n",list); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'c':       /* yorder */
	    fitc = atoi(*(argv+1));
	    /* printf("%s\n",fimg); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'd':       /* density limit */
	    dlim = atof(*(argv+1));
	    /* printf("%s\n",fimg); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    
	  case 'f':       /* output file */
	    strcpy(outname, *(argv+1) );
	    strcat(outname,".fits");
	    strcpy(outname2, *(argv+1) );
	    strcat(outname2,".weight.fits");
	    strcpy(outname3, *(argv+1) );
	    strcat(outname3,".mask.fits");
	    /* printf("%s\n",odir); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'g':       /* grow radius */
	    ngrow = atoi(*(argv+1));
	    /* printf("%s\n",dimg); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;


	  case 'h':       /* high sigma reject */
	    hisig = atof(*(argv+1));
	    /* printf("%s\n",list); */
	    if (argc < 2)
	      PrintUsage (str);
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

	  case 'j':       /* mask for background  */
	    bitmask_ave = atoi(*(argv+1));
	    /* printf("%s\n",list); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'k':       /* mask for output bpm */
	    bitmask = atoi(*(argv+1));
	    /* printf("%s\n",list); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'l':       /* low sigma reject */
	    losig = atof(*(argv+1));
	    /* printf("%s\n",list); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'm':       /* minaraea to do surface fit */
	    minarea = atof(*(argv+1));
	    /* printf("%s\n",list); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	    
	  case 'n':       /* number of rejection iterations */
	    niter = atoi(*(argv+1));
	    /* printf("%s\n",limg); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    
	  case 'p':       /* path to FLATS */
	    strcpy(name3, *(argv+1) );
	    /* printf("%s\n",infptr4); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;


	  case 'r':       /* xorder */
	    fitr = atoi(*(argv+1));
	    /* printf("%s\n",fimg); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    

	  case 's':       /* surface fit */
	    xsurf = atoi(*(argv+1));
	    ysurf = atoi(*(argv+2));
	    csurf = atoi(*(argv+3));
	    /* printf("%s\n",fimg); */
	    argc--; argc--; argc--;
	    argv++; argv++; argv++;
	    break;

	  case 't':       /* type of output */
	    itype = atoi(*(argv+1));
	    /* printf("%s\n",fimg); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'v':       /* bad pixel mask suffix */
	    verbose = atoi(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'w':       /* wavelet  number */
	    waven = atoi(*(argv+1));
	    /* printf("%s\n",fimg); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'x':       /* x grid size */
	    xsmooth = atoi(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'y':       /* y grid size */
	    ysmooth = atoi(*(argv+1));
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
      ntmp = niter;
      if ( verbose )
	printf("%s %s \n",outname,outname2);

      /* printf("STARTING THE LOOP \n"); */
      FILE *input = fopen(list,"r");
      count = 0;
      while (fgets(line,256,input) !=NULL){
	count++;
	if(line[0]=='#') continue;
	if(sscanf(line,"%s",name)!=1) continue;
	strcpy(name2,name);
	strcat(name,".sub.fits");
	strcat(name2,".sky.pl.fits[1]");

/* ####################################################################### */
      /*  open input image  */
      fits_open_file(&infptr1, name, READONLY, &status);
      fits_read_key(infptr1, TDOUBLE, "NEWSKY", &back, NULL, &status);
      status = 0;
      fits_read_key(infptr1, TDOUBLE, "STDDEV2", &bsig, NULL, &status);

      if (verbose&1 )
	printf("%d %s %s %f %f \n",count,name,name2, back, bsig);

      status = 0;
      tmp = 0;
      fwhm = 0;
      fwhmn = 1;
      minave=1.E33;
/* if make weight map */
/* # replace_bad_pix weight cancel_fit verbosity */
/*   8 4 2 1     */
/* ----------- */
/* # 0 0 0 = 0 */
/* # 0 0 1 = 1 */
/* # 0 1 0 = 2 */
/* # 0 1 1 = 3 */
/* # 1 0 0 = 4 */
/* # 1 0 1 = 5 */
/* # 1 1 0 = 6 */
/* # 1 1 1 = 7 */
      if ( verbose & 4 ) {
	fits_read_key(infptr1, TDOUBLE, "MODE", &tmp, NULL, &status);
	status = 0;
	fits_read_key(infptr1, TDOUBLE, "FWHM_AVE", &fwhm, NULL, &status);
	status = 0;
	fits_read_key(infptr1, TDOUBLE, "FWHM_NUM", &fwhmn, NULL, &status);
	status = 0;

	if ( tmp == 0 || fwhm == 0 || fwhmn <= 1 ) {
	  fwhmn = 100;
	} else {
	  fwhmn = 10000000./(tmp*fwhm*fwhm);
	}
	if ( verbose & 1 )
	  printf("Setting weight for %s to %f \n",name,fwhmn);
      }
/* end if make weight map */
      fits_get_img_param(infptr1, 3, &bitpix, &naxis, naxes, &status );
      size = naxes[0] * naxes[1];
/* try opening output file */
      if ( fits_open_file(&outfptr1, outname, READWRITE, &status) ) {
	status = 0;
	/* create new empty file if necessary */
	if ( fits_create_file(&outfptr1, outname, &status) ) {
	  status = 0;
	}
	/* create new image extension for newly created image */
	fits_create_img(outfptr1, 8, 0, NULL, &status);
      }
      fits_copy_header(infptr1, outfptr1, &status);
/* ####################################################################### */
      /*  open mask image  */
      if ( fits_open_file(&infptr2, name2, READONLY, &status) )
      	printerror( status );
      fits_get_img_type(infptr2, &bitpix, &status);
     /* try opening output mask file */
      if ( fits_open_file(&outfptr2, outname2, READWRITE, &status) ) {
	status = 0;
      /* create output mask file if not opened (didnt exist) */
	if ( fits_create_file(&outfptr2, outname2, &status) ) {
	  status = 0;
	}
	fits_create_img(outfptr2, 8, 0, NULL, &status);
      }
      /* create output image extension */
      if ( fits_create_img(outfptr2, bitpix, naxis, naxes, &status) )
      	printerror( status );

      if ( fits_open_file(&outfptr3, outname3, READWRITE, &status) ) {
	status = 0;
      /* create output mask file if not opened (didnt exist) */
	if ( fits_create_file(&outfptr3, outname3, &status) ) {
	  status = 0;
	}
	fits_create_img(outfptr3, 8, 0, NULL, &status);
      }
      /* create output image extension */
      if ( fits_create_img(outfptr3, bitpix, naxis, naxes, &status) )
      	printerror( status );

/* ####################################################################### */
      /* printf("%d\n", size); */
      if ( count == 1 ) {
	pix = (double *) malloc(size * sizeof(double)); /* memory for 2d image */
	tpix = (double *) malloc(size * sizeof(double)); /* memory for 2d image */
	fit = (double *) malloc(size * sizeof(double)); /* memory for output 2d image */
	tmpfit = (double *) malloc(size * sizeof(double)); /* memory for output 2d image */
	flat = (double *) malloc(size * sizeof(double)); /* memory for output 2d image */
	bpix = (int *) malloc(size * sizeof(int)); /* memory for 2d mask */
	tbpix = (int *) malloc(size * sizeof(int)); /* memory for 2d mask */
	if (pix == NULL || fit == NULL || bpix == NULL || tmpfit == NULL ) {
	  printf("Memory allocation error\n");
	  return(1);
	}
      }
      fpixel[0] = fpixel[1] = fpixel[2] = 1;
      fits_read_pix(infptr1, TDOUBLE, fpixel, size, 0, pix, 0, &status);
      fits_read_pix(infptr2, TINT, fpixel, size, 0, bpix, 0, &status);

/* do initial masking of image, divide into blocks and determine whether or not to mask the entire block.  */
      nsmooth = ysmooth * xsmooth / (stride * stride);
      axis = 0;
      oaxis = 0;
      xgrid = ceil((double)naxes[0]/(double)xsmooth);
      ygrid = ceil((double)naxes[1]/(double)ysmooth);

      printf("number of sub-blocks: %d, %d   npix per block: %d\n",xgrid,ygrid, nsmooth);

      gsl_vector *cell = gsl_vector_alloc (nsmooth);
      backmat = gsl_matrix_alloc (xgrid, ygrid);
      sigmat = gsl_matrix_alloc (xgrid, ygrid);
      gsl_matrix_set_zero(backmat); 
      gsl_matrix_set_zero(sigmat); 
      area = xgrid*ygrid;
      barea = 0;
      tmp = 0.0;
      if ( dlim > 0.5 ) {
	lweight = 0.000001;
      }
/* loop over column blocks */
      for (jj = 0; jj < ygrid; jj++) {
/* loop over row blocks */
	for (ii = 0; ii < xgrid; ii++) {
/* average pixels in this block */
	  if ( gsl_matrix_get(sigmat,ii,jj) == lweight ) {
	    /* IF THIS BLOCK WAS MASKED, KEEP IT MASKED */
	    if ( verbose & 64 )
	      printf("%04d %04d Already Masked.... Continuing\n",ii,jj);
	    gsl_matrix_set(backmat,ii,jj, gsl_matrix_get(backmat,ii,jj) );
	    continue;
	  }
	  ave = 0.0;
	  sigma = 0.0;
	  /* density = 0.01; */
	  density = 1.0;
	  nkeys = 0;
	  xnum = 0;

	    if ( verbose & 128 )
	      printf("%04d %04d .... Continuing\n",ii,jj);


	  for (_j = 0 ; _j < ysmooth ; _j+=stride) {
	    if (_j + jj*ysmooth >= naxes[1] ) {
	      break;
	    }
	    for (_i = 0 ; _i < xsmooth ; _i+=stride) {
	      if (_i + ii*xsmooth >= naxes[0] ) {
		break;
	      }
	      kk = _i+ii*xsmooth+naxes[0]*(_j+jj*ysmooth);
	      /* find average background in this block, ignore bad pixels */
/* 2048 - border */
/* 128 - custom object */
/* 64 - no sky, hole */
/* 32 - Object */
/* 16 - transient artifact */
/* 8 - latency, previously saturated */
/* 4 - guide probe vignetting */
/* 2 - saturated */
/* 1 - bad pixel */
/* 0 - good value */
/*   +64+32+16+8+4+2+1 = 127 - match bitpattern for this number */
	      /* bitmask = 127; */
	      /* bitmask = ( verbose & 32 ) ? bitmask + 128 : bitmask; */
	      /* if ( pix[kk] > maxval || pix[kk] < minval || bpix[kk] > 0 || pix[kk] > back+(hisig)*bsig || pix[kk] < back-(losig)*bsig ){ */
	      if ( pix[kk] > maxval || pix[kk] < minval  || pix[kk] > back+(hisig)*bsig || pix[kk] < back-(losig)*bsig || bpix[kk]&bitmask_ave  ){
		gsl_vector_set(cell,_i/stride+xsmooth*_j/stride/stride,1.e33);
		tbpix[kk] = 1;
	      } else {
		tbpix[kk] = 0;
		gsl_vector_set(cell,_i/stride+xsmooth*_j/stride/stride,pix[kk]);
		/* tmp = tmp + pix[kk]; */
		xnum++;
	      }
	    }
	  }
/* compute block statistics */
	  gsl_sort(cell->data,1,nsmooth);
	  /* ave = xnum < 10 ? back : gsl_stats_quantile_from_sorted_data(cell->data,1,xnum,0.25) ; */
	  ave = xnum < 10 ? back : gsl_stats_mean(cell->data,1,xnum) ;
	  sigma = xnum < 10 ? 10000. : gsl_stats_sd(cell->data,1,xnum) ;
	  minave = ave < minave ? ave : minave;
/* find source density above local background for this block */
	  for (_j = 0 ; _j < ysmooth ; _j+=stride) {
	    if (_j + jj*ysmooth >= naxes[1] ) {
	      break;
	    }
	    for (_i = 0 ; _i < xsmooth ; _i+=stride) {
	      if (_i + ii*xsmooth >= naxes[0] ) {
		break;
	      }
	      kk = _i+ii*xsmooth+naxes[0]*(_j+jj*ysmooth);
	      /* 32 + 4 = 36 */
	      if ( bpix[kk] & 32 || (  (pix[kk] > ave+(hisig)*sigma || pix[kk] < ave-(losig)*sigma) && bpix[kk] == 0 ) ) {
		nkeys++;
	      }
	      /* add random noise: */
	      if ( randno ) {
		rand = gsl_ran_gaussian(r, sigma);
		/* rand = gsl_ran_poisson(r, sigma); */
	      } else {
		rand = 0.0;
	      }
	      /* replace potential sources with background level */
	      tpix[kk] = ( tbpix[kk] ) ? ave+rand : pix[kk];
	      tmpfit[kk] = 0.;
	    }
	  }
	  /* density = nkeys > 10 ? (double)nkeys / (double)(nsmooth) : density ; */
	  density = (double)nkeys / (double)(nsmooth) ;
	  gsl_matrix_set(backmat,ii,jj,ave);
	  /* gsl_matrix_set(sigmat, ii, jj, ( xnum<10 ? lweight : 1.0 )  ); */
	  gsl_matrix_set(sigmat, ii, jj, ( xnum<10 ? lweight : lweight>(1.0-density) ? lweight : (1.0-density) )  );

/* mask this subblock if >25% source density *AND* background above normal.  In some cases the background is high but the source density is low (ie sky).  In some cases the source density is high but the background is low (object masks were over-estimated) */
	  if ( 1 &&  ( density > (0.5) || (density > dlim && (ave == 0.0 || fabs(back-ave) > 0.5*sigma ) ) ) ) {
	    if ( verbose & 64 ) 
	      printf("    likely object block: %04d %04d\n",ii,jj);

	    for (ni = -ngrow ; ni <= ngrow ; ni++ ) {
	      _i = (ii+ni) < 0 ? 9999 : (ii+ni)>=xgrid ? 9999 : ii+ni ;
	      if ( _i == 9999)
		continue;
	      for (nj = -ngrow ; nj <= ngrow ; nj++ ) {
		_j = (jj+nj) < 0 ? 9999 : (jj+nj)>=ygrid ? 9999 : jj+nj ;
		if ( _j == 9999)
		  continue;

		if ( ni != 0 && nj !=0 && gsl_matrix_get(sigmat,_i,_j) == lweight ) {
/* # REDUCE BACKGROUND OF ADJACENT GRIDS BY AVERAGING THE GLOBAL BACKGROUND WITH THE BACKGROUND IN THIS GRID */
		  gsl_matrix_set(backmat,_i,_j,(back + gsl_matrix_get(backmat,_i,_j ))/2);
		  continue;
		} else {
/* # REPLACE THIS GRID WITH THE BACKGROUND AVERAGE */
		  gsl_matrix_set(backmat,_i,_j,back);
		  gsl_matrix_set(sigmat,_i,_j,lweight);
		  barea++;
		}
		/* replace grid value with current running average */
		/* if ( fabs(back-ave) > 1.0*sigma ) gsl_matrix_set(backmat,_i,_j,back); */
		if ( verbose & 64 )
		  printf("         masking grid block: %04d %04d  %7.0f \n",_i,_j,barea );

		/* flag bad pixel mask, only necessary if doing fitting... */
		if ( fitr || fitc ) {

		  for (j = 0 ; j < ysmooth ; j++) {
		    if (j + _j*ysmooth >= naxes[1] ) {
		      break;
		    }
		    for (i = 0 ; i < xsmooth ; i++) {
		      if (i + _i*xsmooth >= naxes[0] ) {
			break;
		      }
		      kk = i+_i*xsmooth+naxes[0]*(j+_j*ysmooth);
		      if ( randno ) {
			rand = gsl_ran_gaussian(r, sigma);
			/* rand = gsl_ran_poisson(r, sigma); */
		      } else {
			rand = 0.0;
		      }
		      tbpix[kk] = 1;
		      tpix[kk] = ave+rand;
		    }
		  }
		}

	      }
	    }

	  } else if ( xnum > 10 )  { /* if ( density > 0.15 && (ave == 0.0 || ave > back+10.0*sigma  )   ) */
	    /* back = (back*(tmp)+ave)/(tmp+1.); */
	    /* bsig = sigma > 1000 ? bsig : (bsig*(tmp)+sigma)/(tmp+1.); */
	    tmp = tmp+1;
	  } else {
	    barea++;
	    if ( verbose & 64)
	      printf(" < 10 pixels:ignoring grid block: %04d %04d  %7.0f\n",ii,jj,barea);
	  }


/* end mask */
	  if ( verbose & 64 && 1  )
	    printf("%04d %04d (%04d %04d)  %7d %6.3f %6.3f | %7.2f %9.2f | %5.0f %7.2f %7.2f : %7.0f / %7.0f : %5.1f / %5.1f : %2d \n",ii,jj,xgrid,ygrid,xnum, density,dlim,ave,sigma, tmp, back, bsig, minval, maxval, hisig,losig, ngrow);

	}
      }
      if ( verbose & 64 ){
	printf("\n-------------------------------------\n \
AREA=%7.0f, MASKED AREA=%7.0f, GOOD AREA=%7.1f  \n\n",area, barea, 1.-barea/area);
      }

/* fix the left edge of chip 4 */
      fits_read_key(infptr1, TSTRING, "FILTER", filter, NULL, &status);
      fits_read_key(infptr1, TINT, "CHIP", &chip, NULL, &status);
      if ( chip == 4 ) {
	if ( verbose & 1 )
	  printf("Fixing left edge of Chip 4\n");
/* loop over column blocks */
	for (jj = 0; jj < ygrid; jj++) {
/* loop over row blocks */
	  for (ii = 1; ii >= 0; ii--) {
/* set pixels in this block to the same value as the next row */
	    for (j = 0 ; j < ysmooth ; j++) {
	      if (j + jj*ysmooth >= naxes[1] ) {
		break;
	      }
	      for (i = 0 ; i < xsmooth ; i++) {
		if (i + ii*xsmooth >= naxes[0] ) {
		  break;
		}
		kk = i+ii*xsmooth+naxes[0]*(j+jj*ysmooth);
		tpix[kk] =  tpix[i+(ii+1)*xsmooth+naxes[0]*(j+jj*ysmooth)];		
	      }
	    }

	  }
	}

      }

/* subtract the minimum block value */
      if ( 1 ) {
	if ( verbose & 1 )
	  printf("Subtracting minimum block average from image: %7.3f \n", minave);
	for ( kk=0;kk<size;kk++) {
	  pix[kk] = pix[kk] - minave;
	  tpix[kk] = tpix[kk] - minave;
	}
	gsl_matrix_add_constant(backmat, -minave);
      }

      nxsurf = xsurf;
      nysurf = ysurf;
      ncsurf = csurf;
      if ( 1-barea/area < minarea  ){
	if ( 1 ) {
	  if ( verbose & 64) {
	    printf("ONLY %7.2f good area, setting surface to constant: Z = a.\n", 1-barea/area);
	  }
	  nxsurf = nysurf = 1;
	  ncsurf = 0;
	}
	if ( 0 ) {
	  if ( verbose & 64) {
	    printf("ONLY %7.2f good area, setting surface to planar: Z = aX+bY+d.\n", 1-barea/area);
	  }
	  nxsurf = nysurf = 2;
	  ncsurf = 0;
	}
	if ( 0 ) {
	  if ( verbose & 64) {
	    printf("ONLY %7.2f good area, NOT fitting surface.\n", 1-barea/area);
	  }
	  nxsurf = nysurf = 0;
	  ncsurf = 0;
	}
      }
/* FIT SURFACE TO IMAGE */
      if ( nxsurf != 0 && nysurf != 0 ) {
	int mktemp1 = 0;
	char nname[256];
	fitsfile *outfptr11=NULL, *outfptr22=NULL, *outfptr33=NULL;
	int naxis2 = 2;
	long naxes2[2], fpixel2[2];
	double tback[xgrid*ygrid];
	double tsig[xgrid*ygrid];
	/* double xi[xgrid]; */
	/* double yi[ygrid]; */
	double yerr;

	naxes2[0] = xgrid;
	naxes2[1] = ygrid;
	fpixel2[0] = fpixel2[1] = 1;

	if ( abs(ncsurf) > 1 )
	  mktemp1 = 1;

	if ( mktemp1 ){
	  strcpy(nname,name);
	  strcat(nname,".b1.fits");
	  fits_create_file(&outfptr11, nname , &status);
	  fits_create_img(outfptr11, FLOAT_IMG, naxis2, naxes2, &status);
	  fits_create_file(&outfptr22, strcat(nname,".fits"), &status);
	  fits_create_img(outfptr22, FLOAT_IMG, naxis2, naxes2, &status);
	  fits_create_file(&outfptr33, strcat(nname,".fits"), &status);
	  fits_create_img(outfptr33, FLOAT_IMG, naxis2, naxes, &status);
	}

	_i = xgrid*ygrid;
	_j = nxsurf * nysurf;

	gsl_multifit_linear_workspace *work=NULL;
	work = gsl_multifit_linear_alloc (_i, _j); 
	X = gsl_matrix_alloc (_i, _j); 
	y = gsl_vector_alloc (_i); 
	w = gsl_vector_alloc (_i); 
	c = gsl_vector_alloc (_j);
	x = gsl_vector_alloc (_j); 
	cov = gsl_matrix_alloc (_j, _j);

	for (ii = 0; ii < xgrid; ii++)  {
	  for (jj = 0; jj < ygrid; jj++) {
	    gsl_vector_set (y, ii+xgrid*jj, gsl_matrix_get (backmat,ii,jj) );
	    gsl_vector_set (w, ii+xgrid*jj, gsl_matrix_get (sigmat,ii,jj) );
	    if ( mktemp1 ) {
	      tback[ii+xgrid*jj] = gsl_matrix_get (backmat,ii,jj);
	      tsig[ii+xgrid*jj] = gsl_matrix_get (sigmat,ii,jj);
	    }
	    for (_i = 0; _i<nxsurf; _i++) {
	      for (_j = 0; _j<nysurf; _j++) {
		if ( ncsurf == 0 && _j > 0 && _j == _i) {
		  gsl_matrix_set (X, ii+xgrid*jj, _i+nxsurf*_j, 0.0 );
		} else {
		  gsl_matrix_set (X, ii+xgrid*jj, _i+nxsurf*_j, pow(ii*xsmooth,_i)*pow(jj*ysmooth,_j) );
		}
	      }
	    }
	  }
	}
	gsl_multifit_wlinear (X, w, y, c, cov, &chisq, work);

/* # INTERPOLATE OVER A BAD GRID IF TOO MANY SOURCES TO CONSTRAIN BACKGROUND */
	if ( 1 ) {
	  for (ii = 0; ii < xgrid; ii++)  {
	    for (jj = 0; jj < ygrid; jj++) {
	      if ( gsl_matrix_get(sigmat,ii,jj) <= lweight ) {
		tmp = 0.;
		for (_i = 0; _i<nxsurf; _i++) {
		  for (_j = 0; _j<nysurf; _j++) {
		    if ( verbose & 64 && 0 ) printf("gridx=%3d gridy=%3d    x=%d y=%d term=%7.3g\n",ii,jj,_i,_j,gsl_vector_get(c,_i+nxsurf*_j));
		    tmp = tmp + gsl_vector_get(c,_i+nxsurf*_j)*pow(ii*xsmooth,_i)*pow(jj*ysmooth,_j);
		  }
		}
		gsl_matrix_set(backmat,ii,jj,tmp);
		gsl_matrix_set(sigmat,ii,jj, lweight);
		if ( mktemp1 ) {
		  tback[ii+xgrid*jj] = gsl_matrix_get (backmat,ii,jj);
		  tsig[ii+xgrid*jj] = gsl_matrix_get (sigmat,ii,jj);
		}
	      }
	    }
	  }
	}


	if ( csurf < 0 ) {
	  printf("Fitting Mesh-Surface: xsurf = %d, ysurf= %d, csurf= %d, %5d %5d : %3d %3d \n",nxsurf, nysurf, ncsurf, xsmooth, ysmooth, xgrid, ygrid);
/* IMAGE IS IN BLOCKS grid = xgrid * ygrid...NEED TO SMOOTH IT.  BILINEAR */
	  gsl_matrix *backmat2 = gsl_matrix_alloc (2,2);
	  gsl_matrix *sigmat2 = gsl_matrix_alloc (2,2);
	  double size = xsmooth;
	  int _ii, _jj, kk;
	  double _i, _j;
	  double corner, num;
	  /* LOOP OVER GRID SQUARES */
	  for ( ii=0; ii<(xgrid); ii++ ) {
	    for ( jj=0; jj<(ygrid); jj++) {
	      /* FIND CORNER VALUES */
	      for (_ii=0;_ii<2;_ii++) {
		for (_jj=0;_jj<2;_jj++) {
		  corner = 0;
		  num = 0;
		  for (_i=0;_i<2;_i++) {
		    if ( ii+_ii+_i-1 < 0 || ii+_ii+_i-1 >= xgrid ) continue;
		    for (_j=0;_j<2;_j++) {
		      if ( jj+_jj+_j-1 < 0 || jj+_jj+_j-1 >= ygrid ) continue;
		      corner = corner + gsl_matrix_get (backmat,ii+_ii+_i-1,jj+_jj+_j-1);
		      num++;
		    }
		  }
		  gsl_matrix_set (backmat2, _ii, _jj, corner/num );
		}
	      }
	      /* LOOP OVER PIXELS WITHIN GRID */
	      for (i=0;i<size;i++) {
		for (j=0;j<size;j++) {
		  /* COMPUTE WEIGHTS FOR EACH PIXEL */
		  gsl_matrix_set (sigmat2, 0, 0,  (1.- i/size )*(1.- j/size ) );
		  gsl_matrix_set (sigmat2, 0, 1,  (1.- i/size )*( j/size ) );
		  gsl_matrix_set (sigmat2, 1, 0,  ( i/size )*(1.- j/size ) );
		  gsl_matrix_set (sigmat2, 1, 1,  ( i/size )*( j/size ) );
		  /* FIND WEIGHTED AVERAGE PIXEL VALUE */
		  kk = i+ii*size+naxes[0]*(j+jj*size);
		  fit[kk] = gsl_stats_wmean (sigmat2->data, 1, backmat2->data, 1, backmat2->size1 * backmat2->size2 );
		  tmpfit[kk] = tmpfit[kk] + fit[kk];
		  pix[kk] = pix[kk] - fit[kk];
		}
	      }
	    }
	  }
	  gsl_matrix_free (backmat2);
	  gsl_matrix_free (sigmat2);	  
	  
	} else {
	  printf("Fitting Surface: xsurf = %d, ysurf= %d, csurf= %d, %5d %5d : %3d %3d \n",nxsurf, nysurf, ncsurf, xsmooth, ysmooth, xgrid, ygrid);
	  for (ii = 0; ii < naxes[0]; ii++) {
	    for (jj = 0; jj < naxes[1]; jj++) {  
	      kk = ii+naxes[0]*(jj);
	      fit[kk] = 0.0;
	      if ( gsl_finite(chisq)  ) {
		if ( 0 ) {
		  for (_i = 0; _i<nxsurf; _i++) {
		    for (_j = 0; _j<nysurf; _j++) {
		      gsl_vector_set(x,_i+nxsurf*_j,pow(ii,_i)*pow(jj,_j) );
		    }
		  }
		  gsl_multifit_linear_est (x, c, cov, &fit[kk], &yerr );
		} else {
		  for (_i = 0; _i<nxsurf; _i++) {
		    for (_j = 0; _j<nysurf; _j++) {
		      fit[kk] = fit[kk] + gsl_vector_get(c,_i+nxsurf*_j)*pow(ii,_i)*pow(jj,_j);
		    }
		  }
		}
	      }
	      tmpfit[kk] = tmpfit[kk] + fit[kk];
	      pix[kk] = pix[kk] - fit[kk];	
	    }
	  }

	}

	if ( mktemp1 ) {
	  fits_write_pix(outfptr11, TDOUBLE, fpixel2, xgrid*ygrid, tback, &status);
	  fits_write_pix(outfptr22, TDOUBLE, fpixel2, xgrid*ygrid, tsig, &status);
	  fits_close_file(outfptr11, &status);
	  fits_close_file(outfptr22, &status);
	  fits_write_pix(outfptr33, TDOUBLE, fpixel2, size, tmpfit, &status);
	  fits_close_file(outfptr33, &status);
	}
	gsl_multifit_linear_free (work);
	gsl_matrix_free (X); 
	gsl_vector_free (w); 
	gsl_vector_free (y); 
	gsl_vector_free (c); 
	gsl_vector_free (x); 
	gsl_matrix_free (cov);
      }
      gsl_matrix_free (backmat); 
      gsl_matrix_free (sigmat); 
      gsl_vector_free (cell); 

/* PERFORM WAVELET TRANSFORM */
      printf("waven = %d \n",waven);
      if ( waven > 0 ) {
	xnum = naxes[0]*naxes[1];
	int z;
	char nname[256];
	int mktemp = 0;
	if ( abs(csurf) > 1 )
	  mktemp = 1;
	
	fitsfile *outfptr11=NULL, *outfptr22=NULL, *outfptr33=NULL, *outfptr44=NULL;
	if ( mktemp ){
	  /* create output file */
	  strcpy(nname,name);
	  strcat(nname,".w1.fits");
	  fits_create_file(&outfptr11, nname, &status);
	  fits_copy_header(infptr1, outfptr11, &status); /* copy original header which define naxis, naxes */
	  fits_create_file(&outfptr22, strcat(nname,".w2.fits"), &status);
	  fits_copy_header(infptr1, outfptr22, &status); /* copy original header which define naxis, naxes */
	  fits_create_file(&outfptr33, strcat(nname,".w3.fits"), &status);
	  fits_copy_header(infptr1, outfptr33, &status); /* copy original header which define naxis, naxes */
	  fits_create_file(&outfptr44, strcat(nname,".w4.fits"), &status);
	  fits_copy_header(infptr1, outfptr44, &status); /* copy original header which define naxis, naxes */

	  fits_write_pix(outfptr11, TDOUBLE, fpixel, xnum, tpix, &status);
	}
	if ( verbose & 1 ) {
	  printf("Applying wavelet transform, setting to zero n=1-%d\n", waven);
	  printf("Forward transform\n");
	}
	wave = gsl_wavelet_alloc(gsl_wavelet_haar,2);
	wavework = gsl_wavelet_workspace_alloc(naxes[0]); 
	// Perform the wavelet transform.
/* 	gsl_wavelet2d_nstransform_forward(wave,pix,1*naxes[0],naxes[0],naxes[1],wavework); */
	gsl_wavelet2d_nstransform_forward(wave,tpix,1*naxes[0],naxes[0],naxes[1],wavework);
	if ( mktemp )
	  fits_write_pix(outfptr22, TDOUBLE, fpixel, xnum, tpix, &status);
	if ( 0 ) {
	  tpix[0] = 0;
	}
	for (i=1; i<=(naxes[0]/2); i=i*2) {
	  for (j=1; j<=3; j++){
	    if (j==1)
	      z = i;
	    if (j==2)
	      z = i*naxes[0];
	    if (j==3)
	      z = i + i*naxes[0];
	    /* printf("\nBasis = %d:%d\n",i,j); */
	    for (_j=0; _j<i; _j++) {
	      for (_i=0; _i<i; _i++) {
		kk = z+_i+naxes[0]*_j; 
/* set low frequency structure to zero */
/* 		The larger the number the more it creates divots around objects.  */
		if ( 0 ) {  /* SUBTRACT BACKGROUND STRUCTURE */
		  tpix[kk] = (i<=waven) ? 0 : tpix[kk];
		} else {    /* LEAVE BACKGROUND STRUCTURE */
		  tpix[kk] = (i<=waven) ? tpix[kk] : 0 ;
		}
	      }
	    }
	  } /* change basis sub-block */
	} /* change basis */
	if ( mktemp )
	  fits_write_pix(outfptr33, TDOUBLE, fpixel, xnum, tpix, &status);	
	// Perform the inverse transform.
	if ( verbose & 1 )
	  printf("Reverse transform\n");

	gsl_wavelet2d_nstransform_inverse(wave, tpix, 1*naxes[0], naxes[0], naxes[0], wavework);

/* 	for ( kk = 0; kk<xnum; kk++) { */
/* 	  fit[kk] = tpix[kk] ; */
/* 	  tmpfit[kk] = tmpfit[kk] + fit[kk]; */
/* 	  pix[kk] = pix[kk] - fit[kk]; */
/* 	} */

/* IMAGE IS IN BLOCKS grid = 2*wavelet...NEED TO SMOOTH IT.  BILINEAR */
	gsl_matrix *backmat2 = gsl_matrix_alloc (2,2);
	gsl_matrix *sigmat2 = gsl_matrix_alloc (2,2);
	double size = naxes[0]/(2*waven);
	int _ii, _jj, kk;
	double _i, _j;
	double corner, num;
/* LOOP OVER GRID SQUARES */
	for ( ii=0; ii<(2*waven); ii++ ) {
	  for ( jj=0; jj<(2*waven); jj++) {
/* FIND CORNER VALUES */
	    for (_ii=0;_ii<2;_ii++) {
	      for (_jj=0;_jj<2;_jj++) {
		corner = 0;
		num = 0;
		for (_i=0;_i<2;_i++) {
		  if ( ii+_ii+_i-1 < 0 || ii+_ii+_i-1 >= 2*waven ) continue;
		  for (_j=0;_j<2;_j++) {
		    if ( jj+_jj+_j-1 < 0 || jj+_jj+_j-1 >= 2*waven ) continue;
		    kk = size*(ii+_ii+_i-0.5+naxes[0]*(jj+_jj+_j-0.5));
		    corner = corner + tpix[kk];
		    num++;
		  }
		}
		gsl_matrix_set (backmat2, _ii, _jj, corner/num );
	      }
	    }
/* LOOP OVER PIXELS WITHIN GRID */
	    for (i=0;i<size;i++) {
	      for (j=0;j<size;j++) {
		/* COMPUTE WEIGHTS FOR EACH PIXEL */
		gsl_matrix_set (sigmat2, 0, 0,  (1.- i/size )*(1.- j/size ) );
		gsl_matrix_set (sigmat2, 0, 1,  (1.- i/size )*( j/size ) );
		gsl_matrix_set (sigmat2, 1, 0,  ( i/size )*(1.- j/size ) );
		gsl_matrix_set (sigmat2, 1, 1,  ( i/size )*( j/size ) );
		/* FIND WEIGHTED AVERAGE PIXEL VALUE */
		kk = i+ii*size+naxes[0]*(j+jj*size);
		fit[kk] = gsl_stats_wmean (sigmat2->data, 1, backmat2->data, 1, backmat2->size1 * backmat2->size2 );
		tmpfit[kk] = tmpfit[kk] + fit[kk];
		pix[kk] = pix[kk] - fit[kk];
	      }
	    }
	  }
	}
	gsl_matrix_free (backmat2);
	gsl_matrix_free (sigmat2);	 
	if ( mktemp ) {
	  if ( 1 ) {     /* THE INTERPOLATED VERSION */
	    fits_write_pix(outfptr44, TDOUBLE, fpixel, xnum, fit, &status);
	  } else {       /* THE BLOCK VERSION */
	    fits_write_pix(outfptr44, TDOUBLE, fpixel, xnum, tpix, &status);
	  }
	}
	gsl_wavelet_free(wave);
	gsl_wavelet_workspace_free(wavework);
      }




      if ( 1 ) {
	/* OPEN FLAT FIELD IMAGE, APPLY TO DATA BEFORE SUBTRACTING */
	strcpy(name4,name3);
	strcat(name4,filter);
	strcat(name4,"_");
	char chipstr[10];
	sprintf(chipstr,"%d",chip);
	strcat(name4,chipstr);
	strcat(name4,".fits");
	xnum = naxes[0]*naxes[1];
	printf("%s,%d\n",name4,xnum);
	if ( ! fits_open_file(&infptr4, name4, READONLY, &status) ) {
	  if ( verbose & 1 )
	    printf("Using flat field\n");
	  fits_read_pix(infptr4, TDOUBLE, fpixel, xnum, 0, flat, 0, &status);
	  fits_close_file(infptr4, &status);
	} else {
	  if ( verbose & 1 )
	    printf("NO flat field\n");
	  for (kk=0;kk<xnum;kk++) {
	    flat[kk] = 1.0;
	  }
	}

/* fit single rows/columns (remove striping).  do rows fits then column fits */
      for ( axis=0; axis<=1; axis++) {
	switch (axis) {
	  case 0:
	    ftype = "rows";
	    oaxis = 1;
	    fitn = fitr;
	    nsmooth = fitn < 0 ? floor((double)naxes[0]/fabs(fitn)) : xsmooth;
	    break;
	  case 1:
	    ftype = "cols";
	    oaxis = 0;
	    fitn = fitc;
	    nsmooth = fitn < 0 ? floor((double)naxes[1]/fabs(fitn)) : ysmooth;
	    break;
	  default:
	    break;
	  }

/* check if all sub-blocks along axis are masked along any direction, if so do not fit along that direction.   */
	if ( verbose & 2 ) {
	  if (axis == 0 ) { 
	    for (j = 0; j<ygrid;j++){
	      xnum = 0;
	      for (i = 0; i<xgrid;i++){
		xnum = gsl_matrix_get(backmat,i,j) == 0.0 ? xnum + 1 : xnum  ;
	      }
	      if (xnum >= (frac)*xgrid ){
		printf("not fitting along rows, at least one stripe is totally masked\n");
		fitn = 0;
		break;
	      }
	    }
	  } else {
	    for (i = 0; i<xgrid;i++){
	      xnum = 0;
	      for (j = 0; j<ygrid;j++){
		xnum = gsl_matrix_get(backmat,i,j) == 0.0 ? xnum + 1 : xnum  ;
	      }
	      if (xnum >= (frac)*ygrid ){
		printf("not fitting along columns, at least one stripe is totally masked\n");
		fitn = 0;
		break;
	      }
	    }
	  }
	}


/* fit */
	if ( fitn == 0) continue;
	if ( verbose & 1 )
	  printf("fitting %5s: order = %d, lrej=%4.1g, hrej=%4.1g, lsig = %3.1f, hsig = %3.1f, niter = %d, ngrow = %d, back = %8.3f, bsig = %6.2f, smooth = %d\n", ftype,fitn,minval,maxval,losig,hisig,niter,ngrow,back,bsig,nsmooth);
	gsl_multifit_linear_workspace *work=NULL;
	gsl_vector *cell = gsl_vector_alloc (nsmooth);
	_i = ceil((double)naxes[axis]/(double)nsmooth);
	_j = abs(fitn);
	if ( fitn > 0 ) {
	  X = gsl_matrix_alloc (_i, _j); 
	  c = gsl_vector_alloc (_j); 
	  xi = gsl_vector_alloc (_j); 
	  cov = gsl_matrix_alloc (_j, _j);
	  work= gsl_multifit_linear_alloc (_i, _j);
	}
	x = gsl_vector_alloc (_i); 
	y = gsl_vector_alloc (_i); 
	w = gsl_vector_alloc (_i); 
/* loop over orthogonal (outer) axis */
	for (jj = 0; jj < naxes[oaxis]; jj++) {
	  ntmp = niter;
	  back2 = back;
	  hisig2 = hisig*0.75;
	  losig2 = losig*0.75;
/* loop over segments of length nsmooth */
	  nfit = 0;
	  for (ii = 0; ii < ceil((double)naxes[axis]/(double)nsmooth); ii++) {
/* average pixels in this segment bin */
	    tmp = 0.0;
	    xnum = 0;
	    for (_i = 0 ; _i < nsmooth ; _i++) {
	      kk = (axis == 0) ? _i+ii*nsmooth+naxes[0]*(jj) : jj+naxes[0]*(_i+ii*nsmooth);
	      /* FORCE FLAT TO UNITY */
	      if ( 0 ) 
		flat[kk] = 1.0;

	      if (_i + ii*nsmooth >= naxes[axis] ) {
		break;
	      }
	      if ( (tbpix[kk] > 0  ) || pix[kk] > back2+hisig2*bsig || pix[kk] < back2-losig2*bsig  ) {
		gsl_vector_set(cell,_i,1.e33);
	      } else {
		gsl_vector_set(cell,_i,pix[kk]*flat[kk]);
		xnum++;
	      }
	    }
	    gsl_sort(cell->data,1,nsmooth);
	    /* tmp = xnum < 10 ? 999.99 : gsl_stats_quantile_from_sorted_data(cell->data,1,xnum,0.25) ; */
	    tmp = xnum < 10 ? 999.99 : gsl_stats_mean(cell->data,1,xnum) ;
/* set weight of this line segment */
	    if ( verbose & 64 && 0 ) 
	      printf("%6.2f %6.2f %4.2f %3.1f %3.1f %3d %3d \n",tmp,back2,bsig,hisig2,losig2,xnum,nfit);
	    /* if ( fabs(tmp) > 20 || tmp > back2+hisig2*bsig || tmp < back2-losig2*bsig ) {  */
	    if ( fabs(tmp) > 20 ) { 
	      for (ni = 0 ; ni <= 0 ; ni++ ) {
		_i = (ii+ni) < 0 ? 9999 : (ii+ni)>=ceil((double)naxes[axis]/(double)nsmooth) ? 9999 : ii+ni ;
		if ( _i == 9999)
		  continue;
		if ( fitn > 0) {
		  gsl_vector_set(w, _i, 0);
		} else {
		  gsl_vector_set(w, _i, 0.01);
		}
		gsl_vector_set(y, _i, back2);
	      }
	    } else {
	      gsl_vector_set(w, ii, 1.0);
	      gsl_vector_set(y, ii, tmp);
	      nfit++;
	    }
	    /* set matrix elements if doing a polynomial fit */
	    if (fitn > 0 ) {
	      for (_i = 0; _i < fitn; _i++) {
		gsl_matrix_set (X, ii, _i, pow(ii*nsmooth/2,_i) );
	      }
	    }
	    gsl_vector_set (x, ii, ii*nsmooth/2); 
	    if ( 0 )
	      printf("%6d %6d: %6.0f %6.3f %6.0g\n",jj,ii,gsl_vector_get(x, ii),gsl_vector_get(y, ii),gsl_vector_get(w, ii));
	  }
	  /* row/column initialization done, set average level of this axis */
	  /* require at least this many good segments along the axis */
	  if ( nfit < (int)ceil(frac*(double)naxes[axis]/(double)nsmooth) ) {
	    if ( 1 )
	      printf("%d < %d segments...skipping axis %d:%d.\n",nfit,(int)ceil(frac*(double)naxes[axis]/(double)nsmooth),axis,jj+1);
	    continue;
	  }
	  /* set up interpolation vector if doing spline fit */
	  if ( fitn < 0 ){
	    double xi[nfit+2], yi[nfit+2]; 
	    xi[0] = 0.0-1000.0;
	    yi[0] = 0.0;
	    xi[nfit+2-1] = naxes[axis]+1000.0;
	    yi[nfit+2-1] = 0.0;
	    _i = 1;
	    for (ii = 0; ii<ceil((double)naxes[axis]/(double)nsmooth); ii++){
	      if ( gsl_vector_get (w, ii) == 1.0 ){
		xi[_i] = gsl_vector_get(x,ii);
		yi[_i] = gsl_vector_get(y,ii);
		_i++;
	      }
	    }
	    if ( 0 ) {
	      printf("nfit | %10d\n",nfit);
	      for (_i = 0 ; _i<nfit+2 ; _i++){
		printf("%6.0f %6.3f\n",xi[_i], yi[_i] );
	      }
	    }
	    acc = gsl_interp_accel_alloc (); 
	    /* optional interpolation algorithms | gsl_interp_linear | gsl_interp_polynomial | gsl_interp_akima |  gsl_interp_cspline */
	    spline = gsl_spline_alloc (gsl_interp_linear, nfit+2); 
	    gsl_spline_init (spline, xi, yi, nfit+2); 
	    sigma = bsig;
	  } else {
	    gsl_multifit_wlinear (X, w, y, c, cov, &chisq, work);
	    sigma = sqrt(chisq/(nfit-fitn)*nsmooth);
	    if ( verbose & 64 && 0 ){
	      printf("\nchisq | ntmp  |  nfit | redchisq       %5.2e | %2d | %5d | %5.1f\n",chisq,ntmp,nfit,sigma);
	      for (_j = 0; _j<fitn; _j++) {
		printf("%d : %f\n",_j,gsl_vector_get(c,_j));
	      }
	    }
	  }
/* Loop over each pixel in the row to find the fit */
	  for (ii = 0; ii < naxes[axis]; ii++) {
	    kk = ( axis == 0 ) ? ii+naxes[0]*(jj) : jj+naxes[0]*(ii);
	    tmpfit[kk] = 0.0;
	    if ( fitn < 0 ) {
	      tmpfit[kk] = gsl_spline_eval(spline,ii,acc);
	    } else {
	      for (_i = 0; _i<fitn; _i++) {
		gsl_vector_set(xi,_i,pow(ii,_i));
	      }
	      gsl_multifit_linear_est(xi,c,cov,&tmpfit[kk],&tmp);
	    }
	  } /* inner axis loop */
	  for (ii = 0; ii < naxes[axis]; ii++) {
	    kk = ( axis == 0 ) ? ii+naxes[0]*(jj) : jj+naxes[0]*(ii);
	    fit[kk] = fit[kk] + tmpfit[kk]/flat[kk];
	    pix[kk] = pix[kk] - tmpfit[kk]/flat[kk];
	    tpix[kk] = tpix[kk] - tmpfit[kk]/flat[kk];
	    /* printf("%10d %7.3f\n",kk,fit[kk]); */
	  }
	  if (fitn < 0 ) {
	    gsl_spline_free (spline); 
	    gsl_interp_accel_free (acc); 
	  }
	} /* outer axis loop */
	/* free memory */
	if ( fitn > 0 ) {
	  gsl_matrix_free (X); 
	  gsl_vector_free (c); 
	  gsl_vector_free (xi); 
	  gsl_matrix_free (cov);
	  gsl_multifit_linear_free (work);
	}
	gsl_vector_free (cell); 
	gsl_vector_free (x); 
	gsl_vector_free (y); 
	gsl_vector_free (w); 
      } /* axis loop */

      }


/* smooth background image */
      if ( 0 ) {
	nsmooth = 3;
	printf("Smoothing background, boxcar %dx%d \n",2*nsmooth+1,2*nsmooth+1);
	for ( ii=0;ii<naxes[0];ii++){
	  for ( jj=0;jj<naxes[1];jj++) {
	    kk = ii + naxes[0]*jj;
	    tmpfit[kk] = 0.0;
	    for (ni = -nsmooth; ni <= nsmooth; ni++) {
	      _i = (ii+ni) < 0 ? 9999 : (ii+ni)>=naxes[0] ? 9999 : ii+ni ;
	      if ( _i == 9999)
		continue;
	      for ( nj = -nsmooth; nj <= nsmooth ; nj++){
		_j = (jj+nj) < 0 ? 9999 : (jj+nj)>=naxes[1] ? 9999 : jj+nj ;
		if ( _j == 9999)
		  continue;
		tmpfit[kk] = tmpfit[kk] + fit[_i+naxes[0]*(_j)];
	      }
	    }
	    pix[kk] = pix[kk] + fit[kk];
	    fit[kk] = tmpfit[kk] / (double)pow((2*nsmooth+1),2);
	    pix[kk] = pix[kk] - fit[kk];
	  }
	}
      }


/* 2048 - border */
/* 64 - no sky, hole */
/* 32 - Object */
/* 16 - transient artifact */
/* 8 - latency, previously saturated */
/* 4 - guide probe vignetting */
/* 2 - saturated */
/* 1 - bad pixel */
/* 0 - good value */
/* 2048+64+16+8+4+2+1 = 95 - match bitpattern for this number */
/* 2048+   16+8+4+2+1 = 31 - match bitpattern for this number */
/* 2048+   16+ +4+2+1 = 23 - match bitpattern for this number */
/* 2048+64+16+8+4+ +1 = 93 - match bitpattern for this number */
/* 2048+   16+8+4+ +1 = 29 - match bitpattern for this number */
/* 2048+64+16+ +4+ +1 = 85 - match bitpattern for this number */
/* 2048+   16+ +4+ +1 = 21 - match bitpattern for this number */
/* 2048+  +16+8+4+2+1 = 2079 - match bitpattern for this number */
      /* bitmask = ( verbose & 16 ) ? 21 : 85; */
      /* bitmask = bitmask + 2048; */
/* interpolate image */
      if ( verbose & 8 ) {
	int ns;
	nsmooth = 1;
	printf("Interpolating bad image pixels... \n");
	for ( ii=0;ii<naxes[0];ii++){
	  for ( jj=0;jj<naxes[1];jj++) {
	    kk = ii + naxes[0]*jj;
	    if ( bpix[kk] & bitmask ) {
	      ns = nsmooth;
	    interp:
	      ave = 0.0;
	      xnum = 0;
	      for (ni = -ns; ni <= ns; ni++) {
		_i = (ii+ni) < 0 ? 9999 : (ii+ni)>=naxes[0] ? 9999 : ii+ni ;
		if ( _i == 9999) continue;
		for ( nj = -ns; nj <= ns ; nj++){
		  _j = (jj+nj) < 0 ? 9999 : (jj+nj)>=naxes[1] ? 9999 : jj+nj ;
		  if ( _j == 9999) continue;
		  if ( bpix[_i + naxes[0]*_j] & bitmask ) continue;
		  ave = ave + pix[_i+naxes[0]*(_j)];
		  xnum++;
		}
	      }
	      if ( xnum <= 3 && ns < 32  ) {
		ns = nsmooth*2;
		goto interp;
	      }
	      pix[kk] = xnum>3 ? ave/(double)xnum : 0.0 ;
	    }
	  }
	}
      }


/* write image */
      switch(itype)
      {
      case 0:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, fit, &status);
	break;
      case 1:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, pix, &status);
	break;
      case 2:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, tpix, &status);
	break;
      default:
	break;
      }

/* make weight image */
      if ( verbose & 4 ) {
	printf("Making weight image\n");
	for ( ii=0;ii<naxes[0];ii++){
	  for ( jj=0;jj<naxes[1];jj++) {
	    kk = ii + naxes[0]*jj;
	    // reject flagged pixels
	    bpix[kk] = ( bpix[kk] & bitmask ) ? 0 : (int)fwhmn;
	    // accept only objects 
	    /* bpix[kk] = (bpix[kk] == 32 || bpix[kk] == 0 ) ? (int)fwhmn : 0; */
	    /* bpix[kk] = (int)fwhmn; */
	  }
	}
      }
      fits_write_pix(outfptr2, TINT, fpixel, size, bpix, &status);

/* make mask image */
      if ( verbose & 4 ) {
	printf("Making mask image\n");
	for ( ii=0;ii<naxes[0];ii++){
	  for ( jj=0;jj<naxes[1];jj++) {
	    kk = ii + naxes[0]*jj;
	    bpix[kk] = ( bpix[kk] == 0 ) ? 1 : 0;
	  }
	}
      }
      fits_write_pix(outfptr3, TINT, fpixel, size, bpix, &status);

      fits_close_file(infptr1, &status);
      fits_close_file(infptr2, &status);


      } /* END WHILE LOOP OVER INPUT IMAGE LIST */

/* free memory */
      free(pix);
      free(tpix);
      free(fit);
      free(tmpfit);
      free(bpix);
      free(tbpix);
      free(flat);



      gsl_rng_free (r);

      fits_close_file(outfptr1, &status);
      fits_close_file(outfptr2, &status);
      fits_close_file(outfptr3, &status);
      fclose(input);

      printf("DONE \n");	  
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
    fprintf (stderr,"Not yet documented.\n");


    exit (1);
}
