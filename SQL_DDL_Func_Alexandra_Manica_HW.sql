
-- Task 1.
-- Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. 
-- The view should only display categories with at least one sale in the current quarter.
 
-- Note:
-- If input parameters are incorrect: Not applicable here, as the view does not take input parameters.
-- If required data is missing, the view returns an empty result set (0 rows), without errors.
-- Because we're creating a view, RAISE EXCEPTION cannot be used here.

-- Q: Explain in the comment how you determine:
-- 1. current quarter
-- 2. current year
-- 3. why only categories with sales appear
-- 4. how zero-sales categories are excluded
-- the current default database does not contain data for the current year. Also, please indicate how you verified that view is working correctly

-- A:
-- 1. Current quarter is determined dynamically using DATE_PART('quarter', CURRENT_DATE)
-- 2. Current year is determined dynamically using DATE_PART('year', CURRENT_DATE)
-- 3. Only categories with sales appear because INNER JOINs include only records that have matching rentals and payments
-- 4. Zero-sales categories are excluded using HAVING SUM(p.amount) > 0
-- 5. The default dvdrental database does not contain data for the current year, so the view may return 0 rows
-- The view was verified by running a SELECT on it (test cases presented below) and by checking existing years and quarters in the payment table to confirm data availability.

--Q: Provide example of data that should NOT appear
--A: Categories with sales from previous years or quarters, categories with no sales, and categories with total revenue equal to 0.
categories with sales from previous quarters
categories with no sales at all
categories whose total revenue is 0

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT
    c.name AS category_name,
    SUM(p.amount) AS total_sales_revenue
FROM public.category c
JOIN public.film_category fc
    ON c.category_id = fc.category_id
JOIN public.inventory i
    ON fc.film_id = i.film_id
JOIN public.rental r
    ON i.inventory_id = r.inventory_id
JOIN public.payment p
    ON r.rental_id = p.rental_id
WHERE DATE_PART('year', p.payment_date) = DATE_PART('year', CURRENT_DATE)
  AND DATE_PART('quarter', p.payment_date) = DATE_PART('quarter', CURRENT_DATE)
GROUP BY c.name
HAVING SUM(p.amount) > 0;

-- T1. Valid Test Case
-- This test case returns current quarter/current year sales by category.
-- In the case of dvdrental database, it returns 0 rows because there is no current-year data.

SELECT *
FROM sales_revenue_by_category_qtr;

-- T1. Edge/ No Matching Data Test Case
-- -- This test case checks how the view behaves when no data exists for the current period.
-- Expected result: 0 rows (count=0), without errors.

SELECT COUNT(*)
FROM sales_revenue_by_category_qtr;


-- Task 2.
-- Create a query language function called 'get_sales_revenue_by_category_qtr'
-- that accepts one parameter representing the current quarter and year
-- and returns the same result as the 'sales_revenue_by_category_qtr' view.

-- Note 1:
-- I chose to use a DATE parameter because the requirement was to have a single parameter representing both the current quarter and year.
-- By using a DATE, both values can be extracted using DATE_PART, which avoids the need for separate parameters.


-- Note 2:
-- This function is written in SQL and because of that, RAISE EXCEPTION cannot be used here.
-- In this implementation, an invalid quarter cannot be passed directly, because the function accepts a DATE parameter and derives the quarter automatically.
-- If NULL is passed, the function returns 0 rows.
-- If required data is missing, the function returns 0 rows without errors.

-- Q: Explain in the comment:
-- 1. why parameter is needed
-- 2. what happens if invalid quarter is passed
-- 3. what happens if no data exists

-- A:
-- 1. The parameter is needed to make the function reusable for any quarter and year, not only for the current one.
-- 2. An invalid quarter cannot be passed directly in this implementation, 
-- because the quarter is derived from the input date using DATE_PART('quarter', p_ref_date).
-- 3. If no data exists for the selected quarter and year, the function returns 0 rows without errors.

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(p_ref_date DATE)
RETURNS TABLE (
    category_name TEXT,
    total_sales_revenue NUMERIC
)
LANGUAGE SQL
AS
$$
SELECT
    c.name AS category_name,
    SUM(p.amount) AS total_sales_revenue
FROM public.category c
JOIN public.film_category fc
    ON c.category_id = fc.category_id
