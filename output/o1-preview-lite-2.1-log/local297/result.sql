SELECT
    ROUND((CAST(SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100, 4) AS "Percentage_of_users_with_growth_rate_over_5"
FROM (
    SELECT
        "customer_id",
        COALESCE(balance_prev, 0) AS balance_prev,
        COALESCE(balance_curr, 0) AS balance_curr,
        CASE
            WHEN COALESCE(balance_prev, 0) = 0 AND COALESCE(balance_curr, 0) = 0 THEN 0
            WHEN COALESCE(balance_prev, 0) = 0 THEN balance_curr * 100
            ELSE ((balance_curr - balance_prev) / balance_prev) * 100
        END AS growth_rate
    FROM (
        SELECT
            "customer_id",
            SUM(CASE WHEN date("txn_date") < '2020-03-01' THEN
                        CASE WHEN "txn_type" = 'deposit' THEN "txn_amount"
                             WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                             ELSE 0 END
                     ELSE 0 END) AS balance_prev,
            SUM(CASE WHEN date("txn_date") < '2020-04-01' THEN
                        CASE WHEN "txn_type" = 'deposit' THEN "txn_amount"
                             WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                             ELSE 0 END
                     ELSE 0 END) AS balance_curr
        FROM "customer_transactions"
        GROUP BY "customer_id"
    ) AS balances
) AS growths