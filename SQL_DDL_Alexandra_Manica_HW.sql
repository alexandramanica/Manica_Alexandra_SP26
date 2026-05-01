
-- Task 1. Create a separate physical database and schema and give it an appropriate domain-related name. 

-- The database creation statement is commented out because it only needs to be run once.
-- After creating the database, the remaining script should be executed in the context of that database.

-- CREATE DATABASE car_sharing_service_db;

CREATE SCHEMA IF NOT EXISTS  car_sharing_service_schema;

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Task 2-7

-- Task 2. 
-- Ensure your physical database is in 3NF. 
-- Do not add extra columns, tables, or relations not specified in the logical model 
-- (if you made any additions, you should adjust the logical model accordingly and include comments explaining the reasons for those changes)

-- No extra tables, columns, or relationships were added.
-- One relationship was represented incorrectly in the first task, and it has now been corrected.

-- Task 3.
-- Use appropriate data types for each column 
-- (if the data type is different from what you specified in the logical module, explain in the comments why you made the change). 
-- Please also indicate in the comments what risks would result from choosing the wrong data type?

-- The data type for the columns didn't changed since the first task.
-- Choosing incorrect data types may lead to loss of precision, invalid or inconsistent data, 
-- missing or unnecessary details, truncated text values, and overall reduced data integrity.

-- Task 4. Apply DEFAULT values, and GENERATED ALWAYS AS columns as required.

-- DEFAULT values and GENERATED ALWAYS AS IDENTITY were applied where appropriate.
-- DEFAULT was used for timestamps and status fields to ensure automatic values,
-- while GENERATED ALWAYS AS IDENTITY was used for primary keys to guarantee unique identifiers.

-- Task 5.

-- Create relationships between tables using primary and foreign keys. Explain in the comments what happens if FK is missing

-- Relationships between tables were created using primary and foreign keys to ensure referential integrity.
-- Foreign keys guarantee that related records exist in parent tables and prevent invalid references.
-- If foreign keys are missing, inconsistent data can be inserted (ex referencing non-existent records),
-- leading to data integrity issues and unreliable relationships between tables.

-- Task 6.
-- Apply five check constraints across the tables to restrict certain values, including
-- date to be inserted, which must be greater than January 1, 2000
-- inserted measured value that cannot be negative
-- inserted value that can only be a specific value (as an example of gender)
-- unique
-- not null
-- For each constraint explain in the comments what incorrect data it prevents, what would happen without it.

-- Multiple constraints were applied across the tables to restrict invalid data and improve data integrity.
-- Several CHECK constraints were added especially on date columns, because this restriction was not previously defined in the logical model,
-- and it was necessary to ensure that inserted dates are greater than January 1, 2000.
-- Additional CHECK constraints were used to prevent negative measured values and to restrict certain columns to specific allowed values.
-- UNIQUE constraints were used to prevent duplicate values in columns such as email, phone_number, and license_plate,
-- while NOT NULL constraints were used to ensure that mandatory data is always provided.
-- Without these constraints, the database could store invalid dates, negative amounts, unsupported category values,
-- duplicate records, or missing essential data, which would reduce consistency and reliability.

-- Task 7.
-- Create tables in the correct DDL order: parent tables before child tables to avoid foreign key errors. 
-- Explain in the comments why order matters, what error would occur if order is wrong

-- Tables were created in the correct DDL order, with parent tables before child tables,
-- so that foreign key references could be created successfully.
-- This order matters because a child table cannot reference a parent table that does not yet exist.

-- TABLE CREATION

-- Table Customer

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.customer (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT true,
    
	CONSTRAINT chk_customer_created_at 
		CHECK (created_at >TIMESTAMP '2000-01-01 00:00:00')
);

