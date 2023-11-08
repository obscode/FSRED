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

const double frac = 0.1;


static void PrintUsage();
static char *RevMsg = "mimsurfit 0.0, 10 April 2012, Andy Monson (monson.andy@gmail.com)";
static int version_only = 0;		/* If 1, print only program name and version */

void printerror( int status);

int main(int argc, char *argv[])
    {
      int verbose = 0;
      fitsfile *infptr1=NULL, *infptr2=NULL, *outfptr1=NULL, *outfptr2=NULL, *outfptr3=NULL;  /* pointer to the FITS files */
      char *ftype=NULL, *str=NULL;
      char name[256], name2[256], outname[256], outname2[256],outname3[256]; 
      int status = 0, bitpix, hdunum, nkeys, axis, oaxis, fitn, fitr=0, fitc=0, ni, nj, ngrow=0, i, j, _i, _j, ii, jj, kk, naxis, niter=1, ntmp=1, size ,xnum;  /* MUST initialize status */
      long naxes[3], fpixel[3];
      double *pix=NULL, *tpix=NULL, *fit=NULL, *tmpfit=NULL, tmp, back=0, back2, rand, bsig=0, ave, sigma, density, hisig=3, losig=3, hisig2, losig2, chisq, maxval = 1.E33, minval = -1.E33;
      int *bpix=NULL, *tbpix=NULL;
      int nsmooth, xsmooth = 128, ysmooth = 128, xgrid, ygrid, nfit, itype=0, waven=0, chip;
      int xsurf=0,ysurf=0,csurf=0,nxsurf=0,nysurf=0,ncsurf=0;
      int randno = 1;
      int stride = 1;
      double area, barea;
      gsl_matrix *X=NULL, *cov=NULL, *backmat=NULL, *sigmat=NULL; 
      gsl_vector *x=NULL, *y=NULL, *w=NULL, *c=NULL, *xi=NULL; 

      gsl_interp_accel *acc=NULL;
      gsl_spline *spline=NULL;

      gsl_wavelet *wave;
      gsl_wavelet_workspace *wavework; 

      const gsl_rng_type * T;
      gsl_rng * r;
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
	    	    	    
	  case 'i':       /* input image */
	    strcpy(name,*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'm':       /* input image mask */
	    strcpy(name2,*(argv+1));
	    /* strcat(name2,"[1]"); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    
	  case 'o':       /* output image list */
	    strcpy(outname,*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'x':       /* output image list */
	    strcpy(outname3,*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;


	  case 'b':       /* output image mask */
	    strcpy(outname2,*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'p':       /* minval */
	    minval = atof(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'q':       /* maxval */
	    maxval = atof(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;


	  case 'h':       /* high sigma reject */
	    hisig = atof(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'l':       /* low sigma reject */
	    losig = atof(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    
	  case 'n':       /* number of rejection iterations */
	    niter = atoi(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    
	  case 'g':       /* grow radius */
	    ngrow = atoi(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;


	  case 'r':       /* xorder */
	    fitr = atoi(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    
	  case 'c':       /* yorder */
	    fitc = atoi(*(argv+1));
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

/* ####################################################################### */
      /*  open input image  */
      fits_open_file(&infptr1, name, READONLY, &status);
      fits_get_img_param(infptr1, 3, &bitpix, &naxis, naxes, &status );
      size = naxes[0] * naxes[1];
      if ( verbose )
	printf("%d\n", size);
      if ( 1 ) {
	pix = (double *) malloc(size * sizeof(double)); /* memory for 2d image */
	tpix = (double *) malloc(size * sizeof(double)); /* memory for 2d image */
	fit = (double *) malloc(size * sizeof(double)); /* memory for output 2d image */
	tmpfit = (double *) malloc(size * sizeof(double)); /* memory for output 2d image */
/* CALLOC INITS TO ZERO */
	bpix = (int *) calloc(size , sizeof(int)); /* memory for 2d mask */
	tbpix = (int *) calloc(size , sizeof(int)); /* memory for 2d mask */
	if (pix == NULL || fit == NULL || bpix == NULL || tmpfit == NULL ) {
	  printf("Memory allocation error\n");
	  return(1);
	}
      }
      fpixel[0] = fpixel[1] = fpixel[2] = 1;
      fits_read_pix(infptr1, TDOUBLE, fpixel, size, 0, pix, 0, &status);
      /* create new empty file if necessary */
      if ( strcmp(outname,"" ) ) {
	if ( fits_create_file(&outfptr1, outname, &status) ) {
	  printerror( status );
	}
	fits_copy_file(infptr1, outfptr1, 1, 1, 1, &status);
      }
      if ( strcmp(outname3,"" ) ) {
	if ( fits_create_file(&outfptr3, outname3, &status) ) {
	  printerror( status );
	}
	fits_copy_file(infptr1, outfptr3, 1, 1, 1, &status);
      }

/* ####################################################################### */
      /*  open mask image  */
      if ( strcmp(name2,"" ) ) {
	fits_open_file(&infptr2, name2, READONLY, &status);
	fits_get_num_hdus(infptr2, &hdunum, &status);
	if ( hdunum > 1)
	  fits_movrel_hdu(infptr2, 1, NULL, &status);  /* try to move to next HDU */
	if (fits_read_pix(infptr2, TINT, fpixel, size, 0, bpix, 0, &status))
	  printerror(status);   /* jump out of loop on error */
      } else {
	/* printf("No input mask...\n"); */
      }

      if ( strcmp(outname2,"")) {
	/* create output mask file if not opened (didnt exist) */
	fits_create_file(&outfptr2, outname2, &status);
	/* create output image extension */
	if ( strcmp(name2,"")) {
	  fits_copy_file(infptr2, outfptr2, 1, 1, 1, &status);
	  /* fits_create_img(outfptr2, 8, 0, NULL, &status); */
	} else {
	  fits_create_img(outfptr2, 8, 0, NULL, &status);
	}
      } else {
	/* printf("No output mask...\n"); */
      }


/* ####################################################################### */

/* do initial masking of image, divide into blocks and determine whether or not to mask the entire block.  */
      nsmooth = ysmooth * xsmooth / (stride * stride) ;
      axis = 0;
      oaxis = 0;
      xgrid = ceil((double)naxes[0]/(double)xsmooth);
      ygrid = ceil((double)naxes[1]/(double)ysmooth);

      printf("number of sub-blocks: %d, %d   npix per block: %d\n",xgrid,ygrid, nsmooth);

      gsl_vector *cell = gsl_vector_alloc (nsmooth);
      backmat = gsl_matrix_alloc (xgrid,ygrid);
      sigmat = gsl_matrix_alloc (xgrid,ygrid);
      gsl_matrix_set_zero(backmat); 
      gsl_matrix_set_zero(sigmat); 
      area = xgrid*ygrid;
      barea = 0;
/* loop over column blocks */
      for (jj = 0; jj < ygrid; jj++) {
/* loop over row blocks */
	for (ii = 0; ii < xgrid; ii++) {
/* average pixels in this block */
	  tmp = 0.0;
	  ave = 0.0;
	  sigma = 0.0;
	  density = 0.0;
	  nkeys = 0;
	  xnum = 0;
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
	      if ( pix[kk] >= maxval || pix[kk] <= minval || bpix[kk] > 0 ) {
		tbpix[kk] = 1;
		gsl_vector_set(cell,_i/stride+xsmooth*_j/stride/stride,1.e33);
	      } else {
		gsl_vector_set(cell,_i/stride+xsmooth*_j/stride/stride,pix[kk]);
		xnum++;
	      }

	    }
	  }
/* compute block statistics */
	  gsl_sort(cell->data,1,nsmooth);
	  ave = xnum < 10 ? back : gsl_stats_mean(cell->data,1,xnum) ;
	  sigma = xnum < 10 ? 10 : gsl_stats_sd(cell->data,1,xnum) ;
/* find source density above local background */
	  for (_j = 0 ; _j < ysmooth ; _j+=stride) {
	    if (_j + jj*ysmooth >= naxes[1] ) {
	      break;
	    }
	    for (_i = 0 ; _i < xsmooth ; _i+=stride) {
	      if (_i + ii*xsmooth >= naxes[0] ) {
		break;
	      }
	      kk = _i+ii*xsmooth+naxes[0]*(_j+jj*ysmooth);
	      if ( bpix[kk] & 32 || ( (pix[kk] > ave+(hisig)*sigma || pix[kk] < ave-(losig)*sigma) && bpix[kk] == 0 ) ) {
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
	  density = (double)nkeys / (double)(nsmooth);
	  gsl_matrix_set(backmat,ii,jj,ave);
	  gsl_matrix_set(sigmat, ii, jj, (xnum <10 ? 0 : 1.0) );
/* mask this subblock if >25% source density *AND* background above normal.  In some cases the background is high but the source density is low (ie sky).  In some cases the source density is high but the background is low (object masks were over-estimated) */

/* end mask */
	  if ( verbose & 2 )
	    printf("%04d %04d (%04d %04d)   %5.3f    %7.3f %5.3f \n",ii,jj,xgrid,ygrid,density,ave,sigma);

	}
      }


/* fix the left edge of chip 4 */
      fits_read_key(infptr1, TINT, "CHIP", &chip, NULL, &status);
      if ( chip == 4 ) {
	if ( 1 )
	  printf("Fixing left edge of Chip 4\n");
/* loop over column blocks */
	for (jj = 0; jj < ceil((double)naxes[1]/(double)ysmooth); jj++) {
/* loop over row blocks */
	  for (ii = 0; ii < 1; ii++) {
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


/* FIT SURFACE TO IMAGE */
      if ( xsurf != 0 && ysurf != 0 ) {
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

	if ( abs(csurf) > 1 )
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
	
	if ( 1-barea/area < 0.5  ){
	  if ( 0 ) {
	    if ( verbose & 64) {
	      printf("ONLY %7.2f good area, setting surface to constant: Z = a.\n", 1-barea/area);
	    }
	    nxsurf = nysurf = 1;
	    ncsurf = 0;
	  } else {
	    if ( verbose & 64) {
	      printf("ONLY %7.2f good area, setting surface to planar: Z = aX+bY+cXY+d.\n", 1-barea/area);
	    }
	    nxsurf = nysurf = 2;
	    ncsurf = 1;
	  }
	} else {
	  nxsurf = xsurf;
	  nysurf = ysurf;
	  ncsurf = csurf;
	}
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
	  /* xi[ii] = ii*xsmooth+xsmooth/2.0; */
	  for (jj = 0; jj < ygrid; jj++) {
	    /* if ( ii == 0 ) yi[jj] = jj*ysmooth+ysmooth/2.0; */
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
	if ( 1 ) {
	  for (ii = 0; ii < xgrid; ii++)  {
	    for (jj = 0; jj < ygrid; jj++) {
	      if ( gsl_matrix_get(sigmat,ii,jj) < 1 ) {
		tmp = 0.;
		for (_i = 0; _i<nxsurf; _i++) {
		  for (_j = 0; _j<nysurf; _j++) {
		    if ( verbose & 64 && ii==0 && jj==0 ) printf("x=%d y=%d term=%7.3g\n",_i,_j,gsl_vector_get(c,_i+nxsurf*_j));
		    tmp = tmp + gsl_vector_get(c,_i+nxsurf*_j)*pow(ii*xsmooth,_i)*pow(jj*ysmooth,_j);
		  }
		}
		gsl_matrix_set(backmat,ii,jj,tmp);
		gsl_matrix_set(sigmat,ii,jj, 0.9);
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

	      if (_i + ii*nsmooth >= naxes[axis] ) {
		break;
	      }
	      if ( (tbpix[kk] > 0  ) || pix[kk] > back2+hisig2*bsig || pix[kk] < back2-losig2*bsig  ) {
		gsl_vector_set(cell,_i,1.e33);
	      } else {
		gsl_vector_set(cell,_i,pix[kk]);
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
	    fit[kk] = fit[kk] + tmpfit[kk];
	    pix[kk] = pix[kk] - tmpfit[kk];
	    tpix[kk] = tpix[kk] - tmpfit[kk];
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


/* write image */
      gsl_rng_free (r);
      switch(itype)
      {
/* FIT TO THE IMAGE */
      case 0:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, fit, &status);
	break;
/* RESIDUAL IMAGE */
      case 1:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, pix, &status);
	break;
/* CLEANED IMAGE */
      case 2:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, tpix, &status);
	break;
/* FIT TO THE IMAGE AND RESIDUAL */
      case 3:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, pix, &status);
	if (strcmp(outname3,"")) {
	  fits_write_pix(outfptr3, TDOUBLE, fpixel, size, fit, &status);
	  fits_close_file(outfptr3, &status);
	}
	break;
      default:
	break;
      }

      if (strcmp(outname2,"")) {
	fits_write_pix(outfptr2, TINT, fpixel, size, bpix, &status);
	fits_close_file(outfptr2, &status);
      }

      if (strcmp(name2,"")) {
	fits_close_file(infptr2, &status);
      }

/* free memory */
      free(pix);
      free(tpix);
      free(fit);
      free(tmpfit);
      free(bpix);
      free(tbpix);

      fits_close_file(infptr1, &status);
      fits_close_file(outfptr1, &status);

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
