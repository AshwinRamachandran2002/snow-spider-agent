SELECT
  ROUND((COUNT(DISTINCT CASE WHEN totals."total_transactions" >= 1 THEN totals."fullVisitorId" END) * 100.0) / COUNT(DISTINCT totals."fullVisitorId"), 4) AS "Conversion_rate",
  ROUND(SUM(CASE WHEN totals."total_transactions" >= 1 THEN totals."total_transactions" ELSE 0 END) * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN totals."total_transactions" >= 1 THEN totals."fullVisitorId" END), 0), 4) AS "Average_Number_of_Transactions_per_Purchaser"
FROM (
  SELECT
    "fullVisitorId",
    SUM(COALESCE("transactions", 0)) AS "total_transactions"
  FROM ECOMMERCE.ECOMMERCE.ALL_SESSIONS
  GROUP BY "fullVisitorId"
) AS totals;