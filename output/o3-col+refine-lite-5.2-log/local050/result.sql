WITH
sales19 AS (   -- monthly France sales in 2019 (promo_total_id = 1, channel_total_id = 1)
    SELECT t."calendar_month_number" AS month,
           SUM(s."amount_sold")      AS tot19
    FROM   "sales"      s
    JOIN   "customers"  cu ON cu."cust_id"    = s."cust_id"
    JOIN   "countries"  co ON co."country_id" = cu."country_id"
    JOIN   "promotions" p  ON p."promo_id"    = s."promo_id"  AND p."promo_total_id"  = 1
    JOIN   "channels"   ch ON ch."channel_id" = s."channel_id" AND ch."channel_total_id" = 1
    JOIN   "times"      t  ON t."time_id"     = s."time_id"
    WHERE  co."country_name" = 'France'
      AND  t."calendar_year" = 2019
    GROUP  BY t."calendar_month_number"
),
sales20 AS (   -- monthly France sales in 2020 (same filters)
    SELECT t."calendar_month_number" AS month,
           SUM(s."amount_sold")      AS tot20
    FROM   "sales"      s
    JOIN   "customers"  cu ON cu."cust_id"    = s."cust_id"
    JOIN   "countries"  co ON co."country_id" = cu."country_id"
    JOIN   "promotions" p  ON p."promo_id"    = s."promo_id"  AND p."promo_total_id"  = 1
    JOIN   "channels"   ch ON ch."channel_id" = s."channel_id" AND ch."channel_total_id" = 1
    JOIN   "times"      t  ON t."time_id"     = s."time_id"
    WHERE  co."country_name" = 'France'
      AND  t."calendar_year" = 2020
    GROUP  BY t."calendar_month_number"
),
proj21 AS (    -- project 2021 totals: 2020 * growth‑rate  (i.e. tot20^2 / tot19)
    SELECT s20.month,
           (s20.tot20 * 1.0 * s20.tot20 / s19.tot19) AS proj_tot21
    FROM   sales20 s20
    JOIN   sales19 s19 USING (month)
),
days AS (      -- days in each 2021 month
    SELECT t."calendar_month_number" AS month,
           MAX(t."days_in_cal_month") AS days_in_month
    FROM   "times" t
    WHERE  t."calendar_year" = 2021
    GROUP  BY t."calendar_month_number"
),
proj_daily AS (   -- average projected DAILY sales in USD per month
    SELECT p.month,
           (p.proj_tot21 * c."to_us") / d.days_in_month AS avg_daily_usd
    FROM   proj21  p
    JOIN   "currency" c ON c."country" = 'France'
                       AND c."year"    = 2021
                       AND c."month"   = p.month
    JOIN   days      d ON d.month      = p.month
),
ordered AS (   -- order the 12 averages for median
    SELECT avg_daily_usd,
           ROW_NUMBER() OVER (ORDER BY avg_daily_usd) AS rn,
           COUNT(*)  OVER ()                          AS cnt
    FROM   proj_daily
)
SELECT AVG(avg_daily_usd) AS median_avg_daily_sales_usd_2021
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );