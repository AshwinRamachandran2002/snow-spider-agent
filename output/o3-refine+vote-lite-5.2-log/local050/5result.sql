WITH france AS (
    SELECT country_id, country_name
    FROM countries
    WHERE country_name = 'France'
),
monthly_avg AS (
    /* Average monthly sales (already converted to USD) for 2019 & 2020 */
    SELECT
        t.calendar_year          AS yr,
        t.calendar_month_number  AS mn,
        AVG(s.amount_sold * curr.to_us) AS avg_usd
    FROM       sales      s
    JOIN customers        c   ON s.cust_id   = c.cust_id
    JOIN france           f   ON c.country_id = f.country_id
    JOIN promotions       p   ON s.promo_id  = p.promo_id
    JOIN channels         ch  ON s.channel_id= ch.channel_id
    JOIN times            t   ON s.time_id   = t.time_id
    JOIN currency         curr
         ON curr.country = f.country_name
        AND curr.year    = t.calendar_year
        AND curr.month   = t.calendar_month_number
    WHERE p.promo_total_id   = 1      -- keep only required promotions
      AND ch.channel_total_id= 1      -- keep only required channels
      AND t.calendar_year IN (2019, 2020)
    GROUP BY t.calendar_year, t.calendar_month_number
),
growth AS (
    /* Growth factor from 2019 → 2020 for each month */
    SELECT
        m19.mn,
        m19.avg_usd AS avg19,
        m20.avg_usd AS avg20,
        CASE
            WHEN m19.avg_usd IS NOT NULL AND m19.avg_usd <> 0
            THEN m20.avg_usd / m19.avg_usd
        END           AS growth_factor
    FROM monthly_avg m19
    JOIN monthly_avg m20
         ON m19.mn = m20.mn
        AND m19.yr = 2019
        AND m20.yr = 2020
),
proj2021 AS (
    /* Projected 2021 average monthly sales */
    SELECT
        mn,
        avg20 * growth_factor AS avg2021
    FROM growth
    WHERE growth_factor IS NOT NULL
),
ordered AS (
    /* Order the projected monthly averages to compute median */
    SELECT
        avg2021,
        ROW_NUMBER() OVER (ORDER BY avg2021) AS rn,
        COUNT(*)  OVER ()                     AS cnt
    FROM proj2021
)
SELECT
    ROUND(AVG(avg2021), 4) AS median_avg_monthly_sales_usd_2021
FROM ordered
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );