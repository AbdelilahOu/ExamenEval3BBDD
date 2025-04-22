**Complete Database Exam Revision Notes (Comprehensive)**

**Introduction**

This document provides a comprehensive overview of key database concepts, including views, user/role management, stored functions, stored procedures, triggers, and scheduled events. It utilizes the schemas from the `exa3evaGeografia` and `Exa3EvaPizzeria` databases referenced in your exam, offering detailed explanations, use cases, syntax breakdowns, and complete code examples for each topic.

**I. Database Schemas Referenced**

**A. `exa3evaGeografia` Database**

- **`Localidades` (Localities/Towns):** Stores information about individual towns or municipalities.
  - `id_localidad` (INT PK): Unique identifier for the locality.
  - `nombre` (VARCHAR): Name of the locality (e.g., 'Bilbao').
  - `poblacion` (BIGINT): Number of inhabitants.
  - `n_provincia` (INT FK -> Provincias): Identifier linking to the province it belongs to.
- **`Provincias` (Provinces):** Stores information about provinces.
  - `n_provincia` (INT PK): Unique identifier for the province.
  - `nombre` (VARCHAR): Name of the province (e.g., 'Bizkaia').
  - `superficie` (DECIMAL): Area of the province in km².
  - `id_capital` (INT FK -> Localidades): Identifier of the capital city of the province.
  - `id_comunidad` (INT FK -> Comunidades): Identifier linking to the autonomous community it belongs to.
- **`Comunidades` (Autonomous Communities):** Stores information about Spain's autonomous communities.
  - `id_comunidad` (INT PK): Unique identifier for the community.
  - `nombre` (VARCHAR): Name of the community (e.g., 'País Vasco', 'Comunidad de Madrid').
  - `id_capital` (INT FK -> Localidades): Identifier of the capital city of the community.

**B. `Exa3EvaPizzeria` Database**

- **`Cliente` (Customer):** Stores customer details.
  - `DNI` (VARCHAR PK): Unique identifier for the customer.
  - `nombre`, `direccion`, etc.: Other customer details.
  - `ultimo_pedido` (TIMESTAMP): Timestamp of the customer's last order.
  - `num_pedidos` (INT): Total count of orders placed by the customer.
- **`Pedido` (Order):** Stores information about each order placed.
  - `num_pedido` (INT PK): Unique identifier for the order.
  - `fechahora` (TIMESTAMP): Timestamp when the order was placed.
  - `dni_cliente` (VARCHAR FK -> Cliente): Identifier linking to the customer who placed the order.
  - `importe` (DECIMAL): Total cost of the order.
- **`Pizza`:** Stores details about available pizzas.
  - `nom_pizza` (VARCHAR PK): Unique name/identifier for the pizza.
  - `tiempo_prep` (INT): Preparation time in minutes.
  - `precio` (DECIMAL): Price of the pizza.
  - `num_pedidos` (INT): Counter for how many times this pizza has been included in orders.
  - `num_unidades` (INT): Counter for the total quantity of this pizza sold.
- **`LineaPedido` (Order Line):** Links orders to pizzas and specifies quantities.
  - (Likely structure) `num_pedido` (INT FK -> Pedido), `nom_pizza` (VARCHAR FK -> Pizza), `unidades` (INT), `ing_adicional` (VARCHAR), `unidades_ing_adicional` (INT).
- **(Assumed for examples) `ActivityLog`:** Simple logging table.
  - `log_id` (INT PK AUTO_INCREMENT)
  - `log_time` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
  - `metric_name` (VARCHAR)
  - `metric_value` (INT or VARCHAR)
- **(Assumed for examples) `AdminLog`:** Simple administrative logging table.
  - `log_id` (INT PK AUTO_INCREMENT)
  - `log_time` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
  - `message` (TEXT)

---

**II. Views**

- **Concept:** A view is a virtual table whose content is defined by a query. It acts like a real table but does not store data itself (unless indexed/materialized, which is an advanced topic). The data is generated dynamically when the view is queried.
- **Use Cases:**
  - **Simplification:** Hide complex joins and calculations behind a simple name.
  - **Security:** Restrict access to specific rows or columns of underlying tables. Grant users access to the view instead of the base tables.
  - **Logical Data Independence:** Shield users/applications from changes in the base table structure. If a table is restructured, only the view definition might need updating, not the queries using the view.
  - **Data Presentation:** Present data in a format different from the base tables.
