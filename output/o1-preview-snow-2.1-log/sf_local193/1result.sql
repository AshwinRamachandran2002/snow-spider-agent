WITH customer_totals AS (
  SELECT 
    "customer_id",
    MIN(TO_TIMESTAMP("payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS initial_purchase_date,
    SUM("amount") AS total_ltv
  FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
  GROUP BY "customer_id"
  HAVING SUM("amount") > 0
),
customer_amounts AS (
  SELECT 
    p."customer_id",
    SUM(CASE WHEN TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3') >= c.initial_purchase_date
           AND TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3') < c.initial_purchase_date + INTERVAL '7 DAYS'
         THEN p."amount" ELSE 0 END) AS amount_7_days,
    SUM(CASE WHEN TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3') >= c.initial_purchase_date
           AND TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3') < c.initial_purchase_date + INTERVAL '30 DAYS'
         THEN p."amount" ELSE 0 END) AS amount_30_days
  FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
  JOIN customer_totals c ON p."customer_id" = c."customer_id"
  GROUP BY p."customer_id"
),
customer_percentages AS (
  SELECT
    c."customer_id",
    c.total_ltv,
    ca.amount_7_days,
    ca.amount_30_days,
    (ca.amount_7_days / c.total_ltv)*100 AS percentage_7_days,
    (ca.amount_30_days / c.total_ltv)*100 AS percentage_30_days
  FROM customer_totals c
  JOIN customer_amounts ca ON c."customer_id" = ca."customer_id"
)
SELECT
  ROUND(AVG(total_ltv), 4) AS "Average_LTV",
  CONCAT(ROUND(AVG(percentage_7_days), 4), '%') AS "Percentage_LTV_in_first_7_days",
  CONCAT(ROUND(AVG(percentage_30_days), 4), '%') AS "Percentage_LTV_in_first_30_days"
FROM customer_percentages;