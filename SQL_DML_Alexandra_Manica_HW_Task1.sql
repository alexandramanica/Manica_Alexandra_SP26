-- GENERAL ASPECTS MENTIONED
-- Task 1.1. Based on the table description found online, the rental_duration columns is measured in days, 
-- so the values will be converted from weeks to days.
-- Based on the chat discussion, a trigger is stored for the last_update and full_text columns, and it was recommend for us not to set them explicitly.
-- Task 1.6. Based on the chat discussion, it was recommend for us to choose random_value for paymount amount and random dates from 2017.

-- Task 1.1
-- Choose your real top-3 favorite movies (released in different years, belong to different genres) and add them to the 'film' table 
-- Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively

-- FAVORITE 3 MOVIES
-- 1) Fight Club - 1999, Drama, Actors: Edward Norton, Brad Pitt
-- 2) Barbie- 2023, Comedy, Actors: Margot Robbie, Ryan Gosling
-- 3) Dune: Part One - 2021, Sci-Fi, Actors: Timothée Chalamet , Zendaya

-- ADDITIONAL REQUESTED DETAILS

-- Q: How was data uniqueness ensured?
-- A: films: WHERE NOT EXISTS checks (title + release_year) before each INSERT.
--    If the film already exists, SELECT returns no rows and INSERT is skipped.
--    film_category: WHERE NOT EXISTS checks (film_id + category_id) before each INSERT.
--    This makes sure that the script is reusable without creating duplicates.

-- Q: How are relationships between tables established?
-- A: film.language_id resolved dynamically via subquery on language table (WHERE UPPER(name) = 'ENGLISH') .
--    film_category.film_id resolved dynamically via subquery on (title).
--    film_category.category_id resolved dynamically via subquery on (name).
--    All FKs always point to valid existing records — if IDs change, subqueries adapt automatically.

-- Task 1.1.1 - MOVIES SUBTASK

BEGIN;

INSERT INTO public.film (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating
)
SELECT
    temp_table.title,
    temp_table.description,
    temp_table.release_year,
    temp_table.language_id,
    temp_table.rental_duration,
    temp_table.rental_rate,
    temp_table.length,
    temp_table.replacement_cost,
    temp_table.rating
FROM (
    SELECT
        UPPER('Barbie'),
        'Barbie is a vibrant and subversive film that follows Barbie and Ken as they leave their perfect world of Barbieland to explore the complexities of the real world, confronting issues of identity, patriarchy, and self-discovery.',
        2023,
        (SELECT language_id FROM public.language WHERE UPPER(name) = 'ENGLISH' LIMIT 1),
        7,
        4.99,
        117,
        19.99,
        'PG-13'::mpaa_rating

    UNION ALL

    SELECT
        UPPER('Fight Club'),
        'Fight Club follows an insomniac office worker who forms an underground fight club with a charismatic soap salesman, only to discover his alter ego is orchestrating a nationwide anarchist plot.',
        1999,
        (SELECT language_id FROM public.language WHERE UPPER(name) = 'ENGLISH' LIMIT 1),
        14,
        9.99,
        139,
        17.99,
        'R'::mpaa_rating

    UNION ALL

    SELECT
        UPPER('Dune: Part One'),
        'Dune follows Paul Atreides, heir to House Atreides, as he navigates political intrigue and betrayal on the desert planet Arrakis, the only source of the valuable spice melange.',
        2021,
        (SELECT language_id FROM public.language WHERE UPPER(name) = 'ENGLISH' LIMIT 1),
        21,
        19.99,
        155,
        18.99,
        'PG-13'::mpaa_rating
) temp_table (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating
)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.film f
    WHERE UPPER(f.title) = UPPER(temp_table.title)
      AND f.release_year = temp_table.release_year
);

COMMIT;

-- Task 1.1.2 - FILM_CATEGORIES SUBTASK
-- Since the chosen movies can be placed in one of the existing categories, 
-- the insert operation was applied only on the film_category table. 

BEGIN;

INSERT INTO public.film_category (
    film_id,
    category_id
)
SELECT
    temp_table.film_id,
    temp_table.category_id
FROM (
    SELECT
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Barbie')
         LIMIT 1),
        (SELECT c.category_id
         FROM public.category c
         WHERE UPPER(c.name) = UPPER('Comedy')
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Fight Club')
         LIMIT 1),
        (SELECT c.category_id
         FROM public.category c
         WHERE UPPER(c.name) = UPPER('Drama')
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Dune: Part One')
         LIMIT 1),
        (SELECT c.category_id
         FROM public.category c
         WHERE UPPER(c.name) = UPPER('Sci-Fi')
         LIMIT 1)
) temp_table (
    film_id,
    category_id
)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.film_category fc
    WHERE fc.film_id = temp_table.film_id
      AND fc.category_id = temp_table.category_id
)
RETURNING *;

COMMIT;

-- Check Query

SELECT f.title, c.name AS category
FROM public.film f
JOIN public.film_category fc 
	ON fc.film_id = f.film_id
JOIN public.category c 
	ON c.category_id = fc.category_id
WHERE UPPER(f.title) IN ('BARBIE', 'FIGHT CLUB', 'DUNE: PART ONE');

-- Task 1.2.
-- Add the real actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  

-- Q: How was data uniqueness ensured?
-- A: actors: WHERE NOT EXISTS on (first_name + last_name) before each INSERT.
--    film_actor: ON CONFLICT (film_id, actor_id) DO NOTHING relies on the composite pk to skip duplicates.

-- Q: How are relationships between tables established?
-- A: film_actor.film_id resolved via subquery on (title + release_year).
--    film_actor.actor_id resolved via subquery on (first_name + last_name).
--     All FKs always point to valid existing records — if IDs change, subqueries adapt automatically.

-- Task 1.2.1. ACTORS SUBTASK

BEGIN;

INSERT INTO public.actor (first_name, last_name)
SELECT
    temp_table.first_name,
    temp_table.last_name
FROM (
    SELECT UPPER('Edward'), UPPER('Norton')

    UNION ALL

    SELECT UPPER('Brad'), UPPER('Pitt')

    UNION ALL

    SELECT UPPER('Margot'), UPPER('Robbie')

    UNION ALL

    SELECT UPPER('Ryan'), UPPER('Gosling')

    UNION ALL

    SELECT UPPER('Timothee'), UPPER('Chalamet')

    UNION ALL

    SELECT UPPER('Zendaya'), UPPER('Coleman')
) temp_table (
    first_name,
    last_name
)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.actor a
    WHERE UPPER(a.first_name) = UPPER(temp_table.first_name)
      AND UPPER(a.last_name) = UPPER(temp_table.last_name)
)
RETURNING *;

COMMIT;

-- Task 1.2.2. FILM_ACTOR SUBTASK

BEGIN;

INSERT INTO public.film_actor (actor_id, film_id)
SELECT
    temp_table.actor_id,
    temp_table.film_id
FROM (
    SELECT
        (SELECT a.actor_id
         FROM public.actor a
         WHERE UPPER(a.first_name) = UPPER('Margot')
           AND UPPER(a.last_name) = UPPER('Robbie')
         LIMIT 1),
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Barbie')
           AND f.release_year = 2023
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT a.actor_id
         FROM public.actor a
         WHERE UPPER(a.first_name) = UPPER('Ryan')
           AND UPPER(a.last_name) = UPPER('Gosling')
         LIMIT 1),
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Barbie')
           AND f.release_year = 2023
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT a.actor_id
         FROM public.actor a
         WHERE UPPER(a.first_name) = UPPER('Edward')
           AND UPPER(a.last_name) = UPPER('Norton')
         LIMIT 1),
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Fight Club')
           AND f.release_year = 1999
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT a.actor_id
         FROM public.actor a
         WHERE UPPER(a.first_name) = UPPER('Brad')
           AND UPPER(a.last_name) = UPPER('Pitt')
         LIMIT 1),
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Fight Club')
           AND f.release_year = 1999
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT a.actor_id
         FROM public.actor a
         WHERE UPPER(a.first_name) = UPPER('Timothee')
           AND UPPER(a.last_name) = UPPER('Chalamet')
         LIMIT 1),
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Dune: Part One')
           AND f.release_year = 2021
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT a.actor_id
         FROM public.actor a
         WHERE UPPER(a.first_name) = UPPER('Zendaya')
           AND UPPER(a.last_name) = UPPER('Coleman')
         LIMIT 1),
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Dune: Part One')
           AND f.release_year = 2021
         LIMIT 1)
) temp_table (
    actor_id,
    film_id
)
WHERE temp_table.actor_id IS NOT null AND temp_table.film_id IS NOT NULL
ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING *;

COMMIT;

-- Check Query

SELECT f.film_id,
	f.title,
	f.release_year,
	c.name,
	a.last_name,
	a.first_name
FROM public.film f
JOIN public.film_actor fa
	ON f.film_id = fa.film_id
JOIN public.actor a
	ON fa.actor_id = a.actor_id
JOIN public.film_category fc
	ON f.film_id = fc.film_id
JOIN public.category c
	ON fc.category_id = c.category_id
WHERE UPPER(f.title) IN ('BARBIE', 'FIGHT CLUB', 'DUNE: PART ONE');

-- Task 1.3
-- Add your favorite movies to any store's inventory.

-- Q: How was data uniqueness ensured?
-- A: WHERE NOT EXISTS checks (film_id + store_id) before each INSERT.
--    Each film gets only one copy per store, so duplicate inventory rows are never created.

-- Q: How are relationships between tables established?
-- A: inventory.film_id FK resolved dynamically via (title + release_year).
--    inventory.store_id FK resolved dynamically via ORDER BY store_id LIMIT 1.
--    Both FKs always reference valid existing records in film and store tables.

BEGIN;

INSERT INTO public.inventory (
    film_id,
    store_id
)
SELECT
    temp_table.film_id,
    temp_table.store_id
FROM (
    SELECT
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Barbie')
           AND f.release_year = 2023
         LIMIT 1),
        (SELECT s.store_id
         FROM public.store s
         ORDER BY s.store_id
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Fight Club')
           AND f.release_year = 1999
         LIMIT 1),
        (SELECT s.store_id
         FROM public.store s
         ORDER BY s.store_id
         LIMIT 1)

    UNION ALL

    SELECT
        (SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = UPPER('Dune: Part One')
           AND f.release_year = 2021
         LIMIT 1),
        (SELECT s.store_id
         FROM public.store s
         ORDER BY s.store_id
         LIMIT 1)
) temp_table (
    film_id,
    store_id
)
WHERE temp_table.film_id IS NOT NULL
  AND temp_table.store_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM public.inventory i
      WHERE i.film_id = temp_table.film_id
        AND i.store_id = temp_table.store_id
  )
RETURNING *;

COMMIT;

-- Check Query

SELECT i.inventory_id, i.store_id, f.title, f.release_year, i.last_update    
FROM public.inventory i 
JOIN public.film f 
	ON i.film_id = f.film_id
WHERE UPPER(f.title) IN ('BARBIE', 'FIGHT CLUB', 'DUNE: PART ONE');

-- Task 1.4

--Alter any existing customer in the database with at least 43 rental and 43 payment records. 
--Change their personal data to yours (first name, last name, address, etc.). 
--You can use any existing address from the "address" table. 
--Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.

SELECT 
    c.customer_id,
    c.first_name, 
    c.last_name, 
    c.address_id, 
    c.store_id,
    COUNT(DISTINCT p.payment_id) AS payment_count,
    COUNT(DISTINCT r.rental_id) AS rental_count
FROM public.customer c
INNER JOIN public.rental r ON c.customer_id = r.customer_id
INNER JOIN public.payment p ON c.customer_id = p.customer_id
GROUP BY 
	c.customer_id,
    c.first_name, 
    c.last_name, 
    c.address_id, 
    c.store_id
HAVING COUNT(DISTINCT p.payment_id) >= 43 
   AND COUNT(DISTINCT r.rental_id) >= 43
ORDER BY c.customer_id asc
LIMIT 1;

BEGIN;

UPDATE public.customer
SET
    first_name = 'ALEXANDRA',
    last_name = 'MANICA',
    email = 'alexandra.manica@gmail.com',
    address_id = (SELECT a.address_id FROM public.address a ORDER BY a.address_id LIMIT 1),
    active = 1
WHERE customer_id = (
    SELECT c.customer_id
    FROM public.customer c
    INNER JOIN public.rental r ON c.customer_id = r.customer_id
    INNER JOIN public.payment p ON c.customer_id = p.customer_id
    WHERE c.store_id = (SELECT s.store_id FROM public.store s ORDER BY s.store_id LIMIT 1)
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT p.payment_id) >= 43
       AND COUNT(DISTINCT r.rental_id) >= 43
    ORDER BY c.customer_id
    LIMIT 1
)
RETURNING *;

COMMIT;

-- Check Query

SELECT 
    c.customer_id,
    c.first_name, 
    c.last_name, 
    c.address_id, 
    c.store_id,
    p.payment_id 
FROM public.customer c
INNER JOIN public.payment p ON c.customer_id = p.customer_id
WHERE c.first_name  = 'ALEXANDRA' and c.last_name = 'MANICA';

SELECT 
    c.customer_id,
    c.first_name, 
    c.last_name, 
    c.address_id, 
    c.store_id,
    r.rental_id 
FROM public.customer c
INNER JOIN public.rental r ON c.customer_id = r.customer_id
WHERE c.first_name  = 'ALEXANDRA' and c.last_name = 'MANICA';

-- Task 1.5. Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'

-- Q: Why is deleting from these tables safe?
-- A: I delete in correct FK order: payment first, then rental.
--    payment references rental via rental_id - deleting payment first removes the child record before the parent (rental) is deleted.
--    This respects all FK constraints and avoids constraint violation errors. 

-- Q: How was no unintended data loss ensured?
-- A: All DELETEs are scoped to customer_id resolved by (first_name + last_name).

BEGIN;

WITH deleted_payments AS (
    DELETE FROM public.payment p
    WHERE p.customer_id = (
        SELECT c.customer_id
        FROM public.customer c
        WHERE c.first_name = 'ALEXANDRA'
          AND c.last_name = 'MANICA'
        LIMIT 1
    )
    RETURNING 'payment_table' AS table_name, p.payment_id AS id
),
deleted_rentals AS (
    DELETE FROM public.rental r
    WHERE r.customer_id = (
        SELECT c.customer_id
        FROM public.customer c
        WHERE c.first_name = 'ALEXANDRA'
          AND c.last_name = 'MANICA'
        LIMIT 1
    )
    RETURNING 'rental_table' AS table_name, r.rental_id AS id
)
SELECT * FROM deleted_payments
UNION ALL
SELECT * FROM deleted_rentals;

COMMIT;

-- Task 1.6. 
--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition 
-- or add records for the first half of 2017)

-- Q: How was data uniqueness ensured?
-- A: Rentals: WHERE NOT EXISTS checks for open rental (return_date IS NULL)
--    on the same inventory_id — prevents renting an already rented film.
--    Payments: WHERE NOT EXISTS checks if a payment already exists
--    for the same rental_id — prevents double charging.

-- Q: How are relationships between tables established?
-- A: rental.inventory_id resolved via subquery on (film title + store).
--    rental.customer_id resolved via subquery on (first_name + last_name).
--    payment.rental_id resolved via subquery on (customer_id + inventory_id).
--    All FKs point to valid existing records — no hardcoded IDs anywhere.

-- Task 1.6.1. RENTAL SUBTASK

BEGIN;

INSERT INTO public.rental (
    rental_date,
    inventory_id,
    customer_id,
    staff_id,
    return_date
)
SELECT
    temp_table.rental_date,
    temp_table.inventory_id,
    temp_table.customer_id,
    temp_table.staff_id,
    temp_table.return_date
