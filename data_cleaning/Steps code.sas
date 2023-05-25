options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource ;
options mergenoby=WARN;run;

%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean "&path1\2 Clean data";


data pclean.newstudy_baseline; set pclean.baseline;
studyname="XYZ";
new_id=cat(study_num,"_",id);

mos_lvisit=.;
p90int=.;
mos_lscr=.;
base_oldscr=.;
Treat2=.;*update for each study;
Treat3=.;*update for each study;
base_24_creat_con=.;
base_spot_ucreat=.;
base_24_creat_tot=.;
mos_admvis1=.;*update for each study;

*Calculating CKD-EPI eGFR;
logbasescr=log(base_scr);
if  . < logbasescr <= log(0.7) then scr1=logbasescr-log(0.7);
if  . < logbasescr <= log(0.7) then scr2=0;
if  logbasescr > log(0.7)  then scr1=0;
if  logbasescr > log(0.7)  then scr2=logbasescr-log(0.7);

if  . < logbasescr <= log(0.9) then scr3=logbasescr-log(0.9);
if  . < logbasescr <= log(0.9) then scr4=0;
if  logbasescr > log(0.9)  then scr3=0;
if  logbasescr > log(0.9)  then scr4=logbasescr-log(0.9);

scr11=female*scr1;
scr12=(1-female)*scr3;
scr13=female*scr2+(1-female)*scr4;
b_CKDegfr=exp(4.951+0.018*female+0.146*black-0.007*age-0.329*scr11-0.411*scr12-1.209*scr13);
run;

		
data newstudy_upro; merge pclean.acr pclean.baseline;
by id;
studyname="XYZ";
new_id=cat(study_num,"_",id);
if .<spot_ualb_rat<2 then spot_ualb_rat=2;*update for alternative UP measure if SACR not available;
if spot_ualb_rat>10000 then spot_ualb_rat=10000;*update for alternative UP measure if SACR not available;

keep studyname study_num new_id	id	visit_time	spot_ualb_rat	_24_upro_tot	_24_upro_con	_24_ualb_tot	_24_ualb_con	_24_upro_rat	_24_ualb_rat	spot_upro_rat	spot_ualb_con	_24_uvol
age	black female				
base_spot_ualb_rat base_24_upro_tot base_24_upro_con base_24_ualb_tot base_24_ualb_con	base_24_upro_rat				
base_24_ualb_rat base_spot_upro_rat	base_spot_ualb_con base_24_uvol;
run;
	
data newstudy_egfr1; merge pclean.scr pclean.baseline;
by id;
studyname="XYZ";
new_id=cat(study_num,"_",id);
run;

data newstudy_egfr; set newstudy_egfr1;
if scr ne .;

if .<scr<0.4 then scr=0.4;
if scr>14 then scr=14;

logscr=log(scr);
age_time=age+visit_time/12;
base_oldscr=.;
old_scr=.;
	
if  . < logscr <= log(0.7) then scr1=logscr-log(0.7);
if  . < logscr <= log(0.7) then scr2=0;
if  logscr > log(0.7)  then scr1=0;
if  logscr > log(0.7)  then scr2=logscr-log(0.7);

if  . < logscr <= log(0.9) then scr3=logscr-log(0.9);
if  . < logscr <= log(0.9) then scr4=0;
if  logscr > log(0.9)  then scr3=0;
if  logscr > log(0.9)  then scr4=logscr-log(0.9);

scr11=female*scr1;
scr12=(1-female)*scr3;
scr13=female*scr2+(1-female)*scr4;
fu_CKDegfr=exp(4.951+0.018*female+0.146*black-0.007*age_time-0.329*scr11-0.411*scr12-1.209*scr13);

keep studyname study_num new_id	scr	visit_time	age	black	female	base_scr	base_spot_ualb_rat	b_CKDegfr	logscr	
age_time base_oldscr old_scr fu_CKDegfr;
run;

proc sort data=pclean.newstudy_upro; by new_id visit_time; run;
proc sort data=newstudy_egfr; by new_id visit_time; run;

data pclean.newstudy_egfr; merge pclean.newstudy_upro newstudy_egfr;
by new_id visit_time;
keep studyname study_num new_id	scr	visit_time	age	black	female	base_scr	base_spot_ualb_rat	b_CKDegfr	logscr	
age_time base_oldscr old_scr fu_CKDegfr spot_ualb_rat; *or whichever urine protein variable to use for the study;
run;
 

**check duplicates in baseline data;
data bl_duptest; set pclean.newstudy_baseline;
run;

proc sort data = bl_duptest nodupkey dupout=dups;
by new_id ;
run; 


**check for duplicate visit_times in egfr data;
data egfr_duptest; set pclean.newstudy_egfr;
run;

data egfr_duptest2; set egfr_duptest;
run;

proc sort data = egfr_duptest2 nodupkey dupout=egfr_dups;
by new_id visit_time;
run;

proc sort data = egfr_dups nodupkey dupout=egfr_dups2;
by new_id ;
run;

proc sort data=egfr_duptest; by new_id visit_time; run;
proc sort data=egfr_dups2; by new_id visit_time; run;

data egfr_dups_ids; set egfr_dups2;
keep new_id;
run;

data egfr_dups_only;
merge egfr_duptest egfr_dups_ids (in=a);
by new_id ;
if a=1;
run;

proc sort data=egfr_dups2; by new_id; run;
data lab; set  pclean.scr; 
if scr ne .;
study_num=...;
new_ID = cat(study_num,"_",ID);*update with the ID variable used in dataset scr;
run;

proc sort data= lab; by new_id; run;
data egfr_dups_orig;
merge egfr_dups2 (in=a) lab ;
by new_id;
if a=1;
run;
proc sort data=egfr_dups_orig; by new_id; run;


**check duplicates in upro data;
data upro_duptest; set pclean.newstudy_upro;
run;

proc sort data = upro_duptest nodupkey dupout=upro_dups;
by new_id visit_time;
run;



*****Check ACR eligibility;
data check1; set pclean.newstudy_baseline;
if base_spot_ualb_rat>. then have_acr=1;
else if base_spot_ualb_rat=. then have_acr=0;
run;

proc ttest data=check1;
class have_acr;
var age bmi base_scr sbp;
run;

***add code for N follow-up UP;

**plot GFR measurements over time;
ods graphics on;
ods pdf file="&path1\1 Data cleaning\GFR_over_time.pdf";
proc sgpanel data=pclean.newstudy_egfr;
 panelby t_Assign / columns=2;
 reg x=visit_time y=fu_CKDegfr/ cli clm;
run;
ods pdf close;
ods graphics off;


*Output summary of all variables part 1;
*********;

proc sort data=newstudy.newstudy_baseline; 
by t_Assign; 
run;
Ods excel file='&path1\1 Data cleaning\datachecks1.xlsx' 
options(sheet_interval='proc' sheet_name="newstudy" embedded_titles="yes") style=excel;
proc univariate data=pclean.newstudy_baseline; 
title "newstudy baseline";
run;
proc univariate data=pclean.newstudy_baseline; 
title "newstudy baseline by treatment arm";
by t_Assign;
run;
proc univariate data=pclean.newstudy_egfr; 
title "newstudy eGFR";
run;
proc univariate data=pclean.newstudy_upro; 
title "newstudy upro";
run;
ods excel close;



*********************************************************************************************

*discuss the results so far before running the rest of the code;

*********************************************************************************************


*********************************************************************************************
***PART I-of FDA conference 2 dataset development ***
1) Pooling baseline, eGFR and UPRP to make FDAC2_Baseline_170412 and FDAC2_visits_170412
2) Creating adm censoring
3) Study level indicator variables
4) Create indicator variable for visits post events and censoring
Lesley Inker and Andrew Simon - August 15, 2017
*********************************************************************************************;


*********************************************************************************************
*					Step1 : pooling baseline;


data pooled_bl; 
set pclean.newstudy_baseline;  

*Remove patients w/ missing required baseline variables; 
if age=. or  base_scr=. or  black =. or female=. or 
(base_24_ualb_tot =. and base_24_ualb_rat=. and base_24_ualb_con=. and base_spot_ualb_rat=. and base_spot_ualb_con=. and
base_24_upro_tot=. and  base_24_upro_rat=. and base_24_upro_con=. and base_spot_upro_rat=.) or
(mos_adm =. and mos_admvis1=.)
then delete; 

run;

*********************************************************************************************
		Step 2 
		1) defining kidney failure event to accomodate dial, transplant or ESRD study level variables
		2) create administrative censoring dates;


/*comments from tom which we will delete once finalized

 Let mos_d and mos_x denote the months from randomization to dialysis and death, respectively. I mos_adm is defined, then 
 max_mos_adm = max(mos_adm+1,mos_d,mos_x)
adj_mos_adm =   min(max_mos_adm,mos_adm+6); 

If mos_adm is not defined, then 
adj_mos_adm = mos_admvis1; 

Also, define 

altmax_mos_adm = max(mos_adm+1,mos_lvisit,mos_d,mos_x);
altadj_mos_adm = min(altmax_mos_adm,mos_adm+6);

if mos_adm is not defined, then 
altadj_mos_adm = mos_admvis1; 

We decided to think more about whether to modify mos_admvis1 = mos_lvisit + p90int + 6 at a later time. My current thought is to use mos_admvis1 = mos_lvisit + p90int + 1.
*/
*********************************************************************************************;

data pooled_bl1;
set pooled_bl;
kidney_fail=max(esrd, dial, tplnt);
mos_kidney_fail=min(mos_esrd, mos_dial, mos_tplnt);
if esrd =. and dial=. and tplnt=. then kidney_fail=0;

if mos_adm >. then do;
adm_studyendmos=mos_adm;
adm_1mos=adm_studyendmos+1;
adm_6mos=adm_studyendmos+6;
max_adm_studyend = max(adm_1mos,mos_kidney_fail,mos_death);
adj_adm_studyend =   min(max_adm_studyend ,adm_6mos); 
altmax_mos_adm = max(adm_1mos,mos_lvisit,mos_kidney_fail,mos_death);
altadj_mos_adm = min(altmax_mos_adm,adm_6mos);
end;


if mos_adm =. then do;
adm_studyendmos=mos_admvis1;
adm_1mos=mos_admvis1;
adm_6mos=mos_admvis1;
max_adm_studyend = mos_admvis1;
adj_adm_studyend =   mos_admvis1;
altmax_mos_adm = mos_admvis1;
altadj_mos_adm = mos_admvis1;  

end;

if death =. then death=0;
if diab=. then diab=0;

run;


*********************************************************************************************
*Step 3  Add study level variables;
*********************************************************************************************;

*update for new study;
data pooled_bl2; set pooled_bl1;length UP_MeasureToUse $ 5;
IF  study_num in (77,78)   THEN   do;   UP_MeasureToUse="SACR";  Include_ACR=1; end; 	
run;

*update for new study;
data pooled_bl3; set pooled_bl2;
IF  study_num in (77, 78)   THEN do;  flg_adm=1; region=3;	Disease=8;	Disease2=2; diab_type=2;   end;	*International, Diabetes;

if flg_adm = 0 or flg_adm=1 then study_adm=1;
else if flg_adm = . then study_adm=0;
else study_adm=.;
run;



****************************************************************************************************;
*STep 2
1) check missingness
2) perm dataset-FDAC2_Baseline;
****************************************************************************************************;


PROC TABULATE data=pooled_bl3;  
CLASS studyname;  
VAR age female black diab
p90int 	mos_lscr
	mos_lvisit 
	study_adm
max_adm_studyend
adj_adm_studyend  
altmax_mos_adm 
altadj_mos_adm 
b_CKDegfr kidney_fail death mos_kidney_fail mos_death mos_admvis1 mos_adm adm_1mos 
adm_6mos base_24_upro_tot base_24_upro_rat  base_24_ualb_tot  
base_24_ualb_rat base_24_upro_con base_24_ualb_con base_spot_ualb_rat base_spot_upro_rat 
base_spot_ualb_con adm_studyendmos Include_ACR;  

  
TABLE 
	studyname ,
	mos_admvis1 * (N Nmiss mean min max)   
	mos_adm * (N Nmiss mean min max) 
	p90int * (N Nmiss ) 
	study_adm * (N Nmiss ) 
	mos_lscr *(N Nmiss mean min max) 
	mos_lvisit *(N Nmiss mean min max)
	adm_studyendmos* (N Nmiss mean min max)   
	adm_1mos * (N Nmiss mean min max) 
	adm_6mos * (N Nmiss mean min max)  
	max_adm_studyend  * (N Nmiss mean min max) 
	adj_adm_studyend  * (N Nmiss mean min max)  
	altmax_mos_adm  * (N Nmiss mean min max) 
	altadj_mos_adm  * (N Nmiss mean min max) 
 	mos_kidney_fail mos_death * (N Nmiss mean min max) 

	age * (N Nmiss )   
	female * (N Nmiss) 
	b_CKDeGFR* (N Nmiss )   
	kidney_fail * (N Nmiss) 
	death * (N Nmiss) 
	diab *  (N Nmiss) 
	Include_ACR * (N Nmiss) 
