
FILENAME data '/home/u45032752/myfolder/5939data.csv';
/* read the tallahassee real estate market data*/
PROC IMPORT DATAFILE=data
	DBMS=CSV
	OUT=WORK.realmarket;
	GETNAMES=YES;
RUN;

/* check the data set*/
proc print data= work.realmarket(obs=10);run;

/*check the data format */

proc contents data=work.realmarket;run;

/*format date*/
data tallahassee;
set work.realmarket(rename=(CloseDate = Date  ));
format Date mmddyy10.;
run;

/*
proc print data = tallahassee(obs=10);run;
*/

FILENAME lumber '/home/u45032752/myfolder/5939lumber.csv';
/* import lumber history price*/      
PROC IMPORT DATAFILE=lumber
	DBMS=CSV
	OUT=WORK.lumberprice;
	GETNAMES=YES;
RUN;

/* check the data set */
proc print data = work.lumberprice(obs=10);run;

/*check the date format*/
proc contents data= work.lumberprice;run;


data lumber;
     set work.lumberprice(rename=(Price = LumberPrice));
     Date = datepart(Date);
     format Date mmddyy10.;
     run;
 

/* merge the house data with lumber data*/
proc sql;
create table new1 as
select * 
    from work.tallahassee as t,
         work.lumber as l
    where   t.Date = l.Date;
    quit;

proc contents data=new1;run;

FILENAME interest '/home/u45032752/myfolder/5939mortgage.csv';
/*import interest data*/
proc import datafile=interest
            DBMS=csv
            out= mortgage;
            Getnames= YES;
run;

/*check the data set*/
proc print data= work.mortgage(obs=50);run;

/* check the data format*/
proc contents data=work.mortgage;run;

data interest;
set work.mortgage(rename=(DATE = Date));
format Date mmddyy10.;
run;

proc sql;
create table new2 as 
select * 
from work.new1 as n
    left join work.interest as i
     on n.Date = i.Date;
run;

proc print data=new2(obs=30);run;

proc contents data= new2;run;

/*  **********************************************/
FILENAME data1 '/home/u45032752/myfolder/data.csv';
proc import datafile=data1
            DBMS=csv
            out= data2;
            Getnames= YES;
run;
/*check  the  data */
proc contents data=data2;run;


/* prepare data set : correct wrong data  and delete missing rows*/
data data ;
     set data2(rename=(MORTGAGE30US = Mortgage Price = LumberPrice));
     SoldPrice = substr(SoldPrice,2,length(SoldPrice)-1);
     SoldPrice=compress(scan(SoldPrice, 1, ",")||scan(SoldPrice, 2, ","));
     Sold_Price = input(SoldPrice,8.);
     if BuiltYear = 0 then do;
        BuiltYear = 2020;
        end;
     if Size eq . then delete;
     drop Address Price_sqf SoldPrice ;
run;



title "check whether some wrong or missing in the row data";
proc means data=data;
var Sold Date BuiltYear Size Community LumberPrice Mortgage;
run;
title ;



/* get  average value for deffirent community*/
proc sql;
create table community as 
       select mean(Sold_Price) "Average" format = Best12., Community
       from work.data
       group  by Community
       ;
quit;

/*let area get the numeric depend on average value*/
data new3;
set work.data;
 select(Community);
    when(6) do;
        Area = 1;
        end;
    when(7) do;
        Area = 2;
        end;
    when(11) do;
        Area = 3;
        end;   
    when(10) do;
        Area = 4;
        end; 
    when(8) do;
        Area = 5;
        end; 
    when(2) do;
        Area = 6;
        end; 
    when(3) do;
        Area = 7;
        end; 
    when(5) do;
        Area = 8;
        end; 
    when(4) do;
        Area = 9;
        end; 
    when(1) do;
        Area = 10;
        end; 
    otherwise do;
        Area = 11;
        end; 
  end;
drop Community;
run;
run;
/****************************************************/
FILENAME data5939 '/home/u45032752/myfolder/5939data1.csv';
proc import datafile=data5939
            DBMS=csv
            out= newdata;
            Getnames= YES;
/*check dataset*/
title"dataset after clearing";
proc means data=newdata;run;
title;

title "prepared dataset";
proc print data=work.newdata(obs=5);run;
title;
proc contents data= work.newdata;run;
/*********************************************/

/*create new dataset */
data analyze1;
length LivingSize $8 Community $30;
set work.newdata;
Quarter = qtr(Date);
Month = month(Date);
Year = year(Date);
select(Year);
     when(2017) do; Sold2017 = Sold_Price;end;
     when(2018) do; Sold2018 = Sold_Price;end;
     when(2019) do; Sold2019 = Sold_Price;end;
     otherwise  do; Sold2020 = Sold_Price;end;  
     end;
