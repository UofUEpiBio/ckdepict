%let t=truncation_99;
%let path1=d:\userdata\shared\ckd_endpts\root;

libname Master "&path1\steps\maindatasets";
libname SASdata  "&path1\analysis_egfrslope\&t.\datasets";
libname Exports  "&path1\analysis_egfrslope\&t.\&t._exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path1\macros");

data studies;
 set SASdata.studies_bgfr_bacr;
run;
proc means data=studies mean stderr;
var bCKDegfr blogacr;
class study;
ods output summary=sum_means(keep=study bCKDegfr_StdErr blogacr_mean blogacr_StdErr);
run;
data acute;
 set Exports.ancova_deltaGFR;
 gfr_acute_est=est01;
 gfr_acute_se=stderr01;
 n_acute=n;
 keep allrx gfr_acute_est gfr_acute_se n_acute time_acute;
run;
data old_t99_1;
 set Exports.nt99a_ce_up_corrs_updated;
 if msg ne "NOTE: GCONV convergence criterion satisfied." then delete;
 if eventnumber=1;
 ev1_loghr1_est=loghr1_est;
 ev1_loghr1_se=loghr1_se;
 ev1_total1=total1;
 ev1_event1=event1;
 ev1_loghr2_est=loghr2_est;
 ev1_loghr2_se=loghr2_se;
 ev1_total2=total2;
 ev1_event2=event2;
 keep allrx allrxname allrxname1 study beta31_beta32_est beta31_beta32_se npatients	nevents region 
      region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 
      disease2_fmt b_ckdegfr_mean zzupro_median ev1_loghr1_est ev1_loghr1_se ev1_total1 ev1_event1 ev1_loghr2_est 
      ev1_loghr2_se ev1_total2 ev1_event2 loggmr6_est loggmr6_se total6 kappa_est kappa_se beta31_est beta31_se 
      beta32_est beta32_se beta41_42_3y_est beta41_42_3y_se beta41_3y_est beta41_3y_se beta42_3y_est beta42_3y_se;
run;
data old_t99_r;
 set Exports.nfirstmodelinseqperstudyt99;
 if cs_reason ne "NOTE: GCONV convergence criterion satisfied." then delete;
 keep allrx allrxname allrxname1 study rbeta31_beta32_est rbeta31_beta32_se;
run;
data old_t99_2;
 set Exports.nt99a_ce_up_corrs_updated;
 if msg ne "NOTE: GCONV convergence criterion satisfied." then delete;
 if eventnumber=2;
 ev2_loghr1_est=loghr1_est;
 ev2_loghr1_se=loghr1_se;
 ev2_total1=total1;
 ev2_event1=event1;
 ev2_loghr2_est=loghr2_est;
 ev2_loghr2_se=loghr2_se;
 ev2_total2=total2;
 ev2_event2=event2;
 keep allrx allrxname allrxname1 study beta31_beta32_est beta31_beta32_se npatients	nevents region 
      region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 
      disease2_fmt b_ckdegfr_mean zzupro_median ev2_loghr1_est ev2_loghr1_se ev2_total1 ev2_event1 ev2_loghr2_est 
      ev2_loghr2_se ev2_total2 ev2_event2 loggmr6_est loggmr6_se total6 kappa_est kappa_se beta31_est beta31_se 
      beta32_est beta32_se beta41_42_3y_est beta41_42_3y_se beta41_3y_est beta41_3y_se beta42_3y_est beta42_3y_se;
run;
data old_t99_3;
 set Exports.nt99a_ce_up_corrs_updated;
 if msg ne "NOTE: GCONV convergence criterion satisfied." then delete;
 if eventnumber=3;
 ev3_loghr1_est=loghr1_est;
 ev3_loghr1_se=loghr1_se;
 ev3_total1=total1;
 ev3_event1=event1;
 ev3_loghr2_est=loghr2_est;
 ev3_loghr2_se=loghr2_se;
 ev3_total2=total2;
 ev3_event2=event2;
 keep allrx allrxname allrxname1 study beta31_beta32_est beta31_beta32_se npatients	nevents region 
      region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 
      disease2_fmt b_ckdegfr_mean zzupro_median ev3_loghr1_est ev3_loghr1_se ev3_total1 ev3_event1 ev3_loghr2_est 
      ev3_loghr2_se ev3_total2 ev3_event2 loggmr6_est loggmr6_se total6 kappa_est kappa_se beta31_est beta31_se 
      beta32_est beta32_se beta41_42_3y_est beta41_42_3y_se beta41_3y_est beta41_3y_se beta42_3y_est beta42_3y_se;
run;
data allcorr;
 set Exports.allcorr;
run;
proc sort data=old_t99_1;
 by allrx;
run;
proc sort data=old_t99_r;
 by allrx;
run;
proc sort data=old_t99_2;
 by allrx;
run;
proc sort data=old_t99_3;
 by allrx;
run;
proc sort data=acute;
 by allrx;
run;
data t99_acute;
 merge old_t99_1 old_t99_r old_t99_2 old_t99_3 acute;
 by allrx;
run;
proc sort data=t99_acute;
 by study;
run;
proc sort data=allcorr;
 by study;
run;
proc sort data=sum_means;
 by study;
run;
data t99_13outcomes;
  length study allrx 8. allrxname $19. allrxname1 $18. region 8.	region_fmt $13.	pooled 8. pooled_fmt $19. 
        intervention 8. intervention_fmt $29. intervention_abrev $7. disease 8. disease_fmt	$22. disease2 8. 
        disease2_fmt $22. b_ckdegfr_mean zzupro_median 8.;
 merge t99_acute sum_means allcorr;
 by study;
 if ev1_loghr2_se > 1000 then do;
 ev1_loghr2_se=.;
 ev1_loghr2_est=.;
 end;
 if ev1_loghr1_se > 1000 then do;
 ev1_loghr1_se=.;
 ev1_loghr1_est=.;
 end;
 if ev2_loghr2_se > 1000 then do;
 ev2_loghr2_se=.;
 ev2_loghr2_est=.;
 end;
 if ev2_loghr1_se > 1000 then do;
 ev2_loghr1_se=.;
 ev2_loghr1_est=.;
 end;
 if ev3_loghr2_se > 1000 then do;
 ev3_loghr2_se=.;
 ev3_loghr2_est=.;
 end;
 if ev3_loghr1_se > 1000 then do;
 ev3_loghr1_se=.;
 ev3_loghr1_est=.;
 end;
run;
data Exports.t99_13outcomes;
 set t99_13outcomes;
run;
%zexportcsv(t99_13outcomes,t99_13outcomes,&path1\analysis_egfrslope\&t.\&t._exports);




