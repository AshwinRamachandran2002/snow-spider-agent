WITH "TopCustomers" AS (
    SELECT "customer_id", SUM("amount") AS "total_amount"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT"
    GROUP BY "customer_id"
    ORDER BY "total_amount" DESC
    LIMIT 10
),
"PaymentDifferences" AS (
    SELECT "customer_id",
           EXTRACT(YEAR FROM TO_TIMESTAMP("payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS "year",
           EXTRACT(MONTH FROM TO_TIMESTAMP("payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS "month",
           MAX("amount") - MIN("amount") AS "payment_difference"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT"
    GROUP BY "customer_id", "year", "month"
),
"CustomerMaxDifferences" AS (
    SELECT "customer_id", MAX("payment_difference") AS "max_payment_difference"
    FROM "PaymentDifferences"
    WHERE "customer_id" IN (SELECT "customer_id" FROM "TopCustomers")
    GROUP BY "customer_id"
)
SELECT C."first_name" || ' ' || C."last_name" AS "Customer_Name",
       ROUND(CMD."max_payment_difference", 4) AS "Highest_Payment_Difference"
FROM "CustomerMaxDifferences" CMD
JOIN SQLITE_SAKILA.SQLITE_SAKILA."CUSTOMER" C ON CMD."customer_id" = C."customer_id"
ORDER BY CMD."max_payment_difference" DESC NULLS LAST
LIMIT 1;