; 
RUN;
proc freq data=pooled_bl3  ;  
tables include_acr*study_num / norow nocol nopercent ;
run;

**make sure every person has at least one of these;
data check_nomiss_upro; set pooled_bl3;
if base_24_upro_tot=. and base_24_upro_rat=. and base_24_upro_con=. and
base_spot_upro_rat=. and
base_24_ualb_tot=. and base_24_ualb_rat=. and base_24_ualb_con=. and 
base_spot_ualb_rat=. and base_spot_ualb_con=.;
run;


*********************************************************************************************;
*********************************************************************************************
*Step 3 pooled visit by first pooling egfr and upro

1) merging eGFR and UP into visits w data on adm censorong
2) create indicator variable for visits after dialysis  (visitpost_dial)
3) create indicator variable for vists after censoring  (visitpost_adm)
4) create indicator variable for vists after death  (visitpost_death)
5) make permanent visit level dataset -FDAC2_visits. 
**********************************************************************************************
********************************************************************************************;

data pooled_upro; 
set pclean.newstudy_upro;
drop studyname female black  age;
run;

data pooled_upro1; 
retain new_id study_num visit_time base_24_upro_tot _24_upro_tot 
base_24_upro_con _24_upro_con base_24_ualb_tot _24_ualb_tot base_24_ualb_con 
_24_ualb_con base_24_upro_rat _24_upro_rat base_24_ualb_rat _24_ualb_rat base_spot_ualb_rat 
spot_ualb_rat base_spot_upro_rat spot_upro_rat base_spot_ualb_con spot_ualb_con 
 _24_uvol base_24_uvol ;
set  pooled_upro; 
run;

*Pool egfr dataset - old egfr dataset is one row per patient;
data pooled_egfr; 
set pclean.newstudy_egfr;
drop base_oldscr old_scr allrx studyname female black age mos_adm mos_admvis1; 
run;

data pooled_egfr; 
retain new_id  study_num visit_time base_scr scr age_time b_CKDegfr fu_CKDegfr ;
set  pooled_egfr; 
if study_num not in (21, 35);  *elnt, cattran;
run;
data a;
set pooled_egfr;
if scr=.;run;


data pooled_base_adm; set pooled_bl3; *or set pclean.FDAconf2_Baseline;
keep kidney_fail mos_kidney_fail death mos_death 
adm_1mos adm_6mos adm_studyendmos /*adm_dx*/
new_id 
study_num studyname
female black  age;
run;

proc sort data=pooled_upro1;by study_num new_id;
proc sort data=pooled_egfr;by study_num new_id;

*Merge eGFR and UPRO visits datasets;
data visits;
merge pooled_egfr  pooled_upro1  ; 
by study_num new_id visit_time ; *Added visit_time here;
run;

proc sort data=visits; by study_num new_id; run;
proc sort data=pooled_base_adm;by study_num new_id;
run;

*Merge Visits with baseline adm variable, keep only IDs that are in base and visits;
data visits2;
merge visits (in=a) pooled_base_adm (in=b); 
by  study_num new_id;
if a=1 and b=1;
if age_time=. then age_time = age+(visit_time/12);
run;

data visits3; set visits2;
if scr =. and 
(_24_ualb_tot =. and _24_ualb_rat=. and _24_ualb_con=. and spot_ualb_rat=. and spot_ualb_con=. and
_24_upro_tot=. and  _24_upro_rat=. and _24_upro_con=. and spot_upro_rat=.)
then delete; 
drop base_scr base_24_ualb_con base_24_ualb_rat base_24_ualb_rat base_24_ualb_tot
base_24_upro_con base_24_upro_rat base_24_upro_tot base_24_uvol b_CKDegfr; *these baseline vars are re-added below;
run;
*Above check shows all have at least one upro or scr value;

*In Visits dataset, some rows are missing baseline variables because of egfr/upro dataset merge 
(due to having visits where only scr was taken or only upro was taken).Here we need to get the baseline upro 
and baseline egfr variables back into Visits dataset;
data base_vars; set pooled_bl3;
keep new_id base_scr base_24_ualb_con base_24_ualb_rat base_24_ualb_rat base_24_ualb_tot
base_24_upro_con base_24_upro_rat base_24_upro_tot base_24_uvol b_CKDegfr;
run;

proc sort data=pooled_bl3;
by new_id;
run;
proc sort data=visits3;
by new_id;
run;

data visits4;
merge visits3 (in=a) pooled_bl3 (in=b);
by new_id;
keep _24_ualb_con _24_ualb_rat _24_ualb_tot _24_upro_con _24_upro_rat _24_upro_tot _24_uvol
adm_1mos adm_6mos adm_studyendmos age age_time
b_CKDegfr base_24_ualb_con base_24_ualb_rat base_24_ualb_tot base_24_upro_con
base_24_upro_rat base_24_upro_tot base_24_uvol base_scr base_spot_ualb_con base_spot_ualb_rat
base_spot_upro_rat black death female fu_CKDegfr kidney_fail mos_death
mos_kidney_fail new_id
scr spot_ualb_con spot_ualb_rat spot_upro_rat study_num studyname visit_time;
if a=1;
run;

data visits4;
retain new_id study_num studyname visit_time age age_time black female
base_scr scr b_CKDegfr fu_CKDegfr 
_24_ualb_con _24_ualb_rat _24_ualb_tot _24_upro_con _24_upro_rat _24_upro_tot _24_uvol  spot_ualb_con spot_ualb_rat spot_upro_rat  
base_24_ualb_con base_24_ualb_rat base_24_ualb_tot base_24_upro_con base_24_upro_rat base_24_upro_tot 
base_24_uvol  base_spot_ualb_con base_spot_ualb_rat base_spot_upro_rat
adm_1mos adm_6mos adm_studyendmos death kidney_fail mos_death mos_kidney_fail visitpost_adm visitpost_death visitpost_dial;
set visits4;
run;

*Save permanent interim visits dataset  - need to restrict to vists prior to dial, death, adm later;
data pclean.FDAC2_visits_interim; 
	set visits4; 
run;


*What to do with people who are enrolled but have no visits at follow up and have an event?;
*Proposal:  If no FU visits, censored at 1 yr. this way include events up to a year . in other words, overall, 
was agreement to include all participants in the denominator but for participants without visits, only include 
events if they had no visits within the first year
To do: To determine this, we should calculate the fractional of events that occurred in pts without visits 
happened within a year
*get dataset that includes only people at bl who have no visits;


*Add In Visits yes/no indicator variable to baseline dataset - indicates patient at baseline with no f/u visits;

data in_visits;set pclean.FDAC2_visits_interim; 
in_visits=1;
keep study_num new_id in_visits;
run;
proc sort data=in_visits NODUP ; by study_num new_id;run;
proc sort data=pooled_bl3; by study_num new_id;run;

data pooled_bl4; 
merge pooled_bl3 (in=a) in_visits (in=b);
by study_num new_id;
if a=1;
if in_visits=. then in_visits=0;
run;
*Save permanent baseline + endpts dataset;
data pclean.FDAC2_baseline; set pooled_bl4; 
run;
PROC FREQ DATA=pclean.FDAC2_Baseline; TABLES ESRD DEATH; RUN;


/*Compare unrestricted baseline to baseline dataset restricted to only those with f/u (in those who had events);
data before; set pooled_bl3;
ev_dx=max(kidney_fail, death);
run;
data after; set pooled_bl4;
ev_dx=max(kidney_fail, death);
run;

proc sql noprint;
create table table_before as
select study_num,count(*) as nbefore,sum (ev_dx) as ev_dx_before
from before
group by study_num;
quit;

proc sql noprint;
create table table_after as
select study_num,count(*) as nafter,sum (ev_dx) as ev_dx_after
from after
group by study_num;
quit;


proc sort data=table_before; by study_num; run;
proc sort data=table_after; by study_num; run;

data compare;
merge table_before table_after;
by study_num;
ndiff=nbefore-nafter;
ev_dx_diff=ev_dx_before-ev_dx_after;
run;
proc export 
  data=compare
  dbms=xlsx 
  outfile="D:Userdata\Shared\CKD_Endpts\FDA Conference 2\Data cleaning\Pooled\Compare_prepost_blrestriction.xlsx" 
  replace;
run;*/



/* Creates dataset with baseline upro values for Carly's upro comparisons;
data pooled_upro_baseline; set pooled_upro1;
keep new_id base_24_upro_tot 
base_24_upro_con  base_24_ualb_tot  base_24_ualb_con 
 base_24_upro_rat  base_24_ualb_rat  base_spot_ualb_rat 
 base_spot_upro_rat  base_spot_ualb_con spot_ualb_con ;
run;
proc sort data=pooled_upro_baseline nodupkey; by new_id; run;
 
data carlyfemale; set pclean.FDAC2_baseline;
keep new_id female; 
run;
data carly_upro; set pclean.FDAC2_VISITS;
if (_24_ualb_tot =. and _24_ualb_rat=. and _24_ualb_con=. and spot_ualb_rat=. and spot_ualb_con=. and
_24_upro_tot=. and  _24_upro_rat=. and _24_upro_con=. and spot_upro_rat=.) then delete;
drop base_24_upro_con  base_24_ualb_tot  base_24_ualb_con 
 base_24_upro_rat  base_24_ualb_rat  base_spot_ualb_rat 
 base_spot_upro_rat  base_spot_ualb_con spot_ualb_con ;
RUN;
proc sort data=carly_upro; by new_id; run;
proc sort data=pooled_upro_baseline; by new_id; run;
data carly_upro; 
merge carly_upro pooled_upro_baseline;
by new_id;
run;
data pclean.conf2_upro_carly;set carly_upro;
run;

*/


*********************************************************************************************
***PART II-of FDA conference 2 dataset development ***
Here we create a clean final treatment dataset with confirmed and non confirmed events (CALIBRATED)
This code is run per study and then combined with baseline for that study.
Ultimately will be pooled with other studies and with the orginal FDA treatment

1. Non-confirmed decline eGFR -- 30%, 40%, 57%
2. Confirmed decline eGFR--  30%, 40%, 57%
3. we have created non-confirmed alternatives events ( based on threshold egfr -- 30, 45)
4. we have created confirmed alternatives events ( based on threshold egfr -- 30, 45)
5. Baseline scr > 25ml and confirmed GFR < 15
6. Baseline scr > 25ml and confirmed GFR < 15
7. Doubling of scr
 
Lesley Inker and Andrew Simon - August 16, 2017
*********************************************************************************************
%include 'D:\userdata\Shared\CKD_Endpts\FDA Conference 2\Data cleaning\Individual study\Hm_AIM3_BASELINE_FORMATS_RRFIX.sas';

*****************************************************************************************************************
*****************************************************************************************************************
Step 1: 	1) Open datasets
			2) Use only visits if before dialysis and administrative censoring data + 1 month  (adm_1mos)
*****************************************************************************************************************
*****************************************************************************************************************;

data egfr1; 
	set pclean.FDAC2_visits_interim; 
run;
data item; 
	set pclean.FDAC2_baseline; 
run;
proc sort data=egfr1 ; by Study_num new_id  visit_time; run;
proc sort data=item; by study_num new_id; run;


*****************************************************************************************************************
*****************************************************************************************************************

	*Step 2:  1) Macros for creating nonconfirmed and 
				confirmed declined eGFR 30, 40 and 57% as well as our defined double
			     Administrative censoring for non events is adm_1mos
				
	          2) merging all the datasets together
*****************************************************************************************************************
*****************************************************************************************************************;


%macro Decline_egfr(data,value,varname,monthname,out);

data temp;   set &data;
declinedegfr=b_CKDegfr*(1-&value);
if fu_CKDegfr <= declinedegfr then &varname=1;
if fu_CKDegfr > declinedegfr then &varname=0;
if fu_CKDegfr =. then &varname=0;
if &varname=1 then &monthname=visit_time; 

