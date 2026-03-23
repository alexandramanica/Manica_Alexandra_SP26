-- P1. Task 1:
-- The marketing team needs a list of animation movies between 2017 and 2019 to promote family-friendly content in an upcoming season in stores.
-- Show all animation movies released during this period with rate more than 1, sorted alphabetically
--
-- Assumptions:
-- "rate more than 1" is interpreted as rental_rate > 1
-- "family-friendly" is filtered by rating column assuming that only the movies that are rated as 'G' or 'PG' are considered family friendly
-- release_year BETWEEN 2017 AND 2019
-- schema: public

-- Advantages, disavantages and production choice:
--a) JOIN Solution - *Production Choice*
-- most readable and performant for this task
-- all filters in one place, easy to follow
-- if a film had multiple categories it could cause duplicates (not an issue here)

-- b) SUBQUERY Solution
-- clearly separates "what is animation" from "what are the filters"
-- IN() with subquery less readable than JOIN
-- cannot easily add extra columns from category without rewriting

-- c) CTE Solution
-- most readable for complex queries, easy to debug
-- reusable — can be referenced multiple times in the same query
-- slight over-engineering for a simple filter like this one

-- a) JOIN Solution
-- INNER JOIN ensures only films that have a matching category are returned
-- If a film has no category assigned it will be excluded from results
SELECT
    f.title AS film_title,
    f.release_year,
    f.rating AS film_rating,
    f.rental_rate AS rental_rate
FROM public.film f
INNER JOIN public.film_category fc
    ON f.film_id = fc.film_id
INNER JOIN public.category c
    ON fc.category_id = c.category_id
WHERE c.name = 'Animation'
	AND f.rating IN ('G', 'PG')
  	AND f.rental_rate > 1
  	AND f.release_year BETWEEN 2017 AND 2019
ORDER BY f.title;


-- b) SUBQUERY Solution
SELECT
	f.title AS film_title,
    f.release_year,
    f.rating AS film_rating,
    f.rental_rate AS rental_rate
FROM public.film f
WHERE f.rental_rate > 1
	AND f.rating IN ('G', 'PG')
	AND f.release_year BETWEEN 2017 AND 2019
	AND f.film_id IN (
		SELECT fc.film_id
      	FROM public.film_category fc
      	INNER JOIN public.category c
        	ON fc.category_id = c.category_id
	WHERE c.name = 'Animation'
)
ORDER BY f.title;


-- c) CTE Solution
WITH animation_films AS (
    SELECT fc.film_id
    FROM public.film_category fc
    INNER JOIN public.category c
        ON fc.category_id = c.category_id
    WHERE c.name = 'Animation'
)
SELECT
	f.title AS film_title,
    f.release_year,
    f.rating AS film_rating,
    f.rental_rate AS rental_rate
FROM public.film f
INNER JOIN animation_films a
    ON a.film_id = f.film_id
WHERE f.rental_rate > 1
  	AND f.release_year BETWEEN 2017 AND 2019
	AND f.rating IN ('G', 'PG')
ORDER BY f.title;

--P1. Task 2:

--The finance department requires a report on store performance to assess profitability and plan resource allocation for stores after March 2017.
-- Calculate the revenue earned by each rental store after March 2017 (since April) (include columns: address and address2 – as one column, revenue)

-- Assumptions:
-- "after March 2017" is interpreted as payment_date >= '2017-04-01'
-- address2 can be NULL so COALESCE is used to replace it with empty string
-- revenue is calculated via payment table, joined through inventory - rental - payment
-- schema: public

-- Advantages, disavantages and production choice:
--a) JOIN Solution - *Production Choice*
-- simplest and most direct — everything in one query
-- GROUP BY on a concatenated expression is less clean than grouping on columns
-- harder to reuse the revenue calculation elsewhere in the same query

-- b) SUBQUERY Solution
-- cleanly separates aggregation (revenue) from presentation (address)
-- outer query is easy to read — just joining pre-calculated results
-- store table is joined twice (once inside subquery, once outside) which is redundant and adds unnecessary complexity

