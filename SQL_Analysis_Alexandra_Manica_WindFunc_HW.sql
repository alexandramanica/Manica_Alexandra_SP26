
-- Task 1
-- Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels. 
-- This report should list the top 5 customers for each channel. 
-- Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' 
-- which represents the percentage of a customer's sales relative to the total sales within their respective channel.
-- Please format the columns as follows:
-- Display the total sales amount with two decimal places
-- Display the sales percentage with four decimal places and include the percent sign (%) at the end
-- Display the result for each channel in descending order of sales

-- Notes:
-- TO_CHAR was used instead of ROUND to keep the exact report format, since ROUND doesn’t guarantee ending zeros (ex. 10.5 vs 10.50)
-- The window functions we're used to calculate each customer's sales percentage within their channel
-- and ROW_NUMBER to keep only the Top 5 customers per channel.

WITH cte_total_amount_sold AS (
    SELECT
        ch.channel_desc,
        c.cust_id,
        c.cust_last_name, 
        c.cust_first_name,
        SUM(s.amount_sold) AS total_amount_sold
    FROM sh.customers c
    JOIN sh.sales s 
        ON s.cust_id = c.cust_id 
    JOIN sh.channels ch
        ON s.channel_id = ch.channel_id
    GROUP BY
        ch.channel_desc,
        c.cust_id,
        c.cust_last_name, 
        c.cust_first_name
),
cte_ranking_sales AS (
    SELECT 
        cte.channel_desc,
        cte.cust_id,
        cte.cust_last_name, 
        cte.cust_first_name,
        cte.total_amount_sold,
        (cte.total_amount_sold * 100) / SUM(cte.total_amount_sold) OVER (
            PARTITION BY cte.channel_desc
        ) AS sales_percentage,
        ROW_NUMBER() OVER (
            PARTITION BY cte.channel_desc
            ORDER BY cte.total_amount_sold DESC
        ) AS numbered_row
    FROM cte_total_amount_sold cte
)
SELECT
    cte.channel_desc,
    cte.cust_last_name, 
    cte.cust_first_name,
    TO_CHAR(cte.total_amount_sold, 'FM999999999.00') AS amount_sold,
    CONCAT(TO_CHAR(cte.sales_percentage, 'FM999.0000'), ' %') AS sales_percentage
FROM cte_ranking_sales cte
WHERE cte.numbered_row <= 5
ORDER BY
    cte.channel_desc,
    cte.total_amount_sold DESC;


-- Task 2
-- Create a query to retrieve data for a report that displays the total sales for all products in the Photo category in the Asian region for the year 2000. 
-- Calculate the overall report total and name it 'YEAR_SUM'
-- Display the sales amount with two decimal places
-- Display the result in descending order of 'YEAR_SUM'
-- For this report, consider exploring the use of the crosstab function.

-- Notes:
-- TO_CHAR was used instead of ROUND to keep the exact report format, since ROUND doesn’t guarantee ending zeros (ex. 10.5 vs 10.50)
-- The result was sorted by year_sum as a numeric value, since text formatting caused a different order than the original report.
-- The crosstab function was used to pivot quarterly sales into separate q1-q4 columns, 
-- then formatted the final numeric values with TO_CHAR to match the report format.

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
    prod_name,
    TO_CHAR(q1, 'FM999999999.00') AS q1,
    TO_CHAR(q2, 'FM999999999.00') AS q2,
    TO_CHAR(q3, 'FM999999999.00') AS q3,
    TO_CHAR(q4, 'FM999999999.00') AS q4,
    TO_CHAR(year_sum, 'FM999999999.00') AS year_sum
FROM (
    SELECT *
    FROM crosstab(
        $$
        WITH cte_quarter_amount_sold AS (
            SELECT
                p.prod_id,
                p.prod_name,
                CONCAT('q', t.calendar_quarter_number) AS quarter,
                SUM(s.amount_sold) AS total_amount_sold
            FROM sh.products p
            JOIN sh.sales s ON p.prod_id = s.prod_id
            JOIN sh.times t ON s.time_id = t.time_id
            JOIN sh.customers c ON c.cust_id = s.cust_id
            JOIN sh.countries countr ON c.country_id = countr.country_id
            WHERE UPPER(countr.country_region) = 'ASIA'
              AND t.calendar_year = 2000
              AND UPPER(p.prod_category) = 'PHOTO'
            GROUP BY
                p.prod_id,
                p.prod_name,
                t.calendar_quarter_number
        ),
        cte_total_amount_sold AS (
            SELECT
                prod_id,
                prod_name,
                quarter,
                total_amount_sold,
                SUM(total_amount_sold) OVER (
                    PARTITION BY prod_id
                ) AS year_sum
            FROM cte_quarter_amount_sold
        )
        SELECT
            prod_name,
            year_sum,
            quarter,
            total_amount_sold
        FROM cte_total_amount_sold
        ORDER BY prod_name, quarter
        $$,
        $$
        SELECT unnest(ARRAY['q1', 'q2', 'q3', 'q4'])
        $$
    ) AS ct (
        prod_name TEXT,
        year_sum NUMERIC,
        q1 NUMERIC,
        q2 NUMERIC,
        q3 NUMERIC,
        q4 NUMERIC
    )
) sq
ORDER BY sq.year_sum DESC;

