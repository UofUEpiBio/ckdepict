/* CKD dataset row-count helper.

   The %obsnumber macro is the ckdepict macros/obsnumber.sas definition,
   verbatim: it opens a dataset with %SYSFUNC(OPEN(...)), reads the NOBS
   attribute with %SYSFUNC(ATTRN(...,nobs)), closes the handle, and returns
   the observation count for use in downstream macro logic. The caller below
   builds two small trial datasets and reports each one's row count. */

%macro obsnumber(dataset);
%global nobs;
%let dsid=%sysfunc(open(&dataset));
%if &dsid %then %do;
%let nobs=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));
%end;
%eval(&nobs)
%mend;

data trials_all;
   input study_id region intervention;
   datalines;
1 1 1
2 2 5
3 3 14
4 1 21
5 2 26
6 3 9
7 1 6
;
run;

data trials_asia;
   set trials_all;
   where region = 2;
run;

%let n_all  = %obsnumber(trials_all);
%let n_asia = %obsnumber(trials_asia);

data counts;
   length dataset $16;
   dataset = "trials_all";  nobs = &n_all;  output;
   dataset = "trials_asia"; nobs = &n_asia; output;
run;

proc print data=counts noobs;
   var dataset nobs;
run;
