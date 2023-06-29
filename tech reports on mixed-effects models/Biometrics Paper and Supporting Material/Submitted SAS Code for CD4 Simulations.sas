
/*======================================================*/
/* SAS code used in the simulations in Section 3 of     */
/* the Biometrics paper.                                */
/* AUTHOR:  Edward F. Vonesh (EFV)                      */
/* EMAIL:   edward@vonesh-stats.com (preferred email)   */
/*          or e-vonesh@nothwestern.edu                 */
/*======================================================*/
/* Analysis of simulated MAR, MNAR and MAR+MNAR data    */
/* patterned after the CD4 simulations by Thomadakis    */
/* et al (Biometrics, 75:58-68, 2019). However we use   */
/* ML estimation via NLMIXED rather than the full       */
/* Bayesian formulation used by Thomadakis et al.       */
/* We model event times using a piecewise exponential   */
/* model with four 15 month (1.25 year) intervals.      */
/* NOTES: 1. It is suggested that you run through each  */
/*           macro one time using only 5 reps of the    */
/*           500 datasets created in R under each of    */ 
/*           the missing data mechanisms(MAR, MNAR and  */ 
/*           MAR+MNAR) where datasets BOTH, BOTH1 and   */ 
/*           BOTH2 represent the all-cause competing    */ 
/*           dropout mechanisms T^MIN outlined in the   */ 
/*           Biometrics paper. The MIX, MIX1 and MIX2   */ 
/*           are the 3 corresponding datasets one needs */ 
/*           to evaluate the competing risk SP models.  */ 
/*        2. A single call to one of the SP Model macros*/
/*           will take a long time to complete since it */
/*           involves 500 datasets with 1000 subjects   */ 
/*           each with all but SP Model 1 requiring the */ 
/*           use of 10 quadrature points to achieve an  */ 
/*           adequate approximation to the integrated   */ 
/*           log-likelihood function.                   */
/*======================================================*/

/*=============================================================
  Define a global macro variable that specifies the location  
  of your primary working directory for storing information.
==============================================================*/
 %global lib;
*%let lib=%str(d:\edward);   * EFV  primary working directory *; 
 %let lib=%str(c:\username); * User primary working directory *;

/*=============================================================
  NOTE: MACROS %Convert_R_data and %Summary_simul use libname
        BIOM as defined by the following libname statement to
        store SAS datasets converted from R datasets and to
        store SAS generated datasets with results from each 
        call to macro %SP_Model.
==============================================================*/
*libname BIOM "&lib\RM\Missing Data\Biometrics Reader Reaction\CD4\Missing Data Simulations for CD4\PE 15"; ** EFV libname;
 libname BIOM "&lib\User subdirectory file containing all relevant SAS datasets and results";               ** User libname;
run;

options symbolgen mprint pagesize=60 linesize=120;
run;

/*================================================================================================= 
                     MACRO Convert_R_Data (converts R datasets to SAS datasets)

 Key: Data    -defines the name of the SAS created dataset from the R created dataset            
      Missing -defines missing data mechansism scenarios (MAR, MNAR, BOTH, BOTH1, BOTH2) where
                 MAR is missing at random with h(t) = exp(3.956-0.221*yij) (yields 88% MAR dropout) 
                 MNAR is missing not at random with h(t) = exp(-1.856 - 0.105*b0i - 2.231*b1i)
                 BOTH  is MAR+MNAR with MAR hazard h1(t) = exp(3.956-0.221*yij) (yields 53% MAR)
                 BOTH1 is MAR+MNAR with MAR hazard h1(t) = exp(3.956-0.321*yij) (yields 21% MAR)
                 BOTH2 is MAR+MNAR with MAR hazard h1(t) = exp(3.956-0.421*yij) (yields  7% MAR) 
               and BOTH, BOTH1, BOTH2 have hazard h(t) as defined for MNAR
      Reps    -defines the number of simulated datasets for a given missing data scenario 
 NOTES: 1) The R-generated datasets are stored in the datafiles defined by the PROC IMPORT 
           statement shown within the macro. The R code in master.R identifies the R working 
           directory as being W = "d:/edward/RM/Missing Data/Biometrics Reader Reaction/CD4"
           which the user will have to re-define for his/her own purpose.
        2) The SAS generated dataset is stored in BIOM.&data as shown in code below.
=================================================================================================*/ 
%macro Convert_R_Data(Data=CD4_MAR, Missing=MAR, Reps=1);
 	filename bootlog "&lib\MiscSAS.log";
 	proc printto log=bootlog;
 	run;
	data &data;set _null_;run;
	%do j=1 %to &reps;
	proc import datafile="&lib\RM\Missing Data\Biometrics Reader Reaction\CD4\Data\&Missing._scenarios\Exponential\data.obs&j..csv"
	        out=&data.&j
	        dbms=csv
	        replace;
	run;
	data &data;
	 set &data &data.&j;
	run;
	%end;
 	proc printto;
	run;
	data &data;
	 set &data;
	 if study=. then delete;
	run;
	data &data;
	 set &data;
	 sample=study;
	 Dropout=event;
	 drop event study;
	run;
	data BIOM.&data;
	 set &data;
	 length MissingData $4;
	 MissingData="&Missing";
	 Study=sample;
	 Subject=ID;
	 CD4_Obs=round(sq_cd4,0.0001); ** observed CD4 rounded to 4 decimal place (original analysis);
	 x=obstime;                    ** time of CD4 measurements in years;
	 T=time;                       ** time to dropout in years;
	 Event=0;
	 t1i = x;      
	 t2i = min(t1i+.25, T);
	 /* Define 15 month = 1.25 year Piecewise Exponential Intervals  */ 
	 if 0.00<=x<1.25 then t1=0;
	 if 1.25<=x<2.50 then t1=1.25;
	 if 2.50<=x<3.75 then t1=2.50;
	 if 3.75<=x<5.00 then t1=3.75;
	 t2=t1+1.25;
	 if t2i=T then Event=Dropout;  
	 risktime=t2i-t1i;
	 log_risktime=log(risktime);
	run;
	data BIOM.&data;
	 set BIOM.&data;
	 /*===========================================================*/  
	 /* Define the interval indicators for the PE survival model  */
	 /* with the initial interval being the baseline parameter    */
	 /* eta0 = 3.956 as per Thomadakis et al (Biometrics, 2019)   */
	 /* for the MAR dropout mechanism and eta0 = 1.856 for the    */
	 /* MNAR dropout mechanism under a Exponential model.         */
	 /*===========================================================*/  
	 /* Define 15 month=1.25 year PE interval indicator variables */
	 /*===========================================================*/  
	 Int1=(t1=1.25); Int2=(t1=2.50); Int3=(t1=3.75);  
	run;
