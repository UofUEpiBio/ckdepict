%let t=truncation_99;
%let path1=d:userdata\Shared\CKD_Endpts\FDA Conference 2\Data\Cleaned Data;

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\analysis_egfrslope\macros");

libname Master "&path1";
libname SASdata  "&path2\analysis_egfrslope\&t.\datasets";
libname Exports  "&path2\analysis_egfrslope\&t.\&t._exports";
libname Results "&path2\analysis_egfrslope\&t.\models\results";
libname Corr1 "&path1\analysis_egfrslope\&t.\correlations6\results";
libname Corr2 "&path1\analysis_egfrslope\&t.\correlations12\results";
libname ACR "&path1\analysis_acr\acr_exports";
libname Exports  "&path2\analysis_egfrslope\&t.\&t._exports";

data ntassign01;
 set SASdata.studies;
run;
proc sort data=ntassign01 out=ntassign11 nodupkey;
 by study new_id;
run;
data ntassign11a;
 set ntassign11;
 if t_assign=0;
run;
data ntassign11b;
 set ntassign11;
 if t_assign=1;
run;
proc sql; 
  create table txt0 as
  select study,count(*) as npatients0
  from ntassign11a
  group by study;
quit;
proc sql; 
  create table txt1 as
  select study,count(*) as npatients1
  from ntassign11b
  group by study;
quit;
proc sort data=txt0;
 by study;
run;
proc sort data=txt1;
 by study;
run;
data txt01;
 merge txt0 txt1;
 by study;
run;
data zallrxstudies;
 set SASdata.zallrxdata;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
data studydescrip;
 set SASdata.studydescrip;
 npatients=patients;
 nevents=n1;
 allrx=study_num;
 keep allrx study npatients nevents knot;
run;
proc sort data=studydescrip;
 by study;
run;
/** modified linear GFR model **/
data t99a;
 set SASdata.nfirstmodelinseqperstudyt99;
 msg=cs_reason;
 keep allrx npatients nevents study model surv sp prop pom psi21_used
       beta11_est beta11_se beta12_est beta12_se beta11_beta12_est beta11_beta12_se
        beta31_est beta31_se beta32_est beta32_se beta31_beta32_est	beta31_beta32_se
        beta41_1y_est beta41_1y_se beta42_1y_est beta42_1y_se beta41_42_1y_est beta41_42_1y_se	
        beta41_2y_est beta41_2y_se beta42_2y_est beta42_2y_se beta41_42_2y_est beta41_42_2y_se
        beta41_3y_est beta41_3y_se beta42_3y_est beta42_3y_se beta41_42_3y_est beta41_42_3y_se
        beta41_4y_est beta41_4y_se beta42_4y_est beta42_4y_se beta41_42_4y_est beta41_42_4y_se	
        chronic_t1y_est	chronic_t1y_se chronic_t2y_est chronic_t2y_se chronic_t3y_est chronic_t3y_se chronic_t4y_est chronic_t4y_se msg hessian
        kappa_est kappa_se theta_est theta_se;
run;
/** CE GFR sample **/
data ce1;
 set Exports.egfrslope_txteff_ce_r;
 loghr1_est=estimate;
 loghr1_se=stderr;
 total1=total;
 event1=event;
 keep allrx allrxname region region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev 
      disease disease_fmt disease2 disease2_fmt eventnumber eventname loghr1_est loghr1_se total1 event1
      b_ckdegfr_mean zzupro_median;
run;
data ce2;
 set ACR.txt_effects_endpoints2;
 if datagrp2=1 and parameter="T_assign" and datausedname="6-month sample";
 loghr2_est=estimate;
 loghr2_se=stderr;
 total2=total;
 event2=event;
 keep allrx allrxname region region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev 
      disease disease_fmt disease2 disease2_fmt eventnumber eventname loghr2_est loghr2_se total2 event2;
run;
data ce3;
 set ACR.txt_effects_endpoints2;
 if datagrp2=1 and parameter="T_assign" and datausedname="12-month sample";
 loghr3_est=estimate;
 loghr3_se=stderr;
 total3=total;
 event3=event;
 keep allrx allrxname region region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev 
      disease disease_fmt disease2 disease2_fmt eventnumber eventname loghr3_est loghr3_se total3 event3;
run;
proc sort data=ce1;
 by allrx;
run;
proc sort data=ce2;
 by allrx;
run;
proc sort data=ce3;
 by allrx;
run;
data ce;
 merge ce1 ce2 ce3;
 by allrx;
run;
proc sql; 
  create table t99a_ce as
  select  * 
  from t99a,ce
  where t99a.allrx=ce.allrx;
quit;
ods listing close;
options nomprint nosymbolgen nomlogic nonotes;
%corrs6(corr1,1,1,corrs6);
%corrs12(corr2,1,1,corrs12);
ods listing;
options mprint symbolgen mlogic notes;
data corrs12;
 set corrs12;
 if study in (59) then delete; /** we don't need these since there is no ACR and we are using the one from corr6m for them **/
 drop beta1_ce_corr beta3_ce_corr beta4_ce_1y_corr beta4_ce_2y_corr beta4_ce_3y_corr beta4_ce_4y_corr chronic_t1y_ce_corr chronic_t2y_ce_corr 
      chronic_t3y_ce_corr chronic_t4y_ce_corr;
run;
proc sort data=corrs6;
 by study;
run;
proc sort data=corrs12;
 by study;
run;
data corrs;
 merge corrs6 corrs12;
 by study;
run;
data corrs_all;
 set corrs;
run;
proc sort data=corrs_all out=c1(keep=study allrx corr6_reason hess6_reason corr12_reason hess12_reason) nodupkey;
 by study;
run;
proc sort data=c1;
 by study;
run;
proc sort data=studydescrip;
 by study;
run;
data c1;
 merge c1 studydescrip(keep=study allrx);
 by study;
run;
data c2;
 set c1;
 do eventnumber=1 to 10;
 output;
 end;
run;
proc sort data=c2;
 by study eventnumber;
run;
proc sort data=corrs_all;
 by study eventnumber;
run;
data corrs_all;
 merge corrs_all(drop=corr6_reason hess6_reason corr12_reason hess12_reason) c2;
 by study eventnumber;
run;
data corrs_est0;
 set corrs_all;
 if eventnumber=. then delete;
run;
/** set this to the max **/
proc sql noprint;
 create table corrs_est as
 select *, max(beta1_up6_corr) as mbeta1_up6_corr, max(beta3_up6_corr) as mbeta3_up6_corr, max(beta4_up6_1y_corr) as mbeta4_up6_1y_corr, max(beta4_up6_2y_corr) as mbeta4_up6_2y_corr, 
           max(beta4_up6_3y_corr) as mbeta4_up6_3y_corr, max(beta4_up6_4y_corr) as mbeta4_up6_4y_corr, max(chronic_t1y_up6_corr) as mchronic_t1y_up6_corr, max(chronic_t2y_up6_corr) as mchronic_t2y_up6_corr,
		   max(chronic_t3y_up6_corr) as mchronic_t3y_up6_corr, max(chronic_t4y_up6_corr) as mchronic_t4y_up6_corr,
		   max(beta1_up12_corr) as mbeta1_up12_corr, max(beta3_up12_corr) as mbeta3_up12_corr, max(beta4_up12_1y_corr) as mbeta4_up12_1y_corr, max(beta4_up12_2y_corr) as mbeta4_up12_2y_corr, 
           max(beta4_up12_3y_corr) as mbeta4_up12_3y_corr, max(beta4_up12_4y_corr) as mbeta4_up12_4y_corr, max(chronic_t1y_up12_corr) as mchronic_t1y_up12_corr, max(chronic_t2y_up12_corr) as mchronic_t2y_up12_corr,
		   max(chronic_t3y_up12_corr) as mchronic_t3y_up12_corr, max(chronic_t4y_up12_corr) as mchronic_t4y_up12_corr
