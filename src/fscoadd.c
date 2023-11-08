/* File fsimcoadd.c
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


static void PrintUsage();
static char *RevMsg = "fsimcoadd 0.0, 10 April 2012, Andy Monson (monson.andy@gmail.com)";
static int version_only = 0;		/* If 1, print only program name and version */

void printerror( int status);

int main(int argc, char *argv[])
    {
      int verbose = 0;
      fitsfile *infptr1=NULL, *infptr2=NULL, *outfptr1=NULL, *outfptr2=NULL, *outfptr3=NULL, *outfptr4=NULL;  /* pointer to the FITS files */
      char *ftype=NULL, *str=NULL, *list=NULL, *wlist=NULL;
      char line[256], name1[256], name2[256], outname1[256], outname2[256], outname3[256], outname4[256], suffix[256]; 
      int status = 0, bitpix, nkeys, axis, oaxis, fitn, fitr=0, fitc=0, ni, nj, ngrow=0, i, j, _i, _j, ii, jj, kk, naxis, niter=1, ntmp=1, size ,xnum, count;  /* MUST initialize status */
      long naxes[3], fpixel[3];
      double *inpix1=NULL, *inpix2=NULL, *mospix=NULL, *exppix=NULL, *bppix=NULL, *sigpix=NULL, tmp, fwhm, fwhmn, back, back2, ave, bsig, sigma, rand, density, hisig=3, losig=3, hisig2, losig2, chisq;
      /* double maxval = 1.E33; */
      /* double minval = -1.E33; */
      double maxval = 65536.;
      double minval = -10000.;
      double minave=1.E33;
      double dlim = 0.02;
      double lweight = 0.1;
      double minarea = 0.5;
      int xsurf=0,ysurf=0,csurf=0,nxsurf=0,nysurf=0,ncsurf=0;
      int *bpix=NULL, *tbpix=NULL;
      int xsmooth = 128;
      int ysmooth = 128;
      int nsmooth, xgrid, ygrid, nfit, itype=0, waven=0, chip;
      int randno = 0;
      int stride = 1;
      int nline = 0, ntot = 0;
      double minrej = 0, maxrej = 0;
      int nminrej = 0, nmaxrej = 0;
      double area = 1, barea = 1;
      double corner, num, tave;

      gsl_vector *cell=NULL;
      gsl_vector *weight=NULL;
      gsl_vector *scale=NULL;
      gsl_vector *sample1=NULL;
      gsl_vector *sample2=NULL;
      gsl_matrix *X=NULL, *cov=NULL, *backmat=NULL, *sigmat=NULL; 
      gsl_vector *x=NULL, *y=NULL, *w=NULL, *c=NULL; 



      const gsl_rng_type * T;
      gsl_rng * r;
       gsl_rng_env_setup();
       T = gsl_rng_default;

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
	    	    	    
	  case 'i':       /* input image list */
	    list = *(argv+1);
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'm':       /* input image mask suffix */
	    strcpy(suffix,*(argv+1));
	    /* strcat(name2,"[1]"); */
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;
	    
	  case 'o':       /* output image list */
	    strcpy(outname1,*(argv+1));
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

	  case 'x':       /* maxrej */
	    maxrej = atof(*(argv+1));
	    if (argc < 2)
	      PrintUsage (str);
	    argc--;
	    argv++;
	    break;

	  case 'n':       /* minrej */
	    minrej = atof(*(argv+1));
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
	    if (argc < 2)
	      PrintUsage (str);
	    maxvali = *(argv+1);
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


	  case 'z':       /* input weight list */
	    wlist = *(argv+1);
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

/* ####################################################################### */
      /*  open input image  */

      nline = 0;
      FILE *input = fopen(list,"r");
      while (fgets(line,256,input) !=NULL){
	nline++;
      }
      ntot = nline;
      if ( verbose & 1 )
	printf("Number of input images: %d\n",ntot);

      sample1 = gsl_vector_alloc (ntot);
      sample2 = gsl_vector_alloc (ntot);
      weight = gsl_vector_alloc (ntot);
      scale = gsl_vector_alloc (ntot);
      gsl_vector_set_all(weight,1.0);
      gsl_vector_set_all(scale,1.0);


      if (strcmp(wlist,"")) {
	nline = 0;
	FILE *winput = fopen(wlist,"r");
	while (fgets(line,256,winput) !=NULL){
	  gsl_vector_set(weight, nline, atof(line) );
	  nline++;
	}
	printf("Number of input weights: %d\n",nline);
	fclose(winput);
	if ( nline != ntot ) {
	  gsl_vector_free(weight);
	  printf("Not enough weight elements in list.  Exiting. \n");
	  exit(1);
	}
      }

      r = gsl_rng_alloc (T);
      gsl_matrix *backmat2 = gsl_matrix_alloc (2,2);
      gsl_matrix *sigmat2 = gsl_matrix_alloc (2,2);

      nline = 0;
      rewind(input);
      while (fgets(line,100,input) !=NULL ){
	if(sscanf(line,"%s",name1)!=1) continue;
	nline++;

	fits_open_file(&infptr1, name1, READONLY, &status);
	/* fits_open_file(&infptr1, "shmem://h7", READONLY, &status); */
	fits_get_img_param(infptr1, 3, &bitpix, &naxis, naxes, &status );

	if ( verbose & 1 ) 
	  printf("line: %3d, %s ,weight = %7.1f \n",nline,name,gsl_vector_get(weight,nline-1));


	/*  open mask image  */
	strcpy(name2,strcat(name,suffix));
	if ( strcmp(name2,"" ) ) {
	  printf("%s\n",name2);
	  fits_open_file(&infptr2, name2, READONLY, &status);
	  fits_get_num_hdus(infptr2, &hdunum, &status);
	  if ( hdunum > 1)
	    fits_movrel_hdu(infptr2, 1, NULL, &status);  /* try to move to next HDU */
	}


	/* INITIALIZE ARRAYS */
	if ( nline == 1 ){
	  size = naxes[0] * naxes[1];
	  if ( verbose )
	    printf("SIZE = %d\n", size);

	  pix = (double *) malloc(ntot * size * sizeof(double)); /* memory for 2d image */
	  fit = (double *) malloc(ntot * size * sizeof(double)); /* memory for output 2d image */
	  tpix = (double *) malloc(size * sizeof(double)); /* memory for 2d image */
	  /* CALLOC INITS TO ZERO */
	  bpix = (double *) malloc(ntot * size * sizeof(double)); /* memory for 2d mask */
	  /* bpix = (int *) calloc(ntot * size , sizeof(int)); /\* memory for 2d mask *\/ */
	  tbpix = (int *) calloc(size , sizeof(int)); /* memory for 2d mask */
	  if (pix == NULL || fit == NULL || tpix == NULL || bpix == NULL || tbpix == NULL  ) {
	    printf("Memory allocation error\n");
	    return(1);
	  }
	  /* create output file if necessary */
	  if ( strcmp(outname,"" ) ) {
	    if ( fits_create_file(&outfptr1, outname, &status) ) {
	      printerror( status );
	    }
	    fits_copy_file(infptr1, outfptr1, 1, 1, 1, &status);
	  }
	  
	  if ( strcmp(outname2,"")) {
	    fits_create_file(&outfptr2, outname2, &status);
	    if ( strcmp(name2,"")) {
	      fits_copy_file(infptr2, outfptr2, 1, 1, 1, &status);
	    } else {
	      fits_create_img(outfptr2, 8, 0, NULL, &status);
	    }
	  }
	  nsmooth = ysmooth * xsmooth / (stride * stride) ;
	  xgrid = ceil((double)naxes[0]/(double)xsmooth);
	  ygrid = ceil((double)naxes[1]/(double)ysmooth);
	  printf("number of sub-blocks: %d, %d   npix per block: %d\n",xgrid,ygrid, nsmooth);
	  cell = gsl_vector_alloc (nsmooth);
	  backmat = gsl_matrix_alloc (xgrid,ygrid);
	  sigmat = gsl_matrix_alloc (xgrid,ygrid);
	  area = xgrid*ygrid;
	}

	/* read image into memory */
	fpixel[0] = fpixel[1] = fpixel[2] = 1;
	fits_read_pix(infptr1, TDOUBLE, fpixel, size, 0, tpix, 0, &status);
	fits_read_pix(infptr2, TINT, fpixel, size, 0, tbpix, 0, &status);

/* ####################################################################### */
/* do initial masking of image, divide into blocks and determine whether or not to mask the entire block.  */
	barea = 0;
	tave = 0;
	gsl_matrix_set_zero(backmat); 
	gsl_matrix_set_zero(sigmat); 
	/* loop over column blocks */
	for (jj = 0; jj < ygrid; jj++) {
	  /* loop over row blocks */
	  for (ii = 0; ii < xgrid; ii++) {
	    /* average pixels in this block */
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
		/* find average background in this block, ignore bad pixels */
		kk = _i+ii*xsmooth+naxes[0]*(_j+jj*ysmooth);
		if ( (tpix[kk] >= maxval || tpix[kk] <= minval) || tbpix[kk] > 0 ) {
		  tbpix[kk] = (tbpix[kk] == 0) ? 32 : tbpix[kk] ;
		  gsl_vector_set(cell,_i/stride+xsmooth*_j/stride/stride,1.e33);
		} else {
		  gsl_vector_set(cell,_i/stride+xsmooth*_j/stride/stride,tpix[kk]);
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
		if ( tbpix[kk] & 32 || ( (tpix[kk] > ave+(hisig)*sigma || tpix[kk] < ave-(losig)*sigma) && tbpix[kk] == 0 ) ) {
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
		tpix[kk] = ( tbpix[kk] & BADBITS ) ? ave+rand : tpix[kk];		
	      }
	    }
	    density = (double)nkeys / (double)(nsmooth);
	    gsl_matrix_set(backmat,ii,jj,ave);
	    gsl_matrix_set(sigmat, ii, jj, (xnum <10 ? 0 : 1.0) );
	    tave = (tave*( ((ii+1)*(jj+1))-1 )+ave)/((ii+1)*(jj+1));
	    if ( verbose & 2 )
	      printf("%04d %04d (%04d %04d)   %5.3f    %7.3f %5.3f \n",ii,jj,xgrid,ygrid,density,ave,sigma);

	  }
	}
	gsl_vector_set(scale, nline-1, tave);
/* fix the left edge of chip 4 */
	fits_read_key(infptr1, TINT, "CHIP", &chip, NULL, &status);
	if ( chip == 4 && 0 ) {
	  if ( 1 )
	    printf("Fixing left edge of Chip 4\n");
	  for (jj = 0; jj < ceil((double)naxes[1]/(double)ysmooth); jj++) {
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


/* FIT LOW ORDER SURFACE TO IMAGE */
	if ( xsurf != 0 && ysurf != 0 ) {
	
	  if ( 1-barea/area < 0.5  ){
	    if ( 1 ) {
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
		}
	      }
	    }
	  }

/*  NOW I HAVE A LOW ORDER MAP OF THE IMAGE    */
	  if ( csurf < 0 ) {
	    printf("Fitting Mesh-Surface: xsurf = %d, ysurf= %d, csurf= %d, %5d %5d : %3d %3d \n",nxsurf, nysurf, ncsurf, xsmooth, ysmooth, xgrid, ygrid);
	    /* IMAGE IS IN BLOCKS grid = xgrid * ygrid...NEED TO SMOOTH IT.  BILINEAR */
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
		for (i=0;i<xsmooth;i++) {
		  for (j=0;j<ysmooth;j++) {
		    /* COMPUTE WEIGHTS FOR EACH PIXEL */
		    gsl_matrix_set (sigmat2, 0, 0,  (1.- (double)i/xsmooth )*(1.- (double)j/ysmooth ) );
		    gsl_matrix_set (sigmat2, 0, 1,  (1.- (double)i/xsmooth )*( (double)j/ysmooth ) );
		    gsl_matrix_set (sigmat2, 1, 0,  ( (double)i/xsmooth )*(1.- (double)j/ysmooth ) );
		    gsl_matrix_set (sigmat2, 1, 1,  ( (double)i/xsmooth )*( (double)j/ysmooth ) );
		    /* FIND WEIGHTED AVERAGE PIXEL VALUE */
		    kk = i+ii*xsmooth+naxes[0]*(j+jj*ysmooth)+(nline-1)*size;
		    fit[kk] = gsl_stats_wmean (sigmat2->data, 1, backmat2->data, 1, backmat2->size1 * backmat2->size2 );
		    pix[kk] = tpix[i+ii*xsmooth+naxes[0]*(j+jj*ysmooth)] - fit[kk];
		    bpix[kk] = ( tbpix[i+ii*xsmooth+naxes[0]*(j+jj*ysmooth)] & BADBITS ) ? 0 : gsl_vector_get(weight,nline-1);

		  }
		}
	      }
	    }
	  }
	  gsl_multifit_linear_free (work);
	  gsl_matrix_free (X); 
	  gsl_vector_free (w); 
	  gsl_vector_free (y); 
	  gsl_vector_free (c); 
	  gsl_vector_free (x); 
	  gsl_matrix_free (cov);
	}

	/* close open files */
	fits_close_file(infptr1, &status);
	if (strcmp(name2,"")) {
	  fits_close_file(infptr2, &status);
	}
      }
      fclose(input);

      gsl_matrix_free (backmat); 
      gsl_matrix_free (sigmat); 
      gsl_vector_free (cell); 
      gsl_matrix_free (backmat2);
      gsl_matrix_free (sigmat2);

      printf("Averaging Frames together... %d   %d  minrej = %f maxrej = %f MASKBITS = %d\n", size, ntot*size,minrej,maxrej, BADBITS);
      printf("BACKGND  SCALE\n");
      for(nline=0;nline<ntot;nline++){
	printf("%6.3f  %6.3f\n",gsl_vector_get(scale,nline),(gsl_vector_get(scale,0)/gsl_vector_get(scale,nline)) );
      }
      /* average input frames together */


