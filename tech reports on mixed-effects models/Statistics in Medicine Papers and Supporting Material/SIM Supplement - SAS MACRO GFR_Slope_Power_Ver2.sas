*******************************************************************;
**   PROGRAM: SIM Supplement - SAS MACRO GFR_Slope_Power_Ver2.sas**;
**   WRITTEN: Jan 17, 2019                                       **;
**   UPDATED: Feb 10, 2019                                       **;
**   UPDATED: Apr 13, 2019                                       **;
**   UPDATED: Feb 21, 2021 (This is Version 2 of the program)    **;
**   AUTHOR : Edward F. Vonesh                                   **;
**   PURPOSE: This SAS macro provides the code used to calculate **;
**            power estimates based on user supplied parameters  **;
**            that are consistent with the parameters of the     **;
**            linear spline mixed-effects model (2) described    **;
**            in the Statistics in Medicine (SIM) paper titled:  **;
**                             TITLE                             **;  
**            Mixed-effects models for slope-based endpoints in  **; 
**            clinical trials of chronic kidney disease.         **;
**                            AUTHORS                            **;
**            Vonesh E, Tighiouart H, Ying J, Heerspink HL,      **;
**            Lewis J, Staplin N, Inker L and Greene T.          **;
**                                                               **;
**   A detailed description of the SAS macro and the required    **;
**   and optional macro input variables are described below      **;
**   along with the examples used to generate Tables A.1-A.6 in  **;
**   the supplementary material (Web Appendix A).                **;
**                                                               **;
**              CORRECTIONS/CHANGES: Made Feb 21, 2021           **;
** UPDATED: 1)Correction was made to the original code in which  **;
**            the user might specifiy a value for the knot other **;
**            than the default knot of 4 months which was used   **;
**            for ALL power calculations shown in Web Appendix A **;
**            of the supplementary material. The CONTRAST and    **;
**            ESTIMATE statements used in PROC MIXED to estimate **;
**            power for Total Slope at 2, 3 and 4 years uses     **;
**            constant values of 0.8333=(1-4/24), 0.8888=(1-4/36)**;
**            and 0.9166=(1-4/48) rather than values based on    **;
**            the value of (1-&knot/t) for whatever value of knot**;
**            one specifies in the macro. Note that results that **;
**            are shown in Table 9 are all correct as they look  **;
**            at what impact misspecifying the knot would have on**;
**            overall power for comparing chronic slopes which   **;
**            the program does compute correctly based on the    **;
**            value one assigns to the macro variable &knot. If  **;
**            one specifies a value of &knot different from 4    **;
**            one would get estimated values of power for the    **;
**            total slope comparisons that would be incorrectly  **;
**            based on a knot at 4 months rather than the knot   **;
**            specified in the macro. This version of the macro  **;
**            corrects this mistake.                             **;
*******************************************************************;


/*===========================================================================================================
                                            MACRO GFR_Slope_Power
 This macro computes power for detecting differences in select rates of decline (slopes) in eGFR based on
 a linear spline mixed-effects model with acute slopes, change (or delta) slopes and chronic slopes, an 
 intra-subject power-of-mean (POM) variance structure and a random effects structure which assumes a
 subject-specific (SS) random intercept effect, a random acute slope effect and a random delta slope effect   
 having a multivariate normal distribution with mean vector 0 and a variance-covariance structure as specified
 by input parameters listed under the KEY MACRO VARIABLES shown below. The program also allows the user to assume
 a treatment-dependent or uniform treatment effect on the random slope effects through specification of the macro 
 variable parameter KAPPA (with KAPPA = 0 corresponding to a uniform treatment effect). Additional program 
 options include power estimates based on either 1) a population-average POM (PA-POM) variance structure
 (obtained by setting the macro variable POM=PA) used to approximate the marginal within-subject covariance 
 matrix associated with the SS-POM variances, or 2) an estimated-marginal POM (EM-POM) variance structure 
 (obtained by setting macro variable POM=EM) which is an empirically estimated marginal mean of the SS-POM 
 variances or 3) a homogeneous intra-subject variance structure with constant variance obtained by setting the
 parameter THETA = 0. The program also allows power estimates in the presence of patient dropout due to end-stage 
 kidney disease (ESKD) defined for a subject to occur whenever the subject-specific predicted mean eGFR falls 
 below 15 mL/min/1.73m2. This is determined by generating a multivarite normal random effect vector for each 
 subject and computing subject-specific mean profiles across subjects. This program assumes a RCT with only 
 two treatment groups (Control vs. Treated) and it assumes an equal sample size per treatment group. The power 
 estimates are based on approximations described by Littell et al. and references therein.

 The macro creates two datasets, F_Tests and t_Tests, both of which contain power calculations for specified
 values of the input parameters given by the macro variables listed below. Alternatively, the macro creates 
 a dataset, ALL_t_Tests_Update, which contains power calculations based on the values of the DIFF= option. 

 REFERENCE: Littell RC, et al. (2006). SAS for Mixed Models, Second Edition. Cary NC: SAS Institute Inc.
            Chapter 12, pp. 479-495.
=============================================================================================================
 KEY MACRO VARIABLES: 
      Data=       -Defines a dataset name to be used when creating the dataset on which power is based
      knot=       -Assumed knot (in months) at which the acute slope transitions into a chronic slope  
                   DEFAULT VALUE: KNOT=4   

      THE FOLLOWING MACRO VARIABLE NAMES ARE CONSISTENT WITH THE NOTATION OF EQUATIONS 2 AND 4 OF THE PAPER 

      beta0=      -Baseline mean eGFR (intercepts: beta0c = beta0t = beta0) for Control (c) and Treated (t) 
                   groups assuming equal intercepts for the two groups based on the principals of randomization
      beta1c=     -Assumed acute slope for Control group in mL/min/1.73m2/month
      beta2c=     -Assumed delta (change) slope for Control group in mL/min/1.73m2/month
      beta1t=     -Assumed acute slope for Treated group in mL/min/1.73m2/month
      beta2t=     -Assumed delta (change) slope for Treated group in mL/min/1.73m2/month
      Var_e=      -Assumed within-subject variance component of residual errors  
      Var_u0=     -Assumed random intercept (u0) variance for the Control group in mL/min/1.73m2 
      Var_u1=     -Assumed random acute slope (u1) variance for the Control group in mL/min/1.73m2/month
      Var_u2=     -Assumed random delta (change) slope (u2) variance for the Control group in mL/min/1.73m2/month
      Cov_u0u1=   -Assumed covariance between u0 and u1
      Cov_u0u2=   -Assumed covariance between u0 and u2
      Cov_u1u2=   -Assumed covariance between u1 and u2
      kappa=      -Assumed treatment=dependent effect on random slopes [KAPPA = 0 yields a uniform treatment effect)
      theta=      -Assumed within-subject power-of-mean parameter (THETA = 0 yields a homogeneous variance structure)
      DIFF=       -Assumed incremental differences between the chronic slope for Treated group versus the 
                   chronic slope for the Control group in mL/min/1.73m2/month. The values of DIFF form  
                   the differences between the Treated - Control Chronic Slopes for which power is then
                   calculated for the chronic slope, delta slope and total slopes the latter two of 
                   which are functions of the fixed acute slopes and the assumed chronic slopes. 
                   A typical specification might look like  
                     DIFF = 0.05 to 0.20 by 0.05 
                   which specifies Treated Chronic Slope - Control Chronic Slope = beta3t - beta3c = DIFF
                   in mL/min/1.73m2/month. Note that 0.10 mL/min/1.73m2/month = 1.2 mL/min/1.73m2/year.
                   DEFAULT VALUE: DIFF=   

                   NOTE 1: If DIFF is specified then this automatically assumes the acute slopes remain
                           fixed for the two treatment groups based on the input parameters beta1c and beta1t 
                           as does the delta slope = beta2c and chronic slope = beta1c+beta2c = beta3c for the
                           control group. The treated group chronic slope beta3t is then set equal to beta3c + DIFF. 
                           The differences (DIFF) in the delta and total slopes are then determined exclusively 
                           based on the values of DIFF for the chronic slope differences between the treated 
                           and control groups as determined by the chronic slope for the control group as 
                           determined by the input parameters beta1c and beta2c. .e., any specified value
                           of beta2t is ignored with beta2t being determined based on DIFF (i.e., 
                           beta3c = beta1c+beta2c 3c beta2t=beta3t-beta1t).   
                   NOTE 2: The DIFF values as well as the differences in all slope parameters are converted
                           to units of mL/min/1.73m2/year in the output datasets and corresponding printout.
      Months=     -Measurement occasions in months when eGFR is measured (study design points)
                   DEFAULT VALUE: Months=%str(0,3,6,12,18,24,30,36,42,48,54) based on the IDNT study design 
      POM=        -Defines the Power-of-Mean (POM) structure. The options are
                    1) POM = PA  in which case the population-average power-of-means (PA_POM), mu = E(eGFR), based  
                       on the assumed population intercepts and slopes are used to approximate the intra-subject 
                       marginal power-of-mean variance structure.  
                    2) POM = EM  in which case the macro computes an estimated-marginal powewr-of-mean (EM-POM) 
                       structure used to approximate the intra-subject marginal power-of-means variance structure.
                       This is accomplished by creating M replicates of mu_ij = E(eGFR|bi) based on M generated 
                       multivariate normal random-effects vector bi~N(0,PSI_k) per treatment group and averaging 
                       the values of (mu_ij**2)**theta to form a marginal weights wij which can then be used to 
                       estimate the intra-subject marginal power-of-mean variance structure. The value of M is 
                       determined by the value specified for the macro variable REPS= defined below.  
                    3) POM = 0   in which case the macro computes an estimated-marginal variance structure assuming 
                       a common variance across repeated measures of eGFR with 0 power-of-mean structure (0-POM). 
                       This achived by setting the macro variable THETA = 0 when one specifies POM=0.
                   DEFAULT VALUE: POM = PA 
      Reps=       -Specified number of replicated random effects per subject one wishes to use to compute 
                   an averge of the SS-POM weights which one can then use to compute a marginal covariance structure. 
                   DEFAULT VALUES: Reps = 0   (for options POM=PA or POM=0) 
                                   Reps = 500 (for option POM=EM) 
      LowerGFR=   -Defines a minimum level of eGFR measured in mL/min/1.73m2 at baseline as part of screening. 
                   Subjects whose eGFR falls below this threshold are not eligible for the study.
                   DEFAULT VALUE: LowerGFR = 15   (in mL/min/1.73m2). 

                   Classification of CKD using eGFR that may be used as part of a study inclusion/exclusion
                   criteria are as follows:
                                            CKD Classification using eGFR             
                                          CKD Stage 1    >90   mL/min/1.73m2
                                          CKD Stage 2  60 - 89 mL/min/1.73m2
                                          CKD Stage 3a 45 - 59 mL/min/1.73m2
                                          CKD Stage 3b 30 - 44 mL/min/1.73m2
                                          CKD Stage 4  15 - 29 mL/min/1.73m2
                                          CKD Stage 5    <15   mL/min/1.73m2 

      UpperGFR=   -Defines a maximum level of eGFR measured in mL/min/1.73m2 at baseline as part of screening. 
                   Subjects whose eGFR measured without error falls above this threshold are not eligible for 
                   the study. Classification of CKD based on a range of eGFR values are shown above.  
                   DEFAULT VALUE: UpperGFR = 120  (in mL/min/1.73m2)
      Screen=     -Defines the number of subjects to be screened per group over and beyond the total number of  
                   patients enrolled in a study. If N is the number subjects per group considered for enrollment, 
                   then 2(N + Screen) is the total number of patients that should be screened to ensure they satisfy
                   the entry criteria for a given study. For example, a study that targets patients with CKD 
                   Stages 1 - 4 might screen eGFR at baseline to be between 15 - 120 mL/min/1.73m2 with 
                    LowerGFR =  15 mL/min/1.73m2 
                    UpperGFR = 120 mL/min/1.73m2 
                   Subjects whose predicted eGFR at baseline falls below 15 or above 120 are excluded from the study. 
                   DEFAULT VALUE: SCREEN = 100    (per group over the proposed sample size per group).    
      Accrual=    -Defines an assumed accrual (recruitment) period over which patients are enrolled into a study.
                   For example, the IDNT study (ref. 13) planned to recruit patients over 3 years and follow  
                   patients a minimum of 2 years following the end of accrua. The IDNT study ended up with 1715
                   patients recruited over 35 months (March 21, 1996 through Feb 25, 1999) with folloup through 
                   December 31, 2000. This yields an accrual rate of 49 patients per month assuming a uniform 
                   accrual rate. By combining an Accrual period with a Followup period one can define a 
                   Total Study period over which patients are followed. This in turn may be used to generate a
                   one-time representation of staggered patient entries assuming a uniform accrual rate.              
                   DEFAULT VALUE: ACCRUAL = 0     (to ensure complete and balanced data). 
      Followup=   -Defines the follow-up time (in months) following the end of the accrual period over which     
                   patients are followed. The accrual and followup periods are used to calculate an accrual rate
                   based on the total sample size proposed for a study. One may wish to assume a uniform 
                   accrual rate and work backwards to define the accrual period needed to recruit a set number
                   of patients.  
                   DEFAULT VALUE: FOLLOWUP = 60   (6 months > the last intended measurement at 54 months - see Months=)
      Dropout=    -Defines a non-informative dropout rate based on a proportion of subjects who, at random, dropout 
                   over a 12 month period. For example, Dropout=0.10 implies 10% of subjects dropout in 12 months
                   which gives rise to a constant dropout rate = -log(1-.10)/12 = 0.00878 per month. This is then
                   used to generate a one time set of exponentially distributed dropout times for the 2N subjects 
                   so as to reflect power based on a one-time simulation of non-informative dropout.  
                   DEFAULT VALUE: DROPOUT = 0.00  (implying there is no non-informative patient dropout).  
      InfCensor=  -Defines whether subjects dropout due to ESKD which is defined to occur whenever the predicted
                   eGFR for a subject falls below 15 mL/min/1.73m2. The subject-specific predicted eGFR values are
                   generated one time based on randomly generated intercepts and slopes as described below.
                   Options are
                    1) InfCensor = NO  in which case Power is based on assuming no informative censoring resulting  
                       from dropout due to ESKD which is defined to occur whenever a subject reaches a predicted 
                       mean eGFR < 15 mL/min/1.73m2. When this option is selected along with the option that the  
                       non-informative dropout rate is 0 (DropoutRate = 0 above), the power is based on a completely
                       balanced study design with incomplete data resulting only from staggered entry during accrual.   
                    2) InfCensor = YES in which case Power is based on an unbalanced population with dropout resulting
                       from informative cesnoring due to ESKD as well as non-informative cesnoring due to 
                       administrative censoring based on staggered entry (accrual) and dropout for reasons unrelated
                       to eGFR values. 
                   DEFAULT VALUE: InfCensor = NO  (implying there is no infromative censoring due to ESKD)       

                   DESCRIPTION: 
                    Informative dropout due to ESKD is determined by randomly generating a multivariate normal vector 
                    of random intercept and slope effects for each subject for each specified sample size (N) per 
                    group under the assumed random-effects covariance matrix. Based on these SS random intercepts 
                    and slopes combined with the PA intercept and slopes, the program calculates subject-specific  
                    (SS) predicted mean eGFR values, mu_ij = E(eGFR|bi). Once a subject reaches the threshold value 
                    of a predicted eGFR = mu_ij < 15 mL/minb/1.73m2, followup on that subject is terminated 
                    reflecting dropout due to ESKD. 

                   NOTE:
                    By specifiying non-zero values for ACCRUAL, DROPOUT and INFCENSOR, the program creates a 
                    one time dataset of incomplete data refleting 1) administrative censoring due to staggered entry,
                    2) non-informative dropout due to events unrelated to eGFR and 3) informative dropout due to ESKD.
                    If one specifies DROPOUT = 0 and INFCENSOR=NO then only incomplete data due to staggered entry 
                    is accounted for in the power calculations. By specifying ACCRUAL = 0, DROPOUT = 0 and 
                    INFCENSOR = NO, the power calculations are based on the a balanced and complete dataset with 
                    all subjects assumed to have complete eGFR measurements at each of the intended time points.   
      Alpha=      -Specified two-sided type I error or alpha level 
                   DEFAULT VALUE: Alpha = 0.05
      DDF=        -Defines what denominator degrees of freedom (DDF) one wishes to use when calculating power.
                   The options are: 
                    1) DDF=MIXED    which uses the default DDF of PROC MIXED 
                    2) DDF=NLMIXED  which uses the default DDF of PROC NLMIXED (DDF = 2N-3)  
                   DEFAULT VALUE: DDF = NLMIXED   ( = Number of subjects - Number of random effects = 2N-3 ).   
      N=          -Specified sample size per group assuming equal allocation
                   WARNING: One MUST use the syntax N = n1 TO n2 BY k as this is called from within PROC IML which
                            requires such syntax. If one wishes to specify only one value for N, say N=100, then 
                            specifiy N = 100 to 100. 
      Seed=       -Defines a seed number used to generate 2*N multivariate normal random effect vectors
                   DEFAULT VALUE: SEED = 12345    ( The user may choose any number )
      Close=      -Define whether one prints PROC MIXED output. The options are
                    1) CLOSE=       which causes MIXED output to be printed 
                    2) CLOSE=close= which prevents MIXED output from printing
                   DEFAULT VALUE: CLOSE=close   
      Check=      -Defines whether a printout of a dataset is done to check that dropout is working correctly
                    1) CHECK = NO
                    2) CHECK = YES
                   DEFAULT VALUE: CHECK = NO      ( WARNING: One should only use this one time as a check of program ).
      Print=      -Defines whether power of F-tests and t-tests are printed out to an RTF file. Options are
                    1) PRINT = NO
                    2) PRINT = YES
                   NOTE: If one specifies the DIFF = option then a second macro variable PRINT1 is created
                         with PRINT1 = NO so as to not print out the individual F-Test and t_test power results
                         but if PRINT = YES then the power estimates based on the DIFF option are printed.  
                         One can always print the results based on the created datasets if one chooses. 
                         The created datasets based on one call to the macro are: 
                            F_Tests              (when DIFF= is left blank)
                            t-Tests              (when DIFF= is left blank)
                            All_t_Tests_Update   (when DIFF= is specified)                            
                   DEFAULT VALUE: PRINT = YES     
      Table_F=    -Defines a Table numbering description for printing F-test power estimates by N
                   DEFAULT VALUE: Table_F = 1     
      Table_t=    -Defines a Table numbering description for printing equivalent t-test power estimates by N
                   DEFAULT VALUE: Table_t = 2     
     Directory=   -Defines a user-defined directory to store RTF generated summary tables of power estimates
                   EXAMPLE: DIRECTORY = d:\Stat in Med  
      Filename=   -Defines a user-defined filename for the RTF summary tables to be placed in the DIRECTORY=
                   EXAMPLE: FILENAME = GFR Slope Power Estimates 
 =============================================================================================================*/
