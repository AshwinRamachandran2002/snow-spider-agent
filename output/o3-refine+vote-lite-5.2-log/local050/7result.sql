WITH france AS (
    SELECT country_id
    FROM countries
    WHERE country_name = 'France'
),
filtered_sales AS (  -- 2019‑2020 sales for France, promo_total_id = 1, channel_total_id = 1
    SELECT 
        s.amount_sold * COALESCE(cr.to_us, 1) AS usd_amount,
        t.calendar_year                        AS yr,
        t.calendar_month_number                AS mon
    FROM   sales       AS s
    JOIN   customers   AS c  ON c.cust_id  = s.cust_id
    JOIN   france      AS f  ON f.country_id = c.country_id
    JOIN   promotions  AS p  ON p.promo_id   = s.promo_id   AND p.promo_total_id    = 1
    JOIN   channels    AS ch ON ch.channel_id = s.channel_id AND ch.channel_total_id = 1
    JOIN   times       AS t  ON t.time_id    = s.time_id
    LEFT   JOIN countries co ON co.country_id = c.country_id
    LEFT   JOIN currency  cr ON cr.country = co.country_name
                             AND cr.year    = t.calendar_year
                             AND cr.month   = t.calendar_month_number
    WHERE  t.calendar_year IN (2019, 2020)
),
monthly_totals AS (   -- monthly totals for the two years
    SELECT yr, mon, SUM(usd_amount) AS month_total
    FROM   filtered_sales
    GROUP  BY yr, mon
),
annual_totals AS (    -- yearly totals
    SELECT yr, SUM(month_total) AS year_total
    FROM   monthly_totals
    GROUP  BY yr
),
growth_rate AS (      -- overall growth 2019 → 2020
    SELECT (SELECT year_total FROM annual_totals WHERE yr = 2020) * 1.0 /
           NULLIF((SELECT year_total FROM annual_totals WHERE yr = 2019), 0) AS rate
),
projected_2021 AS (   -- project each 2020 month into 2021
    SELECT 2021 AS yr,
           mon,
           month_total * (SELECT rate FROM growth_rate) AS projected_total
    FROM   monthly_totals
    WHERE  yr = 2020
),
month_days AS (       -- number of days in each month (taken from 2020)
    SELECT calendar_month_number AS mon,
           MAX(days_in_cal_month) AS days_in_cal_month
    FROM   times
    WHERE  calendar_year = 2020
    GROUP  BY calendar_month_number
),
monthly_avg AS (      -- average daily projected sales for each 2021 month
    SELECT p.mon,
           p.projected_total / md.days_in_cal_month AS avg_daily
    FROM   projected_2021 p
    JOIN   month_days     md USING (mon)
),
ordered AS (          -- order the 12 monthly averages
    SELECT avg_daily,
           ROW_NUMBER() OVER (ORDER BY avg_daily) AS rn,
           COUNT(*)  OVER ()                      AS cnt
    FROM   monthly_avg
)
-- median of the 12 monthly averages
SELECT ROUND(AVG(avg_daily), 4) AS median_avg_monthly_projected_sales_usd
FROM (
    SELECT avg_daily
    FROM   ordered
    WHERE  rn = (SELECT (cnt + 1) / 2 FROM ordered LIMIT 1)
       OR  rn = (SELECT (cnt + 2) / 2 FROM ordered LIMIT 1)
);