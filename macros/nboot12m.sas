%macro nboot12m(rep,datagrp2);
proc datasets nolist;
 delete boot1 boot2 boot3 coxboot subgroups cs cs1 pe pe1 convergencestatus coxreps0 coxreps
        upro6 olsboot olsreps regout1 regout1a regout2 regout2a all_boots1 all_boots rep_all rep0 rep1
		sboot sboot1 ci ratios ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 ev9 delta1 delta2 corrx pcorr corr_ratio1 corr_ratio2
		ratios ratios_corrs1 ratios_corrs2 ratios_corrs3 ratios_corrs
        cens1 cens2 cens3 cens4 cens5 cens6 cens7 cens8 cens9
        param1 param2 param3 param4 param5 param6 param7 param8 param9
        conv1 conv2 conv3 conv4 conv5 conv6 conv7 conv8 conv9 xstudies
        zallrxstudies bstudies cstudies studies1;
run;
quit;
data boot1;
 set pclean3.fda2_allrx;
 if delupro12=. then delete;
 if datagrp2=&datagrp2;
 keep new_id allrx logdelupro12 b_CKDegfr zzupro zupro combo datagrp1 datagrp2 t_assign zstudy1 zstudy2 zstudy3 ztrt1 ztrt2
      ev_dg_40_p_con fu_dg_40_p_con ev_dg_30_p_con fu_dg_30_p_con ev_dgs_con fu_dgs_con ev_dg_con fu_dg_con 
      ev_dgsx_con fu_dgsx_con ev_d fu_d ev_dx fu_dx ev_40_p_con mos_40_p_con ev_30_p_con mos_30_p_con;
run;
proc sort data=boot1 nodupkey out=subgroups(keep=datagrp1 datagrp2);
 by datagrp2;
run;
proc sort data=boot1;
 by datagrp2 allrx combo new_id;
run;
proc surveyselect data=boot1 noprint method=urs samprate=1 rep=&rep seed=123 out=boot2;
 strata datagrp2 allrx combo;
run;
data boot3;
 set boot1(in=in1) boot2;
 if in1 then do;replicate=0;numberhits=1;end;
run;
proc sort data=boot3;
 by replicate datagrp2 allrx;
run;
%macro coxreg(data,time,event,out1,out2,out3);
proc phreg data=&data;
 model &time*&event(0)=t_assign ztrt1 ztrt2/rl;
 strata combo;
 ods output censoredsummary=&out1(keep=replicate datagrp2 allrx combo total event);
 ods output parameterestimates=&out2(keep=replicate datagrp2 allrx parameter df estimate stderr chisq probchisq hazardratio 
                                     hrlowercl hruppercl);
 ods output convergencestatus=&out3;
 by replicate datagrp2 allrx;
 freq numberhits;
run;
%mend;
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
%coxreg(boot3,fu_dg_40_p_con,ev_dg_40_p_con,cens1,param1,conv1);
%coxreg(boot3,fu_dg_30_p_con,ev_dg_30_p_con,cens2,param2,conv2);
%coxreg(boot3,fu_dgs_con,ev_dgs_con,cens3,param3,conv3);
%coxreg(boot3,fu_dg_con,ev_dg_con,cens4,param4,conv4);
%coxreg(boot3,fu_dgsx_con,ev_dgsx_con,cens5,param5,conv5);
%coxreg(boot3,fu_d,ev_d,cens6,param6,conv6);
%coxreg(boot3,fu_dx,ev_dx,cens7,param7,conv7);
%coxreg(boot3,mos_40_p_con,ev_40_p_con,cens8,param8,conv8);
%coxreg(boot3,mos_30_p_con,ev_30_p_con,cens9,param9,conv9);
ods listing;
options notes mprint symbolgen mlogic;
data cs;
 set cens1(in=in1) cens2(in=in2) cens3(in=in3) cens4(in=in4) cens5(in=in5) cens6(in=in6) cens7(in=in7)
     cens8(in=in8) cens9(in=in9);
      if in1 then eventnumber=1;
 else if in2 then eventnumber=2;
 else if in3 then eventnumber=3;
 else if in4 then eventnumber=4;
 else if in5 then eventnumber=5;
 else if in6 then eventnumber=6;
 else if in7 then eventnumber=7;
 else if in8 then eventnumber=8;
 else if in9 then eventnumber=9;
run;
data pe;
 set param1(in=in1) param2(in=in2) param3(in=in3) param4(in=in4) param5(in=in5) param6(in=in6) param7(in=in7)
     param8(in=in8) param9(in=in9);
      if in1 then eventnumber=1;
 else if in2 then eventnumber=2;
 else if in3 then eventnumber=3;
 else if in4 then eventnumber=4;
 else if in5 then eventnumber=5;
 else if in6 then eventnumber=6;
 else if in7 then eventnumber=7;
 else if in8 then eventnumber=8;
 else if in9 then eventnumber=9;
