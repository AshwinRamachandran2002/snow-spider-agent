WITH french_customers AS (
    SELECT cu."cust_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  cu
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co
      ON cu."country_id" = co."country_id"
    WHERE co."country_name" = 'France'
), sales_france AS (
    SELECT s."prod_id",
           s."amount_sold",
           s."time_id",
           s."channel_id",
           s."promo_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    JOIN french_customers fc
      ON s."cust_id" = fc."cust_id"
), sales_filtered AS (
    SELECT sf."prod_id",
           sf."amount_sold",
           t."calendar_month_number" AS month_num,
           t."calendar_year"         AS year
    FROM sales_france sf
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS" p
      ON sf."promo_id" = p."promo_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS" ch
      ON sf."channel_id" = ch."channel_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t
      ON sf."time_id" = t."time_id"
    WHERE p."promo_total_id"   = 1
      AND ch."channel_total_id" = 1
      AND t."calendar_year" IN (2019, 2020)
), monthly_totals AS (
    SELECT "prod_id",
           month_num,
           year,
           SUM("amount_sold") AS total_sales
    FROM sales_filtered
    GROUP BY "prod_id", month_num, year
), sales_pivot AS (
    SELECT "prod_id",
           month_num,
           MAX(CASE WHEN year = 2019 THEN total_sales END) AS sales_2019,
           MAX(CASE WHEN year = 2020 THEN total_sales END) AS sales_2020
    FROM monthly_totals
    GROUP BY "prod_id", month_num
), projected_local AS (
    SELECT "prod_id",
           month_num,
           sales_2019,
           sales_2020,
           CASE
               WHEN sales_2019 IS NOT NULL
                AND sales_2020 IS NOT NULL
                AND sales_2019 <> 0
               THEN (((sales_2020 - sales_2019) / sales_2019) * sales_2020) + sales_2020
           END AS projected_2021_local
    FROM sales_pivot
), projected_usd AS (
    SELECT pl."prod_id",
           pl.month_num,
           pl.projected_2021_local *
           COALESCE(cur."to_us", 1.0) AS projected_2021_usd
    FROM projected_local pl
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
           ON cur."country" = 'France'
          AND cur."year"    = 2021
          AND cur."month"   = pl.month_num
), monthly_average AS (
    SELECT month_num,
           AVG(projected_2021_usd) AS avg_monthly_projected_usd
    FROM projected_usd
    WHERE projected_2021_usd IS NOT NULL
    GROUP BY month_num
)
SELECT MEDIAN(avg_monthly_projected_usd) AS median_of_avg_monthly_projected_usd
FROM monthly_average;