-- c) CTE Solution
-- same separation of concerns as subquery but more readable
-- most readable for complex queries, easy to debug
-- reusable — can be referenced multiple times in the same query
-- slight over-engineering 

-- a) JOIN Solution
-- INNER JOIN ensures only stores with actual payments after March 2017 are included
-- stores with no rentals or no payments in this period will be excluded
SELECT 
	s.store_id, 
    a.address || ' ' || COALESCE(a.address2, '') AS store_address,
    SUM(p.amount) AS revenue
FROM public.store s
INNER JOIN public.address a
    ON s.address_id = a.address_id
INNER JOIN public.inventory i
	ON s.store_id = i.store_id
INNER JOIN public.rental r
	ON i.inventory_id = r.inventory_id 
INNER JOIN public.payment p 
     ON r.rental_id = p.rental_id 
WHERE p.payment_date >= '2017-04-01'
GROUP BY s.store_id, 
a.address || ' ' || COALESCE(a.address2, '');

-- b) SUBQUERY Solution
SELECT 
	s.store_id, 
    a.address || ' ' || COALESCE(a.address2, '') AS store_address,
    store_revenue_sq.revenue 
FROM (
	SELECT 
		s.store_id,
		SUM(p.amount) AS revenue
	FROM public.store s
	INNER JOIN public.inventory i
		ON s.store_id = i.store_id
	INNER JOIN public.rental r
		ON i.inventory_id = r.inventory_id 
	INNER JOIN public.payment p 
     	ON r.rental_id = p.rental_id 
	WHERE p.payment_date >= '2017-04-01'
	GROUP BY s.store_id ) store_revenue_sq
INNER JOIN public.store s
	ON store_revenue_sq.store_id = s.store_id 
INNER JOIN public.address a
    ON s.address_id = a.address_id;

-- c) CTE Solution
WITH store_revenue_cte AS (
	SELECT 
		s.store_id,
		SUM(p.amount) AS revenue
	FROM public.store s
	INNER JOIN public.inventory i
		ON s.store_id = i.store_id
	INNER JOIN public.rental r
		ON i.inventory_id = r.inventory_id 
	INNER JOIN public.payment p 
     	ON r.rental_id = p.rental_id 
	WHERE p.payment_date >= '2017-04-01'
	GROUP BY s.store_id 
)
SELECT 
	s.store_id, 
    a.address || ' ' || COALESCE(a.address2, '') AS store_address,
    store_revenue.revenue 
FROM store_revenue_cte store_revenue
INNER JOIN public.store s
	ON store_revenue.store_id = s.store_id 
INNER JOIN public.address a
    ON s.address_id = a.address_id;


--P1. Task 3:

--The marketing department in our stores aims to identify the most successful actors since 2015 to boost customer interest in their films. 
--Show top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)

-- Assumptions:
-- "released after 2015" is interpreted as release_year >= 2015
-- two actors can have two name - for that reason, actor_id was added in group by even if it was not required 
-- schema: public

-- Advantages, disadvantages and production choice:
-- a) JOIN Solution - *Production Choice*
-- simplest and most direct — everything in one query
-- easy to read — filters and joins all in one place
-- GROUP BY on first_name and last_name could cause issues if two actors share the same name (it was safer to include actor_id in GROUP BY even if not asked in requirements)

-- b) SUBQUERY Solution
-- cleanly separates "which films qualify" from "count per actor"
-- slight over-engineering for a straightforward count like this

-- c) CTE Solution
-- same separation of concerns as subquery but more readable
-- most readable for complex queries, easy to debug
-- reusable — can be referenced multiple times in the same query
-- slight over-engineering 

-- a) JOIN Solution
-- INNER JOIN ensures only actors who have at least one qualifying film (released since 2015) are included in the result.
-- Actors with no films or no films after 2015 are excluded.
SELECT
	a.actor_id, 
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa 
    ON a.actor_id = fa.actor_id 
