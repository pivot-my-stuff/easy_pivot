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

    saveConnectionsToFile()
    {
        const connections =
            this.connections.map(connection =>
            {
                const savedConnection =
                {
                    ...connection
                };

                /*
                    Passwords are intentionally excluded from exported
                    connection files. They remain available only for
                    the current browser session.
                */
                delete savedConnection.password;

                return savedConnection;
            });

        const configuration =
        {
            version: 1,
            selectedConnectionId:
                this.selectedConnectionId,
            connections: connections
        };

        this.downloadJsonFile(
            "easy_pivot_connections_" +
            this.getFileTimestamp() +
            ".json",
            configuration
        );
    },

    loadConnectionsFromFile()
    {
        this.openJsonFile(
            data =>
            {
                let importedConnections;

                let selectedConnectionId = "";

                /*
                    Accept both the current file format and a plain
                    connection array for simple backward compatibility.
                */
                if (Array.isArray(data))
                {
                    importedConnections = data;
                }
                else if (
                    data &&
                    Array.isArray(data.connections)
                )
                {
                    importedConnections =
                        data.connections;

                    if (
                        typeof data.selectedConnectionId ===
                        "string"
                    )
                    {
                        selectedConnectionId =
                            data.selectedConnectionId;
                    }
                }

                if (!importedConnections)
                {
                    alert(
                        "The selected file is not a valid Easy Pivot " +
                        "connections file."
                    );

                    return;
                }

                const validConnections =
                    importedConnections.filter(connection =>
                        connection &&
                        typeof connection.id === "string" &&
                        typeof connection.name === "string" &&
                        typeof connection.databaseType === "string" &&
                        typeof connection.host === "string" &&
                        Number.isInteger(Number(connection.port)) &&
                        typeof connection.database === "string" &&
                        typeof connection.username === "string"
                    );

                if (validConnections.length === 0)
                {
                    alert(
                        "The selected connections file contains no " +
                        "valid connections."
                    );

                    return;
                }

                validConnections.forEach(
                    importedConnection =>
                    {
                        /*
                            Local MySQL was a built-in connection in earlier
                            beta versions. Do not import that legacy record.
                        */
                        if (importedConnection.id === "local_mysql")
                        {
                            return;
                        }

                        const existing =
                            this.connections.find(
                                connection =>
                                    connection.id ===
                                    importedConnection.id
                            );

                        const imported =
                        {
                            ...importedConnection,
                            port:
                                Number(importedConnection.port)
                        };

                        if (existing)
                        {
                            const password =
                                existing.password || "";

                            Object.assign(
                                existing,
                                imported,
                                {
                                    password: password
                                }
                            );
                        }
                        else
                        {
                            this.connections.push(
                            {
                                ...imported,
                                password: ""
                            });
                        }
                    }
                );

                if (
                    selectedConnectionId &&
                    this.connections.some(
                        connection =>
                            connection.id ===
                            selectedConnectionId
                    )
                )
                {
                    this.selectedConnectionId =
                        selectedConnectionId;
                }

                this.saveConnections();
                this.refreshConnectionList();
                this.loadSelectedConnection();
                this.updateDeleteConnectionButton();

                alert(
                    "Connections loaded successfully."
                );
            }
        );
    },

    saveConfigurationToFile()
    {
        const configuration =
        {
            version: 1,
            database:
                this.workspace.database,
            selectedConnectionId:
                this.selectedConnectionId,
            sourceQuery:
                document.getElementById(
                    "source_query"
                ).value,
            groups:
                this.workspace.groups,
            pivotChips:
                this.workspace.pivotChips
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

                /*
                    Load the database selection first so the generated
                    JSON and aggregate lists use the correct database.
                */
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
                    discoverFields(..., false) rebuilds the derived
                    available-field list without wiping the loaded
                    Groups and Pivot Chips.
                */
                this.discoverFields(
                    sourceQuery,
                    false
                );

                /*
                    A configuration may refer to a connection saved in
                    a separate connections file. Use it when available;
                    otherwise retain the current connection for the
                    selected database.
                */
                if (
                    typeof data.selectedConnectionId === "string" &&
                    this.connections.some(
                        connection =>
                            connection.id ===
                                data.selectedConnectionId &&
                            connection.databaseType ===
                                data.database
                    )
                )
                {
                    this.selectedConnectionId =
                        data.selectedConnectionId;
                }
                else
                {
                    this.restoreDatabaseConnection();
                }

                this.refreshConnectionList();
                this.loadSelectedConnection();
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
            .getElementById("load_connections_button")
            .addEventListener(
                "click",
                () => this.loadConnectionsFromFile()
            );

        document
            .getElementById("save_connections_button")
            .addEventListener(
                "click",
                () => this.saveConnectionsToFile()
            );

        document
            .getElementById("load_configuration_button")
            .addEventListener(
                "click",
                () => this.loadConfigurationFromFile()
            );

        document
            .getElementById("save_configuration_button")
            .addEventListener(
                "click",
                () => this.saveConfigurationToFile()
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
                () => this.generatePivotQuery()
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
            () =>
            {
                const normalized =
                    this.normalizeSourceQuery(sourceQuery.value);

                if (sourceQuery.value !== normalized)
                {
                    sourceQuery.value = normalized;
                }

                if (normalized !== this.lastProcessedSourceQuery)
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
        const groupDatalist =
            document.getElementById("available_fields");

        groupDatalist.innerHTML = "";

        this.workspace.availableFields.forEach(field =>
        {
            const option = document.createElement("option");

            option.value = field;

            groupDatalist.appendChild(option);
        });

        let pivotDatalist =
            document.getElementById("pivot_available_fields");

        if (!pivotDatalist)
        {
            pivotDatalist =
                document.createElement("datalist");

            pivotDatalist.id =
                "pivot_available_fields";

            document.body.appendChild(pivotDatalist);
        }

        pivotDatalist.innerHTML = "";

        const groupFields =
            new Set(
                this.workspace.groups.map(
                    group => group.field
                )
            );

        this.workspace.availableFields
            .filter(field => !groupFields.has(field))
            .forEach(field =>
            {
                const option =
                    document.createElement("option");

                option.value = field;

                pivotDatalist.appendChild(option);
            });

        document
            .getElementById("pivot_field")
            .setAttribute(
                "list",
                "pivot_available_fields"
            );

        document
            .getElementById("pivot_data_field")
            .setAttribute(
                "list",
                "pivot_available_fields"
            );

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

    discoverFields(sql, resetWorkspace = true)
    {
        sql = this.normalizeSourceQuery(sql);

        this.lastProcessedSourceQuery = sql;

        // A normal query change starts a new project.
        // Configuration loading can preserve the loaded Groups/Pivot Chips.

        if (resetWorkspace)
        {
            this.workspace.groups = [];

            this.workspace.pivotChips = [];
        }

        this.workspace.availableFields = [];

        const parts =
            this.findOuterSelectParts(sql);

        if (!parts)
        {
            this.refreshWorkspace();
            return;
        }

        const selectList =
            sql.substring(
                parts.selectStart + 6,
                parts.fromStart
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

    splitSelectExpressions(selectList)
    {
        const expressions = [];

        let expression = "";

        let level = 0;

        for (const ch of selectList)
        {
            switch (ch)
            {
                case "(":
                    level++;
                    expression += ch;
                    break;

                case ")":
                    level--;
                    expression += ch;
                    break;

                case ",":

                    if (level === 0)
                    {
                        expressions.push(expression.trim());
                        expression = "";
                    }
                    else
                    {
                        expression += ch;
                    }

                    break;

                default:
                    expression += ch;
            }
        }

        if (expression.trim() !== "")
        {
            expressions.push(expression.trim());
        }

        return expressions;
    },

    discoverFieldName(expression)
    {
        let match;

        //
        // Explicit AS alias
        //

        //
        // SQL Server
        //

        match =
            expression.match(/\s+AS\s+\[([^\]]+)\]$/i);

        if (match)
        {
            return match[1];
        }

        //
        // Oracle / PostgreSQL
        //

        match =
            expression.match(/\s+AS\s+"([^"]+)"$/i);

        if (match)
        {
            return match[1];
        }

        //
        // MySQL
        //

        match =
            expression.match(/\s+AS\s+`([^`]+)`$/i);

        if (match)
        {
            return match[1];
        }

        //
        // Simple identifier
        //

        match =
            expression.match(/\s+AS\s+(\w+)$/i);

        if (match)
        {
            return match[1];
        }

        if (match)
        {
            return match[1];
        }

        //
        // Implicit alias
        //

        if (expression.includes("("))
        {
            match =
                expression.match(/.+\s+(\w+)$/);

            if (match)
            {
                return match[1];
            }
        }

        //
        // Backtick identifiers
        //

        match =
            expression.match(/`([^`]+)`\s*$/);

        if (match)
        {
            return match[1];
        }

        //
        // Plain column
        //

        match =
            expression.match(/([A-Za-z_][A-Za-z0-9_]*)\s*$/);

        if (match)
        {
            return match[1];
        }

        return "";
    },

    /******************************************************************************
        Group Dialog
    ******************************************************************************/

    showGroupDialog() {

        document.getElementById("group_field").value = "";

        document.getElementById("group_sort_asc").checked = true;

        document.getElementById("group_dialog").style.display = "block";

        document.getElementById("group_field").focus();

    },

    hideGroupDialog() {

        document.getElementById("group_dialog").style.display = "none";

    },

    /******************************************************************************
        Groups
    ******************************************************************************/

    addGroup() {

        this.showGroupDialog();

    },

    saveGroup() {

        const field =
            document.getElementById("group_field").value.trim();

        if (field === "") {

            alert("Please enter a group field.");

            return;

        }

        const sort =
            document.getElementById("group_sort_desc").checked
                ? "DESC"
                : "ASC";

        const group = {

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

        console.log("Generate JSON");

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

        console.log("Refresh Generate Button");

    },

    /**************************************************************************
        Generated SQL Presentation
    **************************************************************************/

    splitTopLevelSelectItems(selectBody)
    {
        const items = [];

        let start = 0;
        let depth = 0;
        let quote = null;

        for (let i = 0; i < selectBody.length; i++)
        {
            const ch = selectBody[i];

            if (quote)
            {
                if (ch === quote)
                {
                    if (quote === "`" && selectBody[i + 1] === "`")
                    {
                        i++;
                    }
                    else if (quote !== "`" && selectBody[i + 1] === quote)
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

            if (ch === "'" || ch === '"' || ch === "`")
            {
                quote = ch;
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

            if (ch === "," && depth === 0)
            {
                items.push(selectBody.slice(start, i).trim());
                start = i + 1;
            }
        }

        const finalItem =
            selectBody.slice(start).trim();

        if (finalItem !== "")
        {
            items.push(finalItem);
        }

        return items;
    },

    findOuterSelectParts(sql)
    {
        let depth = 0;
        let quote = null;
        let selectStart = -1;
        let fromStart = -1;

        for (let i = 0; i < sql.length; i++)
        {
            const ch = sql[i];

            if (quote)
            {
                if (ch === quote)
                {
                    if (quote === "`" && sql[i + 1] === "`")
                    {
                        i++;
                    }
                    else if (quote !== "`" && sql[i + 1] === quote)
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

            if (ch === "'" || ch === '"' || ch === "`")
            {
                quote = ch;
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

            if (depth !== 0)
            {
                continue;
            }

            const remainder =
                sql.slice(i);

            if (selectStart === -1 &&
                /^SELECT\b/i.test(remainder))
            {
                selectStart = i;
                i += 5;
                continue;
            }

            if (selectStart !== -1 &&
                /^FROM\b/i.test(remainder))
            {
                fromStart = i;
                break;
            }
        }

        if (selectStart === -1 || fromStart === -1)
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
        const match =
            expression.match(
                /\s+AS\s+[`"\[]?([^`"\]]+)[`"\]]?\s*$/i
            );

        return match
            ? match[1].trim()
            : "";
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

    () => EasyPivot.init(),

    document.getElementById("source_query").value = ""

);
