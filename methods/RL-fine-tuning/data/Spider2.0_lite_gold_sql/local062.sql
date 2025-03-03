WITH total_profits AS (
    SELECT "s"."cust_id",
           SUM("s"."quantity_sold" * ("cst"."unit_price" - "cst"."unit_cost")) AS "total_profit"
    FROM "sales" AS "s"
    JOIN "customers" AS "c" ON "s"."cust_id" = "c"."cust_id"
    JOIN "times" AS "t" ON "s"."time_id" = "t"."time_id"
    JOIN "costs" AS "cst" ON
        "s"."prod_id" = "cst"."prod_id" AND
        "s"."time_id" = "cst"."time_id" AND
        "s"."promo_id" = "cst"."promo_id" AND
        "s"."channel_id" = "cst"."channel_id"
    WHERE "c"."country_id" IN (
        SELECT "country_id" FROM "countries" WHERE "country_name" = 'Italy'
    ) AND
        "t"."calendar_year" = 2021 AND
        "t"."calendar_month_number" = 12
    GROUP BY "s"."cust_id"
),
profit_range AS (
    SELECT MIN("total_profit") AS "min_total_profit",
           MAX("total_profit") AS "max_total_profit"
    FROM total_profits
),
intervals AS (
    SELECT ("max_total_profit" - "min_total_profit") / 10.0 AS "interval_width",
           "min_total_profit",
           "max_total_profit"
    FROM profit_range
),
bucketed_profits AS (
    SELECT "cust_id",
           "total_profit",
           CASE
               WHEN "total_profit" = "max_total_profit" THEN 10
               ELSE CAST((("total_profit" - "min_total_profit") / "interval_width") AS INTEGER) + 1
           END AS "Bucket_Number"
    FROM total_profits, intervals
)
SELECT "Bucket_Number",
       COUNT("cust_id") AS "Number_of_Customers",
       ROUND(MIN("total_profit"), 4) AS "Min_Total_Profit",
       ROUND(MAX("total_profit"), 4) AS "Max_Total_Profit"
FROM bucketed_profits
GROUP BY "Bucket_Number"
ORDER BY "Bucket_Number";