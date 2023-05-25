%let t=truncation_99;
%let path1=d:\userdata\shared\ckd_endpts\root;

libname Results "&path1\analysis_egfrslope\&t.\models\results";
libname Exports  "&path1\analysis_egfrslope\&t.\&t._exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path1\macros");
%macro getcorr(datain,dataout);
proc datasets nolist;
 delete t0 t1 t1_study t2 t3;
run;
quit;
data t0;
 set results.&datain;
run;
data t1;
 length var $5.;
 set t0;
 if compress(label) in ("trtmenteffectinACRchange" "LogHR(TrtID=2:TrtID=1)forevent1" "LogHR(TrtID=2:TrtID=1)forevent2"
                        "LogHR(TrtID=2:TrtID=1)forevent3" "beta12-beta11" "beta11" "beta12" "beta42-beta41att=36Months"
						 "totalslope1att=36Months" "totalslope2att=36Months"
                        "MeanBaselineGFR" 
                        "MeanlgACR" "trtmenteffectindeltaGFRacute" "kappa" "beta12/beta11");
 if compress(label) in ("trtmenteffectinACRchange")        then var="dacr ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent1") then var="ev1  ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent2") then var="ev2  ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent3") then var="ev3  ";
 if compress(label) in ("beta12-beta11")                   then var="chr  ";
 if compress(label) in ("beta11")                          then var="chr1 ";
 if compress(label) in ("beta12")                          then var="chr2 ";
 if compress(label) in ("beta42-beta41att=36Months")       then var="ts3y ";
 if compress(label) in ("totalslope1att=36Months")         then var="ts3y1";
 if compress(label) in ("totalslope2att=36Months")         then var="ts3y2";
 if compress(label) in ("MeanBaselineGFR")                 then var="gfr  ";
 if compress(label) in ("MeanlgACR")                       then var="lacr ";
 if compress(label) in ("trtmenteffectindeltaGFRacute")    then var="dgfr ";
 if compress(label) in ("kappa")                           then var="kappa";
 if compress(label) in ("beta12/beta11")                   then var="rchr ";
run;
proc sort data=t1;
 by row;
run;
data t1_study;
 set t1;
 if _n_=1;
run;
proc sql noprint;
select study into :study
       from t1_study;
quit;
proc sql noprint;
select row,var into :rows separated by ' ', :rowsvars separated by ' ' 
       from t1;
quit;
%macro keep;
data t2;
 set t1;
 keep var %do i=1 %to %numwords(&rows);%let k=%scan(&rows,&i,' '); corr&k %end;;
run;
data t3;
 set t2;
 %do i=1 %to %numwords(&rows);
 %let k=%scan(&rows,&i,' ');
 %let name=%scan(&rowsvars,&i,' ');
 rename corr&k=&name;
 %end;
run;
%mend;
%keep;
%macro tr_keep;
proc datasets nolist;
 delete %do i=1 %to %numwords(&rows); t3_&i %end;;
run; 
quit;
%do i=1 %to %numwords(&rows);
%let name=%scan(&rowsvars,&i,' ');
proc transpose data=t3 out=t3_&i(drop=_name_) prefix=&name._ let suffix=_corr;
var &name;
id var;
run;
%end;
data &dataout;
 length study 8.;
 merge %do i=1 %to %numwords(&rows); t3_&i %end;;
 study=&study;
run; 
proc datasets nolist;
 delete %do i=1 %to %numwords(&rows); t3_&i %end;;
run; 
quit;
%mend;
%tr_keep;
proc datasets nolist;
 delete t0 t1 t1_study t2 t3;
run;
quit;
%mend;
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
%getcorr(cor1,zcor1);
data allcorr;
 set zcor1;
 drop dacr_dacr_corr ev1_ev1_corr ev2_ev2_corr ev3_ev3_corr chr_chr_corr chr1_chr1_corr chr2_chr2_corr 
      ts3y_ts3y_corr ts3y1_ts3y1_corr ts3y2_ts3y2_corr gfr_gfr_corr lacr_lacr_corr dgfr_dgfr_corr kappa_kappa_corr
      rchr_rchr_corr;
run;
data Exports.allcorr;
 set allcorr;
run;
%zexportcsv(allcorr,allcorr,&path1\analysis_egfrslope\&t.\&t._exports);