if Size<1600 then 
       LivingSize = "low";
if Size >2400 then 
        LivingSize = "high";
if 1600 <= Size <= 2400 then 
        LivingSize = "middle";
select (Area);
      when(1) do;Community = 'kln-acres'; end;
      when(2) do;Community = 'piney-z'; end; 
      when(3) do;Community = 'kln-estates'; end;
      when(4) do;Community = 'kln-lakes'; end;
      when(5) do;Community = 'waverly'; end;
      when(6) do;Community = 'southwood'; end;
      when(7) do;Community = 'bullrun'; end;
      when(8) do;Community = 'xbottom'; end;
      when(9) do;Community = 'sumbrook'; end;
      when(10) do;Community = 'Goldeneagle'; end;
      otherwise do;Community = 'centerville'; end;
      end;
run;
/*create new dataset */
data analyze1;
length LivingSize $8 Community $30;
set work.newdata;
Quarter = qtr(Date);
Month = month(Date);
Year = year(Date);
select(Year);
     when(2017) do; Sold2017 = Sold_Price;end;
     when(2018) do; Sold2018 = Sold_Price;end;
     when(2019) do; Sold2019 = Sold_Price;end;
     otherwise  do; Sold2020 = Sold_Price;end;  
     end;
if Size<1600 then 
       LivingSize = "Small";
if Size >2400 then 
        LivingSize = "Large";
if 1600 <= Size <= 2400 then 
        LivingSize = "middle";
select (Area);
      when(1) do;Community = 'kln-acres'; end;
      when(2) do;Community = 'piney-z'; end; 
      when(3) do;Community = 'kln-estates'; end;
      when(4) do;Community = 'kln-lakes'; end;
      when(5) do;Community = 'waverly'; end;
      when(6) do;Community = 'southwood'; end;
      when(7) do;Community = 'bullrun'; end;
      when(8) do;Community = 'xbottom'; end;
      when(9) do;Community = 'sumbrook'; end;
      when(10) do;Community = 'Goldeneagle'; end;
      otherwise do;Community = 'centerville'; end;
      end;
run;

/* check the sold price distribute by year*/
proc sql;
create table trend as
select Month, 
       avg(Sold2017) as y2017, 
       avg(Sold2018) as y2018, 
       avg(Sold2019) as y2019, 
       avg(Sold2020) as y2020
from work.analyze1
group by Month;
run;
quit;

symbol1  value=dot  cv=red interpol=join  ci=red line=4;
symbol2  value=+  cv=green  interpol=join  ci=green  line=4;
symbol3  value=#  cv=yellow  interpol=join  ci=yellow  line=4;
symbol4  value=*  cv=blue  interpol=join  ci=blue  line=4;
proc  gplot  data=work.trend;
title  'Yearly  mean Sold price  Series by month';
plot  y2017*MOnth  y2018*Month y2019*Month y2020*Month/overlay legend;
run;
quit;

/* show the average sold price by month*/
data yprice ;
set analyze1;
where LivingSize = "middle";
select(Year);

     when(2017) do; Month = Month;end;
     when(2018) do; Month = Month+12;end;
     when(2019) do; Month = Month+24;end;
     otherwise  do; Month = Month+36;end;  
     end;
keep Sold_Price Month;
run;

proc sql;
create table YearPrice as
select Month, avg(Sold_Price) as Price
from work.yprice
group by Month
;
run;
quit;

symbol1  value=dot  cv=red interpol=join  ci=red line=4;
proc gplot data=work.YearPrice;
title "Average Sales Price trend by year on middle size house";
plot Price*Month;
run ;

/* analyze the  mean sold price on different living size by community and year*/ 
title "Average Sales Price by LivingSize on diffirent Area and year";
legend1 cborder=black
label=("Year:")
position=(bottom right outside)
mode=protect
across=1;
proc gchart data=analyze1;
     block LivingSize /sumvar=Sold_Price 
     type= mean
     group= Area
     subgroup= Year
     legend=legend1
     noheading;
run;
quit;
/* list Area -- Community*/
proc sql;
select mean(Area) as Area,Community
from work.analyze1
group by Community
order by Area;
run;

title "Average Sales Price by LivingSize on diffirent Community and year";
legend1 cborder=black
label=("Year:")
position=(bottom right outside)
mode=protect
across=1;
proc gchart data=analyze1;
     block LivingSize /sumvar=Sold_Price 

     type= mean
     group= Community
     subgroup= Year
     legend=legend1
     noheading;
run;
quit;


