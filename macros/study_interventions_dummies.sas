zstudy1=0;
zstudy2=0;
zstudy3=0;
ztrt1=0;
ztrt2=0;

if allrx=100 then do;
 if combo=48 then zstudy1=1;else if combo in (51 52) then zstudy1=0;
 if combo=51 then zstudy2=1;else if combo in (48 52) then zstudy2=0;
end;

if allrx=101 then do;
 if combo=33 then zstudy1=1;else if combo=36 then zstudy1=0;
end;

if allrx=102 then do;
 if combo=25 then zstudy1=1;else if combo=28 then zstudy1=0;
end;

if allrx=103 then do;
 if combo=49 then zstudy1=1;else if combo=50 then zstudy1=0;
end;

if allrx=200 then do;
 if combo=29 then zstudy1=1;else if combo in (30 31 32) then zstudy1=0;
 if combo=30 then zstudy2=1;else if combo in (29 31 32) then zstudy2=0;
 if combo=31 then zstudy3=1;else if combo in (29 30 31) then zstudy3=0;
end;

if allrx=10 then do;
 if treat2=1 then ztrt1=1;else if treat2=2 then ztrt1=0;
end;

if allrx=40 then do;
 if treat2=1 then ztrt1=1;else if treat2=2 then ztrt1=0;
end;

if allrx=41 then do;
 if treat2=1 then ztrt1=1;else if treat2=2 then ztrt1=0;
end;

if allrx=42 then do;
 if treat1=2 then ztrt1=1;else if treat1 in (3 4) then ztrt1=0;
 if treat1=3 then ztrt2=1;else if treat1 in (2 4) then ztrt2=0;
end;

if allrx=43 then do;
 if treat2=1 then ztrt1=1;else if treat2=2 then ztrt1=0;
end;

if allrx=44 then do;
 if treat1=5 then ztrt1=1;else if treat1=6 then ztrt1=0;
end;


if allrx=45 then do;
 if treat2=1 then ztrt1=1;else if treat2=2 then ztrt1=0;
end;

if allrx=46 then do;
 if treat1=5 then ztrt1=1;else if treat1=6 then ztrt1=0;
end;

if allrx=47 then do;
 if treat1=2 then ztrt1=1;else if treat1=4 then ztrt1=0;
end;

if allrx=54 then do;
 if treat2=1 then ztrt1=1;else if treat2=2 then ztrt1=0;
end;

if allrx=62 then do;
 if treat1=0 then ztrt1=1;else if treat1=1 then ztrt1=0;
end;

if allrx=70 then do;
 if treat3=1 then ztrt1=1;else if treat2=1 then ztrt1=0;
end;

if allrx=71 then do;
 if treat1=0 then ztrt1=1;else if treat1=1 then ztrt1=0;
end;
  


