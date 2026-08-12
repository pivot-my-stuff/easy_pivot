<p align="center">
  <img src="img/easy_pivot_workbench_demo_1.jpg">
</p>

<p align="center">
  <img src="img/easy_pivot_workbench_demo_2.jpg">
</p>

<p align="center">
  <img src="img/easy_pivot_workbench_demo_3.jpg">
</p>

<p align="center">
  <img src="img/easy_pivot_workbench_demo_4.jpg">
</p>

<p align="center">
  <img src="img/easy_pivot_workbench_demo_5.jpg">
</p>

### If you would like to donate to the Easy Pivot Workbench project, you can donate here:

https://github.com/pivot-my-stuff

I won't nag you for donations. But your support REALLY helps. :) I want you to pivot in
pride with a good graphical interface. Something stylish that only donations can help
bring into existense.

Nah, on second thought, who am I kidding? I would do this just for the fun of it, anyway.
So forget about the donations. I'll take care of it myself. :)

"I see you no longer want donations because you would do this for the fun of it anyway.
Would you like donations instead?" -- Pivoty, valued member of the Easy Pivot support
team.

### August 12, 2026 --- Easy Pivot Workbench Installation Instructions

The **Easy Pivot Workbench** provides both standalone and web-based
access to Easy Pivot.

Installation instructions, configuration details, and information about
running the Workbench are available in the documentation included in
the:

`easy_pivot_workbench`

folder.

For MySQL users, the installation documentation includes instructions
for installing the Easy Pivot stored procedure and configuring the
Workbench.

For Oracle, PostgreSQL and SQL Server users: do not feel left out. Your
support is coming soon. We here at the Easy Pivot project are using the
MySQL users as human guinea pigs for development poirposes. But don't
tell them that or they might get mad at us for calling them guinea pigs.
And human. :)

And for SQLite and MariaDB users: we see you out there. Give us time.

### August 11, 2026 --- Remote Database Connections and Connection Diagnostics

Today's testing confirmed that the Easy Pivot Workbench does not have to
run on the same computer as the database server.

A Workbench connection identifies its database target using:

-   Host
-   Port
-   Database
-   User name
-   Password

For example:

``` text
CRYPTID:3306/baan
```

The database name does not have to be `easy_pivot`. The Easy Pivot
stored procedure is installed at the database level, so it can be
installed in an existing application database such as `baan`.

The Workbench can therefore be hosted on one computer and connect to a
database server on another computer, provided the database server,
network, firewall, authentication, and permissions allow the connection.

The **Test Connection** function now reports:

-   Connection success or failure
-   MySQL server version
-   Whether the Easy Pivot stored procedure exists in the selected
    database

This makes it possible to distinguish a database connectivity problem
from a missing Easy Pivot stored procedure.

# Easy Pivot Workbench

**Easy Pivot Workbench is officially no longer vaporware.** 😄 After a
tremendous amount of development and testing, the project has evolved
from a collection of SQL-generation code into a complete, polished
interactive workbench. Users can enter a source query, configure groups
and pivot chips through the interface, generate the resulting pivot SQL,
and execute that SQL against the database. The workbench now includes
dynamic configuration, validation, editing and deletion, NULL handling,
multiple aggregation types, follows relationships, sorting, automatic
source-query parsing, and a redesigned visual interface featuring the
new Pivoty office and chalkboard-style SQL workspace.

The next step is **beta release**. We expect to make Easy Pivot
Workbench available as beta software within the next day or two.
Although the application is already remarkably mature, we want real
users to put it through its paces before calling it production-ready.
**Feedback, bug reports, usability observations, and suggestions are
very welcome.** We've deliberately spent considerable time testing
unusual combinations and trying to break the application ourselves, but
there's nothing quite like having other people approach a tool with
completely different ideas about how it should be used. If you've ever
wished that constructing complicated pivot queries could be easier, we'd
love for you to give Easy Pivot a try and tell us what you think.

## Current Features

-   Visual Group editor
-   Visual Pivot Chip editor
-   Automatic JSON generation
-   Built-in validation
-   Dynamic SQL pivot code generation
-   Local PHP application server (using PHP's built-in development
    server)
-   Direct integration with the Easy Pivot stored procedure

## Current Platform