INNER JOIN public.film f 
    ON fa.film_id = f.film_id
WHERE f.release_year >= 2015
GROUP by
	a.actor_id, 
    a.first_name, 
    a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

-- b) SUBQUERY Solution
SELECT
	a.actor_id, 
    a.first_name,
    a.last_name,
    COUNT(movie_number_sq.film_id) AS number_of_movies
FROM (
	SELECT 
		fa.actor_id,
		fa.film_id 
	FROM public.film_actor fa 
	INNER JOIN public.film f 
    	ON fa.film_id = f.film_id
	WHERE f.release_year >= 2015) movie_number_sq
	INNER JOIN public.actor a 
		ON movie_number_sq.actor_id = a.actor_id	
GROUP by
	a.actor_id, 
    a.first_name, 
    a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

-- c) CTE Solution
WITH movie_number_cte AS(
	SELECT 
		fa.actor_id,
		fa.film_id 
	FROM public.film_actor fa 
	INNER JOIN public.film f 
    	ON fa.film_id = f.film_id
	WHERE f.release_year >= 2015
)
SELECT
	a.actor_id, 
    a.first_name,
    a.last_name,
    COUNT(movie_number.film_id) AS number_of_movies
FROM movie_number_cte movie_number
	INNER JOIN public.actor a 
		ON movie_number.actor_id = a.actor_id	
GROUP by
	a.actor_id, 
    a.first_name, 
    a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

--P1. Task 4
--The marketing team needs to track the production trends of Drama, Travel, and Documentary films to inform genre-specific marketing strategies. 
--Show number of Drama, Travel, Documentary per year (include columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)

-- Assumptions:
-- each film is counted once per category it belongs to
-- all release years are included, even if a year has no Drama, Travel or Documentary films
-- in that case the year still appears in the result with 0 for all three columns
-- NULL handling: category filter is moved into the CASE expression: CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END
-- 				  this way all years are preserved in GROUP BY, and non-matching categories simply contribute 0
-- 				  ELSE 0 inside CASE also prevents SUM from returning NULL for years where none of the three categories appear
-- schema: public

-- Advantages, disadvantages and production choice:
-- a) JOIN Solution *Production Choice*
-- simplest and most direct — everything in one query
-- easy to read — filters and aggregation all in one place
-- harder to reuse category logic elsewhere in the same query

-- b) SUBQUERY Solution - *Production Choice*
-- the subquery cleanly separates the join logic (release_year + category_name)
-- from the aggregation (SUM + CASE)
-- easier to maintain — if join logic changes, only the subquery is updated
-- outer query is clean — just aggregating pre-joined data

-- c) CTE Solution
-- same separation of concerns as subquery but more readable
-- most readable for complex queries, easy to debug
-- reusable — can be referenced multiple times in the same query
-- slight over-engineering for a query of this complexity

-- a) JOIN Solution
-- INNER JOIN ensures only films that have a category assigned are included
SELECT 
    f.release_year,
    SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
    SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category fc 
    ON f.film_id = fc.film_id
