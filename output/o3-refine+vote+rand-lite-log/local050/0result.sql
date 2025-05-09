WITH monthly_sales AS (   -- France monthly sales for 2019‑2020 (promo_total_id=1, channel_total_id=1)
    SELECT
        strftime('%Y', s.time_id)      AS yr,
        CAST(strftime('%m', s.time_id) AS INTEGER) AS mo,
        SUM(s.amount_sold)             AS total_sales
    FROM   sales        s
    JOIN   customers    c   ON c.cust_id   = s.cust_id
    JOIN   countries    co  ON co.country_id = c.country_id
    JOIN   promotions   p   ON p.promo_id  = s.promo_id
    JOIN   channels     ch  ON ch.channel_id = s.channel_id
    WHERE  co.country_name   = 'France'
      AND  p.promo_total_id  = 1
      AND  ch.channel_total_id = 1
      AND  strftime('%Y', s.time_id) IN ('2019','2020')
    GROUP BY yr, mo
),
paired AS (              -- match each month of 2019 to the same month of 2020
    SELECT
        m19.mo                      AS month,
        m19.total_sales             AS sales_2019,
        m20.total_sales             AS sales_2020
    FROM  monthly_sales m19
    JOIN  monthly_sales m20
          ON m19.mo = m20.mo
         AND m19.yr = '2019'
         AND m20.yr = '2020'
),
proj_local AS (          -- project 2021 monthly sales using 2019‑2020 growth
    SELECT
        month,
        (sales_2020 + (sales_2020 - sales_2019)) AS projected_local
    FROM   paired
    WHERE  sales_2019 IS NOT NULL
       AND sales_2020 IS NOT NULL
),
proj_usd AS (            -- convert projected 2021 sales to USD
    SELECT
        pl.month,
        pl.projected_local * COALESCE(cur.to_us,1) AS projected_usd
    FROM   proj_local pl
    LEFT   JOIN currency cur
           ON cur.country = 'France'
          AND cur.year    = 2021
          AND cur.month   = pl.month
),
ordered AS (             -- prepare for median calculation
    SELECT
        projected_usd,
        ROW_NUMBER() OVER (ORDER BY projected_usd) AS rn,
        COUNT(*)  OVER ()                           AS cnt
    FROM   proj_usd
)
SELECT ROUND(AVG(projected_usd),4) AS median_projected_sales_usd
FROM   ordered
WHERE  rn IN ( CAST((cnt + 1)/2 AS INTEGER),
               CAST((cnt + 2)/2 AS INTEGER) );