%global data knot beta0 beta1c beta1t beta2c beta2t Var_e Var_u0 Var_u1 Var_u2 Cov_u0u1 Cov_u0u2 Cov_u1u2 
		kappa theta DIFF Months POM Reps LowerGFR UpperGFR Screen Accrual Followup Dropout InfCensor Alpha DDF N
		Seed Close Check Print Print1 Table_F Table_t Directory Filename beta1c_yr beta1t_yr beta2c_yr dropout_pct;

options spool symbolgen mprint ps=60 ls=120 papersize=LETTER spool nodate ;


/*===========================================================================================================
  The initial default values of the macro variables are taken from the results of the IDNT study (Table 5)
===========================================================================================================*/
%macro GFR_Slope_Power(Data=CKD, knot=4, beta0=50.00, beta1c=-1.038, beta1t=-1.227, beta2c=0.579, beta2t=0.834,
	Var_e=3.355, Var_u0=327.977, Var_u1=1.034, Var_u2=0.794, Cov_u0u1=1.831, Cov_u0u2=-2.265, 
	Cov_u1u2=-0.863, kappa=0.028, theta=0.922, DIFF=, Months=%str(0,3,6,12,18,24,30,36,42,48,54),
	POM=PA, Reps=0, LowerGFR=15, UpperGFR=120, Screen=100, Accrual=0 , Followup=60, Dropout=0.00, InfCensor=NO, 
	Alpha=0.05, DDF=NLMIXED, N=300 to 600 by 100, Seed=12345, Close=close, Check=NO, Print=YES, 
    Table_F=1, Table_t=2, Directory=d:\Stat in Med, Filename=GFR Slope Power Estimates);

	%let POM=%upcase(&POM);
	%let InfCensort=%upcase(&InfCensor);
	%let DDF=%upcase(&DDF);
	%let Check=%upcase(&Check);
	%let Print=%upcase(&Print);
	%let Print1=%upcase(&Print);
	%if %length(&DIFF) %then %let Print1=NO;  ** Do NOT print individual F-test and t-test powers;
	%if %index(&POM, PA) %then %let Reps=0;   ** Set Reps=0 if POM=PA is specified.;
	%if %index(&POM, EM) and &Reps=0 %then 
        %let Reps=500;                        ** Set Reps=500 if POM=EM is specified.;
	%if %index(&POM, 0) %then %let THETA=0;   ** Set THETA = 0 for a 0-POM strutcture with a common variance.;
	%if &THETA = 0 %then %let POM=0;          ** POM structure is POM=0 for independence with common variance;

	proc format;
	 PICTURE PowerF 0-<0.99='9.999' 0.99<-high='>0.99'(noedit);                                              
	run; 

	data dropout_pct;
	 dropout_pct=&dropout;
	 dropout_pct=100*dropout_pct;
	 dropout_pct=round(dropout_pct, 1);
	 call symput("dropout_pct",compress(left(dropout_pct))); 
	run;


	/*=============================================
	  Start of MACRO Sub-program to Calculate Power 
	==============================================*/ 
	%macro CalcPower;
		data CovParms0;
		 do Trt='Control', 'Treated';
			 if Trt='Control' then Group='Trt Control';
			 if Trt='Treated' then Group='Trt Treated';
			 Var_e=&Var_e;                     ** Var_e is within-subject sigma**2;
			 Var_u0=&Var_u0;                   ** Var_u0 for Control group;               
			 Var_u1=&Var_u1;                   ** Var_u1 for Control group;   
			 Var_u2=&Var_u2;                   ** Var_u2 for Control group;   
			 Cov_u0u1=&Cov_u0u1;               ** Cov_u0u1 for Control group;   
			 Cov_u0u2=&Cov_u0u2;               ** Cov_u0u1 for Control group;   
			 Cov_u1u2=&Cov_u1u2;               ** Cov_u0u1 for Control group;   
			 theta=&theta;                     ** POM parameter theta; 
			 kappa=&kappa;
			 Phi_k=1 + kappa*(Trt='Treated');  ** See Table 1 of paper for definition of Phi_k; 

		     Var_b0=Var_u0;                    ** Var_b0 for Control and Treated groups;               
			 Var_b1=Var_u1*(Phi_k**2);         ** Var_b1 for Control group;   
			 Var_b2=Var_u2*(Phi_k**2);         ** Var_b2 for Control group;   
			 Cov_b0b1=Cov_u0u1*Phi_k;          ** Cov_b0b1 for Control group;   
			 Cov_b0b2=Cov_u0u2*(Phi_k**2);     ** Cov_b0b2 for Control group;   
			 Cov_b1b2=Cov_u1u2*(Phi_k**2);     ** Cov_b1b2 for Control group; 
		 output;
		 end;
		 run;

		 data Screen;
		  do N = &N;                           ** Target number of subjects per group;
		   Screen = &Screen;                   ** Additional number of subjects to screen out eGFR<15 at start;
		   TotalN = 2*(N + Screen);            ** Total number of subjects screened initially;
		   beta0=&beta0;
		   Var_u0 = &Var_u0;
		   SD_u0 = sqrt(Var_u0);
		   LowerGFR = &LowerGFR;
		   UpperGFR = &UpperGFR;
		   Prob_LowerGFR = probnorm((LowerGFR - beta0)/SD_u0);
		   Prob_UpperGFR = 1-probnorm((UpperGFR - beta0)/SD_u0);
		   Expected_Failed = ceil( TotalN*(Prob_LowerGFR + Prob_UpperGFR) );
		   Expected_LT_GFR = ceil( TotalN*(Prob_LowerGFR) );
		   Expected_GT_GFR = ceil( TotalN*(Prob_UpperGFR) );
		   MaxScreen=Screen+Expected_Failed+10;** A Cushion against Screen=0;
		   output;
		  end;
		 run;

		 proc sort data=Screen;
		  by MaxScreen;
		 run;
		 data MaxScreen;
		  set Screen end=last;
		  by MaxScreen;
		  if last then do;
	       call symput("MaxScreen",compress(left(MaxScreen))); 
		  end;
		 run;

		 %put NOTE: New Screening Value = &MaxScreen ;

		/*==================================================================
		      Define Starting values of variance-covariance parameters  
          --------------------------- CAUTION ------------------------------
		  NOTE: The residual variance parameter, Var_e, used as input in the 
		        examples provided in this file is assumed to be the
		        value obtained by scaling the intra-subject POM variance 
		        structure as
		           (sigma_sq/100)*[mu_ij**2]**theta 
		        as opposed to 
		           (sigma_sq)*[mu_ij**2]**theta. 
		        The reason, as explained in the paper (section 4.1) is the 
                need to scale all of the model parameters so that they are 
                not more than a few orders of magnitude apart as otherwise
		        one will likely run into computational problems associated
		        with NLMIXED when running the SAS program, 
                 "SIM Supplement - SAS code for MDRD-B Example.sas:
		        which has also been made available for fitting the various 
		        shared parameter models described in the paper and which 
		 		is also provided as part of the supplementary material. 
		        The reason sigma_sq is re-scaled is the actual value on the
		        scale of the eGFR measurements is of order 0.01 or less than
		        the order of the other parameters (slopes and intercepts).  
                For example, in the IDNT study the estimated value of Var_e 
		        (sigma_sq in the paper) under SP model 2 was 3.355. This value
		        reflects the fact that the unscaled value is actually 0.03355    
		        when scaled according to the eGFR unit of measurement. It had  
		        to be scaled up by a factor of 100 within NLMIXED in order for 
		        all the model parameters to fall within a reasonable range of
		        magnitude so as to avoid problems with convergence (the order
		        of magnitude is four-fold between 0.03355 and the variance 
		        psi11=327.977 of the random intercept effect under SP model 2.  
		        Within this macro, however, we need to rescale Var_e back so 
		        as to be consistent with the eGFR unit of measurement in 
		        conjunction with the use of PROC MIXED to compute power.    
		==================================================================*/
		data CovParms0;
		 set CovParms0;
	 	 CovParm ='UN(1,1) ';*Subject='Subject(Trt)'; Estimate=Var_b0;   		output;
		 CovParm ='UN(2,1) ';*Subject='Subject(Trt)'; Estimate=Cov_b0b1; 		output;
		 CovParm ='UN(2,2) ';*Subject='Subject(Trt)'; Estimate=Var_b1;   		output;
		 CovParm ='UN(3,1) ';*Subject='Subject(Trt)'; Estimate=Cov_b0b2; 		output;
		 CovParm ='UN(3,2) ';*Subject='Subject(Trt)'; Estimate=Cov_b1b2; 		output;
		 CovParm ='UN(3,3) ';*Subject='Subject(Trt)'; Estimate=Var_b2;   		output;
		 CovParm ='Residual';*Subject='            '; Estimate=Var_e/100;		output;
		run;
		data CovParms0;
		 set CovParms0;
	 	 keep CovParm Trt Estimate;
		run;
		data CovParms;
		 set CovParms0;
		 do N=&N;                              ** Sample Size per group;
		   TotalN=2*N;                         ** Total Number of Subjects;
		   knot=&knot;
		   output;
		 end;
		run;
		data CovParms;
		 set CovParms;
		 if Trt='Control' and CovParm='Residual' then delete; 
		 if Trt='Treated' and CovParm='Residual' then Trt=' '; 
		run;

		proc sort data=CovParms;
		 by TotalN knot;
		run;

		/*=== Generate MVN(0,PSI) random effects vectors for possible use in defining dropout ===*/ 
		PROC IML;
		call randseed(&seed, 1);
		out={0 0 0 0 0 0 0 0 0 0 0};
		outREP_c ={0 0 0};                   ** replicated random effecst for Control group marginal weights; 
		outREP_t ={0 0 0};                   ** replicated random effecst for Treated group marginal weights; 
		Mean = {0 0 0};
		psi11=&Var_u0;                       ** Var_u0 for Control group;               
		psi22=&Var_u1;                       ** Var_u1 for Control group;   
		psi33=&Var_u2;                       ** Var_u2 for Control group;   
		psi12=&Cov_u0u1;                     ** Cov_u0u1 for Control group;   
		psi13=&Cov_u0u2;                     ** Cov_u0u2 for Control group;   
		psi23=&Cov_u1u2;                     ** Cov_u1u2 for Control group; 
		beta0=&beta0;                        ** Common intercept;
		beta1c=&beta1c;                      ** Acute slope for Control group;
		beta1t=&beta1t;                      ** Acute slope for Treated group;
		beta2c=&beta2c;                      ** Delta slope for Contold group;
		beta2t=&beta2t;                      ** Delta slope for Treated group;
		kappa=&kappa;                        ** Kappa;
		theta=&theta;                        ** Theta;
		knot=&knot;                          ** Knot; 
		Phi_c=1;
		Phi_t=1 + kappa;
		PSI_c = {&Var_u0 &Cov_u0u1 &Cov_u0u2, &Cov_u0u1 &Var_u1 &Cov_u1u2, &Cov_u0u2 &Cov_u1u2 &Var_u2};
		PSI_t = (Phi_t**2)*PSI_c;
		PSI_t[1,1] = PSI_t[1,1]/(Phi_t**2);
		PSI_t[1,2] = PSI_t[1,2]/Phi_t;
		PSI_t[1,3] = PSI_t[1,3]/Phi_t;
		PSI_t[2,1] = PSI_t[2,1]/Phi_t;
		PSI_t[3,1] = PSI_t[3,1]/Phi_t;
		M=&Reps;                             ** M = number of replicated random effects per treatment group;

		%if %index(&POM, EM) %then %do;
		u_c=RandNormal(M,Mean, PSI_c);       ** M replicate random effects (b0i, b1i, b2i) for Control group; 
		u_t=RandNormal(M,Mean, PSI_t);       ** M replicate random effects (b0i, b1i, b2i) for Treated group; 
		%end;

		do N = &N;                           ** Target number of subjects per group;
		    Screen = &MaxScreen;             ** Additional number of subjects to screen out eGFR<15 at start;
		    TotalN = 2*(N + Screen);         ** Total number of subjects screened initially;
			Accrual=&Accrual;                ** Accrual period (in months);
			Followup=&Followup;              ** Followup period (in months);
			AccrualRate=TotalN/Accrual;      ** Accrual rate (subjects per month);
			StudyTime=Accrual+Followup;      ** Total study time in months;
			Dropout = &Dropout;              ** Expressed as expected proportion of dropouts per 12 months;
			DropoutRate=-log(1-Dropout)/12;  ** EXAMPLE: If Dropout = 0.10 so that 10% of subjects dropout in 
			                                             12 months, then DropoutRate = -log(0.90)/12 = 0.00878 under
			                                             an exponential distribution with constant dropout rate; 

			if DropoutRate>0 then do;        ** Ignore dropout if DropoutRate = 0 (i.e., Dropout=0); 
			 lambda = 1/DropoutRate;         ** For use with RANDGEN function for exponential dropout; 
 			 DropoutMonth=J(TotalN,1);
 			 call randgen(DropoutMonth, "Exponential", lambda);
			end;
			else if DropoutRate=0 then do;   ** Set DropoutMonth = StudyTime (censor followup on all subjects); 
			 lambda = 0;                      
			 DropoutMonth=J(TotalN, 1, StudyTime);
			end;
			StartupMonth=J(TotalN,1);        ** Used to conmpute time in study based on staggered entry due to accrual;
			call randgen(StartupMonth, "Uniform", 0, Accrual); 

			u=RandNormal(TotalN,Mean,PSI_c); ** Random effects (u0i, u1i, u2i) for TotalN = 2N subjects;

			/* Define a Screened Subject ID */
			ScreenID=J(TotalN, 1, 0);
			do i=1 to TotalN;
			 ScreenID[i, 1] = i;
			end;

			/* Define individual subject times based on accrual and dropout */
			MaxStudyTime = (Accrual - StartupMonth) + Followup;      
		 	DropoutTime  = DropoutMonth;                  
			SubjectTime  = J(TotalN,1);
			SubjectDropout = J(TotalN,1);
			do i=1 to TotalN;
			 SubjectTime[i] = Min(MaxStudyTime[i], DropoutTime[i]);
			 if DropoutTime[i]<MaxStudyTime[i] then SubjectDropout[i]=1;
			 else if DropoutTime[i]>=MaxStudyTime[i] then SubjectDropout[i]=0;
			end;

			SampleMean = mean(u);
			SampleCov = cov(u);
			_N_  = J(TotalN, 1, N);
			_TotalN_  = J(TotalN, 1, TotalN);
		*	print N TotalN SampleMean Mean, SampleCov PSI_c, ScreenID u SubjectTime SubjectDropout;
		    out=out//(_N_||_TotalN_||ScreenID||u||StartupMonth||MaxStudyTime||DropoutTime||SubjectTime||SubjectDropout);
		    names={N TotalN ScreenID u0i u1i u2i StartupMonth MaxStudyTime DropoutTime SubjectTime SubjectDropout};    
		    create random_effects from out[colname=names];
		    append from out;
		    close random_effects;

			/* Output datasets outREP_c and outREP_t when M>0 */ 
			%if %index(&POM, EM) %then %do;
		    outREP_c=outREP_c//(u_c);
		    name_c={b0_c b1_c b2_c};    
		    create Control_RE from outREP_c[colname=name_c];
		    append from outREP_c;
		    close Control_RE;

		    outREP_t=outREP_t//(u_t);
		    name_t={b0_t b1_t b2_t};    
		    create Treated_RE from outREP_t[colname=name_t];
		    append from outREP_t;
		    close Treated_RE;
			%end;
		end;
		run;
		quit;

		data random_effects;
		 set random_effects;
		 if TotalN=0 then delete;
		run;


		data random_effects;
		 set random_effects;
		 beta0=&beta0;
		 LowerGFR=&LowerGFR;                   ** Lower GFR used for screening;
		 UpperGFR=&UpperGFR;                   ** Upper GFR used for screening;
		 eGFRij_0 = beta0 + u0i;               ** Starting eGFR measured without error at baseline;
		 if LowerGFR< eGFRij_0 <UpperGFR then
		    Status='Keep';
		 else if eGFRij_0>UpperGFR or 
		         eGFRij_0<LowerGFR then
            Status='Drop';                     ** Screened subjects who meet GFR inclusion criteria; 
		run;

		proc means data=random_effects n mean min max maxdec=3 nway noprint;
		 where Status='Keep';
		 class TotalN; 
		 var eGFRij_0;
		 output out=passed n=screened mean=mean_eGFR min=min_eGFR max=max_eGFR;
		run;
		proc means data=random_effects n mean min max maxdec=3 nway noprint;
		 where Status='Drop';
		 class TotalN; 
		 var eGFRij_0;
		 output out=failed n=screened mean=mean_eGFR min=min_eGFR max=max_eGFR;
		run;

		/*	Too see what is happening with screening just run the following proc prints */
		/*
		proc print data=passed;title 'Number of successful subjects screened'; run;
		proc print data=failed;title 'Number of failed subjects screened'; run;
		*/

		data random_effects;
		 set random_effects;
		 if Status='Keep';
		 TotalN = 2*N;                         ** Total number of subjects (sample size) proposed for a study;
		run;
		proc sort data=random_effects;
		 by TotalN ScreenID;
		run;
		data random_effects;
		 set random_effects;
		 by TotalN ScreenID;
		 retain Subject 0;
		 if first.TotalN then Subject=0;
         Subject+1;
		run;
		proc sort data=random_effects;
		 by TotalN Subject;
		run;
		data random_effects;
		 set random_effects;
		 by TotalN Subject;
		 if Subject<=TotalN;
		run;

		*proc print data=random_effects(obs=100);
		run;

		/*=========================================== 
		 Define one time estimates of the marginal 
		 weights of the within-subject R matrix as
		 an approximation to E[(mu_ij**2)**theta]
		===========================================*/
		%if %index(&POM, EM) %then %do;
		data REout;
		 set Control_RE(in=a) Treated_RE(in=b);
		 if a then do; 
		   Trt='Control';
		   b0i=b0_c;
		   b1i=b1_c;
		   b2i=b2_c;
		 end;
		 if b then do; 
		   Trt='Treated';
		   b0i=b0_t;
		   b1i=b1_t;
		   b2i=b2_t;
		 end;
		run;
		data REout;
		 set REout;
		 if b0i=0 and b1i=0 and b2i=0 then delete;
		run;

		data PA_weights;
		 set REout;
		 knot=&knot;                           ** Defines the knot;
		 kappa=&kappa;                         ** Defines the value of kappa;
		 theta=&theta;                         ** Defines the value of theta;
	     Xi=(Trt='Treated');                   ** Indicator function for Treated group (see Equation (4) of paper);
		run;

		data PA_weights;
		 set PA_weights;
		 do Month=&Months;                     ** Design points (months);
		     Month_t = MAX(0,Month-knot);      ** Truncated line function for a linear spline model at Month=knot;
		     beta0=&beta0;                     ** Assumed common intercept for Control and Treated subjects;
		     if Trt='Control'  then do;        ** Assumed acute and delta (change) slopes for Control group; 
		        beta1 = &beta1c;
		        beta2 = &beta2c;
		     end; 
		     if Trt='Treated'  then do;        ** Assumed acute and delta (change) slopes for Treated group; 
		        beta1 = &beta1t;
		        beta2 = &beta2t;
		     end; 
		     wt_ij = (( (beta0+b0i) + (beta1+b1i)*Month + (beta2+b2i)*Month_t )**2)**theta;
			 output;
		 end;
		run;
		*proc print data=PA_weights(obs=100);
		run;
		proc means data=PA_weights noprint nway mean;
		 class Trt Month;
		 var wt_ij;
		 output out=Marginal_Weights mean=_Wt_;
		run;
		*proc print data=Marginal_Weights;
		run;
		%end;

		data &data;
		 do N=&N;                              ** Number of subjects per group;
		  TotalN=N*2;                          ** Total Number of Subjects;
		  knot=&knot;                          ** Defines the knot;
		  kappa=&kappa;                        ** Defines the value of kappa;
		  theta=&theta;                        ** Defines the value of theta;
		  output;
		 end;
		run;

	 	proc sort data=&data;
		 by TotalN;
		run;
	 	proc sort data=random_effects;
		 by TotalN;
		run;
		data &data;
		 merge &data random_effects;
		 by TotalN;
		 if Subject<=N     then Trt='Control';
		 else if Subject>N then Trt='Treated';
	     Xi=(Trt='Treated');                   ** Indicator function for Treated group (see Equation (4) of paper);
		run;

		proc sort data=CovParms;
		 by TotalN;
		run;

		data outdata;
		 set &data;
		 do Month=&Months;                     ** Design points (months);
		     Month_t = MAX(0,Month-knot);      ** Truncated line function for a linear spline model at Month=knot;
		     Year=Month/12;                    ** Year defined as Month/12;
		     beta0=&beta0;                     ** Assumed common intercept for Control and Treated subjects;
		     if Trt='Control'  then do;        ** Assumed acute and delta (change) slopes for Control group; 
		        beta1 = &beta1c;
		        beta2 = &beta2c;
		     end; 
		     if Trt='Treated'  then do;        ** Assumed acute and delta (change) slopes for Treated group; 
		        beta1 = &beta1t;
		        beta2 = &beta2t;
		     end; 
		     mu = beta0 + beta1*Month + beta2*Month_t;
			                                   ** PA predicted mean response over time as a linear function of Trt;
		     eGFR=mu;                          ** Expected value of eGFR using Walt Stroup power calculations;    
		     Var_e=&Var_e;                     ** Var_e;     
		     Var_u0=&Var_u0;                   ** Var_u0 for Control group;               
			 Var_u1=&Var_u1;                   ** Var_u1 for Control group;   
			 Var_u2=&Var_u2;                   ** Var_u2 for Control group;   
			 Cov_u0u1=&Cov_u0u1;               ** Cov_u0u1 for Control group;   
			 Cov_u0u2=&Cov_u0u2;               ** Cov_u0u1 for Control group;   
			 Cov_u1u2=&Cov_u1u2;               ** Cov_u0u1 for Control group;   

			 Phi_k=1 + kappa*(Trt='Treated');  ** See Table 1 of paper for definition of Phi_k; 

		     Var_b0=Var_u0;                    ** Var_b0 for Control and Treated groups;               
			 Var_b1=Var_u1*(Phi_k**2);         ** Var_b1 for Control and Treated groups;   
			 Var_b2=Var_u2*(Phi_k**2);         ** Var_b2 for Control and Treated groups;   
			 Cov_b0b1=Cov_u0u1*Phi_k;          ** Cov_b0b1 for Control and Treated groups;   
			 Cov_b0b2=Cov_u0u2*(Phi_k**2);     ** Cov_b0b2 for Control and Treated groups;   
			 Cov_b1b2=Cov_u1u2*(Phi_k**2);     ** Cov_b1b2 for Control and Treated groups;   
			 Var_Error_1=Var_e*(mu**2)**theta; ** Within-subject variance based on a marginal POM structure
			                                      obtained by setting the SS random effects to 0;
		     output;
		 end;
		run;

		data outdata;
		 set outdata;
		 by TotalN;
		run;

		%if %index(&POM, EM) %then %do;
		proc sort data=outdata;
		 by Trt Month;
		run;
		proc sort data=Marginal_Weights;
		 by Trt Month;
		run;
		data Marginal_Weights;
		 set Marginal_Weights;
		 by Trt Month;
		 keep Trt Month _Wt_;
		run;
		data outdata; 
		 merge outdata(in=a) Marginal_Weights(in=b);
		 by Trt Month;
		 Var_Error_3 = Var_e*_Wt_;
		run;
		%end;

		proc sort data=outdata;
		 by N TotalN knot Trt Subject Month;
		run;

		data outdata;
		 set outdata;
		 by N TotalN knot Trt Subject Month;
		 /*=== Create subject-specific random effects for possible use in defining dropout ===*/
		 b0i = u0i*(1+kappa*(Trt='Treated'));
		 b1i = u1i*(1+kappa*(Trt='Treated'));
		 b2i = u2i*(1+kappa*(Trt='Treated'));
		 mu_ij = (beta0+b0i) + (beta1+b1i)*Month + (beta2+b2i)*Month_t;
		 ESKD=0;                               ** Define ESKD=0 if eGFR>=15 and ESKD=1 as soon as eGFR<15;
		 DropoutStatus=0;                      ** Define DropoutStatus=0 if complete data, 1 if SubjectTime<Month;
		 %if %index(&InfCensor, YES) %then %do;
		 if mu_ij<15 then ESKD=1;              ** Drop subject visits once the SS predicted eGFR<15 mL/min/1.73m2 
		                                          reflecting informative dropout due to ESRD;
		 %end;
		 if Month>SubjectTime then 
            DropoutStatus=1;                   ** Drop subject visits where SubjectTime < current month with
		                                          SubjectTime determined by Accrual and Dropout options;
		 %if %index(&POM, PA) %then %do;
		 Wt = 1/((mu**2)**theta);              ** PA-POM Within-subject fixed weights for MIXED; 
		 %end;
		 %else %if %index(&POM, EM) %then %do;
		 Wt = 1/_Wt_;                          ** EM-POM weights based on E((mu_ij**2)**theta) for MIXED; 
		 %end;
		 %else %if %index(&POM, 0) %then %do;
		 Wt = 1;                               ** 0-POM weights based on E((mu_ij**2)**0)=1 for MIXED; 
		 %end;
		run;

		 /*=== The following code provides a logic check to see if things are working as intended ===*/
		%if %index(&check, YES) %then %do;
		data checkdata;
		 set outdata;
		 if ESKD=1 or DropoutStatus=1 or SubjectDropout=1; 
		 keep N Trt Subject Month eGFR mu mu_ij StartupMonth MaxStudyTime SubjectTime 
              DropoutTime ESKD DropoutStatus SubjectDropout;
		run;
		proc sort data=checkdata;
		 by N Trt Subject Month;
		run;
		data checkdata;
		 set checkdata;
		 by N Trt Subject Month;
		 if first.Subject;
		run;
		proc print data=checkdata(obs=50);
		 var N Trt Subject Month eGFR mu mu_ij StartupMonth MaxStudyTime SubjectTime 
              DropoutTime ESKD DropoutStatus SubjectDropout;
		 title 'List of subjects who dropout, when and why'; 
		run;
		proc means data=checkdata n mean std maxdec=3;
		 class N Trt ESKD SubjectDropout;
		 var MaxStudyTime SubjectTime;
		run;
		%end;
		 /*=== Create a final dataset for power calculations by censoring subjects who dropout ===*/
		data outdata;
		 set outdata;
		 if ESKD=1 then delete;                ** Drop planned visit months once ESKD occurs;
		 if DropoutStatus=1 then delete;       ** Drop planned visit months once SubjectTime occurs;
		run;

		/*=== Run the linear spline mixed-effects regression model using PROC MIXED ===*/
		proc sort data=outdata;
		 by N TotalN knot Trt Subject Month;
		run;
		ods listing &close;
		ods output SolutionF=pe SolutionR=re Contrasts=F_tests Estimates=t_Tests CovParms=cov CovB=Omega; 
		proc mixed data=outdata noprofile;
		 by N TotalN knot;
		 class Trt Subject ;
		 model eGFR = Trt Trt*Month Trt*Month_t / noint s chisq covb ;
		 random Intercept Month Month_t / group=Trt type=un subject=Subject(Trt) G V Vcorr s;
		 parms / parmsdata=CovParms noiter;
		 weight Wt;
		 contrast "H0: No Intercept Effect" Trt -1 1; 
		 contrast "H1: No Acute Slope Effect" Trt*Month -1 1;  
		 contrast "H1a: No Acute Trt Effect" Trt*Month -&knot &knot;  
		 contrast "H2: No Delta Slope Effect" Trt*Month_t -1 1;  
		 contrast "H3: No Chronic Slope Effect" Trt*Month -1 1 Trt*Month_t -1 1;
		/* THE FOLLOWING COMMENTED OUT ORIGINAL CODE DID NOT ALLOW THE MACRO VARIABLE KNOT TO BE USED */
		*contrast "H4a: No Total Slope Effect (2 Yrs)" Trt*Month -1 1 Trt*Month_t -0.8333 + 0.8333;
		*contrast "H4b: No Total Slope Effect (3 Yrs)" Trt*Month -1 1 Trt*Month_t -0.8888 + 0.8888;
		*contrast "H4c: No Total Slope Effect (4 Yrs)" Trt*Month -1 1 Trt*Month_t -0.9166 + 0.9166;
		 contrast "H4a: No Total Slope Effect (2 Yrs)" Trt*Month -1 1 Trt*Month_t %SYSEVALF(-1 + &knot/24) + 
                                                                                  %SYSEVALF( 1 - &knot/24);
		 contrast "H4b: No Total Slope Effect (3 Yrs)" Trt*Month -1 1 Trt*Month_t %SYSEVALF(-1 + &knot/36) + 
                                                                                  %SYSEVALF( 1 - &knot/36);
		 contrast "H4c: No Total Slope Effect (4 Yrs)" Trt*Month -1 1 Trt*Month_t %SYSEVALF(-1 + &knot/48) + 
                                                                                  %SYSEVALF( 1 - &knot/48);

		 estimate "Treated Group Acute Slope" Trt*Month 0 1;
		 estimate "Control Group Acute Slope" Trt*Month 1 0;
		 estimate "Treated Group Delta Slope" Trt*Month_t 0 1;
		 estimate "Control Group Delta Slope" Trt*Month_t 1 0;
		 estimate "Treated Group Chronic Slope" Trt*Month 0 1 Trt*Month_t 0 1;
		 estimate "Control Group Chronic Slope" Trt*Month 1 0 Trt*Month_t 1 0;
		 estimate "Treated Group Total Slope (2 Yrs)" Trt*Month 0 1 Trt*Month_t 0 %SYSEVALF(1 - &knot/24);
		 estimate "Control Group Total Slope (2 Yrs)" Trt*Month 1 0 Trt*Month_t %SYSEVALF(1 - &knot/24) 0;
		 estimate "Treated Group Total Slope (3 Yrs)" Trt*Month 0 1 Trt*Month_t 0 %SYSEVALF(1 - &knot/36);
		 estimate "Control Group Total Slope (3 Yrs)" Trt*Month 1 0 Trt*Month_t %SYSEVALF(1 - &knot/36) 0;
		 estimate "Treated Group Total Slope (4 Yrs)" Trt*Month 0 1 Trt*Month_t 0 %SYSEVALF(1 - &knot/48);
		 estimate "Control Group Total Slope (4 Yrs)" Trt*Month 1 0 Trt*Month_t %SYSEVALF(1 - &knot/48) 0;

		 estimate "H1: No Acute Slope Effect" Trt*Month -1 1;  
		 estimate "H1a: No Acute Trt Effect" Trt*Month -&knot &knot;  
		 estimate "H2: No Delta Slope Effect" Trt*Month_t -1 1;  
		 estimate "H3: No Chronic Slope Effect" Trt*Month -1 1 Trt*Month_t -1 1;
		 estimate "H4a: No Total Slope Effect (2 Yrs)" Trt*Month -1 1 Trt*Month_t %SYSEVALF(-1 + &knot/24) + 
                                                                                  %SYSEVALF( 1 - &knot/24);
		 estimate "H4b: No Total Slope Effect (3 Yrs)" Trt*Month -1 1 Trt*Month_t %SYSEVALF(-1 + &knot/36) + 
                                                                                  %SYSEVALF( 1 - &knot/36);
		 estimate "H4c: No Total Slope Effect (4 Yrs)" Trt*Month -1 1 Trt*Month_t %SYSEVALF(-1 + &knot/48) + 
                                                                                  %SYSEVALF( 1 - &knot/48);
		run;

		/*================================================= 
		  F-tests based on CONTRAST statements are useful 
		  if there are three or more treatment groups in 
		  which case one would need to modify the program  
	      to allow for three or more groups. 
		=================================================*/
		data F_Tests;    ** For F-tests *;
		 length Dropout $3;
		 set F_Tests;
		 by N TotalN knot;
		 Alpha=&alpha;
		 NDF=NumDF;
		 %if %index(&DDF, MIXED) %then %do;
	 	 DDF=DenDF;      ** PROC MIXED default DF;
		 %end;
		 %if %index(&DDF, NLMIXED) %then %do;
	 	 DDF=TotalN-3;   ** PROC NLMIXED default DF;
		 %end;
		 NC = NDF*FValue;
		 FCrit = FINV(1-Alpha, NDF, DDF,0);
		 Power=1-ProbF(FCrit,NDF,DDF,NC);
		 if Power>0.999 or Power=. then Power=0.999;
		 Hypothesis=Label;
		 POM="&POM";
		 Dropout=&dropout;
		 InfCensor="&InfCensor";
		 if Label in ("H1a: No Acute Trt Effect") then delete;
		run;

		/*================================================= 
		  t-tests based on ESTIMATE statements are useful 
		  if there are only two treatment groups in which
	      case summary results can be based on the assumed  
	      population slopes and their differences. The power
		  estimates are exactly the same as for the F-tests
		  provided there just two treatment groups.
		=================================================*/
		data t_Tests;    ** For t-tests *;
		 length Group $15 Dropout $3;
		 set t_Tests;
		 by N TotalN knot;
		 if Label in ( "Treated Group Intercept" "Treated Group Acute Slope" "Treated Group Delta Slope" "Treated Group Chronic Slope"
		               "Control Group Intercept" "Control Group Acute Slope" "Control Group Delta Slope" "Control Group Chronic Slope"
		               "Control Group Total Slope (2 Yrs)" "Control Group Total Slope (3 Yrs)" "Control Group Total Slope (4 Yrs)"
		               "Treated Group Total Slope (2 Yrs)" "Treated Group Total Slope (3 Yrs)" "Treated Group Total Slope (4 Yrs)" )
	     then do;
			Group = scan(Label, 1); 
			Slope = substr(Label, 15);  
	     end; 
		 else do;
			Group = 'Treated-Control';	
			if Label in ("H1a: No Acute Trt Effect") then do;
			Slope= scan(Label, 3)||' '||scan(Label, 4)||' '||scan(Label, 5);  
			end;
			else do;
			Slope = scan(Label, 3)||' '||scan(Label, 4)||' '||substr(Label, 28);  
			end;
	     end; 
		 if Label in ( "Treated Group Intercept" "Treated Group Acute Slope" "Treated Group Delta Slope" "Treated Group Chronic Slope"
		               "Control Group Intercept" "Control Group Acute Slope" "Control Group Delta Slope" "Control Group Chronic Slope"
		               "Control Group Total Slope (2 Yrs)" "Control Group Total Slope (3 Yrs)" "Control Group Total Slope (4 Yrs)"
		               "Treated Group Total Slope (2 Yrs)" "Treated Group Total Slope (3 Yrs)" "Treated Group Total Slope (4 Yrs)" )
	     then Description='Parameter Estimates';   
		 else Description='Tests of Hypotheses';  
		 Alpha=&alpha;
		 Fvalue=tValue**2;
		 NDF=1;
		 %if %index(&DDF, MIXED) %then %do;
	 	 DDF=DenDF;      ** PROC MIXED default DF;
		 %end;
		 %if %index(&DDF, NLMIXED) %then %do;
	 	 DDF=TotalN-3;   ** PROC NLMIXED default DF;
		 %end;
		 NC = NDF*FValue;
		 FCrit = FINV(1-Alpha, NDF, DDF,0);
		 Power=1-ProbF(FCrit,NDF,DDF,NC);
		 if Power>0.999 or Power=. then Power=0.999;
		 Hypothesis=Label;
		 POM="&POM";
		 Dropout=&dropout;
		 InfCensor="&InfCensor";
		run;

		/*================================================= 
		  Convert all slope-based parameters to be in units
		  of mL/min/1.73m2/year versus mL/min/1.73m2/month 
	      for the purpose of reporting.
		=================================================*/
		data t_Tests;
		 set t_Tests;
		 by N TotalN knot;
		 Alpha=&Alpha;
		 Estimate=Estimate*12;
		 StdErr = StdErr*12;
		 if Group in ('Treated' 'Control') then do;
	        Fvalue=.;
			NDF=.;
			DDF=.;
			NC=.;
			FCrit=.;
			Power=.;
		  end;
		run;
		proc sort data=t_Tests;
		 by N TotalN knot Slope Description Descending Group;
		run;
		/*=================================================
	      Datasets pe and pe_year list all model parameters.
		  All slope-based parameters are converted from units
		  of mL/min/1.73m2/month to mL/min/1.73m2/year 
	      for the purpose of reporting.
		=================================================*/
		data pe_year;
		 set pe;
		 by N TotalN knot;
		 if Effect in ('Month*Trt', 'Month_t*Trt') then do;
		  Estimate=Estimate*12;
		  StdErr = StdErr*12;
		 end;
		run;
		ods listing;
	%mend CalcPower;
	/*=============================================
	 End of MACRO Sub-program to Calculate Power 
	==============================================*/ 


	/*=============================================
	 Start of program set-up to calculate power
     and to summarize slopes and time to ESKD
     parameters for clinically relevant differences  
	==============================================*/ 
	data Slope_and_Time_Parameters;
	 beta0 = &beta0;
	 beta1c = &beta1c;
	 beta1t = &beta1t;
	 beta1c_yr = beta1c*12;
	 beta1t_yr = beta1t*12;
	 beta1c=round(beta1c, 0.001);
	 beta1t=round(beta1t, 0.001);
	 beta1c_yr=round(beta1c_yr, 0.001);
	 beta1t_yr=round(beta1t_yr, 0.001);
	 beta1_diff=beta1t-beta1c;
	 beta1_yr_diff=beta1t_yr-beta1c_yr;
	 beta2c = &beta2c;
	 beta2c_yr = beta2c*12;
	 beta2c_yr=round(beta2c_yr, 0.001);
	 beta3c = beta1c + beta2c;
	 beta3c_yr = beta3c*12;
	 beta3c_yr=round(beta3c_yr, 0.001);
	 beta2t = &beta2t;
	 beta2t_yr = beta2t*12;
	 beta2t_yr=round(beta2t_yr, 0.001);
	 knot=&knot;
	 beta3c = beta1c + beta2c;
	 beta3t = beta1t + beta2t;
	 Time_ESKD_c = (((beta0-beta2c*knot) - 15)/-beta3c)   ;
	 Time_ESKD_t = (((beta0-beta2t*knot) - 15)/-beta3t)   ;
     Delta_ESKD = (Time_ESKD_t - Time_ESKD_c)   ;
	 Time_ESKD_c_Yr = (((beta0-beta2c*knot) - 15)/-beta3c)/12;
	 Time_ESKD_t_Yr = (((beta0-beta2t*knot) - 15)/-beta3t)/12;
     Delta_ESKD_Yr = round( ((Time_ESKD_t - Time_ESKD_c)/12), 0.001);
	 call symput("beta1c_yr",compress(left(beta1c_yr))); 
	 call symput("beta1t_yr",compress(left(beta1t_yr))); 
	 call symput("beta1_yr_diff",compress(left(beta1_yr_diff))); 
	 call symput("beta2c_yr",compress(left(beta2c_yr))); 
	 call symput("beta3c_yr",compress(left(beta3c_yr))); 
	 call symput("Delta_ESKD_Yr",compress(left(Delta_ESKD_Yr))); 
	run;

	%if %length(&DIFF) %then %do; 
	data ALL_F_tests;set _null_;run;
	data ALL_t_tests;set _null_;run;
	data beta;
	 incr=0;
	 knot   = &knot;
	 beta0  = &beta0;
	 beta1c = &beta1c;
	 beta1t = &beta1t;
	 beta2c = &beta2c;
	 beta3c = beta1c + beta2c;  ** control group chronic slope;
	 do DIFF = &DIFF;           ** DIFF  = beta3t - beta3c = hypothesized chronic slope differences (treated-control);
	  beta3t = beta3c + DIFF;   ** beta3t = beta3c + DIFF;
	  beta2t = beta3t - beta1t; ** treated group delta slope = beta3t - beta1t;
	  incr+1;
	  output;
	 end;
	run;  

	data beta;
	 set beta end=last;
	 if last then do;
      call symput("No_incr",left(incr)); 
	 end;
	run;
	%end;  

	%else %do;
	data ALL_F_tests;set _null_;run;
	data ALL_t_tests;set _null_;run;
	data beta;
	 incr=1;
	 knot   = &knot;
	 beta0  = &beta0;
	 beta1c = &beta1c;
	 beta1t = &beta1t;
	 beta2c = &beta2c;
	 beta2t = &beta2t;
	 beta3c = beta1c + beta2c;  ** control group chronic slope;
	 beta3t = beta1t + beta2t;  ** treated group chronic slope;
	 beta3t_DIFF=beta3t-beta3c;
	 DIFF=beta3t-beta3c;
	 call symput("No_incr",left(incr)); 
	run;
	%end;
	/*
	proc print data=beta;
	  title "print of dataset beta 1st time based on macro variable DIFF = &DIFF";
	run;
	*/

	/*=============================================
	 Compute projected time to ESKD based on the
	 population-average intercepts and slopes and
	 compute the acute treament effect at the knot
	 which is (beta1t-beta1c)*knot in mL/min/1.73m2
	==============================================*/ 
	data beta;
	 set beta;
	 Time_ESKD_c = (((beta0-beta2c*knot) - 15)/-beta3c)   ;
	 Time_ESKD_t = (((beta0-beta2t*knot) - 15)/-beta3t)   ;
     Delta_ESKD  = (Time_ESKD_t - Time_ESKD_c)   ;
	 Time_ESKD_c_Yr = Time_ESKD_c/12;
	 Time_ESKD_t_Yr = Time_ESKD_t/12;
     Delta_ESKD_Yr  = (Time_ESKD_t - Time_ESKD_c)/12;
	 Acute_Trt_Effect = round( (beta1t-beta1c)*knot, 0.001);
	run;

	%put NOTE: incr = &No_incr;

	/*=============================================
	 Start incremental power calculations via the
	 Sub-Macro CalcPower
	==============================================*/ 
	%do incr = 1 %to &No_incr %by 1;
	 data beta3t_&incr;
	  set beta;
	  if incr=&incr;	  
	  call symput("beta2t",compress(left(beta2t)));
	  call symput("beta3c",compress(left(beta3c)));
	  call symput("beta3t",compress(left(beta3t)));
	  call symput("beta3_DIFF",compress(left(DIFF)));
	  call symput("acute_trt_effect",compress(left(acute_trt_effect)));
	 run; 
	 %put NOTE: incr= &incr  beta1t= &beta1t beta2t= &beta2t beta3t= &beta3t;
	 %CalcPower;
	 data F_Tests;
	   set F_Tests;
	   beta3_DIFF  = &beta3_DIFF;
	   beta3_DIFF_yr = beta3_DIFF*12;
	 run;
	 data t_Tests;
	   set t_Tests;
	   beta3_DIFF  = &beta3_DIFF;
	   beta3_DIFF_yr = beta3_DIFF*12;
	 run;
	 data ALL_F_Tests;
	   set ALL_F_Tests F_Tests;
	 run;
	 data ALL_t_Tests;
	   set ALL_t_Tests t_Tests;
	 run;
	%end; 
	/*=============================================
	 End incremental power calculations via the
	 Sub-Macro CalcPower
	==============================================*/ 

	/*==============================================
	 Programming options to print results of the 
	 power calculations based on MACRO options.
     CASE 1: Option for printing results from a 
	         single specification of slopes (ie., no
	         value assigned to macro variable DIFF)	          
	===============================================*/ 
	%if %index(&Print1, YES) %then %do;
		/*==========================================================
	 	  Code for creating RTF files with two tables summarizing 
	      power estimates based on F-tests (based on CONTRASTS) 
		  and t-tests (based on ESTIMATE statements)
		==========================================================*/
		proc sort data=F_Tests;
		 by N TotalN knot Hypothesis;
		run;
		title;
		ods rtf file="&directory\&filename..rtf"
		        style=Journal NOTOC_DATA BODYTITLE NOKEEPN;

		title1 "Table &Table_F";
		title2 "Approximate power of F-tests for comparing eGFR slope parameters (mL/min/1.73m2/year) between treatment";
		title3 "groups based on a linear spline mixed-effects model with specified model parameters, a knot at month &knot,";
	 	title4 "an accrual period of &accrual months, a followup period of &followup months, and designated sample sizes.";
		%if %index(&InfCensor, YES) %then %do;
		footnote1 "Power based on a &POM POM variance, a dropout rate of &dropout_pct% per year, and censoring due to ESKD.";
		%end;
		%if %index(&InfCensor, NO) %then %do;
		footnote1 "Power based on a &POM POM variance and a dropout rate of &dropout_pct% per year.";
		%end;

		proc report data=F_Tests HEADLINE nowindows HEADSKIP SPLIT='|' spacing=1;
			WHERE Hypothesis ne "H0: No Intercept Effect";
			COLUMN ("Estimated power for jointly testing the following null hypothesis at a type I error=&alpha."
	                "H0: No Differences in Slopes Between Two Treatment Groups (F-Test based on 1 DF)."
					" "
			         N Hypothesis alpha, (NDF DDF FCrit NC Power));
			DEFINE N / GROUP 'N per Group' width=12 format=12.0 center;
			DEFINE Hypothesis / GROUP 'Select|Hypotheses' width=35 ;
			DEFINE Alpha / ACROSS 'F-test type I error' width=25 center;
			DEFINE NDF / mean 'F-test|NDF' width=6 center format=3.0;
			DEFINE DDF / mean 'F-test|DDF' width=6 center format=5.0;
			DEFINE FCrit / mean "F-test|Critical|Value" width=10 center format=8.4;
			DEFINE NC / mean  'F-test|Noncentrality|Parameter' width=13 center format=10.4;
			DEFINE Power / mean 'Power' width=5 center format=PowerF.;
		run;
		quit;
		footnote;

		proc sort data=t_Tests;
		 by N TotalN knot Slope Description Descending Group;
		run;
		title;
		title1 "Table &Table_t";
		title2 "Approximate power of t-tests for comparing eGFR slope parameters (mL/min/1.73m2/year) between treatment";
		title3 "groups based on a linear spline mixed-effects model with specified model parameters, a knot at month &knot,";
	 	title4 "an accrual period of &accrual months, a followup period of &followup months, and designated sample sizes.";
	 	title5 "The Acute Trt Effect is the mean difference in eGFR (mL/min/1.73m2) at &knot months.";
		%if %index(&InfCensor, YES) %then %do;
		footnote1 "Power based on a &POM POM variance, a dropout rate of &dropout_pct% per year, and censoring due to ESKD.";
		%end;
		%if %index(&InfCensor, NO) %then %do;
		footnote1 "Power based on a &POM POM variance and a dropout rate of &dropout_pct% per year.";
		%end;
		footnote2 "An extended time to ESKD due to treatment is predicted to be, on average, &Delta_ESKD_Yr years";  
		footnote3 "where ESKD is defined to have occurred once eGFR reaches 15 mL/min/1.73m2.";  
		proc report data=t_Tests HEADLINE nowindows HEADSKIP SPLIT='|' spacing=1;
			COLUMN ("Power calculation results for jointly testing the following null hypothesis at a 2-sided type I error=&alpha."
	                "H0: No Differences in Slopes Between Two Treatment Groups (t-test)"
			         Slope Group Estimate N, (StdErr Power));
			DEFINE Slope / GROUP 'Slope|Parameter' width=20 center;
			DEFINE Group / GROUP 'Treatment|Comparison' width=15 center;
			DEFINE Estimate / GROUP 'Assumed|Value' width=7 center format=7.3;
			DEFINE N / ACROSS 'Sample Size per Group' width=25 center;
			DEFINE StdErr / mean "Standard|Error" width=8 center format=8.4;
			DEFINE Power / mean 'Power' width=7 center format=PowerF.;
		run;
		quit;
		footnote;
		ods rtf close;

	%end;

	/*================================================
	 Programming options to print results of the 
	 power calculations based on MACRO options.
     CASE 2: Option for printing results from a 
	         specification of different chronic slope
	         differences based on macro variable DIFF	          
	=================================================*/ 
	%if %length(&DIFF) %then %do; 
		data Time_to_ESKD;
		 set beta;
		 beta3_DIFF_yr = round(DIFF*12, 0.001);
		 Delta_ESKD_yr = round(Delta_ESKD_yr, 0.001);
		 ByVar = Compress(left(beta3_DIFF_yr));
		 keep ByVar beta3_DIFF_yr Delta_ESKD_yr;
		run;
		data ALL_t_Tests_Update; 
		 set ALL_t_Tests;
		 if Slope in ("Acute Slope" "Acute Trt Effect") then delete;
		 if Power>.;
		 beta3_DIFF_yr = round(beta3_DIFF_yr, 0.001);
		 ByVar = Compress(left(beta3_DIFF_yr));
		 keep ByVar beta3_DIFF_yr Slope Estimate N knot Group Power;
		run;
		proc sort data=Time_to_ESKD;
		 by ByVar;
		run;
		proc sort data=ALL_t_Tests_Update;
		 by ByVar;
		run;
		data ALL_t_Tests_Update;
		 merge ALL_t_Tests_Update(in=a) Time_to_ESKD(in=b);
		 by ByVar;
		 if a and b;
		run;

		%if %index(&Print, YES) %then %do;
		ods rtf file="&directory\&filename..rtf"
		        style=Journal NOTOC_DATA BODYTITLE NOKEEPN;

		title1 "Table &Table_t";
		title2 "Approximate power of t-tests for comparing eGFR slope parameters (mL/min/1.73m2/year) between treatment";
		title3 "groups based on a linear spline mixed-effects model with specified model parameters, a knot at month &knot,";
	 	title4 "an accrual period of &accrual months, a follow-up period of &followup months, and designated sample sizes.";
        title5 "The treated and control group acute slopes are fixed at &beta1t_yr and &beta1c_yr (mL/min/1.73m2/yr)";
        title6 "corresponding to an acute treatment effect of &acute_trt_effect (mL/min/1.73m2) at month &knot .";
        title7 "The control group chronic slope is fixed at &beta3c_yr (mL/min/1.73m2/yr).";
		%if %index(&InfCensor, YES) %then %do;
		footnote1 "Power based on a &POM POM variance, a dropout rate of &dropout_pct% per year, and censoring due to ESKD.";
		%end;
		%if %index(&InfCensor, NO) %then %do;
		footnote1 "Power based on a &POM POM variance and a dropout rate of &dropout_pct% per year.";
		%end;
		proc report data=ALL_t_Tests_Update HEADLINE nowindows HEADSKIP SPLIT='|' spacing=1 ;
				COLUMN ("Power calculation results for testing the following null vs alternative hypotheses at a 2-sided type I error=&alpha."
		                "H0: Treatment Slope - Control Slope =  0 (no difference)"
		                "HA: Treatment Slope - Control Slope = DIFF (difference)"
						" "
				         beta3_DIFF_yr Delta_ESKD_yr Slope Estimate N, Group, (Power));
				DEFINE Beta3_DIFF_yr / GROUP 'Chronic Slope|Treatment|Difference|mL/min/1.73m2|per year' width=13 format=5.2 center;
				DEFINE Delta_ESKD_yr / GROUP 'Extended|Years to|ESKD|Due to|Treatment' width=9 format=6.3 center;
				DEFINE Slope / GROUP 'Parameter' width=20 center;
				DEFINE Estimate / GROUP 'DIFF' width=9 center format=7.3 ;
				DEFINE N / Across 'Sample Size (N) per Group' width=30 center format=5.0;
				DEFINE Group / Across ' ' width=15 center format=$15.;
			 	DEFINE Power / mean 'Power' width=7 center format=PowerF. nozero;
		run;
		quit;
		ods rtf close;
		%end;
	%end;

	title;
	footnote;