INNER JOIN public.category c 
    ON fc.category_id = c.category_id
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- b) SUBQUERY Solution
SELECT 
   	categories_sq.release_year,
    SUM(CASE WHEN categories_sq.category_name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
    SUM(CASE WHEN categories_sq.category_name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN categories_sq.category_name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM (
    SELECT 
        f.release_year,
        c.name AS category_name
    FROM public.film f
    INNER JOIN public.film_category fc 
        ON f.film_id = fc.film_id
    INNER JOIN public.category c 
        ON fc.category_id = c.category_id
) categories_sq
GROUP BY categories_sq.release_year
ORDER BY categories_sq.release_year DESC;

-- c) CTE Solution
WITH categories_cte AS (
	SELECT 
        f.release_year,
        c.name AS category_name
    FROM public.film f
    INNER JOIN public.film_category fc 
        ON f.film_id = fc.film_id
    INNER JOIN public.category c 
        ON fc.category_id = c.category_id
)
SELECT 
   	categories_cte.release_year,
    SUM(CASE WHEN categories_cte.category_name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
    SUM(CASE WHEN categories_cte.category_name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN categories_cte.category_name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM categories_cte
GROUP BY categories_cte.release_year
ORDER BY categories_cte.release_year DESC;

--P2. Task 1:
--The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores revenue. 
--Show which three employees generated the most revenue in 2017 
--
--Assumptions: 
--staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store; 
--take into account only payment_date

-- Assumptions (based on :
-- revenue is calculated as SUM(payment.amount) per staff member
-- only payments from 2017 are considered, filtered by payment_date
-- last store is derived from the most recent payment in 2017: payment - rental - inventory (inventory holds store_id)
-- this follows the assumption that if staff processed a payment, they work in the same store as that payment's rental inventory
-- in case of equal payment_date (this issue exists within the dataset), payment_id is used as tiebreaker
-- schema: public

-- a) JOIN Solution
-- a plain JOIN between payment, rental and inventory would return one row per payment, 
-- meaning each staff member appears multiple times — once for every payment they processed.
-- to pick only the last store we need to select exactly one row per staff member based on the most recent payment_date, 
-- which requires LIMIT 1 (subquery) or a window function

-- b) SUBQUERY Solution - *Production Choice*
-- cleanly separates the "latest store" logic from the revenue aggregation
-- outer query remains simple: one GROUP BY for revenue, one subquery for store

-- b) SUBQUERY Solution
SELECT
    p.staff_id,
    s.first_name,
    s.last_name,
    (
        SELECT i.store_id
        FROM public.payment p2
        JOIN public.rental r ON r.rental_id    = p2.rental_id
        JOIN public.inventory i ON i.inventory_id = r.inventory_id
        WHERE p2.staff_id = p.staff_id
          AND DATE_PART('year', p2.payment_date) = 2017
        ORDER BY p2.payment_date DESC, p2.payment_id DESC
        LIMIT 1
    ) AS last_store_id,
    SUM(p.amount) AS total_revenue_2017
FROM public.payment p
JOIN public.staff   s ON s.staff_id = p.staff_id
WHERE  DATE_PART('year', p.payment_date) = 2017
GROUP BY
    p.staff_id,
    s.first_name,
    s.last_name
ORDER BY total_revenue_2017 desc
LIMIT 3;

-- c) CTE Solution
WITH revenue_2017_cte AS (
    SELECT
        p.staff_id,
        s.first_name,
        s.last_name,
        SUM(p.amount) AS total_revenue_2017
    FROM public.payment p
    JOIN public.staff s
      ON s.staff_id = p.staff_id
    WHERE DATE_PART('year', p.payment_date) = 2017
    GROUP BY
        p.staff_id,
        s.first_name,
        s.last_name
),
last_payment_date_cte AS (
    SELECT
        p.staff_id,
        MAX(p.payment_date) AS last_payment_date
    FROM public.payment p
    WHERE DATE_PART('year', p.payment_date) = 2017
    GROUP BY p.staff_id
),
last_store_cte AS (
    SELECT
        p.staff_id,
        i.store_id,
        p.payment_date,
        p.payment_id
    FROM public.payment p
    JOIN last_payment_date_cte lpd
		ON lpd.staff_id = p.staff_id AND lpd.last_payment_date = p.payment_date
    JOIN public.rental r
      	ON r.rental_id = p.rental_id
    JOIN public.inventory i
      	ON i.inventory_id = r.inventory_id
    WHERE DATE_PART('year', p.payment_date) = 2017
)
SELECT
    r.staff_id,
    r.first_name,
    r.last_name,
    (
        SELECT ls.store_id
        FROM last_store_cte ls
        WHERE ls.staff_id = r.staff_id
        ORDER BY ls.payment_id DESC
        LIMIT 1
    ) AS last_store_id,
    r.total_revenue_2017
