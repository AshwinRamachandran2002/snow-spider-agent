WITH france AS (
    SELECT country_id
    FROM countries
    WHERE country_name = 'France'
),
-- 1.  Monthly sales for 2019 & 2020 in France (only wanted promos / channels)
sales_ft AS (
    SELECT
        s.prod_id,
        t.calendar_month_number   AS month,
        t.calendar_year           AS yr,
        SUM(s.amount_sold)        AS amt
    FROM       sales       s
    JOIN customers          c   ON c.cust_id   = s.cust_id
    JOIN france             f   ON f.country_id= c.country_id
    JOIN promotions         p   ON p.promo_id  = s.promo_id   AND p.promo_total_id   = 1
    JOIN channels           ch  ON ch.channel_id= s.channel_id AND ch.channel_total_id= 1
    JOIN times              t   ON t.time_id   = s.time_id
    WHERE t.calendar_year IN (2019, 2020)
    GROUP BY s.prod_id, month, yr
),
sales19 AS (SELECT prod_id, month, amt AS amt19 FROM sales_ft WHERE yr = 2019),
sales20 AS (SELECT prod_id, month, amt AS amt20 FROM sales_ft WHERE yr = 2020),

-- 2.  Growth rate 2019→2020 and projected 2021 local‑currency sales
proj21_local AS (
    SELECT
        s20.prod_id,
        s20.month,
        /* projected = 2020 amount × (1 + growth rate) */
        s20.amt20 * (1.0 + (s20.amt20 - s19.amt19) / s19.amt19) AS proj_local
    FROM sales20 s20
    JOIN sales19 s19
      ON s19.prod_id = s20.prod_id
     AND s19.month   = s20.month
    WHERE s19.amt19 > 0          -- avoid divide‑by‑zero
),

-- 3.  Convert projected 2021 amounts to USD with 2021 rates
proj21_usd AS (
    SELECT
        p.month,
        p.prod_id,
        p.proj_local * cur.to_us AS proj_usd
    FROM proj21_local p
    JOIN currency   cur
      ON cur.country = 'France'
     AND cur.year    = 2021
     AND cur.month   = p.month
)

-- 4.  Average projected USD sales by month
SELECT
    month,
    ROUND(AVG(proj_usd), 4) AS avg_projected_sales_usd
FROM proj21_usd
GROUP BY month
ORDER BY month;