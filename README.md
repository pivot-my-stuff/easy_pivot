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

### August 10, 2026 — Easy Pivot Workbench & Web Servers

Work was done yesterday implementing database connection functionality. And Easy Pivot Workbench will be able to run standalone on one computer or made available by another webserver hosting the Easy Pivot Workbench application. The webserver needs to have PHP support enabled.

# Easy Pivot Workbench

**Easy Pivot Workbench is officially no longer vaporware.** 😄 After a tremendous amount of development and testing, the project has evolved from a collection of SQL-generation code into a complete, polished interactive workbench. Users can enter a source query, configure groups and pivot chips through the interface, generate the resulting pivot SQL, and execute that SQL against the database. The workbench now includes dynamic configuration, validation, editing and deletion, NULL handling, multiple aggregation types, follows relationships, sorting, automatic source-query parsing, and a redesigned visual interface featuring the new Pivoty office and chalkboard-style SQL workspace.

The next step is **beta release**. We expect to make Easy Pivot Workbench available as beta software within the next day or two. Although the application is already remarkably mature, we want real users to put it through its paces before calling it production-ready. **Feedback, bug reports, usability observations, and suggestions are very welcome.** We've deliberately spent considerable time testing unusual combinations and trying to break the application ourselves, but there's nothing quite like having other people approach a tool with completely different ideas about how it should be used. If you've ever wished that constructing complicated pivot queries could be easier, we'd love for you to give Easy Pivot a try and tell us what you think.

## Current Features

- Visual Group editor
- Visual Pivot Chip editor
- Automatic JSON generation
- Built-in validation
- Dynamic SQL pivot code generation
- Local PHP application server (using PHP's built-in development server)
- Direct integration with the Easy Pivot stored procedure

## Current Platform

Easy Pivot Workbench is currently under active development and tested on:

- Microsoft Windows
- PHP 8.x
- MySQL

## Planned Platforms

Future releases are planned for:

- Linux
- macOS

## Future Database Support

Easy Pivot Workbench is being designed as a common graphical interface for every Easy Pivot implementation. Planned database support includes:

- SQL Server
- PostgreSQL
- Oracle

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

Since then, the project has undergone continuous refinement,
adding numerous usability improvements, compatibility fixes,
new pivot capabilities, and support for additional database
platforms.

The successful MySQL has also demonstrated that Easy Pivot can
be deployed as a shared stored procedure while maintaining the
flexibility and transparency that have always been central to
the project.

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

# Planned Browser User Interface and Potential Job Scheduling

A browser-based user interface to submit pivot code generation
requests to an Easy Pivot stored procedure will be under
development soon. MySQL will be the first to try out this new
innovation, due to MySQL not having the capability of executing
anonymous blocks of code.

This has been a blessing in disguise, because it has forced
the Easy Pivot project to innovate a way to convert the Easy
Pivot algorithm into a stored procedure in MySQL.

This opens up the possiblity for Easy Pivot to run in scheduled
jobs. If successfully implemented, it would be unnecessary to
regenerate pivot code as new data enters a database for the first
time. Traditional pivot code becomes "stale" when this happens,
and new pivot columns might not be generated because of this. A
scheduled Easy Pivot job would, in theory, keep the pivoted data
"fresh" by regenerating the pivot code during each scheduled
job.

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
the data in the format of their choice. A reference
implementation could be developed using VB.NET or another
freely available application framework.

At present, there appears to be little commercial interest in
providing a database-independent SQL pivot compiler with this
level of flexibility. One possible reason is that SQL pivoting
is often viewed as a collection of database-specific techniques
rather than as a database-independent algorithm capable of
being implemented across multiple platforms.

Easy Pivot is intended to demonstrate that broader approach by
providing an open, database-focused solution for developers,
analysts, and database professionals.

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

Beginning with the MySQL implementation, Easy Pivot also
supports installation as a shared stored procedure,
greatly simplifying deployment within production
environments.

Future versions of the SQL Server, Oracle, and PostgreSQL
implementations are expected to receive the same deployment
option.

For questions or comments, send email to:

tds67 (at) protonmail.com