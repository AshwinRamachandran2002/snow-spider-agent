-- Task: Calculate the net monthly balance changes for each customer based on their transactions. Limit the output to 10 rows.
SELECT
    "customer_id",
    SUBSTR("txn_date", 1, 7) AS "month",
    ROUND(SUM(
        CASE
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
            ELSE 0
        END
    ), 4) AS "monthly_change"
FROM "customer_transactions"
GROUP BY "customer_id", "month"
LIMIT 10;