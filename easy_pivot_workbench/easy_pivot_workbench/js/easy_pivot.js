/******************************************************************************
 *
 * Easy Pivot Workbench
 *
 * Copyright (C) 2026 Timothy David Sharpe
 *
 * Released under the Unlicense.
 *
 ******************************************************************************/

/******************************************************************************
    Easy Pivot Namespace
******************************************************************************/

const EasyPivot = {

    /**************************************************************************
        Workspace

        The Workspace Object is the single source of truth.

        All user input is stored here.

        The screen is refreshed from this object.
    **************************************************************************/

    workspace: {

        database: "",

        groups: [],

        pivotChips: [],

        availableFields: []

    },

    lastProcessedSourceQuery: "",

    sourceQueryDirty: false,

    aggregateTypes:
    {
        mysql:
        [
            "SUM",
            "COUNT",
            "AVG",
            "MIN",
            "MAX",
            "STDDEV",
            "VARIANCE"
        ],

        oracle:
        [
            "SUM",
            "COUNT",
            "AVG",
            "MIN",
            "MAX",
            "MEDIAN",
            "STDDEV",
            "VARIANCE"
        ],

        postgresql:
        [
            "SUM",
            "COUNT",
            "AVG",
            "MIN",
            "MAX",
            "STDDEV",
            "STDDEV_POP",
            "STDDEV_SAMP",
            "VARIANCE",
            "VAR_POP",
            "VAR_SAMP"
        ],

        sqlserver:
        [
            "SUM",
            "COUNT",
            "AVG",
            "MIN",
            "MAX",
            "STDEV",
            "STDEVP",
            "VAR",
            "VARP"
        ]
    },

    editingGroupIndex: -1,

    editingPivotIndex: -1,

    validationErrors:
    {
        groups: {},
        pivots: {}
    },

    /**************************************************************************
        Connection UI
    **************************************************************************/

    connections: [],

    selectedConnectionId: "",

    selectedConnectionsByDatabase:
    {
        mysql: "",
        oracle: "",
        postgresql: "",
        sqlserver: ""
    },

    previousConnectionId: "",

    temporaryConnectionId: "",

    /*
        Password confirmation is session-only.

        The connection object may legitimately contain an empty password,
        so the presence of a password cannot itself tell us whether the
        user has already been prompted for this connection.
    */
    passwordPromptedConnections: {},

    /**************************************************************************
        Host / Connection Identity
    **************************************************************************/

    formatHostName(host)
    {
        const value =
            String(host || "").trim();

        if (
            value === "" ||
            value.toLowerCase() === "localhost" ||
            value === "127.0.0.1" ||
            value === "::1"
        )
        {
            return "Localhost";
        }

        return value.toUpperCase();
    },

    refreshApplicationHost()
    {
        const header =
            document.querySelector(
                "#application_header h2"
            );

        if (!header)
        {
            return;
        }

        const serverHost =
            this.formatHostName(
                window.location.hostname
            );

        header.textContent =
            "Easy Pivot Workbench on " +
            serverHost;
    },

    refreshConnectionIdentity()
    {
        const label =
            document.querySelector(
                'label[for="connection_select"]'
            );

        if (!label)
        {
            return;
        }

        const connection =
            this.connections.find(
                item =>
                    item.id ===
                    this.selectedConnectionId
            );

        if (!connection)
        {
            label.textContent = "Connect to...";
            return;
        }

        label.textContent =
            "Connect to " +
            this.formatHostName(connection.host) +
            ":" +
            connection.port +
            "/" +
            connection.database;
    },


    promptForPassword(connection)
    {

        return new Promise(resolve =>
        {

            const dialog =
                document.createElement("dialog");

            dialog.style.padding = "0";
            dialog.style.border = "none";
            dialog.style.borderRadius = "10px";
            dialog.style.width = "420px";
            dialog.style.maxWidth = "90vw";

            const form =
                document.createElement("form");

            form.method = "dialog";
            form.style.padding = "24px";

            const message =
                document.createElement("div");

            message.textContent =
                "Enter the password for \"" +
                connection.name +
                "\" on " +
                this.formatHostName(connection.host) +
                ".";

            message.style.marginBottom = "12px";

            const note =
                document.createElement("div");

            note.textContent =
                "The password will be kept only for this " +
                "browser session. It will not be saved.";

            note.style.marginBottom = "16px";
            note.style.fontSize = "0.9em";

            const input =
                document.createElement("input");

            input.type = "password";
            input.autocomplete = "current-password";
            input.style.width = "100%";
            input.style.boxSizing = "border-box";
            input.style.padding = "10px";
            input.style.marginBottom = "18px";

            const buttons =
                document.createElement("div");

            buttons.style.display = "flex";
            buttons.style.justifyContent = "flex-end";
            buttons.style.gap = "10px";

            const cancel =
                document.createElement("button");

            cancel.type = "button";
            cancel.textContent = "Cancel";

            const ok =
                document.createElement("button");

            ok.type = "submit";
            ok.textContent = "OK";

            buttons.appendChild(cancel);
            buttons.appendChild(ok);

            form.appendChild(message);
            form.appendChild(note);
            form.appendChild(input);
            form.appendChild(buttons);

            dialog.appendChild(form);
            document.body.appendChild(dialog);

            let finished = false;

            const finish = value =>
            {

                if (finished)
                {
                    return;
                }

                finished = true;

                dialog.close();
                dialog.remove();

                resolve(value);

            };

            form.addEventListener(
                "submit",
                event =>
                {
                    event.preventDefault();

                    finish(input.value);
                }
            );

            cancel.addEventListener(
                "click",
                () =>
                {
                    finish(null);
                }
            );

            dialog.addEventListener(
                "cancel",
                event =>
                {
                    event.preventDefault();

                    finish(null);
                }
            );

            dialog.showModal();

            input.focus();

        });

    },

    async ensureConnectionPassword(connection)
    {
        if (!connection)
        {
            return false;
        }

        if (connection.authentication !== "password")
        {
            return true;
        }

        if (
            this.passwordPromptedConnections[
                connection.id
            ]
        )
        {
            return true;
        }

        /*
            A password already present in memory came from the current
            session (for example, the connection was just saved).
            Do not prompt again.
        */
        if (connection.password !== "")
        {
            this.passwordPromptedConnections[
                connection.id
            ] = true;

            return true;
        }

        const password =
            await this.promptForPassword(connection);

        if (password === null)
        {
            return false;
        }

        /*
            Empty passwords are allowed. The session flag distinguishes
            an intentionally empty password from an unprompted connection.
        */
        connection.password = password;

        this.passwordPromptedConnections[
            connection.id
        ] = true;

        return true;
    },

    /**************************************************************************
        Initialization
    **************************************************************************/

    init() {


        this.refreshApplicationHost();

        this.registerEvents();

        const hideWorkspace =
            document.getElementById("hide_workspace");

        hideWorkspace.checked = false;

        this.refreshWorkspace();

        const selectedDatabase =
            document.querySelector(
                'input[name="database"]:checked'
            );

        this.workspace.database = selectedDatabase.value;

        this.initializeConnections();

        this.refreshWorkspace();

    },

    /**************************************************************************
        Connection UI
    **************************************************************************/

    initializeConnections()
    {

        this.loadSavedConnections();

        this.refreshConnectionList();

        this.loadSelectedConnection();

        this.refreshAuthenticationOptions();

    },


    refreshAuthenticationOptions()
    {

        const database =
            document.querySelector(
                'input[name="database"]:checked'
            ).value;

        const select =
            document.getElementById(
                "connection_authentication"
            );

        const currentValue =
            select.value || "password";

        const passwordOption =
            select.querySelector(
                'option[value="password"]'
            );

        const windowsOption =
            select.querySelector(
                'option[value="windows"]'
            );

        if (!passwordOption || !windowsOption)
        {
            return;
        }

        if (database === "sqlserver")
        {
            select.appendChild(windowsOption);
            select.appendChild(passwordOption);
        }
        else
        {
            select.appendChild(passwordOption);
            select.appendChild(windowsOption);
        }

        select.value = currentValue;

        this.refreshAuthenticationFields();

    },


    refreshAuthenticationFields()
    {

        const authentication =
            document.getElementById(
                "connection_authentication"
            ).value;

        const windows =
            authentication === "windows";

        document.getElementById(
            "connection_username"
        ).disabled = windows;

        document.getElementById(
            "connection_password"
        ).disabled = windows;

    },


    loadSavedConnections()
    {

        try
        {
            const saved =
                localStorage.getItem("easy_pivot_connections");

            if (!saved)
            {
                return;
            }

            const connections =
                JSON.parse(saved);

            if (!Array.isArray(connections))
            {
                return;
            }

            const validConnections =
                connections.filter(connection =>
                    connection &&
                    typeof connection.id === "string" &&
                    typeof connection.name === "string" &&
                    typeof connection.databaseType === "string" &&
                    typeof connection.host === "string" &&
                    Number.isInteger(Number(connection.port)) &&
                    typeof connection.database === "string" &&
                    typeof connection.username === "string"
                );

            validConnections.forEach(savedConnection =>
            {
                /*
                    Local MySQL was a built-in connection in earlier beta
                    versions. It is no longer part of the application.
                    Ignore that legacy record so it cannot recreate an
                    implicit database connection.
                */
                if (savedConnection.id === "local_mysql")
                {
                    return;
                }

                const existing =
                    this.connections.find(
                        connection =>
                            connection.id === savedConnection.id
                    );

                if (existing)
                {
                    Object.assign(
                        existing,
                        savedConnection,
                        {
                            port:
                                Number(savedConnection.port),
                            password:
                                existing.password || ""
                        }
                    );
                }
                else
                {
                    this.connections.push(
                    {
                        ...savedConnection,
                        port:
                            Number(savedConnection.port),
                        password: ""
                    });
                }
            });

            const savedSelectedId =
                localStorage.getItem(
                    "easy_pivot_selected_connection"
                );

            if (
                savedSelectedId &&
                savedSelectedId !== "local_mysql" &&
                this.connections.some(
                    connection =>
                        connection.id === savedSelectedId
                )
            )
            {
                this.selectedConnectionId =
                    savedSelectedId;

                const selectedConnection =
                    this.connections.find(
                        connection =>
                            connection.id ===
                            this.selectedConnectionId
                    );

                if (selectedConnection)
                {
                    this.selectedConnectionsByDatabase[
                        selectedConnection.databaseType
                    ] = selectedConnection.id;
                }
            }
        }
        catch (error)
        {
            console.warn(
                "Easy Pivot could not load saved connections.",
                error
            );
        }

    },

    saveConnections()
    {

        const connectionsForStorage =
            this.connections.map(connection =>
            {
                const savedConnection = { ...connection };

                /*
                    Passwords are intentionally not persisted in browser
                    storage. They remain available for the current session.
                */
                delete savedConnection.password;

                return savedConnection;
            });

        localStorage.setItem(
            "easy_pivot_connections",
            JSON.stringify(connectionsForStorage)
        );

        localStorage.setItem(
            "easy_pivot_selected_connection",
            this.selectedConnectionId
        );

    },

    getFileTimestamp()
    {
        const now = new Date();

        const pad =
            value =>
                String(value).padStart(2, "0");

        return (
            now.getFullYear() +
            pad(now.getMonth() + 1) +
            pad(now.getDate()) +
            "-" +
            pad(now.getHours()) +
            pad(now.getMinutes()) +
            pad(now.getSeconds())
        );
    },

    downloadJsonFile(filename, data)
    {
        const blob =
            new Blob(
                [JSON.stringify(data, null, 4)],
                {
                    type: "application/json"
                }
            );

        const url =
            URL.createObjectURL(blob);

        const link =
            document.createElement("a");

        link.href = url;
        link.download = filename;

        document.body.appendChild(link);
        link.click();
        link.remove();

        URL.revokeObjectURL(url);
    },

    openJsonFile(callback)
    {
        const input =
            document.createElement("input");

        input.type = "file";
        input.accept = ".json,application/json";
        input.style.display = "none";

        input.addEventListener(
            "change",
            async () =>
            {
                const file = input.files[0];

                input.remove();

                if (!file)
                {
                    return;
                }

                try
                {
                    const text =
                        await file.text();

                    const data =
                        JSON.parse(text);

                    callback(data);
                }
                catch (error)
                {
                    console.error(
                        "Easy Pivot could not load JSON file.",
                        error
                    );

                    alert(
                        "The selected file could not be loaded.\n\n" +
                        "Please select a valid Easy Pivot JSON file."
                    );
                }
            }
        );

        document.body.appendChild(input);
        input.click();
    },

    saveConfigurationToFile()
    {

        /*
            A configuration file is now the complete Easy Pivot Workbench
            workspace. It contains the database selection, source query,
            groups, pivot chips, connections, and selected connection.

            Passwords are intentionally excluded. They remain available
            only for the current browser session.
        */

        const connections =
            this.connections.map(connection =>
            {
                const savedConnection =
                {
                    ...connection
                };

                delete savedConnection.password;

                return savedConnection;
            });

        const configuration =
        {
            version: 2,
            database:
                this.workspace.database,
            sourceQuery:
                document.getElementById(
                    "source_query"
                ).value,
            groups:
                this.workspace.groups,
            pivotChips:
                this.workspace.pivotChips,
            selectedConnectionId:
                this.selectedConnectionId,
            connections:
                connections
        };

        this.downloadJsonFile(
            "easy_pivot_configuration_" +
            this.getFileTimestamp() +
            ".json",
            configuration
        );
    },


    loadConfigurationFromFile()
    {

        this.openJsonFile(
            data =>
            {

                if (
                    !data ||
                    typeof data !== "object" ||
                    typeof data.database !== "string" ||
                    typeof data.sourceQuery !== "string" ||
                    !Array.isArray(data.groups) ||
                    !Array.isArray(data.pivotChips)
                )
                {
                    alert(
                        "The selected file is not a valid Easy Pivot " +
                        "configuration file."
                    );

                    return;
                }

                const validDatabases =
                    [
                        "mysql",
                        "oracle",
                        "postgresql",
                        "sqlserver"
                    ];

                if (
                    !validDatabases.includes(
                        data.database
                    )
                )
                {
                    alert(
                        "The configuration contains an unsupported " +
                        "database type."
                    );

                    return;
                }

                this.workspace.database =
                    data.database;

                const databaseRadio =
                    document.querySelector(
                        'input[name="database"][value="' +
                        data.database +
                        '"]'
                    );

                if (databaseRadio)
                {
                    databaseRadio.checked = true;
                }

                const sourceQuery =
                    this.normalizeSourceQuery(
                        data.sourceQuery
                    );

                document.getElementById(
                    "source_query"
                ).value = sourceQuery;

                this.workspace.groups =
                    data.groups.map(group =>
                    ({
                        field:
                            typeof group.field === "string"
                                ? group.field
                                : "",
                        sort:
                            group.sort === "DESC"
                                ? "DESC"
                                : "ASC"
                    }))
                    .filter(group =>
                        group.field !== ""
                    );

                this.workspace.pivotChips =
                    data.pivotChips
                        .filter(
                            pivot =>
                                pivot &&
                                typeof pivot.field === "string"
                        )
                        .map(pivot =>
                        ({
                            field: pivot.field,
                            type:
                                typeof pivot.type === "string"
                                    ? pivot.type
                                    : "SUM",
                            dataField:
                                typeof pivot.dataField === "string"
                                    ? pivot.dataField
                                    : "",
                            trueValue:
                                typeof pivot.trueValue === "string"
                                    ? pivot.trueValue
                                    : "",
                            falseValue:
                                typeof pivot.falseValue === "string"
                                    ? pivot.falseValue
                                    : "",
                            follows:
                                typeof pivot.follows === "string"
                                    ? pivot.follows
                                    : "",
                            sort:
                                pivot.sort === "DESC"
                                    ? "DESC"
                                    : "ASC",
                            removeNullColumns:
                                pivot.removeNullColumns !== false,
                            easyPivotHeadings:
                                pivot.easyPivotHeadings !== false
                        }));

                /*
                    Import connections from the same configuration file.
                    Existing session passwords are preserved.
                */

                if (Array.isArray(data.connections))
                {
                    const previousConnections =
                        this.connections;

                    const validConnections =
                        data.connections.filter(connection =>
                            connection &&
                            typeof connection.id === "string" &&
                            typeof connection.name === "string" &&
                            typeof connection.databaseType === "string" &&
                            typeof connection.host === "string" &&
                            Number.isInteger(Number(connection.port)) &&
                            typeof connection.database === "string" &&
                            typeof connection.username === "string"
                        );

                    this.connections = [];

                    validConnections.forEach(
                        importedConnection =>
                        {
                            if (
                                importedConnection.id ===
                                "local_mysql"
                            )
                            {
                                return;
                            }

                            const existing =
                                previousConnections.find(
                                    connection =>
                                        connection.id ===
                                        importedConnection.id
                                );

                            this.connections.push(
                            {
                                ...importedConnection,
                                port:
                                    Number(importedConnection.port),
                                password:
                                    existing
                                        ? existing.password || ""
                                        : ""
                            });
                        }
                    );
                }

                /*
                    Prefer the connection explicitly selected when the
                    configuration was saved. It must belong to the loaded
                    database. Otherwise preserve the current selection when
                    possible, or use the first connection for the database.
                */

                let selectedConnectionId = "";

                if (
                    typeof data.selectedConnectionId === "string"
                )
                {
                    const savedSelectedConnection =
                        this.connections.find(
                            connection =>
                                connection.id ===
                                data.selectedConnectionId &&
                                connection.databaseType ===
                                data.database
                        );

                    if (savedSelectedConnection)
                    {
                        selectedConnectionId =
                            savedSelectedConnection.id;
                    }
                }

                if (selectedConnectionId === "")
                {
                    const currentSelectedConnection =
                        this.connections.find(
                            connection =>
                                connection.id ===
                                this.selectedConnectionId &&
                                connection.databaseType ===
                                data.database
                        );

                    if (currentSelectedConnection)
                    {
                        selectedConnectionId =
                            currentSelectedConnection.id;
                    }
                }

                if (selectedConnectionId === "")
                {
                    const firstDatabaseConnection =
                        this.connections.find(
                            connection =>
                                connection.databaseType ===
                                data.database
                        );

                    if (firstDatabaseConnection)
                    {
                        selectedConnectionId =
                            firstDatabaseConnection.id;
                    }
                }

                this.selectedConnectionId =
                    selectedConnectionId;

                this.saveConnections();

                /*
                    Field discovery rebuilds only the derived
                    available-field list. It never wipes the loaded
                    Groups or Pivot Chips.
                */

                this.discoverFields(sourceQuery);

                this.sourceQueryDirty = false;

                this.refreshAuthenticationOptions();
                this.refreshConnectionList();

                if (this.selectedConnectionId)
                {
                    this.loadSelectedConnection();
                }
                else
                {
                    this.clearConnectionFields();
                }

                this.updateDeleteConnectionButton();
                this.refreshWorkspace();

                alert(
                    "Configuration loaded successfully."
                );
            }
        );
    },


    restoreDatabaseConnection()
    {

        const database =
            this.workspace.database;

        const rememberedId =
            this.selectedConnectionsByDatabase[database] || "";

        const rememberedConnection =
            this.connections.find(
                connection =>
                    connection.databaseType === database &&
                    connection.id === rememberedId
            );

        if (rememberedConnection)
        {
            this.selectedConnectionId =
                rememberedConnection.id;

            return;
        }

        const firstConnection =
            this.connections.find(
                connection =>
                    connection.databaseType === database
            );

        this.selectedConnectionId =
            firstConnection
                ? firstConnection.id
                : "";

    },

    refreshConnectionList()
    {

        const select =
            document.getElementById("connection_select");

        select.innerHTML = "";

        this.connections
            .filter(connection =>
                connection.databaseType === this.workspace.database
            )
            .forEach(connection =>
            {

                const option =
                    document.createElement("option");

                option.value = connection.id;
                option.textContent = connection.name;

                select.appendChild(option);

            });

        const newOption =
            document.createElement("option");

        newOption.value = "__new_connection__";
        newOption.textContent = "New Connection...";

        select.appendChild(newOption);

        if (
            this.temporaryConnectionId &&
            this.connections.some(
                connection =>
                    connection.id === this.temporaryConnectionId
            )
        )
        {
            select.value =
                this.temporaryConnectionId;
        }
        else if (
            this.selectedConnectionId &&
            this.connections.some(
                connection =>
                    connection.id ===
                        this.selectedConnectionId &&
                    connection.databaseType ===
                        this.workspace.database
            )
        )
        {
            select.value =
                this.selectedConnectionId;
        }
        else
        {
            select.value =
                "__new_connection__";
        }

        this.refreshConnectionIdentity();

    },

    clearConnectionFields()
    {

        document.getElementById("connection_name").value =
            "";

        document.getElementById("connection_host").value =
            "";

        document.getElementById("connection_port").value =
            "";

        document.getElementById("connection_database").value =
            "";

        document.getElementById("connection_authentication").value =
            this.workspace.database === "sqlserver"
                ? "windows"
                : "password";

        document.getElementById("connection_username").value =
            "";

        document.getElementById("connection_password").value =
            "";

        this.refreshAuthenticationOptions();
        this.refreshConnectionIdentity();

    },


    loadSelectedConnection()
    {

        const connection =
            this.connections.find(
                item => item.id === this.selectedConnectionId
            );

        if (!connection)
        {
            return;
        }

        document.getElementById("connection_name").value =
            connection.name;

        document.getElementById("connection_host").value =
            connection.host;

        document.getElementById("connection_port").value =
            connection.port;

        document.getElementById("connection_database").value =
            connection.database;

        document.getElementById("connection_authentication").value =
            connection.authentication;

        document.getElementById("connection_username").value =
            connection.username;

        document.getElementById("connection_password").value =
            connection.password;

        document.getElementById("connection_select").value =
            connection.id;

        this.refreshAuthenticationOptions();

        this.refreshConnectionIdentity();

    },

    showConnectionDialog()
    {

        this.loadSelectedConnection();

        document.getElementById("connection_dialog").style.display =
            "block";

        this.updateDeleteConnectionButton();

        document.getElementById("connection_name").focus();

    },

    updateDeleteConnectionButton()
    {

        const button =
            document.getElementById(
                "delete_connection_button"
            );

        if (!button)
        {
            return;
        }

        button.disabled =
            this.temporaryConnectionId !== "" ||
            !this.connections.some(
                connection =>
                    connection.id ===
                    this.selectedConnectionId
            );

    },

    hideConnectionDialog()
    {

        if (this.temporaryConnectionId)
        {
            this.connections =
                this.connections.filter(
                    connection =>
                        connection.id !== this.temporaryConnectionId
                );

            this.temporaryConnectionId = "";

            if (this.previousConnectionId)
            {
                this.selectedConnectionId =
                    this.previousConnectionId;
            }

            this.previousConnectionId = "";

            this.refreshConnectionList();

            if (this.selectedConnectionId)
            {
                this.loadSelectedConnection();
            }
        }

        document.getElementById("connection_dialog").style.display =
            "none";

    },


    newConnection()
    {

        const databaseType =
            this.workspace.database;

        const defaults =
        {
            mysql:
            {
                host: "localhost",
                port: 3306,
                database: "easy_pivot",
                authentication: "password",
                username: "root",
                password: ""
            },

            oracle:
            {
                host: "",
                port: 1521,
                database: "",
                authentication: "password",
                username: "",
                password: ""
            },

            postgresql:
            {
                host: "localhost",
                port: 5432,
                database: "",
                authentication: "password",
                username: "",
                password: ""
            },

            sqlserver:
            {
                host: "localhost",
                port: 1433,
                database: "",
                authentication: "windows",
                username: "",
                password: ""
            }
        };

        const connectionDefaults =
            defaults[databaseType] ||
            {
                host: "",
                port: 0,
                database: "",
                authentication: "password",
                username: "",
                password: ""
            };

        const id =
            "connection_" +
            Date.now();

        const connection =
        {
            id,
            name: "New Connection",
            databaseType,
            ...connectionDefaults
        };

        this.previousConnectionId =
            this.selectedConnectionId;

        this.connections.push(connection);

        this.temporaryConnectionId = id;

        this.selectedConnectionId = id;

        this.refreshConnectionList();

        this.loadSelectedConnection();

        this.showConnectionDialog();

        this.updateDeleteConnectionButton();

        document
            .getElementById("connection_name")
            .select();

    },

    initializeTestConnectionButton()
    {

        if (document.getElementById("test_connection_button"))
        {
            return;
        }

        const saveButton =
            document.getElementById("save_connection_button");

        if (!saveButton || !saveButton.parentElement)
        {
            return;
        }

        const button =
            document.createElement("button");

        button.id = "test_connection_button";
        button.type = "button";
        button.textContent = "Test Connection";

        button.addEventListener(
            "click",
            () => this.testConnection()
        );

        saveButton.parentElement.insertBefore(
            button,
            saveButton
        );

    },

    async testConnection()
    {

        const connection = {
            host:
                document.getElementById("connection_host").value.trim(),

            port:
                Number(
                    document.getElementById("connection_port").value
                ),

            database:
                document.getElementById("connection_database").value.trim(),

            databaseType:
                document.querySelector(
                    'input[name="database"]:checked'
                ).value,

            authentication:
                document.getElementById(
                    "connection_authentication"
                ).value,

            username:
                document.getElementById(
                    "connection_username"
                ).value,

            password:
                document.getElementById(
                    "connection_password"
                ).value
        };

        if (!connection.host)
        {
            alert("Database host is required.");
            return;
        }

        if (
            !Number.isInteger(connection.port) ||
            connection.port < 1 ||
            connection.port > 65535
        )
        {
            alert(
                "Database port must be between 1 and 65535."
            );
            return;
        }

        if (!connection.database)
        {
            alert("Database name is required.");
            return;
        }

        if (
            connection.authentication !== "windows" &&
            !connection.username
        )
        {
            alert("Database user name is required.");
            return;
        }

        const button =
            document.getElementById("test_connection_button");

        button.disabled = true;
        button.textContent = "Testing...";

        try
        {
            const response =
                await fetch("php/test_connection.php", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        connection
                    })
                });

            const text = await response.text();

            if (!response.ok)
            {
                throw new Error(
                    text || "Connection test failed."
                );
            }

            alert(text);
        }
        catch (error)
        {
            alert(
                "Connection failed.\n\n" +
                (error.message || error)
            );
        }
        finally
        {
            button.disabled = false;
            button.textContent = "Test Connection";
        }

    },

    deleteConnection()
    {

        if (this.temporaryConnectionId)
        {
            alert(
                "This connection has not been saved yet. " +
                "Use Cancel instead."
            );

            return;
        }

        const connection =
            this.connections.find(
                item => item.id === this.selectedConnectionId
            );

        if (!connection)
        {
            return;
        }

        const confirmed =
            window.confirm(
                'Delete connection "' +
                connection.name +
                '"?'
            );

        if (!confirmed)
        {
            return;
        }

        const deletedId =
            connection.id;

        this.connections =
            this.connections.filter(
                item => item.id !== deletedId
            );

        this.selectedConnectionsByDatabase[
            connection.databaseType
        ] = "";

        const remainingConnections =
            this.connections.filter(
                item =>
                    item.databaseType ===
                    this.workspace.database
            );

        this.selectedConnectionId =
            remainingConnections.length > 0
                ? remainingConnections[0].id
                : "";

        if (this.selectedConnectionId)
        {
            this.selectedConnectionsByDatabase[
                this.workspace.database
            ] = this.selectedConnectionId;
        }

        this.saveConnections();

        this.refreshConnectionList();

        if (this.selectedConnectionId)
        {
            this.loadSelectedConnection();
        }

        this.hideConnectionDialog();

    },

    saveConnection()
    {

        const id =
            this.selectedConnectionId;

        let connection =
            this.connections.find(
                item => item.id === id
            );

        const values =
        {
            name:
                document.getElementById("connection_name")
                    .value.trim(),

            host:
                document.getElementById("connection_host")
                    .value.trim(),

            port:
                Number(
                    document.getElementById("connection_port")
                        .value
                ),

            database:
                document.getElementById("connection_database")
                    .value.trim(),

            authentication:
                document.getElementById("connection_authentication")
                    .value,

            username:
                document.getElementById("connection_username")
                    .value,

            password:
                document.getElementById("connection_password")
                    .value
        };

        if (!values.name)
        {
            alert("Connection name is required.");
            return;
        }

        if (!values.host)
        {
            alert("Database host is required.");
            return;
        }

        if (
            !Number.isInteger(values.port) ||
            values.port < 1 ||
            values.port > 65535
        )
        {
            alert(
                "Database port must be between 1 and 65535."
            );
            return;
        }

        if (!values.database)
        {
            alert("Database name is required.");
            return;
        }

        if (
            values.authentication !== "windows" &&
            !values.username
        )
        {
            alert("Database user name is required.");
            return;
        }

        if (!connection)
        {
            connection =
            {
                id,
                name: values.name,
                databaseType:
                    document.querySelector(
                        'input[name="database"]:checked'
                    ).value,
                host: values.host,
                port: values.port,
                authentication: values.authentication,
                username: values.username,
                password: values.password,
                database: values.database
            };

            this.connections.push(connection);

            if (connection.password !== "")
            {
                this.passwordPromptedConnections[
                    connection.id
                ] = true;
            }
        }
        else
        {
            const passwordChanged =
                connection.password !==
                values.password;

            Object.assign(
                connection,
                values
            );

            if (passwordChanged)
            {
                delete this.passwordPromptedConnections[
                    connection.id
                ];
            }
        }

        this.selectedConnectionId =
            connection.id;

        this.selectedConnectionsByDatabase[
            connection.databaseType
        ] = connection.id;

        this.temporaryConnectionId = "";

        this.previousConnectionId = "";

        this.saveConnections();

        this.refreshConnectionList();

        this.loadSelectedConnection();

        this.updateDeleteConnectionButton();

        this.hideConnectionDialog();

    },

    /**************************************************************************
        Event Registration
    **************************************************************************/

    registerEvents() {

        document
            .getElementById("manage_connections_button")
            .addEventListener(
                "click",
                () =>
                {
                    if (
                        this.selectedConnectionId &&
                        this.connections.some(
                            connection =>
                                connection.id ===
                                this.selectedConnectionId
                        )
                    )
                    {
                        this.showConnectionDialog();
                    }
                    else
                    {
                        this.newConnection();
                    }
                }
            );

        document
            .getElementById("load_configuration_button")
            .addEventListener(
                "click",
                () =>
                {
                    this.loadConfigurationFromFile();
                }
            );

        document
            .getElementById("save_configuration_button")
            .addEventListener(
                "click",
                () =>
                {
                    this.saveConfigurationToFile();
                }
            );

        document
            .getElementById("close_connection_dialog")
            .addEventListener(
                "click",
                () => this.hideConnectionDialog()
            );

        document
            .getElementById("cancel_connection_button")
            .addEventListener(
                "click",
                () => this.hideConnectionDialog()
            );

        document
            .getElementById("save_connection_button")
            .addEventListener(
                "click",
                () => this.saveConnection()
            );

        document
            .getElementById("delete_connection_button")
            .addEventListener(
                "click",
                () => this.deleteConnection()
            );

        this.initializeTestConnectionButton();

        document
            .getElementById("connection_select")
            .addEventListener(
                "change",
                (event) =>
                {
                    if (
                        event.target.value ===
                        "__new_connection__"
                    )
                    {
                        this.newConnection();

                        return;
                    }

                    this.selectedConnectionId =
                        event.target.value;

                    this.selectedConnectionsByDatabase[
                        this.workspace.database
                    ] = this.selectedConnectionId;

                    this.saveConnections();

                    this.loadSelectedConnection();
                    this.refreshConnectionIdentity();

                    this.updateDeleteConnectionButton();
                }
            );

        document
            .getElementById("hide_workspace")
            .addEventListener(
                "change",
                (event) => this.toggleWorkspace(event.target.checked)
            );

        document
            .getElementById("add_group_button")
            .addEventListener(
                "click",
                () => EasyPivot.addGroup()
            );

        document
            .getElementById("add_pivot_button")
            .addEventListener(
                "click",
                () => this.showPivotDialog()
            );

        document
            .getElementById("clear_group_button")
            .addEventListener(
                "click",
                () => this.clearGroups()
            );

        document
            .getElementById("clear_pivot_button")
            .addEventListener(
                "click",
                () => this.clearPivotChips()
            );

        document
            .getElementById("generate_sql_button")
            .addEventListener(
                "click",
                () =>
                {
                    this.generatePivotQuery();
                }
            );

        document
            .getElementById("close_button")
            .addEventListener(
                "click",
                () => this.hideOutputWindow()
            );

        document
            .getElementById("save_group_button")
            .addEventListener(
                "click",
                () => this.saveGroup()
            );

        document
            .getElementById("cancel_group_button")
            .addEventListener(
                "click",
                () => this.hideGroupDialog()
            );

        document
            .getElementById("close_group_dialog")
            .addEventListener(
                "click",
                () => this.hideGroupDialog()
            );

        document.addEventListener(

            "keydown",

            (event) => {

                if (event.key === "Escape") {

                    this.hideConnectionDialog();
                    this.hideGroupDialog();

                }

            }

        );

        document
            .getElementById("pivot_aggregate")
            .addEventListener(
                "input",
                () => this.pivotTypeChanged()
            );

        document
            .getElementById("save_pivot_button")
            .addEventListener(
                "click",
                () => EasyPivot.addPivotChip()
            );

        document
            .getElementById("cancel_pivot_button")
            .addEventListener(
                "click",
                () => this.hidePivotDialog()
            );

        document
            .getElementById("close_pivot_dialog")
            .addEventListener(
                "click",
                () => this.hidePivotDialog()
            );

        const sourceQuery =
            document.getElementById("source_query");

        sourceQuery.addEventListener(
            "input",
            () =>
            {
                this.sourceQueryDirty = true;
            });

        sourceQuery.addEventListener(
            "paste",
            () =>
            {
                setTimeout(() =>
                {
                    this.discoverFields(sourceQuery.value);
                }, 0);
            });

        sourceQuery.addEventListener(
            "drop",
            () =>
            {
                setTimeout(() =>
                {
                    this.discoverFields(sourceQuery.value);
                }, 0);
            });

        sourceQuery.addEventListener(
            "blur",
            (event) =>
            {

                const normalized =
                    this.normalizeSourceQuery(sourceQuery.value);

                if (sourceQuery.value !== normalized)
                {
                    sourceQuery.value = normalized;
                }

                /*
                    A blur by itself is not a source-query change.

                    In particular, clicking Generate Pivot Query causes
                    the Source Query textarea to lose focus. Do not let
                    that incidental blur wipe the user's Groups and
                    Pivot Chips.

                    The input event marks the query dirty only when the
                    user actually edits it. Paste/drop discovery already
                    calls discoverFields(), which clears the dirty flag.
                */
                if (
                    this.sourceQueryDirty &&
                    normalized !== this.lastProcessedSourceQuery
                )
                {
                    this.discoverFields(normalized);
                }
            });

        document
            .querySelectorAll('input[name="database"]')
            .forEach(radio =>
            {
                radio.addEventListener(
                    "change",
                    () =>
                    {
                        this.workspace.database = radio.value;
                        this.restoreDatabaseConnection();
                        this.refreshConnectionList();
                        this.loadSelectedConnection();
                        this.refreshAuthenticationOptions();
                        this.refreshConnectionIdentity();
                        this.refreshWorkspace();
                    });
            });

        document
            .getElementById("connection_authentication")
            .addEventListener(
                "change",
                () =>
                {
                    this.refreshAuthenticationFields();
                });

        const groupField = document.getElementById("group_field");
        const pivotField = document.getElementById("pivot_field");

        groupField.addEventListener("keydown", (e) =>
        {
            if (e.key === "Enter")
            {
                e.preventDefault();
                document.getElementById("save_group_button").click();
            }
        });

        pivotField.addEventListener("keydown", (e) =>
        {
            if (e.key === "Enter")
            {
                e.preventDefault();
                document.getElementById("save_pivot_button").click();
            }
        });

        document
            .getElementById("copy_button")
            .addEventListener("click", () => this.copyOutputToClipboard());

        /*
            Field selectors all use the single #available_fields
            datalist defined in index.html. The list is populated by
            refreshAvailableFields().
        */

        const openDropdownOnFocus = (id) =>
        {
            const input = document.getElementById(id);

            input.addEventListener(
                "focus",
                () =>
                {
                    setTimeout(() =>
                    {
                        input.click();
                    }, 0);
                }
            );
        };
        
        openDropdownOnFocus("group_field");
        openDropdownOnFocus("pivot_field");
        openDropdownOnFocus("pivot_data_field");
        openDropdownOnFocus("pivot_aggregate");

    },

    /**************************************************************************
        Workspace Refresh
    **************************************************************************/

    refreshAggregateTypes()
    {
        const datalist =
            document.getElementById(
                "pivot_aggregate_types"
            );

        datalist.innerHTML = "";

        const database =
            this.workspace.database;

        const aggregates =
            this.aggregateTypes[database] || [];

        aggregates.forEach(aggregate =>
        {
            const option =
                document.createElement("option");

            option.value = aggregate;

            datalist.appendChild(option);
        });

        const booleanOption =
            document.createElement("option");

        booleanOption.value = "BOOLEAN";

        datalist.appendChild(booleanOption);
    },

    refreshWorkspace() {

        this.validationErrors =
        {
            groups: {},
            pivots: {}
        };

        this.refreshGroups();

        this.refreshPivotChips();

        this.refreshGeneratedJSON();

        this.refreshGenerateButton();

        this.refreshFollowsList();

        this.refreshAvailableFields();

        this.refreshAggregateTypes();

    },

    refreshAvailableFields()
    {
        /*
            There is deliberately ONE field datalist.

            Groups, Pivot Fields, and Pivot Data Fields all use the
            same derived list of fields discovered from the Source
            Data Query. Keeping a second Pivot-specific datalist
            created by JavaScript introduced unnecessary state and
            made Load Configuration / refresh behavior fragile.

            The user's existing Groups and Pivot Chips are workspace
            state. availableFields is derived state. The datalist is
            simply the visual representation of availableFields.
        */

        const datalist =
            document.getElementById("available_fields");

        if (!datalist)
        {
            console.error(
                "[EP] available_fields datalist not found."
            );

            return;
        }

        datalist.innerHTML = "";

        this.workspace.availableFields.forEach(field =>
        {
            const option =
                document.createElement("option");

            option.value = field;

            datalist.appendChild(option);
        });

        /*
            All field selectors intentionally point to the same
            datalist. Do not create or maintain another field list.
        */

        document
            .getElementById("group_field")
            ?.setAttribute("list", "available_fields");

        document
            .getElementById("pivot_field")
            ?.setAttribute("list", "available_fields");

        document
            .getElementById("pivot_data_field")
            ?.setAttribute("list", "available_fields");

    },

    refreshFollowsList()
    {
        const follows =
            document.getElementById("pivot_follows");

        follows.innerHTML = "";

        const none = document.createElement("option");

        none.value = "";

        none.text = "None";

        follows.appendChild(none);

        this.workspace.groups.forEach(group =>
        {
            const option = document.createElement("option");

            option.value = group.field;
            option.text  = group.field;

            follows.appendChild(option);
        });
    },

    /******************************************************************************
        Field Discovery
    ******************************************************************************/

    normalizeSourceQuery(sql)
    {
        return String(sql)
            .trim()
            .replace(/;+$/, "")
            .trim();
    },

    discoverFields(sql)
    {

        sql = this.normalizeSourceQuery(sql);

        this.lastProcessedSourceQuery = sql;
        this.sourceQueryDirty = false;

        /*
            Field discovery is assistive only.

            Parsing the Source Query updates the derived available-field
            list used by the Group and Pivot field selectors. It must never
            destroy the user's existing Groups or Pivot Chips.

            The workspace configuration belongs to the user, while
            availableFields is derived from the current Source Query.
        */

        this.workspace.availableFields = [];

        const parts =
            this.findOuterSelectParts(sql);

        if (!parts)
        {
            this.refreshWorkspace();
            return;
        }

        let selectList =
            sql.substring(
                parts.selectStart + 6,
                parts.fromStart
            );

        /*
            SELECT-list modifiers belong to the SELECT statement, not to
            the first output field.

            Examples:
                SELECT DISTINCT [item_id] ...
                SELECT TOP 10 [item_id] ...
                SELECT TOP (10) PERCENT [item_id] ...
                SELECT DISTINCT TOP 10 WITH TIES [item_id] ...
        */
        selectList =
            selectList.replace(
                /^\s*DISTINCT\s+/i,
                ""
            );

        selectList =
            selectList.replace(
                /^\s*TOP\s+(?:\([^)]*\)|\S+)(?:\s+PERCENT)?(?:\s+WITH\s+TIES)?\s+/i,
                ""
            );

        const expressions =
            this.splitSelectExpressions(selectList);

        expressions.forEach(expression =>
        {
            expression = expression.trim();

            const field =
                this.discoverFieldName(expression);

            if (field !== "")
            {
                this.workspace.availableFields.push(field);
            }
        });

        this.workspace.availableFields.sort((a, b) => a.localeCompare(b));


        this.refreshWorkspace();


    },

    scanSqlState(sql, startIndex = 0)
    {
        /*
            SQL lexical state used by the lightweight Workbench parser.

            This is intentionally not a full SQL parser.  It only recognizes
            constructs that can contain commas, SELECT/FROM keywords, or
            identifier delimiters so those characters are not mistaken for
            structural SQL syntax.
        */

        let quote = null;
        let bracket = false;
        let lineComment = false;
        let blockComment = false;

        for (let i = startIndex; i < sql.length; i++)
        {
            const ch = sql[i];
            const next = sql[i + 1];

            if (lineComment)
            {
                if (ch === "\n" || ch === "\r")
                {
                    lineComment = false;
                }

                continue;
            }

            if (blockComment)
            {
                if (ch === "*" && next === "/")
                {
                    blockComment = false;
                    i++;
                }

                continue;
            }

            if (quote)
            {
                if (ch === quote)
                {
                    if (next === quote)
                    {
                        i++;
                    }
                    else
                    {
                        quote = null;
                    }
                }

                continue;
            }

            if (bracket)
            {
                if (ch === "]")
                {
                    if (next === "]")
                    {
                        i++;
                    }
                    else
                    {
                        bracket = false;
                    }
                }

                continue;
            }

            if (ch === "-" && next === "-")
            {
                lineComment = true;
                i++;
                continue;
            }

            if (ch === "/" && next === "*")
            {
                blockComment = true;
                i++;
                continue;
            }

            if (ch === "'" || ch === '"' || ch === "`")
            {
                quote = ch;
                continue;
            }

            if (ch === "[")
            {
                bracket = true;
                continue;
            }
        }

        return {
            quote: quote,
            bracket: bracket,
            lineComment: lineComment,
            blockComment: blockComment
        };
    },

    extractTrailingIdentifier(expression)
    {
        let text =
            String(expression).trim();

        /*
            Remove a trailing semicolon.  The source-query normalizer normally
            does this, but this helper is also used on generated expressions.
        */
        text =
            text.replace(/;+$/, "").trim();

        if (text === "")
        {
            return "";
        }

        /*
            Delimited identifiers.

            Scan backward so identifiers may contain spaces, punctuation, and
            escaped delimiters:
                [a]]b]
                "a""b"
                `a``b`
        */
        const last = text[text.length - 1];

        if (last === "]")
        {
            for (let i = text.length - 2; i >= 0; i--)
            {
                if (text[i] !== "[")
                {
                    continue;
                }

                if (i > 0 && text[i - 1] === "]")
                {
                    i--;
                    continue;
                }

                return text
                    .slice(i + 1, text.length - 1)
                    .replace(/]]/g, "]");
            }
        }

        if (last === '"' || last === "`")
        {
            const delimiter = last;

            for (let i = text.length - 2; i >= 0; i--)
            {
                if (text[i] !== delimiter)
                {
                    continue;
                }

                if (i > 0 && text[i - 1] === delimiter)
                {
                    i--;
                    continue;
                }

                const escaped =
                    delimiter === '"'
                        ? /""/g
                        : /``/g;

                return text
                    .slice(i + 1, text.length - 1)
                    .replace(escaped, delimiter);
            }
        }

        const match =
            text.match(
                /([A-Za-z_][A-Za-z0-9_$]*)\s*$/
            );

        return match
            ? match[1]
            : "";
    },

    hasExplicitAs(expression)
    {
        let depth = 0;
        let quote = null;
        let bracket = false;
        let lineComment = false;
        let blockComment = false;
        let lastAs = -1;

        for (let i = 0; i < expression.length; i++)
        {
            const ch = expression[i];
            const next = expression[i + 1];

            if (lineComment)
            {
                if (ch === "\n" || ch === "\r")
                {
                    lineComment = false;
                }

                continue;
            }

            if (blockComment)
            {
                if (ch === "*" && next === "/")
                {
                    blockComment = false;
                    i++;
                }

                continue;
            }

            if (quote)
            {
                if (
                    quote === "'" ||
                    quote === '"' ||
                    quote === "`"
                )
                {
                    if (
                        ch === "\\" &&
                        (
                            quote === "'" ||
                            quote === '"'
                        ) &&
                        next !== undefined
                    )
                    {
                        i++;
                        continue;
                    }

                    if (ch === quote)
                    {
                        if (next === quote)
                        {
                            i++;
                        }
                        else
                        {
                            quote = null;
                        }
                    }
                }
                else if (
                    expression.slice(
                        i,
                        i + quote.length
                    ) === quote
                )
                {
                    i += quote.length - 1;
                    quote = null;
                }

                continue;
            }

            if (bracket)
            {
                if (ch === "]")
                {
                    if (next === "]")
                    {
                        i++;
                    }
                    else
                    {
                        bracket = false;
                    }
                }

                continue;
            }

            if (ch === "-" && next === "-")
            {
                lineComment = true;
                i++;
                continue;
            }

            if (ch === "/" && next === "*")
            {
                blockComment = true;
                i++;
                continue;
            }

            if (ch === "'" || ch === '"' || ch === "`")
            {
                quote = ch;
                continue;
            }

            if (ch === "$")
            {
                const dollarMatch =
                    expression
                        .slice(i)
                        .match(
                            /^\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$/
                        );

                if (dollarMatch)
                {
                    quote = dollarMatch[0];
                    i += quote.length - 1;
                    continue;
                }
            }

            if (
                (ch === "q" || ch === "Q") &&
                next === "'"
            )
            {
                const delimiter = expression[i + 2];

                if (delimiter !== undefined)
                {
                    const closing =
                        {
                            "[": "]",
                            "(": ")",
                            "{": "}",
                            "<": ">"
                        }[delimiter] || delimiter;

                    quote = closing + "'";
                    i += 2;
                    continue;
                }
            }

            if (ch === "[")
            {
                bracket = true;
                continue;
            }

            if (ch === "(")
            {
                depth++;
                continue;
            }

            if (ch === ")")
            {
                depth--;
                continue;
            }

            if (
                depth === 0 &&
                (
                    ch === "A" ||
                    ch === "a"
                ) &&
                /^AS\b/i.test(
                    expression.slice(i)
                )
            )
            {
                lastAs = i;
            }
        }

        return lastAs !== -1;
    },

    splitSelectExpressions(selectList)
    {
        const expressions = [];

        let expression = "";
        let level = 0;
        let quote = null;
        let bracket = false;
        let lineComment = false;
        let blockComment = false;

        for (let i = 0; i < selectList.length; i++)
        {
            const ch = selectList[i];
            const next = selectList[i + 1];

            if (lineComment)
            {
                expression += ch;

                if (ch === "\n" || ch === "\r")
                {
                    lineComment = false;
                }

                continue;
            }

            if (blockComment)
            {
                expression += ch;

                if (ch === "*" && next === "/")
                {
                    expression += next;
                    blockComment = false;
                    i++;
                }

                continue;
            }

            if (quote)
            {
                if (
                    quote === "'" ||
                    quote === '"' ||
                    quote === "`"
                )
                {
                    if (
                        ch === "\\" &&
                        (
                            quote === "'" ||
                            quote === '"'
                        ) &&
                        next !== undefined
                    )
                    {
                        expression += ch + next;
                        i++;
                        continue;
                    }

                    expression += ch;

                    if (ch === quote)
                    {
                        if (next === quote)
                        {
                            expression += next;
                            i++;
                        }
                        else
                        {
                            quote = null;
                        }
                    }
                }
                else
                {
                    if (
                        selectList.slice(
                            i,
                            i + quote.length
                        ) === quote
                    )
                    {
                        expression += quote;
                        i += quote.length - 1;
                        quote = null;
                    }
                    else
                    {
                        expression += ch;
                    }
                }

                continue;
            }

            if (bracket)
            {
                expression += ch;

                if (ch === "]")
                {
                    if (next === "]")
                    {
                        expression += next;
                        i++;
                    }
                    else
                    {
                        bracket = false;
                    }
                }

                continue;
            }

            if (ch === "-" && next === "-")
            {
                expression += ch + next;
                lineComment = true;
                i++;
                continue;
            }

            if (ch === "/" && next === "*")
            {
                expression += ch + next;
                blockComment = true;
                i++;
                continue;
            }

            if (ch === "'" || ch === '"' || ch === "`")
            {
                quote = ch;
                expression += ch;
                continue;
            }

            /*
                PostgreSQL dollar-quoted strings:
                    $$...$$
                    $tag$...$tag$
            */
            if (ch === "$")
            {
                const dollarMatch =
                    selectList
                        .slice(i)
                        .match(
                            /^\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$/
                        );

                if (dollarMatch)
                {
                    quote = dollarMatch[0];
                    expression += quote;
                    i += quote.length - 1;
                    continue;
                }
            }

            /*
                Oracle alternative quoting:
                    q'[ ... ]'
                    q'( ... )'
                    q'{ ... }'
                    q'< ... >'
                    q'X ... X'
            */
            if (
                (ch === "q" || ch === "Q") &&
                next === "'"
            )
            {
                const delimiter =
                    selectList[i + 2];

                if (delimiter !== undefined)
                {
                    const closing =
                        {
                            "[": "]",
                            "(": ")",
                            "{": "}",
                            "<": ">"
                        }[delimiter] || delimiter;

                    quote =
                        closing + "'";

                    expression +=
                        selectList.slice(i, i + 3);

                    i += 2;
                    continue;
                }
            }

            if (ch === "[")
            {
                bracket = true;
                expression += ch;
                continue;
            }

            if (ch === "(")
            {
                level++;
                expression += ch;
                continue;
            }

            if (ch === ")")
            {
                level--;
                expression += ch;
                continue;
            }

            if (ch === "," && level === 0)
            {
                expressions.push(
                    expression.trim()
                );

                expression = "";
                continue;
            }

            expression += ch;
        }

        if (expression.trim() !== "")
        {
            expressions.push(
                expression.trim()
            );
        }

        return expressions;
    },

    stripSqlComments(sql)
    {
        let result = "";

        let quote = null;
        let bracket = false;
        let lineComment = false;
        let blockComment = false;

        for (let i = 0; i < sql.length; i++)
        {
            const ch = sql[i];
            const next = sql[i + 1];

            if (lineComment)
            {
                if (ch === "\n" || ch === "\r")
                {
                    lineComment = false;
                    result += ch;
                }

                continue;
            }

            if (blockComment)
            {
                if (ch === "*" && next === "/")
                {
                    blockComment = false;
                    result += " ";
                    i++;
                }

                continue;
            }

            if (quote)
            {
                if (
                    quote === "'" ||
                    quote === '"' ||
                    quote === "`"
                )
                {
                    if (
                        ch === "\\" &&
                        (
                            quote === "'" ||
                            quote === '"'
                        ) &&
                        next !== undefined
                    )
                    {
                        result += ch + next;
                        i++;
                        continue;
                    }

                    result += ch;

                    if (ch === quote)
                    {
                        if (next === quote)
                        {
                            result += next;
                            i++;
                        }
                        else
                        {
                            quote = null;
                        }
                    }
                }
                else if (
                    sql.slice(
                        i,
                        i + quote.length
                    ) === quote
                )
                {
                    result += quote;
                    i += quote.length - 1;
                    quote = null;
                }
                else
                {
                    result += ch;
                }

                continue;
            }

            if (bracket)
            {
                result += ch;

                if (ch === "]")
                {
                    if (next === "]")
                    {
                        result += next;
                        i++;
                    }
                    else
                    {
                        bracket = false;
                    }
                }

                continue;
            }

            if (ch === "-" && next === "-")
            {
                result += " ";
                lineComment = true;
                i++;
                continue;
            }

            if (ch === "/" && next === "*")
            {
                result += " ";
                blockComment = true;
                i++;
                continue;
            }

            if (ch === "'" || ch === '"' || ch === "`")
            {
                quote = ch;
                result += ch;
                continue;
            }

            if (ch === "$")
            {
                const dollarMatch =
                    sql
                        .slice(i)
                        .match(
                            /^\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$/
                        );

                if (dollarMatch)
                {
                    quote = dollarMatch[0];
                    result += quote;
                    i += quote.length - 1;
                    continue;
                }
            }

            if (
                (ch === "q" || ch === "Q") &&
                next === "'"
            )
            {
                const delimiter = sql[i + 2];

                if (delimiter !== undefined)
                {
                    const closing =
                        {
                            "[": "]",
                            "(": ")",
                            "{": "}",
                            "<": ">"
                        }[delimiter] || delimiter;

                    quote = closing + "'";
                    result += sql.slice(i, i + 3);
                    i += 2;
                    continue;
                }
            }

            if (ch === "[")
            {
                bracket = true;
                result += ch;
                continue;
            }

            result += ch;
        }

        return result;
    },

    discoverFieldName(expression)
    {
        let text =
            this
                .stripSqlComments(
                    String(expression)
                )
                .trim();

        if (text === "")
        {
            return "";
        }

        /*
            Explicit AS is authoritative.  The trailing identifier may be
            unquoted, SQL Server bracketed, Oracle/PostgreSQL double-quoted,
            or MySQL backtick-quoted.
        */
        if (this.hasExplicitAs(text))
        {
            return this.extractTrailingIdentifier(text);
        }

        /*
            A simple column reference may be qualified:
                field
                t.field
                [t].[field]
                "t"."field"
                `t`.`field`
        */
        if (
            /^[A-Za-z_][A-Za-z0-9_$]*(?:\s*\.\s*[A-Za-z_][A-Za-z0-9_$]*)*\s*$/.test(text) ||
            /^(?:\[[^\]]*(?:\]\][^\]]*)*\]\s*\.\s*)*\[[^\]]*(?:\]\][^\]]*)*\]\s*$/.test(text) ||
            /^(?:"[^"]*(?:""[^"]*)*"\s*\.\s*)*"[^"]*(?:""[^"]*)*"\s*$/.test(text) ||
            /^(?:`[^`]*(?:``[^`]*)*`\s*\.\s*)*`[^`]*(?:``[^`]*)*`\s*$/.test(text)
        )
        {
            return this.extractTrailingIdentifier(text);
        }

        /*
            Implicit aliases are also valid for simple quoted identifiers:
                "category" category
                [category] category
                `category` category

            Only treat the final token as an alias when the text before it
            contains whitespace.  Qualified identifiers such as t.category
            do not satisfy this condition.
        */
        const implicitAlias =
            this.extractTrailingIdentifier(text);

        if (implicitAlias !== "")
        {
            const aliasStart =
                text.length - implicitAlias.length;

            const separator =
                aliasStart > 0
                    ? text[aliasStart - 1]
                    : "";

            const prefix =
                text
                    .slice(
                        0,
                        aliasStart
                    )
                    .trimEnd();

            if (
                /\s/.test(separator) &&
                prefix !== "" &&
                !/\bAS\s*$/i.test(prefix) &&
                !/^(END|THEN|ELSE|WHEN|CASE)$/i.test(
                    implicitAlias
                )
            )
            {
                return implicitAlias;
            }
        }

        /*
            Preserve the existing implicit-alias behavior for expressions.
            Only accept a trailing identifier when the expression actually
            contains an expression construct such as a function or CASE.
        */
        if (
            text.includes("(") ||
            /\bCASE\b/i.test(text)
        )
        {
            const alias =
                this.extractTrailingIdentifier(text);

            if (
                alias !== "" &&
                !/^(END|THEN|ELSE|WHEN|CASE)$/i.test(alias)
            )
            {
                /*
                    Do not treat a lone function argument as an alias.
                    For SUM(quantity), expose quantity as the source field.
                */
                if (
                    text.startsWith(alias) ||
                    /\s/.test(
                        text.slice(0, -alias.length)
                    )
                )
                {
                    return alias;
                }
            }

            /*
                A simple one-column function such as SUM(quantity) has no
                alias.  Recover the final identifier inside the parentheses.
            */
            const inner =
                text.match(
                    /\(\s*(?:\[[^\]]*(?:\]\][^\]]*)*\]|"[^"]*(?:""[^"]*)*"|`[^`]*(?:``[^`]*)*`|[A-Za-z_][A-Za-z0-9_$]*)\s*\)\s*$/s
                );

            if (inner)
            {
                return this.extractTrailingIdentifier(
                    inner[0].replace(/^\(/, "").replace(/\)$/, "")
                );
            }
        }

        return "";
    },

    /******************************************************************************
        Group Dialog
    ******************************************************************************/

    showGroupDialog()
    {
        document.getElementById("group_field").value = "";
        document.getElementById("group_sort_asc").checked = true;
        document.getElementById("group_dialog").style.display = "block";
        document.getElementById("group_field").focus();
    },

    hideGroupDialog()
    {
        document.getElementById("group_dialog").style.display = "none";
    },

    /******************************************************************************
        Groups
    ******************************************************************************/

    addGroup()
    {
        this.showGroupDialog();
    },

    saveGroup()
    {
        const field =
            document.getElementById("group_field").value.trim();

        if (field === "")
        {
            alert("Please enter a group field.");
            return;
        }

        const sort =
            document.getElementById("group_sort_desc").checked
                ? "DESC"
                : "ASC";

        const group =
        {
            field: field,
            sort: sort
        };

        if (this.editingGroupIndex === -1)
        {
            this.workspace.groups.push(group);
        }
        else
        {
            this.workspace.groups[this.editingGroupIndex] = group;
            this.editingGroupIndex = -1;
        }

        this.hideGroupDialog();
        this.refreshWorkspace();
    },

    editGroup(index)
    {
        const group = this.workspace.groups[index];

        this.showGroupDialog();

        document.getElementById("group_field").value = group.field;

        if (group.sort === "DESC")
        {
            document.getElementById("group_sort_desc").checked = true;
        }
        else
        {
            document.getElementById("group_sort_asc").checked = true;
        }

        this.editingGroupIndex = index;
    },

    removeGroup(index) {

        this.workspace.groups.splice(index, 1);

        this.refreshWorkspace();

    },

    refreshGroups() {

        const container =
            document.getElementById("group_container");

        container.innerHTML = "";

        this.workspace.groups.forEach((group, index) => {

            const row = document.createElement("div");

            row.className = "group-row";

            if (this.validationErrors.groups[index])
            {
                row.classList.add("validation-error");
                row.title =
                    this.validationErrors.groups[index];
            }

            row.innerHTML = `

                <span>${group.field}</span>

                <span>${group.sort}</span>

                <span class="delete"
                    data-index="${index}">&times;</span>

            `;

            container.appendChild(row);

            row.addEventListener(
                "click",
                () => this.editGroup(index)
            );
                        
        });

        container
            .querySelectorAll(".delete")
            .forEach(button => {

                button.addEventListener("click", (event) =>
                {
                    event.stopPropagation();

                    this.removeGroup(button.dataset.index);
                });

            });

    },

    clearGroups()
    {
        this.workspace.groups = [];
        this.refreshWorkspace();
    },

    /**************************************************************************
        Pivot Chips
    **************************************************************************/

    addPivotChip()
    {

        const field =
            document.getElementById("pivot_field").value.trim();

        if (field === "")
        {
            alert("Please enter a pivot field.");
            return;
        }

        const aggregate =
            document.getElementById("pivot_aggregate").value.trim();

        if (aggregate === "")
        {
            alert("Please enter an Aggregate Type.");
            return;
        }

        const data =
            document.getElementById("pivot_data_field").value.trim();

            if (aggregate !== "BOOLEAN" && data === "")
            {
                alert("Please enter pivot data.");

                return;
            }

        const follows =
            document.getElementById("pivot_follows").value;

        const sort =
            document.getElementById("pivot_sort_desc").checked
                ? "DESC"
                : "ASC";

        const pivot =
        {
            field: field,
            type: aggregate,
            dataField: data,

            trueValue:
                document.getElementById("pivot_true").value.trim(),

            falseValue:
                document.getElementById("pivot_false").value.trim(),

            follows: follows,
            sort: sort,

            removeNullColumns:
                document
                    .getElementById("pivot_remove_null_columns")
                    .checked,

            easyPivotHeadings:
                document
                    .getElementById("pivot_easy_headings")
                    .checked
        };

        if (this.editingPivotIndex === -1)
        {
            this.workspace.pivotChips.push(pivot);
        }
        else
        {
            this.workspace.pivotChips[this.editingPivotIndex] = pivot;

            this.editingPivotIndex = -1;
        }

        this.refreshWorkspace();

        this.hidePivotDialog();

        this.clearPivotDialog();

    },

    editPivotChip(index)
    {
        const pivot = this.workspace.pivotChips[index];

        this.showPivotDialog();

        document.getElementById("pivot_field").value      = pivot.field;
        document.getElementById("pivot_data_field").value = pivot.dataField;
        document.getElementById("pivot_follows").value    = pivot.follows;
        document.getElementById("pivot_true").value       = pivot.trueValue;
        document.getElementById("pivot_false").value      = pivot.falseValue;

        document.getElementById("pivot_remove_null_columns").checked =
            pivot.removeNullColumns !== false;

        document.getElementById("pivot_easy_headings").checked =
            pivot.easyPivotHeadings !== false;

        document.getElementById("pivot_aggregate").value = pivot.type;

        if (pivot.sort === "DESC")
        {
            document.getElementById("pivot_sort_desc").checked = true;
        }
        else
        {
            document.getElementById("pivot_sort_asc").checked = true;
        }

        this.editingPivotIndex = index;

        this.pivotTypeChanged();

    },

    removePivotChip(index)
    {
        this.workspace.pivotChips.splice(index, 1);

        this.refreshWorkspace();
    },

    refreshPivotChips()
    {
        const container =
            document.getElementById("pivot_container");

        container.innerHTML = "";

        this.workspace.pivotChips.forEach((pivot, index) =>
        {
            const row = document.createElement("div");

            row.className = "pivot-row";

            if (this.validationErrors.pivots[index])
            {
                row.classList.add("validation-error");
                row.title =
                    this.validationErrors.pivots[index];
            }

            row.innerHTML = `
                <span>${pivot.field}</span>
                <span>${pivot.type}</span>
                <span>${pivot.dataField}</span>
                <span>${pivot.trueValue ?? ""}</span>
                <span>${pivot.falseValue ?? ""}</span>
                <span>${pivot.follows}</span>
                <span>${pivot.sort}</span>
                <span class="delete"
                    data-index="${index}">
                    ×
                </span>
            `;

            container.appendChild(row);

            row.addEventListener(
                "click",
                () => this.editPivotChip(index)
            );

        });

        container
            .querySelectorAll(".delete")
            .forEach(button =>
            {
                button.addEventListener("click", (event) =>
                {
                    event.stopPropagation();

                    this.removePivotChip(button.dataset.index);
                });
            });

    },

    showPivotDialog() {

        if (this.workspace.groups.length === 0)
        {
            alert(
                "Please add at least one Group before adding Pivot Chips."
            );

            return;
        }
        
        this.editingPivotIndex = -1;

        this.clearPivotDialog();

        document
            .getElementById("pivot_dialog")
            .style.display = "block";

        document
            .getElementById("pivot_field")
            .focus();

    },

    hidePivotDialog() {

        document
            .getElementById("pivot_dialog")
            .style.display = "none";

        this.editingPivotIndex = -1;

    },

    clearPivotDialog() {

        document.getElementById("pivot_field").value = "";

        document.getElementById("pivot_data_field").value = "";

        document.getElementById("pivot_true").value = "";

        document.getElementById("pivot_false").value = "";

        document.getElementById("pivot_aggregate").value = "";

        document.getElementsByName("pivot_sort")[0].checked = true;

        document.getElementById("pivot_remove_null_columns").checked = true;
        document.getElementById("pivot_easy_headings").checked = true;

        this.pivotTypeChanged();

    },

    clearPivotChips()
    {
        this.workspace.pivotChips = [];
        this.refreshWorkspace();
    },

    pivotTypeChanged() {

    const booleanSelected =
        document
            .getElementById("pivot_aggregate")
            .value
            .trim()
            .toUpperCase() === "BOOLEAN";

        document
            .getElementById("boolean_section")
            .style.display =

            booleanSelected
                ? "block"
                : "none";

        const dataField =

            document.getElementById("pivot_data_field");

        if (booleanSelected) {

            dataField.value = "";

            dataField.disabled = true;

        }

        else {

            dataField.disabled = false;

        }

        const aggregateInput =
            document.getElementById("pivot_aggregate");

        const aggregate =
            aggregateInput.value.trim();

        const database =
            this.workspace.database;

        const knownAggregates =
            this.aggregateTypes[database] || [];

        const isKnownAggregate =
            aggregate.toUpperCase() === "BOOLEAN" ||
            knownAggregates.some(
                value =>
                    value.toUpperCase() ===
                    aggregate.toUpperCase()
            );

        const customMessage =
            document.getElementById(
                "custom_aggregate_message"
            );

        customMessage.style.display =
            aggregate !== "" && !isKnownAggregate
                ? "block"
                : "none";

    },

    /**************************************************************************
        JSON
    **************************************************************************/

    generateJSON() {

        
    },

    generateMySqlJson() {
        const json =
        {
            Group: [],
            Order: [],
            Pivot: []
        };

        // Groups
        this.workspace.groups.forEach(group =>
        {
            json.Group.push(group.field);
            json.Order.push(group.sort);
        });

        // Pivot Chips
        this.workspace.pivotChips.forEach(pivot =>
        {
            const item =
            {
                Pivot_Field: pivot.field
            };

            if (pivot.type !== "BOOLEAN")
            {
                item.Pivot_Type = pivot.type;
            }

            if (pivot.type === "BOOLEAN")
            {
                item.Pivot_True = pivot.trueValue;
                item.Pivot_False = pivot.falseValue;
            }
            else
            {
                item.Pivot_Data = pivot.dataField;
            }

            if (pivot.follows)
            {
                item.Follows_Group = pivot.follows;
            }

            if (pivot.sort === "DESC")
            {
                item.Sort_Order = "DESC";
            }

            json.Pivot.push(item);
        });

        return JSON.stringify(json, null, 4);
    },

    generateStandardJson()
    {
        const json =
        [
            {
                Group : [],
                Order : [],
                Pivot : []
            }
        ];

        this.workspace.groups.forEach(group =>
        {
            json[0].Group.push(group.field);
            json[0].Order.push(group.sort);
        });

        this.workspace.pivotChips.forEach(pivot =>
        {
            const item =
            {
                Pivot_Field : pivot.field
            };

            if (pivot.type !== "BOOLEAN")
            {
                item.Pivot_Type = pivot.type;
            }

            if (pivot.type === "BOOLEAN")
            {
                item.Pivot_True  = pivot.trueValue;
                item.Pivot_False = pivot.falseValue;
            }
            else
            {
                item.Pivot_Data = pivot.dataField;
            }

            if (pivot.follows)
            {
                item.Follows_Group = pivot.follows;
            }

            if (pivot.sort === "DESC")
            {
                item.Sort_Order = "DESC";
            }

            json[0].Pivot.push(item);
        });

        return JSON.stringify(json, null, 4);
    },

    refreshGeneratedJSON() {

        let json;

        switch (this.workspace.database)
        {
            case "mysql":
                json = this.generateMySqlJson();
                break;

            case "oracle":
            case "postgresql":
            case "sqlserver":
                json = this.generateStandardJson();
                break;

            default:
                json = "";
        }

        document.getElementById("generated_json").value = json;

    },

    /**************************************************************************
        Generate Button
    **************************************************************************/

    refreshGenerateButton() {

        
    },

    /**************************************************************************
        Generated SQL Presentation
    **************************************************************************/

    splitTopLevelSelectItems(selectBody)
    {
        /*
            Generated SQL uses the same SELECT-list grammar as the source
            query.  Reuse the hardened lexical splitter so post-pivot NULL
            removal cannot be tripped by quoted identifiers, brackets,
            comments, or commas inside expressions.
        */
        return this.splitSelectExpressions(selectBody);
    },

    findOuterSelectParts(sql)
    {
        let depth = 0;
        let quote = null;
        let bracket = false;
        let lineComment = false;
        let blockComment = false;
        let selectStart = -1;
        let fromStart = -1;

        for (let i = 0; i < sql.length; i++)
        {
            const ch = sql[i];
            const next = sql[i + 1];

            if (lineComment)
            {
                if (ch === "\n" || ch === "\r")
                {
                    lineComment = false;
                }

                continue;
            }

            if (blockComment)
            {
                if (ch === "*" && next === "/")
                {
                    blockComment = false;
                    i++;
                }

                continue;
            }

            if (quote)
            {
                if (
                    quote === "'" ||
                    quote === '"' ||
                    quote === "`"
                )
                {
                    if (
                        ch === "\\" &&
                        (
                            quote === "'" ||
                            quote === '"'
                        ) &&
                        next !== undefined
                    )
                    {
                        i++;
                        continue;
                    }

                    if (ch === quote)
                    {
                        if (next === quote)
                        {
                            i++;
                        }
                        else
                        {
                            quote = null;
                        }
                    }
                }
                else if (
                    sql.slice(
                        i,
                        i + quote.length
                    ) === quote
                )
                {
                    i += quote.length - 1;
                    quote = null;
                }

                continue;
            }

            if (bracket)
            {
                if (ch === "]")
                {
                    if (next === "]")
                    {
                        i++;
                    }
                    else
                    {
                        bracket = false;
                    }
                }

                continue;
            }

            if (ch === "-" && next === "-")
            {
                lineComment = true;
                i++;
                continue;
            }

            if (ch === "/" && next === "*")
            {
                blockComment = true;
                i++;
                continue;
            }

            if (ch === "'" || ch === '"' || ch === "`")
            {
                quote = ch;
                continue;
            }

            if (ch === "$")
            {
                const dollarMatch =
                    sql
                        .slice(i)
                        .match(
                            /^\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$/
                        );

                if (dollarMatch)
                {
                    quote = dollarMatch[0];
                    i += quote.length - 1;
                    continue;
                }
            }

            if (
                (ch === "q" || ch === "Q") &&
                next === "'"
            )
            {
                const delimiter = sql[i + 2];

                if (delimiter !== undefined)
                {
                    const closing =
                        {
                            "[": "]",
                            "(": ")",
                            "{": "}",
                            "<": ">"
                        }[delimiter] || delimiter;

                    quote = closing + "'";
                    i += 2;
                    continue;
                }
            }

            if (ch === "[")
            {
                bracket = true;
                continue;
            }

            if (ch === "(")
            {
                depth++;
                continue;
            }

            if (ch === ")")
            {
                depth--;

                if (depth < 0)
                {
                    return null;
                }

                continue;
            }

            if (depth !== 0)
            {
                continue;
            }

            const remainder =
                sql.slice(i);

            if (
                selectStart === -1 &&
                /^SELECT\b/i.test(remainder)
            )
            {
                selectStart = i;
                i += 5;
                continue;
            }

            if (
                selectStart !== -1 &&
                /^FROM\b/i.test(remainder)
            )
            {
                fromStart = i;
                break;
            }
        }

        if (
            selectStart === -1 ||
            fromStart === -1
        )
        {
            return null;
        }

        return {
            selectStart: selectStart,
            fromStart: fromStart
        };
    },

    extractSqlAlias(expression)
    {
        if (!this.hasExplicitAs(expression))
        {
            return "";
        }

        return this.extractTrailingIdentifier(
            expression
        );
    },

    pivotMatchesAlias(pivot, alias)
    {
        if (!alias)
        {
            return false;
        }

        const normalizedAlias =
            alias.toLowerCase();

        const field =
            String(pivot.field || "").toLowerCase();

        if (pivot.type === "BOOLEAN")
        {
            return normalizedAlias.endsWith(
                "_" + field
            );
        }

        const type =
            String(pivot.type || "").toLowerCase();

        const dataField =
            String(pivot.dataField || "").toLowerCase();

        return normalizedAlias.startsWith(type + "_") &&
            normalizedAlias.endsWith("_" + dataField);
    },

    buildPivotNumberMap()
    {
        const map = new Map();
        const pivots = this.workspace.pivotChips;
        const groups = this.workspace.groups;
        let pivotNumber = 1;

        /*
            Reproduce the stored procedure's Pivot numbering order.

            Pass 0:
                Walk ALL Groups and assign numbers to pivots that
                follow each Group.

            Pass 1:
                Walk the Pivot Chips for pivots with no Follows Group.

                The BREAK is intentional.  No-Follows pivots are
                independent of Groups, so Pass 1 must happen only once.
                With multiple Groups, continuing the Group loop here
                would number the same Pivot Chips again.
        */
        for (let passCounter = 0; passCounter <= 1; passCounter++)
        {
            if (passCounter === 0)
            {
                for (const group of groups)
                {
                    for (const pivot of pivots)
                    {
                        if (pivot.follows === group.field)
                        {
                            map.set(pivot, pivotNumber++);
                        }
                    }
                }
            }
            else
            {
                for (const pivot of pivots)
                {
                    if (!pivot.follows && !map.has(pivot))
                    {
                        map.set(pivot, pivotNumber++);
                    }
                }

                break;
            }
        }

        /*
            If there are no Groups, Pass 0 has nothing to walk.
            Pass 1 above still assigns all no-Follows pivots exactly once.
        */

        return map;
    },

    findPivotForSelectItem(item, sql, pivotNumberMap)
    {
        /*
            Group columns belong to the outer EP source.  They do not
            belong to a Pivot Chip and therefore must never be subjected
            to Pivot-specific post-processing.
        */
        if (/\bep\s*\./i.test(item))
        {
            return null;
        }

        const pivotReference =
            item.match(/\bp(\d+)\s*\./i);

        if (pivotReference)
        {
            const pivotNumber =
                Number(pivotReference[1]);

            for (const [pivot, number] of pivotNumberMap.entries())
            {
                if (number === pivotNumber)
                {
                    return pivot;
                }
            }
        }

        /*
            Retain the alias-based match as a fallback for generated
            expressions that do not expose a pN reference.  The pN map
            above is the authoritative method for normal Pivot output.
        */
        const alias =
            this.extractSqlAlias(item);

        if (!alias)
        {
            return null;
        }

        const matches =
            this.workspace.pivotChips.filter(
                pivot => this.pivotMatchesAlias(pivot, alias)
            );

        return matches.length === 1
            ? matches[0]
            : null;
    },

    escapeRegExp(value)
    {
        return String(value)
            .replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    },

    standardizePivotAlias(alias)
    {
        return alias
            .split("_")
            .map(part =>
            {
                if (part === "")
                {
                    return part;
                }

                return part.charAt(0).toUpperCase() +
                    part.slice(1).toLowerCase();
            })
            .join("_");
    },

    isNullPivotAlias(alias)
    {
        const parts =
            alias.split("_");

        return parts.some(
            part => part.toLowerCase() === "null"
        );
    },

    postProcessGeneratedSql(sql)
    {
        if (!sql ||
            this.workspace.pivotChips.length === 0)
        {
            return sql;
        }

        const parts =
            this.findOuterSelectParts(sql);

        if (!parts)
        {
            return sql;
        }

        const selectBody =
            sql.slice(
                parts.selectStart + 6,
                parts.fromStart
            );

        const items =
            this.splitTopLevelSelectItems(selectBody);

        if (items.length === 0)
        {
            return sql;
        }

        const processedItems = [];

        const pivotNumberMap =
            this.buildPivotNumberMap();

        items.forEach(item =>
        {
            const pivot =
                this.findPivotForSelectItem(
                    item,
                    sql,
                    pivotNumberMap
                );

            if (!pivot)
            {
                processedItems.push(item);
                return;
            }

            const alias =
                this.extractSqlAlias(item);

            if (pivot.removeNullColumns !== false &&
                this.isNullPivotAlias(alias))
            {
                return;
            }

            let processedItem = item;

            if (pivot.easyPivotHeadings !== false)
            {
                const newAlias =
                    this.standardizePivotAlias(alias);

                processedItem =
                    item.replace(
                        new RegExp(
                            "(AS\\s+[`\"\\[]?)" +
                            this.escapeRegExp(alias) +
                            "([`\"\\]]?\\s*)$",
                            "i"
                        ),
                        "$1" + newAlias + "$2"
                    );
            }

            processedItems.push(processedItem);
        });

        const newSelectBody =
            "\n" +
            processedItems.join(",\n") +
            "\n";

        return (
            sql.slice(0, parts.selectStart + 6) +
            newSelectBody +
            sql.slice(parts.fromStart)
        );
    },

    /**************************************************************************
        SQL Generation
    **************************************************************************/

    async generatePivotQuery()
    {
        if (!this.validateWorkspace())
        {
            return;
        }

        const connection =
            this.connections.find(
                item =>
                    item.id ===
                    this.selectedConnectionId
            );

        if (!connection)
        {
            alert(
                "Please select a database connection."
            );

            return;
        }

        /*
            The first database operation against a password-authenticated
            connection establishes the password for this browser session.
            Subsequent operations on the same connection do not prompt.
        */
        if (!await this.ensureConnectionPassword(connection))
        {
            return;
        }

        this.generateJSON();

        /*
            Always regenerate the JSON immediately before sending the
            request. This prevents a stale generated_json field from being
            sent if the workspace changed since the last refresh.
        */
        this.refreshGeneratedJSON();

        const request =
        {
            database:
                document.querySelector(
                    'input[name="database"]:checked'
                ).value,

            connection:
            {
                databaseType: connection.databaseType,
                host: connection.host,
                port: connection.port,
                database: connection.database,
                authentication: connection.authentication,
                username: connection.username,
                password: connection.password
            },

            source_query:
                document.getElementById(
                    "source_query"
                ).value,

            generated_json:
                document.getElementById(
                    "generated_json"
                ).value
        };

        const generatedSql =
            document.getElementById(
                "generated_sql"
            );

        generatedSql.value = "";

        const generateButton =
            document.getElementById(
                "generate_sql_button"
            );

        /*
            The database request may take several seconds on a remote or
            slower host. Show the browser's busy cursor and prevent a
            second request until this one completes.
        */
        document.body.style.cursor = "wait";
        generateButton.style.cursor = "wait";
        generateButton.disabled = true;

        try
        {
            const response =
                await fetch(
                    "php/generate.php",
                    {
                        method: "POST",
                        headers:
                        {
                            "Content-Type":
                                "application/json"
                        },
                        body:
                            JSON.stringify(request)
                    }
                );

            const text =
                await response.text();

            if (!response.ok)
            {
                throw new Error(
                    text ||
                    "Database request failed."
                );
            }

            const processedSql =
                this.postProcessGeneratedSql(text);

            generatedSql.value =
                processedSql;

            this.showOutputWindow();

            generatedSql.focus();
        }
        catch (error)
        {
            /*
                If authentication failed, allow the next attempt to prompt
                again rather than trapping the user with a bad password.
            */
            delete this.passwordPromptedConnections[
                connection.id
            ];

            alert(
                "Pivot query generation failed.\\n\\n" +
                (error.message || error)
            );
        }
        finally
        {
            /*
                Restore normal interaction after the database request
                succeeds or fails.
            */
            document.body.style.cursor = "";
            generateButton.style.cursor = "";
            generateButton.disabled = false;
        }
    },

    validateWorkspace() {

        this.validationErrors =
        {
            groups: {},
            pivots: {}
        };

        /*
            Generate Pivot Query is the strict validation boundary.

            Easy Pivot remains permissive while the user is building a
            configuration. Field discovery is assistive only and is not
            used here to reject manually entered fields.
        */

        const sourceQuery =
            document.getElementById("source_query").value.trim();

        if (sourceQuery === "")
        {
            alert(
                "Cannot generate the pivot query.\n\n" +
                "Please enter a source SQL query."
            );

            return false;
        }

        if (this.workspace.groups.length === 0)
        {
            alert(
                "Cannot generate the pivot query.\n\n" +
                "Please add at least one Group."
            );

            return false;
        }

        if (this.workspace.pivotChips.length === 0)
        {
            alert(
                "Cannot generate the pivot query.\n\n" +
                "Please add at least one Pivot Chip."
            );

            return false;
        }

        /*
            A Group field must contain something. This normally cannot
            happen through the UI because saveGroup() already enforces it,
            but it can occur in a loaded configuration.
        */
        for (
            let index = 0;
            index < this.workspace.groups.length;
            index++
        )
        {
            const group =
                this.workspace.groups[index];

            if (
                !group ||
                typeof group.field !== "string" ||
                group.field.trim() === ""
            )
            {
                this.validationErrors.groups[index] =
                    "This Group has no field.";
            }
        }

        const validGroups =
            this.workspace.groups
                .filter(
                    group =>
                        group &&
                        typeof group.field === "string" &&
                        group.field.trim() !== ""
                )
                .map(group => group.field);

        for (
            let index = 0;
            index < this.workspace.pivotChips.length;
            index++
        )
        {
            const pivot =
                this.workspace.pivotChips[index];

            if (
                !pivot ||
                typeof pivot.field !== "string" ||
                pivot.field.trim() === ""
            )
            {
                this.validationErrors.pivots[index] =
                    "This Pivot Chip has no field.";

                continue;
            }

            if (
                !pivot.type ||
                typeof pivot.type !== "string" ||
                pivot.type.trim() === ""
            )
            {
                this.validationErrors.pivots[index] =
                    "This Pivot Chip has no aggregate type.";

                continue;
            }

            if (
                pivot.type.toUpperCase() !== "BOOLEAN" &&
                (
                    typeof pivot.dataField !== "string" ||
                    pivot.dataField.trim() === ""
                )
            )
            {
                this.validationErrors.pivots[index] =
                    "This Pivot Chip requires a data field.";

                continue;
            }

            /*
                At generation time a field cannot be both a Group and
                a Pivot field.
            */
            if (validGroups.includes(pivot.field))
            {
                this.validationErrors.pivots[index] =
                    "This Pivot field is also a Group field.";

                continue;
            }

            /*
                Follows is a real structural relationship. If it names a
                Group that does not exist, the Pivot cannot be generated.
            */
            if (
                pivot.follows &&
                !validGroups.includes(pivot.follows)
            )
            {
                this.validationErrors.pivots[index] =
                    'This Pivot follows "' +
                    pivot.follows +
                    '", but that Group does not exist.';

                continue;
            }
        }

        /*
            Show all identified row errors at once instead of stopping at
            the first bad row.
        */
        if (
            Object.keys(this.validationErrors.groups).length > 0 ||
            Object.keys(this.validationErrors.pivots).length > 0
        )
        {
            this.refreshGroups();
            this.refreshPivotChips();

            alert(
                "Cannot generate the pivot query.\n\n" +
                "One or more Groups or Pivot Chips need attention. " +
                "The invalid row(s) have been highlighted."
            );

            return false;
        }

        const connection =
            this.connections.find(
                item => item.id === this.selectedConnectionId
            );

        if (!connection)
        {
            alert("Please select a database connection.");

            return false;
        }

        return true;
    },

    /**************************************************************************
        Output Window
    **************************************************************************/

    copyOutputToClipboard()
    {

        const text =
            document.getElementById("generated_sql").value;

        const button =
            document.getElementById("copy_button");

        const showCopied =
            () =>
            {
                button.textContent = "Copied!";

                setTimeout(() =>
                {
                    button.textContent = "Copy to Clipboard";
                }, 1000);
            };

        const fallbackCopy =
            () =>
            {
                const textarea =
                    document.createElement("textarea");

                textarea.value = text;
                textarea.setAttribute("readonly", "");
                textarea.style.position = "fixed";
                textarea.style.left = "-9999px";

                document.body.appendChild(textarea);

                textarea.select();
                textarea.setSelectionRange(0, textarea.value.length);

                const successful =
                    document.execCommand("copy");

                document.body.removeChild(textarea);

                if (!successful)
                {
                    throw new Error("Clipboard copy failed.");
                }
            };

        if (
            navigator.clipboard &&
            typeof navigator.clipboard.writeText === "function"
        )
        {
            navigator.clipboard
                .writeText(text)
                .then(showCopied)
                .catch(err =>
                {
                    console.warn(
                        "Clipboard API failed; trying fallback:",
                        err
                    );

                    try
                    {
                        fallbackCopy();
                        showCopied();
                    }
                    catch (fallbackError)
                    {
                        console.error(
                            "Clipboard copy failed:",
                            fallbackError
                        );
                    }
                });
        }
        else
        {
            try
            {
                fallbackCopy();
                showCopied();
            }
            catch (err)
            {
                console.error(
                    "Clipboard copy failed:",
                    err
                );
            }
        }
    },

    toggleWorkspace(hidden) {

        document
            .getElementById("application_workspace")
            .classList.toggle("workspace-hidden", hidden);

        document
            .body
            .classList.toggle("workspace-hidden", hidden);

    },

    showOutputWindow() {

        document
            .getElementById("output_overlay")
            .style.display = "block";

    },

    hideOutputWindow() {

        document
            .getElementById("output_overlay")
            .style.display = "none";

        document
            .getElementById("generated_sql")
            .value = "";
    }

};


/******************************************************************************
    Application Entry Point
******************************************************************************/

window.addEventListener(
    "DOMContentLoaded",
    () => EasyPivot.init()
);
