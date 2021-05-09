/*Macro Expressions
Similarities to SAS expressions:
arithmetic operators
logical operators (Do not precede AND or OR with %.)
comparison operators (symbols and mnemonics)
case sensitivity
special WHERE operators not valid

Differences compared to SAS expressions:
Character operands are not quoted.
Ranges such as 1 <= &x <= 10 behave differently.
The IN operator does not require parentheses.
*/
proc sql;
	title "Order dates on orion.order_fact";
	select min(order_date) format= mmddyy8.,
	       max(order_date) format= mmddyy8.
	from orion.order_fact;
   select today()-max(order_date) into :diff
   from orion.order_fact;
quit;
title;
%put No of days between yesterday and max order date: &diff;

data recent_orders;
   set orion.order_fact;
   order_date=order_date+&diff;/*make last order today*/;
run;   
proc sql;
  select min(order_date) as first_date format=mmddyy10.,
         max(order_date) as last_date format=mmddyy10.
  from recent_orders;
  ;
quit;

proc print data=recent_orders;
   where order_date="&sysdate9"d;
   var product_id total_retail_price;
   title "Daily sales: &sysdate9";
run;

proc means data=recent_orders n sum mean;
   where order_date between 
	  "&sysdate9"d - 6 and "&sysdate9"d;
   var quantity total_retail_price;
   title "Weekly sales: &sysdate9";
run;

%macro daily;
   proc print data=recent_orders;
      where order_date="&sysdate9"d;
      var product_id total_retail_price;
      title "Daily sales: &sysdate9";
   run;
   title;
%mend daily;

%daily

%macro weekly;
   proc means data=recent_orders n sum mean;
      where order_date between 
	    "&sysdate9"d - 6 and "&sysdate9"d;
      var quantity total_retail_price;
      title "Weekly sales: &sysdate9";
   run;
   title;
%mend weekly;

%weekly

%macro reports;
   %daily
   %if &sysday=Friday %then %weekly;
%mend reports;
%reports

/*The mlogic option*/
%macro reports;
   %daily
   %if &sysday=Friday %then %weekly;
%mend reports;
options mlogic;
%reports
options nomlogic;

/*Method 3:  Store the production SAS programs in external files. 
Copy those files to the input stack with %INCLUDE statements.
The %INCLUDE statement 
Copies SAS statements from an external file to the input stack
Is a global SAS statement
Is not a macro language statement
*/


%let path2=/courses/d649d56dba27fe300/STA5067/SAS Programs;
options macrogen;
%macro reports;
   %include "&path2/daily.sas";
   %if &sysday=Friday %then %do;   
	  %include "&path2/weekly.sas";
   %end;
%mend reports;
%reports
options nomacrogen;

%macro reports;
   %include "&path2/daily.sas" /source2;
   %if &sysday=Friday %then %do;   
	  %include "&path2/weekly.sas" /source2;
   %end;
%mend reports;
%reports

%macro count(type=,start=01jan2016,stop=31dec2016);
   proc freq data=recent_orders;
      where order_date between "&start"d and "&stop"d;
      table quantity;
      title1 "Orders from &start to &stop";
	%if &type=  %then %do;
         title2 "For All Order Types";
      %end;
      %else %do;
         title2 "For Order Type &type Only";
         where same and order_type=&type;
      %end;
   run;
   title;
%mend count;

options mprint mlogic;
%count()
%count(type=3)
options nomprint nomlogic;

%macro cust(place);
  %let place=%upcase(&place);
  data customers;
    set orion.customer;
    %if &place=US %then %do;
	where country='US';
	keep customer_name customer_address country;
    %end;
    %else %do;
       	where country ne 'US';
       	keep customer_name customer_address country location;
	length location $ 12;
	if      country="AU" then location='Australia';
	else if country="CA" then location='Canada';
	else if country="DE" then location='Germany';
	else if country="IL" then location='Israel';
	else if country="TR" then location='Turkey';
	else if country="ZA" then location='South Africa';
    %end;
  run;
%mend cust;

options mprint;
%cust(us)

