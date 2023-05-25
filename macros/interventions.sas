/** Formats for intervention **/
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
/*else if intervention=11 then intervention_fmt="Sulodexide v placebo         ";*/
  else if intervention=12 then intervention_fmt="Nurse-coordinated Care       ";
/*else if intervention=13 then intervention_fmt="Statin+Ezetimibe             ";*/
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

       if intervention=1  then intervention_abrev="RAS   ";
  else if intervention=2  then intervention_abrev="RvC   ";
  else if intervention=3  then intervention_abrev="BP    ";
  else if intervention=4  then intervention_abrev="DIET  ";
  else if intervention=5  then intervention_abrev="IS    ";
  else if intervention=6  then intervention_abrev="ALLO  ";
  else if intervention=7  then intervention_abrev="ALB   ";
  else if intervention=8  then intervention_abrev="FO    ";
  else if intervention=9  then intervention_abrev="GLUC  ";
  else if intervention=10 then intervention_abrev="FIB   ";
/*else if intervention=11 then intervention_abrev="SUL   ";*/
  else if intervention=12 then intervention_abrev="NURSE ";
/*else if intervention=13 then intervention_abrev="StatEz";*/
  else if intervention=14 then intervention_abrev="SGLT2I";
  else if intervention=15 then intervention_abrev="RASCCB";
  else if intervention=16 then intervention_abrev="Diu.vC";
  else if intervention=18 then intervention_abrev="DPP4I ";
  else if intervention=20 then intervention_abrev="GLP1A ";
  else if intervention=21 then intervention_abrev="MRA   ";
  else if intervention=22 then intervention_abrev="Statin";  
  else if intervention=23 then intervention_abrev="PPARA ";  
  else if intervention=24 then intervention_abrev="ERA   "; 
  else if intervention=25 then intervention_abrev="AP    "; 