FROM (
    SELECT
        make_timestamptz(2017, 1, 15, 11, 30, 0, 'Europe/Bucharest'),
        (
            SELECT i.inventory_id
            FROM public.inventory i
            JOIN public.film f
                ON i.film_id = f.film_id
            WHERE UPPER(f.title) = UPPER('Barbie')
              AND i.store_id = (
                  SELECT s.store_id
                  FROM public.store s
                  ORDER BY s.store_id
                  LIMIT 1
              )
            LIMIT 1
        ),
        (
            SELECT c.customer_id
            FROM public.customer c
            WHERE c.first_name = 'ALEXANDRA'
              AND c.last_name = 'MANICA'
            LIMIT 1
        ),
        (SELECT MIN(s.staff_id) FROM public.staff s),
        make_timestamptz(2017, 1, 29, 10, 30, 0, 'Europe/Bucharest')

    UNION ALL

    SELECT
        make_timestamptz(2017, 1, 16, 16, 30, 0, 'Europe/Bucharest'),
        (
            SELECT i.inventory_id
            FROM public.inventory i
            JOIN public.film f
                ON i.film_id = f.film_id
            WHERE UPPER(f.title) = UPPER('Fight Club')
            LIMIT 1
        ),
        (
            SELECT c.customer_id
            FROM public.customer c
            WHERE c.first_name = 'ALEXANDRA'
              AND c.last_name = 'MANICA'
            LIMIT 1
        ),
        (SELECT MIN(s.staff_id) FROM public.staff s),
        make_timestamptz(2017, 1, 30, 18, 30, 0, 'Europe/Bucharest')

    UNION ALL

    SELECT
        make_timestamptz(2017, 1, 1, 14, 30, 0, 'Europe/Bucharest'),
        (
            SELECT i.inventory_id
            FROM public.inventory i
            JOIN public.film f
                ON i.film_id = f.film_id
            WHERE UPPER(f.title) = UPPER('Dune: Part One')
            LIMIT 1
        ),
        (
            SELECT c.customer_id
            FROM public.customer c
            WHERE c.first_name = 'ALEXANDRA'
              AND c.last_name = 'MANICA'
            LIMIT 1
        ),
        (SELECT MIN(s.staff_id) FROM public.staff s),
        make_timestamptz(2017, 1, 22, 16, 30, 0, 'Europe/Bucharest')
) temp_table (
    rental_date,
    inventory_id,
    customer_id,
    staff_id,
    return_date
)
WHERE temp_table.inventory_id IS NOT NULL
  AND temp_table.customer_id IS NOT NULL
  AND temp_table.staff_id IS NOT NULL
  AND NOT EXISTS (
  	SELECT 1
    FROM public.rental r
    WHERE r.inventory_id = temp_table.inventory_id
    	AND r.customer_id = temp_table.customer_id
      	AND r.rental_date = temp_table.rental_date
)
RETURNING *;

COMMIT;

-- Check query

SELECT
    r.rental_id,
    f.title,
    r.rental_date,
    r.return_date,
    c.first_name,
    c.last_name
FROM public.rental r
JOIN public.inventory i 
	ON i.inventory_id = r.inventory_id
JOIN public.film f 
	ON f.film_id = i.film_id
JOIN public.customer c 
	ON c.customer_id = r.customer_id
WHERE c.first_name = 'ALEXANDRA'
  AND c.last_name = 'MANICA'
ORDER BY r.rental_date;

-- Task 1.6.2. PAYMENT SUBTASK

BEGIN;

INSERT INTO public.payment (
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date
)
SELECT
    temp_table.customer_id,
    temp_table.staff_id,
    temp_table.rental_id,
    temp_table.amount,
    temp_table.payment_date
