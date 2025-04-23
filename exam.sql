-- Create the Comunidades (Autonomous Communities) table
CREATE TABLE Comunidades (
    id_comunidad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_capital INT NULL
);

-- Create the Provincias (Provinces) table
CREATE TABLE Provincias (
    n_provincia INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    superficie DECIMAL(10,2) NOT NULL COMMENT 'Area in km²',
    id_capital INT NULL,
    id_comunidad INT NOT NULL,
    FOREIGN KEY (id_comunidad) REFERENCES Comunidades(id_comunidad)
);

-- Create the Localidades (Localities/Towns) table
CREATE TABLE Localidades (
    id_localidad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    poblacion INT NOT NULL,
    n_provincia INT NOT NULL,
    FOREIGN KEY (n_provincia) REFERENCES Provincias(n_provincia)
);

-- Add foreign key constraints for capital cities
-- These constraints are added after all tables are created to avoid circular reference issues
ALTER TABLE Comunidades
ADD CONSTRAINT fk_comunidad_capital
FOREIGN KEY (id_capital) REFERENCES Localidades(id_localidad);

ALTER TABLE Provincias
ADD CONSTRAINT fk_provincia_capital
FOREIGN KEY (id_capital) REFERENCES Localidades(id_localidad);


-- Question n1: Create a view named VLocalidadesVascas containing,
-- for all localities in the Basque Country autonomous community,
-- the locality name, its population, and the name of the province it belongs to.
-- The attributes (columns) of this view must be named NomLoc, PobLoc, and NomProv, respectively.

CREATE VIEW VLocalidadesVascas (NomLoc, PobLoc, NomProv) AS
SELECT
    l.nombre,
    l.poblacion,
    p.nombre
FROM
    Localidades l
JOIN
    Provincias p ON l.n_provincia = p.n_provincia
JOIN
    Comunidades c ON p.id_comunidad = c.id_comunidad
WHERE
    c.nombre = 'País Vasco';


-- Question n1.1: Write the command to modify the population of Bilbao to 355,000 inhabitants
-- using the VLocalidadesVascas view

UPDATE VLocalidadesVascas
SET
  PobLoc = 3559999
WHERE
  NomLoc = 'Bilbao';


-- Question n2: Create a role named rolexamen that can query (SELECT) any
-- table in the exa3evaGeografia database. Additionally,
-- it must be able to perform insertions (INSERT) and
-- deletions (DELETE) on the Localidades table, as well as modify (UPDATE) the poblacion attribute of that table


-- Create the role
CREATE ROLE rolexamen;

-- Grant SELECT permission on all tables in the database
GRANT SELECT ON exa3evaGeografia.Localidades TO rolexamen;
GRANT SELECT ON exa3evaGeografia.Provincias TO rolexamen;
GRANT SELECT ON exa3evaGeografia.Comunidades TO rolexamen;
-- or you can use : GRANT SELECT ON exa3evaGeografia.* TO rolexamen;

-- Grant INSERT and DELETE permissions on the Localidades table
GRANT INSERT, DELETE ON exa3evaGeografia.Localidades TO rolexamen;

-- Grant UPDATE permission specifically on the 'poblacion' column of Localidades
GRANT UPDATE (poblacion) ON exa3evaGeografia.Localidades TO rolexamen;


-- Question n3.1: Grant the necessary permissions to the role rolprueba so it can create, modify (ALTER),
-- and delete (DROP) procedures and functions,
-- as well as create indexes, views, and events, all related to the exa3evaGeografia database.

-- Create the role if it doesn't exist (optional, based on interpretation)
CREATE ROLE rolprueba;

-- Grant permissions for procedures and functions (routines)
GRANT CREATE ROUTINE, ALTER ROUTINE, DROP ROUTINE ON exa3evaGeografia.* TO rolprueba;

-- Grant permissions for views
GRANT CREATE VIEW ON exa3evaGeografia.* TO rolprueba;

-- Grant permissions for indexes
GRANT CREATE INDEX, DROP INDEX ON exa3evaGeografia.* TO rolprueba;

-- Grant permissions for events
GRANT CREATE EVENT, ALTER EVENT, DROP EVENT ON exa3evaGeografia.* TO rolprueba;

-- Question n3: Create a user named usuexamen with the password 'asgbd'. This user:
---  Should only be allowed to establish 3 simultaneous connections to the server.
---  Their password must expire in 40 days.
---  Assign the rolprueba role to this user.

-- Create the user with password, connection limit, and password expiry
CREATE USER 'usuexamen'@'%'
IDENTIFIED BY 'asgbd'
WITH MAX_USER_CONNECTIONS 3
PASSWORD EXPIRE INTERVAL 40 DAY;

-- Grant the 'rolprueba' role to the new user
GRANT rolprueba TO 'usuexamen'@'%';


-- Procedures and Functions


-- Question n1: Create a function named Densidad that receives the name of a province and
-- returns its population density as a real number (float/decimal).
-- Population density is calculated by dividing its total population (number of inhabitants)
-- by its area or surface in km².
-- Note that the Provincias table contains the province's area but not its population,
-- which must be calculated by summing the population of all its localities.


CREATE FUNCTION Densidad (nombre_prov VARCHAR(100))
RETURNS DECIMAL(10, 2) -- Return a decimal number, e.g., 10 digits total, 2 after decimal point
READS SQL DATA -- Indicates the function reads data but doesn't modify it
BEGIN
    DECLARE total_poblacion BIGINT;
    DECLARE superficie_prov DECIMAL(10, 2);

    -- Find the province ID and surface area based on the input name
    SELECT superficie INTO superficie_prov
    FROM Provincias
    WHERE nombre = nombre_prov
    LIMIT 1;

    -- Calculate the total population by summing populations of localities in that province
    SELECT SUM(l.poblacion) INTO total_poblacion
    FROM Localidades l
   	JOIN Provincias p ON l.n_provincia = p.n_provincia
   	WHERE p.nombre = nombre_prov;


    -- Calculate and return the density
    RETURN total_poblacion / superficie_prov;

