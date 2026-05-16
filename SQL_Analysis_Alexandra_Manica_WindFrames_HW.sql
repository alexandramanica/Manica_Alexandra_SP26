
-- Task 1

-- Create a query for analyzing the annual sales data for the years 1999 to 2001, 
-- focusing on different sales channels and regions: 'Americas,' 'Asia,' and 'Europe.' 
-- The resulting report should contain the following columns:
-- AMOUNT_SOLD: This column should show the total sales amount for each sales channel
-- % BY CHANNELS: In this column, we should display the percentage of total sales for each channel (e.g. 100% - total sales for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
-- % PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column but for the previous year
-- % DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating the change in sales percentage from the previous year.
-- The final result should be sorted in ascending order based on three criteria: first by 'country_region,' then by 'calendar_year,' and finally by 'channel_desc'

WITH cte_base AS (
    SELECT
        countr.country_region,
        t.calendar_year,
        c.channel_desc,
        SUM(s.amount_sold) AS total_amount_sold
    FROM sh.sales s 
    INNER JOIN sh.times t 
        ON t.time_id = s.time_id 
    INNER JOIN sh.channels c 
        ON s.channel_id = c.channel_id 
    INNER JOIN sh.customers cust
        ON s.cust_id = cust.cust_id 
    INNER JOIN sh.countries countr
        ON cust.country_id = countr.country_id
    WHERE UPPER(countr.country_region) IN ('AMERICAS', 'ASIA', 'EUROPE')
    GROUP BY
        countr.country_region,
        t.calendar_year,
        c.channel_desc
),
cte_base_channels AS (  
    SELECT
        cte.country_region,
        cte.calendar_year,
        cte.channel_desc,
        cte.total_amount_sold,
        cte.total_amount_sold * 100.0
            / SUM(cte.total_amount_sold) OVER (
                PARTITION BY cte.calendar_year, cte.country_region
            ) AS percentage_by_channels
    FROM cte_base cte
),
cte_prev_year AS (
    SELECT
        cte.country_region,
        cte.calendar_year,
        cte.channel_desc,
        cte.total_amount_sold,
        cte.percentage_by_channels,
        MIN(cte.percentage_by_channels) OVER (
            PARTITION BY cte.country_region, cte.channel_desc
            ORDER BY cte.calendar_year
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING
        ) AS prev_year
    FROM cte_base_channels cte
)
SELECT 
	cte.country_region,
    cte.calendar_year,
    cte.channel_desc,
    ROUND(cte.total_amount_sold, 2) AS amount_sold,
    ROUND(cte.percentage_by_channels, 2) AS "% BY CHANNELS",
    ROUND(cte.prev_year, 2) AS "% PREVIOUS_PERIOD",
    ROUND(cte.percentage_by_channels - cte.prev_year, 2) AS "% DIFF"
FROM cte_prev_year cte
WHERE cte.calendar_year IN (1999, 2000, 2001)
ORDER BY
    cte.country_region,
    cte.calendar_year,
    cte.channel_desc;

-- Task 2 

-- Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
-- Include a column named CUM_SUM to display the amounts accumulated during each week.
-- Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days using a centered moving average.
-- For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
-- For Friday, calculate the average sales on Thursday, Friday, and the weekend.

WITH cte_base AS (
    SELECT
        t.calendar_week_number,
        t.time_id,
        t.day_name,
        SUM(s.amount_sold) AS sales
    FROM sh.sales s 
    JOIN sh.times t 
        ON s.time_id = t.time_id
    WHERE t.calendar_year = 1999
    GROUP BY 
        t.calendar_week_number,
        t.time_id,
        t.day_name
),
cte_cum_sum AS (
	SELECT
	    cte.calendar_week_number,
	    cte.time_id,
	    cte.day_name,
	    cte.sales,
	    SUM(cte.sales) OVER (
	        PARTITION BY cte.calendar_week_number 
	        ORDER BY cte.time_id
	        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	    ) AS cum_sum
	FROM cte_base cte
),
cte_avg AS (
	SELECT
	    cte.calendar_week_number,
	    cte.time_id,
	    cte.day_name,
	    cte.sales,
	    cte.cum_sum,
	    CASE
	    	WHEN UPPER(cte.day_name) = 'MONDAY' THEN
	            AVG(cte.sales) OVER (
	                ORDER BY cte.time_id
	                ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
	            )
	        WHEN UPPER(cte.day_name) = 'FRIDAY' THEN
	            AVG(cte.sales) OVER (
	                ORDER BY cte.time_id
	                ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
	            )
	        ELSE
	            AVG(cte.sales) OVER (
	                ORDER BY cte.time_id
	                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
	            )
	    END AS centered_3_day_avg
	FROM cte_cum_sum cte
)
SELECT
	    cte.calendar_week_number,
	    cte.time_id,
	    cte.day_name,
	    ROUND(cte.sales, 2) as sales,
	    ROUND(cte.cum_sum, 2) as cum_sum,
	    ROUND(cte.centered_3_day_avg, 2) as centered_3_day_avg
FROM cte_avg cte
WHERE cte.calendar_week_number in (49, 50, 51)
ORDER BY
    cte.calendar_week_number,
    cte.time_id;

-- Task 3

-- Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. 
-- Additionally, explain the reason for choosing a specific frame type for each example. 
-- This can be presented as a single query or as three distinct queries.

-- Task 3.1.

-- Calculate the moving average of quarterly sales using the current quarter and the previous quarter for the years 1998–2002.

-- ROWS was used because the calculation is based on a fixed number of physical rows: the current quarter and one previous quarter.

WITH cte_quarter_sales AS (
    SELECT
        t.calendar_year,
        t.calendar_quarter_number,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.times t 
        ON s.time_id = t.time_id 
    WHERE EXTRACT(YEAR FROM s.time_id) IN (1998, 1999, 2000, 2001, 2002)
    GROUP BY
        t.calendar_year,
        t.calendar_quarter_number
)
SELECT
    cte.calendar_year,
    cte.calendar_quarter_number,
    cte.total_sales,
    AVG(cte.total_sales) OVER (
        ORDER BY cte.calendar_year, cte.calendar_quarter_number
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS moving_avg_quarters
FROM cte_quarter_sales cte
ORDER BY
    cte.calendar_year,
    cte.calendar_quarter_number;

-- Task 3.2

-- Generate a report showing the total daily sales and the cumulative sales amount 
-- for the previous 7 calendar days (including the current day) for the year 2000 using a RANGE window frame.

-- RANGE was chosen because the calculation should include all rows within a 7-day time interval 
-- relative to the current row, regardless of how many rows exist in that period.

WITH cte_daily_sales AS (
    SELECT
        t.time_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.times t
        ON s.time_id = t.time_id
    WHERE EXTRACT(YEAR FROM t.time_id) = 2000
    GROUP BY
        t.time_id
)
SELECT
    cte.time_id,
    cte.total_sales,
    SUM(cte.total_sales) OVER (
        ORDER BY cte.time_id
        RANGE BETWEEN INTERVAL '7 days' PRECEDING
              AND CURRENT ROW
    ) AS sales_last_7_days
FROM cte_daily_sales cte
ORDER BY cte.time_id;

-- Task 3.3.

-- Generate a report showing total sales by product category and calculate cumulative sales for the current and previous category groups 
-- using a GROUPS window frame.

-- GROUPS was chosen because the calculation should operate on groups of equal ordered values rather than individual rows.

WITH cte_category_sales AS (
    SELECT
        p.prod_category,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.products p
        ON s.prod_id = p.prod_id
    GROUP BY
        p.prod_category
)
SELECT
    cte.prod_category,
    cte.total_sales,
    SUM(cte.total_sales) OVER (
        ORDER BY cte.total_sales
        GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS cum_group_sales
FROM cte_category_sales cte
ORDER BY cte.total_sales;