%mend GFR_Slope_Power;

/*=========================================================================================
Case 0: Assumes no censoring due to staggered entry or dropout nor informative censoring
due to ESKD. Slope and variance-covariance estimates are based on SP Model 1 results 
(Table 5) from the IDNT study. Power is based on a 0-POM variance approximation and study 
design considerations like measurement times taken from the clinical trial design. We 
employed a screening of an additional 100 subjects per treatment group (200 additional 
subjects in total) to ensure subjects enrolled do not have starting predicted eGFR values 
that fall below 15 mL/min/1.73m2 or above 120 mL/min/1.73m2. THIS IS NOT SUMMARIZED IN THE
SUPPLEMENTAL MATERIAL AND IS PRESENTED HERE AS A TEST OF THE 0-POM OPTION. THE POWER 
ESTIMATES WILL BE VERY HIGH AS THE WITHIN_SUBJECT VARIANCE WITH NO POM IS VERY SMALL.
=========================================================================================*/
%GFR_Slope_Power(Data=CKD, knot=4, beta0=50.00, beta1c=-1.012, beta1t=-1.213, beta2c=0.593, 
 beta2t=0.878, Var_e=3.501, Var_u0=325.825, Var_u1=1.088, Var_u2=0.876, Cov_u0u1=2.260, 
 Cov_u0u2=-3.032, Cov_u1u2=-0.935, kappa=-0.061, theta=0.917, DIFF=, 
 Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=0, Reps=0, LowerGFR=15, UpperGFR=120, 
 Screen=100, Accrual=0 , Followup=60, Dropout=0.00, InfCensor=NO,  Alpha=0.05, DDF=NLMIXED, 
 N=300 to 600 by 100, Seed=95738, Close=close, Check=NO, Print=YES, Table_F=A.0a, 
 Table_t=A.0b, Directory=d:\Stat in Med, Filename=GFR Slope Power Estimates - Case 0);

/*=========================================================================================
Case 1: Assumes no censoring due to staggered entry or dropout nor informative censoring
due to ESKD. Slope and variance-covariance estimates are based on SP Model 1 results 
(Table 5) from the IDNT study. Power is based on a PA-POM variance approximation and study 
design considerations like measurement times taken from the clinical trial design. We 
employed a screening of an additional 100 subjects per treatment group (200 additional 
subjects in total) to ensure subjects enrolled do not have starting predicted eGFR values 
that fall below 15 mL/min/1.73m2 or above 120 mL/min/1.73m2. 
=========================================================================================*/
%GFR_Slope_Power(Data=CKD, knot=4, beta0=50.00, beta1c=-1.012, beta1t=-1.213, beta2c=0.593, 
 beta2t=0.878, Var_e=3.501, Var_u0=325.825, Var_u1=1.088, Var_u2=0.876, Cov_u0u1=2.260, 
 Cov_u0u2=-3.032, Cov_u1u2=-0.935, kappa=-0.061, theta=0.917, DIFF=, 
 Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=PA, LowerGFR=15, UpperGFR=120, 
 Screen=100, Accrual=0 , Followup=60, Dropout=0.00, InfCensor=NO,  Alpha=0.05, DDF=NLMIXED, 
 N=300 to 600 by 100, Seed=95738, Close=close, Check=NO, Print=YES, Table_F=A.3, 
 Table_t=A.4, Directory=d:\Stat in Med, Filename=GFR Slope Power Estimates - Case 1);


