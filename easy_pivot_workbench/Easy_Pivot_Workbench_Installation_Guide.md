# Easy Pivot Workbench — Installation Guide

Easy Pivot Workbench is a PHP web application. It can be deployed on a Windows computer using PHP's built-in web server, or deployed to an existing PHP-enabled web server.

This guide documents the current installation and deployment process, including the additional PHP components required when using Oracle.

---

# Step 1 — Download and Extract Easy Pivot

Easy Pivot Workbench is distributed through GitHub.

**Easy Pivot project:**  
https://github.com/pivot-my-stuff/easy_pivot

If you are not using Git, you can download Easy Pivot as a ZIP file.

1. Open the Easy Pivot project using the link above.
2. Click the green **Code** button.
3. Select **Download ZIP**.
4. Save the ZIP file to your computer.
5. Extract the ZIP file.

After extracting the ZIP file, open the extracted folder. You should see:

```text
easy_pivot_workbench
```

Open it. Inside, you should see **another `easy_pivot_workbench` folder**.

**That is the Easy Pivot Workbench folder you want to use.**

> **Using Git?** If you already use Git, you can clone or pull the Easy Pivot repository instead. Git users can proceed once the Easy Pivot files are available locally.

---

# Step 2 — Install the Easy Pivot Database Stored Procedure

Before using Easy Pivot Workbench, install the Easy Pivot stored procedure for the database platform you intend to use.

The project contains a database folder for each supported platform:

```text
easy_pivot_workbench
├── mysql
├── oracle
├── postgresql
└── sql_server
```

Open the folder for your database platform and locate the supplied Easy Pivot stored-procedure script.

Install the procedure in the **database where you want Easy Pivot to be available**.

The procedure is installed at the database level. You do **not** need to create a special database for Easy Pivot, and you do not need to install Easy Pivot across the entire database server.

The Workbench connection must point to a database where the Easy Pivot procedure has been installed.

## Database-specific installation

- **MySQL** — install the procedure from the `mysql` folder.
- **Oracle** — install the procedure from the `oracle` folder.
- **PostgreSQL** — install the procedure from the `postgresql` folder.
- **SQL Server** — install the procedure from the `sql_server` folder.

Use the appropriate database tool to execute the supplied script.

> **Important:** Installing the stored procedure and configuring a Workbench database connection are two separate steps. The procedure must exist in the target database before Easy Pivot can use that database.

---

# Step 2.1 — Understanding Easy Pivot Connections

Easy Pivot Workbench and the Easy Pivot stored procedure are separate components.

A Workbench installation can connect to a database on another computer, provided the database server accepts the connection and the required network access, credentials, and permissions are available.

The connection identifies the target using:

```text
Host     = computer running the database server
Port     = database network port
Database = database or service used by the connection
```

For example:

```text
CRYPTID:3306/baan
```

means:

```text
Server:   CRYPTID
Port:     3306
Database: baan
```

The database does **not** have to be named `easy_pivot`.

For Oracle, the Workbench's **Database** field is the Oracle service name used by the connection, such as `XE`. The Workbench uses an Oracle Easy Connect target such as:

```text
//CRYPTID:1521/XE
```

The Workbench itself does not need to be installed on the same computer as the database server.

Connection information is deployment-specific. A stand-alone Workbench and a Workbench hosted on a web server may connect to the same database, but each deployment must have its own connection configured.

## Connection testing

The **Test Connection** function checks more than network connectivity.

For MySQL, the Workbench reports the connection result, server version, and whether the Easy Pivot procedure exists.

For Oracle, the Workbench reports:

1. Connection status.
2. Oracle Database version.
3. Session user.
4. Current schema.
5. Service.
6. Database.
7. OCI8 availability.
8. Easy Pivot procedure presence.

A successful Oracle test will look generally like:

```text
Connection successful.

Oracle version: Oracle Database ...

Session user: EASY_PIVOT_TEST
Current schema: EASY_PIVOT_TEST
Service: XE
Database: XE
OCI8 extension: available

Easy Pivot procedure found.
```

The exact values depend on the Oracle installation.

A successful connection with a missing procedure means the network connection, database server, and credentials are working; the remaining step is to install the Easy Pivot procedure in the selected database or schema.

> **Important:** Installing the procedure in one database or schema does not make it available automatically in other databases or schemas.

---

# Step 3 — Install and Verify PHP on Windows

## What the stand-alone deployment requires

The **Easy Pivot Workbench stand-alone deployment requires PHP 8.x for Windows**, with PDO and the database-specific PHP driver available to PHP.

It does **not** require Apache, IIS, XAMPP, or another web server. The stand-alone launcher uses PHP's built-in development web server.

PHP is a prerequisite for Easy Pivot and is not included with the Easy Pivot repository.

### Required PHP database support

Easy Pivot uses PHP Data Objects (PDO) to communicate with the database.

- **MySQL** — `PDO` and `pdo_mysql`
- **PostgreSQL** — `PDO` and `pdo_pgsql`
- **SQL Server** — `PDO` and `pdo_sqlsrv`
- **Oracle** — `PDO`, `pdo_oci`, and `oci8`

Oracle requires both Oracle PHP interfaces for the current Workbench:

- **PDO_OCI** is used for the normal Oracle connection and connection diagnostics.
- **OCI8** is used when the Workbench retrieves generated Oracle source code, because the Easy Pivot Oracle procedure returns that source through an Oracle implicit result set.

> **PHP 8.4 and later:** PDO_OCI and OCI8 are no longer bundled with the PHP distribution. They are distributed separately through PECL. If you use PHP 8.4 or later, install and enable both extensions as required by the PHP version you selected.

---

## 3.1 — Check whether PHP is already installed

Open a **new Windows Command Prompt** and run:

```bat
php -v
```

Then run:

```bat
where php
```

You should see the location of `php.exe`, for example:

```text
C:\php\php.exe
```

---

## 3.2 — If PHP is not installed

Download PHP from the official PHP for Windows project:

https://windows.php.net/download/

For a normal modern 64-bit Windows computer, choose the current **x64** PHP build.

For the stand-alone Easy Pivot Workbench, use the **Non Thread Safe (NTS)** ZIP distribution.

You do not need the Debug Pack, Development package, Apache, IIS, or XAMPP.

> **Oracle users:** PHP alone is not sufficient. Oracle also requires the Oracle client libraries and the PHP Oracle extensions described in Section 3.5.

---

## 3.3 — Extract PHP

Create a directory such as:

```text
C:\php
```

Extract the downloaded PHP ZIP file into that directory.

You should have:

```text
C:\php\php.exe
```

You can test it directly:

```bat
C:\php\php.exe -v
```

---

## 3.4 — Add PHP to the Windows PATH

Easy Pivot's launcher executes:

```bat
php -S localhost:18743
```

Windows therefore needs to know where PHP is located.

1. Open **Start** and search for **environment variables**.
2. Select **Edit the system environment variables**.
3. Click **Environment Variables...**.
4. Under **User variables**, select **Path** and click **Edit**.
5. Click **New** and enter `C:\php`.
6. Click **OK** until all dialogs are closed.

**Do not replace the existing PATH.** Add the PHP directory as a new entry.

---

## 3.5 — Oracle PHP Support

Oracle requires additional setup.

The current Easy Pivot Workbench uses:

- **PDO_OCI** for the Oracle database connection.
- **OCI8** for Oracle source-code retrieval.
- **Oracle Instant Client** for the Oracle client libraries when Oracle is not installed on the same computer as PHP.

You do **not** need to install Oracle SQL Developer simply to use Easy Pivot.

You also do not need a full Oracle Database installation on the Workbench computer.

### Install Oracle Instant Client

Download the current Windows x64 **Oracle Instant Client Basic** or **Basic Light** package from Oracle:

https://www.oracle.com/database/technologies/instant-client.html

Extract it to a directory such as:

```text
C:\oracle\instantclient_23_x
```

The exact directory name depends on the Instant Client version.

Add that directory to the Windows **PATH** as a new entry.

Close any Command Prompt windows that were open before changing PATH.

> The Oracle Instant Client supplies the Oracle client libraries used by the PHP Oracle extensions. Easy Pivot does not distribute those Oracle libraries.

### Enable PDO_OCI and OCI8

The PHP installation used by Easy Pivot must provide:

```text
pdo_oci
oci8
```

Verify the loaded modules:

```bat
php -m | findstr /I "PDO oci"
```

You should see entries corresponding to:

```text
PDO
pdo_oci
oci8
```

You can inspect OCI8 directly:

```bat
php --ri oci8
```

If `pdo_oci` or `oci8` is not listed, the extension is not currently available to the PHP installation used by Easy Pivot.

For PHP versions where these extensions are supplied separately, follow the installation instructions for the matching PHP build from the PHP/PECL documentation.

> **Important:** PHP extensions must match the PHP build you are using, including its Windows architecture and thread-safety configuration. Do not mix DLLs from a different PHP build.

### Verify the Oracle connection environment

After installing PHP, Instant Client, and the required extensions, open a **new** Command Prompt and run:

```bat
php -m | findstr /I "PDO oci"
php --ri oci8
```

Then create an Oracle connection in Easy Pivot Workbench using:

```text
Host     = Oracle server name or address
Port     = Oracle listener port, normally 1521
Database = Oracle service name
```

For example:

```text
Host     = CRYPTID
Port     = 1521
Database = XE
```

### Oracle authentication

Easy Pivot Workbench supports Oracle connections using **username and password authentication**.

Windows/External Authentication is **not supported through the Windows PHP Oracle interface used by Easy Pivot**.

This is not an Easy Pivot restriction.

The PHP OCI8 documentation explicitly states that Oracle External/OS Authentication (`OCI_CRED_EXT`) is **not supported on Windows for security reasons**. Easy Pivot uses the supported PHP Oracle interfaces and does not attempt to bypass or modify that restriction.

Therefore, when Easy Pivot Workbench is running under Windows PHP, configure the Oracle connection with an Oracle username and password.

Reference:

https://www.php.net/manual/en/function.oci-connect.php

### Oracle source-code generation

The Oracle Easy Pivot procedure returns generated source code through an Oracle implicit result set. PDO_OCI can establish the connection, but it does not expose that implicit result set to PHP.

The Workbench therefore uses **OCI8** for this operation.

If an Oracle connection test succeeds but the Workbench reports:

```text
Oracle source-code retrieval requires the PHP OCI8 extension.
```

the Oracle connection itself is working. The missing component is the PHP OCI8 extension.

---

## 3.6 — Verify PHP and database support

Close any Command Prompt windows that were already open before changing PATH.

Open a **new** Command Prompt and run:

```bat
php -v
where php
```

Then verify the driver for your database.

MySQL:

```text
PDO
pdo_mysql
```

PostgreSQL:

```text
PDO
pdo_pgsql
```

SQL Server:

```text
PDO
pdo_sqlsrv
```

Oracle:

```text
PDO
pdo_oci
oci8
```

If a required PHP extension is not listed, the PHP installation must be configured before Easy Pivot can connect to that database.

After changing `php.ini`, restarting PHP, or changing PATH, repeat the verification using a **new** Command Prompt.

---

# Step 4 — Put Easy Pivot on the Desktop and Create a Shortcut

Open the Easy Pivot folder you identified in Step 1.

Copy the **easy_pivot_workbench** folder and paste it onto your Windows Desktop.

Open the folder and locate:

```text
start_easy_pivot_workbench.bat
```

Right-click the `.bat` file and select:

**Show more options → Send to → Desktop (create shortcut)**

Rename the new shortcut:

**Easy Pivot Workbench**

You can now double-click the shortcut to launch the stand-alone Workbench.

**Keep the `easy_pivot_workbench` folder on your Desktop.** The launcher needs the files and folders contained within it.

---

# Step 5 — Start Easy Pivot Workbench

Double-click the **Easy Pivot Workbench** desktop shortcut.

The launcher checks port **18743**, starts PHP's built-in web server, and opens Easy Pivot in your browser.

## Port used by the stand-alone launcher

The stand-alone Workbench uses port **18743** by default.

If you previously started Easy Pivot Workbench, the PHP server may still be running even if you closed the browser. Look for the **Easy Pivot Workbench command prompt** and close it before starting Easy Pivot again.

If another application is using port 18743, the `PORT` value in the launcher can be changed.

## The Easy Pivot Workbench command prompt

The command prompt window that appears is the PHP server.

**Do not close that command prompt while using Easy Pivot.**

Closing the browser does **not** stop the PHP server.

## Bookmark Easy Pivot Workbench

The stand-alone Workbench normally opens at:

```text
http://localhost:18743
```

You can bookmark that address. If you close the browser while the PHP server is still running, reopening the bookmark reconnects to the running Workbench.

## Stopping the stand-alone Workbench

When you are finished, close the **Easy Pivot Workbench command-prompt window**. This stops the local PHP server.

---

# Step 6 — Deploy Easy Pivot to a Web Server

Easy Pivot Workbench can also be deployed to an existing PHP-enabled web server.

The web server must:

- Support PHP.
- Be configured to execute PHP files.
- Have the Easy Pivot files available to the web server.

**Easy Pivot does not install or configure the web server.**

## Apache example

If your web server is **Apache**, copy the Easy Pivot Workbench files into Apache's web document directory, normally `htdocs`.

```text
htdocs
└── easy_pivot_workbench
    ├── ...
    └── ...
```

For example:

```text
http://your-server/easy_pivot_workbench/
```

## Other web servers

