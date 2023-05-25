%let t=truncation_99;
%let path1=d:\userdata\shared\ckd_endpts\root_new;

libname Master "&path1\steps\maindatasets";
libname SASdata  "&path1\analysis_egfrslope\&t.\datasets";
libname Exports  "&path1\analysis_egfrslope\&t.\&t._exports";
  
%Global eGFR0;
%let eGFR0=b_CKDegfr;

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path1\macros");


data ddshort;
 set Master.fdac2_tx_allendpts;
 if b_ckdegfr=. then delete;
run;
data ddlong;
 set Master.fdac2_visits;
 if visit_time=. or visit_time <= 0 or fu_ckdegfr=. then delete;
run;
proc sort data=ddshort out=ddshort_unique(keep=new_id study_num) nodupkey;
 by new_id study_num;
run;
proc sort data=ddshort out=fu_dx(keep=new_id study_num fu_dx) nodupkey;
 by new_id study_num;
run;
proc sort data=ddlong out=ddlong_unique(keep=new_id study_num) nodupkey;
 by new_id study_num;
run;
data unique_ids;
 merge ddshort_unique ddlong_unique;
 by new_id study_num;
run;
proc sort data=ddshort;
 by new_id study_num;
run;
proc sort data=unique_ids;
 by new_id study_num;
run;
data dshort;
 merge ddshort(in=in1) unique_ids(in=in2);
 by new_id study_num;
 if in1 and in2;
run;
proc sort data=ddlong;
 by new_id study_num;
run;
proc sort data=unique_ids;
 by new_id study_num;
run;
data dlongx;
 merge ddlong(in=in1) unique_ids(in=in2) fu_dx;
 by new_id study_num;
 if in1 and in2;
run;
data dlongy;
 set dlongx;
 if visit_time > fu_dx then delete;
run;
data zdlongy;
 set dlongx;
 if visit_time > fu_dx;
run;
data dlong;
 set dlongy;
 drop fu_dx;
run;
options nonotes nomprint nosymbolgen nomlogic;
%datacreation(dlong,dshort,dx,4,240,10);
options notes mprint symbolgen mlogic;
data studies;
 set sasdata.studies;
run;
data StudyDescrip;
 set exports.StudyDescrip;
run;
/*
data Exports.StudyDescrip;
 set StudyDescrip;
run;
*/
%zexportcsv(StudyDescrip,StudyDescrip,&path1\analysis_egfrslope\&t.\&t._exports);
/*%zexportxlsx2007(StudyDescrip,StudyDescrip,&path1\analysis_egfrslope\&t.\&t._exports);*/




  