/* CKD disease / disease2 category labelling.

   The body below (the if/else-if assignment ladders for disease_fmt and
   disease2_fmt) is the ckdepict macros/diseases.sas fragment, applied here
   to a small set of disease codes so the labelling can be exercised on its
   own. The category coding (1=CKD-CNS, 2=CKD-HTN, ... 8=Diabetes, ...) and
   the second grouping (disease2: 1=CKD, 2=Diabetes, ...) are unchanged. */

data study_codes;
   input study_id disease disease2;
   datalines;
101 1 1
102 2 1
103 3 2
104 4 3
105 5 3
106 8 2
107 9 5
108 10 4
109 11 3
110 13 2
;
run;

data study_labelled;
   set study_codes;
   length disease_fmt $14 disease2_fmt $14;

  /** Formats disease **/
       if disease=1 then  disease_fmt="CKD-CNS       ";
  else if disease=2 then  disease_fmt="CKD-HTN       ";
  else if disease=3 then  disease_fmt="CKD-DN        ";
  else if disease=4 then  disease_fmt="IgAN          ";
  else if disease=5 then  disease_fmt="Lupus         ";
  else if disease=6 then  disease_fmt="Membranous    ";
  else if disease=7 then  disease_fmt="PKD           ";
  else if disease=8 then  disease_fmt="Diabetes      ";
  else if disease=9 then  disease_fmt="Heart failure ";
  else if disease=10 then disease_fmt="High CV risk  ";
  else if disease=11 then disease_fmt="FSGS          ";
  else if disease=12 then disease_fmt="Per. Art. Dis.";
  else if disease=13 then disease_fmt="Diabetes - CKD";

  /** Formats disease2 **/
       if disease2=1 then disease2_fmt="CKD           ";
  else if disease2=2 then disease2_fmt="Diabetes      ";
  else if disease2=3 then disease2_fmt="Glomerular    ";
  else if disease2=4 then disease2_fmt="Cardiovascular";
  else if disease2=5 then disease2_fmt="Heart failure ";
run;

proc print data=study_labelled noobs;
   var study_id disease disease_fmt disease2 disease2_fmt;
run;

proc freq data=study_labelled;
   tables disease_fmt / nocum;
run;