JOIN public.inventory i
    ON fc.film_id = i.film_id
JOIN public.rental r
    ON i.inventory_id = r.inventory_id
JOIN public.payment p
    ON r.rental_id = p.rental_id
WHERE DATE_PART('year', p.payment_date) = DATE_PART('year', p_ref_date)
  AND DATE_PART('quarter', p.payment_date) = DATE_PART('quarter', p_ref_date)
GROUP BY c.name
HAVING SUM(p.amount) > 0;
$$;

-- T2. Valid Test Case

-- This test case returns sales revenue by category for the quarter and year derived from the input date.
-- In this case, the expected result is 16 categories along with their corresponding revenue.

SELECT *
FROM get_sales_revenue_by_category_qtr(DATE '2017-02-10');

-- T2. Edge Test Case

-- The function accepts a DATE parameter, so an invalid quarter cannot be passed directly, because both the quarter and year are derived from the input date.
-- This test case checks how the function behaves when:
-- 		1. A valid date is provided, but no data exists for that quarter and year
-- 		2. A NULL value is passed as input
-- In both cases, the function returns 0 rows without errors.
-- When NULL is passed, DATE_PART returns NULL, so the filter conditions are not met.

SELECT *
FROM get_sales_revenue_by_category_qtr(CURRENT_DATE);

SELECT *
FROM get_sales_revenue_by_category_qtr(NULL);

-- Task 3.

-- Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
--The function should format the result set as follows: Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);

-- Note:
-- If input parameters are incorrect (ex: input array is NULL or empty), the function raises an exception.
-- If required data is missing, countries with no matching rental data are excluded from the result set.

-- Q: Explain in the comment:
-- 1. how "most popular" is defined
-- 2. how ties are handled
-- 3. what happens if a country has no data

-- A:
-- 1. "Most popular" is defined by rental count. The film with the highest number of rentals in each country is returned.
-- 2. If multiple films have the same rental count, the function returns the alphabetically first film title.
-- 3. If a country has no matching rental data, it does not appear in the result set.


CREATE OR REPLACE FUNCTION most_popular_films_by_countries(p_countries TEXT[])
RETURNS TABLE(
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length SMALLINT,
    release_year INTEGER
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF p_countries IS NULL OR array_length(p_countries, 1) IS NULL THEN
        RAISE EXCEPTION 'Input parameter cannot be NULL or empty.';
    END IF;

    RETURN QUERY
    WITH film_rentals AS (
        SELECT 
            c.country,
            f.title AS film,
            f.rating::TEXT AS rating,
            l.name::TEXT AS language,
            f.length,
            f.release_year::INTEGER,
            COUNT(r.rental_id) AS rental_count
        FROM public.country c
        INNER JOIN public.city ci
            ON c.country_id = ci.country_id
        INNER JOIN public.address a 
            ON ci.city_id = a.city_id
        INNER JOIN public.customer cu
            ON a.address_id = cu.address_id
        INNER JOIN public.rental r 
            ON cu.customer_id = r.customer_id
        INNER JOIN public.inventory i 
            ON r.inventory_id = i.inventory_id
        INNER JOIN public.film f 
            ON i.film_id = f.film_id
        INNER JOIN public.language l 
            ON f.language_id = l.language_id
        WHERE c.country = ANY(p_countries)
        GROUP BY 
            c.country,
            f.title,
            f.rating,
            l.name,
            f.length,
            f.release_year
    ) 
    SELECT 
        fr.country,
        fr.film,
        fr.rating,
        fr.language,
        fr.length,
        fr.release_year
    FROM film_rentals fr
    WHERE fr.rental_count = (
        SELECT MAX(fr2.rental_count)
        FROM film_rentals fr2
        WHERE fr.country = fr2.country
    )
    AND fr.film = (
        SELECT MIN(fr3.film)
        FROM film_rentals fr3
        WHERE fr.country = fr3.country
          AND fr3.rental_count = fr.rental_count
    )
    ORDER BY fr.country;

END;
$$;

-- T3. Valid Test Case
-- This test case returns the most popular film for each country in the input array, based on the highest number of rentals.

SELECT *
FROM most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);

-- T3. Edge / Invalid Input Test Case
-- This test checks how the function behaves when the input array is NULL. 
-- Expected result: an exception is raised.

