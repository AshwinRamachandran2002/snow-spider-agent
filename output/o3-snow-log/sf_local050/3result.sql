WITH fr_sales AS (   -- France sales in 2019-2020, required promotion / channel filters
    SELECT
        s."prod_id",
        s."time_id",
        s."amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"       s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   c  ON s."cust_id"   = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   ctr ON c."country_id" = ctr."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"  p  ON s."promo_id"  = p."promo_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"    ch ON s."channel_id" = ch."channel_id"
    WHERE ctr."country_name" = 'France'
      AND p."promo_total_id" = 1
      AND ch."channel_total_id" = 1
      AND LEFT(s."time_id",4) IN ('2019','2020')
),
prod_month_sales AS (   -- total sales per product-month-year
    SELECT
        "prod_id",
        TO_NUMBER(LEFT("time_id",4))           AS "yr",
        TO_NUMBER(SUBSTR("time_id",6,2))       AS "mo",
        SUM("amount_sold")                     AS "sales_amt"
    FROM fr_sales
    GROUP BY "prod_id","yr","mo"
),
sales_2019 AS (
    SELECT "prod_id","mo","sales_amt" AS "sales_2019"
    FROM prod_month_sales
    WHERE "yr" = 2019
),
sales_2020 AS (
    SELECT "prod_id","mo","sales_amt" AS "sales_2020"
    FROM prod_month_sales
    WHERE "yr" = 2020
),
growth AS (          -- join 2019 & 2020 to compute projection base
    SELECT
        s20."prod_id",
        s20."mo",
        s20."sales_2020",
        COALESCE(s19."sales_2019",0) AS "sales_2019"
    FROM sales_2020 s20
    LEFT JOIN sales_2019 s19
           ON s20."prod_id" = s19."prod_id"
          AND s20."mo"      = s19."mo"
),
projection_local AS (  -- apply given projection formula (local currency)
    SELECT
        "prod_id",
        "mo",
        CASE
            WHEN "sales_2019" = 0 THEN NULL           -- avoid div/0
            ELSE (("sales_2020" - "sales_2019") / "sales_2019") * "sales_2020"
                 + "sales_2020"                       -- (= sales_2020^2 / sales_2019)
        END AS "proj_sales_local"
    FROM growth
),
projection_usd AS (    -- convert to USD (multiply by rate, default 1)
    SELECT
        pl."prod_id",
        pl."mo",
        pl."proj_sales_local"
        * COALESCE(cur."to_us",1)  AS "proj_sales_usd"
    FROM projection_local pl
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
           ON cur."country" = 'France'
          AND cur."year"    = 2021
          AND cur."month"   = pl."mo"
),
monthly_avg AS (       -- average projected sales per month across products
    SELECT
        "mo",
        AVG("proj_sales_usd") AS "avg_month_proj_usd"
    FROM projection_usd
    WHERE "proj_sales_usd" IS NOT NULL
    GROUP BY "mo"
),
median_calc AS (       -- median of the 12 monthly averages
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "avg_month_proj_usd")
        AS "median_avg_monthly_proj_usd"
    FROM monthly_avg
)
SELECT "median_avg_monthly_proj_usd"
FROM   median_calc;