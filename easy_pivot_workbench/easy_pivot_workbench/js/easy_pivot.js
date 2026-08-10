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

    /**************************************************************************
        Connection UI
    **************************************************************************/

    connections: [
        {
            id: "local_mysql",
            name: "Local MySQL",
            databaseType: "mysql",
            host: "localhost",
            port: 3306,
            authentication: "password",
            username: "root",
            password: "",
            database: "easy_pivot"
        }
    ],

    selectedConnectionId: "local_mysql",

    selectedConnectionsByDatabase:
    {
        mysql: "local_mysql",
        oracle: "",
        postgresql: "",
        sqlserver: ""
    },

    previousConnectionId: "",

    temporaryConnectionId: "",

    /**************************************************************************
        Initialization
    **************************************************************************/

    init() {

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
                    The built-in Local MySQL connection is always retained.

                    Earlier versions could accidentally save a YETI
                    connection under the built-in "local_mysql" ID.
                    If that happened, migrate the saved connection to a
                    new ID instead of overwriting Local MySQL.
                */
                if (
                    savedConnection.id === "local_mysql" &&
                    savedConnection.name !== "Local MySQL"
                )
                {
                    const migratedConnection =
                    {
                        ...savedConnection,
                        id:
                            "connection_migrated_" +
                            Date.now() +
                            "_" +
                            Math.random()
                                .toString(36)
                                .substring(2, 8),
                        port:
                            Number(savedConnection.port),
                        password: ""
                    };

                    this.connections.push(
                        migratedConnection
                    );

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
                this.connections.some(
                    connection =>
                        connection.id === savedSelectedId
                )
            )
            {
                /*
                    If the selected connection was the old
                    local_mysql record that contained YETI, select
                    the migrated connection instead.
                */
                if (
                    savedSelectedId === "local_mysql" &&
                    validConnections.some(
                        connection =>
                            connection.id === "local_mysql" &&
                            connection.name !== "Local MySQL"
                    )
                )
                {
                    const migrated =
                        this.connections
                            .slice()
                            .reverse()
                            .find(
                                connection =>
                                    connection.id !== "local_mysql" &&
                                    connection.name !== "Local MySQL" &&
                                    connection.databaseType ===
                                        this.workspace.database
                            );

                    if (migrated)
                    {
                        this.selectedConnectionId =
                            migrated.id;
                    }
                }
                else
                {
                    this.selectedConnectionId =
                        savedSelectedId;
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
            this.selectedConnectionId === "local_mysql" ||
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
                authentication: "password",
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

        if (!connection.username)
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

        if (connection.id === "local_mysql")
        {
            alert(
                "Local MySQL is a built-in connection and cannot be deleted."
            );

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

        if (!values.username)
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
                databaseType: this.workspace.database,
                host: values.host,
                port: values.port,
                authentication: values.authentication,
                username: values.username,
                password: values.password,
                database: values.database
            };

            this.connections.push(connection);
        }
        else
        {
            Object.assign(
                connection,
                values
            );
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
                () => this.showConnectionDialog()
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
                        this.refreshWorkspace();
                    });
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

    discoverFields(sql)
    {
        sql = this.normalizeSourceQuery(sql);

        this.lastProcessedSourceQuery = sql;

        // New query = new project

        this.workspace.groups = [];

        this.workspace.pivotChips = [];

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

    generatePivotQuery() {

        if (!this.validateWorkspace())
        {
            return;
        }

        this.generateJSON();

        this.showOutputWindow();

    },

    validateWorkspace() {

        if (this.workspace.pivotChips.length === 0)
        {
            alert("Please add at least one Pivot Chip.");

            return false;
        }

        const validGroups = this.workspace.groups.map(group => group.field);

        for (const pivot of this.workspace.pivotChips)
        {
            if (pivot.follows &&
                !validGroups.includes(pivot.follows))
            {
                alert(
                    "Cannot generate the pivot query.\n\n" +
                    'Pivot "' + pivot.field + ' (' + pivot.type + ')" follows "' +
                    pivot.follows + '", but that Group no longer exists.\n\n' +
                    "You may:\n\n" +
                    "• Add the Group back.\n" +
                    "• Edit the Pivot Chip and choose another Follows Group.\n" +
                    "• Delete the Pivot Chip if it is no longer needed."
                );

                return false;
            }

            if (validGroups.includes(pivot.field))
            {
                alert(
                    "Cannot generate the pivot query.\n\n" +
                    'Pivot field "' + pivot.field + '" is also a Group field.\n\n' +
                    "A field cannot be used as both a Group and a Pivot Field.\n\n" +
                    "You may:\n\n" +
                    "• Edit the Pivot Chip and choose another field.\n" +
                    "• Remove the Group if it is no longer needed.\n" +
                    "• Delete the Pivot Chip if it is no longer needed."
                );

                return false;
            }
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

        const request = {
            database: document.querySelector('input[name="database"]:checked').value,
            connection: {
                host: connection.host,
                port: connection.port,
                database: connection.database,
                authentication: connection.authentication,
                username: connection.username,
                password: connection.password
            },
            source_query: document.getElementById("source_query").value,
            generated_json: document.getElementById("generated_json").value
        };

        fetch("php/generate.php", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(request)
        })
        .then(async response =>
        {
            const text = await response.text();

            if (!response.ok)
            {
                throw new Error(text || "Database request failed.");
            }

            return text;
        })
        .then(text => {
            const generatedSql =
                document.getElementById("generated_sql");

            const processedSql =
                this.postProcessGeneratedSql(text);

            generatedSql.value = processedSql;

            document.getElementById("output_overlay").style.display = "flex";

            generatedSql.focus();
        })
        .catch(error => {
            alert(error.message || error);
        });

        return true;

    },

    /**************************************************************************
        Output Window
    **************************************************************************/

    copyOutputToClipboard()
    {

        const text =
            document.getElementById("generated_sql").value;

        navigator.clipboard
            .writeText(text)
            .then(() =>
            {
                const button =
                    document.getElementById("copy_button");

                button.textContent = "Copied!";

                setTimeout(() =>
                {
                    button.textContent = "Copy to Clipboard";
                }, 1000);
            })
            .catch(err =>
            {
                console.error("Clipboard copy failed:", err);
            });
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
