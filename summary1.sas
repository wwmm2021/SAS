proc sql;
	select Job_Title, Salary,
		case scan(Job_Title,-1,' ')
		when 'I' then Salary*.05
		when 'II' then Salary*.07
		when 'III' then Salary*.10
		when 'IV' then Salary*.12
		else Salary*.08
		end as Bonus
	from orion.Staff
	;
quit;

/*The distinct and unique keywords*/
proc sql;
   select distinct  Department
      from orion.Employee_Organization
	;
quit;

/*Although the UNIQUE argument is identical to DISTINCT, it is not an ANSI standard.*/
proc sql;
   select unique department
      from orion.Employee_Organization
	;
quit;

/*Subsetting Rows with the WHERE clause*/
proc sql;
   select Employee_ID, Job_Title, Salary
      from orion.Staff
      where Salary > 112000
	;
quit;

/*A new keyword -- calculated
Because a WHERE clause is evaluated before the SELECT clause, 
columns used in the WHERE clause must exist in the table or 
be derived from existing columns */
proc sql;
   select Employee_ID, Employee_Gender,
        Salary, Salary * .10 as Bonus
      from orion.Employee_Payroll
      where Salary * .10 < 3000
	;
quit;
proc sql;
   select Employee_ID, Employee_Gender,
    Salary, Salary * .10 as Bonus
      from orion.Employee_Payroll
      where calculated Bonus < 3000
	;
quit;

/* IN   where ... in('pa','na')
   CONTAINs where ... contains',N'
   IS NULL or IS MISSING  where... is missing
   sounds like()
   like using % or _  _ 
   (underscore)  a single character% any number of characters
   
   between.. and..
*/

/*
Select only those rows where the employees’ first names begin with N
*/
proc sql;
	select Employee_Name
	from orion.Employee_Addresses(obs=10)
	;
	select Employee_Name, Employee_ID
	from orion.Employee_Addresses
	where Employee_Name contains ', N'
	;
quit;

proc sql;
   select Employee_ID, Job_title
      from orion.Employee_Organization
      where Job_title like 'Security%'
	;
quit;

/*
SUM(argument1<,argument2, ...>) 

If the summary function specifies only one column, 
the statistic is calculated for the column (using values from one or more rows).

If the summary function specifies more than one column, 
the statistic is calculated for the row (using values from the listed columns).

*/

proc sql;
   select Employee_ID 
          label='Employee Identifier',
	     Qtr1,Qtr2,Qtr3,Qtr4,
          sum(Qtr1,Qtr2,Qtr3,Qtr4) 
	     label='Annual Donation' 
	     format=comma9.2
      from orion.Employee_donations
      where Paid_By="Cash or Check"
      order by 6 desc
;
quit;

proc sql;
   select sum(Qtr1) 
          'Total Quarter 1 Donations'
      from orion.Employee_Donations
;
quit;
title;
/*
Summary Functions a comparison with proc means
*/
proc means data=orion.Employee_donations
           sum maxdec=0;
   var Qtr1;
run;

/*
COUNT(*|argument)

can be:
* (asterisk) -- counts all rows

a column name, counts the number of non-missing values in that column

*/

proc sql;
   select count(*) as Count
      from orion.Employee_Payroll
      where Employee_Term_Date is missing
;
quit;

proc sql;
   select 'The Average Salary is:',
          avg(Salary)
      from orion.Employee_Payroll
      where Employee_Term_Date is missing
;
     select 'The Mean Salary is:',
          mean(Salary)
      from orion.Employee_Payroll
      where Employee_Term_Date is missing
;
quit;
title;

/*
Remerging in SQL
*/

proc sql;
select *
from orion.employee_payroll
;
quit;


proc means data=orion.employee_payroll noprint;
where employee_term_date=.;
var salary;
output out=avgsal mean=avgsalary;
run;

data report;
retain avgsalary;
if _n_=1 then set avgsal;
set orion.employee_payroll ;
where employee_term_date=.;
run;

proc print data=report;
var employee_id employee_gender avgsalary;
run;

/*
Remerging in SQL
*/

proc sql;
   select Employee_id "Employee ID",Employee_Gender as Gender,
	 				salary format=dollar12.2,
          avg(Salary) format=dollar12.2 as Average 
      from orion.Employee_Payroll
      where Employee_Term_Date is missing
