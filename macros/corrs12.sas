%macro corrs12(lib,start,stop,out);
data xcorr;
study=0;
allrx=0;
eventnumber=0;
beta1_ce_corr=0;
beta3_ce_corr=0;
beta4_ce_1y_corr=0;
beta4_ce_2y_corr=0;
beta4_ce_3y_corr=0;
beta4_ce_4y_corr=0;
chronic_t1y_ce_corr=0;
chronic_t2y_ce_corr=0;
chronic_t3y_ce_corr=0;
chronic_t4y_ce_corr=0;
up12_ce_corr=0;
beta1_up12_corr=0;
beta3_up12_corr=0;
beta4_up12_1y_corr=0;
beta4_up12_2y_corr=0;
beta4_up12_3y_corr=0;
beta4_up12_4y_corr=0;
chronic_t1y_up12_corr=0;
chronic_t2y_up12_corr=0;
chronic_t3y_up12_corr=0;
chronic_t4y_up12_corr=0;
corr12_reason="                                                           ";
hess12_reason="                                                           ";
run;
%do i=&start %to &stop;
%let rowacute=;
%let rowchronic=;
%let rowt1y=;
%let rowt2y=;
%let rowt3y=;
%let rowt4y=;
%let rowup12=;
%let rowct1y=;
%let rowct2y=;
%let rowct3y=;
%let rowct4y=;
data cs;
 set &lib..cs&i;
 corr12_reason=reason;
 hess12_reason=hessian;
 keep study corr12_reason hess12_reason;
run;
data temp1;
 set &lib..cor&i;
run;
proc sort data=temp1;
 by study;
run;
proc sort data=studydescrip;
 by study;
run;
data temp2;
 merge temp1(in=in1) studydescrip;
 by study;
 if in1;
run;
/** Acute **/
data acute_row;
 set temp2;
 if (knot=4 and label in ("beta42 - beta41 at t=4 Months")) or
 (knot=6 and label in ("beta42 - beta41 at t=6 Months")) or
 (knot=8 and label in ("beta42 - beta41 at t=8 Months"));
run;
data _null_;
 set acute_row;
 call symput("rowacute",left(row)); 
run;
data acute;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  beta1_ce_corr=corr&rowacute;
  if eventnumber=. then delete;
  keep study allrx eventnumber beta1_ce_corr;
run;
%if %obsnumber(acute)=0 %then %do;
data acute;
 do eventnumber=1 to 9 by 1;
 study=&i;
 beta1_ce_corr=.;
output;
end;
run;
%end;
data acute_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 beta1_up12_corr=corr&rowacute;
 keep study allrx beta1_up12_corr;
run;
%if %obsnumber(acute_up12)=0 %then %do;
data acute_up12;
 study=&i;
 beta1_up12_corr=.;
run;
%end;
/** Chronic **/
data chronic_row;
 set temp2;
 if label in ("beta12 - beta11");
run;
data _null_;
 set chronic_row;
 call symput("rowchronic",left(row)); 
run;
data chronic;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  beta3_ce_corr=corr&rowchronic;
  if eventnumber=. then delete;
  keep study allrx eventnumber beta3_ce_corr;
run;
%if %obsnumber(chronic)=0 %then %do;
data chronic;
 do eventnumber=1 to 9 by 1;
 study=&i;
 beta3_ce_corr=.;
output;
end;
run;
%end;
data chronic_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 beta3_up12_corr=corr&rowchronic;
 keep study allrx beta3_up12_corr;
run;
%if %obsnumber(chronic_up12)=0 %then %do;
data chronic_up12;
 study=&i;
 beta3_up12_corr=.;
run;
%end;
/** Total 1y **/
data t1y_row;
 set temp2;
 if label in ("beta42 - beta41 at t=12 Months");
run;
data _null_;
 set t1y_row;
 call symput("rowt1y",left(row)); 
run;
data t1y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  beta4_ce_1y_corr=corr&rowt1y;
  if eventnumber=. then delete;
  keep study allrx eventnumber beta4_ce_1y_corr;
run;
%if %obsnumber(t1y)=0 %then %do;
data t1y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 beta4_ce_1y_corr=.;
output;
end;
run;
%end;
data t1y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 beta4_up12_1y_corr=corr&rowt1y;
 keep study allrx beta4_up12_1y_corr;
run;
%if %obsnumber(t1y_up12)=0 %then %do;
data t1y_up12;
 study=&i;
 beta4_up12_1y_corr=.;
run;
%end;
/** Total 2y **/
data t2y_row;
 set temp2;
 if label in ("beta42 - beta41 at t=24 Months");
run;
data _null_;
 set t2y_row;
 call symput("rowt2y",left(row)); 
run;
data t2y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  beta4_ce_2y_corr=corr&rowt2y;
  if eventnumber=. then delete;
  keep study allrx eventnumber beta4_ce_2y_corr;
run;
%if %obsnumber(t2y)=0 %then %do;
data t2y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 beta4_ce_2y_corr=.;
output;
end;
run;
%end;
data t2y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 beta4_up12_2y_corr=corr&rowt2y;
 keep study allrx beta4_up12_2y_corr;
run;
%if %obsnumber(t2y_up12)=0 %then %do;
data t2y_up12;
 study=&i;
 beta4_up12_2y_corr=.;
run;
%end;
/** Total 3y **/
data t3y_row;
 set temp2;
 if label in ("beta42 - beta41 at t=36 Months");
run;
data _null_;
 set t3y_row;
 call symput("rowt3y",left(row)); 
run;
data t3y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  beta4_ce_3y_corr=corr&rowt3y;
  if eventnumber=. then delete;
  keep study allrx eventnumber beta4_ce_3y_corr;
run;
%if %obsnumber(t3y)=0 %then %do;
data t3y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 beta4_ce_3y_corr=.;
output;
end;
run;
%end;
data t3y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 beta4_up12_3y_corr=corr&rowt3y;
 keep study allrx beta4_up12_3y_corr;
run;
%if %obsnumber(t3y_up12)=0 %then %do;
data t3y_up12;
 study=&i;
 beta4_up12_3y_corr=.;
run;
%end;
/** Total 4y **/
data t4y_row;
 set temp2;
 if label in ("beta42 - beta41 at t=48 Months");
run;
data _null_;
 set t4y_row;
 call symput("rowt4y",left(row)); 
run;
data t4y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  beta4_ce_4y_corr=corr&rowt4y;
  if eventnumber=. then delete;
  keep study allrx eventnumber beta4_ce_4y_corr;
run;
%if %obsnumber(t4y)=0 %then %do;
data t4y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 beta4_ce_4y_corr=.;
output;
end;
run;
%end;
data t4y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 beta4_up12_4y_corr=corr&rowt4y;
 keep study allrx beta4_up12_4y_corr;
run;
%if %obsnumber(t4y_up12)=0 %then %do;
data t4y_up12;
 study=&i;
 beta4_up12_4y_corr=.;
run;
%end;
/** Chronic - Total 1y **/
data ct1y_row;
 set temp2;
 if label in ("difference between treatment effect in 1 year total slope and chronic slope");
run;
data _null_;
 set ct1y_row;
 call symput("rowct1y",left(row)); 
run;
data ct1y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  chronic_t1y_ce_corr=corr&rowct1y;
  if eventnumber=. then delete;
  keep study allrx eventnumber chronic_t1y_ce_corr;
run;
%if %obsnumber(ct1y)=0 %then %do;
data ct1y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 chronic_t1y_ce_corr=.;
output;
end;
run;
%end;
data ct1y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 chronic_t1y_up12_corr=corr&rowct1y;
 keep study allrx chronic_t1y_up12_corr;
run;
%if %obsnumber(ct1y_up12)=0 %then %do;
data ct1y_up12;
 study=&i;
 chronic_t1y_up12_corr=.;
run;
%end;
/** Chronic - Total 2y **/
data ct2y_row;
 set temp2;
 if label in ("difference between treatment effect in 2 year total slope and chronic slope");
run;
data _null_;
 set ct2y_row;
 call symput("rowct2y",left(row)); 
run;
data ct2y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  chronic_t2y_ce_corr=corr&rowct2y;
  if eventnumber=. then delete;
  keep study allrx eventnumber chronic_t2y_ce_corr;
run;
%if %obsnumber(ct2y)=0 %then %do;
data ct2y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 chronic_t2y_ce_corr=.;
output;
end;
run;
%end;
data ct2y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 chronic_t2y_up12_corr=corr&rowct2y;
 keep study allrx chronic_t2y_up12_corr;
run;
%if %obsnumber(ct2y_up12)=0 %then %do;
data ct2y_up12;
 study=&i;
 chronic_t2y_up12_corr=.;
run;
%end;
/** Chronic - Total 3y **/
data ct3y_row;
 set temp2;
 if label in ("difference between treatment effect in 3 year total slope and chronic slope");
run;
data _null_;
 set ct3y_row;
 call symput("rowct3y",left(row)); 
run;
data ct3y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  chronic_t3y_ce_corr=corr&rowct3y;
  if eventnumber=. then delete;
  keep study allrx eventnumber chronic_t3y_ce_corr;
run;
%if %obsnumber(ct3y)=0 %then %do;
data ct3y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 chronic_t3y_ce_corr=.;
output;
end;
run;
%end;
data ct3y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 chronic_t3y_up12_corr=corr&rowct3y;
 keep study allrx chronic_t3y_up12_corr;