%mend Convert_R_Data;

/*------------------------------------------------------------------
  The following were run and stored in BIOM - see libname definition 
  at start of program. One need run this just one time after which 
  one should comment out these calls to macro Convert_R_Data 
------------------------------------------------------------------*/
 %Convert_R_Data(data=CD4_MAR_EXPON,   Missing=MAR,   Reps=500);
 %Convert_R_Data(data=CD4_MNAR_EXPON,  Missing=MNAR,  Reps=500);
 %Convert_R_Data(data=CD4_BOTH_EXPON,  Missing=BOTH0, Reps=500);
 %Convert_R_Data(data=CD4_BOTH1_EXPON, Missing=BOTH1, Reps=500);
 %Convert_R_Data(data=CD4_BOTH2_EXPON, Missing=BOTH2, Reps=500);
run;


/*------------------------------------
  Need run this macro just one time 
  after which one can comment it out.
------------------------------------*/
%macro Merge_CD4_Datasets;
	data BIOM.CD4_MAR_EXPON;
	 set BIOM.CD4_MAR_EXPON;
	 Missingness='MAR  ';
	 if T>5 then Cause='EOS '; ** End of Study **;
	        else Cause='MAR '; 
	run;
	data BIOM.CD4_MNAR_EXPON;
	 set BIOM.CD4_MNAR_EXPON;
	 Missingness='MNAR ';
	 if T>5 then Cause='EOS '; ** End of Study **;
	        else Cause='MNAR'; 
	run;
	data BIOM.CD4_BOTH_EXPON;
	 set BIOM.CD4_BOTH_EXPON;
	 Missingness='BOTH ';
	 if T>5 then Cause='EOS '; ** End of Study **;
	 else if Time_MAR<Time_NIM 
	        then Cause='MAR ';  
	 else if Time_NIM<Time_MAR 
	        then Cause='MNAR';  
	run;
	data BIOM.CD4_BOTH1_EXPON;
	 set BIOM.CD4_BOTH1_EXPON;
	 Missingness='BOTH1';
	 if T>5 then Cause='EOS '; ** End of Study **;
	 else if Time_MAR<Time_NIM 
	        then Cause='MAR ';  
	 else if Time_NIM<Time_MAR 
	        then Cause='MNAR';  
	run;
	data BIOM.CD4_BOTH2_EXPON;
	 set BIOM.CD4_BOTH2_EXPON;
	 Missingness='BOTH2';
	 if T>5 then Cause='EOS '; ** End of Study **;
	 else if Time_MAR<Time_NIM 
	        then Cause='MAR ';  
	 else if Time_NIM<Time_MAR 
	        then Cause='MNAR';  
	run;

	data BIOM.CD4_All;
	 set BIOM.CD4_MAR_EXPON BIOM.CD4_MNAR_EXPON 
         BIOM.CD4_BOTH_EXPON BIOM.CD4_BOTH1_EXPON BIOM.CD4_BOTH2_EXPON;
	 Ind_1 = 0;
	 Ind_2 = 0;
	 Ind_3 = 0;
	 if Cause='MAR'  then Ind_1 = 1; ** Corresponding to a non-terminal dropout event;
	 if Cause='MNAR' then Ind_2 = 1; ** Corresponding to a terminal dropout event; 
	 if Cause='EOS'  then Ind_3 = 1; ** Corresponding to End-of-Study reached (independent censoring event);
	run;
%mend;
 %Merge_CD4_Datasets;


proc sort data=BIOM.CD4_All;
 by Missingness Study Subject;  
run;

/*======================================
 Some miscellaneous PROC PRINTS to see
 what created datasets look like.
======================================*/
proc print data=BIOM.CD4_All(obs=100);
 where Missingness='MNAR ';
run;

proc print data=BIOM.CD4_All(obs=300);
 where study=1 and Missingness="MNAR";
 var Missingness Study Subject x CD4_Obs T Dropout t1i t2i t1 t2 Event risktime; 
run;

/*================================================================= 
  Summary of causes of dropout. Note that the MCAR cases
  are those subjects who completed the study (i.e.,EOS)
=================================================================*/ 
proc freq data=BIOM.CD4_All;
 where x=0;
 tables Missingness*Cause /nopercent nocol;
 title "Summary % dropout by causes of dropout (MCAR=Completed study)";
run;


/*====================================================================
                     MACRO Create_CD4_MIXALL
         This macro creates a SAS dataset BIOM.CD4_MIXALL 
 The following datasets are designated for a competing risk SP model 
 analysis based on assuming there is a non-terminal dropout event that
 corresponds to the MAR mechanism and a terminal dropout event that      
 corresponds to the MNAR mechanism.  

 As with other macros above, one need run this just one time after
 which one should comment the call to this macro out.
====================================================================*/
%macro Create_CD4_MIXALL;
	data CD4_MIX_EXP;
	 set BIOM.CD4_All;
	 if Missingness="BOTH";
	run;
	data CD4_MIX_EXP;
	 set CD4_MIX_EXP;
	 Missingness="MIX  ";
	 if Time_MAR<Time_NIM      then Mech='MAR ';  
	 else if Time_NIM<Time_MAR then Mech='MNAR';  
	 else if Time_NIM=Time_MAR then Mech='MCAR';  
	run;
	data CD4_MIX1_EXP;
	 set BIOM.CD4_All;
	 if Missingness="BOTH1";
	run;
	data CD4_MIX1_EXP;
	 set CD4_MIX1_EXP;
	 Missingness="MIX1 ";
	 if Time_MAR<Time_NIM      then Mech='MAR ';  
	 else if Time_NIM<Time_MAR then Mech='MNAR';  
	 else if Time_NIM=Time_MAR then Mech='MCAR';  
	run;
	data CD4_MIX2_EXP;
	 set BIOM.CD4_All;
	 if Missingness="BOTH2";
	run;
	data CD4_MIX2_EXP;
	 set CD4_MIX2_EXP;
	 Missingness="MIX2 ";
	 if Time_MAR<Time_NIM      then Mech='MAR ';  
	 else if Time_NIM<Time_MAR then Mech='MNAR';  
	 else if Time_NIM=Time_MAR then Mech='MCAR';  
	run;
	data BIOM.CD4_MIXALL;
	 set CD4_MIX_EXP CD4_MIX1_EXP CD4_MIX2_EXP;
	run;
	proc sort data=BIOM.CD4_MIXALL;
	 by Missingness Study Subject;
	run;
