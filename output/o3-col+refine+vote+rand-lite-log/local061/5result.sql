WITH france_sales AS (          -- 1.  France 2019-2020 sales (promo_total_id = 1, channel_total_id = 1)
    SELECT  s.prod_id,
            t.calendar_month_number         AS month,
            t.calendar_year                 AS year,
            SUM(s.amount_sold)              AS total_sales
    FROM    sales       AS s
    JOIN    customers   AS c   ON s.cust_id  = c.cust_id
    JOIN    countries   AS co  ON c.country_id = co.country_id
    JOIN    promotions  AS p   ON s.promo_id = p.promo_id
    JOIN    channels    AS ch  ON s.channel_id = ch.channel_id
    JOIN    times       AS t   ON s.time_id   = t.time_id
    WHERE   co.country_name = 'France'
      AND   p.promo_total_id = 1
      AND   ch.channel_total_id = 1
      AND   t.calendar_year IN (2019, 2020)
    GROUP BY s.prod_id, t.calendar_year, t.calendar_month_number
),
sales_2019 AS (                 -- 2.  2019 monthly sales per product
    SELECT prod_id, month, total_sales AS sales_2019
    FROM   france_sales
    WHERE  year = 2019
),
sales_2020 AS (                 -- 3.  2020 monthly sales per product
    SELECT prod_id, month, total_sales AS sales_2020
    FROM   france_sales
    WHERE  year = 2020
),
growth AS (                     -- 4.  Growth factor (2020 / 2019)
    SELECT  s20.prod_id,
            s20.month,
            s19.sales_2019,
            s20.sales_2020,
            CASE WHEN s19.sales_2019 > 0
                 THEN (s20.sales_2020 * 1.0) / s19.sales_2019
                 ELSE NULL
            END AS growth_factor
    FROM    sales_2020 s20
    JOIN    sales_2019 s19
           ON s20.prod_id = s19.prod_id
          AND s20.month   = s19.month
),
proj_2021 AS (                  -- 5.  Projected 2021 sales in local currency
    SELECT  prod_id,
            month,
            CASE WHEN growth_factor IS NOT NULL
                 THEN sales_2020 * growth_factor        -- 2021 = 2020 × growth factor
                 ELSE NULL
            END AS projected_2021_local
    FROM    growth
),
proj_usd AS (                    -- 6.  Convert projected 2021 sales to USD
    SELECT  p.month,
            p.prod_id,
            p.projected_2021_local * cu.to_us AS projected_2021_usd
    FROM    proj_2021 p
    JOIN    currency cu
           ON cu.country = 'France'
          AND cu.year    = 2021
          AND cu.month   = p.month
    WHERE   p.projected_2021_local IS NOT NULL
)
-- 7.  Average projected monthly sales (USD) by month
SELECT  month,
        ROUND(AVG(projected_2021_usd), 4) AS avg_projected_monthly_sales_usd
FROM    proj_usd
GROUP BY month
ORDER BY month;