-- Table Vehicle Type

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.vehicle_type (
    vehicle_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_type_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    activation_fee DECIMAL(10,2) NOT NULL,
    rate_per_km DECIMAL(10,2) NOT NULL,
    rate_per_min DECIMAL(10,2) NOT NULL,

    CONSTRAINT chk_vehicle_type_activation_fee
    	CHECK (activation_fee >= 0),

    CONSTRAINT chk_vehicle_type_rate_per_km
    	CHECK (rate_per_km >= 0),

    CONSTRAINT chk_vehicle_type_rate_per_min
    	CHECK (rate_per_min >= 0)
);

-- Table Employee

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.employee (
    employee_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    manager_id INTEGER,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    position VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_employee_manager_id
        FOREIGN KEY (manager_id)
        REFERENCES car_sharing_service_schema.employee(employee_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_employee_hire_date
        CHECK (hire_date > DATE '2000-01-01')
);


-- Table Vehicle

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.vehicle (
    vehicle_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_type_id INTEGER NOT NULL,
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    model_name VARCHAR(100) NOT NULL,
    manufacture_date DATE NOT NULL,

    CONSTRAINT fk_vehicle_vehicle_type
        FOREIGN KEY (vehicle_type_id)
        REFERENCES car_sharing_service_schema.vehicle_type(vehicle_type_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_vehicle_manufacture_date
        CHECK (manufacture_date BETWEEN DATE '2000-01-01' AND DATE '2100-12-31')
);

-- Table Reservation

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.reservation (
    reservation_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    reserved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reserved_from TIMESTAMP NOT NULL,
    reserved_to TIMESTAMP NOT NULL,

    CONSTRAINT fk_reservation_customer
        FOREIGN KEY (customer_id)
        REFERENCES car_sharing_service_schema.customer(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservation_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES car_sharing_service_schema.vehicle(vehicle_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_reservation_reserved_at
        CHECK (reserved_at >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_reservation_reserved_from
        CHECK (reserved_from >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_reservation_reserved_to
        CHECK (reserved_to >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_reservation_reserved_period
        CHECK (reserved_to > reserved_from),
    
    CONSTRAINT chk_reservation_created_before_start
        CHECK (reserved_at <= reserved_from),
        
    CONSTRAINT ex_reservation_vehicle_no_overlap
        EXCLUDE USING gist (
            vehicle_id WITH =,
            tsrange(reserved_from, reserved_to, '[)') WITH &&
        )
);

-- Table Maintenance

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.maintenance (
    maintenance_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_id INTEGER NOT NULL,
    maintenance_type VARCHAR(20) NOT NULL,
    maintenance_details TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,

    CONSTRAINT fk_maintenance_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES car_sharing_service_schema.vehicle(vehicle_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_maintenance_created_at
        CHECK (created_at >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_maintenance_closed_at
        CHECK (closed_at IS NULL OR closed_at >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_maintenance_period
        CHECK (closed_at IS NULL OR closed_at >= created_at),

    CONSTRAINT chk_maintenance_type
        CHECK (maintenance_type IN ('REPAIR', 'INSPECTION'))
);

-- Table Trip

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.trip (
    trip_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    reservation_id INTEGER,
    distance DECIMAL(10,2),
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,

    CONSTRAINT uq_trip_reservation
        UNIQUE (reservation_id),

    CONSTRAINT fk_trip_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES car_sharing_service_schema.vehicle(vehicle_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_trip_customer
        FOREIGN KEY (customer_id)
        REFERENCES car_sharing_service_schema.customer(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_trip_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES car_sharing_service_schema.reservation(reservation_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_trip_started_at
        CHECK (started_at >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_trip_ended_at
        CHECK (ended_at IS NULL OR ended_at >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_trip_period
        CHECK (ended_at IS NULL OR ended_at >= started_at),

    CONSTRAINT chk_trip_distance
        CHECK (distance IS NULL OR distance >= 0),
        
    CONSTRAINT ex_trip_vehicle_no_overlap
        EXCLUDE USING gist (
            vehicle_id WITH =,
            tsrange(started_at, COALESCE(ended_at, 'infinity'::timestamp), '[)') WITH &&
        )
);

-- Table Payment

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.payment (
    payment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    paid_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_trip
        FOREIGN KEY (trip_id)
        REFERENCES car_sharing_service_schema.trip(trip_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_payment_amount
        CHECK (payment_amount >= 0),

    CONSTRAINT chk_payment_method
        CHECK (payment_method IN ('CARD', 'CASH', 'BANK_TRANSFER')),

    CONSTRAINT chk_payment_paid_at
        CHECK (paid_at >TIMESTAMP '2000-01-01 00:00:00')
);

-- Table Rating

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.rating (
    rating_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    rating_score INTEGER NOT NULL,
    rating_comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_rating_trip
        UNIQUE (trip_id),

    CONSTRAINT fk_rating_trip
        FOREIGN KEY (trip_id)
        REFERENCES car_sharing_service_schema.trip(trip_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_rating_score
        CHECK (rating_score BETWEEN 1 AND 5),

    CONSTRAINT chk_rating_created_at
        CHECK (created_at >TIMESTAMP '2000-01-01 00:00:00')
);

-- Table Employee_maintenance_record

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.employee_maintenance_record (
    record_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    maintenance_id INTEGER NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP,

    CONSTRAINT fk_emr_employee
        FOREIGN KEY (employee_id)
        REFERENCES car_sharing_service_schema.employee(employee_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_emr_maintenance
        FOREIGN KEY (maintenance_id)
        REFERENCES car_sharing_service_schema.maintenance(maintenance_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_emr_assignment
        UNIQUE (employee_id, maintenance_id, assigned_at),

    CONSTRAINT chk_emr_assigned_at
        CHECK (assigned_at >TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_emr_finished_at
        CHECK (finished_at IS NULL OR finished_at >TIMESTAMP '2000-01-01 00:00:00'),
        
    CONSTRAINT chk_emr_period
        CHECK (finished_at IS NULL OR finished_at >= assigned_at)
);

-- Table Vehicle_status_history

CREATE TABLE IF NOT EXISTS car_sharing_service_schema.vehicle_status_history (
    vehicle_status_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    changed_reason TEXT,

    CONSTRAINT fk_vehicle_status_history_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES car_sharing_service_schema.vehicle(vehicle_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_vehicle_status
        CHECK (status IN ('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'RESERVED')),

    CONSTRAINT chk_vehicle_status_valid_from
        CHECK (valid_from > TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_vehicle_status_valid_to
        CHECK (valid_to IS NULL OR valid_to > TIMESTAMP '2000-01-01 00:00:00'),

    CONSTRAINT chk_vehicle_status_period
        CHECK (valid_to IS NULL OR valid_to >= valid_from),

    CONSTRAINT ex_vehicle_status_no_overlap
        EXCLUDE USING gist (
            vehicle_id WITH =,
            tsrange(valid_from, COALESCE(valid_to, 'infinity'::timestamp), '[)') WITH &&
        )
);

-- ROWS INSERTION

-- Task 8
-- After creating tables and adding all constraints, populate the tables with sample data generated, ensuring each table has at least two rows 
-- (for a total of 20+ rows in all the tables). Use INSERT statements with ON CONFLICT DO NOTHING or WHERE NOT EXISTS to avoid duplicates. 
-- Avoid hardcoding values where possible. 
-- Explain in the comments how you ensure consistency of inserted data, how relationships are preserved

-- To avoid duplicates, INSERT statements use either ON CONFLICT DO NOTHING for tables with UNIQUE constraints 
-- or WHERE NOT EXISTS for tables where duplicate prevention is based on logical conditions.
-- Hardcoded values were avoided where possible by using subqueries to retrieve related primary key values.
-- Data consistency is ensured by respecting all defined constraints, using valid values, and inserting data in an order that preserves parent-child relationships.
-- Relationships are preserved by retrieving foreign key values from existing parent records, which ensures that all inserted child rows reference valid related data.

--- Task 8

-- Table 1 - Customer

INSERT INTO car_sharing_service_schema.customer 
    (first_name, last_name, email, phone_number)
VALUES 
    (UPPER('irina'), UPPER('smith'), LOWER('ismith@gmail.com'), '07675454897'),
    (UPPER('iacob'), UPPER('green'), LOWER('igreen@gmail.com'), '08973334121')
ON CONFLICT (email) DO NOTHING
RETURNING *;

-- Table 2 - Vehicle Type

INSERT INTO car_sharing_service_schema.vehicle_type
    (vehicle_type_name, description, activation_fee, rate_per_km, rate_per_min)
VALUES
    (UPPER('eco'), UPPER('small electric vehicle'), 3.00, 0.80, 0.20),
    (UPPER('comfort'), UPPER('premium comfort vehicle'), 15.00, 1.30, 0.50)
ON CONFLICT (vehicle_type_name) DO NOTHING
RETURNING *;

-- Table 3 - Employee

INSERT INTO car_sharing_service_schema.employee 
    (manager_id, first_name, last_name, email, phone_number, hire_date, position)
VALUES
    (NULL, UPPER('elena'), UPPER('quince'), LOWER('elena.quince@BSHARE.COM'), '0732356567', DATE '2025-04-14', UPPER('lead mechanical engineer')),
    (NULL, UPPER('maria'), UPPER('bonart'), LOWER('maria.bonart@BSHARE.COM'), '0736768980', DATE '2024-03-14', UPPER('lead inspection engineer'))
ON CONFLICT (email) DO NOTHING
RETURNING *;

INSERT INTO car_sharing_service_schema.employee
    (manager_id, first_name, last_name, email, phone_number, hire_date, position)
SELECT
    (
        SELECT e.employee_id
        FROM car_sharing_service_schema.employee e
        WHERE e.position = UPPER('lead mechanical engineer')
        LIMIT 1
    ),
    UPPER('darius'),
    UPPER('maxim'),
    LOWER('darius.maxim@BSHARE.COM'),
    '0734585090',
    DATE '2026-02-14',
    UPPER('inspection engineer')
ON CONFLICT (email) DO NOTHING
RETURNING *;

-- Table 4 - Vehicle

INSERT INTO car_sharing_service_schema.vehicle
    (vehicle_type_id, model_name, license_plate, manufacture_date)
SELECT
    (
        SELECT vt.vehicle_type_id
        FROM car_sharing_service_schema.vehicle_type vt
        WHERE vt.vehicle_type_name = UPPER('comfort')
        LIMIT 1
    ),
    UPPER('audi a5'),
    UPPER('b705erd'),
    DATE '2024-12-12'
ON CONFLICT (license_plate) DO NOTHING
RETURNING *;

INSERT INTO car_sharing_service_schema.vehicle
    (vehicle_type_id, model_name, license_plate, manufacture_date)
SELECT
    (
        SELECT vt.vehicle_type_id
        FROM car_sharing_service_schema.vehicle_type vt
        WHERE vt.vehicle_type_name = UPPER('eco')
        LIMIT 1
    ),
    UPPER('toyota prius'),
    UPPER('dj54aem'),
    DATE '2022-10-22'
ON CONFLICT (license_plate) DO NOTHING
RETURNING *;

-- Table 5 - Reservation

INSERT INTO car_sharing_service_schema.reservation
    (customer_id, vehicle_id, reserved_at, reserved_from, reserved_to)
SELECT
    (
        SELECT c.customer_id
        FROM car_sharing_service_schema.customer c
        WHERE c.email = LOWER('ismith@gmail.com')
        LIMIT 1
    ),
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('b705erd')
        LIMIT 1
    ),
    CURRENT_TIMESTAMP,
    TIMESTAMP '2026-07-12 10:00:00',
    TIMESTAMP '2026-07-19 10:00:00'
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.reservation r
    WHERE r.customer_id = (
              SELECT c.customer_id
              FROM car_sharing_service_schema.customer c
              WHERE c.email = LOWER('ismith@gmail.com')
              LIMIT 1
          )
      AND r.vehicle_id = (
              SELECT v.vehicle_id
              FROM car_sharing_service_schema.vehicle v
              WHERE v.license_plate = UPPER('b705erd')
              LIMIT 1
          )
      AND r.reserved_from = TIMESTAMP '2026-07-12 10:00:00'
      AND r.reserved_to = TIMESTAMP '2026-07-19 10:00:00'
)
RETURNING *;

INSERT INTO car_sharing_service_schema.reservation
    (customer_id, vehicle_id, reserved_at, reserved_from, reserved_to)
SELECT
    (
        SELECT c.customer_id
        FROM car_sharing_service_schema.customer c
        WHERE c.email = LOWER('igreen@gmail.com')
        LIMIT 1
    ),
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('dj54aem')
        LIMIT 1
    ),
    TIMESTAMP '2026-07-05 09:00:00',
    TIMESTAMP '2026-08-05 09:00:00',
    TIMESTAMP '2026-08-15 13:00:00'
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.reservation r
    WHERE r.customer_id = (
              SELECT c.customer_id
              FROM car_sharing_service_schema.customer c
              WHERE c.email = LOWER('igreen@gmail.com')
              LIMIT 1
          )
      AND r.vehicle_id = (
              SELECT v.vehicle_id
              FROM car_sharing_service_schema.vehicle v
              WHERE v.license_plate = UPPER('dj54aem')
              LIMIT 1
          )
      AND r.reserved_from = TIMESTAMP '2026-08-05 09:00:00'
      AND r.reserved_to = TIMESTAMP '2026-08-15 13:00:00'
)
RETURNING *;

-- Table 6 - Trip

INSERT INTO car_sharing_service_schema.trip
    (vehicle_id, customer_id, reservation_id, distance, started_at, ended_at)
SELECT
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('b705erd')
        LIMIT 1
    ),
    (
        SELECT c.customer_id
        FROM car_sharing_service_schema.customer c
        WHERE c.email = LOWER('ismith@gmail.com')
        LIMIT 1
    ),
    (
        SELECT r.reservation_id
        FROM car_sharing_service_schema.reservation r
        WHERE r.customer_id = (
                  SELECT c.customer_id
                  FROM car_sharing_service_schema.customer c
                  WHERE c.email = LOWER('ismith@gmail.com')
                  LIMIT 1
              )
          AND r.vehicle_id = (
                  SELECT v.vehicle_id
                  FROM car_sharing_service_schema.vehicle v
                  WHERE v.license_plate = UPPER('b705erd')
                  LIMIT 1
              )
          AND r.reserved_from = TIMESTAMP '2026-07-12 10:00:00'
          AND r.reserved_to = TIMESTAMP '2026-07-19 10:00:00'
        LIMIT 1
    ),
    125.50,
    TIMESTAMP '2026-07-12 10:15:00',
    TIMESTAMP '2026-07-19 12:45:00'
ON CONFLICT (reservation_id) DO NOTHING
RETURNING *;

INSERT INTO car_sharing_service_schema.trip
    (vehicle_id, customer_id, reservation_id, distance, started_at, ended_at)
SELECT
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('dj54aem')
        LIMIT 1
    ),
    (
        SELECT c.customer_id
        FROM car_sharing_service_schema.customer c
        WHERE c.email = LOWER('igreen@gmail.com')
        LIMIT 1
    ),
    (
        SELECT r.reservation_id
        FROM car_sharing_service_schema.reservation r
        WHERE r.customer_id = (
                  SELECT c.customer_id
                  FROM car_sharing_service_schema.customer c
                  WHERE c.email = LOWER('igreen@gmail.com')
                  LIMIT 1
              )
          AND r.vehicle_id = (
                  SELECT v.vehicle_id
                  FROM car_sharing_service_schema.vehicle v
                  WHERE v.license_plate = UPPER('dj54aem')
                  LIMIT 1
              )
          AND r.reserved_from = TIMESTAMP '2026-08-05 09:00:00'
          AND r.reserved_to = TIMESTAMP '2026-08-15 13:00:00'
        LIMIT 1
    ),
    78.25,
    TIMESTAMP '2026-08-05 09:10:00',
    TIMESTAMP '2026-08-15 11:40:00'
ON CONFLICT (reservation_id) DO NOTHING
RETURNING *;

-- Table 7 - Rating

INSERT INTO car_sharing_service_schema.rating
    (trip_id, rating_score, rating_comment)
SELECT
    (
        SELECT t.trip_id
        FROM car_sharing_service_schema.trip t
        WHERE t.customer_id = (
                  SELECT c.customer_id
                  FROM car_sharing_service_schema.customer c
                  WHERE c.email = LOWER('ismith@gmail.com')
              )
          AND t.started_at = TIMESTAMP '2026-07-12 10:15:00'
        LIMIT 1
    ),
    5,
    UPPER('amazing experience')
ON CONFLICT (trip_id) DO NOTHING
RETURNING *;

INSERT INTO car_sharing_service_schema.rating
    (trip_id, rating_score, rating_comment)
SELECT
    (
        SELECT t.trip_id
        FROM car_sharing_service_schema.trip t
        WHERE t.customer_id = (
                  SELECT c.customer_id
                  FROM car_sharing_service_schema.customer c
                  WHERE c.email = LOWER('igreen@gmail.com')
              )
          AND t.started_at = TIMESTAMP '2026-08-05 09:10:00'
        LIMIT 1
    ),
    4,
    UPPER('very good trip')
ON CONFLICT (trip_id) DO NOTHING
RETURNING *;

-- Table 8 - Payment

INSERT INTO car_sharing_service_schema.payment
    (trip_id, payment_amount, payment_method, paid_at)
SELECT
    (
        SELECT t.trip_id
        FROM car_sharing_service_schema.trip t
        WHERE t.customer_id = (
                  SELECT c.customer_id
                  FROM car_sharing_service_schema.customer c
                  WHERE c.email = LOWER('ismith@gmail.com')
              )
          AND t.started_at = TIMESTAMP '2026-07-12 10:15:00'
        LIMIT 1
    ),
    34.90,
    UPPER('card'),
    TIMESTAMP '2026-07-19 12:50:00'
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.payment p
    WHERE p.trip_id = (
              SELECT t.trip_id
              FROM car_sharing_service_schema.trip t
              WHERE t.customer_id = (
                        SELECT c.customer_id
                        FROM car_sharing_service_schema.customer c
                        WHERE c.email = LOWER('ismith@gmail.com')
                    )
                AND t.started_at = TIMESTAMP '2026-07-12 10:15:00'
              LIMIT 1
          )
      AND p.payment_amount = 34.90
      AND p.payment_method = UPPER('card')
      AND p.paid_at = TIMESTAMP '2026-07-19 12:50:00'
)
RETURNING *;

INSERT INTO car_sharing_service_schema.payment
    (trip_id, payment_amount, payment_method, paid_at)
SELECT
    (
        SELECT t.trip_id
        FROM car_sharing_service_schema.trip t
        WHERE t.customer_id = (
                  SELECT c.customer_id
                  FROM car_sharing_service_schema.customer c
                  WHERE c.email = LOWER('igreen@gmail.com')
              )
          AND t.started_at = TIMESTAMP '2026-08-05 09:10:00'
        LIMIT 1
    ),
    52.40,
    UPPER('bank_transfer'),
    TIMESTAMP '2026-08-15 12:50:00'
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.payment p
    WHERE p.trip_id = (
              SELECT t.trip_id
              FROM car_sharing_service_schema.trip t
              WHERE t.customer_id = (
                        SELECT c.customer_id
                        FROM car_sharing_service_schema.customer c
                        WHERE c.email = LOWER('igreen@gmail.com')
                    )
                AND t.started_at = TIMESTAMP '2026-08-05 09:10:00'
              LIMIT 1
          )
      AND p.payment_amount = 52.40
      AND p.payment_method = UPPER('bank_transfer')
      AND p.paid_at = TIMESTAMP '2026-08-15 12:50:00'
)
RETURNING *;

-- Table 9 - Maintenance

INSERT INTO car_sharing_service_schema.maintenance
    (vehicle_id, maintenance_type, maintenance_details, created_at, closed_at)
SELECT
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('b705erd')
        LIMIT 1
    ),
    UPPER('inspection'),
    UPPER('annual technical inspection'),
    TIMESTAMP '2026-01-20 09:00:00',
    TIMESTAMP '2026-01-20 11:30:00'
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.maintenance m
    WHERE m.vehicle_id = (
              SELECT v.vehicle_id
              FROM car_sharing_service_schema.vehicle v
              WHERE v.license_plate = UPPER('b705erd')
              LIMIT 1
          )
      AND m.maintenance_type = UPPER('inspection')
      AND m.created_at = TIMESTAMP '2026-01-20 09:00:00'
)
RETURNING *;

INSERT INTO car_sharing_service_schema.maintenance
    (vehicle_id, maintenance_type, maintenance_details, created_at, closed_at)
SELECT
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('dj54aem')
        LIMIT 1
    ),
    UPPER('repair'),
    UPPER('brake pads repair'),
    TIMESTAMP '2026-02-20 10:00:00',
    TIMESTAMP '2026-02-20 16:00:00'
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.maintenance m
    WHERE m.vehicle_id = (
              SELECT v.vehicle_id
              FROM car_sharing_service_schema.vehicle v
              WHERE v.license_plate = UPPER('dj54aem')
              LIMIT 1
          )
      AND m.maintenance_type = UPPER('repair')
      AND m.created_at = TIMESTAMP '2026-02-20 10:00:00'
)
RETURNING *;

-- Table 10 - Employee_maintenance_record

INSERT INTO car_sharing_service_schema.employee_maintenance_record
    (employee_id, maintenance_id, assigned_at, finished_at)
SELECT
    (
        SELECT e.employee_id
        FROM car_sharing_service_schema.employee e
        WHERE e.email = LOWER('elena.quince@BSHARE.COM')
    ),
    (
        SELECT m.maintenance_id
        FROM car_sharing_service_schema.maintenance m
        WHERE m.vehicle_id = (
                  SELECT v.vehicle_id
                  FROM car_sharing_service_schema.vehicle v
                  WHERE v.license_plate = UPPER('b705erd')
                  LIMIT 1
              )
          AND m.maintenance_type = UPPER('inspection')
          AND m.created_at = TIMESTAMP '2026-01-20 09:00:00'
        LIMIT 1
    ),
    TIMESTAMP '2026-01-20 09:05:00',
    TIMESTAMP '2026-01-20 11:20:00'
ON CONFLICT (employee_id, maintenance_id, assigned_at) DO NOTHING
RETURNING *;

INSERT INTO car_sharing_service_schema.employee_maintenance_record
    (employee_id, maintenance_id, assigned_at, finished_at)
SELECT
    (
        SELECT e.employee_id
        FROM car_sharing_service_schema.employee e
        WHERE e.email = LOWER('maria.bonart@BSHARE.COM')
    ),
    (
        SELECT m.maintenance_id
        FROM car_sharing_service_schema.maintenance m
        WHERE m.vehicle_id = (
                  SELECT v.vehicle_id
                  FROM car_sharing_service_schema.vehicle v
                  WHERE v.license_plate = UPPER('dj54aem')
                  LIMIT 1
              )
          AND m.maintenance_type = UPPER('repair')
          AND m.created_at = TIMESTAMP '2026-02-20 10:00:00'
        LIMIT 1
    ),
    TIMESTAMP '2026-02-20 10:10:00',
    TIMESTAMP '2026-02-20 15:50:00'
ON CONFLICT (employee_id, maintenance_id, assigned_at) DO NOTHING
RETURNING *;

-- Table 11 - Vehicle_status_history

INSERT INTO car_sharing_service_schema.vehicle_status_history
    (vehicle_id, status, valid_from, valid_to, changed_reason)
SELECT
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('b705erd')
        LIMIT 1
    ),
    UPPER('available'),
    TIMESTAMP '2026-01-01 08:00:00',
    TIMESTAMP '2026-01-20 08:59:59',
    UPPER('ready for customer use')
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.vehicle_status_history vsh
    WHERE vsh.vehicle_id = (
              SELECT v.vehicle_id
              FROM car_sharing_service_schema.vehicle v
              WHERE v.license_plate = UPPER('b705erd')
              LIMIT 1
          )
      AND vsh.status = UPPER('available')
      AND vsh.valid_from = TIMESTAMP '2026-01-01 08:00:00'
      AND vsh.valid_to = TIMESTAMP '2026-01-20 08:59:59'
)
RETURNING *;

INSERT INTO car_sharing_service_schema.vehicle_status_history
    (vehicle_id, status, valid_from, valid_to, changed_reason)
SELECT
    (
        SELECT v.vehicle_id
        FROM car_sharing_service_schema.vehicle v
        WHERE v.license_plate = UPPER('dj54aem')
        LIMIT 1
    ),
    UPPER('maintenance'),
    TIMESTAMP '2026-02-20 10:00:00',
    TIMESTAMP '2026-02-20 16:00:00',
    UPPER('brake pads repair')
WHERE NOT EXISTS (
    SELECT 1
    FROM car_sharing_service_schema.vehicle_status_history vsh
    WHERE vsh.vehicle_id = (
              SELECT v.vehicle_id
              FROM car_sharing_service_schema.vehicle v
              WHERE v.license_plate = UPPER('dj54aem')
              LIMIT 1
          )
      AND vsh.status = UPPER('maintenance')
      AND vsh.valid_from = TIMESTAMP '2026-02-20 10:00:00'
      AND vsh.valid_to = TIMESTAMP '2026-02-20 16:00:00'
)
RETURNING *;

-- Task 9
-- Add a not null 'record_ts' field to each table using ALTER TABLE statements, 
-- set the default value to current_date, and check to make sure the value has been set for the existing rows.

-- Add record_ts to all tables

ALTER TABLE car_sharing_service_schema.customer
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.vehicle_type
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.employee
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.vehicle
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.reservation
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.maintenance
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.trip
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.payment
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.rating
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.employee_maintenance_record
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE car_sharing_service_schema.vehicle_status_history
    ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

-- Checks for each table
SELECT * FROM car_sharing_service_schema.customer;

SELECT * FROM car_sharing_service_schema.vehicle_type;

SELECT * FROM car_sharing_service_schema.employee;

SELECT * FROM car_sharing_service_schema.vehicle;

SELECT * FROM car_sharing_service_schema.reservation;

SELECT * FROM car_sharing_service_schema.maintenance;

SELECT * FROM car_sharing_service_schema.trip;

SELECT * FROM car_sharing_service_schema.payment;

SELECT * FROM car_sharing_service_schema.rating;

SELECT * FROM car_sharing_service_schema.employee_maintenance_record;

SELECT * FROM car_sharing_service_schema.vehicle_status_history;

