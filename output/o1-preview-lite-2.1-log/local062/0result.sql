WITH customer_profits AS (
  SELECT
    s."cust_id",
    ROUND(SUM(s."amount_sold" - s."quantity_sold" * c."unit_cost"), 4) AS "total_profit"
  FROM "sales" AS s
  JOIN "costs" AS c ON s."prod_id" = c."prod_id" AND s."time_id" = c."time_id"
  JOIN "customers" AS cu ON s."cust_id" = cu."cust_id"
  WHERE cu."country_id" = (
    SELECT "country_id" FROM "countries" WHERE "country_name" = 'Italy'
  )
    AND s."time_id" LIKE '2021-12-%'
  GROUP BY s."cust_id"
),
profit_stats AS (
  SELECT
    MIN(total_profit) AS min_profit,
    MAX(total_profit) AS max_profit,
    (MAX(total_profit) - MIN(total_profit)) / 10.0 AS interval_width
  FROM customer_profits
),
customer_buckets AS (
  SELECT
    cp."cust_id",
    cp."total_profit",
    CASE
      WHEN cp."total_profit" = ps.max_profit THEN 10
      ELSE CAST( ((cp."total_profit" - ps.min_profit) / ps.interval_width ) AS INTEGER ) + 1
    END AS bucket_number
  FROM
    customer_profits cp,
    profit_stats ps
)
SELECT
  'Bucket' || bucket_number AS Profit_Bucket,
  COUNT(*) AS Number_of_Customers,
  ROUND(MAX(total_profit), 4) AS Max_Profit,
  ROUND(MIN(total_profit), 4) AS Min_Profit
FROM
  customer_buckets
GROUP BY
  bucket_number
ORDER BY
  bucket_number;