Easy Pivot Workbench is currently under active development and tested
on:

-   Microsoft Windows
-   PHP 8.x
-   MySQL

## Planned Platforms

Future releases are planned for:

-   Linux
-   macOS

## Future Database Support

Easy Pivot Workbench is being designed as a common graphical interface
for every Easy Pivot implementation. Planned database support includes:

-   SQL Server
-   PostgreSQL
-   Oracle

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
    * MySQL

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

Since then, the project has undergone continuous refinement, adding
numerous usability improvements, compatibility fixes, new pivot
capabilities, and support for additional database platforms.

The successful MySQL has also demonstrated that Easy Pivot can be
deployed as a shared stored procedure while maintaining the flexibility
and transparency that have always been central to the project.

The results have been overwhelmingly positive.

Because of that experience, future versions of the SQL Server, Oracle,
and PostgreSQL implementations are expected to receive the same stored
procedure deployment option.

Users will continue to have the choice of either:

-   Executing Easy Pivot directly to produce a finished pivot.
-   Generating SQL source code for inspection, customization, debugging,
    education, or scheduled jobs.

The goal is not to replace either workflow, but to provide the most
convenient experience for every type of user.

# Easy Pivot Workbench and Potential Job Scheduling

The Easy Pivot Workbench is now the browser-based graphical interface for
Easy Pivot. Users can visually configure groups, pivot chips, aggregate
functions, Boolean pivots, follows relationships, and sorting options,
then generate the resulting SQL.

The Workbench can be hosted locally using PHP's built-in development
server or deployed to an existing PHP-enabled web server.

The Workbench can also connect to a database server on another computer,
provided the database server accepts the connection and the required
network, firewall, authentication, and database permissions are available.

The connection identifies the database target using the host, port, and
database fields. The Easy Pivot stored procedure is installed at the
database level, so the target database does not have to be named
`easy_pivot`.

The Workbench's Test Connection function reports database connectivity,
the MySQL server version, and whether the Easy Pivot stored procedure is
present in the selected database.

# Future Directions

One of the guiding principles of Easy Pivot has always been to make SQL
pivoting progressively easier.

The original project eliminated the need to manually write complex pivot
queries.

The next evolution is shared stored procedure deployment, allowing Easy
Pivot to be installed once and reused throughout an organization from a
single maintained code base.

Beyond that, the long-term vision is an Easy Pivot Workbench.

Rather than editing JSON by hand, users would visually select their
grouping fields, pivot fields, aggregate options, and sorting
preferences through a graphical interface while Easy Pivot automatically
generates and executes the required SQL, returning the results in a data
grid. Users may then export the data in the format of their choice. A
reference implementation could be developed using VB.NET or another
freely available application framework.

At present, there appears to be little commercial interest in providing
a database-independent SQL pivot compiler with this level of
flexibility. One possible reason is that SQL pivoting is often viewed as
a collection of database-specific techniques rather than as a
database-independent algorithm capable of being implemented across
multiple platforms.

Easy Pivot is intended to demonstrate that broader approach by providing
an open, database-focused solution for developers, analysts, and
database professionals.

Additional database backends currently under investigation include
SQLite and MariaDB.

# Features

With Easy Pivot, you can:

-   Dynamically pivot fields, resulting in any number of pivoted columns
-   Perform aggregate or Boolean pivots (Yes/No, True/False,
    Present/Absent, or any values you choose)
-   Use any aggregate function supported by the target database platform
-   Automatically remove NULLs that normally result from pivoting
-   Choose any number of fields to pivot on
-   Choose any number of fields to group on while pivoting
-   Position the pivoted columns between grouping fields
-   Reverse the sort order of left-to-right pivoted column names
-   Specify ascending ("ASC") or descending ("DESC") group sorting
-   Deploy Easy Pivot as a shared stored procedure (where supported)
-   Generate SQL source code or execute pivots directly

All the work is done for you, except for a small amount of configuration
required to specify a data source and what field(s) to group and pivot
on.

Beginning with the MySQL implementation, Easy Pivot also supports
installation as a shared stored procedure, greatly simplifying
deployment within production environments.

Future versions of the SQL Server, Oracle, and PostgreSQL
implementations are expected to receive the same deployment option.

For questions or comments, send email to:

tds67 (at) protonmail.com
