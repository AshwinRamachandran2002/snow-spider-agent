WITH filtered_sales AS (
    /* France-only sales made through qualifying promos & channels */
    SELECT  s.prod_id,
            s.time_id,
            s.amount_sold
    FROM    sales       s
    JOIN    customers   c   ON c.cust_id   = s.cust_id
    JOIN    countries   co  ON co.country_id = c.country_id
    JOIN    promotions  p   ON p.promo_id  = s.promo_id
    JOIN    channels    ch  ON ch.channel_id = s.channel_id
    WHERE   co.country_name   = 'France'
      AND   p.promo_total_id  = 1          -- only the desired promotions
      AND   ch.channel_total_id = 1        -- only the desired channels
),
sales_2019 AS (
    /* monthly 2019 € sales per product */
    SELECT  strftime('%m', time_id) AS mon,
            prod_id,
            SUM(amount_sold)       AS sales_2019
    FROM    filtered_sales
    WHERE   strftime('%Y', time_id) = '2019'
    GROUP BY mon, prod_id
),
sales_2020 AS (
    /* monthly 2020 € sales per product */
    SELECT  strftime('%m', time_id) AS mon,
            prod_id,
            SUM(amount_sold)       AS sales_2020
    FROM    filtered_sales
    WHERE   strftime('%Y', time_id) = '2020'
    GROUP BY mon, prod_id
),
growth AS (
    /* growth rate 2020 vs 2019 for the same product & month */
    SELECT  s20.mon,
            s20.prod_id,
            s20.sales_2020,
            s19.sales_2019,
            CASE
                 WHEN s19.sales_2019 IS NULL
                      OR s19.sales_2019 = 0
                 THEN NULL                       -- undefined growth
                 ELSE s20.sales_2020 * 1.0 / s19.sales_2019
            END                       AS growth_rate
    FROM    sales_2020 s20
    LEFT JOIN sales_2019 s19
           ON s19.mon     = s20.mon
          AND s19.prod_id = s20.prod_id
),
projected_2021 AS (
    /* apply the growth rate to 2020 sales to project 2021 (€) */
    SELECT  mon,
            prod_id,
            sales_2020 * COALESCE(growth_rate, 1) AS proj_2021_eur
    FROM    growth
)
SELECT  t.calendar_month_name                          AS month_2021,
        ROUND(AVG(p.proj_2021_eur * cu.to_us), 4)      AS avg_projected_sales_usd
FROM    projected_2021 p
JOIN    times     t  ON t.calendar_year        = 2021
                    AND t.calendar_month_number = CAST(p.mon AS INTEGER)
JOIN    currency  cu ON cu.country = 'France'
                    AND cu.year    = 2021
                    AND cu.month   = CAST(p.mon AS INTEGER)
GROUP BY t.calendar_month_number, t.calendar_month_name
ORDER BY t.calendar_month_number;