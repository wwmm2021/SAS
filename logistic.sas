/*Example 1*/
data lung;
   input personal_smoke passive_smoke Disease count;
   datalines;
0 1 1 120
0 1 0 80
0 0 1 111
0 0 0 155
1 1 1 161
1 1 0 130
1 0 1 117
1 0 0 124
;
run;	
proc logistic data=lung;
/*since personal_smoke and passive_smoke are coded as 0 or 1, 
we do not need a class statement*/
   freq count;
   model disease(event='1')=personal_smoke passive_smoke;
run;

/*Example 2*/
proc logistic data=sashelp.heart;
class BP_status;
model status(event='Dead')=BP_status AgeAtStart;
run;