FROM (
    SELECT
        (
            SELECT c.customer_id
            FROM public.customer c
            WHERE c.first_name = 'ALEXANDRA'
              AND c.last_name = 'MANICA'
            LIMIT 1
        ),
        (SELECT MIN(s.staff_id) FROM public.staff s),
        (
            SELECT r.rental_id
            FROM public.rental r
            WHERE r.customer_id = (
                SELECT c.customer_id
                FROM public.customer c
                WHERE c.first_name = 'ALEXANDRA'
                  AND c.last_name = 'MANICA'
                LIMIT 1
            )
              AND r.inventory_id = (
                  SELECT i.inventory_id
                  FROM public.inventory i
                  JOIN public.film f
                    ON i.film_id = f.film_id
                  WHERE UPPER(f.title) = UPPER('Barbie')
                    AND i.store_id = (
                        SELECT s.store_id
                        FROM public.store s
                        ORDER BY s.store_id
                        LIMIT 1
                    )
                  LIMIT 1
              )
            LIMIT 1
        ),
        4.99,
        make_timestamptz(2017, 1, 29, 10, 33, 0, 'Europe/Bucharest')

    UNION ALL

    SELECT
        (
            SELECT c.customer_id
            FROM public.customer c
            WHERE c.first_name = 'ALEXANDRA'
              AND c.last_name = 'MANICA'
            LIMIT 1
        ),
        (SELECT MIN(s.staff_id) FROM public.staff s),
        (
            SELECT r.rental_id
            FROM public.rental r
            WHERE r.customer_id = (
                SELECT c.customer_id
                FROM public.customer c
                WHERE c.first_name = 'ALEXANDRA'
                  AND c.last_name = 'MANICA'
                LIMIT 1
            )
              AND r.inventory_id = (
                  SELECT i.inventory_id
                  FROM public.inventory i
                  JOIN public.film f
                    ON i.film_id = f.film_id
                  WHERE UPPER(f.title) = UPPER('Fight Club')
                    AND i.store_id = (
                        SELECT s.store_id
                        FROM public.store s
                        ORDER BY s.store_id
                        LIMIT 1
                    )
                  LIMIT 1
              )
            LIMIT 1
        ),
        9.99,
        make_timestamptz(2017, 1, 30, 18, 31, 0, 'Europe/Bucharest')

    UNION ALL

    SELECT
        (
            SELECT c.customer_id
            FROM public.customer c
            WHERE c.first_name = 'ALEXANDRA'
              AND c.last_name = 'MANICA'
            LIMIT 1
        ),
        (SELECT MIN(s.staff_id) FROM public.staff s),
        (
            SELECT r.rental_id
            FROM public.rental r
            WHERE r.customer_id = (
                SELECT c.customer_id
                FROM public.customer c
                WHERE c.first_name = 'ALEXANDRA'
                  AND c.last_name = 'MANICA'
                LIMIT 1
            )
              AND r.inventory_id = (
                  SELECT i.inventory_id
                  FROM public.inventory i
                  JOIN public.film f
                    ON i.film_id = f.film_id
                  WHERE UPPER(f.title) = UPPER('Dune: Part One')
                    AND i.store_id = (
                        SELECT s.store_id
                        FROM public.store s
                        ORDER BY s.store_id
                        LIMIT 1
                    )
                  LIMIT 1
              )
            LIMIT 1
        ),
        19.99,
        make_timestamptz(2017, 1, 22, 16, 33, 0, 'Europe/Bucharest')
) temp_table (
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date
)
WHERE temp_table.customer_id IS NOT NULL
  AND temp_table.staff_id IS NOT NULL
  AND temp_table.rental_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM public.payment p
      WHERE p.rental_id = temp_table.rental_id
  )
RETURNING *;

COMMIT;



-- Check Query

SELECT
    p.payment_id,
    f.title,
    r.rental_date,
    r.return_date,
    c.first_name,
    c.last_name
FROM payment p 
JOIN public.rental r 
	ON p.rental_id = r.rental_id 
JOIN public.inventory i 
	ON i.inventory_id = r.inventory_id
JOIN public.film f 
	ON f.film_id = i.film_id
JOIN public.customer c 
	ON c.customer_id = r.customer_id
WHERE c.first_name = 'ALEXANDRA'
  AND c.last_name = 'MANICA'
ORDER BY r.rental_date;

-- GENERAL QUESTION

-- REQUEST: In the comments explain:
-- Why a separate transaction is used
-- What would happen if the transaction fails
-- Whether rollback is possible and what data would be affected
-- How referential integrity is preserved
-- How your script avoids duplicates

-- Q: Why is a separate transaction used for each subtask?
-- A: Each subtask is isolated in its own transaction so that if one fails,  the others are not affected. 
-- For example if actor insertion fails, films that were already committed remain intact

-- Q: What would happen if the transaction fails?
-- A: PostgreSQL automatically rolls back all changes made within the failed transaction.
-- Either all inserts/updates within the transaction succeed or none of them do.

-- Q: Is rollback possible and what data would be affected?
-- A: Yes, rollback is possible at any point before COMMIT is executed.
-- Only the data modified within the current transaction would be rolled back.
-- The data committed in previous transactions remains intact.

-- Q: How is referential integrity preserved?
-- A: All foreign key values are resolved dynamically via subqueries instead of hardcoded IDs. 
-- If IDs change, subqueries adapt automatically.

-- Q: How does the script avoid duplicates?
-- A: To avoid duplicates, I've used the following three strategies:
--    1. WHERE NOT EXISTS 
-- - Used when the table does not have a UNIQUE constraint or PRIMARY KEY on the columns we want to check for duplicates.
-- - Before each INSERT, a SELECT runs first to check if the record already exists in the table. 
-- - If it does, the INSERT is skipped, if it does not, the INSERT proceeds.
--    2. ON CONFLICT ... DO NOTHING 
-- - Used for tables with a composite PRIMARY KEY (ex: film_actor, film_category).
-- - PostgreSQL detects the conflict on the PK and skips the INSERT.
--    3. LIMIT 1 on all subqueries 
-- - Ensures subqueries always return exactly one value, preventing "more than one row returned" errors.
