WITH sales_data AS (
  SELECT
    "TIMES"."calendar_month_number" AS "month",
    "TIMES"."calendar_year" AS "year",
    SUM("SALES"."amount_sold") AS "sales_amount"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS"
    ON "SALES"."cust_id" = "CUSTOMERS"."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"
    ON "CUSTOMERS"."country_id" = "COUNTRIES"."country_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES"
    ON "SALES"."time_id" = "TIMES"."time_id"
  WHERE "COUNTRIES"."country_name" = 'France'
    AND "TIMES"."calendar_year" IN (2019, 2020)
  GROUP BY "TIMES"."calendar_month_number", "TIMES"."calendar_year"
),
pivot_sales AS (
  SELECT
    "month",
    SUM(CASE WHEN "year" = 2019 THEN "sales_amount" END) AS "sales_2019",
    SUM(CASE WHEN "year" = 2020 THEN "sales_amount" END) AS "sales_2020"
  FROM sales_data
  GROUP BY "month"
),
currency_rates AS (
  SELECT
    "month",
    AVG("to_us") AS "exchange_rate"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY"
  WHERE "country" = 'France' AND "year" = 2021
  GROUP BY "month"
),
projected_sales AS (
  SELECT
    p."month",
    p."sales_2019",
    p."sales_2020",
    CASE 
      WHEN p."sales_2019" IS NOT NULL AND p."sales_2019" <> 0 THEN 
        (p."sales_2020" - p."sales_2019") / p."sales_2019"
      ELSE 
        0
    END AS "percentage_change",
    p."sales_2020" * (1 + 
      CASE 
        WHEN p."sales_2019" IS NOT NULL AND p."sales_2019" <> 0 THEN 
          (p."sales_2020" - p."sales_2019") / p."sales_2019"
        ELSE 
          0
      END
    ) AS "projected_sales_2021_local"
  FROM pivot_sales p
)
SELECT
  MONTHNAME(DATE_FROM_PARTS(2021, ps."month", 1)) AS "Month",
  ROUND(ps."projected_sales_2021_local" * COALESCE(cr."exchange_rate", 1), 4) AS "Projected_Sales_USD"
FROM projected_sales ps
LEFT JOIN currency_rates cr
  ON ps."month" = cr."month"
ORDER BY ps."month";