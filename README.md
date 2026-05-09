![Easy Pivot](img/easy_pivot.png)
# Introduction

This is the home of "Easy Pivot", which is SQL code you can easily
add on to the end of your query project to dynamically pivot data.

Currently, it only works with Microsoft SQL Server databases.

# Features

With Easy Pivot, you can:

* Dynamically pivot fields, resulting in any number of pivoted columns
* Perform one- or two-field pivots
* Use various pivot aggregate functions (COUNT, SUM, AVG, MIN, MAX, STDEV)
* Automatically remove NULLs that normally result from pivoting
* Customize values for pivoted data, such as Yes/No, True/False, etc.
* Choose any number of fields to pivot on
* Choose any number of fields to group on while pivoting
* Position the pivoted columns between grouping fields
* Reverse the sort order of the pivoted columns

All the work is done for you, except for a small amount of
configuration required to specify a data source and what field(s)
to group and pivot on. The data source is a local temporary table
in which you have collected your pre-pivoted data. You may also
tell Easy Pivot to output the pivot code it builds for your
personal study or use in other SQL work. If the complete code does
not appear in the Messages tab of the output window, you can use
the Results tab instead. The code there will be in a single line, but
you can use an SQL formatter program or website to format it into
multiple lines. However, it is possible that the SQL formatter
may not format it correctly. In that case, SQL Server Management
Studio should give you a clue where the error is so that it can
be corrected. It will probably have something to do with spacing
inside bracketed alias names for fields.

2025-07-30: Added a "Discussions" area for comments and feedback.

2026-05-09: Added complete pivot query to the Results tab when generating source code only.
