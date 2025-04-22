**Complete Database Exam Revision Notes**

**Introduction**

This document provides comprehensive revision notes covering key database concepts including views, user/role management, stored procedures, stored functions, triggers, and scheduled events, based on the examples and schemas presented in your exam (`exa3evaGeografia` and `Exa3EvaPizzeria`).

**I. Database Schemas Referenced**

**A. `exa3evaGeografia` Database**

- **`Localidades` (Localities/Towns):**
  - `id_localidad` (INT PK): Unique ID for the locality.
  - `nombre` (VARCHAR): Name of the locality (e.g., 'Bilbao').
  - `poblacion` (BIGINT): Number of inhabitants.
  - `n_provincia` (INT FK -> Provincias): ID of the province it belongs to.
- **`Provincias` (Provinces):**
  - `n_provincia` (INT PK): Unique ID for the province.
  - `nombre` (VARCHAR): Name of the province (e.g., 'Bizkaia').
  - `superficie` (DECIMAL): Area in km².
  - `id_capital` (INT FK -> Localidades): ID of the province's capital city.
  - `id_comunidad` (INT FK -> Comunidades): ID of the autonomous community it belongs to.
- **`Comunidades` (Autonomous Communities):**
  - `id_comunidad` (INT PK): Unique ID for the community.
  - `nombre` (VARCHAR): Name of the community (e.g., 'País Vasco').
  - `id_capital` (INT FK -> Localidades): ID of the community's capital city.

**B. `Exa3EvaPizzeria` Database**

- **`Cliente` (Customer):**
  - `DNI` (VARCHAR PK): Unique ID for the customer.
  - `nombre`, `direccion`, etc.: Other customer details.
  - `ultimo_pedido` (TIMESTAMP): Timestamp of the last order.
  - `num_pedidos` (INT): Total count of orders placed.
- **`Pedido` (Order):**
  - `num_pedido` (INT PK): Unique ID for the order.
  - `fechahora` (TIMESTAMP): Timestamp when the order was placed.
  - `dni_cliente` (VARCHAR FK -> Cliente): ID of the customer placing the order.
  - `importe` (DECIMAL): Total cost of the order.
- **`Pizza`:**
  - `nom_pizza` (VARCHAR PK): Name/ID of the pizza.
  - `tiempo_prep` (INT): Preparation time.
  - `precio` (DECIMAL): Price of the pizza.
  - `num_pedidos` (INT): Times this pizza has been ordered.
  - `num_unidades` (INT): Total units of this pizza sold.
- **`LineaPedido` (Order Line):** (Details inferred)
  - `num_pedido` (INT FK -> Pedido)
  - `nom_pizza` (VARCHAR FK -> Pizza)
  - ... (Likely includes quantity, etc.)
- **(Assumed for examples) `ActivityLog`:**
  - `log_id` (INT PK AUTO_INCREMENT)
  - `log_time` (TIMESTAMP)
  - `metric_name` (VARCHAR)
  - `metric_value` (INT or VARCHAR)
- **(Assumed for examples) `AdminLog`:**
  - `log_id` (INT PK AUTO_INCREMENT)
  - `log_time` (TIMESTAMP)
  - `message` (TEXT)

---

**II. Views**

- **Concept:** A virtual table based on the stored result-set of an SQL query. It doesn't store data itself but provides a named way to look at data derived from one or more tables.
- **Use Cases:** Simplify complex queries, restrict data access (security), present data logically, achieve data independence.
- **Syntax:** `CREATE VIEW view_name [(column_list)] AS SELECT_statement;`
- **Example (`VLocalidadesVascas`):** Show Basque locality names, populations, and province names.
  - **Tables Used:** `Localidades`, `Provincias`, `Comunidades`
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

---

**III. Updating Data Through Views**