- **Syntax:**
  ```sql
  CREATE [OR REPLACE] VIEW view_name [(column_list)] -- column_list is optional
  AS
  SELECT statement; -- The query that defines the view's content
  ```
- **Example (`VLocalidadesVascas`):** Show Basque locality names, populations, and province names.
  - **Tables Used:** `Localidades`, `Provincias`, `Comunidades`
  ```sql
  CREATE OR REPLACE VIEW VLocalidadesVascas (NomLoc, PobLoc, NomProv)
  AS
  SELECT
      l.nombre,       -- Locality name from Localidades (aliased l)
      l.poblacion,    -- Locality population from Localidades
      p.nombre        -- Province name from Provincias (aliased p)
  FROM
      Localidades l
  JOIN
      Provincias p ON l.n_provincia = p.n_provincia -- Link based on province ID
  JOIN
      Comunidades c ON p.id_comunidad = c.id_comunidad -- Link based on community ID
  WHERE
      c.nombre = 'País Vasco'; -- Filter for the Basque Country
  ```
- **Dropping:** `DROP VIEW [IF EXISTS] view_name;`

---

**III. Updating Data Through Views**

- **Concept:** You can issue `INSERT`, `UPDATE`, or `DELETE` statements against some views, and the database will attempt to apply these changes to the underlying base tables.
- **Restrictions:** Updatability depends heavily on the database system and the view's complexity. Generally:
  - Views based on a single table are usually updatable.
  - Views with joins might be updatable if the modification affects only one of the base tables and the primary key(s) of that table are included or derivable.
  - Views using aggregate functions (`SUM`, `COUNT`, etc.), `GROUP BY`, `HAVING`, or `DISTINCT` are generally _not_ updatable.