run;
data convergencestatus;
set conv1(in=in1) conv2(in=in2) conv3(in=in3) conv4(in=in4) conv5(in=in5) conv6(in=in6) conv7(in=in7)
    conv8(in=in8) conv9(in=in9);
      if in1 then eventnumber=1;
 else if in2 then eventnumber=2;
 else if in3 then eventnumber=3;
 else if in4 then eventnumber=4;
 else if in5 then eventnumber=5;
 else if in6 then eventnumber=6;
 else if in7 then eventnumber=7;
 else if in8 then eventnumber=8;
 else if in9 then eventnumber=9;
run;
data cs1;
 set cs;
 if compress(combo)="";
 drop combo;
run;
data pe1;
 set pe;
 if compress(parameter)="T_assign";
run;
proc sort data=cs1;
 by replicate datagrp2 eventnumber allrx;
run;
proc sort data=pe1;
 by replicate datagrp2 eventnumber allrx;
run;
proc sort data=convergencestatus;
 by replicate datagrp2 eventnumber allrx;
run;
data coxreps0;
 merge cs1 pe1 convergencestatus;
 by replicate datagrp2 eventnumber allrx;
run;
data coxreps;
 set coxreps0;
 drop parameter df;
 if stderr=. or stderr > 1000 or status=2 then estimate=.;
 rename estimate=loghr stderr=seloghr;
run;
data coxreps12m;
 set coxreps;
run;
/** Treatment effects on delta UP **/
data upro12;
 set boot3;
 if zupro > 0 then x=log(zupro);else if zupro=0 then x=log(0.01);
 y=logdelupro12;
 keep replicate datagrp2 allrx new_id numberhits x y t_assign zstudy1 zstudy2 zstudy3 ztrt1 ztrt2;
run;
data olsboot;
 set upro12(in=in1) upro12(in=in2);
 if x=. or y=. then delete;
 if in1 then do;
 model="1. Unadjusted";
 adj=0;
 resp=y;
 end;
 if in2 then do;
 adj=x;
 resp=y;
 model="2. ANCOVA";
 end;
run;
%wregs(olsboot,resp,numberhits,replicate datagrp2 model allrx,t_assign adj zstudy1 zstudy2 zstudy3 ztrt1 ztrt2,olsreps);
data olsreps12m;
 set olsreps;
 if se=. then estimate=.;
run;
data regout1;
 set olsreps;
 if se=. then estimate=.;
 if compress(variable)="T_assign" and compress(model)="1.Unadjusted";
 n1=_p_+_edf_;
run;
data regout1a;
 set regout1;
 drop variable model gmr gmr_lcl95 gmr_ucl95 gmr_pct gmr_lcl95_pct gmr_ucl95_pct _p_ _edf_ _rsq_ _rmse_;
 rename estimate=loggmr1 se=seloggmr1 pvalue=ploggmr1 lcl95=loggmr1_lcl95 ucl95=loggmr1_ucl95;
run;
data regout2;
 set olsreps;
 if se=. then estimate=.;
 n2=_p_+_edf_;
 if compress(variable)="T_assign" and compress(model)="2.ANCOVA";
run;
data regout2a;
 set regout2;
 drop variable model gmr gmr_lcl95 gmr_ucl95 gmr_pct gmr_lcl95_pct gmr_ucl95_pct _p_ _edf_ _rsq_ _rmse_;
 rename estimate=loggmr2 se=seloggmr2 pvalue=ploggmr2 lcl95=loggmr2_lcl95 ucl95=loggmr2_ucl95;
run;
proc sort data=coxreps;
 by replicate datagrp2 allrx;
run;
proc sort data=regout2a;
 by replicate datagrp2 allrx;
run;
proc sort data=regout2a;
 by replicate datagrp2 allrx;
run;
data all_boots1;
 merge coxreps regout1a regout2a;
 by replicate datagrp2 allrx;
run;
data all_boots;
 set all_boots1;
 logratio1=loghr-loggmr1;
 logratio2=loghr-loggmr2;
run;
data all_boots12m;
 set all_boots;
run;
/** Get variance of treatment effects and ratios **/
data rep_all;
 set all_boots;
 exp_logratio1=exp(logratio1);
 exp_logratio2=exp(logratio2);
 keep replicate datagrp2 allrx eventnumber total event loghr seloghr loggmr1 seloggmr1 loggmr2 seloggmr2 logratio1 logratio2 exp_logratio1 exp_logratio2;
run;
data rep0;
 set rep_all;
 if replicate=0;
