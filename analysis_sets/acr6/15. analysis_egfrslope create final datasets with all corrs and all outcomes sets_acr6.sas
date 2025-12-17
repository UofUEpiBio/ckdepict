%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\acr6\datasets";
libname Exports "&path1\analysis_sets\acr6\Exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");
data sum_means; 
 set SASdata.sum_means_gfr_acr;
run;
data t99;
 set SASdata.nfirstmodelinseqperstudyt99;
 if cs_reason ne "NOTE: GCONV convergence criterion satisfied." then delete;
 keep allrx allrxname allrxname1 study beta31_beta32_est beta31_beta32_se beta31_beta32_sem beta31_beta32_sem npatients	nevents region 
      region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 
      disease2_fmt mean_b_CKDegfr zzupro_median  
	  zbeta11_est zbeta11_se zbeta11_sem zbeta11_sem zbeta12_est zbeta12_se zbeta12_sem zbeta12_sem
      zbeta11_beta12_est zbeta11_beta12_se zbeta11_beta12_sem zbeta11_beta12_see
      beta31_est beta31_se beta31_sem beta31_sem beta32_est beta32_se beta32_sem beta32_sem
	  rbeta31_beta32_est rbeta31_beta32_se rbeta31_beta32_sem rbeta31_beta32_see
	  beta41_42_1y_est beta41_42_1y_se beta41_42_1y_sem beta41_42_1y_see beta41_1y_est beta41_1y_se beta41_1y_sem beta41_1y_see 
      beta42_1y_est beta42_1y_se beta42_1y_sem beta42_1y_see
	  beta41_42_2y_est beta41_42_2y_se beta41_42_2y_sem beta41_42_2y_see beta41_2y_est beta41_2y_se beta41_2y_sem beta41_2y_see 
      beta42_2y_est beta42_2y_se beta42_2y_sem beta42_2y_see
	  beta41_42_3y_est beta41_42_3y_se beta41_42_3y_sem beta41_42_3y_see beta41_3y_est beta41_3y_se beta41_3y_sem beta41_3y_see 
      beta42_3y_est beta42_3y_se beta42_3y_sem beta42_3y_see
      beta41_42_4y_est beta41_42_4y_se beta41_42_4y_sem beta41_42_4y_see beta41_4y_est beta41_4y_se beta41_4y_sem beta41_4y_see 
      beta42_4y_est beta42_4y_se beta42_4y_sem beta42_4y_see kappa_est kappa_se kappa_sem kappa_see;
run;
proc sort data=t99;
 by study;
run;
proc sort data=sum_means;
 by study;
run;
data t99;
 merge t99 sum_means;
 by study;
run;
/** Get ACR **/
data acr0;
 set SASdata.txt_effects_up2;
 if compress(model)="2.ANCOVA";
 if compress(variable)="T_assign";
 loggmr_est=estimate;
 loggmr_se=se;
 acr_total=_p_+_edf_;
 keep allrx loggmr_est loggmr_se acr_total;
run;
data acr1;
 set SASdata.noint_txt_effects_up2;
 if compress(model)="2.ANCOVA";
 if compress(variable)="t_assign0";
 loggmr1_est=estimate;
 loggmr1_se=se;
 keep allrx loggmr1_est loggmr1_se;
run;
data acr2;
 set SASdata.noint_txt_effects_up2;
 if compress(model)="2.ANCOVA";
 if compress(variable)="t_assign1";
 loggmr2_est=estimate;
 loggmr2_se=se;
 keep allrx loggmr2_est loggmr2_se;
run;
%macro get_evs(n);
data ev&n;
 set Exports.egfrslope_txteff_ce_r;
 if eventnumber=&n;
 ev&n._loghr_est=estimate;
 ev&n._loghr_se=stderr;
 ev&n._total=total;
 ev&n._event=event;
 if stderr > 1000 then do;
 ev&n._loghr_se=.;
 ev&n._loghr_est=.;
 end;
 keep allrx ev&n._loghr_est ev&n._loghr_se ev&n._total ev&n._event;
run;
proc sort data=ev&n;
 by allrx;
run;
%mend;
%get_evs(1);
%get_evs(2);
%get_evs(3);
%get_evs(4);
%get_evs(5);
%get_evs(6);
%get_evs(7);
%get_evs(8);
data acute;
 set SASdata.ancova_deltaGFR;
 gfr_acute_est=est01;
 gfr_acute_se=stderr01;
 n_acute=n;
 keep allrx gfr_acute_est gfr_acute_se n_acute time_acute;
run;
proc sort data=acute;
 by allrx;
run;
proc sort data=acr0;
 by allrx;
run;
proc sort data=acr1;
 by allrx;
run;
proc sort data=acr2;
 by allrx;
run;
data t99_all1;
 merge t99 acute ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 acr0 acr1 acr2;
 by allrx;
run;
data allcorr;
 set SASdata.allcorr;
run;
proc sort data=t99_all1;
 by study;
run;
proc sort data=allcorr;
 by study;
run;
data t99_all2;
 merge t99_all1 allcorr;
 by study;
run;
data t99_acr6;
  length study allrx 8. allrxname $19. allrxname1 $18. region 8. region_fmt $13. pooled 8. pooled_fmt $19. 
        intervention 8. intervention_fmt $29. intervention_abrev $12. disease 8. disease_fmt $22. disease2 8. 
        disease2_fmt $22. mean_b_CKDegfr bCKDegfr_N bCKDegfr_StdErr zzupro_median blogacr_N blogacr_Mean blogacr_StdErr 8.;
 set t99_all2;
run;
data Exports.t99_acr6;
 set t99_acr6;
run;
%zexportcsv(t99_acr6,t99_acr6,&path1\analysis_sets\acr6\Exports);

data SASdata.t99_acr6;
 set t99_acr6;
run;
%zexportcsv(t99_acr6,t99_acr6,&path1\analysis_sets\acr6\Datasets);