- **Concept:** Modifying data in the underlying base tables by issuing `INSERT`, `UPDATE`, or `DELETE` commands against a view. This is only possible if the view meets certain criteria (e.g., often needs to be based on a single table or the modification must unambiguously target one base table).
- **Example (Updating Bilbao's Population):**
  - **View Used:** `VLocalidadesVascas`
  - **Table Modified:** `Localidades` (column `poblacion`)
  ```sql
  UPDATE VLocalidadesVascas
  SET PobLoc = 355000 -- Sets the 'poblacion' column in the underlying table
  WHERE NomLoc = 'Bilbao'; -- Identifies the row using the 'nombre' column
  ```

---

**IV. Roles and Privileges**

- **Concept:**
  - **Privileges:** Permissions defining what actions can be performed (e.g., `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE VIEW`, `EXECUTE`, `EVENT`).
  - **Roles:** Named collections of privileges. Users are granted roles, simplifying permission management.
- **Creating Roles:** `CREATE ROLE role_name;`
- **Granting Privileges:** `GRANT privilege(s) ON database_object TO role_name | user_name;`
- **Example (`rolexamen`):** Query any table, plus specific modifications on `Localidades`.

  - **Database:** `exa3evaGeografia`

  ```sql
  -- Create the role
  CREATE ROLE rolexamen;

  -- Grant SELECT on all relevant tables in the database
  GRANT SELECT ON exa3evaGeografia.Localidades TO rolexamen;
  GRANT SELECT ON exa3evaGeografia.Provincias TO rolexamen;
  GRANT SELECT ON exa3evaGeografia.Comunidades TO rolexamen;
  -- Note: Shorthand GRANT SELECT ON exa3evaGeografia.* TO rolexamen; might work depending on DBMS/version.

  -- Grant specific DML on Localidades
  GRANT INSERT, DELETE ON exa3evaGeografia.Localidades TO rolexamen;

  -- Grant UPDATE only on the 'poblacion' column of Localidades
  GRANT UPDATE (poblacion) ON exa3evaGeografia.Localidades TO rolexamen;
  ```

- **Example (`rolprueba` Object Privileges):** Allow creation/modification of procedures, functions, views, indexes, events.

  - **Database:** `exa3evaGeografia`

  ```sql
  -- Assuming rolprueba already exists or CREATE ROLE rolprueba; first
  -- Grant permissions for procedures/functions (routines)
  GRANT CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission for views
  GRANT CREATE VIEW ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission for indexes (allows CREATE INDEX, DROP INDEX on tables)
  GRANT INDEX ON exa3evaGeografia.* TO rolprueba;

  -- Grant permission for events
  GRANT EVENT ON exa3evaGeografia.* TO rolprueba;
  ```

---

**V. User Management**

- **Concept:** Creating and managing database user accounts, defining authentication, resource limits, password policies, and assigning privileges (usually via roles).
- **Creating Users:** `CREATE USER 'username'@'host' IDENTIFIED BY 'password' [options];`
  - `'host'`: `localhost` (local connections), `%` (any host), specific IP/hostname.
  - Options (MySQL): `WITH MAX_USER_CONNECTIONS n`, `PASSWORD EXPIRE INTERVAL n DAY`, etc.
- **Assigning Roles:** `GRANT role_name TO 'username'@'host';`
- **Example (`usuexamen`):** Create user with limits, expiry, and assign `rolprueba`.

  ```sql
  -- Create the user 'usuexamen' connecting from localhost
  CREATE USER 'usuexamen'@'localhost'
  -- Set the password
  IDENTIFIED BY 'asgbd'
  -- Set resource limit: max 3 simultaneous connections
  WITH MAX_USER_CONNECTIONS 3
  -- Set password policy: expires after 40 days
  PASSWORD EXPIRE INTERVAL 40 DAY;

  -- Grant the 'rolprueba' role (and its associated privileges) to the user
  GRANT rolprueba TO 'usuexamen'@'localhost';

  -- Optional: Make the assigned role the default active role upon login
  SET DEFAULT ROLE rolprueba TO 'usuexamen'@'localhost';
  ```

---

**VI. Stored Functions**

- **Concept:** Named, precompiled SQL code block designed to perform a calculation or lookup and **return a single scalar value**. Called within SQL expressions.
- **Characteristics:** Must `RETURN` a value, primarily `IN` parameters, DML restricted inside queries, can have characteristics (`DETERMINISTIC`, `READS SQL DATA`).
- **Use Cases:** Reusable calculations, data formatting, encapsulate simple lookups, simplify query expressions.
- **Syntax:**
  ```sql
  DELIMITER //
  CREATE FUNCTION function_name (param1 type, ...)
  RETURNS return_type
  [CHARACTERISTICS]
  BEGIN
      -- Declarations
      -- Logic (IF, SET, SELECT INTO, etc.)
      RETURN value;
  END //
  DELIMITER ;
  ```
- **Example (`Densidad`):** Calculate population density.

  - **Database:** `exa3evaGeografia`

  ```sql
  DELIMITER //
  CREATE FUNCTION Densidad (nombre_prov VARCHAR(100))
  RETURNS DECIMAL(10, 2) -- Return a decimal number
  READS SQL DATA -- Indicates the function reads data
  BEGIN
      DECLARE total_poblacion BIGINT DEFAULT 0;
      DECLARE superficie_prov DECIMAL(10, 2);
      DECLARE v_n_provincia INT;

      -- Find the province ID and surface area based on the input name
      SELECT n_provincia, superficie INTO v_n_provincia, superficie_prov
      FROM Provincias
      WHERE nombre = nombre_prov
      LIMIT 1;

      -- Handle case where province is not found or has zero/null surface area
      IF v_n_provincia IS NULL OR superficie_prov IS NULL OR superficie_prov <= 0 THEN
          RETURN NULL; -- Or return 0.00 depending on requirements
      END IF;

      -- Calculate the total population using IFNULL for safety
      SELECT IFNULL(SUM(poblacion), 0) INTO total_poblacion
      FROM Localidades
      WHERE n_provincia = v_n_provincia;

      -- Calculate and return the density
      RETURN total_poblacion / superficie_prov;
  END //
  DELIMITER ;

  -- How to use it:
  SELECT nombre, superficie, Densidad(nombre) AS calculated_density
  FROM Provincias
  WHERE id_comunidad = 1; -- Example: Assuming 1 is País Vasco's ID
  ```

- **Dropping:** `DROP FUNCTION [IF EXISTS] function_name;`

---

**VII. Stored Procedures**

- **Concept:** Named, precompiled collection of SQL statements designed to perform an _action_ or _set of actions_. Can take `IN`, `OUT`, `INOUT` parameters, perform DML, manage transactions, and return result sets.
- **Characteristics:** No mandatory return value (can return result sets via `SELECT`), flexible parameters, can modify data, encapsulate complex logic.
- **Use Cases:** Encapsulate business logic, security layer, improve performance, reduce network traffic, batch processing, enforce complex rules.
- **Syntax:**
  ```sql
  DELIMITER //
  CREATE PROCEDURE procedure_name ( [mode] param1 type, ... )
  [CHARACTERISTICS]
  BEGIN
      -- Declarations
      -- Logic (IF, Loops, DML, SELECT, CALL, etc.)
      -- Can SELECT data to return to client
      -- Can SET OUT/INOUT parameters
  END //
  DELIMITER ;
  ```
- **Example (`ContarProvinciasComunidad`):** Count provinces and display message.

  - **Database:** `exa3evaGeografia`

  ```sql
  DELIMITER //
  CREATE PROCEDURE ContarProvinciasComunidad (IN nombre_com VARCHAR(100))
  BEGIN
      DECLARE prov_count INT;
      DECLARE v_id_comunidad INT;

      -- Find the ID of the community based on its name
      SELECT id_comunidad INTO v_id_comunidad
      FROM Comunidades
      WHERE nombre = nombre_com
      LIMIT 1; -- Assuming name is unique or we take the first match

      -- Handle case where community might not be found
      IF v_id_comunidad IS NOT NULL THEN
          SELECT COUNT(*) INTO prov_count
          FROM Provincias
          WHERE id_comunidad = v_id_comunidad;

          -- Display the appropriate message based on the count
          IF prov_count = 1 THEN
              SELECT CONCAT(nombre_com, ' es una comunidad autónoma uniprovincial') AS Mensaje;
          ELSE
              SELECT CONCAT('La comunidad ', nombre_com, ' consta de ', prov_count, ' provincias') AS Mensaje;
          END IF;
      ELSE
          SELECT CONCAT('Comunidad Autónoma ''', nombre_com, ''' no encontrada.') AS Mensaje;
      END IF;
  END //
  DELIMITER ;

  -- How to call it:
  CALL ContarProvinciasComunidad('País Vasco');
  CALL ContarProvinciasComunidad('Comunidad de Madrid');
  ```

- **Example (Procedure with `OUT` Parameter):** Get Province Details.

  - **Database:** `exa3evaGeografia`

  ```sql
  DELIMITER //
  CREATE PROCEDURE GetProvinciaDetails (
      IN p_nombre_prov VARCHAR(100),
      OUT p_superficie DECIMAL(10, 2),
      OUT p_id_comunidad INT,
      OUT p_found BOOLEAN -- Indicate if found
  )
  BEGIN
      -- Initialize OUT parameters
      SET p_superficie = NULL;
      SET p_id_comunidad = NULL;
      SET p_found = FALSE;

      SELECT superficie, id_comunidad INTO p_superficie, p_id_comunidad
      FROM Provincias
      WHERE nombre = p_nombre_prov
      LIMIT 1;

      -- Check if a row was found (MySQL specific check)
      IF FOUND_ROWS() > 0 THEN
          SET p_found = TRUE;
      END IF;
  END //
  DELIMITER ;

  -- How to call it:
  CALL GetProvinciaDetails('Bizkaia', @sf, @id_c, @fnd);
  SELECT @sf AS Surface, @id_c AS CommunityID, @fnd AS Found;
  ```

- **Dropping:** `DROP PROCEDURE [IF EXISTS] procedure_name;`

---

**VIII. Triggers**

- **Concept:** A stored procedure automatically executed by the database in response to a DML event (`INSERT`, `UPDATE`, `DELETE`) on a specific table. Can run `BEFORE` or `AFTER` the event. Uses `NEW` (for inserted/updated row data) and `OLD` (for updated/deleted row data) pseudo-records.
- **Use Cases:** Auditing changes, enforcing complex business rules, maintaining summary/derived data, preventing invalid operations.
- **Syntax:**
  ```sql
  DELIMITER //
  CREATE TRIGGER trigger_name
  {BEFORE | AFTER} {INSERT | UPDATE | DELETE}
  ON table_name
  FOR EACH ROW -- Usually required for row-level actions
  BEGIN
      -- Trigger logic using NEW and OLD
  END //
  DELIMITER ;
  ```
- **Example (`InsertarPedido`):** Update customer stats on new order.
  - **Database:** `Exa3EvaPizzeria`
  - **Triggering Table/Event:** `AFTER INSERT ON Pedido`
  - **Action Table:** `Cliente`
  ```sql
  DELIMITER //
  CREATE TRIGGER InsertarPedido
  AFTER INSERT ON Pedido -- Trigger fires after a row is inserted into Pedido
  FOR EACH ROW -- The trigger logic executes for each inserted row
  BEGIN
      -- Update the Cliente table based on the DNI from the newly inserted Pedido row
      UPDATE Cliente
      SET
          ultimo_pedido = NEW.fechahora, -- Set last order time to the new order's time
          num_pedidos = num_pedidos + 1  -- Increment the order count
      WHERE
          DNI = NEW.dni_cliente; -- Update the specific client who placed the order
  END //
  DELIMITER ;
  ```
- **Dropping:** `DROP TRIGGER [IF EXISTS] trigger_name;`

---

**IX. Events (Scheduled Events)**

- **Concept:** A task (SQL statement or procedure call) executed automatically by the database server based on a predefined schedule. Requires the server's event scheduler to be enabled (`event_scheduler=ON` in MySQL).
- **Characteristics:** Scheduled execution (one-time or recurring), automatic, requires `EVENT` privilege.
- **Use Cases:** Automated maintenance, data archiving, report generation support, data aggregation, periodic cleanup.
- **Syntax:**
  ```sql
  DELIMITER //
  CREATE EVENT event_name
  ON SCHEDULE schedule_definition -- AT timestamp | EVERY interval [STARTS/ENDS]
  [ON COMPLETION PRESERVE] -- Keep for recurring events
  [ENABLE | DISABLE]
  [COMMENT 'description']
  DO
  event_body; -- Single statement or BEGIN...END block
  DELIMITER ;
  ```
- **Example (`RegistrarGastoClienteEvento`):** Call procedure annually.
  - **Database:** `Exa3EvaPizzeria` (indirectly via procedure call)
  ```sql
  -- Ensure scheduler is ON: SET GLOBAL event_scheduler = ON; (needs privileges)
  DELIMITER //
  CREATE EVENT RegistrarGastoClienteEvento
  ON SCHEDULE
      -- Execute every 1 year
      EVERY 1 YEAR
      -- Start at the end of the current year (using LAST_DAY is robust)
      STARTS DATE_FORMAT(LAST_DAY(CONCAT(YEAR(CURDATE()),'-12-01')), '%Y-%m-%d 23:59:59')
  ON COMPLETION PRESERVE -- Keep the event for future runs
  ENABLE -- Ensure the event is active
  COMMENT 'Calls RegistrarGastoCliente procedure annually at year end.'
  DO
  BEGIN
      -- Call the fictional procedure mentioned in the exam
      CALL RegistrarGastoCliente();
      -- Optional: Add logging
      -- INSERT INTO AdminLog (message) VALUES ('Executed RegistrarGastoClienteEvento');
  END //
  DELIMITER ;
  ```
- **Example (Recurring Log Event):** Log active customer count hourly.

  - **Database:** `Exa3EvaPizzeria` (`Cliente`), `ActivityLog`

  ```sql
  /* -- Required table setup for this example:
  CREATE TABLE ActivityLog (
      log_id INT AUTO_INCREMENT PRIMARY KEY,
      log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      metric_name VARCHAR(50),
      metric_value INT
  );
  */
  DELIMITER //
  CREATE EVENT LogActiveCustomersHourly
  ON SCHEDULE
      EVERY 1 HOUR
      STARTS CURRENT_TIMESTAMP -- Start roughly on the next hour
  ON COMPLETION PRESERVE
  ENABLE
  COMMENT 'Logs the count of customers with recent orders hourly.'
  DO
  BEGIN
      DECLARE active_customer_count INT;

      -- Define 'active' as ordered in the last 30 days
      SELECT COUNT(*) INTO active_customer_count
      FROM Cliente
      WHERE ultimo_pedido >= NOW() - INTERVAL 30 DAY;

      INSERT INTO ActivityLog (metric_name, metric_value)
      VALUES ('ActiveCustomers', active_customer_count);
  END //
  DELIMITER ;
  ```

- **Managing Events:**
  - `SHOW EVENTS;`
  - `DROP EVENT [IF EXISTS] event_name;`
  - `ALTER EVENT event_name [DISABLE | ENABLE | ON SCHEDULE ... | RENAME TO ... | DO ...];`
