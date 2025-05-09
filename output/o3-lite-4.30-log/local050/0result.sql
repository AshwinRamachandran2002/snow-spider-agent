WITH france_customers AS (
    SELECT cu."cust_id"
    FROM "customers" cu
    JOIN "countries" co
      ON co."country_id" = cu."country_id"
    WHERE co."country_name" = 'France'
),
sales_filtered AS (
    SELECT s."amount_sold",
           s."time_id"
    FROM "sales" s
    JOIN france_customers fc
      ON fc."cust_id" = s."cust_id"
    JOIN "channels" ch
      ON ch."channel_id"     = s."channel_id"
     AND ch."channel_total_id" = 1
    JOIN "promotions" pr
      ON pr."promo_id"        = s."promo_id"
     AND pr."promo_total_id"  = 1
),
monthly_totals AS (
    SELECT t."calendar_year"        AS yr,
           t."calendar_month_number" AS mon,
           SUM(s."amount_sold")      AS total_sales
    FROM sales_filtered s
    JOIN "times" t
      ON t."time_id" = s."time_id"
    WHERE t."calendar_year" IN (2019, 2020)
    GROUP BY t."calendar_year", t."calendar_month_number"
),
growth AS (
    SELECT t20.mon,
           t19.total_sales                      AS total_2019,
           t20.total_sales                      AS total_2020,
           (t20.total_sales * 1.0 / t19.total_sales) AS growth_rate
    FROM monthly_totals t20
    JOIN monthly_totals t19
      ON t19.mon = t20.mon
     AND t19.yr  = 2019
    WHERE t20.yr = 2020
),
projected_2021 AS (
    SELECT mon,
           total_2020 * growth_rate AS projected_sales
    FROM growth
),
projected_usd AS (
    SELECT p.mon,
           p.projected_sales * COALESCE(c."to_us", 1.0) AS projected_sales_usd
    FROM projected_2021 p
    LEFT JOIN "currency" c
      ON c."country" = 'France'
     AND c."year"    = 2021
     AND c."month"   = p.mon
),
ordered_vals AS (
    SELECT projected_sales_usd,
           ROW_NUMBER() OVER (ORDER BY projected_sales_usd) AS rn,
           COUNT(*)  OVER ()                                AS cnt
    FROM projected_usd
),
median_set AS (
    SELECT projected_sales_usd
    FROM ordered_vals
    WHERE rn = (cnt + 1) / 2
       OR rn = (cnt + 2) / 2
)
SELECT ROUND(AVG(projected_sales_usd), 4) AS median_projected_monthly_sales_usd
FROM median_set;