/*=========================================================================================
Case 2: Assumes administrative censoring due to staggered entry, random dropout and  
censoring due to ESKD. We continue to use slope and variance-covariance estimates based on         
SP Model 1 for comparison to Case 1 above. Power is based on EM-POM variance approximation
and the same study design considerations as in Case 1. We use the same starting seed so as
to keep the same set of random effects. We employed a screening of an additional 100 
subjects per treatment group (200 additional subjects in total) to ensure subjects enrolled 
do not have starting predicted eGFR values < 15 mL/min/1.73m2 or > 120 mL/min/1.73m2.  
=========================================================================================*/
%GFR_Slope_Power(Data=CKD, knot=4, beta0=50.00, beta1c=-1.012, beta1t=-1.213, beta2c=0.593, 
 beta2t=0.878, Var_e=3.501, Var_u0=325.825, Var_u1=1.088, Var_u2=0.876, Cov_u0u1=2.260, 
 Cov_u0u2=-3.032, Cov_u1u2=-0.935, kappa=-0.061, theta=0.917, DIFF=, 
 Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=EM, Reps=500, LowerGFR=15, UpperGFR=120, Screen=100, 
 Accrual=36, Followup=24, Dropout=0.05, InfCensor=YES, Alpha=0.05, DDF=NLMIXED, 
 N=300 to 600 by 100, Seed=95738, Close=close, Check=NO, Print=YES, Table_F=A.5(F-tests), Table_t=A.5, 
 Directory=d:\Stat in Med, Filename=GFR Slope Power Estimates - Case 2);


