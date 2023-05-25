%macro numwordst(lst);
   %local i v;
   %let i = 1;
   %let v = %scan(&lst,&i,'~');
   %do %while (%length(&v) > 0);
      %let i = %eval(&i + 1);
      %let v = %scan(&lst,&i,'~');
      %end;
   %eval(&i - 1)
%mend;

