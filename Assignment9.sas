libname mydata 	'/courses/u_northwestern.edu1/i_888005/c_7415/SAS_Data/' access=readonly;

TITLE "Cigarette Consumption Data and Segmented Regression Modeling";
TITLE2 "Data Coming from the mydata Library"; 
ODS GRAPHICS ON; * to get scatterplots with high-resolution graphics out of SAS procedures;

DATA cigarette;
SET mydata.cigarette_consumption;
RUN;

PROC CONTENTS DATA = cigarette;
RUN;

* print observations checking values of all variables;
 
PROC PRINT DATA = cigarette;
VAR State Age HS Income Black Female Price Sales;
RUN;
 

/* 
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
Baseline regression model
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
*/

TITLE2 "Baseline Regression Model"; 

/* Use SAS macro to name the set of explanatory variables */
%let EXPLANATORY_VARIABLES =
Age HS Income Black Female Price
;

PROC REG DATA = cigarette;
MODEL sales = &EXPLANATORY_VARIABLES/ VIF;
RUN;

*Run correlation matrix for the total sample;
PROC CORR DATA = cigarette;
VAR &EXPLANATORY_VARIABLES;
RUN;  


/* 
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
Principal components prior to cluster analysis
This is used just to provide clean input to cluster
analysis programs to follow. The principal component 
scores are standardized and uncorrelated... perfect
for cluster input.  
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
*/


TITLE2 "Principal Components Analysis"; 
 /*  Use PROC FACTOR before cluster to accomplish standardization */
 PROC FACTOR DATA = cigarette
 MAXITER = 100
 METHOD = PRINCIPAL 
 NFACTORS = 6
 SCORE 
 OUTSTAT = PCSCORING
 ;
 VAR &EXPLANATORY_VARIABLES;
 RUN;

* show contents of the full data set;
PROC CONTENTS DATA = PCSCORING;
RUN;

/* need to use this procedure to get principal component scores */
PROC SCORE DATA = cigarette SCORE = PCSCORING OUT = PCSCORES;
RUN;

* show contents of the full data set;
PROC CONTENTS DATA = PCSCORES;
RUN;


/* print observations checking values of all variables */
 
PROC PRINT DATA = PCSCORES;
RUN;
 

/* Use SAS macro to name the set of principal component scores */
%let PC_SCORES =
Factor1
Factor2
Factor3
Factor4
Factor5
Factor6
;

/* Demonstrate that principal component scores are indeed standardized */
PROC CORR DATA = PCSCORES;
VAR &PC_SCORES;
RUN;

PROC UNIVARIATE DATA = PCSCORES NOPRINT;
HISTOGRAM &EXPLANATORY_VARIABLES &PC_SCORES/KERNEL(C = 0.50 L =1 NOPRINT);
RUN;

/* Late additional code to demonstrate the utility of principal components.
   Principal components regression provides a model with the same
   predictive power of the baseline model but with uncorrelated
   explanatory variables. Through this analysis, we demonstrate one
   solution to the collinearity problem.
   
   Principal components methods were introduced by statistican and
   mathematical economist Harold Hotelling:
   
   Hotelling, H. (1933) Analysis of a complex of statistical variables 
   into principal components. Journal of Educucational Psychology, 24 
   (6,7), 417-441 and 498-520.
   
*/

TITLE2 "Principal Components Regression Model"; 
PROC REG DATA = PCSCORES;
MODEL sales = &PC_SCORES/ VIF;
RUN;


/* 
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
Hierarchical cluster analysis is sometimes used prior 
to non-hierarchical cluster analysis to get an idea about
the number of clusters to use. It can also serve as an
end-result itself, defining the clusters what we will use.
Note that there are many alternatives for clustering
Here we use AVERAGE. We could have used CENTRIOD or WARD.
The cubic clustering criterion (CCC) and dendrogram provide
guidance regarding the number of clusters to use.
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
*/

TITLE2 "Hierarchical Cluster Analysis Using Average Linkage";

PROC CLUSTER DATA=PCSCORES
	METHOD=AVERAGE SIMPLE CCC PSEUDO
	OUTTREE=OUTCLUS
	PLOTS=CCC  
	;
	VAR &PC_SCORES;
	COPY &EXPLANATORY_VARIABLES Sales;
	ID state;
RUN;

* show contents of the full data set;
PROC CONTENTS DATA = OUTCLUS;
RUN;

* plot the dendrogram;
PROC TREE DATA = OUTCLUS NCLUSTERS = 2 OUT = HCLUSTER;
COPY &EXPLANATORY_VARIABLES Sales;
ID state;
RUN;

/* Note that this cluster solution is not particularly interesting 
   It has DC in one cluster and the 50 states in another cluster
*/

PROC CONTENTS DATA = HCLUSTER;
RUN;

/* print observations checking values of all variables */
 
PROC PRINT DATA = HCLUSTER;
RUN;
 

/* Note that we are not actually using the HCLUSTER output do to any 
   additional analyses in this demonstration. If we wanted to use the
   resulting clusters, we could---in much the same way as we
   use the results from the K-means solution to follow.
   We are just showing what is possible with hierarchical clustering and
   getting an idea of how many clusters might make sense.
   Much more needs to be done here before we would be satisfied
   with the resulting clusters.... Try other methods and see how they work.
*/   


/* 
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
Non-hierarchical cluster analysis.... see what it yields.
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
*/

TITLE2 "Cluster Analysis K-Means Clustering";

PROC FASTCLUS DATA = PCSCORES OUT=FASTOUT MAXCLUSTERS = 2 NOPRINT;
VAR &PC_SCORES;
RUN;

PROC CONTENTS DATA = FASTOUT;
RUN;

/* print observations checking values of all variables */
  
PROC PRINT DATA = FASTOUT;
RUN;
 

* sort so that we can get results by cluster in other procedures;
PROC SORT DATA = FASTOUT OUT = SORTOUT; BY CLUSTER;
RUN;

* use means to compare cluster profiles;
PROC MEANS DATA = SORTOUT;
VAR &EXPLANATORY_VARIABLES; BY CLUSTER;
RUN;

*Run correlation matrix for the separate clusters;
PROC CORR DATA=SORTOUT;
VAR &EXPLANATORY_VARIABLES;
BY cluster;
RUN;  

* define cluster datasets for use in segmented regression;
DATA CLUSTER1;
SET SORTOUT;
IF CLUSTER = 2 THEN DELETE;
RUN;

DATA CLUSTER2;
SET SORTOUT;
IF CLUSTER = 1 THEN DELETE;
RUN;


TITLE2 "Segmented Regression Modeling: CLUSTER 1"; 
PROC REG DATA = CLUSTER1;
MODEL sales = &EXPLANATORY_VARIABLES;
RUN;


TITLE2 "Segmented Regression Modeling: CLUSTER 2"; 
PROC REG DATA = CLUSTER2;
MODEL sales = &EXPLANATORY_VARIABLES;
RUN;
 
/* the bottom line will be how these segmented regression results
   compare with the baseline regression at the beginning
*/   

QUIT;