%mend Create_CD4_MIXALL;
 %Create_CD4_MIXALL;


/*================================================================ 
 1) Create indicator variables for the status of each subject
    at the end of follow-up with status being EOS, MAR or MNAR
    dropout with EOS and MAR being ignorable missing (IM)  
    dropout while MNAR is non-ignorbale missing (NIM) dropout.
 2) KEY:
    Cause=MAR corresponds to subjects with a non-terminal dropout
    Cause=MNAR corresponds to subjects with a terminal dropout
    Cause=EOS corresponds to subjects who reach end of study (EOS)
================================================================*/ 
data CD4_MIXALL; 
 set BIOM.CD4_MIXALL;
 by Missingness Study Subject;
run;

proc means data=CD4_MIXALL nway mean;
 where x=0;
 class Missingness;
 var Ind_1 Ind_2 Ind_3;
run;

proc print data=CD4_MIXALL(obs=300);
 where Subject<=5 and study<=5;
 var Study Subject x CD4_Obs  Dropout time_MAR time_NIM T Event risktime t1i t2i t1 t2 
     Missingness Cause Mech Ind_1 Ind_2 Ind_3;
run;


/*================================================================= 
                HOW TO REDUCE SAS LOG OUTPUT
* Puts unwanted log output into the following file or whatever    ;
* file you wish to name it within whatever directory you want it  ;

filename bootlog "c:\edward\EFVwork.log";
proc printto log=bootlog;
run;

* Put SAS code here that may contain a lot of needless SAS log    ;
*...                                                              ;

* This instructs SAS to write SAS log in normal mode again        ;

proc printto;
run;
/*===============================================================*/ 


