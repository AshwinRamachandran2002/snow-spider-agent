WITH customer_profits AS (
    SELECT s."cust_id",
           SUM(s."amount_sold" - s."quantity_sold" * c."unit_cost") AS "total_profit"
    FROM "sales" s
    JOIN "costs" c ON s."prod_id" = c."prod_id"
                   AND s."time_id" = c."time_id"
    JOIN "customers" cu ON s."cust_id" = cu."cust_id"
    JOIN "countries" co ON cu."country_id" = co."country_id"
    WHERE s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
      AND co."country_name" = 'Italy'
    GROUP BY s."cust_id"
),
profit_stats AS (
    SELECT MIN("total_profit") AS "min_profit",
           MAX("total_profit") AS "max_profit",
           (MAX("total_profit") - MIN("total_profit")) / 10.0 AS "interval_width"
    FROM customer_profits
),
customer_buckets AS (
    SELECT c."cust_id",
           c."total_profit",
           ((c."total_profit" - ps."min_profit") / ps."interval_width") AS "bucket_number_float"
    FROM customer_profits c
    CROSS JOIN profit_stats ps
),
customer_buckets_int AS (
    SELECT "cust_id",
           "total_profit",
           CASE
              WHEN "bucket_number_float" >= 10 THEN 10
              WHEN "bucket_number_float" < 0 THEN 1
              ELSE CAST("bucket_number_float" AS INTEGER) + 1
           END AS "bucket_number"
    FROM customer_buckets
),
buckets AS (
    SELECT 1 AS "bucket_number" UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4 UNION ALL
    SELECT 5 UNION ALL
    SELECT 6 UNION ALL
    SELECT 7 UNION ALL
    SELECT 8 UNION ALL
    SELECT 9 UNION ALL
    SELECT 10
)
SELECT 'Bucket' || b."bucket_number" AS "Profit_Bucket",
       COALESCE(COUNT(cbi."cust_id"), 0) AS "Number_of_Customers",
       ROUND(COALESCE(MAX(cbi."total_profit"), 0), 4) AS "Max_Profit",
       ROUND(COALESCE(MIN(cbi."total_profit"), 0), 4) AS "Min_Profit"
FROM buckets b
LEFT JOIN customer_buckets_int cbi ON b."bucket_number" = cbi."bucket_number"
GROUP BY b."bucket_number"
ORDER BY b."bucket_number";