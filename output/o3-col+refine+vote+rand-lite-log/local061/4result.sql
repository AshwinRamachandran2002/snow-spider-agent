WITH
-- 1) France’s country_id
fr AS (
    SELECT country_id
    FROM   countries
    WHERE  country_name = 'France'
),
-- 2) 2019-2020 monthly sales per product that match
--    (a) French customers,
--    (b) promo_total_id = 1,
--    (c) channel_total_id = 1
filtered_sales AS (
    SELECT
        s.prod_id,
        t.calendar_year  AS yr,
        t.calendar_month_number AS mo,
        SUM(s.amount_sold)      AS sales_amt
    FROM   sales       AS s
    JOIN   customers   AS c   ON c.cust_id   = s.cust_id
    JOIN   fr          AS f   ON c.country_id = f.country_id
    JOIN   promotions  AS p   ON p.promo_id  = s.promo_id
                              AND p.promo_total_id = 1
    JOIN   channels    AS ch  ON ch.channel_id = s.channel_id
                              AND ch.channel_total_id = 1
    JOIN   times       AS t   ON t.time_id   = s.time_id
    WHERE  t.calendar_year IN (2019, 2020)
    GROUP  BY s.prod_id, t.calendar_year, t.calendar_month_number
),
-- 3) Split the two years
sales19 AS (
    SELECT prod_id, mo, sales_amt AS sales2019
    FROM   filtered_sales
    WHERE  yr = 2019
),
sales20 AS (
    SELECT prod_id, mo, sales_amt AS sales2020
    FROM   filtered_sales
    WHERE  yr = 2020
),
-- 4) Compute growth rate and project 2021 sales
proj21 AS (
    SELECT
        s20.prod_id,
        s20.mo,
        /* growth rate = (2020-2019)/2019 ; projected = 2020 * (1+growth) */
        s20.sales2020 * (s20.sales2020 / s19.sales2019)  AS projected_amt
    FROM   sales20 s20
    JOIN   sales19 s19
           ON s19.prod_id = s20.prod_id
          AND s19.mo      = s20.mo
    WHERE  s19.sales2019 > 0            -- avoid div-by-zero
),
-- 5) Convert the projected 2021 amounts to USD
proj21_usd AS (
    SELECT
        p.mo,
        p.projected_amt * cur.to_us AS proj_usd
    FROM   proj21  AS p
    JOIN   currency AS cur
           ON  cur.country = 'France'
           AND cur.year    = 2021
           AND cur.month   = p.mo
)
-- 6) Average projected sales by month
SELECT
    mo   AS month,
    ROUND(AVG(proj_usd), 4) AS avg_projected_monthly_sales_usd
FROM   proj21_usd
GROUP  BY mo
ORDER  BY mo;