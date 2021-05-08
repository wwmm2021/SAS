
/* Appending and Concatenating  Files */
proc sort data=orion.qtr1 out=qtr1;by id;
proc sort data=orion.qtr2 out=qtr2;by id;
proc sort data=orion.qtr3 out=qtr3;by id;
proc sort data=orion.qtr4 out=qtr4;by id;

/* wide merge
Wide format – each row contains information for a single participant 
– variables are often numbered accordingly.
*/

data wide;
merge qtr1(rename=(qtr=qtr1)) qtr2(rename=(qtr=qtr2)) qtr3(rename=(qtr=qtr3)) qtr4(rename=(qtr=qtr4)); 
by id;
run;


proc corr data=wide;
var qtr:;
run;

/* long merge
Long format – each row contains a single measurement and the time it was taken.  
So each participant has multiple rows on the file.
*/

data long (keep=id quarter qtr);
  set qtr1 (in=a)
	 qtr2 (in=b) 
	 qtr3 (in=c) 
	 qtr4 (in=d); 
	if a then quarter=1;
	else if b then quarter=2;
	else if c then quarter=3;
	else if d then quarter=4;
run;

proc sort data=long;by id quarter;run;
proc print data=long noobs;run;

/* proc sgplot */

proc sgplot data=long;
series x=quarter y=qtr/group=id;
run;

proc sgplot data=long;
series x=quarter y=qtr/group=id markers;
run;

proc sgplot data=long;
series x=quarter y=qtr/group=id markers
 markerattrs=(symbol=circlefilled);
run;

proc sgplot data=long;
series x=quarter y=qtr/group=id markers 
		markerattrs=(symbol=circlefilled size=12)
		lineattrs=(thickness=3);
run;

title "Spaghetti Plot for 15 Employees";
proc sgplot data=long;
series x=quarter y=qtr/group=id markers 
		markerattrs=(symbol=circlefilled size=12)
		lineattrs=(thickness=3);
run;
title;

title "Spaghetti Plot for 15 Participants";
proc sgplot data=long;
series x=quarter y=qtr/group=id markers 
		markerattrs=(symbol=circlefilled size=12)
		lineattrs=(thickness=3);
xaxis label="Quarter" labelattrs=(family=swiss weight=bold);
yaxis label="Donation" labelattrs=(family=swiss weight=bold);
run;
title;


/* SQL join */
/*
Vertically –SET statement (Proc Append)
Horizontally – MERGE statement 
*/

data tmp1 tmp2;
		call streaminit(54321);
   do id=1 to 12;
		chol=int(rand("Normal",240,40));
		sbp=int(rand("Normal",120,20));
		if id<6 then output tmp1;
		else output tmp2;
	end;
run;
/* 
combine vertical 

SQL uses set operators to combine tables vertically.
*/
proc sql;
select * from tmp1
union
select * from tmp2
;
quit;

/*Data Step uses the set statement to combine tables vertically*/
title "Concatenation, data step";
data tot1;
	set tmp1 tmp2;
run;
proc print data=tot1 noobs;run;
title;

/*
SQL Joins combine data from multiple tables horizontally .

inner and outer SQL joins.
*/

data tmp1(keep=id chol sbp) tmp2(keep=id weight height);
		call streaminit(54321);
   do id=1,7,4,2,6;
		chol=int(rand("Normal",240,40));
		sbp=int(rand("Normal",120,20));
		output tmp1;
  	end;
   do id=2,1,5,7,3;
		height=round(rand("Normal",69,5),.25);
		weight=round(rand("Normal",160,10),.5);
		output tmp2;
	end;
run;
title "tmp1";
proc print data=tmp1 noobs;run;
title "tmp2";
proc print data=tmp2 noobs;run;


/*
Cartesian Product JOIN

A query that lists multiple tables in the FROM clause without a WHERE clause 
produces all possible combinations of rows from all tables -- Cartesian product
*/
title "Cartesian Product Join";
proc sql;
select * from tmp1,tmp2
;
quit;
title;

