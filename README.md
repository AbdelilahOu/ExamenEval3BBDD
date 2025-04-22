**Database Exam Revision Notes (Based on Provided Exam)**

This guide covers key concepts in Views, User/Role Management, Stored Procedures, Stored Functions, Triggers, and Events, using examples directly from your exam questions.

**1. Views**

- **Concept:** A view is a virtual table based on the result-set of an SQL query. It doesn't store data itself but provides a named, reusable query structure. Views can simplify complex queries, restrict access to data (show only certain columns/rows), and present data from multiple tables as a single entity.
- **Creating Views:** Use `CREATE VIEW`. You can optionally specify column names for the view.
  - **Syntax:** `CREATE VIEW view_name (col1, col2, ...) AS SELECT ...;`
- **Example (`VLocalidadesVascas` - UD10, Q1):** Create a view showing Basque locality names, populations, and their province names.
  ```sql
  CREATE VIEW VLocalidadesVascas (NomLoc, PobLoc, NomProv) AS
  SELECT
      l.nombre,       -- Locality name from Localidades table (aliased as l)
      l.poblacion,    -- Locality population from Localidades
      p.nombre        -- Province name from Provincias table (aliased as p)
  FROM
      Localidades l
  JOIN
      Provincias p ON l.n_provincia = p.n_provincia -- Connect localities to provinces
  JOIN
      Comunidades c ON p.id_comunidad = c.id_comunidad -- Connect provinces to communities
  WHERE
      c.nombre = 'País Vasco'; -- Filter for the specific community
  ```
- **Key Techniques Used:**
  - `JOIN`: Combining rows from multiple tables based on related columns (`n_provincia`, `id_comunidad`).
  - `WHERE`: Filtering results based on a condition (`c.nombre = 'País Vasco'`).
  - Column Aliasing: Defining specific names for the view's columns (`NomLoc`, `PobLoc`, `NomProv`).
  - Table Aliasing: Using short names for tables (`l`, `p`, `c`) for readability.

**2. Updating Data Through Views**

