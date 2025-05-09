WITH monthly_sales AS (
    /* 1.  France‑only monthly sales for 2019‑2020 under the required
           promotions and channels                                         */
    SELECT  s.prod_id,
            t.calendar_year       AS yr,
            t.calendar_month_number AS mnth,
            SUM(s.amount_sold)    AS amt
    FROM    sales       s
    JOIN    times       t   ON t.time_id   = s.time_id
    JOIN    promotions  p   ON p.promo_id  = s.promo_id
    JOIN    channels    ch  ON ch.channel_id = s.channel_id
    JOIN    customers   cu  ON cu.cust_id  = s.cust_id
    JOIN    countries   co  ON co.country_id = cu.country_id
    WHERE   p.promo_total_id   = 1               -- promo filter
      AND   ch.channel_total_id = 1              -- channel filter
      AND   co.country_name     = 'France'       -- France only
      AND   t.calendar_year IN (2019, 2020)      -- needed years
    GROUP BY s.prod_id, t.calendar_year, t.calendar_month_number
),
growth AS (
    /* 2.  Growth rate from 2019 to 2020 for the same product & month       */
    SELECT  m19.prod_id,
            m19.mnth,
            m19.amt  AS amt_2019,
            m20.amt  AS amt_2020,
            CASE WHEN m19.amt > 0
                 THEN 1.0 * m20.amt / m19.amt
            END      AS growth_rate
    FROM    monthly_sales m19
    JOIN    monthly_sales m20
           ON m19.prod_id = m20.prod_id
          AND m19.mnth    = m20.mnth
    WHERE   m19.yr = 2019
      AND   m20.yr = 2020
),
projected AS (
    /* 3.  Project 2021 local‑currency sales by applying the growth rate
           to the 2020 amount                                              */
    SELECT  prod_id,
            mnth,
            amt_2020 * growth_rate AS proj_2021_local
    FROM    growth
    WHERE   growth_rate IS NOT NULL
),
projected_usd AS (
    /* 4.  Convert projected 2021 sales to USD using 2021 FX rates          */
    SELECT  p.mnth,
            p.proj_2021_local * c.to_us AS proj_2021_usd
    FROM    projected p
    JOIN    currency  c
           ON c.country = 'France'
          AND c.year    = 2021
          AND c.month   = p.mnth
)
/* 5.  Average the projected USD sales across all products for each month  */
SELECT      mnth  AS month,
            ROUND(AVG(proj_2021_usd), 4) AS avg_projected_monthly_sales_usd
FROM        projected_usd
GROUP BY    mnth
ORDER BY    mnth;