WITH fr_sales AS (      -- 2019‑2020 French sales in USD (promo_total_id=1, channel_total_id=1)
    SELECT  s.amount_sold * cu.to_us        AS amount_usd,
            t.calendar_year                 AS yr,
            t.calendar_month_number         AS mo
    FROM    sales       AS s
    JOIN    customers   AS c   ON s.cust_id  = c.cust_id
    JOIN    countries   AS co  ON c.country_id = co.country_id
    JOIN    promotions  AS p   ON s.promo_id = p.promo_id
    JOIN    channels    AS ch  ON s.channel_id = ch.channel_id
    JOIN    times       AS t   ON s.time_id   = t.time_id
    JOIN    currency    AS cu  ON cu.country  = co.country_name
                               AND cu.year    = t.calendar_year
                               AND cu.month   = t.calendar_month_number
    WHERE   co.country_name     = 'France'
      AND   p.promo_total_id    = 1
      AND   ch.channel_total_id = 1
      AND   t.calendar_year IN (2019, 2020)
),
month_tot AS (          -- monthly totals for 2019 and 2020
    SELECT yr,
           mo,
           SUM(amount_usd) AS total_usd
    FROM   fr_sales
    GROUP  BY yr, mo
),
growth AS (             -- month‑by‑month growth rate 2019 → 2020
    SELECT  t20.mo,
            t20.total_usd                                           AS total_2020,
            CASE WHEN t19.total_usd = 0 
                 THEN 0
                 ELSE (t20.total_usd - t19.total_usd) * 1.0 / t19.total_usd
            END                                                     AS growth_rate
    FROM    month_tot t19
    JOIN    month_tot t20 ON t20.mo = t19.mo
    WHERE   t19.yr = 2019
      AND   t20.yr = 2020
),
proj_2021 AS (          -- projected 2021 monthly totals
    SELECT  mo,
            total_2020 * (1 + growth_rate)  AS projected_usd
    FROM    growth
),
txn_2020 AS (           -- transaction count per month in 2020
    SELECT  t.calendar_month_number AS mo,
            COUNT(*)                AS txn_cnt
    FROM    sales       AS s
    JOIN    customers   AS c   ON s.cust_id  = c.cust_id
    JOIN    countries   AS co  ON c.country_id = co.country_id
    JOIN    promotions  AS p   ON s.promo_id = p.promo_id
    JOIN    channels    AS ch  ON s.channel_id = ch.channel_id
    JOIN    times       AS t   ON s.time_id   = t.time_id
    WHERE   co.country_name     = 'France'
      AND   p.promo_total_id    = 1
      AND   ch.channel_total_id = 1
      AND   t.calendar_year     = 2020
    GROUP BY t.calendar_month_number
),
month_avg AS (          -- average projected sale value per month for 2021
    SELECT  p.mo,
            p.projected_usd / NULLIF(t.txn_cnt,0) AS avg_month_usd
    FROM    proj_2021 p
    JOIN    txn_2020  t ON t.mo = p.mo
),
median_calc AS (        -- median of the 12 monthly averages
    SELECT  AVG(avg_month_usd) AS median_projected_monthly_sales_usd
    FROM   (
        SELECT  avg_month_usd
        FROM    month_avg
        ORDER BY avg_month_usd
        LIMIT 2 - (SELECT COUNT(*) % 2 FROM month_avg)          -- 1 row if odd, 2 if even
        OFFSET (SELECT (COUNT(*) - 1)/2 FROM month_avg)         -- middle row(s)
    )
)
SELECT ROUND(median_projected_monthly_sales_usd,4) AS median_projected_monthly_sales_usd
FROM   median_calc;