- **Concept:** You can sometimes use `UPDATE`, `INSERT`, or `DELETE` statements on a view, which will modify the underlying base table(s). However, this is subject to restrictions. Generally, simple views based on a single table are updatable. Views involving joins might be updatable if the modification unambiguously targets a single base table.
- **Example (Updating Bilbao's Population - UD10, Q1.1):** Modifying data using the previously created view.
  ```sql
  UPDATE VLocalidadesVascas
  SET PobLoc = 355000
  WHERE NomLoc = 'Bilbao';
  ```
- **Why it Works (Likely):** The `PobLoc` column in the view directly maps to the `poblacion` column in the `Localidades` table, and the `NomLoc` maps to `nombre` in the same table. The update targets a single row in a single base table.

**3. Roles and Privileges**

- **Concept:** Roles are named collections of privileges. Instead of granting individual permissions to many users, you grant permissions to a role, and then grant the role to users. This simplifies permission management. Privileges define what actions a user/role can perform (e.g., `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE VIEW`, `EXECUTE`).
- **Creating Roles:**
  - **Syntax:** `CREATE ROLE role_name;`
- **Granting Privileges:** Use `GRANT`. Privileges can be granted on different levels (database, table, column).
  - **Syntax:** `GRANT privilege(s) ON object_level TO role_name;`
- **Example (`rolexamen` - UD10, Q2):** Create a role for querying all tables, plus INSERT/DELETE/UPDATE(population) on `Localidades`.

  ```sql
  -- Create the role
  CREATE ROLE rolexamen;

  -- Grant SELECT on all tables in the database (example for specific tables)
  GRANT SELECT ON exa3evaGeografia.Localidades TO rolexamen;
  GRANT SELECT ON exa3evaGeografia.Provincias TO rolexamen;
  GRANT SELECT ON exa3evaGeografia.Comunidades TO rolexamen;
  -- Note: GRANT SELECT ON database.* TO role; is a shorthand if supported.

  -- Grant specific DML on Localidades
  GRANT INSERT, DELETE ON exa3evaGeografia.Localidades TO rolexamen;

  -- Grant UPDATE only on a specific column
  GRANT UPDATE (poblacion) ON exa3evaGeografia.Localidades TO rolexamen;
  ```

- **Example (`rolprueba` Privileges - UD10, Q3.1):** Granting permissions to manage database objects.

  ```sql
  -- Grant permissions for procedures/functions
  GRANT CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission for views
  GRANT CREATE VIEW ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission for indexes
  GRANT INDEX ON exa3evaGeografia.* TO rolprueba; -- Create/Drop indexes

  -- Grant permission for events
  GRANT EVENT ON exa3evaGeografia.* TO rolprueba; -- Create/Alter/Drop events
  ```

  _Note: `ON exa3evaGeografia._` applies the grant to all objects (or potential objects) of that type within the database.\*

**4. User Management**

- **Concept:** Database users are accounts that connect to the database server, usually requiring authentication (password). Users are assigned privileges, often through roles. You can set resource limits and password policies for users.
- **Creating Users:** Use `CREATE USER`. Specify username, host (where the user can connect from - `localhost`, `%` for any), and password.
  - **Syntax:** `CREATE USER 'username'@'host' IDENTIFIED BY 'password';`
- **Setting Policies/Limits:** Add clauses to `CREATE USER` (or use `ALTER USER`).
  - `WITH MAX_USER_CONNECTIONS count`: Limits simultaneous connections.
  - `PASSWORD EXPIRE INTERVAL days DAY`: Forces password change after a period.
- **Assigning Roles:** Use `GRANT`.
  - **Syntax:** `GRANT role_name TO 'username'@'host';`
- **Example (`usuexamen` - UD10, Q3):** Create a user with specific limits, policy, and assign `rolprueba`.

  ```sql
  CREATE USER 'usuexamen'@'localhost'
  IDENTIFIED BY 'asgbd'
  WITH MAX_USER_CONNECTIONS 3
  PASSWORD EXPIRE INTERVAL 40 DAY;

  GRANT rolprueba TO 'usuexamen'@'localhost';
  ```

**5. Stored Functions**

- **Concept:** A stored function is a named block of SQL code stored in the database that performs a specific calculation or task and **returns a single value**. They are called within SQL expressions.
- **Creating Functions:** Use `CREATE FUNCTION`. Define input parameters (e.g., `IN param_name TYPE`), the return data type (`RETURNS type`), and the function body within `BEGIN...END`.
  - `DELIMITER // ... // DELIMITER ;`: Often needed in clients to handle semicolons within the function body.
  - `DECLARE`: Used to create local variables.
  - `SELECT ... INTO variable`: Used to assign query results to variables.
  - `READS SQL DATA` / `DETERMINISTIC` / etc.: Characteristics describing the function's behavior (optional but good practice).
- **Example (`Densidad` - UD11, Q1):** Calculate population density for a given province.

  ```sql
  DELIMITER //
  CREATE FUNCTION Densidad (nombre_prov VARCHAR(100))
  RETURNS DECIMAL(10, 2) -- Returns a number like 123.45
  READS SQL DATA
  BEGIN
      DECLARE total_poblacion BIGINT DEFAULT 0;
      DECLARE superficie_prov DECIMAL(10, 2);
      DECLARE v_n_provincia INT;

      -- Get province ID and area
      SELECT n_provincia, superficie INTO v_n_provincia, superficie_prov
      FROM Provincias WHERE nombre = nombre_prov LIMIT 1;

      -- Basic error/edge case handling
      IF v_n_provincia IS NULL OR superficie_prov IS NULL OR superficie_prov <= 0 THEN
          RETURN NULL; -- Or 0.00
      END IF;

      -- Calculate total population (must query Localidades)
      SELECT SUM(poblacion) INTO total_poblacion
      FROM Localidades WHERE n_provincia = v_n_provincia;

      -- Handle case where SUM might return NULL if no localities
      IF total_poblacion IS NULL THEN SET total_poblacion = 0; END IF;

      -- Return the calculated density
      RETURN total_poblacion / superficie_prov;
  END //
  DELIMITER ;

  -- How to use it:
  -- SELECT Densidad('NombreDeProvincia');
  ```

- **Key Techniques Used:** Parameter input, variable declaration, querying data into variables, aggregate function (`SUM`), conditional logic (`IF`), calculation, returning a value.

**6. Stored Procedures**

- **Concept:** A stored procedure is a named block of SQL code stored in the database designed to perform a specific action or set of actions. Unlike functions, they don't _have_ to return a single value; they can modify data, perform complex operations, and return result sets (like a standard `SELECT`).
- **Creating Procedures:** Use `CREATE PROCEDURE`. Define parameters (`IN`, `OUT`, `INOUT`), and the procedure body within `BEGIN...END`.
- **Calling Procedures:** Use `CALL procedure_name(arguments);`
- **Example (`ContarProvinciasComunidad` - UD11, Q2):** Count provinces in a community and display a message.

  ```sql
  DELIMITER //
  CREATE PROCEDURE ContarProvinciasComunidad (IN nombre_com VARCHAR(100))
  BEGIN
      DECLARE prov_count INT;
      DECLARE v_id_comunidad INT;

      -- Get community ID (assumes name exists per NOTE)
      SELECT id_comunidad INTO v_id_comunidad FROM Comunidades
      WHERE nombre = nombre_com LIMIT 1;

      -- Count provinces
      SELECT COUNT(*) INTO prov_count FROM Provincias
      WHERE id_comunidad = v_id_comunidad;

      -- Output message based on count (uses SELECT to display)
      IF prov_count = 1 THEN
          SELECT CONCAT(nombre_com, ' es una comunidad autónoma uniprovincial') AS Mensaje;
      ELSE
          SELECT CONCAT('La comunidad ', nombre_com, ' consta de ', prov_count, ' provincias') AS Mensaje;
      END IF;
  END //
  DELIMITER ;

  -- How to call it:
  -- CALL ContarProvinciasComunidad('Comunidad de Madrid');
  -- CALL ContarProvinciasComunidad('País Vasco');
  ```

- **Key Techniques Used:** Input parameter, variable declaration, `SELECT INTO`, aggregate function (`COUNT(*)`), conditional logic (`IF/ELSE`), outputting results via `SELECT`, string concatenation (`CONCAT`).

**7. Triggers**

- **Concept:** A trigger is a stored procedure that is automatically executed (fired) by the database server in response to certain Data Manipulation Language (DML) events (`INSERT`, `UPDATE`, `DELETE`) on a specific table. Often used for enforcing complex business rules, auditing changes, or maintaining summary data.
- **Creating Triggers:** Use `CREATE TRIGGER`. Specify trigger name, timing (`BEFORE` or `AFTER`), event (`INSERT`, `UPDATE`, `DELETE`), table (`ON table_name`), scope (`FOR EACH ROW`), and the trigger body (`BEGIN...END`).
  - `NEW`: Inside `INSERT` and `UPDATE` triggers, `NEW` refers to the row being inserted or the new version of the row being updated.
  - `OLD`: Inside `UPDATE` and `DELETE` triggers, `OLD` refers to the old version of the row being updated or the row being deleted.
- **Example (`InsertarPedido` - UD12, Q1):** Update customer's last order time and order count when a new order is inserted.
  ```sql
  DELIMITER //
  CREATE TRIGGER InsertarPedido
  AFTER INSERT ON Pedido -- Fires AFTER an INSERT on Pedido table
  FOR EACH ROW -- Executes once per inserted row
  BEGIN
      -- Update the Cliente table for the customer who placed the order
      UPDATE Cliente
      SET
          ultimo_pedido = NEW.fechahora,  -- Use the timestamp from the new order
          num_pedidos = num_pedidos + 1   -- Increment the count
      WHERE
          DNI = NEW.dni_cliente;          -- Match the customer using the DNI from the new order
  END //
  DELIMITER ;
  ```
- **Key Techniques Used:** Trigger timing/event (`AFTER INSERT`), scope (`FOR EACH ROW`), accessing newly inserted data (`NEW.fechahora`, `NEW.dni_cliente`), performing DML (`UPDATE`) within the trigger body to maintain related data.

**8. Events (Scheduled Events)**

- **Concept:** An event is a task or block of SQL code that the database server executes automatically based on a predefined schedule. Useful for periodic maintenance, generating reports, archiving data, or running summary calculations at specific times.
- **Creating Events:** Use `CREATE EVENT`. Specify event name, schedule (`ON SCHEDULE`), frequency (`EVERY interval`), start time (`STARTS timestamp`), whether it persists (`ON COMPLETION PRESERVE`), and the action (`DO ...`).
  - The event scheduler must be enabled on the server (e.g., `SET GLOBAL event_scheduler = ON;` in MySQL).
- **Example (`RegistrarGastoClienteEvento` - UD12, Q2):** Call a (fictional) procedure at the end of every year.
  ```sql
  -- Assumes event_scheduler is ON
  DELIMITER //
  CREATE EVENT RegistrarGastoClienteEvento
  ON SCHEDULE
      EVERY 1 YEAR -- Frequency: once per year
      -- Calculate the start time: Dec 31st, 23:59:59 of the current year
      STARTS STR_TO_DATE(CONCAT(YEAR(CURDATE()), '-12-31 23:59:59'), '%Y-%m-%d %H:%i:%s')
      ON COMPLETION PRESERVE -- Keep the event for future runs
  DO
  BEGIN
      -- The task to perform: call the procedure
      CALL RegistrarGastoCliente();
  END //
  DELIMITER ;
  ```
- **Key Techniques Used:** Defining schedule (`EVERY`, `STARTS`), calculating dynamic start time (`YEAR`, `CURDATE`, `CONCAT`, `STR_TO_DATE`), ensuring recurrence (`ON COMPLETION PRESERVE`), defining the action (`DO CALL ...`).