/* 
inner join 

Inner join syntax resembles Cartesian product syntax, 
but a WHERE clause restricts which rows are returned. 

*/
title "tmp1 inner join tmp2";
proc sql;
select * from tmp1,tmp2
where tmp1.id=tmp2.id
;
quit;

/*
Columns are not overlayed.

One method of displaying the a column only once is to use a table qualifier in the SELECT list. 

*/

data tmp1(keep=id chol sbp) tmp2(keep=id weight height chol);
		call streaminit(54321);
   do id=1,7,4,2,6;
		chol=int(rand("Normal",240,40));
		sbp=int(rand("Normal",120,20));
		output tmp1;
  	end;
   do id=2,1,5,7,3;
		height=round(rand("Normal",69,5),.25);
		weight=round(rand("Normal",160,10),.5);
		chol=int(rand("Normal",240,40));
		output tmp2;
	end;
run;
title "tmp1";
proc print data=tmp1 noobs;run;
title "tmp2";
proc print data=tmp2 noobs;run;

proc sql;
	select *
	from tmp1 as one,tmp2 as two
	where one.id=two.id
	;
quit;

proc sql;
	select one.id,one.chol,height,weight,sbp
	from tmp1 as one,tmp2 as two
	where one.id=two.id
	;
quit;

/*
The coalesce function

*/
data t;
   input x1 x2 x3 @@;
   x=coalesce(x1,x2,x3);
datalines;
1 2 3 . 2 3 . . 3
;
run;
proc print data=t noobs;run;

%let demographics=hsageir hssex DMAETHNR dmaracer dmarethn SDPSTRA6 SDPPSU6 WTPFQX6;
%let lib=work;
proc format lib=&lib;
    value f_SEX 1="Male" 2="Female";
	/*dmaracer*/
    value f_RACER 1="White" 2="Black" 3="Other" 8="Mexican-American of unknown race";
	/*DMARETHN */
    value f_rethn 1="Non-Hispanic white" 2="Non-Hispanic black" 3="Mexican-American" 4="Other";
	/*DMAETHNR*/    
    value f_ethnr 1="Mexican-American" 2="Other Hispanic" 3="Not Hispanic";
run;
proc sql;
	create table &lib..adultdemographics as
	select seqn,
		   hsageir as age ,
		   hssex as sex format=f_sex.,
		   dmaracer as race format=f_racer.,
		   dmarethn as race_ethn format=f_rethn.,
		   dmaethnr as hispanic format= f_ethnr.,
		   SDPSTRA6 as strata, /*strata for survey procs*/
		   SDPPSU6 as cluster, /*cluster for survey procs*/
		   WTPFQX6 as weight /*weight for survey procs*/
		   from nhanes3.adult
		   where seqn in (select seqn from nhanes3.mortality 		   					
		                              where eligstat=1)
	;
run;
	
proc contents data=&lib..adultdemographics;
run;

/* Views */
/*What Is a PROC SQL View?*/
/*
A stored query

Contains no actual data

Extracts underlying data each time that it is used -- accesses the most current data

Can be referenced in SAS programs in the same way as a data table

Cannot have the same name as a data table stored in the same SAS library.
*/
/*CREATE VIEW view-name AS query-expression;*/

proc sql;
create view Tom_Zhou as
   select Employee_Name as Name format=$25.0,
          Job_Title as Title format=$15.0,
          Salary 'Annual Salary' format=comma10.2,
          int((today()-Employee_Hire_Date)/365.25) 
             as YOS 'Years of Service'
      from orion.Employee_Addresses as a,
           orion.Employee_Payroll as p,
           orion.Employee_Organization as o
      where a.Employee_ID=p.Employee_ID and
            o.Employee_ID=p.Employee_ID and
            Manager_ID=120102;/*Tom Zhou’s id*/
quit;

proc contents data=orion.tom_zhou;
run;

proc sql;
   describe view orion.Tom_Zhou;
quit;

/*model1 Defining Columns*/
proc sql;
   create table Discounts
      (Product_ID num format=z12.,
       Start_Date date,
       End_Date date,
       Discount num format=percent.);
quit;
proc contents data=discounts;run;