FROM revenue_2017_cte r
ORDER BY r.total_revenue_2017 DESC
LIMIT 3;


--P2. Task 2:
--2. The management team wants to identify the most popular movies and their target audience age groups to optimize marketing efforts. 
--Show which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? 
--To determine expected age please use 'Motion Picture Association film rating system'

-- Assumptions:
-- number of rentals is counted using film - inventory - rental join (a film can have multiple inventory copies)
-- MPA rating descriptions are taken from the official Motion Picture Association rating system
-- in case of equal rental count, films are sorted alphabetically by title as tiebreaker
-- schema: public

-- Advantages, disadvantages and production choice:
-- a) JOIN Solution
-- simplest and most direct — everything in one query
-- easy to read — filters, joins and aggregation all in one place
-- harder to reuse the rental count elsewhere in the same query

-- b) SUBQUERY Solution - *Production Choice*
-- The subquery cleanly separates aggregation (rental count) from presentation (film title, rating, MPA description). 
-- This makes the query easier to maintain if the rental count logic changes, you only update the subquery.
-- outer query is clean — just joining pre-calculated rental counts with film data

-- c) CTE Solution
-- same separation of concerns as subquery but more readable
-- most readable for complex queries, easy to debug
-- reusable — can be referenced multiple times in the same query
-- slight over-engineering 

-- a) JOIN Solution
-- INNER JOIN ensures only films with at least one rental are included
-- films never rented will be excluded from results
SELECT 
    f.title AS film_title, 
    COUNT(r.rental_id) AS number_of_rentals,
    f.rating,
    CASE
        WHEN f.rating = 'G' THEN 'All ages admitted.'
        WHEN f.rating = 'PG' THEN 'Some material may not be suitable for children.'
        WHEN f.rating = 'PG-13' THEN 'Some material may be inappropriate for children under 13.'
        WHEN f.rating = 'R' THEN 'Under 17 requires accompanying parent or adult guardian.'
        WHEN f.rating = 'NC-17' THEN 'No one 17 and under admitted.'
        ELSE 'Unknown Rating'
    END AS expected_age
FROM public.film f
INNER JOIN  public.inventory i 
    ON f.film_id = i.film_id
INNER JOIN  public.rental r
    ON i.inventory_id = r.inventory_id
GROUP BY 
    f.film_id,
    f.title,
    f.rating
ORDER BY 
	number_of_rentals DESC, 
	f.title
LIMIT 5; 

-- b) SUBQUERY Solution
SELECT 
    f.title AS film_title, 
    rentals_sq.number_of_rentals AS number_of_rentals,
    f.rating,
    CASE
        WHEN f.rating = 'G' THEN 'All ages admitted.'
        WHEN f.rating = 'PG' THEN 'Some material may not be suitable for children.'
        WHEN f.rating = 'PG-13' THEN 'Some material may be inappropriate for children under 13.'
        WHEN f.rating = 'R' THEN 'Under 17 requires accompanying parent or adult guardian.'
        WHEN f.rating = 'NC-17' THEN 'No one 17 and under admitted.'
        ELSE 'Unknown Rating'
    END AS expected_age
FROM (
	SELECT
		i.film_id,
		COUNT(r.rental_id) AS number_of_rentals
	FROM  public.inventory i 
	INNER JOIN  public.rental r
    ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
) rentals_sq 
INNER JOIN  public.film f
    ON rentals_sq.film_id = f.film_id
ORDER BY 
	number_of_rentals desc, 
	f.title
LIMIT 5;

-- c) CTE Solution
WITH rentals_cte AS (
	SELECT
		i.film_id,
		COUNT(r.rental_id) AS number_of_rentals
	FROM  public.inventory i 
	INNER JOIN  public.rental r
    ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
)
SELECT 
    f.title AS film_title, 
    rentals_cte.number_of_rentals AS number_of_rentals,
    f.rating,
    CASE
        WHEN f.rating = 'G' THEN 'All ages admitted.'
        WHEN f.rating = 'PG' THEN 'Some material may not be suitable for children.'
        WHEN f.rating = 'PG-13' THEN 'Some material may be inappropriate for children under 13.'
        WHEN f.rating = 'R' THEN 'Under 17 requires accompanying parent or adult guardian.'
        WHEN f.rating = 'NC-17' THEN 'No one 17 and under admitted.'
        ELSE 'Unknown Rating'
    END AS expected_age
FROM rentals_cte 
INNER JOIN  public.film f
    ON rentals_cte.film_id = f.film_id
ORDER BY 
	number_of_rentals desc,
	f.title
LIMIT 5;

-- P3. Task 1
--The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks 
--for targeted promotional campaigns, highlighting their comebacks or consistent appearances to engage customers with nostalgic or reliable film stars
--The task can be interpreted in various ways, and here are a few options (provide solutions for each one):
--V1: gap between the latest release_year and current year per each actor;
--V2: gaps between sequential films per each actor;

-- Assumptions:
-- V1: gap is calculated as current year minus the actor's last release year
-- V1: actors with no films are excluded (INNER JOIN on film_actor and film)
-- V2: gap is calculated between consecutive release years per actor using a self join on film_actor and film
-- V2: only the immediately next release year is considered (MIN of future years)
-- V2: actors with only one film have no sequential gap and are excluded (HAVING)
-- V2: if an actor has multiple films in the same year, gap between that year and the next year is still calculated correctly via MIN
-- V2: for V2 two solutions we're prepared
-- schema: public

-- V1: gap between latest release_year and current year per actor

---- Advantages, disadvantages and production choice:
-- a) JOIN Solution
-- simplest and most direct — aggregation and presentation in one query
-- easy to read — MAX and gap calculation visible immediately
-- harder to reuse the gap calculation elsewhere in the same query
--
-- b) SUBQUERY Solution - *Production Choice for V1*
-- cleanly separates gap calculation from actor name presentation
-- outer query is clean — just joining pre-calculated results with actor details
-- this will be the production choice because of the separation between calculation and presentation

-- c) CTE Solution
-- same separation of concerns as subquery but more readable
-- easiest to debug — run the CTE alone to verify gap calculations
-- reusable — if gap data needed to be used elsewhere in the same query

-- V1 - a) JOIN Solution
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS last_release_year,
    CAST(DATE_PART('year', current_date) AS int) - MAX(f.release_year) AS gap_between_last_release_and_current_year
FROM actor a
INNER JOIN film_actor fa
    ON a.actor_id = fa.actor_id
INNER JOIN film f
    ON fa.film_id = f.film_id
GROUP BY
    a.actor_id,
    a.first_name,
    a.last_name
ORDER BY DATE_PART('year', current_date) - MAX(f.release_year) DESC;

-- V1 - b) Subquery Solution
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    last_release_sq.last_release_year,
    last_release_sq.gap_between_last_release_and_current_year
FROM (
    SELECT 
        fa.actor_id,
        MAX(f.release_year) AS last_release_year,
        CAST(DATE_PART('year', current_date) AS int) - MAX(f.release_year) AS gap_between_last_release_and_current_year
    FROM film_actor fa
    INNER JOIN film f
        ON fa.film_id = f.film_id 
    GROUP BY fa.actor_id
) last_release_sq
INNER JOIN actor a 
    ON last_release_sq.actor_id = a.actor_id 
ORDER BY last_release_sq.gap_between_last_release_and_current_year DESC;

--V1 c) CTE Solution
WITH last_release_cte AS (
	SELECT 
	        fa.actor_id,
	        MAX(f.release_year) AS last_release_year,
	        CAST(DATE_PART('year', current_date) AS int) - MAX(f.release_year) AS gap_between_last_release_and_current_year
	    FROM film_actor fa
	    INNER JOIN film f
	        ON fa.film_id = f.film_id 
	    GROUP BY fa.actor_id
)
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    last_release_cte.last_release_year,
    last_release_cte.gap_between_last_release_and_current_year