;
quit;

/*
Noremerge option (a system option nosqlremerge also exists)
*/

proc sql noremerge;
   select Employee_Gender,
          avg(Salary) as Average
      from orion.Employee_Payroll
      where Employee_Term_Date is missing
;
quit;

/*
Use the GROUP BY clause to:
Classify the data into groups based on the values of one or more columns

Calculate statistics for each unique value of the grouping columns
*/
proc sql;
   select Employee_Gender,
          avg(Salary) as Average
      from orion.Employee_Payroll
      where Employee_Term_Date is missing
      group by Employee_Gender
;
quit;

/*
he WHERE clause is processed before a GROUP BY clause and 
determines which individual rows are available for grouping.


The HAVING clause is processed after the GROUP BY clause and 
determines which groups will be displayed.
*/
proc sql;
title "Male Employee Salaries";
   select Employee_ID, Salary format=comma12.,
          Salary / sum(Salary) 
          format=percent6.2
      from orion.Employee_Payroll
      where Employee_Gender="M"
            and Employee_Term_Date is missing
      order by 3 desc
;
quit;
title;

/*
Selecting Groups with the HAVING Clause -- Display the names of the departments 
and the number of employees for departments with 25 or more employees
*/

proc sql;
   select Department, count(*) as Count
      from orion.Employee_Organization
	 group by Department
	 having Count ge 25
	 order by Count desc
;
quit;

/*
FIND(string, substring<,modifier(s)><,startpos>)
*/
data one;
	job_title="Administration Manager";
	x=find(Job_Title,"manager","i");
run;
proc print data=one;run;

data one;
   job_title="Administration Manager";
   x=find(Job_Title,"manager");
run;
proc print data=one;run;

proc sql ;
   select Department,Job_Title,
          (find(Job_Title,"manager","i") >0)
          "Manager" 
      from orion.Employee_Organization
;
quit;

proc sql;
title "Manager to Employee Ratios";
   select Department,
          sum((find(Job_Title,"manager","i") >0))
            as Managers,
          sum((find(Job_Title,"manager","i") =0))
            as Employees,
          calculated Employees/calculated Managers
          "E/M Ratio" format=8.3
      from orion.Employee_Organization
      group by Department
;
quit;

%let reps=10000;
%let obs=25;
data normalmean;
call streaminit(1768315);
do reps=1 to &reps;
  do obs=1 to &obs;
    sales=round(rand("normal",250,40),.01);
    output;
  end;
end;
run;

proc sql;
	create table means as
	select mean(sales)as mnreps
	from normalmean
	group by reps;
quit;

ods select histogram;
proc univariate data=means;
var mnreps;
histogram mnreps/normal;
title "&reps Replications of normal mean";
title2 "From a sample of size &obs";
run;
title;

/*
Subqueries
*/
/*A query corresponds to a single SELECT statement within a PROC SQL step.

A subquery is a query (SELECT statement) that resides within an outer query (the main SELECT statement). 
The subquery must be resolved before the main query can be resolved.

Return values to be used in the outer query’s  WHERE or HAVING clause

Can return single or multiple rows

Must return only a single column.


*/
proc sql;
select * 
   from orion.Staff
;
select avg(Salary) as MeanSalary
   from orion.Staff
;
select Job_Title, avg(Salary) as MeanSalary
   from orion.Staff
   group by Job_Title
   having avg(Salary) > 38041.51
;
quit;

/*
Noncorrelated subquery
*/

proc sql;
   select Employee_ID, 
          Employee_Name, City, 
          Country 
      from orion.Employee_Addresses
      where Employee_ID in
        (select Employee_ID
            from orion.Employee_Payroll
            where month(Birth_Date)=2)
      order by 1
;
quit;

/*single-value non correlated subquery*/
proc sql;
	select jobcode,
	avg(salary) as AvgSalary
	format=dollar11.2
	from train.payrollmaster
	group by jobcode
	having avg(salary) >
	(select avg(salary) from
	   train.payrollmaster)
;
quit;

/*
The ANY keyword with subqueries that return multiple values

List employee id, job code, 
and date of birth for level 1 or 2 flight attendants 
who are older than any level 3 flight attendants
*/