run;


data evt;  set temp;  if &varname=1; run;
proc sort data=evt;   by new_id visit_time; run;
data evt1; set evt;
 by new_id visit_time;
 if first.new_id;
 &varname=1;
 keep study_num new_id visit_time &varname &monthname adm_1mos;
run;
proc sort data=evt1;  by new_id; run;

data nonevt;  set temp;  if &varname=0; run;
proc sort data=nonevt;  by new_id;run;

data nonevt;
 merge nonevt(in=in1) evt(in=in2);
 by new_id;
 if in1 and not in2;
run;

proc sort data=nonevt;  by new_id visit_time;run;

data evt2; set nonevt;
 by new_id visit_time;
 if last.new_id;
 &varname=0;
 &monthname= adm_1mos;
 keep study_num new_id &varname &monthname adm_1mos ;
run;

data &out;
 set evt1 evt2; 
keep study_num new_id &varname &monthname adm_1mos;
run;

proc sort data=&out; 
 by study_num  new_id;
run;

proc datasets;
delete evt evt1 evt2 nonevt temp;
run;
quit;

%mend Decline_egfr;

**********************************confirmed decline****************************;
 
%macro Decline_egfr_confirmed(indata,value,var,month,varname, monthname,outdata);

data egfr3; set &indata;
declinedegfr=b_CKDegfr*(1-&value);
if fu_CKDegfr <= declinedegfr then &var=1;
if fu_CKDegfr > declinedegfr then  &var=0;
if fu_CKDegfr =. then &var=0;
if &var ne . then &month=visit_time; 

run;

proc sort data=egfr3; by new_id visit_time; run;

** Creating dataset with the people with last visit_time event*****; 
data egfr4; set egfr3;
by new_id visit_time;
if last.new_id and &var=1 
then &varname=1;
keep new_id study_num visit_time b_CKDegfr fu_CKDegfr &varname &month adm_1mos;
run; 

data egfr_last; set egfr4;
keep new_id study_num visit_time b_CKDegfr fu_CKDegfr &varname &month adm_1mos;
where &varname=1; run;


proc sort data=egfr_last; by study_num new_id ;run;

**creating dataset with intermediate repeated event***; 
data egfr5; set egfr3;
lag_ev=lag(&var);
lag_mos=lag(&month);
run;

data egfr6; set egfr5; 
by new_id;
if first.new_id then lag_ev=.;
keep new_id study_num visit_time b_CKDegfr fu_CKDegfr &month &var lag_mos lag_ev adm_1mos; 
run;
proc sort data=egfr6;by new_id lag_mos; run;

data egfr7 ; set egfr6;
if &var=1 and lag_ev=1 then &varname=1;
if &varname=. then &varname=0;
run;
proc sort data=egfr7; by new_id lag_mos; run;

data egfr8 ; set egfr7 ;
by new_id lag_mos;
if &varname=1 then output;
run;

proc sort data=egfr8; by new_id &month; run;

data egfr9; set egfr8; 
by new_id &month;
if &varname=1 and first.new_id then output;
run;

** Creating only last egfr event data( without intermediate event)***;
proc sort data=egfr_last; by  new_id study_num;run;
data egfr_last; set egfr_last; rename &month=&monthname;run;

proc sort data=egfr9; by new_id study_num ;run;
data egfr9; set egfr9; rename lag_mos=&monthname;run;

data egfr10; merge egfr_last(in=in1) egfr9(in=in2); by new_id;
if in1 and not in2; run;

proc sort data=egfr10; by study_num new_id; run;

data egfr_event; set egfr9 egfr10;run;
data egfr_event; set egfr_event ; keep new_id study_num b_CKDegfr fu_CKDegfr &varname &monthname adm_1mos; run;

***Creating dataset with the people who has 0 event *****;
proc sql; create table egfr_count as
select *, max(&var) as egfr_max 
from egfr3
group by new_id;
quit;
data egfr_count1; set egfr_count;
if &var=0 and egfr_max=0 then ev0_con=1;
by new_id; run;

data egfr_count2; set egfr_count1;
by new_id visit_time;
if last.new_id  and
ev0_con=1 ;
keep new_id study_num visit_time b_CKDegfr fu_CKDegfr ev0_con &month adm_1mos; run; 

data egfr_count3; set egfr_count2;
if ev0_con=1 then &varname=0;
&monthname=&month; 
keep new_id study_num b_CKDegfr fu_CKDegfr &varname &monthname adm_1mos;
run;

** egfr_count3 data has all the people with 0 event.**;
proc sort data=egfr_count3; by study_num new_id ; run;

data out1; set egfr_event egfr_count3; run;


data out2; set egfr3;
if &var=1 then &varname=0;
if &var=0 then &varname=0;
&monthname=&month;
keep study_num new_id b_CKDegfr fu_CKDegfr visit_time &varname &monthname &month &var adm_1mos;
run;

proc sort data=out2; by  new_id study_num;run;

data out3; set out2;
by new_id ;
if last.new_id  and
&varname=0 ;
keep new_id study_num visit_time b_CKDegfr fu_CKDegfr &varname &var &monthname &month adm_1mos; run; 
proc sort data =out3; by  new_id study_num; run;
proc sort data =out1; by  new_id study_num; run;
data out4; merge out3(in=in1) out1(in=in2);by new_id;
if in1 and not in2; run;

data final1; set out1 out4; run;

proc sort data=final1; by study_num new_id ; run;

data final2; set final1; keep new_id study_num b_CKDegfr fu_CKDegfr &varname &monthname adm_1mos;
run;


data &outdata; set final2;
if &varname=0 then &monthname=adm_1mos;
run;

proc datasets; delete egfr3 egfr4 egfr_last egfr5 egfr6 egfr7 egfr8 egfr9 egfr10
egfr_event egfr_count egfr_count1 egfr_count2 egfr_count3 out1 out2 out3 out4 final1 final2 ;
run; quit;

%mend Decline_egfr_confirmed;


*Creating declined base_line eGFR to fixed threshold including egfr 15;
%macro Decline_eGFR_Thresh(data,minvalue, value,varname,monthname,out); run; 

data temp;  set &data ;

if b_CKDeGFR < &minvalue then &varname=0;
else if b_CKDeGFR >= &minvalue and  fu_CKDegfr <  &value then &varname=1;
else if b_CKDeGFR >= &minvalue and fu_CKDegfr >=  &value then &varname=0;
else  &varname=0;
if &varname=1 then &monthname=visit_time;  
run;


data evt;
 set temp;
 if &varname=1;
run;

proc sort data=evt; 
 by new_id visit_time;
run;

data evt1;
 set evt;
 by new_id visit_time;
 if first.new_id;
 &varname=1;
 keep study_num new_id visit_time &varname &monthname adm_1mos;
run;

data nonevt;
 set temp;
 if &varname=0;
run;

proc sort data=nonevt;
 by new_id;
run;

proc sort data=evt1;
 by new_id;
run;

data nonevt;
 merge nonevt(in=in1) evt(in=in2);
 by new_id;
 if in1 and not in2;
run;

proc sort data=nonevt; 
 by new_id visit_time;
run;

data evt2;
 set nonevt;
 by new_id visit_time;
 if last.new_id;
 &varname=0;
if adm_1mos >0 then &monthname= adm_1mos;
 keep study_num new_id &varname &monthname adm_1mos;
run;

data &out;
 set evt1 evt2;
 keep study_num new_id &varname &monthname adm_1mos; 
run;

proc sort data=&out; 
 by study_num new_id ;
run;


proc datasets;
delete evt evt1 evt2 nonevt temp;
run; 
quit;

%mend Decline_eGFR_Thresh;



*Creating declined base_line eGFR to fixed threshold including egfr 15 confirmed );
%macro Decline_eGFR_Thresh_confirmed(indata,minvalue, value,var,month,varname, monthname,outdata); 

data egfr3; set &indata;
if b_CKDeGFR <  &minvalue then &var=0;
else if b_CKDeGFR >= &minvalue and  fu_CKDegfr <  &value then &var=1;
else if b_CKDeGFR >= &minvalue and fu_CKDegfr >=  &value then &var=0;
if fu_CKDegfr =. then &var=0;
if &var ne . then &month=visit_time; 
run;


proc sort data=egfr3; by new_id visit_time; run;

** Creating dataset with the people with last visit_time event*****; 
data egfr4; set egfr3;
by new_id visit_time;
if last.new_id and &var=1 
then &varname=1;
keep new_id study_num visit_time &varname &month adm_1mos;
run; 


data egfr_last; set egfr4;
keep new_id study_num visit_time &varname &month adm_1mos;
where &varname=1; run;


proc sort data=egfr_last; by study_num new_id ;run;

**creating dataset with intermediate repeated event***; 
data egfr5; set egfr3;
lag_ev=lag(&var);
lag_mos=lag(&month);
run;

data egfr6; set egfr5; 
by new_id;
if first.new_id then lag_ev=.;
keep new_id study_num visit_time &month &var lag_mos lag_ev adm_1mos; 
run;
proc sort data=egfr6;by new_id lag_mos; run;

data egfr7 ; set egfr6;
if &var=1 and lag_ev=1 then &varname=1;
if &varname=. then &varname=0;
run;
proc sort data=egfr7; by new_id lag_mos; run;

data egfr8 ; set egfr7 ;
by new_id lag_mos;
if &varname=1 then output;
run;

proc sort data=egfr8; by new_id &month; run;

data egfr9; set egfr8; 
by new_id &month;
if &varname=1 and first.new_id then output;
run;

** Creating only last egfr event data( without intermediate event)***;
proc sort data=egfr_last; by  new_id study_num;run;
data egfr_last; set egfr_last; rename &month=&monthname;run;

proc sort data=egfr9; by new_id study_num ;run;
data egfr9; set egfr9; rename lag_mos=&monthname;run;

data egfr10; merge egfr_last(in=in1) egfr9(in=in2); by new_id;
if in1 and not in2; run;

proc sort data=egfr10; by study_num new_id; run;

data egfr_event; set egfr9 egfr10;run;
data egfr_event; set egfr_event ; keep new_id study_num &varname &monthname adm_1mos; run;

***Creating dataset with the people who has 0 event *****;
proc sql; create table egfr_count as
select *, max(&var) as egfr_max 
from egfr3
group by new_id;
quit;
data egfr_count1; set egfr_count;
if &var=0 and egfr_max=0 then ev0_con=1;
by new_id; run;

data egfr_count2; set egfr_count1;
by new_id visit_time;
if last.new_id  and
ev0_con=1 ;
keep new_id study_num visit_time ev0_con &month adm_1mos; run; 

data egfr_count3; set egfr_count2;
if ev0_con=1 then &varname=0;
&monthname=&month; 
keep new_id study_num &varname &monthname adm_1mos;
run;

** egfr_count3 data has all the people with 0 event.**;
proc sort data=egfr_count3; by study_num new_id ; run;

data out1; set egfr_event egfr_count3; run;


data out2; set egfr3;
if &var=1 then &varname=0;
if &var=0 then &varname=0;
&monthname=&month;
keep study_num new_id visit_time &varname &monthname &month &var adm_1mos;
run;
proc sort data=out2; by  new_id study_num;run;
data out3; set out2;
by new_id ;
if last.new_id  and
&varname=0 ;
keep new_id study_num visit_time &varname &var &monthname &month adm_1mos; run; 
proc sort data =out3; by  new_id study_num; run;
proc sort data =out1; by  new_id study_num; run;
data out4; merge out3(in=in1) out1(in=in2);by new_id;
if in1 and not in2; run;

data final1; set out1 out4; run;

proc sort data=final1; by study_num new_id ; run;

data final2; set final1; keep new_id study_num &varname &monthname adm_1mos;
run;


data &outdata; set final2;
if &varname=0  then &monthname=adm_1mos;
run;
/*
*proc datasets; delete egfr3 egfr4 egfr_last egfr5 egfr6 egfr7 egfr8 egfr9 egfr10
*egfr_event egfr_count egfr_count1 egfr_count2 egfr_count3 out1 out2 out3 out4 final1 final2 ;
*run; quit;*/

%mend Decline_eGFR_Thresh_confirmed;



%Macro double  (data);
*Calculate doubling;
proc sort data = &data; by study_num new_id visit_time; run; 		

data fupscr;  set &data; 
     if base_scr > . and scr > . and visit_time > 0;
	 scr_ratio = scr/base_scr;																				
