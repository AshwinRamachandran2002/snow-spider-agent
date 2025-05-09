WITH ------------------------------------------------ 2020 monthly totals for France
monthly_20 AS (
    SELECT  t."calendar_month_number" AS mon,
            SUM(s."amount_sold")      AS tot20
    FROM    "sales"      s
    JOIN    "customers"  cu  ON cu."cust_id"    = s."cust_id"
    JOIN    "countries"  co  ON co."country_id" = cu."country_id"
    JOIN    "promotions" p   ON p."promo_id"    = s."promo_id"
    JOIN    "channels"   ch  ON ch."channel_id" = s."channel_id"
    JOIN    "times"      t   ON t."time_id"     = s."time_id"
    WHERE   co."country_name"     = 'France'
      AND   p."promo_total_id"    = 1
      AND   ch."channel_total_id" = 1
      AND   t."calendar_year"     = 2020
    GROUP BY mon
),
------------------------------------------------------ 2019 & 2020 monthly totals
monthly_all AS (
    SELECT  t."calendar_year"         AS yr,
            t."calendar_month_number" AS mon,
            SUM(s."amount_sold")      AS month_tot
    FROM    "sales"      s
    JOIN    "customers"  cu  ON cu."cust_id"    = s."cust_id"
    JOIN    "countries"  co  ON co."country_id" = cu."country_id"
    JOIN    "promotions" p   ON p."promo_id"    = s."promo_id"
    JOIN    "channels"   ch  ON ch."channel_id" = s."channel_id"
    JOIN    "times"      t   ON t."time_id"     = s."time_id"
    WHERE   co."country_name"     = 'France'
      AND   p."promo_total_id"    = 1
      AND   ch."channel_total_id" = 1
      AND   t."calendar_year" IN (2019, 2020)
    GROUP BY yr, mon
),
yr_avgs AS (                         -- average monthly total for each year
    SELECT  yr, AVG(month_tot) AS avg_mon
    FROM    monthly_all
    GROUP BY yr
),
growth AS (                          -- overall growth rate 2019 -> 2020
    SELECT  (MAX(CASE WHEN yr = 2020 THEN avg_mon END) -
             MAX(CASE WHEN yr = 2019 THEN avg_mon END))
            / MAX(CASE WHEN yr = 2019 THEN avg_mon END)  AS g
    FROM    yr_avgs
),
projected_local AS (                 -- 2021 projection in local currency
    SELECT  m.mon,
            m.tot20 * (1 + g.g) AS proj_local
    FROM    monthly_20 m
    CROSS   JOIN growth g
),
proj_usd AS (                        -- convert projections to USD
    SELECT  pl.mon,
            pl.proj_local * fx."to_us" AS proj_usd
    FROM    projected_local pl
    JOIN    "currency"      fx
           ON fx."country" = 'France'
          AND fx."year"    = 2021
          AND fx."month"   = pl.mon
),
ordered_vals AS (                    -- prepare for median
    SELECT  proj_usd,
            ROW_NUMBER() OVER (ORDER BY proj_usd) AS rn,
            COUNT(*)    OVER ()                  AS cnt
    FROM    proj_usd
)
SELECT  AVG(proj_usd) AS median_projected_2021_usd
FROM    ordered_vals
WHERE   rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );