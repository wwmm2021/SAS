%let path=/courses/d649d56dba27fe300/STA5067/SAS Data;
libname orion "&path/orion";

/*Setting SQL Procedure Options*/

/*
PROC SQL options give you finer control over your SQL processes:

Syntax checking without executing your code

Expanding SQL statements to their fully-qualified values

Restricting the number of rows processed

Providing system utilization statistics for query tuning
*/
proc sql number outobs=10;
title "Top 10 Employee's 2007 Charitable Donations";
   select Employee_Name, Sum(Qtr1,Qtr2, Qtr3,Qtr4) as Donation_Total
      from orion.Employee_Addresses as a,
           orion.Employee_donations as d
	   where a.Employee_ID=d.Employee_ID
	   order by Donation_Total desc, Employee_Name
;
reset nonumber outobs=9;
title "Top 9 Employee's 2007 Charitable Donations";
   select Employee_Name, Sum(Qtr1,Qtr2, Qtr3,Qtr4) as Donation_Total
      from orion.Employee_Addresses as a,
           orion.Employee_donations as d
	  where a.Employee_ID=d.Employee_ID
	  order by Donation_Total desc, Employee_Name
;
quit;
title;
/*
The SAS Macro Language Overview

The SAS macro language 
Is a programmable system for producing text
Uses syntax similar to Base SAS

# Macro Variables

SAS macro variables are stored in an area of memory referred to as the global symbol table. 
SAS uses automatic macro variables to “remember” important information about the SAS session.
 Macro variables in SAS are classified as either automatic (created and updated by SAS) or user-defined.
When SAS is invoked, 
the global symbol table is created and several automatic macro variables values are initialized by SAS. 
*/

%put _automatic_;

data tmp;
set orion.sales;
run;

%put &syslast;
/*
Executing a PROC SQL statement automatically creates and populates the following user-defined (global scope) macro variable values:
SQLOBS	records the number of rows (observations) that 	are output or deleted by the SQL statement.
SQLRC	contains the return code from each SQL 		statement, which can be decoded as follows:

 Value   |       Meaning
 0       | The statement completed successfully with no errors.
 4       | A warning was issued, but execution continued.
 > 4     | An error that stopped execution was encountered
 */
proc sql;
	select count(*) 
	from orion.sales
	;
%put sqlobs:  &sqlobs;
%put sqlrc:  &sqlrc;
quit;

proc sql;
	select count(*), 
	from orion.sales
	;
%put sqlobs:  &sqlobs;
%put sqlrc:  &sqlrc;
quit;

/*User-Defined Macro Variables

    %LET variable = value;
Quotation marks included in value are treated as normal text, 
and become part of the text stored in the macro variable. */

%let bigsalary=5000000;

%put The value of bigsalary is &bigsalary;

/*
PROC SQL creates or updates macro variables using an INTO clause. 

The INTO clause has three syntaxes, and each produces a different result.

SELECT column-1<, …column-n>	
	INTO :macvar_1<, ... :macvar_n> 
	FROM table|view …
*/
proc sql noprint;
   select avg(Salary)
      into :MeanSalary
      from orion.Employee_payroll;
%put The average salary is &MeanSalary;
quit;

%let Dept=Sales;
proc sql noprint;
   select avg(Salary) 
      into :MeanSalary
      from orion.Employee_payroll as p,
           orion.Employee_Organization as o
      where p.Employee_ID=o.Employee_ID
            and Department=propcase("&Dept")
;
reset print number;
title "&Dept Department Employees Earning";
title2 "More Than The Department Average "
       "Of &meansalary";
select p.Employee_ID, Salary
   from orion.Employee_payroll as p,
        orion.Employee_Organization as o
   where p.Employee_ID=O.Employee_ID
     and Department=Propcase("&Dept")
     and Salary > &meansalary
;
quit;
title;

proc sql;
   select substr(put(Customer_Type_ID,4.),1,1)
          as Tier, count(*)
      from orion.Customer
      group by Tier;
%let Rows=&SQLOBS;
reset noprint;
   select substr(put(Customer_Type_ID,4.),1,1) 
          as Tier, count(*)
      into :Tier1-:Tier&Rows,:Count1-:Count&Rows
      from orion.Customer
      group by Tier;
%put NOTE: Tier1 is &tier1  Count1 is: &count1;
%put NOTE: Tier2 is &tier2  Count2 is: &count2;
%put NOTE: Tier3 is &tier3  Count3 is: &count3;
quit;

proc sql;
   create table Payroll as
      select Employee_ID, Employee_Gender, Salary,
             Birth_Date format=date9.,   
             Employee_Hire_Date as Hire_Date 
             format=date9., 
             Employee_Term_Date as Term_Date 
             format=date9. 
        from orion.Employee_Payroll
        order by Employee_ID;
quit;



proc sql noprint;
select Name
   into :Column_Names separated by ","
   from Dictionary.Columns
   where libname ="WORK"
   and memname="PAYROLL"
   and upcase(Name) like '%DATE%';
%put  &Column_Names;
reset print;
title "Dates of Interest by Employee_ID";
select Employee_ID, &Column_Names
   from work.Payroll
   order by Employee_ID;
quit;


%put This text was output:  &systime &sysday &sysdate9 ;
%put The last dataset created was:  &syslast;

/*with macro variables*/
/*When using macro variables inside quotes you must use double quotes!*/

proc freq data=orion.Customer;
   table Country / nocum;
   footnote1 'Created &systime &sysday, &sysdate9';
   footnote2 'By user &sysuserid ';
run;

footnote;

proc freq data=orion.Customer;
   table Country / nocum;
   footnote1 "Created &systime &sysday, &sysdate9";
   footnote2 "By user &sysuserid";
run;

footnote;

/*Writing a simple macro (with parameters)*/
%macro impdat(datanm);
filename iris "/courses/d649d56dba27fe300/Data Sets/&datanm..csv";
PROC IMPORT OUT=&datanm 
    DATAFILE=iris
	DBMS=CSV
	replace;
	GETNAMES=No;
	
RUN;
%mend;
/*Call the macro*/
%impdat(IrisDataNoHeaderCsv)
/*
Developing macro applicatons often involves several steps.

1.Write and debug the SAS program without macro coding.
2.Generalize the program by replacing hardcoded values with macro variable references.
3.Create a macro definition with macro parameters.
4.Add macro-level programming for conditional and iterative processing.
5.Add data-driven customization.
*/
%let name= Ed Norton ; 
%put The value of the macro variable name is:  &name;
%let name2=' Ed Norton ';
%put name2 is &name2;
%let title="Joan's Report";
%put quotes are included in the saved text, title is  &title;
%let start=;
%put Macro variable may be assigned a null value:  &start;
%let sum=3+4;
%put Macro variables contain text, including numbers, no arithmetic is done. Sum is &sum;
%let total=0;
%let total=&total+&sum;
%put When macro variable definition included macro variables;
%put The included macro variables are "resolved" and then the definition is made;
%put total is now:  &total;

%let x = varlist;

%let &x = name age height;
%put The macro variable being defined can be a macro variable.  Still the resolution is done first.;

/*The user keyword with %put lists all user-defined macro variables*/
%put _user_;
/*The SYMBOLGEN system option writes macro variable values to the SAS log
(NOSYMBOLGEN is default)
*/
Options symbolgen;
%let office=Sydney;
Proc print data=orion.employee_addresses;
Where city="&office";
Var employee_name;
Title "&office Employees";
Run;

/*The %SYMDEL statement deletes one or more user-defined macro variables from the global symbol table.*/
%let x1=First macro text;
%let x2=Second macro text;
%put &x1 &x2;

%symdel x1 x2;
%put &x1 &x2;

title1 "%sysfunc(today(),weekdate.)";
title2 "%sysfunc(time(),timeAMPM8.)";
data orders;
   set orion.Order_fact;
   where year(Order_Date)=2007;
   Lag=Delivery_Date - Order_Date;
run;
proc means data=orders maxdec=2 min max mean;
   class Order_Type;
   var Lag;
run;
title;

%let dietvars=PROTEIN   FAT TOTAL_CARBOHYDRATE Alcohol   CALCIUM PHOSPHORUS IRON SODIUM
 POTASSIUM SATURATED_FAT OLEIC_ACID      LINOLEIC_ACID CHOLESTEROL;
