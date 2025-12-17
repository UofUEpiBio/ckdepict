%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\trunc24\datasets";
libname Results  "&path1\analysis_sets\trunc24\correlations\results";
libname Exports  "&path1\analysis_sets\trunc24\exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");

%macro getcorr(datain,dataout);
proc datasets nolist;
 delete t0 t1 t1_study t2 t3;
run;
quit;
data t0;
 set results.&datain;
run;
data t1;
 length var $7.;
 set t0;
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent1" 
                        "LogHR(TrtID=2:TrtID=1)forevent2"
                        "LogHR(TrtID=2:TrtID=1)forevent3" 
                        "LogHR(TrtID=2:TrtID=1)forevent4" 
                        "LogHR(TrtID=2:TrtID=1)forevent5"
                        "LogHR(TrtID=2:TrtID=1)forevent6"
                        "LogHR(TrtID=2:TrtID=1)forevent7"
                        "LogHR(TrtID=2:TrtID=1)forevent8" 
                        "beta12-beta11" "beta11" "beta12" 
						"beta31att=3Months" "beta32att=3Months" "beta32-beta31att=3Months"
						"MeanBaselineGFR" 
                        "MeanLogACR" 
                        "TrtmenteffectindeltaGFRacute" 
                        "kappa" "beta12/beta11");

 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent1") then var="ev1    ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent2") then var="ev2    ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent3") then var="ev3    ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent4") then var="ev4    ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent5") then var="ev5    ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent6") then var="ev6    ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent7") then var="ev7    ";
 if compress(label) in ("LogHR(TrtID=2:TrtID=1)forevent8") then var="ev8    ";

 if compress(label) in ("beta32-beta31att=3Months")        then var="dgfr3m ";
 if compress(label) in ("beta31att=3Months")               then var="dgfr3m1";
 if compress(label) in ("beta32att=3Months")               then var="dgfr3m2";

 if compress(label) in ("beta12-beta11")                   then var="chr    ";
 if compress(label) in ("beta11")                          then var="chr1   ";
 if compress(label) in ("beta12")                          then var="chr2   ";

 if compress(label) in ("MeanBaselineGFR")                 then var="gfr    ";
 if compress(label) in ("MeanLogACR")                      then var="lacr   ";
 if compress(label) in ("TrtmenteffectindeltaGFRacute")    then var="dgfr   ";
 if compress(label) in ("kappa")                           then var="kappa  ";
 if compress(label) in ("beta12/beta11")                   then var="rchr   ";
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
 drop ev1_ev1_corr ev2_ev2_corr ev3_ev3_corr ev4_ev4_corr ev5_ev5_corr ev6_ev6_corr ev7_ev7_corr ev8_ev8_corr
     dgfr3m_dgfr3m_corr dgfr3m1_dgfr3m1_corr dgfr3m2_dgfr3m2_corr chr_chr_corr chr1_chr1_corr chr2_chr2_corr
     gfr_gfr_corr lacr_lacr_corr dgfr_dgfr_corr kappa_kappa_corr rchr_rchr_corr;
run;
data Exports.allcorr;
 set allcorr;
run;
%zexportcsv(allcorr,allcorr,&path1\analysis_sets\trunc24\exports);

data SASdata.allcorr;
 set allcorr;
run;
%zexportcsv(allcorr,allcorr,&path1\analysis_sets\trunc24\datasets);