run;
%if %obsnumber(ct3y_up12)=0 %then %do;
data ct3y_up12;
 study=&i;
 chronic_t3y_up12_corr=.;
run;
%end;
/** Chronic - Total 4y **/
data ct4y_row;
 set temp2;
 if label in ("difference between treatment effect in 4 year total slope and chronic slope");
run;
data _null_;
 set ct4y_row;
 call symput("rowct4y",left(row)); 
run;
data ct4y;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  chronic_t4y_ce_corr=corr&rowct4y;
  if eventnumber=. then delete;
  keep study allrx eventnumber chronic_t4y_ce_corr;
run;
%if %obsnumber(ct4y)=0 %then %do;
data ct4y;
 do eventnumber=1 to 9 by 1;
 study=&i;
 chronic_t4y_ce_corr=.;
output;
end;
run;
%end;
data ct4y_up12;
 set temp2;
 if label in ("trtment effect in ACR change");
 chronic_t4y_up12_corr=corr&rowct4y;
 keep study allrx chronic_t4y_up12_corr;
run;
%if %obsnumber(ct4y_up12)=0 %then %do;
data ct4y_up12;
 study=&i;
 chronic_t4y_up12_corr=.;
run;
%end;
/** up12 **/
data up12_row;
 set temp2;
 if label in ("trtment effect in ACR change");
run;
data _null_;
 set up12_row;
 call symput("rowup12",left(row)); 
run;
data up12;
 set temp2;
       if label="LogHR( TrtID=2 : TrtID=1 ) for event 1" then eventnumber=1;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 2" then eventnumber=2;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 3" then eventnumber=3;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 4" then eventnumber=4;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 5" then eventnumber=5;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 6" then eventnumber=6;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 7" then eventnumber=7;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 8" then eventnumber=8;
  else if label="LogHR( TrtID=2 : TrtID=1 ) for event 9" then eventnumber=9;
  up12_ce_corr=corr&rowup12;
  if eventnumber=. then delete;
  keep study allrx eventnumber up12_ce_corr;
run;
%if %obsnumber(up12)=0 %then %do;
data up12;
 do eventnumber=1 to 9 by 1;
 study=&i;
 up12_ce_corr=.;
output;
end;
run;
%end;
proc sort data=acute;
 by study eventnumber;
run;
proc sort data=chronic;
 by study eventnumber;
run;
proc sort data=t1y;
 by study eventnumber;
run;
proc sort data=t2y;
 by study eventnumber;
run;
proc sort data=t3y;
 by study eventnumber;
run;
proc sort data=t4y;
 by study eventnumber;
run;
proc sort data=ct1y;
 by study eventnumber;
run;
proc sort data=ct2y;
 by study eventnumber;
run;
proc sort data=ct3y;
 by study eventnumber;
run;
proc sort data=ct4y;
 by study eventnumber;
run;
proc sort data=up12;
 by study eventnumber;
run;
data corr;
 merge acute chronic t1y t2y t3y t4y ct1y ct2y ct3y ct4y up12;
 by study eventnumber;
run;
proc sort data=corr;
 by study;
run;
proc sort data=acute_up12;
 by study;
run;
proc sort data=chronic_up12;
 by study;
run;
proc sort data=t1y_up12;
 by study;
run;
proc sort data=t2y_up12;
 by study;
run;
proc sort data=t3y_up12;
 by study;
run;
proc sort data=t4y_up12;
 by study;
run;
proc sort data=ct1y_up12;
 by study;
run;
proc sort data=ct2y_up12;
 by study;
run;
proc sort data=ct3y_up12;
 by study;
run;
proc sort data=ct4y_up12;
 by study;
run;
proc sort data=cs;
 by study;
run;
data corr;
 merge corr acute_up12 chronic_up12 t1y_up12 t2y_up12 t3y_up12 t4y_up12 ct1y_up12 ct2y_up12 ct3y_up12 ct4y_up12 cs;
 by study;
run;
proc sort data=corr;
 by study eventnumber;
run;
proc append force base=xcorr data=corr;
run;
proc datasets nolist;
 delete acute chronic t1y t2y t3y t4y up12 temp1 temp2 acute_row chronic_row t1y_row
        t2y_row t3y_row t4y_row up12_row corr acute_up12 chronic_up12 t1y_up12 t2y_up12 t3y_up12 t4y_up12 cs
        ct1y ct2y ct3y ct4y ct1y_row ct2y_row ct3y_row ct4y_row ct1y_up12 ct2y_up12 ct3y_up12 ct4y_up12;
run;
quit;
%end;
data &out;
 set xcorr;
 if study=0 then delete;
run;
proc datasets nolist;
 delete xcorr;
run;
quit;
%mend;