%put &dietvars;
%let varlist=%sysfunc(compbl(&dietvars));
%put &varlist;
%let varlist=%sysfunc(translate(&varlist,","," "));
%put &varlist;

/* %NRSTR -- quotes special characters, including macro triggers.*/

%let statement=%str(title "S&P 500";);
%put &statement;
%let statement=%nrstr(title "S&P 500";);
%put &statement;

/*A macro often generates SAS code*/
%macro calc;
   proc means data=orion.order_fact &stats;
	 var &vars;
   run;
%mend calc;
/*Call the CALC macro. Precede the call with %LET statements that create the macro variables referenced within the macro.*/
%let stats=min max;
%let vars=quantity;
%calc

/*Define and call macros with parameters.

The difference between positional parameters and keyword parameters.
*/
%let stats=min max;
%let vars=quantity;
%calc

%let stats=n mean;
%let vars=discount;
%calc

/*
Macro Parameters
*/
%macro calc(stats,vars);
   proc means data=orion.order_fact &stats;
	 var &vars;
   run;
%mend calc;

%calc(min max,quantity)

/*Local Symbol Tables
When a macro with a parameter list is called, 
the parameters are created in a separate local symbol table

A local symbol table is
Created when a macro with a parameter list is called
Deleted when the macro finishes execution.

Macro variables in the local table are available only during macro execution and can be referenced only within the macro.

*/
%macro count(opts, start, stop);
   proc freq data=orion.order_fact;
      where order_date between 
	       "&start"d and "&stop"d;
      table order_type / &opts;
      title1 "Orders from &start to &stop";
   run;
%mend count;
options mprint;
%count(nocum,01jan2004,31dec2004)
%count(,01jul2004,31dec2004)
title;

/*Keyword Parameters
Keyword parameters are assigned a default value after an equal (=) sign*/
%macro count(opts=,start=01jan04,stop=31dec04);
   proc freq data=orion.order_fact;
      where order_date between 
	       "&start"d and "&stop"d;
      table order_type / &opts;
      title1 "Orders from &start to &stop";
   run;
%mend count;
options mprint;
%count(opts=nocum)
%count(stop=01jul04,opts=nocum nopercent)
%count()
title;

/*Creating Macro Variables in the DATA Step*/

%let month=2;
%let year=2007;

data orders;
   keep order_date order_type quantity total_retail_price;
   set orion.order_fact end=final;
   where year(order_date)=&year and month(order_date)=&month;
   if order_type=3 then Number+1;
   if final then do;
      put Number=;
      if Number=0 then do;
         %let foot=No Internet Orders;
      	  end;
      else do;
         %let foot=Some Internet Orders;
      	  end;
      end;
run;

proc print data=orders;
   title "Orders for &month-&year";
   footnote "&foot";
run;

/*The SYMPUTX Routine
CALL SYMPUTX(macro-variable, text);
The SYMPUTX routine is an executable DATA step statement
macro-variable is assigned the character value of text.
If macro-variable already exists, its value is replaced.
Literal values in either argument must be enclosed in quotation marks
*/
%let month=2;
%let year=2007;

data orders;
   keep order_date order_type quantity total_retail_price;
   set orion.order_fact end=final;
   where year(order_date)=&year and month(order_date)=&month;
   if order_type=3 then Number+1;
   if final then do;
      put Number=;
      if Number=0 then do;
         call symputx('foot', 'No Internet Orders');
      end;
      else do;
         call symputx('foot', 'Some Internet Orders');
      end;
   end;
run;
proc print data=orders;
   title "Orders for &month-&year";
   footnote "&foot";
run;

%let month=1;
%let year=2007;

data orders; 
   keep order_date order_type quantity total_retail_price;
   set orion.order_fact end=final;
   where year(order_date)=&year and month(order_date)=&month;
   if order_type=3 then Number+1;
   if final then call symputx('num', Number);
run;

proc print data=orders;
   title "Orders for &month-&year";
   footnote "&num Internet Orders";
run;

%let month=1;
%let year=2007;

