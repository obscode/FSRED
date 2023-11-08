/* File pvsip.c
 * Nov 15, 2012
 * By Andy Monson
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <fitsio.h>
#include <gsl/gsl_multifit.h>
/* #include <gsl/gsl_multifit.h> */
/* #include <gsl/gsl_errno.h>  */
/* #include <gsl/gsl_interp.h>  */
/* #include <gsl/gsl_spline.h>   */
/* #include <gsl/gsl_blas.h>  */

static void PrintUsage();
static char *RevMsg = "pvsip 0.0, 15 Nov 2012, Andy Monson (monson.andy@gmail.com)";
static int version_only = 0;		/* If 1, print only program name and version */


int main(int argc, char *argv[])
    {
      int verbose = 0;		/* verbose/debugging flag */
      char *str=NULL,*list=NULL,*image=NULL;
      char str1[80],str2[80];
      fitsfile *infptr1=NULL, *outfptr1=NULL;  /* pointer to the FITS files */
      long naxes[3] = {1024,1024,1};
      char card[FLEN_CARD]; 
      int status = 0;
      char line[256];
      FILE *input=NULL;

      int ii,jj,_i,_j,NCHIP=4,CHIP=0, pvorder=0, siporder=0;
      double CRVAL1=0, CRVAL2=0, CRPIX1=0, CRPIX2=0, CD11=0, CD12=0, CD21=0, CD22=0;
      double CRVAL1p=0, CRVAL2p=0, CD11p=0, CD12p=0, CD21p=0, CD22p=0;
      double CD11pi=0, CD12pi=0, CD21pi=0, CD22pi=0, deter;
      double PV1[40],PV2[40];
      double k[6][6],l[6][6];
      double A[5][5], B[5][5];
      //           1  x  y  r x2 xy y2 x3 x2y xy2 y3 r3 x4 x3y x2y2 xy3 y4
      //          x5 x4y x3y2 x2y3 xy4 y5 r5 x6 x5y x4y2, x3y3 x2y4 xy5 y6
      //          x7 x6y x5y2 x4y3 x3y4 x2y5 xy6 y7 r7
      int xe[] = { 0, 1, 0, 0, 2, 1, 0, 3,  2,  1, 0, 0, 4,  3,   2,  1, 0,
		   5,  4,   3,   2,  1, 5, 0, 6,  5,   4,    3,   2,  1, 0,
		   7,  6,   5,   4,   3,   2,  1, 0, 0};
      int ye[] = { 0, 0, 1, 0, 0, 1, 2, 0,  1,  2, 3, 0, 0,  1,   2,  3, 4,
		   0,  1,   2,   3,  4, 0, 0, 0,  1,   2,    3,   4,  5, 6,
		   0,  1,   2,   3,   4,   5,  6, 7, 0};
      int re[] = { 0, 0, 0, 1, 0, 0, 0, 0,  0,  0, 0, 3, 0,  0,   0,  0, 0,
		   0,  0,   0,   0,  0, 0, 5, 0,  0,   0,    0,   0,  0, 0,
		   0,  0,   0,   0,   0,   0,  0, 0, 7};

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
	
      case 'f':       /* input file */
	if (argc < 2)
	  PrintUsage (str);
	list = *(argv+1);
	argc--;
	argv++;
	break;

      case 'i':       /* input image */
	if (argc < 2)
	  PrintUsage (str);
	image = *(argv+1);
	argc--;
	argv++;
	break;

      case 'v':	/* more verbosity */
	verbose = atoi(*(argv+1));
	break;

      default:
	/* printf("%s\n",*(argv+1)); */
	PrintUsage(str);
	break;
      }
  }


  if ( list != NULL ) {
    input = fopen(list,"r");
  }

  if ( image != NULL ) {
    fits_open_file(&infptr1, image, READONLY, &status);
  }

    read:
  siporder = pvorder = 0;
  if ( list != NULL ) {
    while (fgets(line,80,input) != NULL ){
      if(line[0]=='#') continue;
      if (sscanf(line,"%8s%*[= \']%s%*[/ \']{%*s}",str1,str2 ) >= 2 ) {
	if ( verbose & 1 )
	  printf("%s -> %s\n",str1,str2 );
      }
      if ( ! strcmp(str1,"CRVAL1")) {CRVAL1 = atof(str2); continue;}
      if ( ! strcmp(str1,"CRVAL2")) {CRVAL2 = atof(str2); continue;}
      if ( ! strcmp(str1,"CRPIX1")) {CRPIX1 = atof(str2); continue;}
      if ( ! strcmp(str1,"CRPIX2")) {CRPIX2 = atof(str2); continue;}
      if ( ! strcmp(str1,"CD1_1")) {CD11 = atof(str2); continue;}
      if ( ! strcmp(str1,"CD1_2")) {CD12 = atof(str2); continue;}
      if ( ! strcmp(str1,"CD2_1")) {CD21 = atof(str2); continue;}
      if ( ! strcmp(str1,"CD2_2")) {CD22 = atof(str2); continue;}
      pvorder = atoi(str1+4) > pvorder ? atoi(str1+4) : pvorder;
      if ( strncmp(str1,"PV1_",4) == 0) {
	PV1[atoi(str1+4)] = atof(str2);
	continue;
      }
      if ( strncmp(str1,"PV2_",4) == 0) {
	PV2[atoi(str1+4)] = atof(str2);
	continue;
      }
      if ( strncmp(str1,"A_ORDER",7) == 0) {
	siporder = atoi(str2);
	continue;
      } else if ( strncmp(str1,"A_",2) == 0) {
	A[atoi(str1+2)][atoi(str1+4)] = atof(str2);
	continue;
      }
      if ( strncmp(str1,"B_ORDER",7) == 0) {
	siporder = atoi(str2);
	continue;
      } else if ( strncmp(str1,"B_",2) == 0) {
	B[atoi(str1+2)][atoi(str1+4)] = atof(str2);
	continue;
      }
      if( ! strncmp(line,"END",3) || ! strncmp(line,"|",1) ){ CHIP++ ;break; }
    }
  }

  if ( image != NULL ) {
    CHIP++;
    fits_read_key(infptr1, TDOUBLE, "CRVAL1", &CRVAL1, NULL, &status);
  }


  if ( pvorder > 0 && siporder == 0 ) {
    if ( verbose & 1 )
      printf ("Finding SIP coefficients\n");
/* COMPUTE NEW CRVAL and CD MATRIX WHICH CAN BE SHARED BY BOTH SIP AND PV TERMS*/
    CRVAL1p = CRVAL1 + PV2[0]/cos(CRVAL2*3.1415926535897/180);
    CRVAL2p = CRVAL2 + PV1[0];
    CD11p = CD11*PV2[1] + CD21*PV2[2];
    CD12p = CD12*PV2[1] + CD22*PV2[2];
    CD21p = CD11*PV1[2] + CD21*PV1[1];
    CD22p = CD12*PV1[2] + CD22*PV1[1];
/* ANALYTICALLY TRANSFORM PV TO SIP */
    if ( pvorder >=6 ) {
      siporder = 2;
      k[0][2] = pow(CD12,2)*(PV1[4]) + (CD12)*(CD22)*(PV1[5]) + pow(CD22,2)*(PV1[6]);
      l[0][2] = pow(CD12,2)*(PV2[6]) + (CD12)*(CD22)*(PV2[5]) + pow(CD22,2)*(PV2[4]);

      k[1][1] = 2*(CD11)*(CD12)*(PV1[4]) + (CD11)*(CD22)*(PV1[5]) + (CD12)*(CD21)*(PV1[5]) + 2*(CD21)*(CD22)*(PV1[6]);
      l[1][1] = 2*(CD11)*(CD12)*(PV2[6]) + (CD11)*(CD22)*(PV2[5]) + (CD12)*(CD21)*(PV2[5]) + 2*(CD21)*(CD22)*(PV2[4]);

      k[2][0] = pow(CD11,2)*(PV1[4]) + (CD11)*(CD21)*(PV1[5]) + pow(CD21,2)*(PV1[6]);
      l[2][0] = pow(CD11,2)*(PV2[6]) + (CD11)*(CD21)*(PV2[5]) + pow(CD21,2)*(PV2[4]);
    }
    if ( pvorder >= 10 ) {
      siporder = 3;
      k[0][3] = pow(CD12,3)*(PV1[7]) + pow(CD12,2)*(CD22)*(PV1[8]) + (CD12)*pow(CD22,2)*(PV1[9]) + pow(CD22,3)*(PV1[10]);
      l[0][3] = pow(CD12,3)*(PV2[10]) + pow(CD12,2)*(CD22)*(PV2[9]) + (CD12)*pow(CD22,2)*(PV2[8]) + pow(CD22,3)*(PV2[7]);

      k[1][2] = 3*(CD11)*pow(CD12,2)*(PV1[7]) + 2*(CD11)*(CD12)*(CD22)*(PV1[8]) + (CD11)*pow(CD22,2)*(PV1[9]) +\
	pow(CD12,2)*(CD21)*(PV1[8]) + 2*(CD12)*(CD21)*(CD22)*(PV1[9]) + 3*(CD21)*pow(CD22,2)*(PV1[10]);
      l[1][2] = 3*(CD11)*pow(CD12,2)*(PV2[10]) + 2*(CD11)*(CD12)*(CD22)*(PV2[9]) + (CD11)*pow(CD22,2)*(PV2[8]) +\
	pow(CD12,2)*(CD21)*(PV2[9]) + 2*(CD12)*(CD21)*(CD22)*(PV2[8]) + 3*(CD21)*pow(CD22,2)*(PV2[7]);

      k[2][1] = 3*pow(CD11,2)*(CD12)*(PV1[7]) + pow(CD11,2)*(CD22)*(PV1[8]) + 2*(CD11)*(CD12)*(CD21)*(PV1[8]) +\
	2*(CD11)*(CD21)*(CD22)*(PV1[9]) + (CD12)*pow(CD21,2)*(PV1[9]) + 3*pow(CD21,2)*(CD22)*(PV1[10]);
      l[2][1] = 3*pow(CD11,2)*(CD12)*(PV2[10]) + pow(CD11,2)*(CD22)*(PV2[9]) + 2*(CD11)*(CD12)*(CD21)*(PV2[9]) +\
	2*(CD11)*(CD21)*(CD22)*(PV2[8]) + (CD12)*pow(CD21,2)*(PV2[8]) + 3*pow(CD21,2)*(CD22)*(PV2[7]);

      k[3][0] = pow(CD11,3)*(PV1[7]) + pow(CD11,2)*(CD21)*(PV1[8]) + (CD11)*pow(CD21,2)*(PV1[9]) + pow(CD21,3)*(PV1[10]);
      l[3][0] = pow(CD11,3)*(PV2[10]) + pow(CD11,2)*(CD21)*(PV2[9]) + (CD11)*pow(CD21,2)*(PV2[8]) + pow(CD21,3)*(PV2[7]);
    }
    if ( pvorder >= 15 ) {
      siporder = 4;
      k[0][4] = pow(CD12,4)*(PV1[12]) + pow(CD12,3)*(CD22)*(PV1[13]) + pow(CD12,2)*pow(CD22,2)*(PV1[14]) +\
  	(CD12)*pow(CD22,3)*(PV1[15]) + pow(CD22,4)*(PV1[16]);
      l[0][4] = pow(CD12,4)*(PV2[16]) + pow(CD12,3)*(CD22)*(PV2[15]) + pow(CD12,2)*pow(CD22,2)*(PV2[14]) +\
	(CD12)*pow(CD22,3)*(PV2[13]) + pow(CD22,4)*(PV2[12]);

      k[1][3] = 4*(CD11)*pow(CD12,3)*(PV1[12]) + 3*(CD11)*pow(CD12,2)*(CD22)*(PV1[13]) + \
	2*(CD11)*(CD12)*pow(CD22,2)*(PV1[14]) + (CD11)*pow(CD22,3)*(PV1[15]) + pow(CD12,3)*(CD21)*(PV1[13]) + \
	2*pow(CD12,2)*(CD21)*(CD22)*(PV1[14]) + 3*(CD12)*(CD21)*pow(CD22,2)*(PV1[15]) + 4*(CD21)*pow(CD22,3)*(PV1[16]);
      l[1][3] = 4*(CD11)*pow(CD12,3)*(PV2[16]) + 3*(CD11)*pow(CD12,2)*(CD22)*(PV2[15]) + \
	2*(CD11)*(CD12)*pow(CD22,2)*(PV2[14]) + (CD11)*pow(CD22,3)*(PV2[13]) + pow(CD12,3)*(CD21)*(PV2[15]) + \
	2*pow(CD12,2)*(CD21)*(CD22)*(PV2[14]) + 3*(CD12)*(CD21)*pow(CD22,2)*(PV2[13]) + 4*(CD21)*pow(CD22,3)*(PV2[12]);

      k[2][2] = 6*pow(CD11,2)*pow(CD12,2)*(PV1[12]) + 3*pow(CD11,2)*(CD12)*(CD22)*(PV1[13]) + pow(CD11,2)*pow(CD22,2)*(PV1[14]) + \
	3*(CD11)*pow(CD12,2)*(CD21)*(PV1[13]) + 4*(CD11)*(CD12)*(CD21)*(CD22)*(PV1[14]) + 3*(CD11)*(CD21)*pow(CD22,2)*(PV1[15]) + \
	pow(CD12,2)*pow(CD21,2)*(PV1[14]) + 3*(CD12)*pow(CD21,2)*(CD22)*(PV1[15]) + 6*pow(CD21,2)*pow(CD22,2)*(PV1[16]);
      l[2][2] = 6*pow(CD11,2)*pow(CD12,2)*(PV2[16]) + 3*pow(CD11,2)*(CD12)*(CD22)*(PV2[15]) + pow(CD11,2)*pow(CD22,2)*(PV2[14]) + \
	3*(CD11)*pow(CD12,2)*(CD21)*(PV2[15]) + 4*(CD11)*(CD12)*(CD21)*(CD22)*(PV2[14]) + 3*(CD11)*(CD21)*pow(CD22,2)*(PV2[13]) + \
	pow(CD12,2)*pow(CD21,2)*(PV2[14]) + 3*(CD12)*pow(CD21,2)*(CD22)*(PV2[13]) + 6*pow(CD21,2)*pow(CD22,2)*(PV2[12]);

      k[3][1] = 4*pow(CD11,3)*(CD12)*(PV1[12]) + pow(CD11,3)*(CD22)*(PV1[13]) + 3*pow(CD11,2)*(CD12)*(CD21)*(PV1[13]) + \
	2*pow(CD11,2)*(CD21)*(CD22)*(PV1[14]) + 2*(CD11)*(CD12)*pow(CD21,2)*(PV1[14]) + 3*(CD11)*pow(CD21,2)*(CD22)*(PV1[15]) + \
	(CD12)*pow(CD21,3)*(PV1[15]) + 4*pow(CD21,3)*(CD22)*(PV1[16]);
      l[3][1] = 4*pow(CD11,3)*(CD12)*(PV2[16]) + pow(CD11,3)*(CD22)*(PV2[15]) + 3*pow(CD11,2)*(CD12)*(CD21)*(PV2[15]) + \
	2*pow(CD11,2)*(CD21)*(CD22)*(PV2[14]) + 2*(CD11)*(CD12)*pow(CD21,2)*(PV2[14]) + 3*(CD11)*pow(CD21,2)*(CD22)*(PV2[13]) + \
	(CD12)*pow(CD21,3)*(PV2[13]) + 4*pow(CD21,3)*(CD22)*(PV2[12]);

      k[4][0] = pow(CD11,4)*(PV1[12]) + pow(CD11,3)*(CD21)*(PV1[13]) + pow(CD11,2)*pow(CD21,2)*(PV1[14]) + \
	(CD11)*pow(CD21,3)*(PV1[15]) + pow(CD21,4)*(PV1[16]);
      l[4][0] = pow(CD11,4)*(PV2[16]) + pow(CD11,3)*(CD21)*(PV2[15]) + pow(CD11,2)*pow(CD21,2)*(PV2[14]) + \
	(CD11)*pow(CD21,3)*(PV2[13]) + pow(CD22,4)*(PV2[12]);
    }
/* FIND SIP COEFFICIENTS */
/* # MATRIX INVERSION OF 2x2 MATRIX                             */
/* #                -1       1                    1             */
/* #  A^-1 = | a b |    =  -----  | d -b | =   ------- | d -b | */
/* #         | c d |       det(A) | -c a |      ad-bc  | -c a | */
/* #                                                            */
    deter = CD11p*CD22p - CD12p*CD21p;
    CD11pi = CD22p/deter;
    CD12pi = -CD12p/deter;
    CD21pi = -CD21p/deter;
    CD22pi = CD11p/deter;
    for ( ii=0;ii<=siporder;ii++) {
      for ( jj=0;jj<=siporder;jj++) {
	if ( ii+jj > siporder || ii+jj <= 1 ) continue;
	A[ii][jj] = CD11pi*k[ii][jj] + CD12pi*l[ii][jj];
	B[ii][jj] = CD21pi*k[ii][jj] + CD22pi*l[ii][jj];
      }
    }

  } else {
    CRVAL1p = CRVAL1;
    CRVAL2p = CRVAL2;
    CD11p = CD11;
    CD12p = CD12;
    CD21p = CD21;
    CD22p = CD22;
    pvorder = siporder <= 2 ? 6 : ( siporder == 3 ? 10 : (siporder == 4 ? 16 : 16 ) ); 
  }