END;


-- Question n2: Create a procedure that receives the name of an autonomous community and counts
-- the number of provinces belonging to it according to the data in the Provincias table:
-- If the autonomous community consists of only one province, it should display
-- the message "XXXX is a uniprovincial autonomous community"
-- Otherwise (if it has more than one), it should display
-- the message "The community XXXX consists of YY provinces"
-- In these messages, XXXX is the name of the autonomous community received as a parameter,
--  and YY is its number of provinces
-- Write two examples of calling the procedure, one for each case
-- NOTE: It is not necessary to handle the case where the procedure
-- receives the name of an autonomous community for which we do not have information in the database


CREATE PROCEDURE ContarProvinciasComunidad (IN nombre_com VARCHAR(100))
BEGIN
    DECLARE prov_count INT;

    -- Count the number of provinces associated with that community ID
    SELECT COUNT(*) INTO prov_count
    FROM Provincias p
    JOIN Comunidades c ON p.id_comunidad = c.id_comunidad
    WHERE c.nombre = nombre_com;

    -- Display the appropriate message based on the count
    IF prov_count = 1 THEN
        SELECT CONCAT(nombre_com, ' es una comunidad autónoma uniprovincial') AS Mensaje;
    ELSE
        -- This covers count > 1 and also count = 0 (if a community existed with no provinces)
        SELECT CONCAT('La comunidad ', nombre_com, ' consta de ', prov_count, ' provincias') AS Mensaje;
    END IF;

END;

CALL ContarProvinciasComunidad('Comunidad de Madrid');
CALL ContarProvinciasComunidad('País Vasco');


-- PART 2

CREATE TABLE Cliente (
    DNI VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    ultimo_pedido TIMESTAMP NULL,
    num_pedidos INT NOT NULL DEFAULT 0
);

-- Create Pizza table
CREATE TABLE Pizza (
    nom_pizza VARCHAR(50) PRIMARY KEY,
    tiempo_prep INT NOT NULL COMMENT 'Preparation time in minutes',
    precio DECIMAL(6,2) NOT NULL,
    num_pedidos INT NOT NULL DEFAULT 0,
    num_unidades INT NOT NULL DEFAULT 0
);

-- Create Ingrediente (Ingredient) table
CREATE TABLE Ingrediente (
    nom_ingrediente VARCHAR(50) PRIMARY KEY,
    unidad_medida VARCHAR(20) NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    num_veces INT NOT NULL DEFAULT 0 COMMENT 'Times used as extra ingredient'
);

-- Create Pedido (Order) table
CREATE TABLE Pedido (
    num_pedido INT AUTO_INCREMENT PRIMARY KEY,
    fechahora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dni_cliente VARCHAR(15) NOT NULL,
    importe DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (dni_cliente) REFERENCES Cliente(DNI)
);

-- Create Contiene (Pizza Contains Ingredient) table with composite primary key
CREATE TABLE Contiene (
    nom_pizza VARCHAR(50) NOT NULL,
    nom_ingrediente VARCHAR(50) NOT NULL,
    cantidad DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (nom_pizza, nom_ingrediente),
    FOREIGN KEY (nom_pizza) REFERENCES Pizza(nom_pizza),
    FOREIGN KEY (nom_ingrediente) REFERENCES Ingrediente(nom_ingrediente)
);

-- Create LineaPedido (Order Line) table with composite primary key
CREATE TABLE LineaPedido (
    num_pedido INT NOT NULL,
    nom_pizza VARCHAR(50) NOT NULL,
    unidades INT NOT NULL,
    ing_adicional VARCHAR(50) NULL,
    unidades_ing_adicional INT NULL,
    PRIMARY KEY (num_pedido, nom_pizza),
    FOREIGN KEY (num_pedido) REFERENCES Pedido(num_pedido),
    FOREIGN KEY (nom_pizza) REFERENCES Pizza(nom_pizza),
    FOREIGN KEY (ing_adicional) REFERENCES Ingrediente(nom_ingrediente)
);


-- Question n1: A trigger named InsertarPedido must be created that does the following:
-- When an order (pedido) is added to the database, this trigger must:
-- Update the ultimo_pedido column of the client who placed the order,
-- assigning this column the same value (fechahora) that is inserted in the new order
-- (i.e., do NOT use CURRENT_TIMESTAMP or similar).
-- Update (increment) the num_pedidos column of the Cliente table for that client.

CREATE TRIGGER InsertarPedido
AFTER INSERT ON Pedido
FOR EACH ROW
BEGIN
    UPDATE Cliente
    SET
        ultimo_pedido = NEW.fechahora,
        num_pedidos = num_pedidos + 1
    WHERE
        DNI = NEW.dni_cliente;
END;

-- Question n2: Create an event named RegistrarGastoClienteEvento that calls the fictional procedure
-- RegistrarGastoCliente() and executes once per year, specifically on the last day of each year at 23:59:59.

CREATE EVENT RegistrarGastoClienteEvento
ON SCHEDULE
    EVERY 1 YEAR
    STARTS '2025-12-31 23:59:59'
    STARTS STR_TO_DATE(CONCAT(YEAR(CURDATE()), '-12-31 23:59:59'), '%Y-%m-%d %H:%i:%s')
    ON COMPLETION PRESERVE
DO
BEGIN
    CALL RegistrarGastoCliente();
END
