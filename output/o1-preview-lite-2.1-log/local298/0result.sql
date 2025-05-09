WITH Months AS (
  SELECT DISTINCT substr("txn_date", 1, 7) AS "Month"
  FROM "customer_transactions"
),
OrderedMonths AS (
  SELECT "Month", ROW_NUMBER() OVER (ORDER BY "Month") AS rn
  FROM Months
),
SecondAndLaterMonths AS (
  SELECT "Month"
  FROM OrderedMonths
  WHERE rn > 1
),
CutoffDates AS (
  SELECT "Month",
         date(substr("Month", 1, 7) || '-01', '-1 day') AS "CutoffDate"
  FROM SecondAndLaterMonths
),
UserBalances AS (
  SELECT M."Month",
         U."customer_id",
         SUM(T."txn_amount") AS "balance"
  FROM CutoffDates M
  CROSS JOIN (SELECT DISTINCT "customer_id" FROM "customer_transactions") U
  LEFT JOIN "customer_transactions" T
    ON U."customer_id" = T."customer_id"
   AND T."txn_date" <= M."CutoffDate"
  GROUP BY M."Month", U."customer_id"
),
AdjustedBalances AS (
  SELECT "Month",
         "customer_id",
         CASE
           WHEN "balance" < 0 OR "balance" IS NULL THEN 0
           ELSE "balance"
         END AS "adj_balance"
  FROM UserBalances
),
TotalBalances AS (
  SELECT "Month",
         SUM("adj_balance") AS "Total_Balance"
  FROM AdjustedBalances
  GROUP BY "Month"
  ORDER BY "Month"
)
SELECT "Month", "Total_Balance"
FROM TotalBalances;