/*===========================================================================================================
                                              MACRO REPLICATE     
 This macro simply allows the user to replicate the SAS macro GFR_Slope_Power for some specified number of
 replications when choosing to use the Dropout=0.05 (or some other value) and InfCensor=YES options.
 Doing so will allow the user to address concerns regarding possible "sampling" error due to different 
 randomly generated dropout values and different informative censoring values when using these options
 compared to one call GFR_Slope_Power. The macro creates two summary datasets, Avg_F_Tests and Avg_t_Tests.

 One must specifiy the call to SAS macro GFR_Slope_Power that one wishes to replicate from within the SAS 
 macro REPLICATE as illustrated in the example below. 

 USAGE WARNINGS: 
    1) The user should ALWAYS set the following GFR_Slope_Power macro variables to the following values when
       making the call to SAS macro GFR_Slope_Power within SAS macro REPLICATE.  
       Fixed GFR_Slope_Power Macro Variable Settings:
            SEED = &seed_i
            PRINT= NO
            CHECK= NO  
            CLOSE= Close
    2) The other GFR_Slope_Power macro variables should be consistent with whatever one used with a single 
       call to GFR_Slope_Power  
    3) It is strongly advised to use the following calls to PROC PRINTTO before and after one calls the 
       SAS macro REPLICATE so as to avoid an unnecessarily long SAS log
          
       filename bootlog "a user defined file name";
       proc printto log=bootlog;
       %REPLICATE(seed=12345, Rep=100);
       proc printto;
       run; 
=============================================================================================================
 KEY MACRO VARIABLES: 
      StartSeed=  -Defines a starting seed such that each replicated dataset has its own starting seed and
                   also allows the user to recreate the same results by making the same call with the same 
                   starting seed.
                   DEFAULT VALUE: SEED = 12345    ( The user may choose any number )
       Rep=       -Defines how many replicated "dummy" datasets one uses to verify the power calculations 
                   from a single call to SAS macro GFR_Slope_Power. 
                   DEFAULT VALUE: REP = 100
===========================================================================================================*/
%macro Replicate(StartSeed=12345, Rep=100);
	data seeds;
	 retain seed &StartSeed;
	 do i = 1 to &Rep;
	  call ranuni(seed,uni);
	  output;
	 end;
	run;
	data Avg_F_Tests;set _null_;run;
	data Avg_t_Tests;set _null_;run;

	%do i=1 %to &rep;
	data seed;
	 set seeds;
	 if i=&i;
	run;
	data seed;
	 set seed;
	 call symput('seed_i', seed);
	run;
	%GFR_Slope_Power(Data=CKD, knot=4, beta0=50.00, beta1c=-1.012, beta1t=-1.213, 
      beta2c=0.593, beta2t=0.878, Var_e=3.501, Var_u0=325.825, Var_u1=1.088, 
      Var_u2=0.876, Cov_u0u1=2.260, Cov_u0u2=-3.032, Cov_u1u2=-0.935, kappa=-0.061, 
      theta=0.917, DIFF=, Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=EM, Reps=500, 
      LowerGFR=15, UpperGFR=120, Screen=150, Accrual=36, Followup=24, Dropout=0.05, 
      InfCensor=YES, Alpha=0.05, DDF=NLMIXED, N=400 to 400, Seed=&seed_i, Close=close, 
      Check=NO, Print=NO, Table_F=., Table_t=., Directory=d:\Stat in Med, Filename=);

	data Avg_F_Tests; 
	 set Avg_F_Tests F_Tests(in=a);
	 if a then do; replication=&i; end;
	run;
	data Avg_t_Tests; 
	 set Avg_t_Tests t_Tests(in=a);
	 if a then do; replication=&i; end;
	run;
	%end;
