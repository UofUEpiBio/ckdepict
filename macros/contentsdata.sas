%macro contentsdata(data,path);
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
proc contents data=&data;
ods output variables=&data._vars;
run;
proc sort data=&data._vars;
 by num;
run;
proc export data=&data._vars
            outfile="&path\&data._vars.csv"
            dbms=csv replace;
run;
proc export data=&data
            outfile="&path\&data..csv"
            dbms=csv replace;
run;
ods listing;
options notes mprint symbolgen mlogic;
%mend;