WITH base AS (   -- sales in France (2019-2020) that belong to promo_total_id=1 & channel_total_id=1
    SELECT
        s."prod_id",
        s."amount_sold",
        t."calendar_year",
        t."calendar_month_number"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"       s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"  p ON s."promo_id"  = p."promo_id"  AND p."promo_total_id"   = 1
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"    c ON s."channel_id" = c."channel_id" AND c."channel_total_id" = 1
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" cust ON s."cust_id"   = cust."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" ctr  ON cust."country_id" = ctr."country_id" AND ctr."country_name" = 'France'
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"      t   ON s."time_id"   = t."time_id"
    WHERE t."calendar_year" IN (2019, 2020)
),
agg AS (          -- totals per product & month for 2019 and 2020
    SELECT
        "prod_id",
        "calendar_month_number"    AS month_num,
        SUM(CASE WHEN "calendar_year" = 2019 THEN "amount_sold" ELSE 0 END) AS sum_2019,
        SUM(CASE WHEN "calendar_year" = 2020 THEN "amount_sold" ELSE 0 END) AS sum_2020
    FROM base
    GROUP BY "prod_id", "calendar_month_number"
),
proj AS (         -- 2021 projection using growth from 2019→2020
    SELECT
        "prod_id",
        month_num,
        CASE
            WHEN sum_2019 = 0 THEN sum_2020            -- avoid ÷0; if no 2019 sales use 2020 value
            ELSE ((sum_2020 - sum_2019) / NULLIF(sum_2019,0)) * sum_2020 + sum_2020
        END AS projected_2021_local
    FROM agg
),
conv AS (         -- 2021 FX rate France→USD (default 1 when absent)
    SELECT
        "month"                                     AS month_num,
        COALESCE(AVG("to_us"),1)                    AS rate
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY"
    WHERE "country" = 'France' AND "year" = 2021
    GROUP BY "month"
),
proj_usd AS (     -- projection converted to USD
    SELECT
        p.month_num,
        p."prod_id",
        p.projected_2021_local * COALESCE(c.rate,1) AS projected_2021_usd
    FROM proj p
    LEFT JOIN conv c ON p.month_num = c.month_num
),
avg_month AS (    -- average projected sales per month across products
    SELECT
        month_num,
        AVG(projected_2021_usd) AS avg_projected_usd
    FROM proj_usd
    GROUP BY month_num
)
-- median of the 12 monthly averages
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_projected_usd)
        AS median_avg_monthly_projected_sales_usd
FROM avg_month;