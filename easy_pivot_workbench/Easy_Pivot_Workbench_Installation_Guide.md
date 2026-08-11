# Easy Pivot Workbench --- Installation Guide

Easy Pivot Workbench is a PHP web application. It can be deployed on a
Windows computer using PHP's built-in web server, or deployed to an
existing PHP-enabled web server.

------------------------------------------------------------------------

# Step 1 --- Download and Extract Easy Pivot

Easy Pivot Workbench is distributed through GitHub.

**Easy Pivot project:**\
https://github.com/pivot-my-stuff/easy_pivot

If you are not using Git, you can download Easy Pivot as a ZIP file.

1.  Open the Easy Pivot project using the link above.
2.  Click the green **Code** button.
3.  Select **Download ZIP**.
4.  Save the ZIP file to your computer.
5.  Extract the ZIP file.

After extracting the ZIP file, open the extracted folder.

You should see a folder named:

``` text
easy_pivot_workbench
```

Open it.

Inside, you should see **another `easy_pivot_workbench` folder**.

**That is the Easy Pivot Workbench folder you want to use.**

> **Using Git?** If you already use Git, you can clone or pull the Easy
> Pivot repository instead. Git users can proceed once the Easy Pivot
> files are available locally.

------------------------------------------------------------------------

# Step 2 --- Install the Easy Pivot Database Stored Procedure

Before using Easy Pivot Workbench, install the Easy Pivot stored
procedure for the database platform you intend to use.

The Easy Pivot project contains a database folder for each supported
database platform:

``` text
easy_pivot_workbench
├── mysql
├── oracle
├── postgresql
└── sql_server
```

Open the folder for your database platform and locate the supplied Easy
Pivot stored-procedure script.

Install the procedure in the **database where you want Easy Pivot to be
available**.

The procedure is installed at the database level. You do **not** need to
create a special database for Easy Pivot, and you do not need to install
Easy Pivot across the entire database server.

For example, a database administrator can choose to make Easy Pivot
available in one database while leaving it unavailable in another.

The Easy Pivot Workbench database connection must point to a database
where the Easy Pivot procedure has been installed.

### Database-specific installation

-   **MySQL** --- install the procedure from the `mysql` folder.
-   **Oracle** --- install the procedure from the `oracle` folder.
-   **PostgreSQL** --- install the procedure from the `postgresql`
    folder.
-   **SQL Server** --- install the procedure from the `sql_server`
    folder.

The exact installation method depends on the database platform. Use the
appropriate database tool to execute the supplied script.

> **Important:** Installing the stored procedure and configuring a
> Workbench database connection are two separate steps. The procedure
> must exist in the target database before Easy Pivot can use that
> database.

------------------------------------------------------------------------

# Step 2.1 --- Understanding Easy Pivot Connections

Easy Pivot Workbench and the Easy Pivot stored procedure are separate
components.

The Workbench is the application interface. The stored procedure is
installed inside the target database.

A Workbench installation can connect to a database located on another
computer, provided the database server accepts the connection and the
required network access, credentials, and permissions are available.

The connection identifies the database target using the host, port, and
database fields:

``` text
Host     = computer running the database server
Port     = database network port
Database = database containing the Easy Pivot procedure
```

For example:

``` text
CRYPTID:3306/baan
```

means:

``` text
Server:   CRYPTID
Port:     3306
Database: baan
```

The database does **not** have to be named `easy_pivot`.

Easy Pivot can be installed into any database where the administrator
wants to use it. The Workbench connection simply needs to point to that
database.

For example, a Workbench hosted on `YETI` can connect to a MySQL
database on `CRYPTID`:

``` text
YETI
└── Easy Pivot Workbench
        |
        |  Host: CRYPTID
        |  Port: 3306
        |  Database: baan
        |
        v
CRYPTID
└── MySQL Server
        |
        └── baan
            ├── application tables
            └── Easy Pivot stored procedure
```

The Workbench itself does not need to be installed on the same computer
as the database server.

