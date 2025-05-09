WITH sales_fr AS (          -- 1.  France sales (2019‑2020) that match the required promos & channels
    SELECT  s.prod_id,
            t.calendar_year  AS yr,
            t.calendar_month_number AS mn,
            SUM(s.amount_sold)      AS amt
    FROM    sales      AS s
    JOIN    customers  AS cu  ON cu.cust_id   = s.cust_id
    JOIN    countries  AS co  ON co.country_id= cu.country_id
    JOIN    promotions AS pr  ON pr.promo_id  = s.promo_id
    JOIN    channels   AS ch  ON ch.channel_id= s.channel_id
    JOIN    times      AS t   ON t.time_id    = s.time_id
    WHERE   co.country_name   = 'France'
      AND   pr.promo_total_id = 1            -- only the requested promotions
      AND   ch.channel_total_id = 1          -- only the requested channels
      AND   t.calendar_year IN (2019,2020)   -- base years
    GROUP BY s.prod_id, t.calendar_year, t.calendar_month_number
),

growth AS (               -- 2.  Compute growth rate per product & month
    SELECT  s19.prod_id,
            s19.mn,
            s19.amt              AS amt_2019,
            s20.amt              AS amt_2020,
            CASE WHEN s19.amt>0
                 THEN (s20.amt - s19.amt)*1.0 / s19.amt
            END                  AS growth_rate
    FROM   sales_fr AS s19
    JOIN   sales_fr AS s20
           ON  s19.prod_id = s20.prod_id
           AND s19.mn      = s20.mn
           AND s19.yr      = 2019
           AND s20.yr      = 2020
),

proj_local AS (           -- 3.  Project 2021 sales in local currency
    SELECT  prod_id,
            mn,
            amt_2020 * (1.0 + growth_rate)   AS proj_2021_local
    FROM    growth
    WHERE   growth_rate IS NOT NULL
),

proj_usd AS (             -- 4.  Convert projection to USD with 2021 FX rate
    SELECT  pl.prod_id,
            pl.mn,
            pl.proj_2021_local * cu.to_us    AS proj_2021_usd
    FROM    proj_local AS pl
    JOIN    currency  AS cu
           ON cu.country = 'France'
          AND cu.year    = 2021
          AND cu.month   = pl.mn
)

-- 5.  Average projected 2021 USD sales by month
SELECT   mn  AS month,
         ROUND(AVG(proj_2021_usd),4) AS avg_projected_sales_usd
FROM     proj_usd
GROUP BY mn
ORDER BY mn;