Easy Pivot is **not limited to Apache**.

If your organization uses IIS or another PHP-enabled web server, follow that server's normal procedure for deploying PHP applications.

**Your web-server administrator is responsible for configuring the server and PHP.**

### Remote database connections

The web server and database server do not have to be the same computer.

The database server must accept connections from the web server, and required firewall rules, authentication, and database permissions must allow the connection.

### PHP database extensions

The PHP installation used by the web server must have the required database extension enabled.

For Oracle, the web-server PHP installation requires:

```text
pdo_oci
oci8
```

The Oracle Instant Client libraries must also be available to that PHP installation.

If the required PHP database driver is not enabled, Easy Pivot may report:

```text
Connection failed.
could not find driver
```

This is a **PHP/server configuration issue**, not an Easy Pivot database connection setting.

---

# Step 7 — Stand-Alone or Web Deployment?

Easy Pivot Workbench is the **same web application** in both deployment models. The difference is where PHP hosts it.

| | Stand-alone deployment | Web deployment |
|---|---|---|
| Easy Pivot Workbench | Same | Same |
| PHP | User installs | Server administrator provides |
| Web server | PHP built-in server | Existing PHP-enabled server |
| Launcher | Included BAT file | Not required |
| Typical access | `localhost:18743` | Server URL |
| Intended use | Individual Windows computer | Shared/server environment |

## Stand-alone deployment

Use this when you want Easy Pivot on your own Windows computer.

You need:

- Windows
- PHP
- Required PHP database extensions
- Easy Pivot Workbench
- A web browser
- Oracle Instant Client if using Oracle

## Web deployment

Use this when Easy Pivot will live on an existing web server.

You need:

- An existing PHP-enabled web server
- Easy Pivot Workbench files
- Required PHP database extensions
- A web browser
- Oracle Instant Client if using Oracle

Your web-server administrator handles the server and PHP configuration.

## Using both deployments

You can use the **stand-alone** and **web** deployments at the same time.

The two deployments operate independently. Database connections must be configured separately for each deployment.

The same database can be accessed by both deployments, provided each deployment has the appropriate connection information and database access.

---

# Troubleshooting Quick Reference

## `php` is not recognized

Run:

```bat
where php
```

If Windows cannot find `php.exe`, verify that the PHP directory has been added to PATH and open a new Command Prompt.

## `could not find driver`

The PHP database extension required by the selected database is missing or not enabled.

```text
MySQL       → pdo_mysql
PostgreSQL  → pdo_pgsql
SQL Server  → pdo_sqlsrv
Oracle      → pdo_oci
```

## Oracle connection fails

Verify:

1. Oracle is reachable from the Workbench computer.
2. The host name is correct.
3. The listener port is correct, normally `1521`.
4. The **Database** field contains the Oracle service name.
5. The Oracle username and password are correct.
6. `pdo_oci` is loaded by PHP.
7. Oracle Instant Client is installed if required.
8. The Instant Client directory is on PATH.
9. The PHP and Oracle client architectures are compatible.

## Oracle source-code generation fails because OCI8 is missing

Run:

```bat
php --ri oci8
```

If OCI8 is not installed or enabled, install/enable the matching OCI8 extension for your PHP build.

The normal Oracle connection can work through PDO_OCI even when OCI8 is missing. Source-code retrieval, however, requires OCI8.

## Oracle Windows Authentication does not work

This is expected.

PHP documents that Oracle External/OS Authentication (`OCI_CRED_EXT`) is **not supported on Windows for security reasons**.

Use Oracle username/password authentication with Easy Pivot Workbench.

Easy Pivot does not attempt to bypass this restriction.

## Easy Pivot procedure not found

Install the procedure from the appropriate database directory:

```text
mysql
oracle
postgresql
sql_server
```

Then test the connection again.

## Port 18743 is already in use

Check whether an existing Easy Pivot Workbench PHP command prompt is still running.

If another application is using the port, change the `PORT` value in the stand-alone launcher.

---

# Official PHP and Oracle References

PHP for Windows:

https://windows.php.net/download/

PHP PDO_OCI:

https://www.php.net/manual/en/ref.pdo-oci.php

PHP OCI8 requirements:

https://www.php.net/manual/en/oci8.requirements.php

PHP OCI8 installation:

https://www.php.net/manual/en/oci8.installation.php

PHP Oracle External Authentication behavior:

https://www.php.net/manual/en/function.oci-connect.php

Oracle Instant Client:

https://www.oracle.com/database/technologies/instant-client.html

---

*Easy Pivot Workbench documentation — August 2026*