%cust(international)
proc sql;
select distinct country 
from customers;
quit;
options nomprint;

options mprint;
%macro counts(rows);
    title 'Customer Counts by Gender';
    proc freq data=orion.customer_dim;
    	  tables
    %if &rows ne  %then &rows *;
       customer_gender;
    run;
%mend counts;

%counts()
%counts(customer_age_group)
options nomprint;

/*Parameter Validation*/
/*
Perform parameter validation with the OR operator.
Perform parameter validation with the IN operator.
Perform data-driven parameter validation.
Perform parameter validation with the %INDEX function.
*/
/*Example:  Validate a parameter value before generating SAS code that is based on that value.
*/
%macro customers(place);
   %let place=%upcase(&place);
   %if &place=AU
   or  &place=CA
   or  &place=DE
   or  &place=IL
   or  &place=TR
   or  &place=US
   or  &place=ZA %then %do;
       proc print data=orion.customer;
          var customer_name customer_address country;
          where upcase(country)="&place";
          title "Customers from &place";
       run;
		title;
   %end;
   %else %put Sorry, no customers from &place..;
%mend customers;
%customers(de)
%customers(aa)

/*Use the IN operator for parameter validation*/
%macro customers(place) / minoperator;
   %let place=%upcase(&place);
   %if &place in AU CA DE IL TR US ZA %then %do;       	
         proc print data=orion.customer;
         var customer_name customer_address country;
         where upcase(country)="&place";
         title "Customers from &place";
      run;
   %end;
   %else %put Sorry, no customers from &place..;
%mend customers;

%customers(de)
%customers(aa)

%macro customers(place) / minoperator;
   %let place=%upcase(&place);
   proc sql noprint;
      select distinct country into :list separated by ' '
   		 from orion.customer;
   quit;
   %if &place in &list %then %do;             	
	proc print data=orion.customer;
	   var customer_name customer_address country;
         where upcase(country)="&place";
         title "Customers from &place";
      run;
   %end;
   %else %do;
	  %put Sorry, no customers from &place..;
	  %put Valid countries are: &list..;
   %end;
%mend customers;
%customers(de)
%customers(aa)

/*
Iterative Processing
*/

/*The %INDEX Function
Use the %INDEX function to check the value of a macro variable against a list of valid values
The %INDEX function does the following:
%INDEX(argument1, argument2)
searches argument1 for the first occurrence of argument2
returns an integer representing the position in argument1 of the first character of argument2 if there is an exact match
returns 0 if there is no match
argument1 and argument2 can be the following:
constant text
macro variable references
macro functions
macro calls
*/
%macro customers(place);
   %let place=%upcase(&place);
   proc sql noprint;
      select distinct country into :list separated by '*'
         from orion.customer;
   quit;
   %if %index(*&list*,*&place*) > 0 %then %do;
      proc print data=orion.customer;
	   var customer_name customer_address country;
         where upcase(country)="&place";
         title "Customers from &place";
      run;
   %end;
   %else %do;
	%put Sorry, no customers from &place..;
	%put Valid countries are: &list..;
   %end;
%mend customers;
%customers(de)

data _null_;
   set orion.country end=no_more;
   call symputx('Country'||left(_n_),country_name);
   if no_more then call symputx('numrows',_n_);
run;
proc sql;
select name from dictionary.macros
where scope="GLOBAL";
quit;

data _null_;
   set orion.country end=no_more;
   call symputx('Country'||left(_n_),country_name);
   if no_more then call symputx('numrows',_n_);
run;
proc sql;
select name, value from dictionary.macros
where scope="GLOBAL" and upcase(name) contains "COUNTRY";
quit;

proc sql;
describe table dictionary.macros;
quit;

%macro putloop;
   %do i=1 %to &numrows;
      %put Country&i is &&country&i;
   %end;
%mend putloop;
%putloop

%macro readraw(first=2003,last=2007);
  %do year=&first %to &last;
	 data year&year; 
      set orion.orders&year;
	 run;
  %end;
%mend readraw;	

options mlogic mprint;

