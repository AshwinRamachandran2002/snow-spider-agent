WITH sales_filtered AS (
    SELECT
        S."prod_id",
        S."amount_sold",
        T."calendar_year"            AS "year",
        T."calendar_month_number"    AS "month"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"       S
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   CU  ON S."cust_id"   = CU."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   CO  ON CU."country_id" = CO."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"    CH  ON S."channel_id" = CH."channel_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"  PR  ON S."promo_id"   = PR."promo_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"       T   ON S."time_id"    = T."time_id"
    WHERE CO."country_name"   = 'France'
      AND CH."channel_total_id" = 1
      AND PR."promo_total_id"   = 1
      AND T."calendar_year" IN (2019, 2020)
),
sales_agg AS (           -- total sales by product, year & month
    SELECT
        "prod_id",
        "year",
        "month",
        SUM("amount_sold") AS "total_sales"
    FROM sales_filtered
    GROUP BY "prod_id", "year", "month"
),
sales_2019 AS (
    SELECT * FROM sales_agg WHERE "year" = 2019
),
sales_2020 AS (
    SELECT * FROM sales_agg WHERE "year" = 2020
),
projection_local AS (    -- project 2021 sales in local currency
    SELECT
        s20."prod_id",
        s20."month",
        (
            ( (s20."total_sales" - s19."total_sales") / NULLIF(s19."total_sales", 0) )
            * s20."total_sales"
        ) + s20."total_sales"      AS "proj_sales_local"
    FROM sales_2020 s20
    JOIN sales_2019 s19
      ON s20."prod_id" = s19."prod_id"
     AND s20."month"   = s19."month"
    WHERE s19."total_sales" <> 0
),
projection_usd AS (      -- convert projection to USD
    SELECT
        p."prod_id",
        p."month",
        p."proj_sales_local"
        * COALESCE(cur."to_us", 1) AS "proj_sales_usd"
    FROM projection_local p
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
           ON cur."country" = 'France'
          AND cur."year"    = 2021
          AND cur."month"   = p."month"
),
monthly_avg AS (         -- average across products for each month
    SELECT
        "month",
        AVG("proj_sales_usd") AS "avg_month_sales_usd"
    FROM projection_usd
    GROUP BY "month"
)
SELECT
    MEDIAN("avg_month_sales_usd") AS "median_avg_monthly_projected_sales_usd_2021_france"
FROM monthly_avg;