Connection information is deployment-specific. A stand-alone Workbench
and a Workbench hosted on a web server may connect to the same database,
but each deployment must have its own connection configured.

## Connection testing

The **Test Connection** function checks more than network connectivity.

For MySQL, the Workbench reports:

1.  Whether the database connection succeeded.
2.  The MySQL server version.
3.  Whether the Easy Pivot stored procedure exists in the selected
    database.

A successful test looks like:

``` text
Connection successful.

MySQL version: 8.0.46

Easy Pivot procedure found.
```

If the database connection succeeds but the procedure has not been
installed in that database, the test reports:

``` text
Connection successful.

MySQL version: 8.0.46

Easy Pivot procedure NOT found.
```

This distinction is useful when troubleshooting deployment. A successful
connection with a missing procedure means that the network connection,
database server, and credentials are working; the remaining step is to
install the Easy Pivot procedure in the selected database.

> **Important:** The stored procedure must exist in the database named
> by the Workbench connection. Installing the procedure in one database
> does not make it available automatically in other databases on the
> same server.

# Step 3 --- Install and Verify PHP on Windows

## What the stand-alone deployment requires

The **Easy Pivot Workbench stand-alone deployment requires PHP 8.x for
Windows**, with **PDO and the PDO driver for the database you intend to
use** available to PHP.

It does **not** require Apache, IIS, XAMPP, or another web server. The
stand-alone launcher uses PHP's built-in development web server.

PHP is a prerequisite for Easy Pivot and is not included with the Easy
Pivot repository.

### Required PHP database support

Easy Pivot uses PHP Data Objects (PDO) to communicate with the database.

PDO itself is normally enabled by default in the official Windows PHP
distribution, but it should be verified. The database-specific PDO
driver must also be available.

For example:

-   **MySQL** --- `PDO` and `pdo_mysql`
-   **PostgreSQL** --- `PDO` and `pdo_pgsql`
-   **SQL Server** --- `PDO` and `pdo_sqlsrv`
-   **Oracle** --- `PDO` and `pdo_oci`

If either PDO or the required database driver is missing, Easy Pivot
will not be able to connect to the database.

> **Important:** PHP installation is not complete for Easy Pivot until
> both PDO and the appropriate database-specific PDO driver have been
> verified.

## 3.1 Check whether PHP is already installed

Open a **new Windows Command Prompt** and run:

``` bat
php -v
```

If PHP is installed and available to Windows, you should see something
similar to:

``` text
PHP 8.x.x (cli) ...
```

Then run:

``` bat
where php
```

You should see the location of `php.exe`, for example:

``` text
C:\php\php.exe
```

If both commands work, PHP is ready for Easy Pivot.

## 3.2 If PHP is not installed

Download PHP from the official PHP for Windows project:

https://windows.php.net/download/

For a normal modern 64-bit Windows computer, choose the current **x64**
PHP build.

For the stand-alone Easy Pivot Workbench, use the **Non Thread Safe
(NTS)** ZIP distribution.

You do not need the Debug Pack, Development package, Apache, IIS, or
XAMPP.

## 3.3 Extract PHP

Create a directory such as:

``` text
C:\php
```

Extract the downloaded PHP ZIP file into that directory. When finished,
you should have:

``` text
C:\php\php.exe
```

You can test the installation directly:

``` bat
C:\php\php.exe -v
```

## 3.4 Add PHP to the Windows PATH

Easy Pivot's launcher executes:

``` bat
php -S localhost:18743
```

Windows therefore needs to know where PHP is located.

1.  Open **Start** and search for **environment variables**.
2.  Select **Edit the system environment variables**.
3.  Click **Environment Variables...**.
4.  Under **User variables**, select **Path** and click **Edit**.
5.  Click **New** and enter `C:\php`.
6.  Click **OK** until all dialogs are closed.

**Do not replace the existing PATH.** Add the PHP directory as a new
entry.