data doublescr;  set fupscr; 
	 if scr_ratio >= 2;
	 double = 1;
	mos_double = visit_time;run;																				
data doublescr; set doublescr; by study_num new_id visit_time;
     if first.new_id;
	 keep study_num new_id double mos_double adm_1mos;
     run;
proc sort; by new_id;run;


data nodouble;  set fupscr;  if scr_ratio<2;double=0; run;
proc sort data=nodouble;  by new_id;run;


data nodouble1;
 merge nodouble(in=in1) doublescr(in=in2);
 by new_id;
 if in1 and not in2;
run;

data nodouble2; set nodouble1;
 by new_id visit_time;
 if last.new_id;

 mos_double= adm_1mos;
 keep study_num new_id double mos_double adm_1mos ;
run;

data double;
 set doublescr nodouble2; 
keep study_num new_id double mos_double adm_1mos;
run;

proc sort data=double;  by study_num  new_id;run;

proc datasets;  delete nodouble nodouble1 nodouble2 doublescr fupscr; run;
quit;
%mend double;




%Decline_egfr(egfr1,0.3,ev_30_p,mos_30_p,egfr30);   * 30% egfr change*;
%Decline_egfr(egfr1,0.4,ev_40_p,mos_40_p,egfr40);   * 40% egfr change*;
%Decline_egfr(egfr1,0.57,ev_57_p,mos_57_p,egfr57);  * 57% egfr change*;


%Decline_egfr_confirmed(egfr1,.30,ev_30_p,mos_30_p,ev_30_p_con,mos_30_p_con,data_30_p_con);  *30% egfr change confirmed*;
%Decline_egfr_confirmed(egfr1,.40,ev_40_p,mos_40_p,ev_40_p_con,mos_40_p_con,data_40_p_con);	*40% egfr change confirmed*;
%Decline_egfr_confirmed(egfr1,.57,ev_57_p,mos_57_p,ev_57_p_con,mos_57_p_con,data_57_p_con);  *57% egfr change confirmed*;


%Decline_eGFR_Thresh(egfr1,25, 15,ev_15_t,mos_15_t,egfr15t); * 15ml under egfr threshold ;
%Decline_eGFR_Thresh(egfr1,60, 30,ev_30_t,mos_30_t,egfr30t); * 30ml under egfr threshold*;
%Decline_eGFR_Thresh(egfr1,60, 45,ev_45_t,mos_45_t,egfr45t); * 45ml under egfr threshold*;

%Decline_eGFR_Thresh_confirmed(egfr1,25, 15,ev_15_t,mos_15_t,ev_15_t_con,mos_15_t_con,data_15_t_con) ;
%Decline_eGFR_Thresh_confirmed(egfr1,60, 30,ev_30_t,mos_30_t,ev_30_t_con,mos_30_t_con,data_30_t_con);
%Decline_eGFR_Thresh_confirmed(egfr1,60, 45,ev_45_t,mos_45_t,ev_45_t_con,mos_45_t_con,data_45_t_con);

%double (egfr1);

* merging all the non-confirmed data;
proc sort data=egfr30; by study_num  new_id; run;
proc sort data=egfr40; by study_num  new_id; run;
proc sort data=egfr57; by study_num  new_id; run;
proc sort data=egfr45t; by study_num  new_id; run;
proc sort data=egfr30t; by study_num  new_id; run;
proc sort data=egfr15t; by study_num  new_id; run;

data final_noncon; merge  egfr30 egfr40 egfr57 egfr45t egfr30t egfr15t; by study_num new_id; run;


*merge all confirmed;
proc sort data=data_30_p_con; by study_num  new_id; run;
proc sort data=data_40_p_con; by study_num  new_id; run;
proc sort data=data_57_p_con; by study_num  new_id; run;
proc sort data=data_45_t_con; by study_num  new_id; run;
proc sort data=data_30_t_con; by study_num  new_id; run;
proc sort data=data_15_t_con; by study_num  new_id; run;
data final_con; merge  data_30_p_con data_40_p_con data_57_p_con data_45_t_con data_30_t_con data_15_t_con; by study_num new_id; run;
*sort both;


***********************************************************************************************************
***********************************************************************************************************
*check that all participants have assigned event and coherent in that fewer events with increasing decline;
***********************************************************************************************************
***********************************************************************************************************
***********************************************************************************************************;

proc freq data=final_con; tables ev_30_p_con ev_40_p_con ev_57_p_con ev_45_t_con ev_30_t_con ev_15_t_con/missing  ;
proc freq data=final_noncon; tables ev_30_p ev_40_p ev_57_p ev_45_t ev_30_t ev_15_t /missing;run;
proc freq data= double; tables double/missing; run;



***alll datasets w endpts to combine w baseline;
proc sort data=final_con; by study_num new_id; run;
proc sort data=final_noncon; by study_num new_id; run;
proc sort data=double; by study_num new_id; run;


data all_ev; 
	merge final_noncon final_con double ;
	by study_num new_id;
drop adm_1mos;
run;

*****************************************************************************************************************
*****************************************************************************************************************
	Step 3 :   Create treatment level dataset
	1. Merge in baseline and eGFR decline endpts 
	2. Decide on which double 
	- Studies where we dont like the double or was missing from the original 
	- use double as defined above)
    (3. If running this code for one study , would need to alter if study_num sentence below
*****************************************************************************************************************
*****************************************************************************************************************;

proc sort data=item;by  Study_num new_id; run;
proc sort data=all_ev; by study_num new_id; run;
data base_ev; 
	merge item (in=a) all_ev (in=b); 
	by study_num new_id; 
	if a=1;
*include study number below if doubling not given;
	*update for new study;

	if study_num in (10,13,15,16,18,24,26,27,29,30,31,32,33,35,48,49,50,51,52,54,57,60,63,66,500) then do; 
 		if double = . then double=0;
 		dbl = double; 
		mos_dbl = mos_double;  *** mos_dbl defined only if doubling event occurred;
 		end;
		drop fu_ckdegfr;
run;
proc sort data=base_ev; by study_num new_id; run;



*****************************************************************************************************************
*****************************************************************************************************************
 Step 4 : Make composite endpts
1) allow ESRD and death 6 months to develop event, if not assign adm_1mos as censoring
2) create ev_d ev_x w censoring date of 6 months post study end (if info was available or our definition)
3) create ev_s censoring date of 1 months post study end (if info was available or our definition)
4) create composites of the above plus GFR decline
5) If no visits, then include events if before 12 months, otherwise censor at 12 months

*****************************************************************************************************************
*****************************************************************************************************************;

data base_ev1;  set base_ev;
/*Total of 390 people at baseline with no visits
103 had dx event
69 had dx event  before 1 year – to be included
34 had dx event  after 1 year – to be censored at one year
*/

**IN VISITS**;

if in_visits=1 then do;

  	/***ESRD***/
	if kidney_fail = 1 and  mos_kidney_fail > adm_6mos then do;
	ev_d=0 ;
	fu_d=adm_1mos;
	ev_d_ever=1;
	fu_d_ever=mos_kidney_fail;
	end;

	if kidney_fail =1 and  mos_kidney_fail =< adm_6mos then do;
 	ev_d=1;
	fu_d=mos_kidney_fail;
	ev_d_ever=1;
	fu_d_ever=mos_kidney_fail;
	end;

	if kidney_fail =0 then do;
		ev_d=0;
		ev_d_ever=0;

			if death = 1 and  mos_death> adm_6mos then do;
				fu_d=adm_1mos;
				fu_d_ever= adm_1mos;
			end;

			if death =1 and  mos_death <= adm_6mos then do;
				fu_d=mos_death;
				fu_d_ever= adm_1mos;
			end;

			if death =0 then do;
				fu_d=adm_1mos;
				fu_d_ever= adm_1mos;
			end;
	end;

	/***DEATH***/
	if death = 1 and  mos_death > adm_6mos then do;
 		ev_x=0;
		ev_x_ever=0;

		if kidney_fail = 1 and  mos_kidney_fail > adm_6mos then do;
			fu_x=adm_1mos;
			fu_x_ever= adm_1mos;
		end;
		
		if kidney_fail = 1 and  mos_kidney_fail <= adm_6mos & mos_kidney_fail >= adm_1mos then do;
			fu_x=mos_kidney_fail; 	
			fu_x_ever= mos_kidney_fail;
		end;

		if kidney_fail = 1 and  mos_kidney_fail <= adm_1mos then do;
			fu_x=adm_1mos; 
			fu_x_ever= adm_1mos;
		end;

		if kidney_fail = 0 then do;
			fu_x=adm_1mos;
			fu_x_ever= adm_1mos;
		end;
	
	end;


	if death =1 and  mos_death <= adm_6mos then do;
 	ev_x=1;
	ev_x_ever=1;
	fu_x=mos_death;
	fu_x_ever=mos_death;
	end;

	if death =0 then do;
	 	ev_x=0;
		ev_x_ever=0;

		if kidney_fail = 1 and  mos_kidney_fail > adm_6mos then do;
 			fu_x=adm_1mos;
			fu_x_ever= adm_1mos;
		end;
		
		if kidney_fail = 1 and  mos_kidney_fail <= adm_6mos & mos_kidney_fail >= adm_1mos then do;
			fu_x=mos_kidney_fail; 	
			fu_x_ever= mos_kidney_fail;
		end;

			
		if kidney_fail = 1 and  mos_kidney_fail <= adm_1mos then do;
			fu_x=adm_1mos ; *should not be fu_x=adm_1mos here - otherwise fu_d > fu_x (and fu_dx) when ev_d=1;
			fu_x_ever= mos_kidney_fail;
		end;

		if kidney_fail = 0 then do;
			fu_x=adm_1mos;
			fu_x_ever= adm_1mos;
		end;
	end;
end;

