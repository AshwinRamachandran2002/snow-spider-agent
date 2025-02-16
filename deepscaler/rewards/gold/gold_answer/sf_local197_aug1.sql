-- Task: List the names of our top 10 customers by total payment amount, including their total amounts rounded to two decimal places.
WITH top_customers AS (
    SELECT "customer_id", SUM("amount") AS "total_amount"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT"
    GROUP BY "customer_id"
    ORDER BY "total_amount" DESC
    LIMIT 10
),
customer_info AS (
    SELECT tc."customer_id", c."first_name" || ' ' || c."last_name" AS "Customer_Name", ROUND(tc."total_amount", 2) AS "Total_Payment_Amount"
    FROM top_customers tc
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."CUSTOMER" c ON tc."customer_id" = c."customer_id"
)
SELECT "Customer_Name", "Total_Payment_Amount"
FROM customer_info
ORDER BY "Total_Payment_Amount" DESC;