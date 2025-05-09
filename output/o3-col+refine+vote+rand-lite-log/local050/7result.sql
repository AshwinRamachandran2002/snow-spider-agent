WITH base AS (                         -- average monthly sales for 2019 & 2020
    SELECT
        strftime('%m', t."time_id") AS month,
        AVG(CASE WHEN strftime('%Y', t."time_id")='2019'
                 THEN s."amount_sold" END) AS avg19,
        AVG(CASE WHEN strftime('%Y', t."time_id")='2020'
                 THEN s."amount_sold" END) AS avg20
    FROM   "sales"      s
    JOIN   "customers"  cu ON cu."cust_id"    = s."cust_id"
    JOIN   "countries"  co ON co."country_id" = cu."country_id"
    JOIN   "promotions" p  ON p."promo_id"    = s."promo_id"
    JOIN   "channels"   ch ON ch."channel_id" = s."channel_id"
    JOIN   "times"      t  ON t."time_id"     = s."time_id"
    WHERE  co."country_name"    = 'France'
      AND  p."promo_total_id"   = 1
      AND  ch."channel_total_id"= 1
      AND  strftime('%Y', t."time_id") IN ('2019','2020')
    GROUP BY month
),
proj_local AS (                        -- project 2021 monthly averages (local)
    SELECT
        month,
        avg20 * (avg20 / avg19) AS proj21_local
    FROM base
),
proj_usd AS (                          -- convert projection to USD
    SELECT
        pl.month,
        pl.proj21_local * COALESCE(c.to_us,1) AS proj21_usd
    FROM   proj_local pl
    LEFT JOIN "currency" c
           ON c.country='France'
          AND c.year   = 2020          -- latest known rate
          AND printf('%02d', c.month)=pl.month
),
ordered AS (                           -- order for median calculation
    SELECT
        proj21_usd,
        ROW_NUMBER() OVER (ORDER BY proj21_usd) AS rn,
        COUNT(*)    OVER ()                     AS cnt
    FROM proj_usd
)
SELECT AVG(proj21_usd) AS median_monthly_proj_sales_usd
FROM   ordered
WHERE  rn IN (cnt/2, cnt/2 + 1);        -- median for even/odd counts