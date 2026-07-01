/* CKD study region / pooling-status labelling.

   The two if/else-if ladders below are the ckdepict macros/regions.sas
   (region: 1=NA/Eur/Aus, 2=Asia, 3=International) and macros/pooled.sas
   (pooled: 1=No, 2=Indiv. Study Pooled, 3=Pooled Study) fragments. They are
   applied verbatim to a small set of study attribute rows and then summarised
   with a region-by-pooling crosstab. */

data study_attr;
   input study_id region pooled;
   datalines;
101 1 1
102 1 2
103 2 1
104 2 3
105 3 2
106 3 3
107 1 1
108 2 2
109 3 1
110 1 3
;
run;

data study_attr_lbl;
   set study_attr;
   length region_fmt $13 pooled_fmt $19;

/** Formats region **/
        if region=1 then region_fmt="NA,Eur,Aus   ";
   else if region=2 then region_fmt="Asia         ";
   else if region=3 then region_fmt="International";

/** Formats for pooled **/
        if pooled=1 then pooled_fmt="No                 ";
   else if pooled=2 then pooled_fmt="Indiv. Study Pooled";
   else if pooled=3 then pooled_fmt="Pooled Study       ";
run;

proc print data=study_attr_lbl noobs;
   var study_id region_fmt pooled_fmt;
run;

proc freq data=study_attr_lbl;
   tables region_fmt*pooled_fmt / norow nocol nopercent;
run;