/* WITH SIP COEFFICIENTS IN HAND, RE-DETERMINE THE HIGHER ORDER PV TERMS */
  int grid = 20;
  int alt = -1;
  double u[grid*grid];
  double v[grid*grid];
  double x[grid*grid];
  double y[grid*grid];
  double up[grid*grid];
  double vp[grid*grid];
  double xp[grid*grid];
  double yp[grid*grid];
  double xf[grid*grid];
  double yf[grid*grid];
  gsl_multifit_linear_workspace *work =	gsl_multifit_linear_alloc (grid*grid, pvorder+1 ); 
  gsl_matrix *X1 = gsl_matrix_alloc (grid*grid, pvorder+1 ); 
  gsl_matrix *X2 = gsl_matrix_alloc (grid*grid, pvorder+1 ); 
  gsl_vector *dxp = gsl_vector_alloc (grid*grid);
  gsl_vector *dyp = gsl_vector_alloc (grid*grid);
  gsl_vector *c1 = gsl_vector_alloc (pvorder+1);
  gsl_vector *c2 = gsl_vector_alloc (pvorder+1);
  gsl_matrix *cov = gsl_matrix_alloc (pvorder+1, pvorder+1);
  double chisq;

  for ( _i=0;_i<grid;_i++){
    for ( _j=0;_j<grid;_j++){
      u[_i+grid*_j] = CRPIX1+_i*(pow(alt,_i))*naxes[0]/grid;
      v[_i+grid*_j] = CRPIX2+_j*(pow(alt,_j))*naxes[1]/grid;
      x[_i+grid*_j] = CD11p*(u[_i+grid*_j]) + CD12p*(v[_i+grid*_j]);
      y[_i+grid*_j] = CD21p*(u[_i+grid*_j]) + CD22p*(v[_i+grid*_j]);
      up[_i+grid*_j] = u[_i+grid*_j];
      vp[_i+grid*_j] = v[_i+grid*_j];
      for ( ii=0;ii<=siporder;ii++) {
	for ( jj=0;jj<=siporder;jj++) {
	  if ( ii+jj > siporder || ii+jj <= 1 ) continue;
	  up[_i+grid*_j] = up[_i+grid*_j] + A[ii][jj]*pow(u[_i+grid*_j],ii)*pow(v[_i+grid*_j],jj) ;
	  vp[_i+grid*_j] = vp[_i+grid*_j] + B[ii][jj]*pow(u[_i+grid*_j],ii)*pow(v[_i+grid*_j],jj) ;
	}
      }
      xp[_i+grid*_j] = CD11p*up[_i+grid*_j] + CD12p*vp[_i+grid*_j];
      yp[_i+grid*_j] = CD21p*up[_i+grid*_j] + CD22p*vp[_i+grid*_j];
/* SUBTRACT LINEAR TERM FROM KNOWN's MATRIX */
      gsl_vector_set(dxp,_i+grid*_j,xp[_i+grid*_j]-x[_i+grid*_j]);
      gsl_vector_set(dyp,_i+grid*_j,yp[_i+grid*_j]-y[_i+grid*_j]);
/*       SET LINEAR TERM, RADIAL TERMS TO ZERO */
      for ( ii=0;ii<= pvorder;ii++){
	jj = (ii<=3 || ii==11 || ii ==23 || ii==39 ) ? 0 : 1 ;
	gsl_matrix_set(X1, _i+grid*_j, ii, jj * pow(x[_i+grid*_j],xe[ii]) * pow(y[_i+grid*_j],ye[ii]) );
	gsl_matrix_set(X2, _i+grid*_j, ii, jj * pow(y[_i+grid*_j],xe[ii]) * pow(x[_i+grid*_j],ye[ii]) );
      }

    }
  }

  gsl_multifit_linear (X1, dxp, c1, cov, &chisq, work);
  gsl_multifit_linear (X2, dyp, c2, cov, &chisq, work);

  for ( _i=0;_i<grid;_i++){
    for ( _j=0;_j<grid;_j++){
/*       START BY INITILIZING TO LINEAR TERM */
      xf[_i+grid*_j] = x[_i+grid*_j];
      yf[_i+grid*_j] = y[_i+grid*_j];
      for ( ii=0;ii<= pvorder;ii++){
	jj = (ii<=3 || ii==11 || ii ==23 || ii==39 ) ? 0 : 1 ;
	xf[_i+grid*_j] = xf[_i+grid*_j] + jj * gsl_vector_get(c1,ii) * pow(x[_i+grid*_j],xe[ii]) * pow(y[_i+grid*_j],ye[ii]) ;
	yf[_i+grid*_j] = yf[_i+grid*_j] + jj * gsl_vector_get(c2,ii) * pow(y[_i+grid*_j],xe[ii]) * pow(x[_i+grid*_j],ye[ii]) ;
      }
      if ( verbose & 4 )
	printf("%8.2f  %8.2f  %8.5f  %8.5f      %8.2f  %8.2f  %8.5f  %8.5f      %8.5f  %8.5f  \n",\
	       u[_i+grid*_j],v[_i+grid*_j], x[_i+grid*_j],y[_i+grid*_j],\
	       up[_i+grid*_j],vp[_i+grid*_j],xp[_i+grid*_j],yp[_i+grid*_j], \
	       xf[_i+grid*_j],yf[_i+grid*_j])  ;
    }
  }
  gsl_vector_free (dxp);
  gsl_vector_free (dyp);
  gsl_vector_free (c1);
  gsl_vector_free (c2);
  gsl_matrix_free (cov);
  gsl_matrix_free (X1);
  gsl_matrix_free (X2);
  gsl_multifit_linear_free (work);

  if ( verbose & 2 ){
    printf ("%-8s=%20d\n","CHIP",CHIP);
    printf ("%-8s=%20f\n","CRPIX1",CRPIX1);
    printf ("%-8s=%20f\n","CRPIX2",CRPIX2);
    printf ("%-8s=%20f\n","CRVAL1",CRVAL1p);
    printf ("%-8s=%20f\n","CRVAL2",CRVAL2p);
    printf ("%-8s=%20g\n","CD1_1",CD11p);
    printf ("%-8s=%20g\n","CD1_2",CD12p);
    printf ("%-8s=%20g\n","CD2_1",CD21p);
    printf ("%-8s=%20g\n","CD2_2",CD22p);
    if ( CD11pi != 0 ) {  /* ONLY PRINT ORIGINAL PV TERMS IF SIP TERMS DID NOT EXIST IN HEADER */
      for (ii=0;ii<=pvorder;ii++) {
	printf ("%-5s%-3d=%20g\n","OPV1_",ii,PV1[ii]);
      }
      for (ii=0;ii<=pvorder;ii++) {
	printf ("%-5s%-3d=%20g\n","OPV2_",ii,PV2[ii]);
      }
    }
    printf ("A_ORDER =%20d\n",siporder);
    for ( ii=0;ii<=siporder;ii++) {
      for ( jj=0;jj<=siporder;jj++) {
	if ( ii+jj > siporder || ii+jj <= 1 ) continue;
	printf ("A_%d_%d   =%20g\n",ii,jj,A[ii][jj]);
      }
    }
    printf ("B_ORDER =%20d\n",siporder);
    for ( ii=0;ii<=siporder;ii++) {
      for ( jj=0;jj<=siporder;jj++) {
	if ( ii+jj > siporder || ii+jj <= 1 ) continue;	  
	printf ("B_%d_%d   =%20g\n",ii,jj,B[ii][jj]);
      }
    }

/* SET PV LINEAR TERMS  */
    for ( ii=0;ii<= pvorder;ii++){
      PV1[ii] = gsl_vector_get(c1,ii);
    }
    for ( ii=0;ii<= pvorder;ii++){
      PV2[ii] = gsl_vector_get(c2,ii);
    }
/* EXPLICITLY SET PV RADIAL TERMS */
    PV1[0] = PV1[2] = PV2[0] = PV2[2] = 0;
    PV1[1] = PV2[1] = 1;
    PV1[3] = PV1[11] = PV2[3] = PV2[11] = 0;
    for ( ii=0;ii<= pvorder;ii++){
      printf("PV1_%-2d  =%20g\n",ii,PV1[ii]);
    }
    for ( ii=0;ii<= pvorder;ii++){
      printf("PV2_%-2d  =%20g\n",ii,PV2[ii]);
    }

    printf ("%-8s\n","END");
  }

  if ( fgets(line,80,input) != NULL  && CHIP< NCHIP  ){
    goto read;
  } else if ( input != NULL ) {
    fclose(input);
  }

  if ( image != NULL && CHIP< NCHIP  ){
    goto read;
  } else if ( image != NULL ) {
    fits_close_file(infptr1, &status);
  }

  exit(0);
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