/*===============================================================================
                      MACRO SP_Model
  Performs Laplace (QPOINTS=1) or Gaussian Quadrature (QPOINTS=10) in order 
  to obtain MLE estimation in NLMIXED for the joint SP Models.     
  KEY: 
      Data= -Defines dataset to be run
     Where= -Defines a where statement set of restrictions on 
             what subset of the overall dataset is to be used.
   Listing= -Defines whether we print all of NLMIXED or not.
             When running 500 datasets it is best to use default = CLOSE
             Options are:
               Listing=CLOSE, (default)
               Listing=       (to print NLMIXED output)
   Exclude= -Defines whether we exclude all or none of ods output 
             datasets (use Exclude=ALL to speed up simulations
             after initial run so DLL is loaded)
             Options are:
               Exclude=NONE,  (default)
               Exclude=ALL,   (to speed up simulations) 
   Results= -Defines whether we include or exclude results where  
             we set Results=ON or Results=OFF                
             after initial run so DLL is loaded)
             Options are:
               Results=       (leave blank to allow results)
               Results=OFF    (set to OFF to speed up simulations) 
    Output= -Defines whether to output predicted values etc. 
             The user BEWARE as this produces large SAS datasets
             and so the default option is OUTPUT=NO
   qpoints= -Defines the number of quadrature points to be used for 
             numerical integration. The following were used in the    
             program according to which model is specified.
               Model=1: QPOINTS=1  Rationale: Since the random effects 
                        only appear in the model for CD4 which is a 
                        strictly linear mixed-effects model, qpoints=1
                        equates with the Laplace approximation which  
                        is exact when the random effects enter the 
                        overall model in a linear fashion and hence 
                        will yield exact ML estimates.
               Model=x: For Models x=2,3,4 and 5, we used QPOINTS=10. 
                        Rationale: We initially used QPOINTS=1 but did 
                        not achieve adequate confidence interval coverage
                        and so we ended up using QPOINTS=10 as this provided
                        good numerical intergration results and hence more
                        reliable posterior mode estimates of ranodm effects.
 Technique= -Defines what optimization technique should be used. 
             The default used throughout was technique=quanew.
   NumReps= -Defines the number of replicated datasets to run
   Hessian= -Defines whether one runs the MACRO Hessian on all NumReps 
             (specified number of replicated datasets as defined above). 
             This is useful as it informs one as to how many of the simulated
             datasets result in convergence but with a possible non-positive 
             definite Hessian matrix or a Hessian with negative eigenvalues  
             Options are:
               Hessian=YES (default)
               Hessian=NO  
     Model= -Defines what SP model is being fit to the data
               Model=1 All-Cause PH-(LV) model (SP Covariates=CD4_Obs)           
               Model=2 All_Cause PH-SREM(RE) model (SP Covariates=u1i,u2i) 
               Model=3 All-Cause PH-SREM(CV) model (SP Covariates=CD4_True) 
                       NOTE: Model 3 was never used in the Biometrics paper
               Model=4 All-Cause PH-SREM(LV,RE) model (SP Covariates=u1i,u2i,CD4_Obs)
               Model=5 Competing Risk PH-SREM(LV,RE) model with two hazard functions 
                       for non-terminal and terminal events having the following covariates
                       (SP1 Covariates = u1i,u2i,CD4_Obs for non-terminal dropout=MAR)
                       (SP2 Covariates = u1i,u2i,CD4_Obs for terminal dropout=MNAR)
                       Here we fit a competing risk SP model based on two known causes
                       of dropout where MAR dropout is linked to a non-terminal event
                       and MNAR dropout is linked to a terminal event. 
     LogHt= -Defines an all-cause log hazard function for SP models 1-4
             NOTE: Set LogHt=1 when running Model 5
    LogHt1= -Defines a log hazard function for the SP model 5 for non-terminal events 
             NOTE: Set LogHt1=1 when running Models 1-4
    LogHt2= -Defines a log hazard function for the SP model 5 for terminal events 
             NOTE: Set LogHt2=1 when running Models 1-4
     Parms= -Defines starting values of all parameters. Make sure one 
             defines the parameters for Missingness=MIX like eta01,
             eta11, eta21, eta31, et02, eta12, eta22, eta32 etc.   
      soln= -Defines name of SAS dataset with final parameter estimates
       fit= -Defines name of SAS dataset with final fit statistics (AIC, etc.)
     nlmix= -Defines name of SAS dataset with final predicted values (NOT RECOMMENDED)
      conv= -Defines name of SAS dataset with final convergence results
==================================================================================*/ 
%macro SP_Model(data=BIOM.CD4_MAR, 
                where=Study<1000,
                Output=no,
				listing=close,
				exclude=none,
				results=on,
				NumReps=500,
				Hessian=YES,
                qpoints=1 ,
				Technique=quanew,
				Model=1,
				LogHt = eta0 + eta1*Int1 + eta2*Int2 + eta3*Int3 + 
				        eta_CD4*CD4_Obs,
				LogHt1 = 1,
				LogHt2 = 1,
				Parms=%str( b1=26.0 b2=-1.30
				            eta0=3.956 -1.8563 -0.10 
                            eta1=0  eta2=0 eta3=0 eta_CD4-0.221
				            _psi11_=22.6 _psi12_=-2.07 _psi22_=1.85
				            Sigma_Sq=5.3),              
				soln = SP_Model_pe_1,
				fit  = SP_Model_fit_1,
				nlmix= SP_Model_nlmix_1,
				conv = SP_Model_conv_1);
	 %let Output=%qupcase(&output);  ** RECOMMENDED TO USE OUTPUT=NO **;
	 %let Hessian=%qupcase(&Hessian);
	 %let listing=%qupcase(&results);
	 %let exclude=%qupcase(&exclude);
	 %let results=%qupcase(&results);

	 %let _sdtm=%sysfunc(datetime());

	 *** SAS code ***;

	 proc sort data=&data;
	  by Missingness Study;
	 run;

	 %if %index(&exclude, ALL) or %index(&results, OFF) %then %do; 
	 ods exclude &exclude;
	 ods results=&results;
	 %end;
	 %else %do;
	 ods listing &listing;
	 %end;
	 ods output Hessian= Hessian 
	            parameterestimates=BIOM.&soln 
	            fitstatistics=BIOM.&fit 
	            convergencestatus=BIOM.&conv;
	 proc nlmixed data=&data technique=&technique %if %length(&qpoints) %then %do; qpoints=&qpoints %end; 
	                         HESS ECORR COV NOSORTSUB ZNLP;
	  where &where;
	  by Missingness Study;
	  parms &parms /best=1;

	  /* LME model for CD4 trajectories */ 
	  b1i=b1 + u1;
	  b2i=b2 + u2; 
	  SS_MeanCD4 = b1i + b2i*x;                       ** The subject-specific (SS) predicted mean CD4 at time x; 
	  CD4_True   = b1i + b2i*x;                       ** The SS_MeanCD4 equals CD4 measured without error at time x;
	  ll_1 = ( - 0.5*((CD4_Obs - SS_MeanCD4)**2)/Sigma_Sq 
	           - 0.5*log(Sigma_Sq) );                 ** The LME model conditional log-likelihood for CD4_Obs;

	  /* PE survival model for time to dropout */ 
	  LogT = log_risktime;                            ** Log risktime within a PE interval;
	  if Missingness in ('MAR' 'MNAR' 'BOTH' 'BOTH1' 'BOTH2') then do;
	   LogHt = &LogHt;                                ** The PE log-hazard rate log(H(t)) for all-cause SP models 1-4;
	   Ht = exp(LogHt);                               ** The PE hazard rate per unit time H(t) for SP models 1-4;
	   LogHt1 = 1;                                    ** NOT USED;                                            
	   LogHt2 = 1;                                    ** NOT USED;                                            
	   ll_2 = ( event*LogHt - Ht*exp(LogT) );         ** The PE model log-likelihood for all-cause dropout for SP models 1-4;
	  end;
	  if Missingness in ('MIX' 'MIX1' 'MIX2') then do;
	   LogHt  = 1;                                    ** NOT USED;
	   LogHt1 = &LogHt1;                              ** The PE log-hazard rate log(H(t)) for non-terminal dropout (MAR);
	   Ht1 = exp(LogHt1);                             ** The PE hazard rate per unit time H(t) for non-terminal dropout (MAR);
	   ll_21 = ( Ind_1*event*LogHt1 - Ht1*exp(LogT) );** The PE model log-likelihood for non-terminal dropout (MAR);
	                                                  ** NOTE: Ind_1*Event = delta_1i in Biometrics paper; 
	   LogHt2 = &LogHt2;                              ** The PE log-hazard rate log(H(t)) for terminal dropout (MNAR);
	   Ht2 = exp(LogHt2);                             ** The PE hazard rate per unit time H(t) for terminal dropout (MNAR);
	   ll_22 = ( Ind_2*event*LogHt2 - Ht2*exp(LogT) );** The PE model log-likelihood for terminal dropout (MNAR);
	                                                  ** NOTE: Ind_2*Event = delta_2i in Biometrics paper; 
	  end;

	  /*-------------------------------------------*/
	  /* SP model and its joint log-likelihood     */
	  /* for SP models 1-4. PLEASE NOTE SP model 3 */
	  /* was never modeled in these simulations    */
	  /*-------------------------------------------*/
	  %if &Model=1 or &Model=2 or &Model=3 or 
	      &Model=4 %then %do;
	  ll = ll_1  + ll_2;
	  %end;
	  /*-------------------------------------------*/
	  /* Competing Risk SP Model 5 and its joint   */
	  /* log-liklihood which is a PH-SREM(LV,RE)   */
	  /* model similar to all-cause SP model 4     */
	  /* which is a PH-SREM(LV,RE) model for CD4   */
	  /* If Cause='MAR'  then Ind_1 = 1, else 0    */
	  /* If Cause='MNAR' then Ind_2 = 1, else 0    */
	  /*  NOTE:  If Ind_1=1 then Ind_2=0 and       */
 	  /*         if Ind_2=1 then Ind_1=0 so that   */
	  /*         delta_1i = Ind_1*event and        */
	  /*         delta_2i = Ind_2*event where      */
	  /*         delta_1i and delat_2i are the     */
	  /*         event indicator variables for     */
	  /*         the non-terminal (MAR) dropout    */
	  /*         and the terminal (MNAR) dropout   */
	  /*         under a competing risk SP model   */
	  /*-------------------------------------------*/
	  %else %if &Model=5 %then %do;
	  ll = (ll_1 + ll_21 + ll_22);
	  %end;

	  model CD4_Obs ~ general(ll);
	  random u1 u2 ~ normal([0,0],[_psi11_,
	                               _psi12_, _psi22_])
	                 subject=subject; 
	  %if %index(&output,YES) %then %do; 
	  /*---------------------------------------------------------
	    Modify output to only include Missingness Study Subject 
	     and b1 b2 b1i b2i u1 u2 Sigma_sq _psi11_ _psi12_ _psi22_
         at x=0 so as to minimize the amount of output and so we 
	     can examine how well the model estimates the true random
	     effects as given by u1i and u2i
	    WARNING: One should probably avoid using OUTPUT=YES as it
                 will generate a huge dataset  
      ----------------------------------------------------------*/ 
	  id x ll_1 ll_2 b1i b2i b1 b2 u1 u2 u1i u2i Sigma_Sq _psi11_ _psi12_ _psi22_ ;
	  predict b1i out=BIOM.&nlmix;
	  data BIOM.&nlmix;
	   set BIOM.&nlmix;
	   by Missingness Study;
	   if x=0;
	   keep Missingness Study Subject x ll_1 ll_2: b1i b2i b1 b2 u1 u2 
            u1i u2i Sigma_Sq _psi11_ _psi12_ _psi22_;
	  run; 
	  %end;
	 run;

	 data BIOM.&soln; 
	  set BIOM.&soln; 
	  Model=&Model; 
	 run; 
	 data BIOM.&fit ; 
	  set BIOM.&fit ; 
	  Model=&Model; 
	 run;
	 data BIOM.&conv; 
	  set BIOM.&conv; 
	  Model=&Model; 
	 run; 

	option spool;

	%if %index(&Hessian, YES) %then %do;
	data Hessian;
	 set Hessian;
	 if Missingness="MAR  " then MissingMechanism=1;
	 if Missingness="MNAR " then MissingMechanism=2;
	 if Missingness="BOTH " then MissingMechanism=3;
	 if Missingness="BOTH1" then MissingMechanism=4;
	 if Missingness="BOTH2" then MissingMechanism=5;
	 if Missingness="MIX  " then MissingMechanism=6;
	 if Missingness="MIX1 " then MissingMechanism=7;
	 if Missingness="MIX2 " then MissingMechanism=8;
	run;
	data FinalHessOut;
	 set _null_;
	run;
	** Set j=1 for all eight 8 MissingMechanisms  **;
	** Set j=6 for just the competing risk SP     **;
	** models corresponding to MIX, MIX1 and MIX2.**; 
	%do j = 1 %to 8;  
	 %do k = 1 %to &NumReps;
	 data matrix;
	  set Hessian;
	  by Missingness Study;
	  if MissingMechanism=&j and Study=&k;
	  drop Missingness Study Row Parameter MissingMechanism;
	 run;
	 run;
	 proc iml;
	  use work.matrix;
	  read all var _NUM_ into H[colname=varNames]; 
	  close matrix;
	  /* Determine problems with Hessian matrix so that convergence status can be updataed to reflect this */
	  DetH = det(H);                ** If 0 then Hessian is not p.d. or is singular; 
	  EigenH=eigval(H);             ** If a negative eigenvalue then second-order optimality is violated ;
	  MinEigenH = min(eigval(H));   ** One or more eigenvalue are negative, second-order optimality is violated ;  
	  Status_H=0;                    
	  pdH = 0;                      ** Hessian is p.d. (i.e., non-singular with DET(H) not equal to 0);
	  negH = 0;                     ** Hessian does not have any negative eigenvalues;
      if DetH<=0 then pdH=1;        ** Hessian is non p.d. (DET(H)=0);  
      if MinEigenH<0 then negH=1;   ** Hessian has 1 or more negative eigenvalues; 
	  Status_H=max(pdH, negH);      ** Status_H =0 => Hessian is OK, else Hessian is non p.d. or has eigenvalues<0;
	  MissingMechanism=&j;          ** Include MissingMechanism to get back MissingData values; 
	  Study=&k;                     ** Include the Study number (i.e., the study replication number) here; 
	 *print MissingMechanism Study DetH EigenH MinEigenH pdH negH Status_H;
	  /* Create dataset Hessout */
	  HessOut = MissingMechanism||Study||DetH||pdH||MinEigenH||negH||Status_H;
	 *print HessOut;
 	  create HessData from HessOut;
      append from HessOut;
	  quit;
	  data HessData;
	   set HessData;
	   rename col1=MissingMechanism col2=Study col3=DetH col4=pdH col5=MinEigenH col6=negH col7=Status_H;
	  run;
	  data FinalHessOut;
	   set FinalHessOut Hessdata;
	  run;
	  %end;
	 %end;
	 data FinalHessOut;
	  set FinalHessOut;
	  if MissingMechanism=1       then Missingness="MAR  ";
	  else if MissingMechanism=2  then Missingness="MNAR ";
	  else if MissingMechanism=3  then Missingness="BOTH ";
	  else if MissingMechanism=4  then Missingness="BOTH1";
	  else if MissingMechanism=5  then Missingness="BOTH2";
	  else if MissingMechanism=6  then Missingness="MIX  ";
	  else if MissingMechanism=7  then Missingness="MIX1 ";
	  else if MissingMechanism=8  then Missingness="MIX2 ";
	 run;
	 proc sort data=FinalHessOut;
	  by Missingness Study;
	 run;
	 %let _edtm=%sysfunc(datetime());
	 %let _runtm=%sysfunc(putn(&_edtm - &_sdtm, 12.4));
	 %put It took &_runtm seconds to run the program;
	 *proc print data=FinalHessOut;run;
	 data BIOM.&conv;
	  merge BIOM.&conv FinalHessOut;
	  RunTimeSec = &_runtm;                   ** RunTime in seconds **;
	  RunTimeMin = round(RunTimeSec/60, .01); ** RunTime in minutes **;
	  RunTimeHrs = round(RunTimeMin/60, .01); ** RunTime in hours   **;
	  by Missingness Study;
	 run;
	%end;
	 ods exclude none;
	 ods results;
	 ods listing; 

