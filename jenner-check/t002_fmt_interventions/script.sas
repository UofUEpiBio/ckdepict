/* CKD trial intervention labelling.

   The if/else-if ladders below (intervention_fmt full descriptions and
   intervention_abrev short codes) are the ckdepict macros/interventions.sas
   fragment, run here against a small set of intervention codes. The coding
   is unchanged: 1=RASB vs CONTROL, 14=SGLT-2 Inhibitor, 21=Mineralocorticoid
   receptor antagonist, 26=ARNI, etc. */

data trial_arms;
   input trial_id intervention;
   datalines;
1 1
2 2
3 5
4 6
5 9
6 14
7 20
8 21
9 26
10 27
;
run;

data trial_labelled;
   set trial_arms;
   length intervention_fmt $29 intervention_abrev $6;

       if intervention=1  then intervention_fmt="RASB vs CONTROL              ";
  else if intervention=2  then intervention_fmt="RASB v CCB                   ";
  else if intervention=3  then intervention_fmt="Low v Usual BP               ";
  else if intervention=4  then intervention_fmt="Low v Usual Diet             ";
  else if intervention=5  then intervention_fmt="Immunosuppression            ";
  else if intervention=6  then intervention_fmt="Allopurinol                  ";
  else if intervention=7  then intervention_fmt="Albuminuria Targeted Protocol";
  else if intervention=8  then intervention_fmt="Fish Oil                     ";
  else if intervention=9  then intervention_fmt="Intensive Glucose            ";
  else if intervention=10 then intervention_fmt="Fenofibrate                  ";
  else if intervention=12 then intervention_fmt="Nurse-coordinated Care       ";
  else if intervention=14 then intervention_fmt="SGLT-2 Inhibitor             ";
  else if intervention=15 then intervention_fmt="RASB+CCB	                  ";
  else if intervention=16 then intervention_fmt="Diuretic vs RASB+CCB         ";
  else if intervention=18 then intervention_fmt="DPP-4 Inhibitor              ";
  else if intervention=20 then intervention_fmt="GLP-1 Agonist                ";
  else if intervention=21 then intervention_fmt="Mineralocort. rec. antagonist";
  else if intervention=22 then intervention_fmt="Statin 		              ";
  else if intervention=23 then intervention_fmt="PPAR agonist                 ";
  else if intervention=24 then intervention_fmt="Endothelin rec. antagonist   ";
  else if intervention=25 then intervention_fmt="Antiplatelet			      ";
  else if intervention=26 then intervention_fmt="Angiotensin rec/neprilysin in";
  else if intervention=27 then intervention_fmt="Cardiac Myosin Activatation  ";

       if intervention=1  then intervention_abrev="RAS   ";
  else if intervention=2  then intervention_abrev="RvC   ";
  else if intervention=5  then intervention_abrev="IS    ";
  else if intervention=6  then intervention_abrev="ALLO  ";
  else if intervention=9  then intervention_abrev="GLUC  ";
  else if intervention=14 then intervention_abrev="SGLT2I";
  else if intervention=20 then intervention_abrev="GLP1A ";
  else if intervention=21 then intervention_abrev="MRA   ";
  else if intervention=26 then intervention_abrev="ARNI  ";
  else if intervention=27 then intervention_abrev="CMyAct";
run;

proc print data=trial_labelled noobs;
   var trial_id intervention intervention_abrev intervention_fmt;
run;