%readraw(first=2004,last=2006)
options nomlogic nomprint;

/*Generating Data-Dependent Code
Step 1:  Store unique data values into macro variables*/
%macro split (data=, var=);
  proc sort data=&data(keep=&var) out=values nodupkey;
     by &var;
  run;
  data _null_;
     set values end=last;
     call symputx('site'||left(_n_),&var);
     if last then call symputx('count',_n_);
  run;
  %put _local_;
%mend split;

%split(data=orion.customer, var=country)

/*Step 2:  Use loops to generate the DATA step. */


%macro split (data=, var=);
  proc sort data=&data(keep=&var) out=values nodupkey;
     by &var;
  run;
  data _null_;
     set values end=last;
     call symputx('site'||left(_n_),&var);
     if last then call symputx('count',_n_);
  run;
  data
     %do i=1 %to &count;
        &&site&i
     %end;
  ;
     set &data;
        select(&var);
        %do i=1 %to &count;
           when("&&site&i") output &&site&i;
        %end;
        otherwise;
        end;
  run;
%mend split;
%split(data=orion.customer, var=country)

/*Conditional Iteration
You can perform conditional iteration in macros with %DO %WHILE and %DO %UNTIL statements.
A %DO %WHILE loop:
evaluates expression at the top of the loop before the loop executes
executes repetitively while expression is true

General form of the %DO %UNTIL statement
expression can be any valid macro expression.
A %DO %UNTIL loop does the following:
evaluates expression at the bottom of the loop after the loop executes
executes repetitively until expression is true
executes at least once
*/

%macro stats(datasets);
    %let i=1;
    %let dsn=%scan(&datasets,1);
    %do %while(&dsn ne );
	  title "ORION.%upcase(&dsn)";
        proc means data=orion.&dsn n min mean max;  
	  run;
        %let i=%eval(&i+1);
	  %let dsn=%scan(&datasets,&i);
    %end;
	title;
%mend stats;

%stats(staff supervisors country)

%macro stats(datasets);
   %let i=1;
   %do %until(&dsn= );
      %let dsn=%scan(&datasets,&i);
      %if &dsn= %then %put NOTE: Processing completed.;
      %else %if %sysfunc(exist(orion.&dsn)) %then %do;
	   title "ORION.%upcase(&dsn)";
         proc means data=orion.&dsn n min mean max;
	   run;
      %end;
      %else %put ERROR: No &dsn dataset in ORION library.;
      %let i=%eval(&i+1);
   %end;
%mend stats;

%stats(discount music orders)

/*
Make multiple copies of a dataset
*/

data tmp;
do i=1 to 5;
output;
end;
run;
data tmp1;
set tmp tmp;
proc print data=tmp1 noobs;
run;

%macro mkcopies(reps,newdata,copydata);
  data &newdata;
  set
  %do i=1 %to &reps;
  &copydata 
  %end;
  ;
  run;
%mend mkcopies;

options mprint;
%mkcopies(2,tmp2,tmp);
proc print data=tmp2;
run;
options nomprint;

/*Global and Local Symbol Tables
The difference between global and local symbol tables.

The global symbol table is
Created during SAS initialization
Initialized with automatic macro variables
Deleted at the end of the session

%GLOBAL macro-variable1 macro-variable2 . . . ;
The %GLOBAL statement adds one or more macro variables to the global symbol table with null values.
It has no effect on variables already in the global table.
It can be used anywhere in a SAS program.

Local macro variables can be created within a macro definition:
%LET statement
DATA step SYMPUTX routine
PROC SQL SELECT statement INTO clause
%LOCAL statement

A local symbol table is
Created when a macro with a parameter list is called or a local macro variable is created during macro execution 
Deleted when the macro finishes execution.
Macros that do not create local variables do not have a local table.

The %LOCAL statement adds one or more macro variables to the local symbol table with null values.
It has no effect on variables already in the local table.
It can appear only inside a macro definition.
*/

%macro simple;
proc sql;
select count(*) into :numobs
from fram.frex4
;
quit;
%mend;

%simple
%put &numobs;

