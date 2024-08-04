CREATE TABLE meat_poultry_egg_establishments (
	establishment_number text CONSTRAINT est_number_key PRIMARY KEY,
	company text,
	street text,
	city text,
	st text,
	zip text,
	phone text,
	grant_date date,
	activities text,
	dbas text
);

COPY meat_poultry_egg_establishments
 FROM
 'C:\Users\DELL\Desktop\sql_proj\MPI_Directory_by_Establishment_Name.csv'	
WITH (FORMAT CSV,  HEADER);


CREATE INDEX company_idx ON meat_poultry_egg_establishments (company);

SELECT *
FROM meat_poultry_egg_establishments;

SELECT count(*) FROM meat_poultry_egg_establishments;

-- checking where more than one row has the same combination of values

SELECT company, street, city, st, count(*) AS address_count
FROM meat_poultry_egg_establishments
GROUP BY company, street, city, st
HAVING count(*) > 1
ORDER BY company, street, city, st;

-- checking for missing values

SELECT st, count(*) AS st_count
FROM meat_poultry_egg_establishments
GROUP BY st
ORDER BY st NULLS FIRST;

SELECT establishment_number, company, city, st, zip
FROM meat_poultry_egg_establishments
WHERE st IS NULL;

--checking for inconsistent data values

SELECT company, count(*) AS company_count
FROM meat_poultry_egg_establishments
GROUP BY company
ORDER BY company ASC;

--checking for formatting error 

SELECT length(zip), count(*) AS length_count
FROM meat_poultry_egg_establishments
GROUP BY length(zip)
ORDER BY length(zip) ASC;

SELECT st, count(*) AS st_count
FROM meat_poultry_egg_establishments
WHERE length(zip) < 5
GROUP BY st
ORDER BY st ASC;


-- NOTED- LIST OF ISSUES TO FIX IN THE DATASET

-- Missing values for three rows in the st column
-- Inconsistent spelling of at least one company’s name
-- Inaccurate ZIP codes due to file conversion



--NEXT: MODIFYING TABLES, COLUMNS AND DATA

-- CAUTIONARY PRACTICE: creating meat_poultry_egg_establishments backup table
CREATE TABLE meat_poultry_egg_establishments_backup AS 
SELECT * FROM meat_poultry_egg_establishments;
-- running a check
SELECT
 (SELECT count(*) FROM meat_poultry_egg_establishments) AS
original,
 (SELECT count(*) FROM
meat_poultry_egg_establishments_backup) AS backup;


-- creating a copy column
ALTER TABLE meat_poultry_egg_establishments ADD COLUMN st_copy text;
UPDATE meat_poultry_egg_establishments
SET st_copy = st;
-- running a check
SELECT st, st_copy
FROM meat_poultry_egg_establishments
WHERE st IS DISTINCT FROM st_copy
ORDER BY st;

--updating rows where values are missing
UPDATE meat_poultry_egg_establishments
SET st = 'MN'
WHERE establishment_number = 'V18677A';
UPDATE meat_poultry_egg_establishments
SET st = 'AL'
WHERE establishment_number = 'M45319+P45319';
UPDATE meat_poultry_egg_establishments
SET st = 'WI'
WHERE establishment_number = 'M263A+P263A+V263A'
RETURNING establishment_number, company, city, st, zip;

--updating values for consistency


-- CAUTIONARY PRACTICE: creating column copy
ALTER TABLE meat_poultry_egg_establishments ADD COLUMN company_standard text;

UPDATE meat_poultry_egg_establishments
SET company_standard = company;


UPDATE meat_poultry_egg_establishments
SET company_standard = 'Armour-Eckrich Meats'
WHERE company LIKE 'Armour%'
RETURNING company, company_standard;

--Repairing Inaccurate ZIP codes entry

ALTER TABLE meat_poultry_egg_establishments ADD COLUMN
zip_copy text;

UPDATE meat_poultry_egg_establishments
SET zip_copy = zip;

UPDATE meat_poultry_egg_establishments
SET zip = '00' || zip
WHERE st IN('PR','VI') AND length(zip) = 3;

UPDATE meat_poultry_egg_establishments
SET zip = '0' || zip
WHERE st IN('CT','MA','ME','NH','NJ','RI','VT') AND
length(zip) = 4;

-- updating specifc values across Tables
CREATE TABLE state_regions (
 st text CONSTRAINT st_key PRIMARY KEY,
 region text NOT NULL
);
COPY state_regions
FROM 'C:\Users\DELL\Desktop\sql_proj\state_regions.csv'
WITH (FORMAT CSV, HEADER);

SELECT *
FROM state_regions;

ALTER TABLE meat_poultry_egg_establishments
 ADD COLUMN inspection_deadline timestamp with time zone;

UPDATE meat_poultry_egg_establishments AS establishments
SET inspection_deadline = '2022-12-01 00:00 EST'
WHERE EXISTS (SELECT state_regions.region 
	FROM state_regions
	WHERE establishments.st = state_regions.st 
		AND state_regions.region = 'New England');

SELECT st, inspection_deadline
FROM meat_poultry_egg_establishments
GROUP BY st, inspection_deadline
ORDER BY st;

-- deleting unneeded columns and tables

ALTER TABLE meat_poultry_egg_establishments 
DROP COLUMN zip_copy;

DROP TABLE meat_poultry_egg_establishments_backup;