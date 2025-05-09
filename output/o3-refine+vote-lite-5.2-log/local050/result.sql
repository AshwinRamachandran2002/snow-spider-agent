WITH france AS (
    SELECT country_id
    FROM countries
    WHERE country_name = 'France'
),
--------------------------------------------------------------------
-- 1. 2019‑2020 sales for French customers, limited to the required
--    promotions (promo_total_id = 1) and channels (channel_total_id = 1)
--------------------------------------------------------------------
filtered_sales AS (
    SELECT  s.amount_sold,
            t.calendar_year  AS yr,
            t.calendar_month_number AS mon
    FROM    sales       s
    JOIN    customers   c  ON c.cust_id   = s.cust_id
    JOIN    france      f  ON f.country_id = c.country_id
    JOIN    channels    ch ON ch.channel_id = s.channel_id
    JOIN    promotions  p  ON p.promo_id   = s.promo_id
    JOIN    times       t  ON t.time_id    = s.time_id
    WHERE   ch.channel_total_id = 1
      AND   p.promo_total_id    = 1
      AND   t.calendar_year IN (2019, 2020)
),
--------------------------------------------------------------------
-- 2. Monthly totals for each year
--------------------------------------------------------------------
monthly_sales AS (
    SELECT  yr,
            mon,
            SUM(amount_sold) AS total_sales
    FROM    filtered_sales
    GROUP BY yr, mon
),
--------------------------------------------------------------------
-- 3. Year‑level totals and overall growth factor 2019 → 2020
--------------------------------------------------------------------
year_totals AS (
    SELECT  yr,
            SUM(total_sales) AS year_total
    FROM    monthly_sales
    GROUP BY yr
),
growth AS (
    SELECT (SELECT year_total FROM year_totals WHERE yr = 2020) * 1.0 /
           (SELECT year_total FROM year_totals WHERE yr = 2019) AS g_factor
),
--------------------------------------------------------------------
-- 4. Project 2021 monthly sales in local currency
--------------------------------------------------------------------
proj_2021_local AS (
    SELECT  mon,
            ms20.total_sales * g.g_factor AS proj_sales_local
    FROM    monthly_sales ms20
    CROSS JOIN growth g
    WHERE   ms20.yr = 2020
),
--------------------------------------------------------------------
-- 5. Convert the projection to USD using the 2021 FX rate
--------------------------------------------------------------------
proj_2021_usd AS (
    SELECT  p.mon,
            p.proj_sales_local / COALESCE(cur.to_us,1) AS proj_sales_usd
    FROM    proj_2021_local p
    LEFT JOIN currency cur
           ON cur.country = 'France'
          AND cur.year    = 2021
          AND cur.month   = p.mon
),
--------------------------------------------------------------------
-- 6. Order the 12 monthly values and pick the median
--------------------------------------------------------------------
ordered_vals AS (
    SELECT  proj_sales_usd,
            ROW_NUMBER() OVER (ORDER BY proj_sales_usd) AS rn,
            COUNT(*)  OVER ()                           AS cnt
    FROM    proj_2021_usd
),
median_calc AS (
    SELECT AVG(proj_sales_usd) AS median_value
    FROM   ordered_vals
    WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 )     -- works for odd/even
)
SELECT median_value
FROM   median_calc;