WITH sales_fr AS (
    /* 1.  France sales in 2019‑2020 that meet the promo & channel filters */
    SELECT
        sa.prod_id,
        t.calendar_month_number   AS month_n,
        t.calendar_year           AS yr,
        SUM(sa.amount_sold)       AS amt
    FROM   sales        sa
    JOIN   times        t   ON t.time_id      = sa.time_id
    JOIN   customers    cu  ON cu.cust_id     = sa.cust_id
    JOIN   countries    co  ON co.country_id  = cu.country_id
    JOIN   promotions   pr  ON pr.promo_id    = sa.promo_id
    JOIN   channels     ch  ON ch.channel_id  = sa.channel_id
    WHERE  co.country_name   = 'France'
      AND  pr.promo_total_id = 1
      AND  ch.channel_total_id = 1
      AND  t.calendar_year IN (2019, 2020)
    GROUP  BY sa.prod_id, month_n, yr
),
pivot AS (
    /* 2.  Put 2019 and 2020 amounts side‑by‑side */
    SELECT
        prod_id,
        month_n,
        SUM(CASE WHEN yr = 2019 THEN amt END) AS amt_2019,
        SUM(CASE WHEN yr = 2020 THEN amt END) AS amt_2020
    FROM   sales_fr
    GROUP  BY prod_id, month_n
),
projected AS (
    /* 3.  Project 2021 per product & month (simple linear growth) */
    SELECT
        prod_id,
        month_n,
        CASE
            WHEN COALESCE(amt_2019,0) > 0
                 THEN COALESCE(amt_2020,0) + (COALESCE(amt_2020,0) - COALESCE(amt_2019,0))
            ELSE COALESCE(amt_2020,0)      -- if no 2019 data, keep 2020 level
        END AS proj_2021_local
    FROM   pivot
),
projection_usd AS (
    /* 4.  Convert every projected value to USD using 2021 FX rate */
    SELECT
        p.month_n,
        p.proj_2021_local * c.to_us AS proj_2021_usd
    FROM   projected p
    JOIN   currency  c  ON c.country = 'France'
                       AND c.year    = 2021
                       AND c.month   = p.month_n
)
 /* 5.  Average projected USD sales per month across products */
SELECT
    month_n                                 AS month,
    ROUND(AVG(proj_2021_usd),4)             AS avg_projected_sales_usd
FROM   projection_usd
GROUP  BY month_n
ORDER  BY month_n;