%mend SP_Model;

/*=========================================================================
   Macro Summary_Simul summarizes bias in intercept and slope parameters 
   along with the key association parameters for predicting dropout.
   KEY: 
        N=  -Defines the number of replicated datasets that converged
             successfully to be summarized.
    Model=  -Defines which model is to be summarized. For example, if one
             wants to summarize results for Model=2 (SP covariates: u1, u2)
             one would specify the options as follows:
               Model= 2  
             The possible Models are:
               Model=1 (SP Covariates = CD4_Obs) 
               Model=2 (SP Covariates = u1i, u2i) 
               Model=3 (SP Covariates = CD4_True) - This model was never run
               Model=4 (SP Covariates = u1i, u2i, CD4_Obs) 
               Model=5 (SP1 Covariates = u1i, u2i, CD4_Obs for MAR cause)
                       (SP2 Covariates = u1i, u2i, CD4_Obs for MNAR cause)
                       where we now fit a competing risk SP model
                       based on two known causes of dropout where
                       MAR dropout is linked to a non-terminal event
                       and MNAR dropout is linked to a terminal event. 
PrintFreq=  -Define whether we print PROC FREQ results on the number
             of studues that converged successfully. 
               PrintFreq=YES 
               PrintFreq=NO 
===========================================================================*/