%mend Replicate;


filename bootlog "d:\Stat in Med\MacroPower.log";
proc printto log=bootlog;
run;
%Replicate(startseed=82346, rep=100);
proc printto;
run;

libname SIM "d:\Stat in Med\";
run;
data SIM.Avg_t_Tests;
 set Avg_t_Tests;
run;

proc format;
 value N_fmt 400='N = 400 Subjects per Group';   
 PICTURE PowerF 0-<0.999='9.999' other='>0.999' .=' ';                                                
run;
ods rtf file="d:\Stat in Med\Power Estimates from 100 Replicaed Datasets.rtf"
        style=Journal NOTOC_DATA BODYTITLE NOKEEPN;

title1 "Table A.6";
title2 "Approximate power of t-tests for comparing eGFR slope parameters (mL/min/1.73m2/year) between";
title3 "treatment groups based on a linear spline mixed-effects model with specified model parameters,";
title4 "36 month accrual period, 24 month follow-up, a sample size of 400 subjects per group and 100";
title5 "replicated 'dummy' datasets to assess how robust estimates from a single 'dummy' dataset are";
title6 "to variation in simulated screening and simulated dropout to ESKD.";
footnote1 "Power based on an EM-POM variance, a dropout rate of 5% per year, and censoring due to ESKD.";
footnote2 "An extended time to ESKD due to treatment is predicted to be, on average, 1.344 years";  
footnote3 "where ESKD is defined to have occurred once eGFR reaches 15 mL/min/1.73m2.";  
proc report data=SIM.Avg_t_Tests HEADLINE nowindows HEADSKIP SPLIT='|' spacing=1 ;
				COLUMN ("Power calculation results for testing the following null hypotheses at a 2-sided type I error=0.05."
	                "H0: No Differences in Slopes Between Two Treatment Groups (t-test)"
						" "
			Slope Group Estimate N, (Power Power=PowerSD Power=PowerMedian Power=PowerMin Power=PowerMax) );
			DEFINE Slope / GROUP 'Slope|Parameter' width=20 center;
			DEFINE Group / GROUP 'Treatment|Comparison' width=15 center;
			DEFINE Estimate / GROUP 'Assumed|Value' width=7 center format=7.3;
			DEFINE N / ACROSS 'Summary of Power Calculations' width=25 format=N_fmt. center;
			DEFINE Power / mean 'Mean|Power' width=7 center format=PowerF.;
			DEFINE PowerSD / std 'SD' width=5 center format=PowerF.;
			DEFINE PowerMedian / median 'Median|Power' width=8 center format=PowerF.;
			DEFINE PowerMin / min 'Minimum|Power' width=7 center format=PowerF.;
			DEFINE PowerMax/ max 'Maximum|Power' width=7 center format=PowerF.;
		run;
		quit;
