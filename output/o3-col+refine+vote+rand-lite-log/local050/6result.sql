WITH
-- 1.  helper sets for the required promo / channel roll-ups
promo_ids AS (
    SELECT promo_id
    FROM promotions
    WHERE promo_total_id = 1
),
channel_ids AS (
    SELECT channel_id
    FROM channels
    WHERE channel_total_id = 1
),

-- 2.  all 2019/2020 French sales that match the above filters
sales_fr AS (
    SELECT s.amount_sold,
           s.time_id
    FROM   sales      AS s
    JOIN   customers  AS c  ON c.cust_id   = s.cust_id
    JOIN   countries  AS co ON co.country_id = c.country_id
    WHERE  co.country_name = 'France'
      AND  s.promo_id  IN (SELECT promo_id  FROM promo_ids)
      AND  s.channel_id IN (SELECT channel_id FROM channel_ids)
      AND  substr(s.time_id,1,4) IN ('2019','2020')
),

-- 3.  average € sales per month & year
monthly_avg AS (
    SELECT CAST(substr(time_id,6,2) AS INTEGER)  AS month,
           CAST(substr(time_id,1,4) AS INTEGER)  AS year,
           AVG(amount_sold)                      AS avg_amount
    FROM   sales_fr
    GROUP  BY year, month
),

avg_2019 AS (
    SELECT month, avg_amount AS avg_2019
    FROM   monthly_avg
    WHERE  year = 2019
),
avg_2020 AS (
    SELECT month, avg_amount AS avg_2020
    FROM   monthly_avg
    WHERE  year = 2020
),

-- 4.  month-by-month growth factor (2020 vs 2019) and 2021 projection
projection_2021 AS (
    SELECT a20.month,
           a20.avg_2020,
           a19.avg_2019,
           /* growth factor = 2020 / 2019 */
           CASE WHEN a19.avg_2019 IS NOT NULL AND a19.avg_2019 <> 0
                THEN a20.avg_2020 / a19.avg_2019
           END                                   AS growth_factor,
           /* projected 2021 average = 2020 * growth factor */
           CASE WHEN a19.avg_2019 IS NOT NULL AND a19.avg_2019 <> 0
                THEN a20.avg_2020 * (a20.avg_2020 / a19.avg_2019)
           END                                   AS proj_avg_2021_eur
    FROM   avg_2020 a20
    JOIN   avg_2019 a19 USING (month)
),

-- 5.  convert projected 2021 € averages to USD using 2021 FX rates
proj_usd AS (
    SELECT p.month,
           p.proj_avg_2021_eur,
           c.to_us,
           p.proj_avg_2021_eur * c.to_us  AS proj_avg_2021_usd
    FROM   projection_2021  AS p
    JOIN   currency         AS c
           ON  c.country = 'France'
           AND c.year    = 2021
           AND c.month   = p.month
),

-- 6.  median of the 12 projected monthly averages (even-row median logic)
median_calc AS (
    SELECT AVG(proj_avg_2021_usd) AS median_projected_avg_sales_usd
    FROM (
        SELECT proj_avg_2021_usd
        FROM   proj_usd
        ORDER  BY proj_avg_2021_usd
        LIMIT  2 - (SELECT COUNT(*) FROM proj_usd) % 2            -- 1 row if odd, 2 rows if even
        OFFSET (SELECT (COUNT(*) - 1) / 2 FROM proj_usd)          -- middle (or lower-middle) position
    )
)

SELECT median_projected_avg_sales_usd
FROM   median_calc;