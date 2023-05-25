%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean4 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");

data dup;
 set pclean4.fda2_allrx;
 if compress(UP_MeasureToUse)="PER" then do;
	 delupro6=delupro6/1.67;
	 delupro12=delupro12/1.67;
 end;
 if compress(UP_MeasureToUse)="AER" then do;
	 delupro6=delupro6;
	 delupro12=delupro12;
 end;
 if compress(UP_MeasureToUse)="PCR" then do;
	 delupro6=delupro6/1.67;
	 delupro12=delupro12/1.67;
 end;
 if compress(UP_MeasureToUse)="ACR" then do;
	 delupro6=delupro6;
	 delupro12=delupro12;
 end;
 if compress(UP_MeasureToUse)="SPCR" then do;
	 delupro6=delupro6/1.67;
	 delupro12=delupro12/1.67; 
 end;
 if compress(UP_MeasureToUse)="SACR" then do;
	 delupro6=delupro6;
	 delupro12=delupro12;
 end;
run;
data delta6;
 set dup(in=in1) dup(in=in2);
 if datagrp2=1;
 if delupro6=. then delete;
 basevalue=zupro;
 fupvalue=delupro6+zupro;
 y=delupro6;
 logy=logdelupro6;
 ytime=uprotime6;
 period="1. 6m ";
 if in2 then do;
 allrx=1000;
 if pooled=2 then delete;
 end;
 keep basevalue fupvalue y logy ytime new_id allrx allrxname t_assign period disease disease_fmt;
run;
data delta6_all;
 set dup(in=in1) dup(in=in2);
 if datagrp2=1;
 if delupro6=. then delete;
 basevalue=zupro;
 fupvalue=delupro6+zupro;
 y=delupro6;
 logy=logdelupro6;
 ytime=uprotime6;
 period="1. 6m ";
 t_assign=2;
 if in2 then do;
 allrx=1000;
 if pooled=2 then delete;
 end;
 keep basevalue fupvalue y logy ytime new_id allrx allrxname t_assign period disease disease_fmt;
run;
data delta12;
 set dup(in=in1) dup(in=in2);
 if datagrp2=1;
 if delupro12=. then delete;
 basevalue=zupro;
 fupvalue=delupro12+zupro;
 y=delupro12;
 logy=logdelupro12;
 ytime=uprotime12;
 period="2. 12m";
 if in2 then do;
 allrx=1000;
 if pooled=2 then delete;
 end;
 keep basevalue fupvalue y logy ytime new_id allrx allrxname t_assign period disease disease_fmt;
run;
data delta12_all;
 set dup(in=in1) dup(in=in2);
 if datagrp2=1;
 if delupro12=. then delete;
 basevalue=zupro;
 fupvalue=delupro12+zupro;
 y=delupro12;
 logy=logdelupro12;
 ytime=uprotime12;
 period="2. 12m";
 t_assign=2;
 if in2 then do;
 allrx=1000;
 if pooled=2 then delete;
 end;
 keep basevalue fupvalue y logy ytime new_id allrx allrxname t_assign period disease disease_fmt;
run;
data deltaup;
 set delta6 delta6_all delta12 delta12_all;
run;
ods listing close;
proc means data=deltaup n mean std median p25 p75 min max maxdec=4;
 var basevalue fupvalue y logy ytime;
 class period allrx t_assign/*allrxname disease disease_fmt t_assign*/;
 ods output summary=out1;
run;
data deltaupsummary292018;
 set out1;
 drop nobs y_n vname_y vname_logy vname_ytime logy_n ytime_n y_min y_max logy_min logy_max
      vname_basevalue vname_fupvalue fupvalue_n;
run;
data deltaupsummary292018;
 set deltaupsummary292018;
 order=_n_;
run;
proc sort data=dup out=study(keep=allrx allrxname disease disease_fmt pooled pooled_fmt) nodupkey;
 by allrx;
run;
proc sort data=study;
 by allrx;
run;
proc sort data=deltaupsummary292018;
 by allrx;
run;
data deltaupsummary292018;
 merge study deltaupsummary292018;
 by allrx;
run;
data deltaupsummary292018;
 set deltaupsummary292018;
 if allrx=1000 then do;
 allrxname="Overall";
 disease_fmt="Overall";
 disease=1000;
 pooled=1000;
 pooled_fmt="Overall";
 end;
run;
proc sort data=deltaupsummary292018;
 by order;
run;
data deltaupsummary292018;
 set deltaupsummary292018;
 drop order;
run;
%zexportcsv(deltaupsummary292018,deltaupsummary,&path1\analysis_acr\acr_exports);
data Exports.deltaupsummary;
 set deltaupsummary292018;
run;