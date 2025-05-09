WITH monthly_sales AS (
    /* 1.  Monthly sales (local currency) for 2019‑2020 that meet all stated filters */
    SELECT
        s.prod_id,
        t.calendar_year  AS yr,
        t.calendar_month_number AS mon,
        SUM(s.amount_sold)      AS amt
    FROM        sales       s
    JOIN promotions  p   ON p.promo_id   = s.promo_id        AND p.promo_total_id   = 1
    JOIN channels    ch  ON ch.channel_id = s.channel_id     AND ch.channel_total_id = 1
    JOIN customers   cu  ON cu.cust_id    = s.cust_id
    JOIN countries   co  ON co.country_id = cu.country_id    AND co.country_name    = 'France'
    JOIN times       t   ON t.time_id     = s.time_id        AND t.calendar_year IN (2019,2020)
    GROUP BY s.prod_id, t.calendar_year, t.calendar_month_number
),
growth AS (
    /* 2.  2019→2020 growth factor for each product & month */
    SELECT
        m20.prod_id,
        m20.mon,
        m20.amt                            AS amt20,
        m19.amt                            AS amt19,
        CASE WHEN m19.amt <> 0 THEN m20.amt * 1.0 / m19.amt END AS growth_factor
    FROM monthly_sales m19
    JOIN monthly_sales m20
          ON m20.prod_id = m19.prod_id
         AND m20.mon     = m19.mon
         AND m19.yr      = 2019
         AND m20.yr      = 2020
),
proj_2021_local AS (
    /* 3.  Projected 2021 sales in local currency */
    SELECT
        prod_id,
        mon,
        amt20 * growth_factor AS proj21_local
    FROM growth
    WHERE growth_factor IS NOT NULL
),
proj_2021_usd AS (
    /* 4.  Convert projected 2021 sales to USD using 2021 FX rates */
    SELECT
        p.mon,
        p.prod_id,
        p.proj21_local * c.to_us AS proj21_usd
    FROM proj_2021_local p
    JOIN currency      c
         ON c.country = 'France'
        AND c.year     = 2021
        AND c.month    = p.mon
)
 /* 5.  Average the projected USD amounts by month */
SELECT
    mon                              AS month,
    ROUND(AVG(proj21_usd), 4)        AS avg_projected_sales_usd
FROM proj_2021_usd
GROUP BY mon
ORDER BY mon;