%macro Summary_Simul(N=500, Model=2, PrintFreq=YES);
	data pe_&Model;
	 set _null_;
	run;
	data conv_&Model;
	 set _null_;
	run;

	data pe_&Model;
	 set BIOM.SP_Model_pe_&Model;
	 by Missingness Study;
	run;
	data conv_&Model;
	 set BIOM.SP_Model_conv_&Model;
	 by Missingness Study;
	 Convergence="Success";
	 if status=1 or status_H=1 then 
	 Convergence="Failed ";
	 keep Missingness Study Convergence Status Status_H;
	run; 
	data pe_&Model;
	 merge pe_&Model(in=a) conv_&Model(in=b);
	 by Missingness Study;
	 if a and b;
	run;
	data pe_&Model;
	 set pe_&Model;
	 by Missingness Study;
	 if Convergence="Success";
	run;
	proc sort data= pe_&Model;
	 by Missingness Study;
	run;
	data pe_&Model;
	 set pe_&Model;
	 by Missingness Study;
	 retain N_ind 0;
	 if first.Missingness then N_Ind=0;
	 if first.Study then N_ind+1;
	run;
	data pe_&Model;
	 set pe_&Model;
	 by Missingness Study;
	 if N_Ind<=&N; /* Pick the first 500 replications that converged */
	run;

	data cause_&Model;
	 set pe_&Model;
	 by Missingness Study;
	 if first.Study;
	 keep Missingness Study;
	run;

	%macro Bias(Parameter=, TrueValue=);
	 if Parameter="&Parameter" then do;
	  TrueValue=&TrueValue;
	  Bias= (Estimate - TrueValue); 
	  PctBias = round(100*(Bias/TrueValue), .01);
	  if TrueValue=0 then PctBias=Bias;
	  if Lower<=TrueValue<=Upper then do;
	   CI_Coverage=1;
	  end;   
	  else do;
	   CI_Coverage=0;
	  end;
	 end;
	%mend Bias;

	data pe_&Model;
	 set pe_&Model;
	 by Missingness Study;
	 %bias(Parameter=b1, TrueValue=23.60);
	 %bias(Parameter=b2, TrueValue=-1.30);
	 %bias(Parameter=_psi11_, TrueValue=22.60);
	 %bias(Parameter=_psi12_, TrueValue=-2.07);
	 %bias(Parameter=_psi22_, TrueValue=1.85);
	 %bias(Parameter=Sigma_Sq, TrueValue=5.30);

	 /*=========================================
	   No need to include eta_u1 or eta_u2 as
	   these covariates are not in Model 1.
	 =========================================*/
	 if Model in (1) then do;
	 if Missingness in ('MNAR') then do;
	   %bias(Parameter=eta_CD4, TrueValue=0);
	 end;
	 else if Missingness in ('MAR') then do;
	   %bias(Parameter=eta_CD4, TrueValue=-0.221);
	 end;
	 else if Missingness in ('BOTH') then do;
	   %bias(Parameter=eta_CD4, TrueValue=-0.221);
	 end;
	 else if Missingness in ('BOTH1') then do;
	   %bias(Parameter=eta_CD4, TrueValue=-0.321);
	 end;
	 else if Missingness in ('BOTH2') then do;
	   %bias(Parameter=eta_CD4, TrueValue=-0.421);
	 end;
	 end;

	 /*=========================================
	   No need to include eta_CD4 as this
	   covariate is not in Model 2 
	 =========================================*/
	 if Model in (2) then do;
	  %bias(Parameter=eta_u1, TrueValue=-0.10536);
	  %bias(Parameter=eta_u2, TrueValue=-2.23144);
	 end;

	 /*=========================================
	   We need consider eta_CD4, eta_u1, eta_u2
	   as these covariates are in Models 4 and 5 
	   under Missingness=BOTH, BOTH1, BOTH2 and 
	   under Missingness=MIX, MIX1, MIX2
	 =========================================*/
	 if Model in (4 5) then do;
	 if Missingness='MAR' then do;
	   %bias(Parameter=eta_u1, TrueValue=0);
	   %bias(Parameter=eta_u2, TrueValue=0);
	   %bias(Parameter=eta_CD4, TrueValue=-0.221);
	 end;
	 if Missingness='MNAR' then do;
	   %bias(Parameter=eta_u1, TrueValue=-0.10536);
	   %bias(Parameter=eta_u2, TrueValue=-2.23144);
	   %bias(Parameter=eta_CD4, TrueValue=0);
	 end;
	 if Missingness='BOTH' then do;
	   %bias(Parameter=eta_CD4, TrueValue=-0.221);
	   %bias(Parameter=eta_u1, TrueValue=-0.10536);
	   %bias(Parameter=eta_u2, TrueValue=-2.23144);
	 end;
	 if Missingness='BOTH1' then do;
	   %bias(Parameter=eta_CD4, TrueValue=-0.321);
	   %bias(Parameter=eta_u1, TrueValue=-0.10536);
	   %bias(Parameter=eta_u2, TrueValue=-2.23144);
	 end;
	 if Missingness='BOTH2' then do;
	   %bias(Parameter=eta_CD4, TrueValue=-0.421);
	   %bias(Parameter=eta_u1, TrueValue=-0.10536);
	   %bias(Parameter=eta_u2, TrueValue=-2.23144);
	 end;
	 if Missingness='MIX  ' then do;
	   %bias(Parameter=eta1_CD4, TrueValue=-0.221);
	   %bias(Parameter=eta1_u1, TrueValue=0);
	   %bias(Parameter=eta1_u2, TrueValue=0);
	   %bias(Parameter=eta2_CD4, TrueValue=0);
	   %bias(Parameter=eta2_u1, TrueValue=-0.10536);
	   %bias(Parameter=eta2_u2, TrueValue=-2.23144);
	 end;
	 if Missingness='MIX1 ' then do;
	   %bias(Parameter=eta1_CD4, TrueValue=-0.321);
	   %bias(Parameter=eta1_u1, TrueValue=0);
	   %bias(Parameter=eta1_u2, TrueValue=0);
	   %bias(Parameter=eta2_CD4, TrueValue=0);
	   %bias(Parameter=eta2_u1, TrueValue=-0.10536);
	   %bias(Parameter=eta2_u2, TrueValue=-2.23144);
	 end;
	 if Missingness='MIX2 ' then do;
	   %bias(Parameter=eta1_CD4, TrueValue=-0.421);
	   %bias(Parameter=eta1_u1, TrueValue=0);
	   %bias(Parameter=eta1_u2, TrueValue=0);
	   %bias(Parameter=eta2_CD4, TrueValue=0);
	   %bias(Parameter=eta2_u1, TrueValue=-0.10536);
	   %bias(Parameter=eta2_u2, TrueValue=-2.23144);
	 end;
	 end;
	 SE=StandardError;
	run;

	proc means data=pe_&Model n mean std clm nway maxdec=4;
	 where Convergence in ('Success') and Missingness in ('MAR' 'MNAR' 'BOTH' 'BOTH1' 'BOTH2' 'MIX' 'MIX1' 'MIX2') 
           and Parameter in ('b1' 'b2' '_psi11_' '_psi12_' '_psi22_' 'SigmaSq' 
                             'eta_CD4' 'eta_u1' 'eta_u2' 'eta1_CD4' 'eta1_u1' 'eta1_u2' 'eta2_CD4' 'eta2_u1' 'eta2_u2');
	 class Missingness Model Parameter;
	*var TrueValue Estimate SE Bias PctBias CI_Coverage;
	 var TrueValue Estimate Bias PctBias CI_Coverage;
	 title1 "Mean bias in intercept (b1) and slope (b2) under SP model &model based on 15 month PE intervals.";
	 title2 "The mean of the SE estimate of the parameter should be close to the empirical Std Dev of the estimate.";
	 %if &model=1 %then %do;
	 title4 "Model=1 - All-Cause PH-(LV) Joint Model (SP Covariates = CD4(Obs))";
	 %end; 
	 %if &model=2 %then %do;
	 title4 "Model=2 - All-Cause PH-SREM(RE) Joint Model (SP Covariates = u1i, u2i)";
	 %end; 
	 %if &model=3 %then %do;
	 title4 "Model=3 - All-Cause PH-SREM(CV) Joint Model (SP Covariates = CD4(True))";
	 %end; 
	 %if &model=4 %then %do;
	 title4 "Model=4 - All-Cause PH-SREM(LV,RE) Joint Model (SP Covariates = CD4(Obs), u1i, u2i)";
	 %end;
	 %if &model=5 %then %do;
	 title4 "Model=5 - Competing Risk PH-SREM(LV,RE) Joint MOdel (SP1 and SP2 Covariates = CD4(Obs), u1i, u2i)";
	 %end;
	 title6 "NOTE: PctBias = Mean Bias when true value=0 but reported in manuscript/paper as |Mean Bias|";
	run;
	%if %index(&PrintFreq, YES) %then %do;
	proc freq data=conv_&Model;
	 tables Missingness*Convergence / crosslist;
	 title "Sumary of convergence status under SP model &Model based on 15 month (1.25 year) PE intervals.";
	run; 
	%end;