SELECT *
FROM most_popular_films_by_countries(NULL);

-- T3. Missing Data Test Case
-- This test checks how the function behaves when a country has no rental data.
-- Expected result: countries with no matching data do not appear in the result set.

SELECT *
FROM most_popular_films_by_countries(ARRAY['Morroco', 'Brazil']);

-- Task 4.
--Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies containing the word 'love' in their title). 
--The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a message indicating that it was not found.
--The function should produce the result set in the following format (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
-- Query (example):select * from core.films_in_stock_by_title('%love%’);

-- Note 1:
-- Based on the teams discussion, the function returns the most recent customer who rented the film, along with the most recent rental date.
-- To ensure a single result per film and avoid duplicates in cases where multiple rentals have the same rental_date, an additional tie-breaker is used
-- (MAX(rental_id)), to make sure that only one rental record is selected.

-- Note 2:
-- If input parameters are incorrect (ex: the title pattern is NULL or empty), the function raises an exception.
-- If required data is missing, the function returns one row with a message indicating that the movie was not found in stock.

-- Q: Explain in the comment:
-- 1. how pattern matching works (LIKE, %)
-- 2. how you ensure performance
-- 3. case sensitivity
-- 4. what happens if multiple matches
-- 5. what happens if no matches

-- A:
-- 1. Pattern matching is done using ILIKE and the % wildcard matching any sequence of characters before, after, or inside the title.
-- 2. To reduce unnecessary processing, the query first filters matching titles
--    and then checks stock availability and the most recent rental only for those films.
-- 3. The search is case-insensitive because ILIKE is used instead of LIKE.
-- 4. If multiple matches exist, all matching films currently in stock are returned.
-- 5. If no matches exist, the function returns one row with a message indicating that the movie was not found in stock.

CREATE OR REPLACE FUNCTION films_in_stock_by_title(p_title_pattern TEXT)
RETURNS TABLE (
    row_num INT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date TIMESTAMP,
    customer_message TEXT
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_counter INT := 0;
    v_found BOOLEAN := FALSE;
    rec RECORD;
BEGIN
    IF p_title_pattern IS NULL OR TRIM(p_title_pattern) = '' THEN
        RAISE EXCEPTION 'Input title pattern cannot be NULL or empty.';
    END IF;

    FOR rec IN
        SELECT 
            f.title AS film_title,
            l.name AS language,
            c.first_name || ' ' || c.last_name AS customer_name,
            r.rental_date
        FROM public.film f 
        INNER JOIN public.language l 
            ON f.language_id = l.language_id
        INNER JOIN public.inventory i 
            ON f.film_id = i.film_id
        INNER JOIN public.rental r 
            ON i.inventory_id = r.inventory_id
        INNER JOIN public.customer c 
            ON r.customer_id = c.customer_id
        WHERE f.title ILIKE p_title_pattern
        AND EXISTS (
            SELECT 1 
            FROM public.inventory i2 
            LEFT JOIN public.rental r2
                ON i2.inventory_id = r2.inventory_id
               AND r2.return_date IS NULL
            WHERE i2.film_id = f.film_id 
              AND r2.rental_id IS NULL
        )
        AND r.rental_id = (
            SELECT MAX(r3.rental_id)
            FROM public.rental r3
            INNER JOIN public.inventory i3
                ON r3.inventory_id = i3.inventory_id
            WHERE i3.film_id = f.film_id
              AND r3.rental_date = (
                  SELECT MAX(r4.rental_date)
                  FROM public.rental r4
                  INNER JOIN public.inventory i4
                      ON r4.inventory_id = i4.inventory_id
                  WHERE i4.film_id = f.film_id
              )
        )
        ORDER BY f.title
    LOOP
        v_found := TRUE;
        v_counter := v_counter + 1;

        row_num := v_counter;
        film_title := rec.film_title;
        language := rec.language;
        customer_name := rec.customer_name;
        rental_date := rec.rental_date;
        customer_message := NULL;

        RETURN NEXT;
    END LOOP;

    IF NOT v_found THEN
        row_num := 1;
        film_title := NULL;
        language := NULL;
        customer_name := NULL;
        rental_date := NULL;
        customer_message := 'Movie not found in stock.';
        RETURN NEXT;
    END IF;

END;
$$;

-- T4. Valid Test Case
-- This test returns all films currently in stock whose title matches the given pattern.

SELECT *
FROM films_in_stock_by_title('%love%');

-- T4. Edge / Invalid Input Test Case
-- This test checks how the function behaves when the input pattern is NULL.
-- Expected result: an exception is raised.

SELECT *
FROM films_in_stock_by_title(NULL);

-- T4. No Match Test Case
-- This test checks how the function behaves when no film in stock matches the pattern.
-- Expected result: one row is returned with a message indicating that the movie was not found in stock.

SELECT *
FROM films_in_stock_by_title('%No movies match%');

-- Task 5

--Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie with the given title in the film table. The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. The release year and language are optional and by default should be current year and Klingon respectively. 
--The function should also verify that the language exists in the 'language' table. 
--The function must prevent inserting duplicate movie titles and raise an exception if duplicate exists.
--Ensure that no such function has been created before; if so, replace it.

--Note:
-- If input parameters are incorrect (ex: the title is NULL or empty), the function raises an exception.
-- If required data is missing (ex: the specified language does not exist), the function raises an exception and the movie is not inserted.

--Q: Explain in the comment:
--1. how you generate unique ID
--2. how you ensure no duplicates
--3. what happens if movie already exists
--4. how you validate language existence
--5. what happens if insertion fails
--6. how consistency is preserved

-- A:
-- 1. A new unique film_id is generated using MAX(film_id) + 1.
-- 2. Duplicate titles are prevented by checking the film table before insertion.
-- 3. If the movie already exists, the function raises an exception and the insert is not performed.
-- 4. Language existence is validated by checking the language table and retrieving the corresponding language_id.
-- 5. If insertion fails, PostgreSQL rolls back the failed statement automatically.
-- 6. Consistency is preserved by validating both title uniqueness and language existence before inserting the new row.

CREATE OR REPLACE FUNCTION new_movie(
    p_title TEXT,
    p_release_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    p_language_name TEXT DEFAULT 'Klingon'
)
RETURNS VOID
LANGUAGE plpgsql
AS
$$
DECLARE
    v_new_film_id INTEGER;
    v_language_id INTEGER;
BEGIN

    IF p_title IS NULL OR TRIM(p_title) = '' THEN
        RAISE EXCEPTION 'Movie title cannot be NULL or empty.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.film f
        WHERE UPPER(f.title) = UPPER(p_title)
    ) THEN
        RAISE EXCEPTION 'Movie title "%" already exists.', p_title;
    END IF;

    SELECT l.language_id
    INTO v_language_id
    FROM public.language l
    WHERE UPPER(l.name) = UPPER(p_language_name);

    IF v_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" does not exist in the language table.', p_language_name;
    END IF;

    SELECT COALESCE(MAX(film_id), 0) + 1
    INTO v_new_film_id
    FROM public.film;

    INSERT INTO public.film (
        film_id,
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        length,
        replacement_cost,
        rating,
        last_update
    )
    VALUES (
        v_new_film_id,
        p_title,
        NULL,
        p_release_year,
        v_language_id,
        3,
        4.99,
        NULL,
        19.99,
        'G',
        CURRENT_TIMESTAMP
    );

END;
$$;

-- T5. Valid Test Case with Optional Parameters
-- This test inserts a new movie with a custom release year and language.

SELECT new_movie('Deadpool', 2016, 'English');

SELECT * FROM public.film f WHERE f.title = 'Deadpool';

-- T5. Edge / Duplicate Title Test Case
-- This test checks how the function behaves when the movie title already exists.
-- Expected result: an exception is raised.

SELECT new_movie('ACADEMY DINOSAUR');

-- T5. Edge / Invalid Language Test Case
-- This test checks how the function behaves when the language does not exist.
-- Expected result: an exception is raised.

SELECT new_movie('Parasite', 2025, 'Unknown Language');


-- Task 6.2 + 6.7
--The initial function returns 0 rows because it filters payments based on a month calculated from the current date, 
-- while the dvdrental database contains data up to 2017 , so no records match the date range.
 
--The function was corrected by replacing the CURRENT_DATE with the maximum payment_date from the payment table, 
--ensuring that the date range matches the available data while preserving the original structure of the function.

-- The corrected function is presented below:

CREATE OR REPLACE FUNCTION public.rewards_report_date_correction_applied(min_monthly_purchases integer, min_dollar_amount_purchased numeric)
RETURNS SETOF customer
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
    rr RECORD;
    tmpSQL TEXT;
BEGIN

    IF min_monthly_purchases = 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;

    IF min_dollar_amount_purchased = 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    SELECT DATE_TRUNC('month', MAX(payment_date))::date
    INTO last_month_start
    FROM payment;

    last_month_end := LAST_DAY(last_month_start);

    CREATE TEMPORARY TABLE tmpCustomer (customer_id INTEGER NOT NULL PRIMARY KEY);

    tmpSQL := 'INSERT INTO tmpCustomer (customer_id)
        SELECT p.customer_id
        FROM payment AS p
        WHERE DATE(p.payment_date) BETWEEN '||quote_literal(last_month_start)||' AND '||quote_literal(last_month_end)||'
        GROUP BY customer_id
        HAVING SUM(p.amount) > '|| min_dollar_amount_purchased || '
        AND COUNT(customer_id) > ' || min_monthly_purchases;

    EXECUTE tmpSQL;

    FOR rr IN EXECUTE '
        SELECT c.*
        FROM tmpCustomer t
        JOIN customer c ON t.customer_id = c.customer_id
    ' LOOP
        RETURN NEXT rr;
    END LOOP;

    tmpSQL := 'DROP TABLE tmpCustomer';
    EXECUTE tmpSQL;

RETURN;
END
$function$;

-- The function was rewritten , eliminating the the dynamic SQL, temporary tables, and EXECUTE statements, 
-- since all table names and conditions are fixed.
CREATE OR REPLACE FUNCTION public.rewards_report_corrected_v2(
    min_monthly_purchases integer,
    min_dollar_amount_purchased numeric
)
RETURNS SETOF customer
LANGUAGE plpgsql
AS
$$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
BEGIN

    IF min_monthly_purchases <= 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;

    IF min_dollar_amount_purchased <= 0 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > 0';
    END IF;

    SELECT DATE_TRUNC('month', MAX(payment_date))::date
    INTO last_month_start
    FROM payment;

    last_month_end := LAST_DAY(last_month_start);

    RETURN QUERY
    SELECT c.*
    FROM customer c
    JOIN (
        SELECT p.customer_id
        FROM payment p
        WHERE p.payment_date::date BETWEEN last_month_start AND last_month_end
        GROUP BY p.customer_id
        HAVING SUM(p.amount) > min_dollar_amount_purchased
           AND COUNT(*) > min_monthly_purchases
    ) t
    ON c.customer_id = t.customer_id;

END;
$$;

-- Initial function test case
SELECT * FROM rewards_report(1,1)

-- Corrected function test case
SELECT * FROM rewards_report_date_correction_applied(1,1)

 --Corrected function test case - without dymanic sql
SELECT * FROM rewards_report_corrected_v2(1,1)

-- Task 6.4.

CREATE OR REPLACE FUNCTION public.get_customer_balance_corrected(
    p_customer_id integer,
    p_effective_date timestamp with time zone
)
RETURNS numeric
LANGUAGE plpgsql
AS
$$
DECLARE
    v_balance numeric(10,2);
BEGIN

    SELECT COALESCE(SUM(
        f.rental_rate
        + GREATEST(
            0,
            (
                (
                    COALESCE(r.return_date, p_effective_date)::date 
                    - r.rental_date::date
                ) - f.rental_duration
            )
        )
        + CASE
            WHEN (
                COALESCE(r.return_date, p_effective_date)::date 
                - r.rental_date::date
            ) > (f.rental_duration * 2)
            THEN f.replacement_cost
            ELSE 0
          END

    ), 0)
    INTO v_balance
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.customer_id = p_customer_id
      AND r.rental_date <= p_effective_date;

    v_balance := v_balance - COALESCE((
        SELECT SUM(p.amount)
        FROM payment p
        WHERE p.customer_id = p_customer_id
          AND p.payment_date <= p_effective_date
    ), 0);

    RETURN v_balance;

END;
$$;

-- Initial function test case
SELECT * FROM get_customer_balance(100, '2017-02-03')

-- Corrected function test case
SELECT * FROM get_customer_balance_corrected(100, '2017-02-03')