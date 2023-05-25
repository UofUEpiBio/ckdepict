%macro wregs(data,resp,weight,bys,vars,out);
ods listing close;
options nonotes nomprint nomlogic nosymbolgen;
proc sort data=&data;
 by &bys;
run;
proc reg data=&data outest=outest1 outseb edf tableout;
 model &resp=&vars;
 by &bys;
 freq &weight;
run;
quit;
data summary1;
 set outest1;
 if _type_="PARMS";
 keep &bys _rmse_ _rsq_ _p_ _edf_;
run;
data outest1a;
 set outest1;
 if _type_="PARMS";
 drop _depvar_ _in_ &resp _type_ _model_ _rmse_ _rsq_ _p_ _edf_;
run;
proc sort data=outest1a;
 by &bys;
run;
proc transpose data=outest1a out=outest1a1(drop=_label_ rename=(_name_=variable col1=estimate));
 var intercept &vars;
 by &bys;
run;
data outest1b;
 set outest1;
 if _type_="SEB";
 drop _depvar_ _in_ &resp _type_ _model_ _rmse_ _p_ _edf_ _rsq_ _rmse_;
run;
proc sort data=outest1b;
 by &bys;
run;
proc transpose data=outest1b out=outest1b1(drop=_label_ rename=(_name_=variable col1=se));
 var intercept &vars;
 by &bys;
run;
data outest1c;
 set outest1;
 if _type_="PVALUE";
 drop _depvar_ _in_ &resp _type_ _model_ _rmse_ _p_ _edf_ _rsq_ _rmse_;
run;
proc sort data=outest1c;
 by &bys;
run;
proc transpose data=outest1c out=outest1c1(drop=_label_ rename=(_name_=variable col1=pvalue));
 var intercept &vars;
 by &bys;
run;
data outest1d;
 set outest1;
 if _type_="L95B";
 drop _depvar_ _in_ &resp _type_ _model_ _rmse_ _p_ _edf_ _rsq_ _rmse_;
run;
proc sort data=outest1d;
 by &bys;
run;
proc transpose data=outest1d out=outest1d1(drop=_label_ rename=(_name_=variable col1=lcl95));
 var intercept &vars;
 by &bys;
run;
data outest1e;
 set outest1;
 if _type_="U95B";
 drop _depvar_ _in_ &resp _type_ _model_ _rmse_ _p_ _edf_ _rsq_ _rmse_;
run;
proc sort data=outest1e;
 by &bys;
run;
proc transpose data=outest1e out=outest1e1(drop=_label_ rename=(_name_=variable col1=ucl95));
 var intercept &vars;
 by &bys;
run;
proc sort data=outest1a1;
 by &bys variable;
run;
proc sort data=outest1b1;
 by &bys variable;
run;
proc sort data=outest1c1;
 by &bys variable;
run;
proc sort data=outest1d1;
 by &bys variable;
run;
proc sort data=outest1e1;
 by &bys variable;
run;
data s1;
 merge outest1a1 outest1b1 outest1c1 outest1d1 outest1e1;
 by &bys variable;
run;
proc sort data=summary1;
 by &bys;
run;
proc sort data=s1;
 by &bys;
run;
data &out;
 merge s1 summary1;
 by &bys;
run;
data &out;
 set &out;
 gmr=exp(estimate);
 gmr_lcl95=exp(lcl95);
 gmr_ucl95=exp(ucl95);
 gmr_pct=100*(exp(estimate)-1);
 gmr_lcl95_pct=100*(exp(lcl95)-1);
 gmr_ucl95_pct=100*(exp(ucl95)-1);
run;
proc sort data=&out;
 by &bys variable;
run;
proc datasets nolist;
 delete outest1a outest1b outest1c outest1d outest1e outest1a1 outest1b1 outest1c1 outest1d1 outest1e1 outest1 summary1 s1;
run;
quit;
ods listing;
options notes mprint symbolgen mlogic;
%mend;
