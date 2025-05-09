WITH
"monthly_sales_per_year" AS (
    SELECT 
        "times"."calendar_year",
        "times"."calendar_month_number", 
        SUM("sales"."amount_sold") AS "monthly_sales"
    FROM "sales"
    JOIN "customers" ON "sales"."cust_id" = "customers"."cust_id"
    JOIN "countries" ON "customers"."country_id" = "countries"."country_id"
    JOIN "times" ON "sales"."time_id" = "times"."time_id"
    WHERE "countries"."country_name" = 'France' 
      AND "times"."calendar_year" IN (2019, 2020)
    GROUP BY "times"."calendar_year", "times"."calendar_month_number"
),
"average_monthly_sales" AS (
    SELECT
        "calendar_month_number",
        AVG("monthly_sales") AS "average_sales"
    FROM "monthly_sales_per_year"
    GROUP BY "calendar_month_number"
),
"projected_sales" AS (
    SELECT
        "calendar_month_number",
        "average_sales" * 1.05 AS "projected_sales"
    FROM "average_monthly_sales"
)
SELECT
    AVG("projected_sales_usd") AS "Average_Monthly_Projected_Sales_in_USD"
FROM (
    SELECT
        ("projected_sales"."projected_sales" * "currency"."to_us") AS "projected_sales_usd"
    FROM "projected_sales"
    JOIN "currency" ON "currency"."country" = 'France' 
                   AND "currency"."year" = 2021 
                   AND "currency"."month" = "projected_sales"."calendar_month_number"
);