- **Example (Updating Bilbao's Population via `VLocalidadesVascas`):**
  - **View Used:** `VLocalidadesVascas`
  - **Table Modified:** `Localidades` (specifically the `poblacion` column for the row where `nombre` is 'Bilbao'). This works because the update clearly targets one column in one base table identified by a column from the same base table.
  ```sql
  UPDATE VLocalidadesVascas
  SET PobLoc = 355000    -- This updates Localidades.poblacion
  WHERE NomLoc = 'Bilbao'; -- This uses Localidades.nombre to find the row
  ```

---

**IV. Roles and Privileges**

- **Concept:**
  - **Privileges:** Specific permissions granted to users or roles, defining what actions they can perform on database objects (e.g., `SELECT` data from a table, `INSERT` new rows, `EXECUTE` a procedure, `CREATE` new tables).
  - **Roles:** Named collections of privileges. Granting a role to a user gives them all the privileges associated with that role. This simplifies managing permissions for multiple users with similar access needs.
- **Creating Roles:**
  ```sql
  CREATE ROLE role_name;
  ```
- **Granting Privileges:**

  ```sql
  GRANT privilege1, privilege2, ...
  ON object_type object_name -- e.g., TABLE Localidades, DATABASE exa3evaGeografia, PROCEDURE AddNewPizza
  TO role_name | 'user_name'@'host';

  -- Granting all privileges (use with caution!)
  GRANT ALL PRIVILEGES ON ... TO ...;
  ```

- **Example (`rolexamen`):** Allow querying all tables in `exa3evaGeografia`, plus specific DML rights on `Localidades`.

  - **Database:** `exa3evaGeografia`

  ```sql
  -- 1. Create the role
  CREATE ROLE rolexamen;

  -- 2. Grant SELECT privilege on each table to the role
  GRANT SELECT ON exa3evaGeografia.Localidades TO rolexamen;
  GRANT SELECT ON exa3evaGeografia.Provincias TO rolexamen;
  GRANT SELECT ON exa3evaGeografia.Comunidades TO rolexamen;

  -- 3. Grant INSERT and DELETE privileges on the Localidades table
  GRANT INSERT, DELETE ON exa3evaGeografia.Localidades TO rolexamen;

  -- 4. Grant UPDATE privilege specifically on the 'poblacion' column of Localidades
  GRANT UPDATE (poblacion) ON exa3evaGeografia.Localidades TO rolexamen;
  ```

- **Example (`rolprueba` Object Management Privileges):** Grant rights to create/manage database objects.

  - **Database:** `exa3evaGeografia`

  ```sql
  -- Assuming rolprueba exists: CREATE ROLE rolprueba;
  -- Grant permissions for Procedures and Functions (Routines)
  GRANT CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission to create Views
  GRANT CREATE VIEW ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission to create/drop Indexes on tables within the database
  GRANT INDEX ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission to create/alter/drop scheduled Events
  GRANT EVENT ON exa3evaGeografia.* TO rolprueba;
  ```

- **Revoking Privileges:** `REVOKE privilege(s) ON object FROM role_name | user_name;`
- **Dropping Roles:** `DROP ROLE [IF EXISTS] role_name;`

---

**V. User Management**

- **Concept:** Creating and managing user accounts that can connect to the database server. This involves setting authentication methods (passwords), defining resource limits, password policies, and granting necessary privileges, typically through roles.
- **Creating Users:**
  ```sql
  CREATE USER 'username'@'host' -- 'host' can be 'localhost', '%', IP, etc.
  IDENTIFIED BY 'password'
  [WITH resource_option ...]   -- e.g., MAX_USER_CONNECTIONS n
  [PASSWORD EXPIRE option ...]; -- e.g., PASSWORD EXPIRE INTERVAL n DAY
  ```
- **Assigning Roles to Users:**
  ```sql
  GRANT role_name1, role_name2, ...
  TO 'username'@'host';
  ```
- **Setting Default Role(s):** (Ensures role privileges are active on login)
  ```sql
  SET DEFAULT ROLE role_name1, ...
  TO 'username'@'host';
  -- SET DEFAULT ROLE ALL TO 'username'@'host'; -- Make all granted roles default
  ```
- **Example (`usuexamen`):** Create user `usuexamen` connecting locally, with specific limits, password expiry, and assigned `rolprueba`.

  ```sql
  -- 1. Create the user with password, connection limit, and password expiry
  CREATE USER 'usuexamen'@'localhost'
  IDENTIFIED BY 'asgbd'
  WITH MAX_USER_CONNECTIONS 3          -- Limit to 3 concurrent connections
  PASSWORD EXPIRE INTERVAL 40 DAY;    -- Password must be changed after 40 days

  -- 2. Grant the previously defined 'rolprueba' role to this user
  GRANT rolprueba TO 'usuexamen'@'localhost';

  -- 3. (Recommended) Set the granted role as the default active role for the user
  SET DEFAULT ROLE rolprueba TO 'usuexamen'@'localhost';
  ```

- **Modifying Users:** `ALTER USER 'username'@'host' [options];` (e.g., change password, limits)
- **Dropping Users:** `DROP USER [IF EXISTS] 'username'@'host';`

---

**VI. Stored Functions**

- **Detailed Concept:** A stored function is a named database object containing a block of SQL code designed specifically to perform a calculation or data lookup and **return a single scalar value** (e.g., a number, string, date, boolean). They encapsulate reusable logic and are typically invoked _within_ other SQL statements (like `SELECT`, `WHERE`, `SET`).
- **Key Characteristics:**
  - **Mandatory Single Return Value:** Defined using `RETURNS data_type`. The function body _must_ execute a `RETURN value;` statement that matches the declared type.
  - **Input Parameters (`IN`):** Primarily accept input parameters. `OUT` and `INOUT` are generally not supported or used.
  - **Usage in Expressions:** Designed to be used where a single value is expected in SQL (e.g., `SELECT MyFunc(col), ...`, `WHERE amount > CalculateTax(price)`).
  - **Side Effects (DML Restrictions):** Standard SQL generally prohibits functions called from within `SELECT` or `WHERE` clauses from modifying database data (`INSERT`, `UPDATE`, `DELETE`) to ensure query predictability. Some database systems relax this under certain conditions (e.g., if declared `MODIFIES SQL DATA`), but it's often discouraged in functions used within queries.
  - **Determinism:** Can be declared `DETERMINISTIC` (always returns the same output for the same input) or `NOT DETERMINISTIC` (output can vary, e.g., uses `NOW()`). This helps the query optimizer.
- **Use Cases:** Reusable formulas/calculations (tax, discounts), data formatting/manipulation (concatenating strings, parsing dates), simple data lookups, encapsulating calculation logic, improving query readability.
- **Syntax Breakdown (MySQL Example):**

  ```sql
  DELIMITER //

  CREATE FUNCTION function_name (
      parameter1 data_type, -- Parameters are IN by default
      parameter2 data_type,
      ...
  )
  RETURNS return_data_type -- The single data type the function will return
  [CHARACTERISTIC ...] -- e.g., DETERMINISTIC, READS SQL DATA, NOT DETERMINISTIC
  BEGIN
      -- Declare local variables if needed
      DECLARE variable1 data_type [DEFAULT value];
      DECLARE variable2 data_type;

      -- Function logic: Calculations, assignments, lookups (SELECT INTO)
      -- Control flow statements (IF, CASE, loops) can be used

      -- Ensure a value of the 'return_data_type' is returned
      RETURN calculated_or_looked_up_value;
  END //

  DELIMITER ;
  ```

- **Example (`Densidad`):** Calculate population density for a province.

  - **Database:** `exa3evaGeografia`

  ```sql
  DELIMITER //
  CREATE FUNCTION Densidad (nombre_prov VARCHAR(100))
  RETURNS DECIMAL(10, 2) -- Returns a number like 123.45
  READS SQL DATA -- Characteristic: Indicates the function reads data
  BEGIN
      DECLARE total_poblacion BIGINT DEFAULT 0;
      DECLARE superficie_prov DECIMAL(10, 2);
      DECLARE v_n_provincia INT;

      -- Find the province ID and surface area
      SELECT n_provincia, superficie INTO v_n_provincia, superficie_prov
      FROM Provincias
      WHERE nombre = nombre_prov
      LIMIT 1;

      -- Handle not found or invalid area
      IF v_n_provincia IS NULL OR superficie_prov IS NULL OR superficie_prov <= 0 THEN
          RETURN NULL; -- Return NULL if input is invalid or not found
      END IF;

      -- Calculate total population, handling NULL if no localities exist
      SELECT IFNULL(SUM(poblacion), 0) INTO total_poblacion
      FROM Localidades
      WHERE n_provincia = v_n_provincia;

      -- Return the density calculation
      RETURN total_poblacion / superficie_prov;
  END //
  DELIMITER ;

  -- Example Usage in a SELECT statement:
  SELECT
      nombre,
      superficie,
      Densidad(nombre) AS PopulationDensity
  FROM Provincias
  ORDER BY PopulationDensity DESC;
  ```

- **Example (`FormatLocalityName`):** Combine locality and province names.

  - **Database:** `exa3evaGeografia`

  ```sql
  DELIMITER //
  CREATE FUNCTION FormatLocalityName (p_id_localidad INT)
  RETURNS VARCHAR(255)
  READS SQL DATA
  DETERMINISTIC -- Assumes names don't change often relative to query execution
  BEGIN
      DECLARE loc_name VARCHAR(100);
      DECLARE prov_name VARCHAR(100);

      SELECT l.nombre, p.nombre INTO loc_name, prov_name
      FROM Localidades l
      JOIN Provincias p ON l.n_provincia = p.n_provincia
      WHERE l.id_localidad = p_id_localidad
      LIMIT 1;

      IF loc_name IS NULL THEN
          RETURN 'Unknown Locality ID';
      ELSE
          RETURN CONCAT(loc_name, ' (', prov_name, ')');
      END IF;
  END //
  DELIMITER ;

  -- Example Usage:
  SELECT id_localidad, FormatLocalityName(id_localidad) AS FullName
  FROM Localidades LIMIT 10;
  ```

- **Dropping/Altering:**
  - `DROP FUNCTION [IF EXISTS] function_name;`
  - `ALTER FUNCTION function_name [CHARACTERISTIC ...];` (Changing body/params often requires `DROP`+`CREATE`).

---

**VII. Stored Procedures**

- **Detailed Concept:** A stored procedure is a named group of one or more SQL statements, potentially including control flow logic (`IF`, loops), variable declarations, error handling, and transaction management, compiled and stored in the database. It is designed to perform a specific _action_ or _sequence of operations_. Procedures are executed explicitly using the `CALL` statement.
- **Key Characteristics:**
  - **No Mandatory Return Value:** Unlike functions, procedures are not required to return a value. Their primary purpose is often to execute actions.
  - **Parameter Modes:** Support `IN` (input, default), `OUT` (output, value assigned by procedure), and `INOUT` (input/output, modified by procedure) parameters, allowing them to return multiple values or modify input variables.
  - **Can Perform DML:** Can freely execute `INSERT`, `UPDATE`, `DELETE` statements to modify data.
  - **Can Return Result Sets:** Can contain `SELECT` statements whose results are sent directly back to the calling client application. A procedure can return multiple result sets.
  - **Transaction Control:** Can explicitly manage database transactions using `START TRANSACTION`, `COMMIT`, and `ROLLBACK`.
  - **Can Call Other Procedures/Functions:** Can invoke other stored routines.
- **Use Cases:** Encapsulating complex business logic/workflows, providing a secure API to database operations (grant `EXECUTE` only), improving performance for complex/repeated tasks, reducing network traffic by sending one `CALL` instead of many SQL statements, performing batch updates or administrative tasks.
- **Syntax Breakdown (MySQL Example):**

  ```sql
  DELIMITER //

  CREATE PROCEDURE procedure_name (
      [parameter_mode] parameter1 data_type, -- mode: IN, OUT, INOUT
      [parameter_mode] parameter2 data_type,
      ...
  )
  -- Optional characteristics (e.g., COMMENT 'string', SQL SECURITY DEFINER/INVOKER)
  BEGIN
      -- Declare local variables, cursors, condition handlers (optional)
      DECLARE variable1 data_type [DEFAULT value];
      DECLARE done INT DEFAULT FALSE;
      DECLARE cur CURSOR FOR SELECT ...;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

      -- Procedure logic: Control flow, DML, SELECT, variable assignments
      -- Example: Loop through results using a cursor
      OPEN cur;
      read_loop: LOOP
          FETCH cur INTO variable1;
          IF done THEN
              LEAVE read_loop;
          END IF;
          -- Process fetched data
          UPDATE some_table SET ... WHERE id = variable1;
      END LOOP;
      CLOSE cur;

      -- Example: Assign value to an OUT parameter
      -- SET out_parameter = some_calculated_value;

      -- Example: Return a result set to the client
      SELECT columnA, columnB FROM some_table WHERE condition;

  END //

  DELIMITER ;
  ```

- **Example (`ContarProvinciasComunidad`):** Count provinces and return message result set.

  - **Database:** `exa3evaGeografia`

  ```sql
  DELIMITER //
  CREATE PROCEDURE ContarProvinciasComunidad (IN nombre_com VARCHAR(100))
  BEGIN
      DECLARE prov_count INT;
      DECLARE v_id_comunidad INT;

      -- Find the Community ID
      SELECT id_comunidad INTO v_id_comunidad
      FROM Comunidades WHERE nombre = nombre_com LIMIT 1;

      -- Handle Community Not Found
      IF v_id_comunidad IS NULL THEN
          SELECT CONCAT('Comunidad Autónoma ''', nombre_com, ''' no encontrada.') AS Mensaje;
      ELSE
          -- Count Provinces for the found Community
          SELECT COUNT(*) INTO prov_count
          FROM Provincias WHERE id_comunidad = v_id_comunidad;

          -- Generate and return the message as a result set
          IF prov_count = 1 THEN
              SELECT CONCAT(nombre_com, ' es una comunidad autónoma uniprovincial') AS Mensaje;
          ELSE
              SELECT CONCAT('La comunidad ', nombre_com, ' consta de ', prov_count, ' provincias') AS Mensaje;
          END IF;
      END IF;
  END //
  DELIMITER ;

  -- How to Call:
  CALL ContarProvinciasComunidad('País Vasco');
  ```

- **Example (`GetProvinciaDetails` with `OUT` Params):** Retrieve details into variables.

  - **Database:** `exa3evaGeografia`

  ```sql
  DELIMITER //
  CREATE PROCEDURE GetProvinciaDetails (
      IN p_nombre_prov VARCHAR(100),
      OUT p_superficie DECIMAL(10, 2), -- Output: Area
      OUT p_id_comunidad INT,      -- Output: Community ID
      OUT p_found BOOLEAN         -- Output: Flag indicating success
  )
  BEGIN
      -- Initialize output parameters
      SET p_superficie = NULL;
      SET p_id_comunidad = NULL;
      SET p_found = FALSE;

      -- Attempt to retrieve data into OUT parameters
      SELECT superficie, id_comunidad INTO p_superficie, p_id_comunidad
      FROM Provincias
      WHERE nombre = p_nombre_prov
      LIMIT 1;

      -- Check if the SELECT found a row (updates OUT params only if found)
      IF p_superficie IS NOT NULL THEN -- Check if SELECT INTO succeeded
          SET p_found = TRUE;
      END IF;
  END //
  DELIMITER ;

  -- How to Call and retrieve OUT values (MySQL session variables):
  CALL GetProvinciaDetails('Bizkaia', @sf, @id_c, @fnd);
  SELECT @sf AS Surface, @id_c AS CommunityID, @fnd AS FoundStatus;

  CALL GetProvinciaDetails('NonExistentProvince', @sf, @id_c, @fnd);
  SELECT @sf, @id_c, @fnd; -- Will show NULLs and FALSE
  ```

- **Example (`AddNewPizza` Performing DML):** Safely add a new pizza.

  - **Database:** `Exa3EvaPizzeria`

  ```sql
  DELIMITER //
  CREATE PROCEDURE AddNewPizza (
      IN p_nom_pizza VARCHAR(50),
      IN p_tiempo_prep INT,
      IN p_precio DECIMAL(5, 2)
  )
  BEGIN
      -- Check if pizza already exists to prevent duplicates
      IF NOT EXISTS (SELECT 1 FROM Pizza WHERE nom_pizza = p_nom_pizza) THEN
          INSERT INTO Pizza (nom_pizza, tiempo_prep, precio, num_pedidos, num_unidades)
          VALUES (p_nom_pizza, p_tiempo_prep, p_precio, 0, 0); -- Initialize counters

          SELECT 'Pizza added successfully.' AS Result;
      ELSE
          SELECT 'Error: Pizza with this name already exists.' AS Result;
      END IF;
  END //
  DELIMITER ;

  -- How to Call:
  CALL AddNewPizza('Marinara Special', 10, 6.50);
  CALL AddNewPizza('Margarita', 15, 8.50); -- Call again to see the error message
  ```

- **Dropping/Altering:**
  - `DROP PROCEDURE [IF EXISTS] procedure_name;`
  - `ALTER PROCEDURE procedure_name [CHARACTERISTIC ...];` (Changing body/params often requires `DROP`+`CREATE`).

---

**VIII. Triggers**

- **Detailed Concept:** A trigger is a special type of stored procedure that the database automatically executes (fires) in response to specific Data Manipulation Language (DML) events (`INSERT`, `UPDATE`, `DELETE`) occurring on a particular table. Triggers can be defined to run `BEFORE` the DML operation attempts to modify the data (allowing modification of data or prevention of the operation) or `AFTER` the operation has successfully completed (useful for auditing or updating related data).
- **`NEW` and `OLD` Pseudo-Rows:**
  - `NEW`: Available in `INSERT` and `UPDATE` triggers. Represents the row data _as it will be_ after the insert or update. In `BEFORE` triggers, you can modify `NEW` values.
  - `OLD`: Available in `UPDATE` and `DELETE` triggers. Represents the row data _as it was_ before the update or delete operation. Values in `OLD` cannot be modified.
- **Use Cases:**
  - **Auditing:** Log changes made to sensitive tables into an audit log.
  - **Data Integrity/Validation:** Enforce complex business rules that cannot be handled by standard constraints (e.g., checking related tables before allowing an update).
  - **Derived Data Maintenance:** Automatically update summary columns or related tables when base data changes (like the `ultimo_pedido` example).
  - **Preventing Invalid Operations:** Cancel an operation under certain conditions (usually in a `BEFORE` trigger by signalling an error).
- **Syntax Breakdown (MySQL Example):**

  ```sql
  DELIMITER //

  CREATE TRIGGER trigger_name
  {BEFORE | AFTER} {INSERT | UPDATE | DELETE} -- Timing and Event
  ON table_name -- The table the trigger monitors
  FOR EACH ROW -- Executes the trigger body for every row affected by the DML
  BEGIN
      -- Trigger logic:
      -- Can use IF statements, declare variables, etc.
      -- Access row data using NEW.column_name and OLD.column_name

      -- Example: Check value in BEFORE UPDATE
      -- IF NEW.price < 0 THEN
      --     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Price cannot be negative.';
      -- END IF;

      -- Example: Modify data in BEFORE INSERT
      -- SET NEW.created_at = NOW();

      -- Example: Log change in AFTER UPDATE
      -- IF OLD.status <> NEW.status THEN
      --     INSERT INTO AuditLog (...) VALUES (OLD.id, OLD.status, NEW.status, NOW());
      -- END IF;
  END //

  DELIMITER ;
  ```

- **Example (`InsertarPedido`):** Update customer's last order time and order count when a new order is inserted.
  - **Database:** `Exa3EvaPizzeria`
  - **Triggering Table/Event:** `AFTER INSERT ON Pedido`
  - **Action:** Updates the `Cliente` table.
  ```sql
  DELIMITER //
  CREATE TRIGGER InsertarPedido
  AFTER INSERT ON Pedido -- Fires AFTER a successful INSERT on Pedido
  FOR EACH ROW -- Executes once for each inserted row
  BEGIN
      -- Update the customer record related to the new order
      UPDATE Cliente
      SET
          ultimo_pedido = NEW.fechahora,  -- Set last order timestamp from the NEW order
          num_pedidos = num_pedidos + 1   -- Increment the existing order count
      WHERE
          DNI = NEW.dni_cliente;          -- Find the customer using the DNI from the NEW order
  END //
  DELIMITER ;
  ```
- **Dropping:** `DROP TRIGGER [IF EXISTS] trigger_name;`

---

**IX. Events (Scheduled Events)**

- **Detailed Concept:** An event is a database object that executes a predefined task (one or more SQL statements, often a `CALL` to a stored procedure) according to a specified schedule. They are managed by the database's internal event scheduler, which must be enabled and running. Events automate routine tasks without requiring external cron jobs or task schedulers.
- **Key Characteristics:**
  - **Scheduled Execution:** Runs based on time – either once (`AT`) or repeatedly (`EVERY`).
  - **Automatic:** Once created and enabled, the database scheduler handles execution.
  - **Requires Scheduler Service:** The global `event_scheduler` variable (in MySQL) must be set to `ON` (requires appropriate privileges).
  - **Permissions:** Requires the `EVENT` privilege on the relevant database to manage events.
- **Use Cases:** Periodic database maintenance (optimizing tables, clearing logs), data archiving or purging, generating nightly/weekly reports or summaries, performing regular data aggregation, automated cleanup tasks.
- **Syntax Breakdown (MySQL Example):**

  ```sql
  -- Ensure scheduler is ON (typically done once by DBA)
  -- SET GLOBAL event_scheduler = ON;

  DELIMITER //

  CREATE EVENT [IF NOT EXISTS] event_name
  ON SCHEDULE schedule_definition -- REQUIRED: Defines when it runs
  [ON COMPLETION {PRESERVE | NOT PRESERVE}] -- PRESERVE needed for recurring
  [ENABLE | DISABLE | DISABLE ON SLAVE] -- Initial state
  [COMMENT 'Optional description string']
  DO
  event_body; -- The SQL statement(s) to execute

  -- schedule_definition examples:
  --   AT 'YYYY-MM-DD HH:MM:SS' [+ INTERVAL N unit] -- One time
  --   AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR      -- One time, 1 hour from now
  --   EVERY N unit                                -- Recurring (e.g., EVERY 1 DAY, EVERY 6 HOUR)
  --   EVERY N unit STARTS 'YYYY-MM-DD HH:MM:SS'   -- Recurring, specific start time
  --   EVERY N unit ENDS 'YYYY-MM-DD HH:MM:SS'     -- Recurring, specific end time

  -- event_body examples:
  --   DO CALL MyMaintenanceProcedure();
  --   DO DELETE FROM logs WHERE log_date < NOW() - INTERVAL 30 DAY;
  --   DO BEGIN
  --      -- Multiple statements require BEGIN...END
  --      CALL Step1Procedure();
  --      INSERT INTO LogTable(message) VALUES ('Step 1 complete');
  --      CALL Step2Procedure();
  --   END //

  DELIMITER ;
  ```

- **Example (`RegistrarGastoClienteEvento`):** Call a (fictional) procedure annually at year-end.
  - **Database:** `Exa3EvaPizzeria` (indirectly via procedure)
  ```sql
  -- Ensure scheduler is ON: SET GLOBAL event_scheduler = ON;
  DELIMITER //
  CREATE EVENT RegistrarGastoClienteEvento
  ON SCHEDULE
      EVERY 1 YEAR -- Frequency: Annual
      -- Start at 23:59:59 on Dec 31st of the current year
      STARTS STR_TO_DATE(CONCAT(YEAR(CURDATE()), '-12-31 23:59:59'), '%Y-%m-%d %H:%i:%s')
  ON COMPLETION PRESERVE -- Essential for recurring events
  ENABLE -- Make sure it's active
  COMMENT 'Calls RegistrarGastoCliente procedure annually at year end.'
  DO
  BEGIN
      -- It's good practice to log event execution
      -- INSERT INTO AdminLog (message) VALUES ('Executing RegistrarGastoClienteEvento');
      CALL RegistrarGastoCliente(); -- Call the procedure defined elsewhere
  END //
  DELIMITER ;
  ```
- **Example (`ArchiveOldOrders_OneTime`):** One-time cleanup.

  - **Database:** `Exa3EvaPizzeria`

  ```sql
  DELIMITER //
  CREATE EVENT ArchiveOldOrders_OneTime
  ON SCHEDULE
      -- Define specific one-time execution timestamp
      AT '2025-01-15 03:00:00' -- Example: Jan 15th, 2025 at 3 AM
  ON COMPLETION NOT PRESERVE -- Event definition is dropped after execution
  DISABLE -- Create disabled, enable manually later if needed: ALTER EVENT ... ENABLE;
  COMMENT 'One-time cleanup of orders older than 2 years as of Jan 2025.'
  DO
  BEGIN
      -- IMPORTANT: Assumes appropriate handling of LineaPedido (e.g., CASCADE DELETE FK)
      --            Or delete from LineaPedido first if no cascade.
      DECLARE cutoff_date TIMESTAMP;
      SET cutoff_date = '2023-01-15 00:00:00'; -- Orders before this date

      DELETE FROM Pedido WHERE fechahora < cutoff_date;

      INSERT INTO AdminLog (message)
      VALUES (CONCAT('ArchiveOldOrders_OneTime executed. Deleted orders before ', cutoff_date));
  END //
  DELIMITER ;
  ```

- **Example (`LogActiveCustomersHourly`):** Recurring logging.

  - **Database:** `Exa3EvaPizzeria`, `ActivityLog`

  ```sql
  /* -- Required table:
  CREATE TABLE ActivityLog ( log_id INT AUTO_INCREMENT PRIMARY KEY, log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, metric_name VARCHAR(50), metric_value INT ); */
  DELIMITER //
  CREATE EVENT LogActiveCustomersHourly
  ON SCHEDULE
      EVERY 1 HOUR
      -- Starts aligning roughly with the next full hour after creation
      STARTS CURRENT_TIMESTAMP + INTERVAL (60 - MINUTE(CURRENT_TIMESTAMP)) MINUTE
  ON COMPLETION PRESERVE
  ENABLE
  COMMENT 'Logs the count of customers with orders in last 30 days, hourly.'
  DO
  BEGIN
      DECLARE active_customer_count INT;

      SELECT COUNT(DISTINCT DNI) INTO active_customer_count -- Count unique customers
      FROM Cliente
      WHERE ultimo_pedido >= NOW() - INTERVAL 30 DAY; -- Definition of 'active'

      INSERT INTO ActivityLog (metric_name, metric_value)
      VALUES ('ActiveCustomersLast30Days', active_customer_count);
  END //
  DELIMITER ;
  ```

- **Managing Events:**
  - View Events: `SHOW EVENTS;` or `SELECT * FROM information_schema.EVENTS WHERE EVENT_SCHEMA = 'your_database_name';`
  - Drop Event: `DROP EVENT [IF EXISTS] event_name;`
  - Alter Event: `ALTER EVENT event_name [ON SCHEDULE ...] [RENAME TO new_name] [ENABLE | DISABLE] [COMMENT '...'] [DO event_body];`
  - Enable/Disable: `ALTER EVENT event_name ENABLE;`, `ALTER EVENT event_name DISABLE;`
