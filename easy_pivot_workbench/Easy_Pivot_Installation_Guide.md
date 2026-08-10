# Easy Pivot Workbench — Installation Guide

Easy Pivot Workbench is a PHP web application. It can be deployed on a Windows computer using PHP's built-in web server, or deployed to an existing PHP-enabled web server.

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

After extracting the ZIP file, open the extracted folder.

You should see a folder named:

```text
easy_pivot_workbench
```

Open it.

Inside, you should see **another `easy_pivot_workbench` folder**.

**That is the Easy Pivot Workbench folder you want to use.**

> **Using Git?** If you already use Git, you can clone or pull the Easy Pivot repository instead. Git users can proceed once the Easy Pivot files are available locally.

---

# Step 2 — Install and Verify PHP on Windows

## What the stand-alone deployment requires

The **Easy Pivot Workbench stand-alone deployment requires PHP 8.x for Windows**.

It does **not** require Apache, IIS, XAMPP, or another web server. The stand-alone launcher uses PHP's built-in development web server.

PHP is a prerequisite for Easy Pivot and is not included with the Easy Pivot repository.

## 2.1 Check whether PHP is already installed

Open a **new Windows Command Prompt** and run:

```bat
php -v
```

If PHP is installed and available to Windows, you should see something similar to:

```text
PHP 8.x.x (cli) ...
```

Then run:

```bat
where php
```

You should see the location of `php.exe`, for example:

```text
C:\php\php.exe
```

If both commands work, PHP is ready for Easy Pivot.

## 2.2 If PHP is not installed

Download PHP from the official PHP for Windows project:

https://windows.php.net/download/

For a normal modern 64-bit Windows computer, choose the current **x64** PHP build.

For the stand-alone Easy Pivot Workbench, use the **Non Thread Safe (NTS)** ZIP distribution.

You do not need the Debug Pack, Development package, Apache, IIS, or XAMPP.

## 2.3 Extract PHP

Create a directory such as:

```text
C:\php
```

Extract the downloaded PHP ZIP file into that directory. When finished, you should have:

```text
C:\php\php.exe
```

You can test the installation directly:

```bat
C:\php\php.exe -v
```

## 2.4 Add PHP to the Windows PATH

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

## 2.5 Verify PHP

Close any Command Prompt windows that were already open before changing PATH.

Open a **new** Command Prompt and run:

```bat
php -v
where php
```

If both commands work, PHP is successfully installed and configured for Easy Pivot.

---

# Step 3 — Put Easy Pivot on the Desktop and Create a Shortcut

Open the Easy Pivot folder you identified in Step 1.

Copy the **easy_pivot_workbench** folder and paste it onto your Windows Desktop.

Open the `easy_pivot_workbench` folder on your Desktop and locate:

```text
start_easy_pivot_workbench.bat
```

Right-click the `.bat` file and select:

**Show more options → Send to → Desktop (create shortcut)**

Return to your Desktop and rename the new shortcut:

**Easy Pivot Workbench**

You can now double-click the **Easy Pivot Workbench** shortcut to launch the stand-alone Workbench.

**Keep the `easy_pivot_workbench` folder on your Desktop.** The launcher needs the files and folders contained within it.

---

# Step 4 — Start Easy Pivot Workbench

Double-click the **Easy Pivot Workbench** desktop shortcut.

The launcher checks port **18743**, starts PHP's built-in web server, and opens Easy Pivot in your browser.

## Port used by the stand-alone launcher

The stand-alone Workbench uses port **18743** by default.

Before starting PHP, the launcher checks whether that port is already in use.

If you previously started Easy Pivot Workbench, the PHP server may still be running even if you closed the browser. Look for the **Easy Pivot Workbench command prompt** and close it before starting Easy Pivot again.

If Easy Pivot is not already running, another application may be using port 18743. In that case, the `PORT` value in the launcher can be changed.

## The Easy Pivot Workbench command prompt

The command prompt window that appears is the PHP server.

**Do not close that command prompt while using Easy Pivot.**

Closing the browser does **not** stop the PHP server.

## Bookmark Easy Pivot Workbench

When the browser opens Easy Pivot Workbench, we recommend adding the page to your browser's **bookmarks or favorites**.

The stand-alone Workbench normally opens at:

```text
http://localhost:18743
```

If you close the browser while the Easy Pivot PHP server is still running, you can reopen the browser and select the Easy Pivot Workbench bookmark. The browser will reconnect to the running PHP server without requiring you to start Easy Pivot again.

## Stopping the stand-alone Workbench

When you are finished with Easy Pivot, close the **Easy Pivot Workbench command-prompt window**. This stops the local PHP server.

If you later launch Easy Pivot again while the previous PHP server is still running, the launcher will detect that port 18743 is already in use and tell you how to proceed.

---

# Step 5 — Deploy Easy Pivot to a Web Server

Easy Pivot Workbench is a PHP web application. The same Workbench used by the stand-alone deployment can also be deployed to an existing web server.

The web server must:

- Support PHP.
- Be configured to execute PHP files.
- Have the Easy Pivot files available to the web server.

**Easy Pivot does not install or configure the web server.**

## Apache example

If your web server is **Apache**, copy the Easy Pivot Workbench files into Apache's web document directory, normally the `htdocs` folder.

For example:

```text
htdocs
└── easy_pivot_workbench
    ├── ...
    └── ...
```

The Workbench can then be accessed through the URL assigned to that directory, for example:

```text
http://your-server/easy_pivot_workbench/
```

The exact location of the `htdocs` directory and the URL depend on the Apache installation and configuration.

## Other web servers

Easy Pivot is **not limited to Apache**.

If your organization uses IIS or another PHP-enabled web server, follow that server's normal procedure for deploying PHP applications.

**Your web-server administrator is responsible for configuring the server and PHP.**

---

# Step 6 — Stand-Alone or Web Deployment?

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
- Easy Pivot Workbench
- A web browser

The supplied launcher starts PHP's built-in web server for you.

## Web deployment

Use this when Easy Pivot is going to live on an existing web server and be accessed through a normal web URL.

You need:

- An existing PHP-enabled web server
- Easy Pivot Workbench files
- A web browser

Your web-server administrator handles the server and PHP configuration.

## Using both deployments

You can use the **stand-alone** and **web** deployments of Easy Pivot Workbench at the same time.

For example, you can have the stand-alone Workbench running on your Windows computer while also accessing an Easy Pivot Workbench installation hosted on a web server.

The two deployments operate independently. However, **database connections must be configured separately for each deployment** because the connection information is stored differently in the stand-alone and web environments.

Configuring a database connection in the stand-alone Workbench does **not** automatically make that connection available to the web deployment, and vice versa.

The same database can be accessed by both deployments, provided each deployment has been configured with the appropriate connection information and the necessary database access is available.

## Which should I use?

If you are installing Easy Pivot for yourself on a Windows computer, use the **stand-alone deployment**.

If your organization already has a PHP-enabled web server and wants Easy Pivot hosted there, use the **web deployment**.

---

*Easy Pivot Workbench documentation — beta*
