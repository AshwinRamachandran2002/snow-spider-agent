-- Task: For each customer and each month in 2020, calculate the net transaction amount by adding all deposit amounts and subtracting all withdrawal amounts that occurred during that specific month. Limit the result to the first 100 rows.

SELECT
    "customer_id",
    TO_CHAR(DATE_TRUNC('MONTH', TO_DATE("txn_date", 'YYYY-MM-DD')), 'YYYY-MM') AS "txn_month",
    SUM(
        CASE
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            ELSE - "txn_amount"
        END
    ) AS "net_transaction_amount"
FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
WHERE
    TO_CHAR(TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY') = '2020'
GROUP BY
    "customer_id",
    "txn_month"
ORDER BY
    "customer_id",
    "txn_month"
LIMIT 100;