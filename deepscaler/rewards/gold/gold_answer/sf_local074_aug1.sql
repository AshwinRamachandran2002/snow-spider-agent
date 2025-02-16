-- Task: For each customer, calculate the net transaction amount per month (positive or negative), for the months in which transactions occurred.

SELECT
    "customer_id",
    TO_VARCHAR(DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD')), 'YYYY-MM') AS "month",
    SUM(
        CASE 
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
            ELSE 0
        END
    ) AS "monthly_change"
FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
GROUP BY "customer_id", DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))
ORDER BY "customer_id", "month";