**NOT IN VISITS - HAS DX EVENT**;
if in_visits=0 and max(kidney_fail, death) = 1 then do;
	
	/***ESRD***/
	if kidney_fail = 1 and  mos_kidney_fail > 12 then do;
	ev_d=0;
	fu_d=12;
	ev_d_ever=1;
	fu_d_ever=mos_kidney_fail;
	ev_30_p=0;     mos_30_p=12; 
	ev_40_p=0;	   mos_40_p=12; 
	ev_57_p=0;	   mos_57_p=12; 
	ev_45_t=0; 	   mos_45_t=12; 
	ev_30_t=0; 	   mos_30_t=12; 
	ev_15_t=0; 	   mos_15_t=12; 
	ev_30_p_con=0; mos_30_p_con=12; 
	ev_40_p_con=0; mos_40_p_con=12; 
	ev_57_p_con=0; mos_57_p_con=12; 
	ev_45_t_con=0; mos_45_t_con=12; 
	ev_30_t_con=0; mos_30_t_con=12; 
	ev_15_t_con=0; mos_15_t_con=12; 
	end;

	if kidney_fail = 1 and  mos_kidney_fail <= 12 then do;
	ev_d=1;
	fu_d=mos_kidney_fail;
	ev_d_ever=1;
	fu_d_ever=mos_kidney_fail;
	ev_30_p=0;     mos_30_p=mos_kidney_fail; 
	ev_40_p=0;	   mos_40_p=mos_kidney_fail; 
	ev_57_p=0;	   mos_57_p=mos_kidney_fail; 
	ev_45_t=0; 	   mos_45_t=mos_kidney_fail; 
	ev_30_t=0; 	   mos_30_t=mos_kidney_fail; 
	ev_15_t=0; 	   mos_15_t=mos_kidney_fail; 
	ev_30_p_con=0; mos_30_p_con=mos_kidney_fail; 
	ev_40_p_con=0; mos_40_p_con=mos_kidney_fail; 
	ev_57_p_con=0; mos_57_p_con=mos_kidney_fail; 
	ev_45_t_con=0; mos_45_t_con=mos_kidney_fail; 
	ev_30_t_con=0; mos_30_t_con=mos_kidney_fail; 
	ev_15_t_con=0; mos_15_t_con=mos_kidney_fail; 
	end;

	if kidney_fail =0 then do;
	ev_d=0;
	fu_d=12;
	ev_d_ever=0;
	fu_d_ever= adm_1mos;
	ev_30_p=0;     mos_30_p=12; 
	ev_40_p=0;	   mos_40_p=12; 
	ev_57_p=0;	   mos_57_p=12; 
	ev_45_t=0; 	   mos_45_t=12; 
	ev_30_t=0; 	   mos_30_t=12; 
	ev_15_t=0; 	   mos_15_t=12; 
	ev_30_p_con=0; mos_30_p_con=12; 
	ev_40_p_con=0; mos_40_p_con=12; 
	ev_57_p_con=0; mos_57_p_con=12; 
	ev_45_t_con=0; mos_45_t_con=12; 
	ev_30_t_con=0; mos_30_t_con=12; 
	ev_15_t_con=0; mos_15_t_con=12; 
	end;


	/***DEATH***/
	if death = 1 and  mos_death> 12 then do;
	ev_x=0 ;
	fu_x=12;
	ev_x_ever=1;
	fu_x_ever=mos_death;
	ev_30_p=0;     mos_30_p=12; 
	ev_40_p=0;	   mos_40_p=12; 
	ev_57_p=0;	   mos_57_p=12; 
	ev_45_t=0; 	   mos_45_t=12; 
	ev_30_t=0; 	   mos_30_t=12; 
	ev_15_t=0; 	   mos_15_t=12; 
	ev_30_p_con=0; mos_30_p_con=12; 
	ev_40_p_con=0; mos_40_p_con=12; 
	ev_57_p_con=0; mos_57_p_con=12; 
	ev_45_t_con=0; mos_45_t_con=12; 
	ev_30_t_con=0; mos_30_t_con=12; 
	ev_15_t_con=0; mos_15_t_con=12; 
	end;

	if death =1 and  mos_death =< 12 then do;
	ev_x=1;
	fu_x=mos_death;
	ev_x_ever=1;
	fu_x_ever=mos_death;
	ev_30_p=0;     mos_30_p=mos_death; 
	ev_40_p=0;	   mos_40_p=mos_death; 
	ev_57_p=0;	   mos_57_p=mos_death; 
	ev_45_t=0; 	   mos_45_t=mos_death; 
	ev_30_t=0; 	   mos_30_t=mos_death; 
	ev_15_t=0; 	   mos_15_t=mos_death; 
	ev_30_p_con=0; mos_30_p_con=mos_death; 
	ev_40_p_con=0; mos_40_p_con=mos_death; 
	ev_57_p_con=0; mos_57_p_con=mos_death; 
	ev_45_t_con=0; mos_45_t_con=mos_death; 
	ev_30_t_con=0; mos_30_t_con=mos_death; 
	ev_15_t_con=0; mos_15_t_con=mos_death; 
	end;

	if death =0 then do;
	ev_x=0;
	ev_x_ever=0;
	fu_x=12;
	fu_x_ever= adm_1mos;
	ev_30_p=0;     mos_30_p=12; 
	ev_40_p=0;	   mos_40_p=12; 
	ev_57_p=0;	   mos_57_p=12; 
	ev_45_t=0; 	   mos_45_t=12; 
	ev_30_t=0; 	   mos_30_t=12; 
	ev_15_t=0; 	   mos_15_t=12; 
	ev_30_p_con=0; mos_30_p_con=12; 
	ev_40_p_con=0; mos_40_p_con=12; 
	ev_57_p_con=0; mos_57_p_con=12; 
	ev_45_t_con=0; mos_45_t_con=12; 
	ev_30_t_con=0; mos_30_t_con=12; 
	ev_15_t_con=0; mos_15_t_con=12; 
	end;


end;

**NOT IN VISITS - DOES NOT HAVE DX EVENT**;
if in_visits=0 and max(kidney_fail, death) = 0  then do; 

	/***ESRD***/
 	ev_d=0;
	ev_d_ever=0;
	fu_d=12;
	fu_d_ever= adm_1mos;


	/***DEATH***/
 	ev_x=0;
	ev_x_ever=0;
	fu_x=12;
	fu_x_ever= adm_1mos;

	/**GFR Decline Variables**/
	ev_30_p=0;     mos_30_p=12; 
	ev_40_p=0;	   mos_40_p=12; 
	ev_57_p=0;	   mos_57_p=12; 
	ev_45_t=0; 	   mos_45_t=12; 
	ev_30_t=0; 	   mos_30_t=12; 
	ev_15_t=0; 	   mos_15_t=12; 
	ev_30_p_con=0; mos_30_p_con=12; 
	ev_40_p_con=0; mos_40_p_con=12; 
	ev_57_p_con=0; mos_57_p_con=12; 
	ev_45_t_con=0; mos_45_t_con=12; 
	ev_30_t_con=0; mos_30_t_con=12; 
	ev_15_t_con=0; mos_15_t_con=12; 
end;



/***Doubling***/

if dbl = 1 and  mos_dbl> adm_1mos then do;
ev_s=0 ;
ev_s_ever=1;
fu_s=adm_1mos;
fu_s_ever=mos_dbl;
end;

if dbl =1 and  mos_dbl =< adm_1mos then do;
ev_s=1;
ev_s_ever=1;
fu_s=mos_dbl;
fu_s_ever=mos_dbl;
end;


if dbl =0 then do;
 ev_s=0;
ev_s_ever=0;
fu_s=adm_1mos;
fu_s_ever= adm_1mos;
end;


if max(ev_d, ev_s) then ev_sd=1;
	if ev_sd=.  then ev_sd=0;
  	fu_sd  = min(fu_d,fu_s);

if max(ev_d, ev_x) then ev_dx=1; 
	if ev_dx=.  then ev_dx=0;
  	fu_dx  = min(fu_d,fu_x); 

if max(ev_d, ev_s, ev_x) then ev_dsx=1;
	if ev_dsx=.  then ev_dsx=0;



  * non-confirmed * ;

if max(ev_d, ev_15_t) then ev_dg=1;
if max(ev_d, ev_15_t, ev_x) then ev_dgx=1; 
if max(ev_d, ev_15_t, ev_s) then ev_dgs=1;
if max(ev_d, ev_15_t, ev_s, ev_x) then ev_dgsx=1; 

	if ev_dg=.  then ev_dg=0;
	if ev_dgx=. then ev_dgx=0;
	if ev_dgs=.  then ev_dgs=0;
	if ev_dgsx=.  then ev_dgsx=0;


	fu_dg  = min(fu_d,mos_15_t);
  	fu_dgx  = min(fu_d,mos_15_t, fu_x);
  	fu_dgs = min(fu_d,mos_15_t,fu_s);
  	fu_dgsx = min(fu_d,fu_x,fu_s, mos_15_t);
  	fu_dsx = min(fu_d,fu_x,fu_s);




* confirmed * ;

if max(ev_d, ev_15_t_con) then ev_dg_con=1;
if max(ev_d, ev_15_t_con, ev_x) then ev_dgx_con=1; 
if max(ev_d, ev_15_t_con, ev_s) then ev_dgs_con=1;
if max(ev_d, ev_15_t_con, ev_s, ev_x) then ev_dgsx_con=1; 

if ev_dg_con=. then ev_dg_con=0;
if ev_dgx_con=. then ev_dgx_con=0;
if ev_dgs_con=. then ev_dgs_con=0;
if ev_dgsx_con=. then ev_dgsx_con=0;

  fu_dg_con  = min(fu_d,mos_15_t_con);
  fu_dgx_con  = min(fu_d,mos_15_t_con,fu_x);
  fu_dgs_con = min(fu_d,mos_15_t_con,fu_s);
  fu_dgsx_con = min(fu_d,fu_x,fu_s, mos_15_t_con);


run;


*To restrict and save Visits dataset that includes no visits with visit_time > fu_dx;
data base_forvisits;  set base_ev1;
keep new_id study_num ev_x fu_x ev_d fu_d adm_1mos;
run; 
data visits_update; set pclean.FDAC2_visits_interim; run;
proc sort data=base_forvisits; by new_id study_num; run;
proc sort data=visits_update; by new_id study_num; run;
data visits_update2; 
merge visits_update (in=a) base_forvisits (in=b);
by new_id study_num;
if a=1;
run;
data visits_update3; set visits_update2;
if ev_d=1 and visit_time >= fu_d then visitpost_d=1;
else visitpost_d=0;
if ev_x=1 and visit_time >= fu_x then visitpost_x=1;
else visitpost_x=0;
if ev_d =0 and ev_x=0 and visit_time  >= adm_1mos then visitpost_adm=1;
else visitpost_adm=0;
run;
data pclean.FDAC2_visits; 
	set visits_update3; 
	if visitpost_d=0 and visitpost_x=0 and visitpost_adm=0;
run;


%macro composite(ev1, ev2, evg15, mosg15, edg, edgx, edgs, edgsx,  esd, edx, edsx, ed,  fdg, fdgx, fdgs, fdgsx,  fsd, fdx, fdsx, fd);

data base_ev1; set base_ev1;

if max(ev_d, &evg15, &ev1) then &edg=1;
if max(ev_d, &evg15, ev_x, &ev1) then &edgx=1; 
if max(ev_d, &evg15, ev_s, &ev1) then &edgs=1;
if max(ev_d, &evg15, ev_s, ev_x, &ev1) then &edgsx=1;
 

if max(ev_d, ev_s, &ev1) then &esd=1;
if max(ev_d, ev_x, &ev1) then &edx=1;
if max(ev_d, ev_s,ev_x, &ev1) then &edsx=1;
if max(ev_d, &ev1) then &ed=1;

if &edg=. then &edg=0;
if &edgx=. then &edgx=0;
if &edgs=. then &edgs=0;
if &edgsx=. then &edgsx=0;


if &esd=. then &esd=0;
if &edx=. then &edx=0;
if &edsx=. then &edsx=0;
if &ed=. then &ed=0;


  &fdg  =  min(fu_d,	&mosg15,	&ev2);
  &fdgx =  min(fu_d,	&mosg15,	fu_x, 	&ev2);
  &fdgs =  min(fu_d,	&mosg15,	fu_s,	&ev2);
  &fdgsx = min(fu_d,	&mosg15,	fu_x,	fu_s, 	&ev2);

  &fsd =  min(fu_d, 	fu_s,	&ev2);
  &fdx =  min(fu_d, 	fu_x,	&ev2);
  &fdsx = min(fu_d,	fu_x,	fu_s, 	&ev2);
  &fd =    min(fu_d,	&ev2);



run;
%mend;

* Creating non-confirmed composite Variables*************************************;

%composite(ev_30_p, mos_30_p, ev_15_t, mos_15_t, ev_dg_30_p, ev_dgx_30_p, ev_dgs_30_p, ev_dgsx_30_p,ev_sd_30_p,ev_dx_30_p, ev_dsx_30_p, ev_d_30_p, fu_dg_30_p, fu_dgx_30_p, fu_dgs_30_p, fu_dgsx_30_p,  fu_sd_30_p, fu_dx_30_p,fu_dsx_30_p,fu_d_30_p)
%composite(ev_40_p, mos_40_p, ev_15_t, mos_15_t, ev_dg_40_p, ev_dgx_40_p, ev_dgs_40_p, ev_dgsx_40_p,ev_sd_40_p,ev_dx_40_p, ev_dsx_40_p, ev_d_40_p, fu_dg_40_p, fu_dgx_40_p, fu_dgs_40_p, fu_dgsx_40_p,  fu_sd_40_p, fu_dx_40_p,fu_dsx_40_p,fu_d_40_p)
%composite(ev_57_p, mos_57_p, ev_15_t, mos_15_t, ev_dg_57_p, ev_dgx_57_p, ev_dgs_57_p, ev_dgsx_57_p,ev_sd_57_p,ev_dx_57_p, ev_dsx_57_p, ev_d_57_p, fu_dg_57_p, fu_dgx_57_p, fu_dgs_57_p, fu_dgsx_57_p,  fu_sd_57_p, fu_dx_57_p,fu_dsx_57_p,fu_d_57_p)


* Creating confirmed composite Variables*************************************;

%composite(ev_30_p_con, mos_30_p_con, ev_15_t_con, mos_15_t_con, ev_dg_30_p_con, ev_dgx_30_p_con, ev_dgs_30_p_con, ev_dgsx_30_p_con,ev_sd_30_p_con,ev_dx_30_p_con, ev_dsx_30_p_con, ev_d_30_p_con, fu_dg_30_p_con, fu_dgx_30_p_con, fu_dgs_30_p_con, fu_dgsx_30_p_con,  fu_sd_30_p_con, fu_dx_30_p_con,fu_dsx_30_p_con,fu_d_30_p_con);
%composite(ev_40_p_con, mos_40_p_con, ev_15_t_con, mos_15_t_con, ev_dg_40_p_con, ev_dgx_40_p_con, ev_dgs_40_p_con, ev_dgsx_40_p_con,ev_sd_40_p_con,ev_dx_40_p_con, ev_dsx_40_p_con, ev_d_40_p_con, fu_dg_40_p_con, fu_dgx_40_p_con, fu_dgs_40_p_con, fu_dgsx_40_p_con,  fu_sd_40_p_con, fu_dx_40_p_con,fu_dsx_40_p_con,fu_d_40_p_con);
%composite(ev_57_p_con, mos_57_p_con, ev_15_t_con, mos_15_t_con, ev_dg_57_p_con, ev_dgx_57_p_con, ev_dgs_57_p_con, ev_dgsx_57_p_con,ev_sd_57_p_con,ev_dx_57_p_con, ev_dsx_57_p_con, ev_d_57_p_con, fu_dg_57_p_con, fu_dgx_57_p_con, fu_dgs_57_p_con, fu_dgsx_57_p_con,  fu_sd_57_p_con, fu_dx_57_p_con,fu_dsx_57_p_con,fu_d_57_p_con);