data orders (drop=last_order); 
   retain last_order 0;
   keep order_date order_type quantity total_retail_price;
   set orion.order_fact end=final;
   where year(order_date)=&year and month(order_date)=&month;
   if order_type=3 then do;
		Number+1;
		sumprice+total_retail_price;
		if order_date>last_order then last_order=order_date;
	end;
   if final then do;
	 call symputx('num', Number);
	 call symputx('avg',put(sumprice/number,dollar8.));
	 call symputx("last",put(last_order,mmddyy8.));
   end;
run;

proc print data=orders;
   title "Orders for &month-&year";
   footnote "&num Internet Orders";
   footnote2 "Average Internet Order: &avg";
   footnote3 "Last Internet Order: &last";
run;
title;footnote;

/*Passing Values between Steps */
%let start=01Jan2007;
%let stop=31Dec2007;
proc means data=orion.order_fact noprint;
   where order_date between "&start"d and "&stop"d;
   var total_retail_price;
   output out=stats n=count mean=avg;
   run;
data _null_;
   set stats;
   call symputx('Num_orders',count);
   call symputx('Avg_order',avg);
run;
%put Number of orders: &num_orders;
%put Average order price: &avg_order;

/*Indirect References to Macro Variables*/
%let custID=9;

data _null_;
   set orion.customer;
   where customer_ID=&custID;
   call symputx('name', Customer_Name);
run;

proc print data=orion.order_fact;
   where customer_ID=&custID;
   var order_date order_type quantity total_retail_price;
   title1 "Customer Number: &custID";
   title2 "Customer Name: &name";
run;

/*Creating a Series of Macro Variables 
CALL SYMPUTX(expression1,expression2);
expression1	evaluates to a character value that is a valid 
	        macro variable name, unique to each execution of the routine.

expression2  	is the value to assign to each macro variable.
*/
data _null_;
   set orion.customer;
   call symputx('name'||left(Customer_ID),customer_Name);
run;

%put _user_;

%let custID=9;
proc print data=orion.order_fact;
   where customer_ID=&custID;
   var order_date order_type quantity total_retail_price;
   title1 "Customer Number: &custID";
   title2 "Customer Name: &name9";
run;

/*The Forward Rescan Rule
Multiple ampersands preceding a name token denote an indirect reference.
The macro processor will rescan an indirect reference, left to right, from the point where multiple ampersands begin.  
Two ampersands (&&) resolve to one ampersand (&).
Scanning continues until no more references can be resolved.
*/
%let custID=9;
proc print data=orion.order_fact;
   where customer_ID=&custID;
   var order_date order_type quantity total_retail_price;
   title1 "Customer Number: &custID";
   title2 "Customer Name: &&name&custID";
run;
title;

/*Retrieving Macro Variables in the DATA Step
*/

data _null_;
   set orion.customer;
   call symputx('name'||left(Customer_ID), 
		     customer_Name);
run;

%put _user_;

data InternetCustomers;
   keep order_date customer_ID customer_name;
   set orion.order_fact;
   if order_type=3;
   length Customer_Name $ 20;
   Customer_Name=symget('name'||left(customer_ID));                     
run;

proc print data=InternetCustomers;
   var order_date customer_ID customer_name;
   title "Internet Customers";
run;


title 'Top 2007 Sales';
proc sql outobs=3 double;
   select total_retail_price, order_date format=mmddyy10.
     	into :price1-:price3, :date1-:date3
	from orion.order_fact
	where year(order_date)=2007
	order by total_retail_price desc;
quit;
title;
%put Top 3 sales amounts: #1: &price1 #2: &price2 #3: &price3;
%put Top 3 sales dates: #1: &date1 #2: &date2 #3: &date3;

proc sql noprint;
   select distinct country into :countries 
      separated by ', '
      from orion.customer;
quit;
%put Customer Countries: &Countries;

proc sql;
   select name, value
      from dictionary.macros
      where scope='GLOBAL'
	 order by name;
quit;

proc sql noprint;
   select name into: vars separated by ' '
	 from dictionary.macros
	 where scope='GLOBAL';
quit;
%put &vars;

%macro deletemymacvars;

   proc sql noprint;
	select name into: vars separated by ' '
	   from dictionary.macros
	   where scope='GLOBAL';
   quit;

   %symdel &vars;

%mend deletemymacvars;

%deletemymacvars
/**/
proc sql;
   select name
   from dictionary.macros
   where scope="GLOBAL";
quit;