%mend Summary_Simul;

options symbolgen mprint;  
run;

/*================================================================================================
  The following calls to MACRO SP_Model are for a PE survival model with 15-month intervals
  Remove the comment star in front of the macros %SP_Model and %Summary_Simul to run the macros 
  NOTE 1: Each call to %SP_Model runs &NumReps simulated datasets on 1000 subjects per dataset and 
          so it may take quite sometime to complete each call to the macro if one sets NumRep=500. 
  NOTE 2: The initial value of NumReps is set to be NumReps=5 so as to avoid running all 500 
          datasets until the user is ready to do so. 
================================================================================================*/

/* Call to SP Model 1 */
 %SP_Model( data=BIOM.CD4_All, 
				where=Study<1000,
				output=no,
			  	listing=close,
				exclude=ALL,
				results=OFF,    
				NumReps=5  ,
				qpoints=1,
				technique=quanew,
				Model=1,
				LogHt = eta0 + eta1*Int1 + eta2*Int2 + eta3*Int3 + 
				        eta_CD4*CD4_Obs,
				LogHt1=1,
				LogHt2=1,
				parms=%str( b1=26.0 b2=-1.30
				             eta0=3.956 -1.8563 -0.10 eta1=0  eta2=0 
				             eta3=0 eta_CD4=0 -0.221
				            _psi11_=22.6 _psi12_=-2.07 _psi22_=1.85
				            Sigma_Sq=5.3),              
				soln = SP_Model_pe_1,
				fit  = SP_Model_fit_1,
				nlmix= SP_Model_nlmix_1,
				conv = SP_Model_conv_1);