from corrs_est0
group by study;
quit;
data corrs_est;
 set corrs_est;
 beta1_up6_corr=mbeta1_up6_corr;
 beta3_up6_corr=mbeta3_up6_corr;
 beta4_up6_1y_corr=mbeta4_up6_1y_corr;
 beta4_up6_2y_corr=mbeta4_up6_2y_corr;
 beta4_up6_3y_corr=mbeta4_up6_3y_corr;
 beta4_up6_4y_corr=mbeta4_up6_4y_corr;
 chronic_t1y_up6_corr=mchronic_t1y_up6_corr;
 chronic_t2y_up6_corr=mchronic_t2y_up6_corr;
 chronic_t3y_up6_corr=mchronic_t3y_up6_corr;
 chronic_t4y_up6_corr=mchronic_t4y_up6_corr;
 beta1_up12_corr=mbeta1_up12_corr;
 beta3_up12_corr=mbeta3_up12_corr;
 beta4_up12_1y_corr=mbeta4_up12_1y_corr;
 beta4_up12_2y_corr=mbeta4_up12_2y_corr;
 beta4_up12_3y_corr=mbeta4_up12_3y_corr;
 beta4_up12_4y_corr=mbeta4_up12_4y_corr;
 chronic_t1y_up12_corr=mchronic_t1y_up12_corr;
 chronic_t2y_up12_corr=mchronic_t2y_up12_corr;
 chronic_t3y_up12_corr=mchronic_t3y_up12_corr;
 chronic_t4y_up12_corr=mchronic_t4y_up12_corr;
 drop mbeta1_up6_corr mbeta3_up6_corr mbeta4_up6_1y_corr mbeta4_up6_2y_corr mbeta4_up6_3y_corr mbeta4_up6_4y_corr mchronic_t1y_up6_corr mchronic_t2y_up6_corr mchronic_t3y_up6_corr mchronic_t4y_up6_corr
      mbeta1_up12_corr mbeta3_up12_corr mbeta4_up12_1y_corr mbeta4_up12_2y_corr mbeta4_up12_3y_corr mbeta4_up12_4y_corr mchronic_t1y_up12_corr mchronic_t2y_up12_corr mchronic_t3y_up12_corr mchronic_t4y_up12_corr;
run;
data corrs_est1;
 set corrs_est;
 if corr6_reason in ("NOTE: GCONV convergence criterion satisfied." "NOTE: ABSGCONV convergence criterion satisfied.") and compress(hess6_reason)="Hessianisp.d.withnoissues" then conv6=1;else conv6=0;
 if corr12_reason in ("NOTE: GCONV convergence criterion satisfied." "NOTE: ABSGCONV convergence criterion satisfied.") and compress(hess12_reason)="Hessianisp.d.withnoissues" then conv12=1;else conv12=0;
 if conv6=0 then do;
 beta1_ce_corr=.; beta3_ce_corr=.; beta4_ce_1y_corr=.;
 beta4_ce_2y_corr=.; beta4_ce_3y_corr=.;beta4_ce_4y_corr=.;
 up6_ce_corr=.; beta1_up6_corr=.;beta3_up6_corr=.;beta4_up6_1y_corr=.;
 beta4_up6_2y_corr=.; beta4_up6_3y_corr=.; beta4_up6_4y_corr=.;
 chronic_t1y_ce_corr=.; chronic_t2y_ce_corr=.; chronic_t3y_ce_corr=.;
 chronic_t4y_ce_corr=.; chronic_t1y_up6_corr=.; chronic_t2y_up6_corr=.;
 chronic_t3y_up6_corr=.; chronic_t4y_up6_corr=.;
end;
if conv12=0 then do;
 up12_ce_corr=.; beta1_up12_corr=.;beta3_up12_corr=.;beta4_up12_1y_corr=.;
 beta4_up12_2y_corr=.; beta4_up12_3y_corr=.; beta4_up12_4y_corr=.;
 chronic_t1y_up12_corr=.; chronic_t2y_up12_corr=.;
 chronic_t3y_up12_corr=.; chronic_t4y_up12_corr=.;
end;
drop conv6 conv12;
run;
proc sort data=corrs_est1;
 by allrx eventnumber;
run;
proc sort data=t99a_ce;
 by allrx eventnumber;
