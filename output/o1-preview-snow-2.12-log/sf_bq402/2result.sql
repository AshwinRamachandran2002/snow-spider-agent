WITH
  "total_visitors" AS (
    SELECT COUNT(DISTINCT "fullVisitorId") AS "total_visitors"
    FROM ECOMMERCE.ECOMMERCE."ALL_SESSIONS"
  ),
  "total_purchasers" AS (
    SELECT COUNT(DISTINCT "fullVisitorId") AS "total_purchasers"
    FROM ECOMMERCE.ECOMMERCE."ALL_SESSIONS"
    WHERE "transactions" >= 1
  ),
  "average_transactions_per_purchaser" AS (
    SELECT ROUND(AVG("total_transactions"), 4) AS "average_transactions_per_purchaser"
    FROM (
      SELECT "fullVisitorId", SUM("transactions") AS "total_transactions"
      FROM ECOMMERCE.ECOMMERCE."ALL_SESSIONS"
      WHERE "transactions" >= 1
      GROUP BY "fullVisitorId"
    )
  )
SELECT
  ROUND(("total_purchasers"."total_purchasers" * 100.0) / "total_visitors"."total_visitors", 4) AS "Conversion_rate",
  "average_transactions_per_purchaser"."average_transactions_per_purchaser" AS "Average_Number_of_Transactions_per_Purchaser"
FROM
  "total_visitors",
  "total_purchasers",
  "average_transactions_per_purchaser";