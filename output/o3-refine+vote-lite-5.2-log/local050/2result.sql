WITH france_sales AS (
    SELECT 
        s.amount_sold,
        s.time_id,
        strftime('%Y', s.time_id) AS yr,
        strftime('%m', s.time_id) AS mon
    FROM   sales       AS s
    JOIN   customers   AS c   ON s.cust_id   = c.cust_id
    JOIN   countries   AS co  ON c.country_id = co.country_id
    JOIN   promotions  AS p   ON s.promo_id  = p.promo_id
    JOIN   channels    AS ch  ON s.channel_id = ch.channel_id
    WHERE  co.country_name      = 'France'
      AND  p.promo_total_id     = 1
      AND  ch.channel_total_id  = 1
      AND  strftime('%Y', s.time_id) IN ('2019','2020')
), ------------------------------------------------------------------
monthly_totals AS (               -- total sales per month
    SELECT 
        yr, 
        mon, 
        SUM(amount_sold) AS month_total
    FROM   france_sales
    GROUP  BY yr, mon
), ------------------------------------------------------------------
yearly_totals AS (                -- total sales per year
    SELECT 
        yr, 
        SUM(month_total) AS year_total
    FROM   monthly_totals
    GROUP  BY yr
), ------------------------------------------------------------------
growth_rate AS (                  -- 2019 → 2020 growth factor
    SELECT 
        CAST(y2020.year_total AS REAL) / NULLIF(y2019.year_total,0) AS rate
    FROM   yearly_totals AS y2019
    JOIN   yearly_totals AS y2020
           ON y2019.yr = '2019' AND y2020.yr = '2020'
), ------------------------------------------------------------------
projected_2021_local AS (         -- project 2021 by applying growth
    SELECT 
        2021                 AS proj_year,
        mt.mon               AS month,
        mt.month_total * gr.rate  AS projected_local
    FROM   monthly_totals AS mt
    CROSS  JOIN growth_rate AS gr
    WHERE  mt.yr = '2020'
), ------------------------------------------------------------------
projected_2021_usd AS (           -- convert projected amounts to USD
    SELECT 
        p.month,
        p.projected_local * cu.to_us AS proj_usd
    FROM   projected_2021_local AS p
    LEFT  JOIN currency AS cu
           ON cu.country = 'France'
          AND cu.year    = 2021
          AND cu.month   = CAST(p.month AS INTEGER)
) ------------------------------------------------------------------
-- ---------------  Median of the monthly projected USD values ---------------
SELECT 
    AVG(proj_usd) AS median_projected_monthly_sales_usd
FROM (
    SELECT 
        proj_usd
    FROM   projected_2021_usd
    ORDER  BY proj_usd
    LIMIT  2 - (SELECT COUNT(*) FROM projected_2021_usd) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM projected_2021_usd)
);