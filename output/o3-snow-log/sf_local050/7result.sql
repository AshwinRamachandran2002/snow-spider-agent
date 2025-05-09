WITH "FR_SALES" AS (
    SELECT
        s."prod_id",
        t."calendar_year"          AS "year",
        t."calendar_month_number"  AS "month",
        SUM(s."amount_sold")       AS "amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"       s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   c   ON s."cust_id"  = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   cn  ON c."country_id" = cn."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"  p   ON s."promo_id" = p."promo_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"    ch  ON s."channel_id" = ch."channel_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"       t   ON s."time_id"  = t."time_id"
    WHERE cn."country_name"   = 'France'
      AND p."promo_total_id"  = 1
      AND ch."channel_total_id" = 1
      AND t."calendar_year" IN (2019, 2020)
    GROUP BY s."prod_id", t."calendar_year", t."calendar_month_number"
),
"SALES_PIVOT" AS (
    SELECT
        "prod_id",
        "month",
        SUM(CASE WHEN "year" = 2019 THEN "amount_sold" END) AS "sales_2019",
        SUM(CASE WHEN "year" = 2020 THEN "amount_sold" END) AS "sales_2020"
    FROM "FR_SALES"
    GROUP BY "prod_id", "month"
),
"PROJ2021" AS (
    SELECT
        sp."prod_id",
        sp."month",
        CASE
            WHEN sp."sales_2019" IS NULL 
              OR sp."sales_2019" = 0 
              OR sp."sales_2020" IS NULL
            THEN NULL
            ELSE (((sp."sales_2020" - sp."sales_2019") / sp."sales_2019") * sp."sales_2020") + sp."sales_2020"
        END AS "projected_sales_2021"
    FROM "SALES_PIVOT" sp
),
"PROJ2021_USD" AS (
    SELECT
        p21."prod_id",
        p21."month",
        COALESCE(cur."to_us", 1) * p21."projected_sales_2021" AS "proj_sales_usd"
    FROM "PROJ2021" p21
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
           ON cur."country" = 'France'
          AND cur."year"    = 2021
          AND cur."month"   = p21."month"
    WHERE p21."projected_sales_2021" IS NOT NULL
),
"MONTHLY_AVG" AS (
    SELECT
        "month",
        AVG("proj_sales_usd") AS "avg_proj_sales_usd"
    FROM "PROJ2021_USD"
    GROUP BY "month"
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "avg_proj_sales_usd") 
        AS "median_avg_monthly_proj_sales_usd"
FROM "MONTHLY_AVG";