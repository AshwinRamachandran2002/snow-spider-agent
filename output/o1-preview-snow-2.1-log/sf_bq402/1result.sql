SELECT
  ROUND(
    (COUNT(DISTINCT "fullVisitorId") * 100.0) / (SELECT COUNT(DISTINCT "fullVisitorId") FROM ECOMMERCE.ECOMMERCE."ALL_SESSIONS"), 4
  ) AS "Conversion_rate",
  ROUND(
    AVG("Total_Transactions"), 4
  ) AS "Average_Number_of_Transactions_per_Purchaser"
FROM (
  SELECT "fullVisitorId", SUM("transactions") AS "Total_Transactions"
  FROM ECOMMERCE.ECOMMERCE."ALL_SESSIONS"
  WHERE "transactions" >= 1
  GROUP BY "fullVisitorId"
) AS purchasers;