## 3.5 Verify PHP and database support

Close any Command Prompt windows that were already open before changing
PATH.

Open a **new** Command Prompt and run:

``` bat
php -v
where php
```

Then verify PDO and the driver for your database.

For MySQL, for example:

``` bat
php -m | findstr /I "PDO mysql"
```

You should see:

``` text
PDO
pdo_mysql
```

For other databases, verify the corresponding driver:

``` text
PostgreSQL  → pdo_pgsql
SQL Server  → pdo_sqlsrv
Oracle      → pdo_oci
```

If `PDO` or the required database driver is not listed, the PHP
installation must be configured before Easy Pivot can connect to that
database.

After changing `php.ini`, restart PHP/the web server as appropriate and
repeat the verification.

If `php -v` and `where php` work and the required PDO support is
present, PHP is ready for Easy Pivot.

------------------------------------------------------------------------

# Step 4 --- Put Easy Pivot on the Desktop and Create a Shortcut

Open the Easy Pivot folder you identified in Step 1.

Copy the **easy_pivot_workbench** folder and paste it onto your Windows
Desktop.

Open the `easy_pivot_workbench` folder on your Desktop and locate:

``` text
start_easy_pivot_workbench.bat
```

Right-click the `.bat` file and select:

**Show more options → Send to → Desktop (create shortcut)**

Return to your Desktop and rename the new shortcut:

**Easy Pivot Workbench**

You can now double-click the **Easy Pivot Workbench** shortcut to launch
the stand-alone Workbench.

**Keep the `easy_pivot_workbench` folder on your Desktop.** The launcher
needs the files and folders contained within it.

------------------------------------------------------------------------

# Step 5 --- Start Easy Pivot Workbench

Double-click the **Easy Pivot Workbench** desktop shortcut.

The launcher checks port **18743**, starts PHP's built-in web server,
and opens Easy Pivot in your browser.

## Port used by the stand-alone launcher

The stand-alone Workbench uses port **18743** by default.

Before starting PHP, the launcher checks whether that port is already in
use.

If you previously started Easy Pivot Workbench, the PHP server may still
be running even if you closed the browser. Look for the **Easy Pivot
Workbench command prompt** and close it before starting Easy Pivot
again.

If Easy Pivot is not already running, another application may be using
port 18743. In that case, the `PORT` value in the launcher can be
changed.

## The Easy Pivot Workbench command prompt

The command prompt window that appears is the PHP server.

**Do not close that command prompt while using Easy Pivot.**

Closing the browser does **not** stop the PHP server.

## Bookmark Easy Pivot Workbench

When the browser opens Easy Pivot Workbench, we recommend adding the
page to your browser's **bookmarks or favorites**.

The stand-alone Workbench normally opens at:

``` text
http://localhost:18743
```

If you close the browser while the Easy Pivot PHP server is still
running, you can reopen the browser and select the Easy Pivot Workbench
bookmark. The browser will reconnect to the running PHP server without
requiring you to start Easy Pivot again.

## Stopping the stand-alone Workbench

When you are finished with Easy Pivot, close the **Easy Pivot Workbench
command-prompt window**. This stops the local PHP server.

If you later launch Easy Pivot again while the previous PHP server is
still running, the launcher will detect that port 18743 is already in
use and tell you how to proceed.

------------------------------------------------------------------------

# Step 6 --- Deploy Easy Pivot to a Web Server

Easy Pivot Workbench is a PHP web application. The same Workbench used
by the stand-alone deployment can also be deployed to an existing web
server.

The web server must:

-   Support PHP.
-   Be configured to execute PHP files.
-   Have the Easy Pivot files available to the web server.

**Easy Pivot does not install or configure the web server.**

## Apache example

If your web server is **Apache**, copy the Easy Pivot Workbench files
into Apache's web document directory, normally the `htdocs` folder.

For example:

``` text
htdocs
└── easy_pivot_workbench
    ├── ...
    └── ...
```