run;
data t99a_ce_corrs;
 merge t99a_ce corrs_est1;
 by allrx eventnumber;
run;
data delta_up1;
 set ACR.txt_effects_up2;
 if compress(datagrp1)="Overall";
 if compress(period)="2.6m";
 if compress(model)="2.ANCOVA";
 if compress(variable)="T_assign";
 loggmr6_est=estimate;
 loggmr6_se=se;
 gmr6=gmr;
 gmr6_lower=gmr_lcl95;
 gmr6_upper=gmr_ucl95;
 total6=_p_+_edf_;
 keep allrx total6 loggmr6_est loggmr6_se gmr6 gmr6_lower gmr6_upper;
run;
data delta_up2;
 set ACR.txt_effects_up2;
 if compress(datagrp1)="Overall";
 if compress(period)="3.12m";
 if compress(model)="2.ANCOVA";
 if compress(variable)="T_assign";
 loggmr12_est=estimate;
 loggmr12_se=se;
 gmr12=gmr;
 gmr12_lower=gmr_lcl95;
 gmr12_upper=gmr_ucl95;
 total12=_p_+_edf_;
 keep allrx total12 loggmr12_est loggmr12_se gmr12 gmr12_lower gmr12_upper;
run;
/** Get bootstrap correlations **/
data boot_corrs6m;
 set ACR.ratios_corrs6m;
 if datagrp2=1;
 boot_up6_ce_corr=corr_ratio2;
 keep allrx eventnumber boot_up6_ce_corr;
run;
data boot_corrs12m;
 set ACR.ratios_corrs12m;
 if datagrp2=1;
 boot_up12_ce_corr=corr_ratio2;
 keep allrx eventnumber boot_up12_ce_corr;
run;
proc sort data=delta_up1;
 by allrx;
run;
proc sort data=delta_up2;
 by allrx;
run;
proc sort data=boot_corrs6m;
 by allrx;
run;
proc sort data=boot_corrs12m;
 by allrx;
run;
proc sort data=t99a_ce_corrs;
 by allrx;
run;
data t99a_ce_up_corrs;
 merge t99a_ce_corrs(in=in1) delta_up1 delta_up2 boot_corrs6m boot_corrs12m;
 by allrx;
run;
proc sort data=t99a_ce_up_corrs;
 by allrx;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
data t99a_ce_up_corrs;
 merge t99a_ce_up_corrs(in=in1) zallrxstudies(in=in2);
 by allrx;
 if in1;
run;
proc sort data=t99a_ce_up_corrs;
 by zallrx eventnumber;
run;
%zexportcsv(t99a_ce_up_corrs,nt99a_ce_up_corrs_updated,&path2\analysis_egfrslope\&t.\datasets);
data SASdata.nt99a_ce_up_corrs_updated;
 set t99a_ce_up_corrs;
run;
%zexportcsv(t99a_ce_up_corrs,nt99a_ce_up_corrs_updated,&path2\analysis_egfrslope\&t.\&t._exports);
data Exports.nt99a_ce_up_corrs_updated;
 set t99a_ce_up_corrs;
