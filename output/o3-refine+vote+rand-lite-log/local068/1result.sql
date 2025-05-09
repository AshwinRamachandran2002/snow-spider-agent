WITH
-- define the years and the three months we care about
years AS (
    SELECT 2021 AS yr UNION ALL
    SELECT 2022 UNION ALL
    SELECT 2023
),
months AS (
    SELECT 4 AS mo UNION ALL
    SELECT 5 UNION ALL
    SELECT 6
),
-- every (year , month) combination we need
grid AS (
    SELECT yr AS year , mo AS month
    FROM years
    CROSS JOIN months
),
-- count how many cities were inserted for every (year , month);
-- if none were inserted the count will be 0
month_totals AS (
    SELECT 
        g.year ,
        g.month ,
        COALESCE(COUNT(c.city_id),0) AS num_cities
    FROM grid g
    LEFT JOIN cities c
        ON CAST(STRFTIME('%Y', c.insert_date) AS INTEGER) = g.year
       AND CAST(STRFTIME('%m', c.insert_date) AS INTEGER) = g.month
    GROUP BY g.year , g.month
),
-- cumulative running total for the *same* month across the years
running AS (
    SELECT
        year ,
        month ,
        num_cities ,
        SUM(num_cities) OVER (PARTITION BY month ORDER BY year)    AS running_total
    FROM month_totals
),
-- add previous‑year values so we can compute YoY %
lagged AS (
    SELECT
        year ,
        month ,
        num_cities ,
        running_total ,
        LAG(num_cities)      OVER (PARTITION BY month ORDER BY year) AS prev_num ,
        LAG(running_total)   OVER (PARTITION BY month ORDER BY year) AS prev_run
    FROM running
)
SELECT
    year                                                     AS year ,
    CASE month
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
    END                                                      AS month ,
    num_cities                                               AS month_total ,
    running_total                                            AS running_total ,
    CASE
        WHEN prev_num IS NULL OR prev_num = 0 THEN NULL
        ELSE ROUND( (num_cities   - prev_num) * 100.0 / prev_num , 4)
    END                                                      AS yoy_month_pct ,
    CASE
        WHEN prev_run IS NULL OR prev_run = 0 THEN NULL
        ELSE ROUND( (running_total - prev_run) * 100.0 / prev_run , 4)
    END                                                      AS yoy_running_pct
FROM lagged
WHERE year IN (2022, 2023)
ORDER BY year , month;