run;
data rep1;
 set rep_all;
 if replicate>0;
run;
ods listing close;
proc means data=rep1 std n;
 var logratio1 logratio2;
 ods output summary=sboot;
 class datagrp2 allrx eventnumber;
run;
ods listing;
data sboot1;
 set sboot;
 drop vname_logratio1 vname_logratio2 nobs;
run;
proc sort data=rep1;
 by datagrp2 allrx eventnumber;
run; 
ods listing close;
proc univariate data=rep1 noprint;
 var logratio1 logratio2;
 by datagrp2 allrx eventnumber;
 where replicate > 0;
 output out=ci pctlpre=logratio1 logratio2 pctlpts=2.5 97.5;
run;
ods listing;
proc sort data=sboot1;
 by datagrp2 allrx eventnumber;
run;
proc sort data=ci;
 by datagrp2 allrx eventnumber;
run;
proc sort data=rep0;
 by datagrp2 allrx eventnumber;
run;
data ratios;
 merge rep0 sboot1 ci;
 by datagrp2 allrx eventnumber;
 rename logratio12_5=logratio1_lcl95 logratio197_5=logratio1_ucl95 logratio22_5=logratio2_lcl95 logratio297_5=logratio2_ucl95;
 exp_logratio1_lcl95=exp(logratio12_5);
 exp_logratio1_ucl95=exp(logratio197_5);
 exp_logratio2_lcl95=exp(logratio22_5);
 exp_logratio2_ucl95=exp(logratio297_5);
 drop replicate;
run;
data ratios12m;
 set ratios;
run;
/** Get all correlations **/
%macro evc(data,number);
data ev&number;
 set &data;
 if eventnumber=&number;
 loghr&number=loghr;
 keep replicate datagrp2 allrx loghr&number;
run;
proc sort data=ev&number;
 by replicate datagrp2 allrx;
run;
%mend;
%evc(coxreps,1);
%evc(coxreps,2);
%evc(coxreps,3);
%evc(coxreps,4);
%evc(coxreps,5);
%evc(coxreps,6);
%evc(coxreps,7);
%evc(coxreps,8);
%evc(coxreps,9);
data delta1;
 set regout1a;
 keep replicate datagrp2 allrx loggmr1;
run;
data delta2;
 set regout2a;
 keep replicate datagrp2 allrx loggmr2;
run;
proc sort data=delta1;
 by replicate datagrp2 allrx;
run;
proc sort data=delta2;
 by replicate datagrp2 allrx;
run;
data corrx;
 merge ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 ev9 delta1 delta2;
 by replicate datagrp2 allrx;
 if replicate>0;
run;
proc sort data=corrx;
 by datagrp2 allrx;
run;
ods listing close;
proc corr data=corrx pearson;
 var loggmr1 loggmr2 loghr1 loghr2 loghr3 loghr4 loghr5 loghr6 loghr7 loghr8 loghr9;
 by datagrp2 allrx;
 ods output pearsoncorr=pcorr;
run;
ods listing;
data pcorr12m;
 set pcorr;
run;
/** Create one final dataset which has the ratios and also the correlations **/
data corr_ratio1;
 set pcorr;
 if variable in ("loghr1" "loghr2" "loghr3" "loghr4" "loghr5" "loghr6" "loghr7" "loghr8" "loghr9");
 corr_ratio1=loggmr1;
       if compress(variable)="loghr1" then eventnumber=1;
  else if compress(variable)="loghr2" then eventnumber=2;
  else if compress(variable)="loghr3" then eventnumber=3;
  else if compress(variable)="loghr4" then eventnumber=4;
  else if compress(variable)="loghr5" then eventnumber=5;
  else if compress(variable)="loghr6" then eventnumber=6;
  else if compress(variable)="loghr7" then eventnumber=7;
  else if compress(variable)="loghr8" then eventnumber=8;
  else if compress(variable)="loghr9" then eventnumber=9;
 keep datagrp2 allrx corr_ratio1 eventnumber;
run;
data corr_ratio2;
 set pcorr;
 if variable in ("loghr1" "loghr2" "loghr3" "loghr4" "loghr5" "loghr6" "loghr7" "loghr8" "loghr9");
 corr_ratio2=loggmr2;
       if compress(variable)="loghr1" then eventnumber=1;
  else if compress(variable)="loghr2" then eventnumber=2;
  else if compress(variable)="loghr3" then eventnumber=3;
  else if compress(variable)="loghr4" then eventnumber=4;
  else if compress(variable)="loghr5" then eventnumber=5;
  else if compress(variable)="loghr6" then eventnumber=6;
  else if compress(variable)="loghr7" then eventnumber=7;
  else if compress(variable)="loghr8" then eventnumber=8;
  else if compress(variable)="loghr9" then eventnumber=9;
 keep datagrp2 allrx corr_ratio2 eventnumber;
