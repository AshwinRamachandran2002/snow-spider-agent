WITH
"france_country_id" AS (
  SELECT "country_id"
  FROM "countries"
  WHERE "country_name" = 'France'
),
"monthly_2019" AS (
  SELECT 
    "times"."calendar_month_number" AS "month",
    SUM("sales"."amount_sold" * "currency"."to_us") AS "sales_2019_usd"
  FROM "sales"
  JOIN "customers" ON "sales"."cust_id" = "customers"."cust_id"
  JOIN "promotions" ON "sales"."promo_id" = "promotions"."promo_id"
  JOIN "channels" ON "sales"."channel_id" = "channels"."channel_id"
  JOIN "times" ON "sales"."time_id" = "times"."time_id"
  JOIN "currency" ON "currency"."country" = 'France'
    AND "currency"."year" = "times"."calendar_year"
    AND "currency"."month" = "times"."calendar_month_number"
  WHERE "customers"."country_id" = (SELECT "country_id" FROM "france_country_id")
    AND "promotions"."promo_total_id" = 1
    AND "channels"."channel_total_id" = 1
    AND "times"."calendar_year" = 2019
  GROUP BY "times"."calendar_month_number"
),
"monthly_2020" AS (
  SELECT 
    "times"."calendar_month_number" AS "month",
    SUM("sales"."amount_sold" * "currency"."to_us") AS "sales_2020_usd"
  FROM "sales"
  JOIN "customers" ON "sales"."cust_id" = "customers"."cust_id"
  JOIN "promotions" ON "sales"."promo_id" = "promotions"."promo_id"
  JOIN "channels" ON "sales"."channel_id" = "channels"."channel_id"
  JOIN "times" ON "sales"."time_id" = "times"."time_id"
  JOIN "currency" ON "currency"."country" = 'France'
    AND "currency"."year" = "times"."calendar_year"
    AND "currency"."month" = "times"."calendar_month_number"
  WHERE "customers"."country_id" = (SELECT "country_id" FROM "france_country_id")
    AND "promotions"."promo_total_id" = 1
    AND "channels"."channel_total_id" = 1
    AND "times"."calendar_year" = 2020
  GROUP BY "times"."calendar_month_number"
),
"growth_rates" AS (
  SELECT
    "monthly_2019"."month",
    "monthly_2019"."sales_2019_usd",
    "monthly_2020"."sales_2020_usd",
    (("monthly_2020"."sales_2020_usd" - "monthly_2019"."sales_2019_usd") / "monthly_2019"."sales_2019_usd") AS "growth_rate"
  FROM "monthly_2019"
  JOIN "monthly_2020" ON "monthly_2019"."month" = "monthly_2020"."month"
),
"projected_sales_2021" AS (
  SELECT
    "month",
    ("sales_2020_usd" * (1 + "growth_rate")) AS "projected_sales_usd"
  FROM "growth_rates"
)
SELECT AVG("projected_sales_usd") AS "Median_Average_Monthly_Projected_Sales_USD"
FROM (
  SELECT "projected_sales_usd"
  FROM "projected_sales_2021"
  ORDER BY "projected_sales_usd"
  LIMIT 2 OFFSET 5
);