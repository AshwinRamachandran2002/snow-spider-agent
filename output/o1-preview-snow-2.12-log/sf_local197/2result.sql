WITH total_payments AS (
  SELECT "customer_id", SUM("amount") AS "total_payment"
  FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
  GROUP BY "customer_id"
  ORDER BY "total_payment" DESC NULLS LAST
  LIMIT 10
),
payment_differences AS (
  SELECT
    p."customer_id",
    SUBSTRING(p."payment_date", 1, 7) AS "year_month",
    MAX(p."amount") - MIN(p."amount") AS "payment_difference"
  FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
  WHERE p."customer_id" IN (SELECT "customer_id" FROM total_payments)
  GROUP BY p."customer_id", SUBSTRING(p."payment_date", 1, 7)
),
max_payment_differences AS (
  SELECT "customer_id", MAX("payment_difference") AS "max_payment_difference"
  FROM payment_differences
  GROUP BY "customer_id"
),
max_customer AS (
  SELECT "customer_id", "max_payment_difference"
  FROM max_payment_differences
  ORDER BY "max_payment_difference" DESC NULLS LAST
  LIMIT 1
)
SELECT
  c."first_name" || ' ' || c."last_name" AS "Customer_Name",
  ROUND(m."max_payment_difference", 4) AS "Highest_Payment_Difference"
FROM max_customer m
JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER" c
  ON c."customer_id" = m."customer_id";