run;
proc sort data=corr_ratio1;
 by datagrp2 allrx eventnumber;
run;
proc sort data=corr_ratio2;
 by datagrp2 allrx eventnumber;
run;
proc sort data=ratios;
 by datagrp2 allrx eventnumber;
run;
data ratios_corrs1;
 merge ratios corr_ratio1 corr_ratio2;
 by datagrp2 allrx eventnumber;
run;
proc sort data=ratios_corrs1;
 by eventnumber;
run;
proc sort data=eventsfile1;
 by eventnumber;
run;
data ratios_corrs2;
 merge eventsfile1(keep=eventnumber eventname) ratios_corrs1;
 by eventnumber;
run;
proc sort data=ratios_corrs2;
 by datagrp2 allrx;
run;
data xstudies;
 set studies;
run;
proc sort data=xstudies;
 by datagrp2 allrx;
run;
data ratios_corrs3;
 merge xstudies ratios_corrs2(in=in1);
 by datagrp2 allrx;
 if in1;
run;
proc sort data=ratios_corrs3;
 by datagrp2;
run;
proc sort data=subgroups;
 by datagrp2;
run;
data ratios_corrs;
 merge subgroups ratios_corrs3;
 by datagrp2;
run;
data ratios_corrs;
 set ratios_corrs;
 hr=exp(loghr);
 hr_lcl=exp(loghr-1.96*seloghr);
 hr_ucl=exp(loghr+1.96*seloghr);
 gmr1=exp(loggmr1);
 gmr1_lcl=exp(loggmr1-1.96*seloggmr1);
 gmr1_ucl=exp(loggmr1+1.96*seloggmr1);
 gmr2=exp(loggmr2);
 gmr2_lcl=exp(loggmr2-1.96*seloggmr2);
 gmr2_ucl=exp(loggmr2+1.96*seloggmr2);
run;
proc sort data=ratios_corrs;
 by datagrp2 allrx eventnumber;
run;
data zallrxstudies;
 set pclean3.zallrxdata;
run;
data bstudies;
 set pclean3.allrxdata;
run;
data cstudies;
 set pclean3.b_gfr_up_12m;
run;
proc sort data=bstudies;
 by allrx;
run;
proc sort data=cstudies;
 by allrx;
run;
data studies1;
 merge bstudies cstudies;
 by allrx;
run;
proc sort data=ratios_corrs;
 by datagrp1 datagrp2 allrx;
run;
proc sort data=studies1;
 by datagrp1 datagrp2 allrx;
run;
data ratios_corrs12m; 
  merge ratios_corrs(in=in1) studies1;
  by datagrp1 datagrp2 allrx;
  if in1;
run;
data ratios_corrs12m;
length dataused 8. datausedname $15. datagrp2 8. datagrp1 $12. allrx 8. allrxname $19.  allrx_year $16. 
        region 8. region_fmt $13. pooled 8. pooled_fmt $19. intervention 8. intervention_fmt $29. intervention_abrev $7.
	    disease 8. disease_fmt $22. disease2 8. disease2_fmt $22. include_ia 8. calc_b_n_egfr calc_b_mean_egfr calc_b_n_up calc_b_median_up 8. 
        eventnumber 8. eventname $8.;
 set ratios_corrs12m;
run;
proc sort data=ratios_corrs12m;
 by allrx;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
data ratios_corrs12m;
 merge ratios_corrs12m(in=in1) zallrxstudies;
 by allrx;
 if in1;
run;
proc sort data=ratios_corrs12m;
 by datagrp2 zallrx eventnumber;
run;
data Exports.ratios_corrs12m&datagrp2;
 set ratios_corrs12m;
run;
proc datasets nolist;
 delete boot1 boot2 boot3 coxboot subgroups cs cs1 pe pe1 convergencestatus coxreps0 coxreps
        upro6 olsboot olsreps regout1 regout1a regout2 regout2a all_boots1 all_boots rep_all rep0 rep1
		sboot sboot1 ci ratios ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 ev9 delta1 delta2 corrx pcorr corr_ratio1 corr_ratio2
		ratios ratios_corrs1 ratios_corrs2 ratios_corrs3 ratios_corrs
        cens1 cens2 cens3 cens4 cens5 cens6 cens7 cens8 cens9
        param1 param2 param3 param4 param5 param6 param7 param8 param9
        conv1 conv2 conv3 conv4 conv5 conv6 conv7 conv8 conv9 xstudies
        zallrxstudies bstudies cstudies studies1;
run;
quit;
%mend;