proc sort data=base_ev1; by study_num new_id;run;


*****************************************************************************************************************
*****************************************************************************************************************
Step 5 Permanent dataset
*****************************************************************************************************************
*****************************************************************************************************************;

*dataset w all variables except redundant ones from original dataset;
data treatment_AllEndpts; set base_ev1; 
drop dial mos_dial esrd mos_esrd death mos_death  tplnt mos_tplnt double mos_double dbl mos_dbl;
run;


**make permanent datasets***;
data pclean.FDAC2_StudyGFR;
set treatment_AllEndpts;
run;
proc  means data=pclean.FDAC2_StudyGFR n nmiss;
run;
data check; set pclean.FDAC2_StudyGFR;
if in_visits=0;
run;
proc  means data=check n nmiss;
run;


*********************************************************************************************
***PART III-of FDA conference 2 dataset development ***
Here we create a UP change over 6, 9 and 12 months  (9 months for UPE only)

Lesley Inker and Andrew Simon - December 4, 2017
*********************************************************************************************;


data baseall;
 set pclean.FDAC2_baseline;
run;

data visits;
 set pclean.FDAC2_visits;
run;

data StudyGFR;
set pclean.FDAC2_StudyGFR;
run;


/*
proc sort data=baseall out=study(keep=study_num UP_MeasureToUse) nodupkey;
 by study_num;
run;
proc sort data=visits;
 by study_num;
run;
data visits2;
 merge visits(in=in1) study;
 by study_num;
 if in1;
run;
data fupro1;
 set visits2;
  if UP_MeasureToUse= "PER"  then zupro=_24_upro_tot; 
  else if UP_MeasureToUse= "AER"  then zupro=_24_ualb_tot; 
  else if UP_MeasureToUse= "PCR"  then zupro=_24_upro_rat;	
  else if UP_MeasureToUse= "ACR"  then zupro=_24_ualb_rat; 
  else if UP_MeasureToUse= "SPCR"  then zupro=spot_upro_rat;
 else if UP_MeasureToUse= "SACR"  then zupro=spot_ualb_rat; 
run; 
data fupro2;
 set fupro1;
 if zupro=. then delete;
run;
proc sort data=fupro2;
 by study_num new_id;
run;
data fupro3;
 set fupro2;
 by study_num new_id;
 if first.new_id;
run;
proc means data=fupro3 min max mean p5 p95 p99 median maxdec=2;
var visit_time;
class study_num;
run;
data idnt;
 set visits;
 if study_num=14;
run;
proc sort data=idnt;
 by new_id visit_time;
run;

*/

%macro changeprotein(basedata,data,basevariable,variablein,variabledelta,time,low,high,out);

data base;
 set &basedata;
 keep new_id study_num &basevariable  UP_measuretouse;
run;
data temp0;
 set &data;
 if &variablein ne . and (&low <= visit_time <= &high);
 diff=visit_time-&time;
 absdiff=abs(visit_time-&time);
 keep new_id  study_num visit_time absdiff diff &variablein;
run;
proc sort data=temp0;
 by new_id study_num  absdiff diff;
run;
data temp1;
 set temp0;
 by new_id study_num  absdiff diff;
 if first.study_num;
 &variablein._&time.m=&variablein;
 &variablein._&time.m_exact=diff;
 keep new_id  study_num &variablein._&time.m &variablein._&time.m_exact;
run;
proc sort data=temp1;
 by new_id study_num ;
run;
proc sort data=base;
 by new_id study_num ;
run;


data &out;
 merge base temp1;
 by new_id study_num ;
visitime&variablein._&time=&time + &variablein._&time.m_exact;

if &basevariable ne . and &variablein._&time.m ne . then 
    missingtype&variablein._&time.m=1;
 else if &basevariable ne . and &variablein._&time.m=. then 
    missingtype&variablein._&time.m=2;
else if &basevariable=. and &variablein._&time.m ne . then 
    missingtype&variablein._&time.m=3;
else if &basevariable =. and &variablein._&time.m =. then 
    missingtype&variablein._&time.m=4;
run;

proc sort data=&out;
 by study_num  new_id;
run;

data &out;
set &out;
 if &basevariable >0 and &variablein._&time.m >0 and &variablein._&time.m ne . 
	and &basevariable ne .
    then do;
	log&variabledelta=log(&variablein._&time.m)-log(&basevariable);
	log2&variabledelta=log2(&variablein._&time.m)-log2(&basevariable);
	&variabledelta=&variablein._&time.m-&basevariable;
		end;
 else if &basevariable=0 and &variablein._&time.m>0 and &variablein._&time.m ne . and &basevariable ne .
    then do;
	log&variabledelta=log(&variablein._&time.m)-log(0.01);
	log2&variabledelta=log2(&variablein._&time.m)-log2(0.01);
	&variabledelta=&variablein._&time.m-&basevariable;
	end;
else if &basevariable>0 and &variablein._&time.m=0 and &variablein._&time.m ne . and &basevariable ne .
    then do;
	log&variabledelta=log(0.01)-log(&basevariable);
	log2&variabledelta=log2(0.01)-log2(&basevariable);
	&variabledelta=&variablein._&time.m-&basevariable;
	end;
else if &basevariable=0 and &variablein._&time.m=0 and &variablein._&time.m ne . and &basevariable ne .
    then do;
	log&variabledelta=log(0.01)-log(0.01);
	log2&variabledelta=log2(0.01)-log2(0.01);
	&variabledelta=&variablein._&time.m-&basevariable;
	end;
	run;

proc datasets nolist;
delete base temp0 temp1;
run;
quit;
%mend;
%changeprotein(baseall,visits,base_24_upro_tot,_24_upro_tot,delta_upT6, 6,2.5,14,uproT6);
%changeprotein(baseall,visits,base_24_upro_tot,_24_upro_tot,delta_upT9, 9,2.5,14,uproT9);
%changeprotein(baseall,visits,base_24_upro_tot,_24_upro_tot,delta_upT12, 12,2.5,19,uproT12);

%changeprotein(baseall,visits,base_24_ualb_tot,_24_ualb_tot,delta_albT6, 6,2.5,14,ualbT6);
%changeprotein(baseall,visits,base_24_ualb_tot,_24_ualb_tot,delta_albT9, 9,2.5,14,ualbT9);
%changeprotein(baseall,visits,base_24_ualb_tot,_24_ualb_tot,delta_albT12, 12,2.5,19,ualbT12);

%changeprotein(baseall,visits,base_24_upro_rat,_24_upro_rat,delta_upR6, 6,2.5,14,uproR6);
%changeprotein(baseall,visits,base_24_upro_rat,_24_upro_rat,delta_upR9, 9,2.5,14,uproR9);
%changeprotein(baseall,visits,base_24_upro_rat, _24_upro_rat,delta_upR12, 12,2.5,19,uproR12);

%changeprotein(baseall,visits,base_24_ualb_rat,_24_ualb_rat,delta_albR6, 6,2.5,14,ualbR6);
%changeprotein(baseall,visits,base_24_ualb_rat,_24_ualb_rat,delta_albR9, 9,2.5,14,ualbR9);
%changeprotein(baseall,visits,base_24_ualb_rat,_24_ualb_rat,delta_albR12, 12,2.5,19,ualbR12);

%changeprotein(baseall,visits,base_spot_upro_rat,spot_upro_rat,delta_upSR6, 6,2.5,14,uproSR6);
%changeprotein(baseall,visits,base_spot_upro_rat,spot_upro_rat,delta_upSR9, 9,2.5,14,uproSR9);
%changeprotein(baseall,visits,base_spot_upro_rat,spot_upro_rat,delta_upSR12, 12,2.5,19,uproSR12);

%changeprotein(baseall,visits,base_spot_ualb_rat,spot_ualb_rat,delta_albSR6, 6,2.5,14,ualbSR6);
%changeprotein(baseall,visits,base_spot_ualb_rat,spot_ualb_rat,delta_albSR9, 9,2.5,14,ualbSR9);
%changeprotein(baseall,visits,base_spot_ualb_rat,spot_ualb_rat,delta_albSR12, 12,2.5,19,ualbSR12);
 


data upro_change0;
 merge uproT6  uproT9 uproT12 
ualbT6 ualbT9 ualbT12   
uproR6 uproR9 uproR12 
ualbR6  ualbR9 ualbR12
uproSR6 uproSR9 uproSR12 
ualbSR6 ualbSR9 ualbSR12;

 by study_num  new_id;
 RUN;

 
data upro_change1 ;
 SET  upro_change0;

 if UP_MeasureToUse= "PER"  then do;
	delupro6=delta_upT6 ; 				delupro12=delta_upT12; 	
	logdelupro6=logdelta_upT6 ; 		logdelupro12=logdelta_upT12; 
	log2delupro6=log2delta_upT6 ; 		log2delupro12=log2delta_upT12; 	
	uprotime6=visitime_24_upro_tot_6;	 uprotime12=visitime_24_upro_tot_12; 
	upro6=_24_upro_tot_6m; 				upro12=_24_upro_tot_12m;

	delupro9=delta_upT9; 			
	logdelupro9=logdelta_upT9 ; 	
	log2delupro9=log2delta_upT9 ; 		 	
	uprotime9=visitime_24_upro_tot_9;	 
	upro9=_24_upro_tot_9m; 			

end;


 if UP_MeasureToUse= "AER"  then do;
	delupro6=delta_albT6 ;				delupro12=delta_albT12;
	logdelupro6=logdelta_albT6 ;		logdelupro12=logdelta_albT12;
	log2delupro6=log2delta_albT6 ;		log2delupro12=log2delta_albT12;
	uprotime6=visitime_24_ualb_tot_6;	uprotime12=visitime_24_ualb_tot_12; 
	upro6=_24_ualb_tot_6m; 				upro12=_24_ualb_tot_12m;

	delupro9=delta_albT9 ;			
	logdelupro9=logdelta_albT9 ;	
	log2delupro9=log2delta_albT9 ;	
	uprotime9=visitime_24_ualb_tot_9;
	upro9=_24_ualb_tot_9m; 			
end;

if UP_MeasureToUse= "PCR"  then do;
	delupro6=delta_upR6 ; 				delupro12=delta_upR12; 	
	logdelupro6=logdelta_upR6 ; 		logdelupro12=logdelta_upR12; 
	log2delupro6=log2delta_upR6 ; 		log2delupro12=log2delta_upR12; 
	uprotime6=visitime_24_upro_rat_6;	uprotime12=visitime_24_upro_rat_12; 
	upro6=_24_upro_rat_6m; 				upro12=_24_upro_rat_12m;

	delupro9=delta_upR9; 	
	logdelupro9=logdelta_upR9; 
	log2delupro9=log2delta_upR9; 
	uprotime9=visitime_24_upro_rat_9; 
	upro9=_24_upro_rat_9m;

end;

 if UP_MeasureToUse= "ACR"  then do;
	delupro6=delta_albR6 ; 				delupro12=delta_albR12; 
	logdelupro6=logdelta_albR6 ; 		logdelupro12=logdelta_albR12; 
	log2delupro6=log2delta_albR6 ; 		log2delupro12=log2delta_albR12; 
	uprotime6=visitime_24_ualb_rat_6; 	uprotime12=visitime_24_ualb_rat_12; 
	upro6=_24_ualb_rat_6m; 				upro12=_24_ualb_rat_12m;

	delupro9=delta_albR9; 
	logdelupro9=logdelta_albR9; 
	log2delupro9=log2delta_albR9; 
	uprotime9=visitime_24_ualb_rat_9; 
	upro9=_24_ualb_rat_9m;
