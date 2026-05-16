
-- Task 1.

-- Task 1.1
-- Existing users/roles and their permissions 

SELECT * FROM pg_roles;

-- Task 1.2
-- Table-level privileges

SELECT *
FROM information_schema.role_table_grants
WHERE table_schema = 'public';

-- Task 1.3
-- Any existing row-level security policies

SELECT *
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

SELECT *
FROM pg_policies;

-- Task 1.4
-- Database-level settings 
SELECT
    datname,
    pg_get_userbyid(datdba) AS owner,
    datconnlimit
FROM pg_database
WHERE datname = 'dvdrental';

SHOW password_encryption;

-- Task 2.
-- Task 2.1.
-- Create a new user with the username "rentaluser" and the password "rentalpassword". 
-- Give the user the ability to connect to the database but no other permissions.

CREATE ROLE rentaluser
WITH LOGIN
PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

-- Task 2.2
-- Grant "rentaluser" permission allows reading data from the "customer" table. 
-- Сheck to make sure this permission works correctly: write a SQL query to select all customers.

GRANT SELECT ON TABLE public.customer TO rentaluser;

SET ROLE rentaluser;

-- Successful access
SELECT * FROM public.customer;

-- Denied access (expected)
SELECT * FROM public.actor;

-- Task 2.3.
-- Create a new user group called "rental" and add "rentaluser" to the group. 

RESET ROLE; -- back to postgres user

CREATE ROLE rental;

GRANT rental TO rentaluser;

-- Task 2.4
-- Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
-- Insert a new row and update one existing row in the "rental" table under that role. 

GRANT INSERT, UPDATE ON TABLE public.rental TO rental;

-- Task 2.4.1. INSERT

--Access to the sequence is required to automatically generate IDs during INSERT operations. 
-- Without this access, a new ID cannot be generated and the insert fails.
-- The remaining IDs are hardcoded to avoid granting additional permissions.
-- This approach was chosen based on the chat discussion and 
-- to not affect the database by inserting a hardcoded ID for customer and interfere in further operations
GRANT USAGE, SELECT ON SEQUENCE public.rental_rental_id_seq TO rental; 

SET ROLE rental;

-- Successful access
INSERT INTO public.rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id
)
VALUES (
    make_timestamptz(2025, 7, 24, 12, 0, 0, 'Europe/Bucharest'),
    24,
    24,
    make_timestamptz(2025, 7, 30, 12, 0, 0, 'Europe/Bucharest'),
    1
);

-- Denied access (expected)
INSERT INTO public.actor (first_name, last_name)
VALUES ('ALEXANDRA', 'MANICA');

-- Task 2.4.2. UPDATE

-- Denied access (expected)
UPDATE public.rental
SET return_date = make_timestamptz(2025, 4, 24, 12, 0, 0, 'Europe/Bucharest')
WHERE rental_id = 24;

-- In this case, an UPDATE statement requires reading the affected rows. 
-- Therefore, SELECT permission is needed when using a WHERE clause. 
-- It is not possible to perform targeted updates without granting at least limited SELECT access.
-- To not affect the database I've chose to grant additional permissions.

-- If we want to avoid granting additional permissions, we can use the following query.
--UPDATE public.rental
--SET return_date = make_timestamptz(2025, 4, 24, 12, 0, 0, 'Europe/Bucharest');

RESET ROLE;

GRANT SELECT (rental_id) ON public.rental TO rental;

SET ROLE rental;

-- Successful access
UPDATE public.rental
SET return_date = make_timestamptz(2025, 4, 24, 12, 0, 0, 'Europe/Bucharest')
WHERE rental_id = 24;

-- Task 2.5
-- Revoke the "rental" group's INSERT permission for the "rental" table. 
-- Try to insert new rows into the "rental" table make sure this action is denied.

-- Successful access
INSERT INTO public.rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id
)
VALUES (
    make_timestamptz(2025, 8, 24, 12, 0, 0, 'Europe/Bucharest'),
    24,
    24,
    make_timestamptz(2025, 8, 30, 12, 0, 0, 'Europe/Bucharest'),
    1
);

RESET ROLE;

REVOKE INSERT ON TABLE public.rental FROM rental;

SET ROLE rental;

-- Denied access (expected)
INSERT INTO public.rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id
)
VALUES (
    make_timestamptz(2025, 9, 24, 12, 0, 0, 'Europe/Bucharest'),
    24,
    24,
    make_timestamptz(2025, 9, 30, 12, 0, 0, 'Europe/Bucharest'),
    1
);

