%macro obsnumber(dataset);
%global nobs;
%let dsid=%sysfunc(open(&dataset));
%if &dsid %then %do;
%let nobs=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));
%end;
%eval(&nobs)
%mend;