/* any keyword*/
proc sql;
	select empid,jobcode,dateofbirth
	from train.payrollmaster
	where jobcode in ("FA1","FA2")
	 and dateofbirth < any
	 (select dateofbirth
	  from train.payrollmaster
	  where jobcode="FA3")
;
quit;


/*
The ALL keyword

List employee id, jobcode, and date of birth for level 1 or level 2 flight attendants 
who are older than all level 3 flight attendants
*/

/* all keyword*/
proc sql;
	select empid,jobcode,dateofbirth
	from train.payrollmaster
	where jobcode in ("FA1","FA2")
	 and dateofbirth < all
	 (select dateofbirth
	  from train.payrollmaster
	  where jobcode="FA3")
;
quit;

/* scan()
Use the SCAN() function to separate first and last names then concatenate the pieces into First, Last order.

CATX(delimiter,argument-1,argument-2<, ...argument-n>)

delimiter	a character string that is used as a delimiter between concatenated arguments. 
argument	a character variable’s name, a character constant, or an expression yielding a character value.
*/
proc sql;  
   create table work.Supervisors as 
      select distinct Manager_Id as Employee_Id, 
             upcase(Country) as Country
         from orion.Employee_Addresses as e, 
              orion.Staff as s
         where e.Employee_Id=s.Manager_Id
           and e.employee_id in 
              (120103,120104,120260,120262,120668,120672,120679,120735,
               120736,120780,120782,120798,120800,121141,121143)
;
quit;
proc print data=supervisors;run;

proc sql;
  select Employee_ID,
         catx(' ',scan(Employee_Name,2),scan(Employee_Name,1)) as Manager_Name length=25
     from orion.Employee_Addresses
     where 'AU'=
       (select Country
           from Work.Supervisors
           where Employee_Addresses.Employee_ID=
								Supervisors.Employee_ID) ;
quit;

/*
The EXISTS and NOT EXISTS Condition

The EXISTS condition tests for the existence of a set of values returned by the subquery.

The EXISTS condition is true if the subquery returns at least one row.

The NOT EXISTS condition is true if the subquery returns no data.
*/
proc sql;
   select Employee_ID, Job_Title
      from orion.Sales 
	 where not exists
	   (select *
            from orion.Order_Fact
            where Sales.Employee_ID=Order_Fact.Employee_ID);
quit;

/*Match-Merge in the Data Step*/
/*
Match-Merging involves combining observations from two or more SAS data sets 
into a single observation in a new SAS data set.
*/
data htwt;
length id 8;
input height weight id @@;
datalines;
56.50 98  1  62.25 145 2  62.50 128 3 64.75 119 4 
68.75 144 5 60.00 117 6  58.00 125 7 
;
run;

data chol;
length id 8;
input chol id @@;
datalines;
234 1  172 2  248 3  215 4 
145 5  281 6  335 7 
;
run;

proc print data=htwt noobs;
run;

proc print data=chol noobs;
run;

data tot1;
  merge htwt chol;
	by id;
run;
proc print data=tot1 noobs;run;

/*Match-Merge Different Number of Rows*/
/* Output controlled with In option */
data htwt;
input height weight id @@;
datalines;
56.50 98 1 62.25 145 2 62.50 128 3 
64.75 119 4 68.75 144 5 60.00 117 6 
63.00 156 9 63.00 134 10 
;
run;

data chol;
input chol id @@;
datalines;
215 1 145 2 281 3 335 4 196 7 
;
run;

proc print data=htwt noobs;
run;

proc print data=chol noobs;
run;

data tot4;
merge htwt(in=h) chol(in=c);
by id;
run;
proc print data=tot4 noobs;
run;
/* wrong to merge "forgetten 'by' " */
data tot3;
merge htwt chol;
run;
proc print data=tottmp;
run;

/* if condition */
data tot5;
merge htwt(in=h) chol(in=c);
by id;
if h;
run;
proc print data=tot5 noobs;
run;

data tot6;
merge htwt(in=h) chol(in=c);
by id;
if c;
run;
proc print data=tot6 noobs;
run;

data tot7;
merge htwt(in=h) chol(in=c);
by id;
if h and c;
run;
proc print data=tot7 noobs;
run;



