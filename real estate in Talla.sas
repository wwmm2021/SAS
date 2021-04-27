FILENAME data5939 '/home/u45032752/myfolder/data5939.csv';
proc import datafile=data5939
            DBMS=csv
            out= data;
            Getnames= YES;
quit;

/*******************************************************/

/*check the normality of Sold_Price*/

proc gchart data=work.data ;
      vbar Sold_Price/type=freq;
      run;

proc univariate data=work.data normal;
var Sold_price;
run;

proc univariate data=work.data noprint;
qqplot Sold_Price;
run;
/*log transfer */
proc sql;
create table data1 as
select log(Sold_Price) as Sold_Price,
       log(Date) as Date,
       log(LumberPrice) as LumberPrice,
       BuiltYear,
       log(Size) as Size,
       Area,
       Mortgage
from work.data
;
quit;

proc univariate data=work.data1 noprint;
qqplot Sold_Price;
run;

proc gchart data=work.data1 ;
      vbar Sold_Price/type=freq;
      run;

/* correlation coefficent*/
title"PROC CORR: Sold_Prise with predict vaviables";
proc corr data=work.data1 rank ;
     var Date BuiltYear LumberPrice Size Area Mortgage;
     with Sold_Price;
run;
title;

/* scatter plot*/
options ps=50 ls=64;
goptions reset=all gunit=pct border
fontres=presentation ftext=swissb;
axis1 length=70 w=3 color=blue label=(h=3) value=(h=3);
axis2 length=70 w=3 color=blue label=(h=3) value=(h=3);
proc gplot data=work.data1;
plot Sold_Price * (Date BuiltYear LumberPrice Size Area Mortgage)
/ vaxis=axis1 haxis=axis2;
symbol1 v=dot h=1 w=1 color=black;
title h=5 color=blueviolet 'sold price by Other Variables';
run;
quit;
/* full model method to choose model*/
proc reg data=work.data1;
ALL_REG: 
model Sold_Price =  Date BuiltYear LumberPrice Size Area Mortgage;
run;
quit;



/* residual test*/
proc reg data=work.data1;
PREDICT: 
model Sold_Price = Date BuiltYear LumberPrice Size Area Mortgage;
plot r.*(p. Date BuiltYear LumberPrice Size Area Mortgage);
plot student.*obs. / vref=3 2 -2 -3 haxis=0 to 32 by 1;
plot nqq.*student.; /**student. is residuals divided by their standard errors***/
symbol v=dot;
title 'PREDICT Model - Plots of Diagnostic Statistics';
run;
quit;

/****************************************************************************/
/*residual analyze*/
proc reg data=work.data1;
PREDICT: 
model Sold_Price = Date BuiltYear LumberPrice Size Area Mortgage;
plot r.*(p. Date BuiltYear LumberPrice Size Area Mortgage);
plot student.*obs. / vref=3 2 -2 -3 haxis=0 to 32 by 1;
plot nqq.*student.; /**student. is residuals divided by their standard errors***/
symbol v=dot;
title 'PREDICT Model - Plots of Diagnostic Statistics';
run;
quit;

/* delete outliers */
proc reg data=work.data1;
   PREDICT: 
   model Sold_Price = Date BuiltYear LumberPrice Size Area Mortgage/ r influence;
   output out=outliers 
          rstudent=rstud dffits=dfits cookd=cooksd;
   title;
run;
quit;

/*  set the values of these macro variables, */
/*  based on your data and model.            */
%let numparms = 7;  /* # of predictor variables + 1 */ 
%let numobs = 3776;   /* # of observations */
%let idvars = name; /* relevant identification variable(s) */
/*EM peocedure*/
data influential;
  set outliers;     
   cutdifts =2*(sqrt(&numparms/&numobs));
   cutcookd = 3/&numobs;

   rstud_i = (abs(rstud)>3);
   dfits_i = (abs(dfits)>cutdifts);
   cookd_i = (cooksd>cutcookd);
   sum_i = rstud_i + dfits_i + cookd_i;
   if sum_i > 0;
run;
/*delete outlier data from dataset*/
proc sql ;
create table data3 as
select Sold_Price, Date, BuiltYear, LumberPrice, Size, Area, Mortgage 
from data1 
     except
select Sold_Price, Date, BuiltYear, LumberPrice, Size, Area, Mortgage 
from influential
;
quit;

proc reg data=work.data3;
title h=2 'Best=4 Models Using All Regression Option';
ALL_REG: 
model Sold_Price =  Date BuiltYear LumberPrice Size Area Mortgage/ selection = rsquare adjrsq AIc BIC cp best=4  ;
run;
quit;



proc reg data=work.data3;
   FULLMODL: 
   model Sold_Price =  Date BuiltYear LumberPrice Size Area Mortgage
                         / vif collin collinoint; 
                
   title 'Collinearity -- Full Model';
run;
quit;