proc sql;
   create table Testing_Types
      (Char_Column char(4),
       Varchar_Column varchar,
       Int_Column int, 
       SmallInt_Column smallint, 
       Dec_Column dec, 
       Num_Column num,  
       Float_Column float, 
       Real_Column real,
       Date_Column date,
       Double_Column double precision);
quit;
proc contents data=testing_types;run;

/*
Method 2: Copying Table Structure
*/
proc sql; 
create table work.New_Sales_Staff like orion.Sales
;
quit;
proc contents data=new_sales_staff;
run;

/*
Method 3: Create and populate a table with an SQL query.
*/

proc sql;
create table work.Melbourne as
   select Employee_Name as Name,Salary
      from orion.Staff as s,
           orion.Employee_addresses as a
      where s.Employee_ID=a.Employee_ID
	       and City ="Melbourne";
quit;
proc contents data=melbourne;run;

/*
Adding Data to a Table, the INSERT Statement
The INSERT statement can be used to add data to an empty table, 
or to append data to a table that already contains data, 
using one of three methods.

INSERT INTO table-name 
SET column-name=value,
column-name=value,...;

INSERT INTO table-name
<(column list)>
VALUES (value,value,...);

INSERT INTO table-name
<(column list)>
SELECT columns
FROM table-name;
*/

/*
The SET clause requires that you add data using column name–value pairs:
*/

proc sql;
insert into Discounts
   set Product_ID=230100300006,
       Start_Date='01MAR2007'd,
       End_Date='15MAR2007'd,Discount=.33
   set Product_ID=230100600018,
       Start_Date='16MAR2007'd,
       End_Date='31MAR2007'd, Discount=.15
;
quit;
proc print data=discounts;run;

/*
The VALUES clause adds data to the columns in a single row of data.  
The VALUES clause must produce values in the same order as the INSERT INTO statement column list.
*/
proc sql;
   create table Discounts
      (Product_ID num format=z12.,
       Start_Date date,
       End_Date date,
       Discount num format=percent.)
;
insert into Discounts
   values (230100300006,'01MAR2007'd,
          '15MAR2007'd,.33)
   values (230100600018,'16MAR2007'd,
          '31MAR2007'd,.15)
;
select * from discounts;
quit;

/*
Query results are inserted positionally. 
The query must produce values in the same order as the INSERT statement column list.
*/
proc sql;
   create table Discounts
      (Product_ID num format=z12.,
       Start_Date date,
       End_Date date,
       Discount num format=percent.)
;
insert into Discounts
     (Product_ID,Discount,Start_Date,End_Date)
      select distinct Product_ID,.35,
             '01MAR2007'd,'31mar2007'd
         from orion.Product_Dim
         where Supplier_Name contains 
              'Pro Sportswear Inc'
;
select * from discounts;
quit;

/*
integrity constraints

Integrity constraints are rules enforced when data is added to a table to guarantee data validity.
To preserve the consistency and correctness of your data, specify integrity constraints for the SAS data file.
SAS uses integrity constraints to validate data values when you insert or update columns for which you defined integrity constraints.

Integrity constraints were added to Base SAS software in SAS 8
follow ANSI standards
Cannot be defined for views
Can be specified when a table is created
Can be added to a table that already contains data
Are commonly found in large database management systems (DBMS) with frequently updated tables.
*/
proc sql;
create table Discounts
  (Product_ID num format=z12.,
   Start_Date date,
   End_Date date,
   Discount num format=percent.
   )
;
describe table discounts;
quit;
proc contents data=discounts;run;

proc sql;
insert into Discounts
   values (240500200009,'01Mar2007'd,
           '31Mar2007'd,.45)
   values (220200200036,'01Mar2007'd,
           '31Mar2007'd,.54)
   values (220200200038,'01Mar2007'd,
           '31Mar2007'd,.25)
;
quit;
proc print data=discounts noobs;run;

/*
General form of PROC SQL using integrity constraints:
*/
proc sql;
create table Discounts
  (Product_ID num format=z12.,
   Start_Date date,
   End_Date date,
   Discount num format=percent.,
   constraint ok_discount 
   check (Discount le .5))
;
describe table discounts;
quit;
proc contents data=discounts;run;

proc sql;
insert into Discounts
   values (240500200009,'01Mar2007'd,
           '31Mar2007'd,.45)
   values (220200200036,'01Mar2007'd,
           '31Mar2007'd,.54)
   values (220200200038,'01Mar2007'd,
           '31Mar2007'd,.25)
;
quit;

/*What should we do if there is a constraint failure?UNDO_POLICY Option*/
/*
UNDO_POLICY=REQUIRED (default)
undoes all inserts or updates up to the point of the error. Sometimes the UNDO operation cannot be accomplished reliably.
UNDO_POLICY=NONE
rejects only rows that violate constraints. Rows that do not violate constraints are inserted.
UNDO_POLICY=OPTIONAL
operates in a manner similar to REQUIRED when the UNDO operation can be accomplished reliablyotherwise, operates similar to NONE.
*/
proc sql undo_policy=none;
create table Discounts
  (Product_ID num format=z12.,
   Start_Date date,
   End_Date date,
   Discount num format=percent.,
   constraint ok_discount 
   check (Discount le .5))
;
insert into Discounts
   values (240500200009,'01Mar2007'd,
           '31Mar2007'd,.45)
   values (220200200036,'01Mar2007'd,
           '31Mar2007'd,.54)
   values (220200200038,'01Mar2007'd,
           '31Mar2007'd,.25)
;
quit;

proc sql undo_policy=optional;
create table Discounts
  (Product_ID num format=z12.,
   Start_Date date,
   End_Date date,
   Discount num format=percent.,
   constraint ok_discount 
   check (Discount le .5))
;
insert into Discounts
   values (240500200009,'01Mar2007'd,
           '31Mar2007'd,.45)
   values (220200200036,'01Mar2007'd,
           '31Mar2007'd,.54)
   values (220200200038,'01Mar2007'd,
           '31Mar2007'd,.25)
;
quit;
proc print data=discounts noobs;run;

/*
PROC SQL;
	DESCRIBE TABLE table-name<, …table-name>;
   	DESCRIBE VIEW proc-sql-view <, …proc-sql-view>;
   	DESCRIBE TABLE CONSTRAINTS table-name		                         <, …table-name>;
*/
proc sql;
   describe table  Discounts;
quit;

/*
SQL set operators and modifiers
Except 
intersect
Union
##Columns are matched by position and must be the same data type.
Column names in the final result set are determined by the first result set.##

Outer Union
All columns from both result sets are selected.

*/
data t1(drop=i) t2(drop=i rename=(z=w));
call streaminit(54321);
do i= 1 to 3;
  x=int(rand("uniform")*5);
  z=int(rand("uniform")*5);
  output t1;
  output t2;
end;
do i= 4 to 6;
  x=int(rand("uniform")*5);
  z=int(rand("uniform")*5);
  output t1;
  x=int(rand("uniform")*6);
  z=int(rand("uniform")*6);
  output t2;
end;
run;

data t1;
	set t1 end=done;
	output;
	if done then output;
run;
data  t2;
	set  t2 end=done;
	output;
	if _n_=1 then output;
run;
/*
1.Unique rows from the first table that are not found in the second table are selected.
2.Columns are matched by position and must be the same data type.
3.Column names in the final result set are determined by the first result set.
*/
proc sql;
   select *
      from t1 
   except 
   select *
      from t2
;
quit;

/*
CORR – overlays by name and removes columns not on both tables
*/
proc sql;
   select *
      from t1 
   except corr 
   select *
      from t2;
quit;

/*
ALL – does not remove duplicate rows  (not allowed in outer union)
*/
proc sql;
   select *
   	from t1
	except all
   select * 
    from t2
;
quit;

proc sql;
   select *
      from t1 
   except corr all
   select *
      from t2;
quit;

proc sql;
   select count(*) 'No. Non-Sales Employees'
      from (select *
               from orion.Employee_organization
            except all corr
            select * 
               from orion.Sales);
quit;