FROM last_release_cte 
INNER JOIN actor a 
    ON last_release_cte.actor_id = a.actor_id 
ORDER BY last_release_cte.gap_between_last_release_and_current_year DESC;

-- V2: gaps between sequential films per actor (self join approach)

-- For this exercise I've provided two solutions depending on what the expected outcome is.
-- V2.1 -- Expected outcome: for each actor we want to be able to see all the gaps in his/hers carrer and then sort them descending

---- Advantages, disadvantages and production choice:
-- a) JOIN
-- everything in one query — no subquery or CTE
-- self join logic is visible immediately
-- most complex to read — two self joins on film_actor and film in one query
-- harder to reuse the sequential gap logic elsewhere

-- b) SUBQUERY
-- cleanly separates sequential gap calculation from actor name presentation
-- outer query is clean — just joining pre-calculated gaps with actor details
-- easier to maintain — if gap logic changes, only the subquery needs updating
-- self join logic inside subquery is still complex but isolated

-- c) CTE - *Production Choice for V2.1*
-- same separation of concerns as subquery but more readable 
-- V2 logic is complex enough that CTE adds real value over subquery - production choice
-- easiest to debug 
-- reusable — CTE can be referenced multiple times (e.g. for longest gap variant)

-- V2.1 - a) JOIN Solution
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    f.release_year AS current_release_year,
    MIN(f2.release_year) AS next_release_year,
    MIN(f2.release_year) - f.release_year AS gap_between_sequential_films
FROM public.actor a 
INNER JOIN public.film_actor fa 
    ON a.actor_id = fa.actor_id 
INNER JOIN public.film f
    ON fa.film_id = f.film_id
LEFT JOIN public.film_actor fa2 
    ON a.actor_id = fa2.actor_id 
LEFT JOIN public.film f2 
    ON fa2.film_id = f2.film_id
   AND f2.release_year > f.release_year
GROUP BY
    a.actor_id,
    a.first_name,
    a.last_name,
    f.release_year
HAVING MIN(f2.release_year) IS NOT NULL
ORDER BY
    a.actor_id ASC,
    MIN(f2.release_year) - f.release_year DESC;

-- V2.1 - b) Subquery Solution
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    seq_film_sq.release_year AS current_release_year, 
    seq_film_sq.next_release_year,
    seq_film_sq.gap_between_sequential_films
FROM (
    SELECT
        fa.actor_id,
        f.release_year, 
        MIN(f2.release_year) AS next_release_year,
        MIN(f2.release_year) - f.release_year AS gap_between_sequential_films
    FROM public.film_actor fa 
    INNER JOIN public.film f
        ON fa.film_id = f.film_id
    LEFT JOIN public.film_actor fa2 
        ON fa.actor_id = fa2.actor_id 
    LEFT JOIN public.film f2 
        ON fa2.film_id = f2.film_id 
       AND f2.release_year > f.release_year
    GROUP BY
        fa.actor_id,
        f.release_year
    HAVING MIN(f2.release_year) IS NOT NULL
) seq_film_sq
INNER JOIN actor a 
    ON a.actor_id = seq_film_sq.actor_id 
ORDER BY
    a.actor_id ASC,
    seq_film_sq.gap_between_sequential_films DESC;

-- V2.1 c) CTE Solution
WITH seq_film_cte AS(
	SELECT
        fa.actor_id,
        f.release_year, 
        MIN(f2.release_year) AS next_release_year,
        MIN(f2.release_year) - f.release_year AS gap_between_sequential_films
    FROM public.film_actor fa 
    INNER JOIN public.film f
        ON fa.film_id = f.film_id
    LEFT JOIN public.film_actor fa2 
        ON fa.actor_id = fa2.actor_id 
    LEFT JOIN public.film f2 
        ON fa2.film_id = f2.film_id 
       AND f2.release_year > f.release_year
    GROUP BY
        fa.actor_id,
        f.release_year
    HAVING MIN(f2.release_year) IS NOT NULL
)
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    seq_film_cte.release_year AS current_release_year, 
    seq_film_cte.next_release_year,
    seq_film_cte.gap_between_sequential_films
