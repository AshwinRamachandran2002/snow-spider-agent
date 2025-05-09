WITH italian_customers AS (
    SELECT "cust_id"
    FROM "customers"
    WHERE "country_id" = (
        SELECT "country_id"
        FROM "countries"
        WHERE "country_name" = 'Italy'
    )
),
customer_profits AS (
    SELECT s."cust_id",
           SUM(s."quantity_sold" * (c."unit_price" - c."unit_cost")) AS "total_profit"
    FROM "sales" s
    JOIN "costs" c
      ON s."prod_id" = c."prod_id"
     AND s."time_id" = c."time_id"
     AND s."channel_id" = c."channel_id"
     AND s."promo_id" = c."promo_id"
    WHERE s."cust_id" IN (SELECT "cust_id" FROM italian_customers)
      AND s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY s."cust_id"
),
profit_buckets AS (
    SELECT
        "cust_id",
        "total_profit",
        NTILE(10) OVER (ORDER BY "total_profit") AS "Bucket_Number"
    FROM customer_profits
)
SELECT
    "Bucket_Number",
    COUNT(*) AS "Number_of_Customers",
    ROUND(MIN("total_profit"), 4) AS "Min_Total_Profit",
    ROUND(MAX("total_profit"), 4) AS "Max_Total_Profit"
FROM profit_buckets
GROUP BY "Bucket_Number"
ORDER BY "Bucket_Number";