end;

 if UP_MeasureToUse= "SPCR"  then do;
	delupro6=delta_upSR6 ; 				delupro12=delta_upSR12; 
	logdelupro6=logdelta_upSR6 ; 		logdelupro12=logdelta_upSR12; 
	log2delupro6=log2delta_upSR6 ; 		log2delupro12=log2delta_upSR12; 
	uprotime6=visitimespot_upro_rat_6;	uprotime12=visitimespot_upro_rat_12; 
	upro6=spot_upro_rat_6m; 			upro12=spot_upro_rat_12m;

	delupro9=delta_upSR9; 
	logdelupro9=logdelta_upSR9; 
	log2delupro9=log2delta_upSR9; 
	uprotime9=visitimespot_upro_rat_9; 
	upro9=spot_upro_rat_9m;
end;

if UP_MeasureToUse= "SACR"  then do;
	delupro6=delta_albSR6 ;				delupro12=delta_albSR12;
	logdelupro6=logdelta_albSR6 ;		logdelupro12=logdelta_albSR12;
	log2delupro6=log2delta_albSR6 ;		log2delupro12=log2delta_albSR12;
	uprotime6=visitimespot_ualb_rat_6;	uprotime12=visitimespot_ualb_rat_12; 
	upro6=spot_ualb_rat_6m; 			upro12=spot_ualb_rat_12m;

	delupro9=delta_upSR9; 
	logdelupro9=logdelta_upSR9; 
	log2delupro9=log2delta_upSR9; 
	uprotime9=visitimespot_upro_rat_9; 
	upro9=spot_upro_rat_9m;

end;

run;



data missing;
set upro_change1;


if UP_MeasureToUse= "PER" and (missingtype_24_upro_tot_6m in (3, 4) or 
missingtype_24_upro_tot_12m in (3, 4) or missingtype_24_upro_tot_9m  in (3, 4)) then  missing =1; 

else if   UP_MeasureToUse= "AER"  and (missingtype_24_ualb_tot_6m  in (3, 4) or 
missingtype_24_ualb_tot_12m in (3, 4) or missingtype_24_ualb_tot_9m in (3, 4)) then  missing =1;

else if UP_MeasureToUse= "PCR"  and (missingtype_24_upro_rat_6m  in (3, 4) or  
missingtype_24_upro_rat_12m  in (3, 4) or missingtype_24_upro_rat_9m  in (3, 4)) then  missing =1;  

else if  UP_MeasureToUse= "ACR"  and (missingtype_24_ualb_rat_6m  in (3, 4) or  
missingtype_24_ualb_rat_12m  in (3, 4) or  missingtype_24_ualb_rat_9m  in (3, 4)) then  missing =1; 

else if  UP_MeasureToUse= "SPCR"  and (missingtypespot_upro_rat_6m  in (3, 4) or 
missingtypespot_upro_rat_12m  in (3, 4) or missingtypespot_upro_rat_9m  in (3, 4)) then  missing =1;

else if UP_MeasureToUse= "SACR"  and (missingtypespot_ualb_rat_6m  in (3, 4) or 
missingtypespot_ualb_rat_12m in (3, 4)  or missingtypespot_ualb_rat_9m in (3, 4)) then  missing =1;

else missing=0;


if UP_MeasureToUse= "PER" and missingtype_24_upro_tot_6m in (2)  then  missing6 =1;
else if   UP_MeasureToUse= "AER"  and missingtype_24_ualb_tot_6m  in (2) then  missing6 =1; 
else if UP_MeasureToUse= "PCR"  and missingtype_24_upro_rat_6m  in (2)  then  missing6 =1;
else if  UP_MeasureToUse= "ACR"  and missingtype_24_ualb_rat_6m  in (2)  then  missing6 =1;
else if  UP_MeasureToUse= "SPCR"  and missingtypespot_upro_rat_6m  in (2) then  missing6 =1;
else if UP_MeasureToUse= "SACR"  and missingtypespot_ualb_rat_6m  in (2)  then  missing6 =1;
else missing6=0;



if UP_MeasureToUse= "PER" and missingtype_24_upro_tot_9m  in (2) then  missing9 =1; 
else if   UP_MeasureToUse= "AER" and missingtype_24_ualb_tot_9m in (2) then  missing9 =1;
else if UP_MeasureToUse= "PCR"  and missingtype_24_upro_rat_9m  in (2) then  missing9 =1;
else if  UP_MeasureToUse= "ACR" aND missingtype_24_ualb_rat_9m  in (2) then  missing9 =1; 
else if  UP_MeasureToUse= "SPCR" and missingtypespot_upro_rat_9m  in (2) then  missing9 =1;
else if UP_MeasureToUse= "SACR"  and missingtypespot_ualb_rat_9m in (2)then  missing9 =1;
else missing9=0;


if UP_MeasureToUse= "PER" and missingtype_24_upro_tot_12m  in (2) then  missing12 =1; 
else if   UP_MeasureToUse= "AER" and missingtype_24_ualb_tot_12m in (2) then  missing12 =1;
else if UP_MeasureToUse= "PCR"  and missingtype_24_upro_rat_12m  in (2) then  missing12 =1;
else if  UP_MeasureToUse= "ACR" aND missingtype_24_ualb_rat_12m  in (2) then  missing12 =1; 
else if  UP_MeasureToUse= "SPCR" and missingtypespot_upro_rat_12m  in (2) then  missing12 =1;
else if UP_MeasureToUse= "SACR"  and missingtypespot_ualb_rat_12m in (2)then  missing12 =1;
else missing12=0;
run;

/*
data missing2;
set missing;
if missing=1;
*if missing6=1 or missing12=1; 
if study_num in (56 , 57) then delete;run;

proc freq; tables missing6*study_num*up_measuretouse  missing12*study_num*up_measuretouse /nocol norow nopercent;run;


data missing2;
set missing;
if missing=1; 
if study_num=56 then delete;run;


proc freq; tables study_num*up_measuretouse;run;

*/

****add studyname to the two datasetscreated below if doing this one study 
at a time and change path to the specific study. would then merge this study specific one
with the larger one so we have this desriptiomn on everyone;
data pclean.upro_change;
 set upro_change1;
run;
proc export data=upro_change1 outfile="&path1\2 Clean data\upro_change.csv" dbms=csv replace;
run;
 *added 9 month;
data upro_change2;
set upro_change1;
keep 
study_num
new_id 
delupro6 delupro12 delupro9
uprotime6 uprotime12 uprotime9
logdelupro6 logdelupro12 logdelupro9
log2delupro6 log2delupro12 log2delupro9
upro6 upro12 upro9;
run;
proc sort data=baseall; by study_num new_id;
data upro_change3;
merge  upro_change2 (in=b) StudyGFR (in= a);
by study_num new_id;
if a=1;
run;

*make new dataset;
data pclean.FDAC2_StudyGFRUP;
set upro_change3;
run;


proc  means data=pclean.FDAC2_StudyGFRUP n mean ;
where delupro6 ne .;
var  base_24_ualb_tot base_24_upro_tot age b_CKDegfr sbp;
class studyname;
run;

proc  freq data=pclean.FDAC2_StudyGFRUP  ;
where delupro6 ne .;
tables ev_d ev_dg ev_dg_40_p_con;
run;