run;
 %Summary_Simul(N=500, Model=1, PrintFreq=NO );                 

/* Call to SP Model 2 */
*%SP_Model( data=BIOM.CD4_All,  
				where=Study<1000,
				output=no,
				listing=close,
				exclude=ALL,
				results=OFF,
				NumReps=5  ,
				qpoints=10,
				technique=quanew,
				Model=2,
				LogHt = eta0 + eta1*Int1 + eta2*Int2 + eta3*Int3 + 
				        eta_u1*u1 + eta_u2*u2,
				LogHt1=1,
				LogHt2=1,
				parms=%str( b1=26.0 b2=-1.30
				             eta0=3.956 -1.8563 -0.10 eta1=0  eta2=0 
				             eta3=0 eta_u1=0 -0.105 eta_u2=0 -2.23
				            _psi11_=22.6 _psi12_=-2.07 _psi22_=1.85
				            Sigma_Sq=5.3),              
				soln = SP_Model_pe_2,
				fit  = SP_Model_fit_2,
				conv = SP_Model_conv_2);
run;
*%Summary_Simul(N=500, Model=2, PrintFreq=NO );                  

/* Call to SP Model 3 - This SP model was not used in the Biometrics paper */
*%SP_Model( data=BIOM.CD4_All, 
				where=Study<1000,
				output=no,
				listing=close,
				exclude=ALL,
				results=OFF,
				NumReps=5  ,
				qpoints=10,
				technique=quanew,
				Model=3,
				LogHt = eta0 + eta1*Int1 + eta2*Int2 + eta3*Int3 + 
				        eta_Muij*CD4_True,
				LogHt1=1,
				LogHt2=1,
				parms=%str( b1=26.0 b2=-1.30
				             eta0=3.956 -1.8563 -0.10 eta1=0  eta2=0 
				             eta3=0 eta_Muij=0 -.221 
				            _psi11_=22.6 _psi12_=-2.07 _psi22_=1.85
				            Sigma_Sq=5.3),              
				soln = SP_Model_pe_3,
				fit  = SP_Model_fit_3,
				conv = SP_Model_conv_3);
run;

/* Call to SP Model 4 */
*%SP_Model( data=BIOM.CD4_All,  
				where=Study<1000,
				output=no,
				listing=close,
				exclude=ALL,
				results=OFF,
				NumReps=5  ,
				qpoints=10,
				technique=quanew,
				Model=4,
				LogHt = eta0 + eta1*Int1 + eta2*Int2 + eta3*Int3 + 
				        eta_CD4*CD4_Obs + eta_u1*u1 + eta_u2*u2,
				LogHt1=1,
				LogHt2=1,
				parms=%str( b1=26.0 b2=-1.30
				             eta0=3.956 -1.8563 -0.10 eta1=0  eta2=0 eta3=0 
				             eta_CD4=0 -0.221 eta_u1=0 -0.105 eta_u2=0 -2.23
				            _psi11_=22.6 _psi12_=-2.07 _psi22_=1.85
				            Sigma_Sq=5.3),              
				soln = SP_Model_pe_4,
				fit  = SP_Model_fit_4,
				nlmix= SP_Model_nlmix_4,
				conv = SP_Model_conv_4);
run;
*%Summary_Simul(N=500, Model=4, PrintFreq=NO );                  

/* Call to SP Model 5 */
*%SP_Model( data=CD4_MIXALL,
				where=Study<1000,
				output=no,
				Hessian=YES,
				listing=close,
				exclude=ALL,
				results=OFF,
				NumReps=5  ,
				qpoints=10,
				technique=quanew,
				Model=5,
				LogHt  = 1,
				LogHt1 = eta01 + eta11*Int1 + eta21*Int2 + eta31*Int3 +
				         eta1_CD4*CD4_Obs + eta1_u1*u1 + eta1_u2*u2,
				LogHt2 = eta02 + eta12*Int1 + eta22*Int2 + eta32*Int3 +
				         eta2_CD4*CD4_Obs + eta2_u1*u1 + eta2_u2*u2,
				parms=%str( b1=26.0 b2=-1.30
				            eta01=3.956
				            eta11=0 eta21=0 eta31=0 
				            eta02=-1.8563 
				            eta12=0 eta22=0 eta32=0  
				            eta1_CD4=-0.221 eta1_u1=0 eta1_u2=0
				            eta2_CD4=0 eta2_u1=-0.105 eta2_u2=-2.23
				            _psi11_=22.6 _psi12_=-2.07 _psi22_=1.85
				            Sigma_Sq=5.3),
				soln = SP_Model_pe_5,
				fit  = SP_Model_fit_5,
				nlmix= SP_Model_nlmix_5,
				conv = SP_Model_conv_5);
run;
*%Summary_Simul(N=500, Model=5, PrintFreq=NO );      