-- Task 2.6
-- Create a personalized role for any customer already existing in the dvd_rental database. 
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
-- The customer's payment and rental history must not be empty. 

RESET ROLE;

CREATE OR REPLACE FUNCTION create_customer_personalized_role(p_id INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_firstname TEXT;
    v_lastname  TEXT;
    v_role_name TEXT;
BEGIN
    SELECT
        c.first_name,
        c.last_name
    INTO v_firstname, v_lastname
    FROM public.customer c
    WHERE c.customer_id = p_id
      AND EXISTS (
          SELECT 1
          FROM public.payment p
          WHERE p.customer_id = c.customer_id
      )
      AND EXISTS (
          SELECT 1
          FROM public.rental r
          WHERE r.customer_id = c.customer_id
      )
    LIMIT 1;

    IF v_firstname IS NULL OR v_lastname IS NULL THEN
        RAISE EXCEPTION 'Customer does not exist or does not have payments or rentals';
    END IF;

    v_role_name := 'client_' || lower(v_firstname) || '_' || lower(v_lastname);

    IF EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = v_role_name
    ) THEN
        RAISE NOTICE 'Role % already exists', v_role_name;
    ELSE
        EXECUTE format('CREATE ROLE %I', v_role_name);
    END IF;
END;
$$;

SELECT create_customer_personalized_role(24);

SELECT * FROM pg_roles
WHERE rolname like 'client_%';

-- Task 3.
-- Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
-- Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
-- Write a query to make sure this user sees only their own data and one to show zero rows or error
-- As a result you have to demonstrate:
-- access to allowed records 
-- denied access to other users’ records 

GRANT SELECT ON TABLE public.rental TO client_kimberly_lee;
GRANT SELECT ON TABLE public.payment TO client_kimberly_lee;

GRANT USAGE ON SCHEMA public TO client_kimberly_lee;

ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;


-- Initially, I implemented a subquery to retrieve the customer_id and avoid hardcoded IDs. 
-- However, following the chat discussion, I decided to avoid this approach as it requires granting extra SELECT permissions on the customer table.

--CREATE POLICY rental_policy
--ON public.rental
--FOR SELECT
--TO client_kimberly_lee
--USING (
--    customer_id = (
--        SELECT c.customer_id
--        FROM public.customer c
--        WHERE LOWER(c.first_name) = split_part(current_user, '_', 2)
--          AND LOWER(c.last_name) = split_part(current_user, '_', 3)
--        LIMIT 1
--    )
--);
--
--CREATE POLICY payment_policy
--ON public.payment
--FOR SELECT
--TO client_kimberly_lee
--USING (
--    customer_id = (
--        SELECT c.customer_id
--        FROM public.customer c
--        WHERE LOWER(c.first_name) = split_part(current_user, '_', 2)
--          AND LOWER(c.last_name) = split_part(current_user, '_', 3)
--        LIMIT 1
--    )
--);

CREATE POLICY rental_policy
ON public.rental
FOR SELECT
TO client_kimberly_lee
USING (
    customer_id = 24
);

CREATE POLICY payment_policy
ON public.payment
FOR SELECT
TO client_kimberly_lee
USING (
    customer_id = 24
);

SET ROLE client_kimberly_lee;

-- Successful access
SELECT * FROM public.rental;

-- Successful access
SELECT * FROM public.payment;

-- Denied access (expected)
SELECT * FROM public.rental
WHERE customer_id = 1;

-- Denied access (expected)
SELECT * FROM public.payment
WHERE customer_id = 1;

-- Task 4.
-- Prepare answers to the following questions
-- How can one restrict access to certain columns of a database table?
-- What is the difference between user identification and user authentication?
-- What are the recommended authentication protocols for PostgreSQL?
-- What is proxy authentication in PostgreSQL and what is it for? Why does it make the previously discussed role-based access control easier to implement?
--
-- For each answer:
-- Provide a practical example from the dvd_rental database 
-- Describe a real scenario where this concept is used

-- Task 4.1 - Practical example

RESET ROLE;

GRANT SELECT (first_name, last_name)
ON public.staff 
TO rentaluser

SET ROLE rentaluser;

-- Successful access
SELECT first_name, last_name FROM public.staff s;

-- Denied access (expected)
SELECT * FROM public.staff s;

-- Task 4.2 - Practical example
-- Used the example for Task 2.1

-- Task 4.3 - Practical example
RESET ROLE;

SHOW hba_file;

-- Task 4.4 - Practical example

SET ROLE client_kimberly_lee;

SELECT * FROM public.rental;