The Workbench can then be accessed through the URL assigned to that
directory, for example:

``` text
http://your-server/easy_pivot_workbench/
```

The exact location of the `htdocs` directory and the URL depend on the
Apache installation and configuration.

## Other web servers

Easy Pivot is **not limited to Apache**.

If your organization uses IIS or another PHP-enabled web server, follow
that server's normal procedure for deploying PHP applications.

**Your web-server administrator is responsible for configuring the
server and PHP.**

### Remote database connections

The web server and database server do not have to be the same computer.

The Workbench uses the connection's host, port, and database values to
identify the database target. For a remote database, the database server
must be configured to accept connections from the web server, and any
required firewall rules, authentication, and database permissions must
allow the connection.

For example:

``` text
Easy Pivot Workbench on YETI
        |
        |  CRYPTID:3306/baan
        v
MySQL on CRYPTID
```

This allows one Workbench installation to be used with a database
located elsewhere on the network.

## PHP database extensions

The PHP installation used by the web server must have **PDO and the PDO
driver required by the selected database platform** available and
enabled.

PDO itself is normally enabled by default in the official Windows PHP
distribution, but the database-specific driver must be available. The
same database-driver requirement applies to the stand-alone and web
deployments.

For example:

-   **MySQL** --- `pdo_mysql`
-   **PostgreSQL** --- `pdo_pgsql`
-   **SQL Server** --- `pdo_sqlsrv`
-   **Oracle** --- `pdo_oci`

If the required PHP database driver is not enabled, Easy Pivot will not
be able to establish the database connection and may report:

``` text
Connection failed.
could not find driver
```

This is a **PHP/server configuration issue**, not an Easy Pivot database
connection setting.

Your web-server administrator should verify that the appropriate PHP
database extension is installed and enabled before troubleshooting the
Easy Pivot connection itself.

------------------------------------------------------------------------

# Step 7 --- Stand-Alone or Web Deployment?

Easy Pivot Workbench is the **same web application** in both deployment
models. The difference is where PHP hosts it.

  -----------------------------------------------------------------------
                          Stand-alone deployment  Web deployment
  ----------------------- ----------------------- -----------------------
  Easy Pivot Workbench    Same                    Same

  PHP                     User installs           Server administrator
                                                  provides

  Web server              PHP built-in server     Existing PHP-enabled
                                                  server

  Launcher                Included BAT file       Not required

  Typical access          `localhost:18743`       Server URL

  Intended use            Individual Windows      Shared/server
                          computer                environment
  -----------------------------------------------------------------------

## Stand-alone deployment

Use this when you want Easy Pivot on your own Windows computer.

You need:

-   Windows
-   PHP
-   Easy Pivot Workbench
-   A web browser

The supplied launcher starts PHP's built-in web server for you.

## Web deployment

Use this when Easy Pivot is going to live on an existing web server and
be accessed through a normal web URL.

You need:

-   An existing PHP-enabled web server
-   Easy Pivot Workbench files
-   A web browser

Your web-server administrator handles the server and PHP configuration.

## Using both deployments

You can use the **stand-alone** and **web** deployments of Easy Pivot
Workbench at the same time.

For example, you can have the stand-alone Workbench running on your
Windows computer while also accessing an Easy Pivot Workbench
installation hosted on a web server.

The two deployments operate independently. However, **database
connections must be configured separately for each deployment** because
the connection information is stored differently in the stand-alone and
web environments.

Configuring a database connection in the stand-alone Workbench does
**not** automatically make that connection available to the web
deployment, and vice versa.

The same database can be accessed by both deployments, provided each
deployment has been configured with the appropriate connection
information and the necessary database access is available.

## Which should I use?

If you are installing Easy Pivot for yourself on a Windows computer, use
the **stand-alone deployment**.

If your organization already has a PHP-enabled web server and wants Easy
Pivot hosted there, use the **web deployment**.

------------------------------------------------------------------------

*Easy Pivot Workbench documentation --- beta*