/* with the low order sky subtracted the pixel to pixel variations can be averaged together with no weighting since the high-order variations (sample1) should be relatively invariant. Do a min/max reject to clip stars and other high frequency sources.  */

/* The low order sky fluctuations (sample2) should be weighted (weight) by time and distance from the reference sky.  Since this is a model, no clipping is necessary.  */

      for (i=0;i<size;i++) {
	nmaxrej=0;
	nminrej=0;
	for(nline=0;nline<ntot;nline++){
	  /* gsl_vector_set(sample2,nline,fit[i+size*nline]);  */
/* SCALE THE DATA TO THE FIRST IMAGE */
	  gsl_vector_set(sample2,nline,fit[i+size*nline]*(gsl_vector_get(scale,0)/gsl_vector_get(scale,nline))); 
	  /* gsl_vector_set(sample2,nline,fit[i+size*nline]+(scale[0]-scale[nline]));  */
	  /* gsl_vector_set(weight,nline,bpix[i+size*nline]); */
	  if (bpix[i+size*nline] == 0){
	    gsl_vector_set(sample1,nline,1.e16);
	    nmaxrej++;
	  } else {
	    gsl_vector_set(sample1,nline,pix[i+size*nline]);
	  }
	}
	if ( nmaxrej == ntot ){
	  nminrej = 0;
	} else {
	  if (minrej < 1){
	    nminrej = ceil(minrej*(ntot-nmaxrej));
	  } else {
	    nminrej = (int)minrej;
	  }
	  if (maxrej < 1){
	    nmaxrej = nmaxrej + floor(maxrej*(ntot-nmaxrej));
	  } else {
	    nmaxrej = nmaxrej + (int)maxrej;
	  }
	  while ( (ntot - (nminrej + nmaxrej)) < 0 ){
	    nminrej = gsl_max(0,nminrej-1);
	    nmaxrej--;
	  }

	}

	/* printf("%d %d %d\n",ntot,nminrej,nmaxrej); */

	gsl_sort(sample1->data,1,ntot);
/* BOTH */
	tpix[i] = gsl_stats_mean ( sample1->data+nminrej, 1, sample1->size-(nminrej+nmaxrej) ) \
	        + gsl_stats_wmean ( weight->data, 1 ,sample2->data, 1, sample2->size );
/* JUST HIGH FREQUENCY */
	/* tpix[i] = gsl_stats_mean ( sample1->data+nminrej, 1, sample1->size-(nminrej+nmaxrej) ) ; */
/* JUST LOW ORDER SKY */
	/* tpix[i] = gsl_stats_wmean ( weight->data, 1 ,sample2->data, 1, sample2->size ) ; */




	/* tpix[i] = fit[i+(8)*size]; */


	tbpix[i] = ntot-(nminrej+nmaxrej) ;
	/* tbpix[i] = bpix[i+size] == 0 ? 1 : 0; */
      }
      gsl_vector_free (weight); 
      gsl_vector_free (scale); 
      gsl_vector_free (sample1); 
      gsl_vector_free (sample2); 


      printf("Writing images...\n");

      /* write image */
      fpixel[0] = fpixel[1] = fpixel[2] = 1;
      switch(itype) {
      case 1:
	fits_write_pix(outfptr1, TDOUBLE, fpixel, size, tpix, &status);
	break;

      default:
	break;
      }

/* close open files */
      fits_close_file(outfptr1, &status);
      if (strcmp(outname2,"")) {
	printf("writing mask image\n");
	fits_write_pix(outfptr2, TINT, fpixel, size, tbpix, &status);
	fits_close_file(outfptr2, &status);
      }

/* free memory */
      gsl_rng_free (r);
      free(pix);
      free(tpix);
      free(fit);
      free(bpix);
      free(tbpix);

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