FROM seq_film_cte
INNER JOIN actor a 
    ON a.actor_id = seq_film_cte.actor_id 
ORDER BY
    seq_film_cte.gap_between_sequential_films DESC;

-- V2.2 -- Expected outcome: for each actor we want to be able to see aonly the biggest gap in his/hers carrer and then sort them descending

---- Advantages, disadvantages and production choice:
-- a) JOIN Solution
-- To find the biggest gap per actor we need two levels of aggregation:
--   1. first GROUP BY (actor, release_year) + MIN to find the next film and calculate the gap
--   2. then GROUP BY actor + MAX to find the biggest gap among all calculated gaps
-- SQL does not allow nesting aggregate functions directly — MAX(MIN(...)) is invalid syntax.
-- A subquery or CTE is mandatory to separate the two aggregation levels.

-- b) SUBQUERY Solution
-- separates gap calculation from MAX aggregation per actor


-- c) CTE Solution - *Production Choice*
-- clearly separates gap calculation logic into a named block
-- final SELECT is clean — just MAX and GROUP BY per actor
-- easiest to debug and reusable
-- V2.2 requires two levels of aggregation which makes a subquery or CTE mandatory. 
-- CTE wins here because the same gap logic can be reused. 
-- Also, because the logic it's more complex having a CTE will increase the code readibility and maintainbility.


-- V2.2 - b) Subquery Solution
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    MAX(seq_film_sq.gap_between_sequential_films) AS max_gap
FROM (
    SELECT
        fa.actor_id,
        f.release_year, 
        MIN(f2.release_year) AS next_release_year,
        MIN(f2.release_year) - f.release_year AS gap_between_sequential_films
    FROM public.film_actor fa 
    INNER JOIN public.film f
        ON fa.film_id = f.film_id
    LEFT JOIN public.film_actor fa2 
        ON fa.actor_id = fa2.actor_id 
    LEFT JOIN public.film f2 
        ON fa2.film_id = f2.film_id 
       AND f2.release_year > f.release_year
    GROUP BY
        fa.actor_id,
        f.release_year
    HAVING MIN(f2.release_year) IS NOT NULL
) seq_film_sq
INNER JOIN actor a 
    ON a.actor_id = seq_film_sq.actor_id
group by
	a.actor_id,
    a.first_name,
    a.last_name
ORDER by MAX(seq_film_sq.gap_between_sequential_films) DESC;

-- V2.2 c) CTE Solution
WITH seq_film_cte2 AS(
	SELECT
        fa.actor_id,
        f.release_year, 
        MIN(f2.release_year) AS next_release_year,
        MIN(f2.release_year) - f.release_year AS gap_between_sequential_films
    FROM public.film_actor fa 
    INNER JOIN public.film f
        ON fa.film_id = f.film_id
    LEFT JOIN public.film_actor fa2 
        ON fa.actor_id = fa2.actor_id 
    LEFT JOIN public.film f2 
        ON fa2.film_id = f2.film_id 
       AND f2.release_year > f.release_year
    GROUP BY
        fa.actor_id,
        f.release_year
    HAVING MIN(f2.release_year) IS NOT NULL
)
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    MAX(seq_film_cte2.gap_between_sequential_films) AS max_gap
FROM seq_film_cte2
INNER JOIN public.actor a 
    ON a.actor_id = seq_film_cte2.actor_id 
group by
	a.actor_id,
    a.first_name,
    a.last_name
ORDER BY
    MAX(seq_film_cte2.gap_between_sequential_films) DESC;