ods rtf close;

/*=========================================================================================
Case 3: Assumes administrative censoring due to staggered entry, random dropout and  
censoring due to ESKD. We use slope and variance-covariance estimates from SP Model 2.         
Here we summarize the power required to detect specified differences in the chronic slope
as well as for delta and total slopes holding the observed difference in the control and 
treated acute slopes fixed. Results utilize a within-subject EM-POM variance approximation. 
We kept the same seed as for Case 1 and Case 2 above to maintain the same "dummy" dataset.
We set the value of DIFF = .0625 to .125 by .02083 in units of mL/min/1.73m2/month which  
is equivalent to DIFF = 0.75 to 1.50 by 0.25 in units of mL/min/1.73m2/year which
correspond to incremental differences (Treated minus Control) in the chronic slopes.
=========================================================================================*/
%GFR_Slope_Power(Data=CKD, knot=4, beta0=50.00, beta1c=-1.038, beta1t=-1.227, beta2c=0.579,
 beta2t=0.834, Var_e=3.355, Var_u0=327.977, Var_u1=1.034, Var_u2=0.794, Cov_u0u1=1.831, 
 Cov_u0u2=-2.265, Cov_u1u2=-0.863, kappa=0.028, theta=0.922, DIFF=.0625 to .125 by .02083, 
 Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=EM, Reps=500, LowerGFR=15, UpperGFR=120, Screen=100, 
 Accrual=36, Followup=24, Dropout=0.05, InfCensor=YES, Alpha=0.05, DDF=NLMIXED, 
 N=300 to 600 by 100, Seed=95738, Close=close, Check=NO, Print=YES, Table_F=., Table_t=A.7, 
 Directory=d:\Stat in Med, Filename=GFR Slope Power Estimates - Case 3);

/*=========================================================================================
Case 4: Assumes administrative censoring due to staggered entry, random dropout and  
censoring due to ESKD. We use slope and variance-covariance estimates from SP Model 2 but
we set the treatment group acute slope at -1.133 mL/min/1.73m2/month corresponding to an 
approximate 50% reduction in the acute treatment effect at 4 months with the mean 
difference in eGFR going from -0.756 mL/min/1.73m2 (treated – control) to a mean difference
of -0.38 mL/min/1.73m2. Here we summarize the power required to detect the same specified 
differences in the chronic slopes but with alternative differences in the delta and total
slopes resulting from a change to the treatment group acute slope. Results utilize a 
within-subject SS-POM variance approximation. We kept the same seed as in Cases 1-3 above.
=========================================================================================*/
%GFR_Slope_Power(Data=CKD, knot=4, beta0=50.00, beta1c=-1.038, beta1t=-1.133, beta2c=0.579,
 beta2t=0.834, Var_e=3.355, Var_u0=327.977, Var_u1=1.034, Var_u2=0.794, Cov_u0u1=1.831, 
 Cov_u0u2=-2.265, Cov_u1u2=-0.863, kappa=0.028, theta=0.922, DIFF=.0625 to .125 by .02083,   
 Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=EM, Reps=500, LowerGFR=15, UpperGFR=120, Screen=100, 
 Accrual=36, Followup=24, Dropout=0.05, InfCensor=YES, Alpha=0.05, DDF=NLMIXED, 
 N=300 to 600 by 100, Seed=95738, Close=close, Check=NO, Print=YES, Table_F=., Table_t=A.8, 
 Directory=d:\Stat in Med, Filename=GFR Slope Power Estimates - Case 4);

/*=========================================================================================
Case 5: Assumes administrative censoring due to staggered entry, random dropout and  
censoring due to ESKD. We use slope and variance-covariance estimates from SP Model 2.         
Here we summarize the power required to detect specified differences in the chronic slope
as well as for delta and total slopes holding the observed difference in the control and 
treated acute slopes fixed. Results utilize a within-subject EM-POM variance approximation
as well as the more liberal PA-POM variance approximation. We changed the value of seed 
and set the value of DIFF = 0.08333 to 0.10416 by 0.002083 (per month) corresponding to an 
incremental difference of 1.00-1.25/yr (Treated–Control) diffewrence in the chronic slopes. 
Finally we set the knot at 3,4,5, and 6 months to see what impact possible misspecification 
of the knot would have on prospective power estimates for N = 400 subjects/treatment group.
=========================================================================================*/
data t_Tests_by_knots_PA;set _null_;run;
data t_Tests_by_knots_EM;set _null_;run;
%macro Run_Knots;
	%do knot=3 %to 6;
	%GFR_Slope_Power(Data=CKD, knot=&knot, beta0=50.00, beta1c=-1.038, beta1t=-1.227, beta2c=0.579,
	 beta2t=0.834, Var_e=3.355, Var_u0=327.977, Var_u1=1.034, Var_u2=0.794, Cov_u0u1=1.831, 
	 Cov_u0u2=-2.265, Cov_u1u2=-0.863, kappa=0.028, theta=0.922, DIFF=0.08333 to .10416 by .02083, 
	 Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=PA, Reps=0, LowerGFR=15, UpperGFR=120, Screen=100, 
	 Accrual=36, Followup=24, Dropout=0.05, InfCensor=YES, Alpha=0.05, DDF=NLMIXED, 
	 N=400 to 400, Seed=94765, Close=close, Check=NO, Print=NO, Table_F=A.9a(F-tests), Table_t=A.9a, 
	 Directory=c:\Stat in Med, Filename=GFR Slope Power Estimates - Case 5a);
	 data t_Tests_by_knots_PA; 
	  set t_Tests_by_knots_PA All_t_Tests_Update;
	 run; 
	%GFR_Slope_Power(Data=CKD, knot=&knot, beta0=50.00, beta1c=-1.038, beta1t=-1.227, beta2c=0.579,
	 beta2t=0.834, Var_e=3.355, Var_u0=327.977, Var_u1=1.034, Var_u2=0.794, Cov_u0u1=1.831, 
	 Cov_u0u2=-2.265, Cov_u1u2=-0.863, kappa=0.028, theta=0.922, DIFF=0.08333 to .10416 by .02083, 
	 Months=%str(0,3,6,12,18,24,30,36,42,48,54), POM=EM, Reps=500, LowerGFR=15, UpperGFR=120, Screen=100, 
	 Accrual=36, Followup=24, Dropout=0.05, InfCensor=YES, Alpha=0.05, DDF=NLMIXED, 
	 N=400 to 400, Seed=94765, Close=close, Check=NO, Print=NO, Table_F=A.9a(F-tests), Table_t=A.9a, 
	 Directory=c:\Stat in Med, Filename=GFR Slope Power Estimates - Case 5b);
	 data t_Tests_by_knots_EM; 
	  set t_Tests_by_knots_EM All_t_Tests_Update;
	 run; 
	%end;
%mend Run_Knots;
%Run_Knots;

proc print data=t_Tests_by_knots_PA;
 where Slope='Chronic Slope';
 format Power 5.3;
 title "Sensitivity analysis of knots using a PA-POM approximation - see Table 9 of paper"; 
run;
proc print data=t_Tests_by_knots_EM;
 where Slope='Chronic Slope';
 format Power 5.3;
 title "Sensitivity analysis of knots using an EM-POM approximation - see Table 9 of paper"; 
run;