*********************************************************************************************
/***PART IV-of FDA conference 2 dataset development ***
0) Set event times after time to death as equal to time to death
1) Pooling treatment
2) Creating ALLRX
3) Creating combo
Lesley Inker and Andrew Simon - August 18, 2017
*********************************************************************************************;

data pooled; set pclean.FDAC2_STUDYGFRUP;
run;
*********************************************************************************************
*Step 0: Set event times after time to death as equal to time to death
*********************************************************************************************;
proc contents data=pooled;
run;

data pooled0; set pooled;
array all1 fu_d	fu_d_30_p	fu_d_30_p_con	fu_d_40_p	fu_d_40_p_con	fu_d_57_p	fu_d_57_p_con	fu_d_ever	fu_dg	fu_dg_30_p	fu_dg_30_p_con	fu_dg_40_p	fu_dg_40_p_con	fu_dg_57_p	fu_dg_57_p_con	fu_dg_con	fu_dgs	fu_dgs_30_p	fu_dgs_30_p_con	fu_dgs_40_p	fu_dgs_40_p_con	fu_dgs_57_p	fu_dgs_57_p_con	fu_dgs_con	fu_dgsx	fu_dgsx_30_p	fu_dgsx_30_p_con	fu_dgsx_40_p	fu_dgsx_40_p_con	fu_dgsx_57_p	fu_dgsx_57_p_con	fu_dgsx_con	fu_dgx	fu_dgx_30_p	fu_dgx_30_p_con	fu_dgx_40_p	fu_dgx_40_p_con	fu_dgx_57_p	fu_dgx_57_p_con	fu_dgx_con	fu_dsx	fu_dsx_30_p	fu_dsx_30_p_con	fu_dsx_40_p	fu_dsx_40_p_con	fu_dsx_57_p	fu_dsx_57_p_con	fu_dx	fu_dx_30_p	fu_dx_30_p_con	fu_dx_40_p	fu_dx_40_p_con	fu_dx_57_p	fu_dx_57_p_con	fu_s	fu_s_ever	fu_sd	fu_sd_30_p	fu_sd_30_p_con	fu_sd_40_p	fu_sd_40_p_con	fu_sd_57_p	fu_sd_57_p_con mos_15_t	mos_15_t_con	mos_30_p	mos_30_p_con	mos_30_t	mos_30_t_con	mos_40_p	mos_40_p_con	mos_45_t	mos_45_t_con	mos_57_p	mos_57_p_con;
array all2 ev_d	ev_d_30_p	ev_d_30_p_con	ev_d_40_p	ev_d_40_p_con	ev_d_57_p	ev_d_57_p_con	ev_d_ever	ev_dg	ev_dg_30_p	ev_dg_30_p_con	ev_dg_40_p	ev_dg_40_p_con	ev_dg_57_p	ev_dg_57_p_con	ev_dg_con	ev_dgs	ev_dgs_30_p	ev_dgs_30_p_con	ev_dgs_40_p	ev_dgs_40_p_con	ev_dgs_57_p	ev_dgs_57_p_con	ev_dgs_con	ev_dgsx	ev_dgsx_30_p	ev_dgsx_30_p_con	ev_dgsx_40_p	ev_dgsx_40_p_con	ev_dgsx_57_p	ev_dgsx_57_p_con	ev_dgsx_con	ev_dgx	ev_dgx_30_p	ev_dgx_30_p_con	ev_dgx_40_p	ev_dgx_40_p_con	ev_dgx_57_p	ev_dgx_57_p_con	ev_dgx_con	ev_dsx	ev_dsx_30_p	ev_dsx_30_p_con	ev_dsx_40_p	ev_dsx_40_p_con	ev_dsx_57_p	ev_dsx_57_p_con	ev_dx	ev_dx_30_p	ev_dx_30_p_con	ev_dx_40_p	ev_dx_40_p_con	ev_dx_57_p	ev_dx_57_p_con	ev_s	ev_s_ever	ev_sd	ev_sd_30_p	ev_sd_30_p_con	ev_sd_40_p	ev_sd_40_p_con	ev_sd_57_p	ev_sd_57_p_con ev_15_t	ev_15_t_con	ev_30_p	ev_30_p_con	ev_30_t	ev_30_t_con	ev_40_p	ev_40_p_con	ev_45_t	ev_45_t_con	ev_57_p	ev_57_p_con;
do over all1;
if all1 > fu_x then do; all1=fu_x; all2=0; end;
end;
run;


********************************************************************************************
*Step 1: Create allrx expanded  dataset;
*********************************************************************************************;
*update for new study;

data pooled1; set pooled0;
IF  study_num=77   THEN do;   ALLRX=77; studyname1="newstudy";			study_code="ab.c ";		end;		*newstudy; 
IF  study_num=78   THEN do;   ALLRX=78; studyname1="CREDENCE";			study_code="xy.z";		end;		*CREDENCE; 
run;

data OutcomesallRx; set pooled1; 
if allRx = . then delete;		*** key step to eliminate unused records; 
run;


*********************************************************************************************
*Step 2: **Add allrx level variables;
*********************************************************************************************;
*update for new study;
data OutcomesallRx2; set OutcomesallRx;
IF  ALLRX in (77,78)  THEN do; Include_IA=1; pooled=1;  Incl_ACR_Efct_Alb=1; end;	 
run;


*********************************************************************************************
*Step 3: Intevention grps and abbreviations
*********************************************************************************************;


data StudyTrtComp; set OutcomesallRx2;
if AllRx in (77, 78) then do; INTERVENTION = 14;  INTERVENTION_ABREV = "SGLT-2"; end;*Canagliflozin;
combo = AllRx;
run;

data fda_conf2_baseline_pooled; 
set StudyTrtComp;
run;

**************************************************************************************
*Check for correct assignment of variables;
**************************************************************************************;
proc freq data=OutcomesallRx ;
tables allrx*treat1 allrx*treat2 allrx*treat3 allrx*T_assign / missing nocol norow nopercent; 
run;

proc freq data=StudyTrtComp; tables allrx*combo allrx*INTERVENTION /missing nocol norow nopercent ;run;


*********************************************************************************************
*Step 5: Permanent dataset
1) fix order of variables with retain
2) decide on which variables to keep
*********************************************************************************************;

data fda_treatment_update_allendpts; 
retain new_id study_num studyname studyname1 ALLRX combo intervention Include_IA pooled region Disease mos_lvisit 
base_scr base_oldscr b_CKDegfr  
T_assign Treat1 Treat2 Treat3 
adm_studyendmos adm_1mos adm_6mos
age female black kd diab HTN sbp dbp smoke HEIGHT WEIGHT BMI bun mGFR base_24_uvol base_24_ualb_tot 
base_24_ualb_con base_24_upro_tot base_24_upro_con base_24_ualb_rat base_spot_ualb_rat 
base_24_upro_rat base_spot_upro_rat base_24_creat_con base_spot_ualb_con base_spot_ualb_rat 
base_spot_ucreat  Hg Alb Gluc Cal Phos Potas Chol HDL LDL TG  cvd base_24_creat_tot 

  diab_type UP_MeasureToUse;
set fda_conf2_baseline_pooled; 
run;

*saved pooled dataset - all endpoints; 
data pclean.FDAC2_TX_AllEndpts; set fda_treatment_update_allendpts;
run;

*Create pooled dataset - selected endpoints;
data fda_trtmnt_update_SelectedEndpts; set  fda_treatment_update_allendpts; 
keep new_id study_num studyname studyname1 study_code ALLRX combo intervention Include_IA pooled region Disease  base_scr base_oldscr   age T_assign 
Treat1 Treat2 Treat3 female black kd diab HTN sbp dbp smoke HEIGHT WEIGHT BMI bun mGFR base_24_uvol base_24_ualb_tot 
base_24_ualb_con base_24_upro_tot base_24_upro_con base_24_ualb_rat base_spot_ualb_rat 
base_24_upro_rat base_spot_upro_rat base_24_creat_con base_spot_ualb_con base_spot_ualb_rat 
base_spot_ucreat  Hg Alb Gluc Cal Phos Potas Chol HDL LDL TG  cvd base_24_creat_tot adm_studyendmos adm_1mos adm_6mos
b_CKDegfr  diab_type UP_MeasureToUse
ev_dg_40_p_con ev_dg_30_p_con ev_dgs_con ev_dg_con ev_dgsx_con ev_d ev_dx ev_x
fu_dg_40_p_con fu_dg_30_p_con fu_dgs_con fu_dg_con fu_dgsx_con fu_d fu_dx fu_x;
run;

data fda_trtmnt_update_SelectedEndpts; 
retain new_id study_num studyname studyname1 study_code ALLRX combo intervention Include_IA pooled region Disease  base_scr b_CKDegfr   base_oldscr   
T_assign  Treat1 Treat2 Treat3 
adm_studyendmos adm_1mos adm_6mos
age female black kd diab HTN sbp dbp smoke HEIGHT WEIGHT BMI bun mGFR base_24_uvol base_24_ualb_tot 
base_24_ualb_con base_24_upro_tot base_24_upro_con base_24_ualb_rat base_spot_ualb_rat 
base_24_upro_rat base_spot_upro_rat base_24_creat_con base_spot_ualb_con base_spot_ualb_rat 
base_spot_ucreat  Hg Alb Gluc Cal Phos Potas Chol HDL LDL TG  cvd _24_creat_tot adm_studyendmos 
diab_type UP_MeasureToUse
ev_dg_40_p_con ev_dg_30_p_con ev_dgs_con ev_dg_con ev_dgsx_con ev_d ev_dx ev_x
fu_dg_40_p_con fu_dg_30_p_con fu_dgs_con fu_dg_con fu_dgsx_con fu_d fu_dx fu_x;
set  fda_trtmnt_update_SelectedEndpts;
run;

*saved pooled dataset - all selected; 
data pclean.FDAC2_TX_SlctEndpts; set fda_trtmnt_update_SelectedEndpts;
run;


PROC FREQ DATA=pclean.FDAC2_TX_AllEndpts; TABLES studyname /nocol norow nopercent;RUN;


PROC TABULATE data=pclean.FDAC2_TX_AllEndpts;  
CLASS studyname;  
VAR age female black diab
p90int 	mos_lscr
	mos_lvisit 
	study_adm
max_adm_studyend
adj_adm_studyend  
altmax_mos_adm 
altadj_mos_adm 
b_CKDegfr kidney_fail  mos_kidney_fail mos_admvis1 mos_adm adm_1mos 
ev_d ev_x ev_s 
fu_d fu_x fu_s
adm_6mos base_24_upro_tot base_24_upro_rat  base_24_ualb_tot  
base_24_ualb_rat base_24_upro_con base_24_ualb_con base_spot_ualb_rat base_spot_upro_rat 
base_spot_ualb_con adm_studyendmos ;  

  
TABLE 
	studyname ,
	mos_admvis1 * (N Nmiss mean min max)   
	mos_adm * (N Nmiss mean min max) 
	p90int * (N Nmiss ) 
	study_adm * (N Nmiss ) 
	mos_lscr *(N Nmiss mean min max) 
	mos_lvisit *(N Nmiss mean min max)
	adm_studyendmos* (N Nmiss mean min max)   
	adm_1mos * (N Nmiss mean min max) 
	adm_6mos * (N Nmiss mean min max)  
	max_adm_studyend  * (N Nmiss mean min max) 
	adj_adm_studyend  * (N Nmiss mean min max)  
	altmax_mos_adm  * (N Nmiss mean min max) 
	altadj_mos_adm  * (N Nmiss mean min max) 
 	mos_kidney_fail  * (N Nmiss mean min max) 

fu_d * (N Nmiss mean min max)  
fu_x * (N Nmiss mean min max) 
fu_s * (N Nmiss mean min max) 
	age * (N Nmiss )   
	female * (N Nmiss) 
	b_CKDeGFR* (N Nmiss )   
	kidney_fail * (N Nmiss) 
	diab *  (N Nmiss) 
	ev_d*  (N Nmiss) 
ev_x *  (N Nmiss)  
ev_s  *  (N Nmiss) 
; 
RUN;

proc means data= pclean.FDAC2_TX_AllEndpts n nmiss ;
run;

data check; set  pclean.FDAC2_TX_AllEndpts;
run;
proc sort data=check nodupkey;
by allrx;
run;

proc freq data=check ;
tables study_code; 
run;
proc print data=pclean.FDAC2_TX_AllEndpts;
where study_code ="A6.1";
run;

/*SUMMARIES*/

data newbaseline1; set dataout.fdac2_tx_allendpts;
dummy=1;run;

proc sort data=newbaseline1; 
by t_Assign; 
run;

proc sort data=dataout.fdac2_baseline ; 
by t_Assign; 
run;

ods noproctitle; 
Ods excel file="&path1\FDA Conference 2\Data\Cleaned Data\data2\data2_datachecks.xlsx"
options(sheet_name="table1_categ" sheet_interval="none" embedded_titles="yes") style=journal ;
proc tabulate data=newbaseline1  FORMAT=8.1;
class t_assign;
var   dummy female black diab ev_d ev_d_ever ev_x ev_s ev_s_ever
    		ev_30_p_con      ev_40_p_con ev_57_p_con
			ev_30_t_con	     ev_45_t_con	ev_15_t_con
			ev_d_30_p_con    ev_d_40_p_con	   ev_d_57_p_con 	
ev_dg_con   ev_dg_30_p_con 	 ev_dg_40_p_con	   ev_dg_57_p_con	
ev_dgs_con  ev_dgs_30_p_con  ev_dgs_40_p_con   ev_dgs_57_p_con
ev_dgx_con  ev_dgx_30_p_con	 ev_dgx_40_p_con   ev_dgx_57_p_con	
ev_dgsx_con ev_dgsx_30_p_con ev_dgsx_40_p_con  ev_dgsx_57_p_con
		    ev_dsx_30_p_con	 ev_dsx_40_p_con   ev_dsx_57_p_con	
ev_dx		ev_dx_30_p_con   ev_dx_40_p_con	   ev_dx_57_p_con	
ev_sd		ev_sd_30_p_con	 ev_sd_40_p_con	   ev_sd_57_p_con 	
;
table  dummy female black diab ev_d ev_d_ever ev_x ev_s ev_s_ever
    		ev_30_p_con      ev_40_p_con ev_57_p_con
			ev_30_t_con	     ev_45_t_con	ev_15_t_con
			ev_d_30_p_con    ev_d_40_p_con	   ev_d_57_p_con 	
ev_dg_con   ev_dg_30_p_con 	 ev_dg_40_p_con	   ev_dg_57_p_con	
ev_dgs_con  ev_dgs_30_p_con  ev_dgs_40_p_con   ev_dgs_57_p_con
ev_dgx_con  ev_dgx_30_p_con	 ev_dgx_40_p_con   ev_dgx_57_p_con	
ev_dgsx_con ev_dgsx_30_p_con ev_dgsx_40_p_con  ev_dgsx_57_p_con
		    ev_dsx_30_p_con	 ev_dsx_40_p_con   ev_dsx_57_p_con	
ev_dx		ev_dx_30_p_con   ev_dx_40_p_con	   ev_dx_57_p_con	
ev_sd		ev_sd_30_p_con	 ev_sd_40_p_con	   ev_sd_57_p_con ,
t_assign='Treatment'*(sum='N'*f=nft. PCTSUM<DUMMY>='%') / rts=22 ;
title "Categorical vars for Table 1";
RUN;

/*Add dummy table */
ods excel options(sheet_interval="table");
ods exclude all;
data _null_;
file print;
put _all_;
run;
ods select all;

ods excel options(sheet_name="table1_contin" sheet_interval="none" embedded_titles="yes");
proc tabulate data=newbaseline1  FORMAT=8.1;
class t_assign;
var    age sbp dbp b_CKDegfr base_spot_ualb_rat base_scr;
table (age sbp dbp b_CKDegfr base_spot_ualb_rat base_scr)*(mean std median p25 p75),
t_assign='Treatment';
title "Continuous vars for Table 1";
run;


/*Add dummy table */
ods excel options(sheet_interval="table");
ods exclude all;
data _null_;
file print;
put _all_;
run;
ods select all;

ods excel options(sheet_name="fdac2_baseline" sheet_interval="none" embedded_titles="yes") ;
proc means data=dataout.fdac2_baseline n nmiss mean std min p25 median p75 max maxdec=1  stackodsoutput; 
title "data2 baseline by treatment arm";
by t_Assign;
run;


/*Add dummy table */
ods excel options(sheet_interval="table");
ods exclude all;
data _null_;
file print;
put _all_;
run;
ods select all;

ods excel options(sheet_name="fdac2_visits" sheet_interval="none" embedded_titles="yes");
proc means data=dataout.fdac2_visits n nmiss mean std min p25 median p75 max maxdec=1 stackodsoutput; 
title "data2 fdac2_visits";
run;

/*Add dummy table */
ods excel options(sheet_interval="table");
ods exclude all;
data _null_;
file print;
put _all_;
run;
ods select all;

ods excel options(sheet_name="fdac2_studygfrup" sheet_interval="none" embedded_titles="yes");
proc means data=dataout.fdac2_studygfrup n nmiss mean std min p25 median p75 max maxdec=1 stackodsoutput;
title "data2 fdac2_studygfrup";
run;


/*Add dummy table */
ods excel options(sheet_interval="table");
ods exclude all;
data _null_;
file print;
put _all_;
run;
ods select all;

ods excel options(sheet_name="fdac2_tx_allendpts" sheet_interval="none" embedded_titles="yes");
proc means data=dataout.fdac2_tx_allendpts n nmiss mean std min p25 median p75 max maxdec=1 stackodsoutput;
title "data2 fdac2_tx_allendpts";
run;

ods excel close;