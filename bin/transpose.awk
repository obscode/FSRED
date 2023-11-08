BEGIN { a[1,1]="NPIX";a[1,2]="MEAN";a[1,3]="MIDPT";a[1,4]="MODE";a[1,5]="STDDEV";a[1,6]="SKEW";a[1,7]="KURT";a[1,8]="MIN";a[1,9]="MAX" } { for(i=1;i<=NF;i++) { a[NR+1,i]=$i } } NF>p { p=NF }  END { for(j=1;j<=p;j++) { print a[1,j]"="a[2,j]  } }

