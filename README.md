![Easy Pivot](img/easy_pivot.jpg)

# Introduction

Easy Pivot is an open-source SQL pivot compiler that dramatically
simplifies the creation of complex dynamic pivot queries.

Rather than manually writing tedious SQL pivot syntax, Easy Pivot
generates the required SQL for you from a simple JSON configuration.

The project was originally developed for Microsoft SQL Server and has
since evolved into a cross-platform solution supporting multiple
database engines while preserving a consistent user experience across
all implementations.

Easy Pivot currently supports:

    * Microsoft SQL Server
    * Oracle Database
    * PostgreSQL
    * MySQL (Public release scheduled for tomorrow)

Choose the folder corresponding to your target database platform:

    sql_server/
    oracle/
    postgresql/
    mysql/

Each implementation contains:

    * Database-specific Easy Pivot source code
    * Installation instructions
    * Documentation
    * Frequently Asked Questions
    * Example configurations

# Easy Pivot in 2026

Easy Pivot was originally published on GitHub in 2021.

Since then, the project has undergone continuous refinement,
adding numerous usability improvements, compatibility fixes,
new pivot capabilities, and support for additional database
platforms.

The MySQL port has now been completed and is scheduled for
public release tomorrow.

The successful MySQL port has also demonstrated that
Easy Pivot can be deployed as a shared stored procedure while
maintaining the flexibility and transparency that have always
been central to the project.

The results have been overwhelmingly positive.

Because of that experience, future versions of the SQL Server,
Oracle, and PostgreSQL implementations are expected to receive
the same stored procedure deployment option.

Users will continue to have the choice of either:

* Executing Easy Pivot directly to produce a finished pivot.
* Generating SQL source code for inspection, customization,
  debugging, education, or scheduled jobs.

The goal is not to replace either workflow, but to provide the
most convenient experience for every type of user.

# Future Directions

One of the guiding principles of Easy Pivot has always been to
make SQL pivoting progressively easier.

The original project eliminated the need to manually write
complex pivot queries.

The next evolution is shared stored procedure deployment,
allowing Easy Pivot to be installed once and reused throughout
an organization from a single maintained code base.

Beyond that, the long-term vision is an Easy Pivot Workbench.

Rather than editing JSON by hand, users would visually select
their grouping fields, pivot fields, aggregate options, and
sorting preferences through a graphical interface while Easy
Pivot automatically generates and executes the required SQL,
returning the results in a data grid. Users may then export
the data in the format of their choice.

At present, there appears to be little commercial interest in
providing a database-independent SQL pivot compiler with this
level of flexibility. Easy Pivot is intended to help fill that
gap by providing an open, database-focused solution for
developers, analysts, and database professionals.

Additional database backends currently under investigation
include SQLite and MariaDB.

# Features

With Easy Pivot, you can:

* Dynamically pivot fields, resulting in any number of pivoted columns
* Perform aggregate or Boolean pivots (Yes/No, True/False, Present/Absent,
  or any values you choose)
* Use any aggregate function supported by the target database platform
* Automatically remove NULLs that normally result from pivoting
* Choose any number of fields to pivot on
* Choose any number of fields to group on while pivoting
* Position the pivoted columns between grouping fields
* Reverse the sort order of left-to-right pivoted column names
* Specify ascending ("ASC") or descending ("DESC") group sorting
* Deploy Easy Pivot as a shared stored procedure (where supported)
* Generate SQL source code or execute pivots directly

All the work is done for you, except for a small amount of
configuration required to specify a data source and what field(s)
to group and pivot on.

The data source requirements depend on the target
database platform.

SQL Server currently uses a local temporary table
populated by your query.

Oracle, PostgreSQL, and MySQL execute directly against
the user query supplied in the USER AREA.

Beginning with the MySQL implementation, Easy Pivot also
supports installation as a shared stored procedure,
greatly simplifying deployment within production
environments.

Future versions of the SQL Server, Oracle, and PostgreSQL
implementations are expected to receive the same deployment
option.

You may also tell Easy Pivot to output the pivot code it builds for
your personal study or use in other SQL work.

If the complete code does not appear in the Messages tab of
SQL Server's output window, you can use the Results tab
instead. The code there will be in a single line, but you can
use an SQL formatter program or website to format it into
multiple lines. However, it is possible that the SQL formatter
may not format it correctly. In that case, SQL Server
Management Studio should give you a clue where the error is
so that it can be corrected. It will probably have something
to do with spacing inside bracketed alias names for fields.

Note: PostgreSQL users should execute the Easy Pivot generator
as a script (F5 in pgAdmin). The generated pivot query itself
may then be executed as ordinary SQL.

You cannot directly schedule an Easy Pivot job. Easy Pivot
uses dynamic query execution which is not compatible with
job scheduling.

You can, however, tell Easy Pivot to generate the pivot
query source code and replace the Easy Pivot code with it
for a scheduled job.

When Easy Pivot is used in source-code generation mode
("DECLARE @generate_source_code_only AS BIT = 1" in the
SQL Server version), the generated SQL contains a fixed
list of pivot values discovered at generation time.

If new pivot values appear later in the source data,
those values will not automatically appear in scheduled
job reports using previously generated static SQL.

To incorporate new pivot values:

1. Run Easy Pivot again against current source data.
2. Generate updated source code.
3. Replace the scheduled query with the newly generated version.

For questions or comments, send email to:

tds67 (at) protonmail.com