-- Task 3

-- Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 1998, 1999, and 2001. The report should be categorized based on sales channels, and separate calculations should be performed for each channel.
-- Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
-- Categorize the customers based on their sales channels
-- Perform separate calculations for each sales channel
-- Include in the report only purchases made on the channel specified
-- Format the column so that total sales are displayed with two decimal places

-- Notes:
-- TO_CHAR was used instead of ROUND to keep the exact report format, since ROUND doesn’t guarantee ending zeros (ex. 10.5 vs 10.50)
-- Based on the teams chat: The query ranks customers per channel and per year to get the Top 300,
-- then keeps only those who appear in the Top 300 for all three years within the same channel.

WITH cte_channel_total_amount AS (
    SELECT
        ch.channel_desc,
        t.calendar_year,
        c.cust_id,
        c.cust_first_name,
        c.cust_last_name,
        SUM(s.amount_sold) AS total_amount_sold,
        ROW_NUMBER() OVER (
            PARTITION BY t.calendar_year, ch.channel_desc
            ORDER BY SUM(s.amount_sold) DESC
        ) AS numbered_row
    FROM sh.customers c 
    JOIN sh.sales s 
        ON c.cust_id = s.cust_id
    JOIN sh.channels ch
        ON s.channel_id = ch.channel_id
    JOIN sh.times t 
        ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY
        ch.channel_desc,
        t.calendar_year,
        c.cust_id,
        c.cust_first_name,
        c.cust_last_name
),
cte_top_300_per_year AS (
    SELECT *
    FROM cte_channel_total_amount
    WHERE numbered_row <= 300
),
cte_customers_all_3_years AS (
    SELECT
        cte.channel_desc,
        cte.cust_id
    FROM cte_top_300_per_year cte
    GROUP BY
        cte.channel_desc,
        cte.cust_id
    HAVING COUNT(DISTINCT calendar_year) = 3
)
SELECT
    cte.channel_desc,
    cte.cust_id,
    cte.cust_last_name,
    cte.cust_first_name,
    TO_CHAR(SUM(cte.total_amount_sold), 'FM999999999.00') AS amount_sold
FROM cte_top_300_per_year cte
JOIN cte_customers_all_3_years cte2
    ON cte.channel_desc = cte2.channel_desc
   AND cte.cust_id = cte2.cust_id
group by
	cte.channel_desc,
    cte.cust_id,
    cte.cust_first_name,
    cte.cust_last_name
ORDER BY
   	amount_sold DESC;

-- Task 4
-- Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
-- Display the result by months and by product category in alphabetical order.

-- Notes:
-- ROUND(, 0) was used to keep the exact report format (no decimals)
-- WHERE reduces the dataset to the required months and regions,
-- while FILTER splits the sales totals into separate Americas and Europe columns.

WITH cte_region_amount_sold AS (
    SELECT
        t.calendar_month_desc, 
        p.prod_category,
        SUM(s.amount_sold) FILTER (
            WHERE UPPER(countr.country_region) LIKE UPPER('%America%')
        ) AS america_sales,
        SUM(s.amount_sold) FILTER (
            WHERE UPPER(countr.country_region) = UPPER('Europe')
        ) AS europe_sales
    FROM sh.products p 
    JOIN sh.sales s 
        ON p.prod_id = s.prod_id
    JOIN sh.times t 
        ON s.time_id = t.time_id 
    JOIN sh.customers c 
        ON c.cust_id = s.cust_id 
    JOIN sh.countries countr 
        ON c.country_id = countr.country_id
    WHERE t.calendar_year = 2000
      AND t.calendar_month_number IN (1, 2, 3)
      AND (
          UPPER(countr.country_region) LIKE UPPER('%America%')
          OR UPPER(countr.country_region) = UPPER('Europe')
      )
    GROUP BY
        t.calendar_month_desc, 
        p.prod_category
)
SELECT 
    cte.calendar_month_desc,
    cte.prod_category,
    ROUND(cte.america_sales, 0) AS "Americas SALES",
    ROUND(cte.europe_sales, 0) AS "Europe SALES"
FROM cte_region_amount_sold cte
ORDER BY 
    cte.calendar_month_desc,
    cte.prod_category;

    
 