run;
/** slope dataset for ma **/
data zacute;
 length parameter $16. parameternumber 8.;
 set SASdata.nfirstmodelinseqperstudyt99;
 parameter="zAcute";
 estimate=zbeta11_beta12_est;
 se=zbeta11_beta12_se;
 estimate1=zbeta11_est;
 se1=zbeta11_se;
 estimate2=zbeta12_est;
 se2=zbeta12_se;
 parameternumber=-1;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data acute;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Acute";
 estimate=beta11_beta12_est;
 se=beta11_beta12_se;
 estimate1=beta11_est;
 se1=beta11_se;
 estimate2=beta12_est;
 se2=beta12_se;
 parameternumber=0;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data chronic;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Chronic";
 estimate=beta31_beta32_est;
 se=beta31_beta32_se;
 estimate1=beta31_est;
 se1=beta31_se;
 estimate2=beta32_est;
 se2=beta32_se;
 parameternumber=1;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data total_1y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Total 1y";
 estimate=beta41_42_1y_est;
 se=beta41_42_1y_se;
 estimate1=beta41_1y_est;
 se1=beta41_1y_se;
 estimate2=beta42_1y_est;
 se2=beta42_1y_se;
 parameternumber=2;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data total_2y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Total 2y";
 estimate=beta41_42_2y_est;
 se=beta41_42_2y_se;
 estimate1=beta41_2y_est;
 se1=beta41_2y_se;
 estimate2=beta42_2y_est;
 se2=beta42_2y_se;
 parameternumber=3;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data total_3y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Total 3y";
 estimate=beta41_42_3y_est;
 se=beta41_42_3y_se;
 estimate1=beta41_3y_est;
 se1=beta41_3y_se;
 estimate2=beta42_3y_est;
 se2=beta42_3y_se;
 parameternumber=4;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data total_4y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Total 4y";
 estimate=beta41_42_4y_est;
 se=beta41_42_4y_se;
 estimate1=beta41_4y_est;
 se1=beta41_4y_se;
 estimate2=beta42_4y_est;
 se2=beta42_4y_se;
 parameternumber=5;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data chronic_t1y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Chronic-Total 1y";
 estimate=chronic_t1y_est;
 se=chronic_t1y_se;
 parameternumber=6;
 keep study parameter parameternumber estimate se zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt pooled pooled_fmt intervention intervention_fmt
      intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data chronic_t2y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Chronic-Total 2y";
 estimate=chronic_t2y_est;
 se=chronic_t2y_se;
 parameternumber=7;
 keep study parameter parameternumber estimate se zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt pooled pooled_fmt intervention intervention_fmt
      intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data chronic_t3y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Chronic-Total 3y";
 estimate=chronic_t3y_est;
 se=chronic_t3y_se;
 parameternumber=8;
 keep study parameter parameternumber estimate se zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt pooled pooled_fmt intervention intervention_fmt
      intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data chronic_t4y;
 length parameter $16. parameternumber 8.;
 set t99a_ce_up_corrs;
 if eventnumber=1;
 parameter="Chronic-Total 4y";
 estimate=chronic_t4y_est;
 se=chronic_t4y_se;
 parameternumber=9;
 keep study parameter parameternumber estimate se zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt pooled pooled_fmt intervention intervention_fmt
      intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data slopes_t99_ma;
 set zacute acute chronic total_1y total_2y total_3y total_4y chronic_t1y chronic_t2y chronic_t3y chronic_t4y;
run;
proc sort data=slopes_t99_ma;
 by study;
run;
proc sort data=txt01;
 by study;
run;
data slopes_t99_ma;
 merge slopes_t99_ma txt01;
 by study;
run;
proc sort data=slopes_t99_ma;
 by parameternumber zallrx;
run;
data SASdata.nslopes_t99_ma_updated;
 set slopes_t99_ma;
run;
%zexportcsv(slopes_t99_ma,nslopes_t99_ma_updated,&path2\analysis_egfrslope\&t.\datasets);

data Exports.nslopes_t99_ma_updated;
 set slopes_t99_ma;
run;
%zexportcsv(slopes_t99_ma,nslopes_t99_ma_updated,&path2\analysis_egfrslope\&t.\&t._exports);

/** ce dataset for ma **/
data ce_t99_ma;
 set t99a_ce_up_corrs;
 estimate=loghr1_est;
 se=loghr1_se;
 total=total1;
 event=event1;
 keep study eventnumber eventname estimate se zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt pooled pooled_fmt intervention intervention_fmt
      intervention_abrev disease disease_fmt disease2 disease2_fmt total event;
run;
proc sort data=ce_t99_ma;
 by eventnumber zallrx;
run;
data SASdata.nce_t99_ma_updated;
 set ce_t99_ma;
run;
%zexportcsv(ce_t99_ma,nce_t99_ma_updated,&path2\analysis_egfrslope\&t.\datasets);

data Exports.nce_t99_ma_updated;
 set ce_t99_ma;
run;
%zexportcsv(ce_t99_ma,nce_t99_ma_updated,&path2\analysis_egfrslope\&t.\&t._exports);



