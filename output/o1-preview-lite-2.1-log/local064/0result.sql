WITH cte_transactions AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "txn_date") AS "month",
        SUM("txn_amount") AS "monthly_amount"
    FROM "customer_transactions"
    WHERE strftime('%Y', "txn_date") = '2020'
    GROUP BY "customer_id", "month"
),
cte_cumulative AS (
    SELECT
        "customer_id",
        "month",
        SUM("monthly_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY "month"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_balance"
    FROM cte_transactions
),
cte_month_stats AS (
    SELECT
        "month",
        COUNT(CASE WHEN "cumulative_balance" > 0 THEN 1 END) AS "positive_customers",
        AVG(CASE WHEN "cumulative_balance" > 0 THEN "cumulative_balance" END) AS "average_balance"
    FROM cte_cumulative
    GROUP BY "month"
),
cte_ranked_months AS (
    SELECT
        "month",
        "positive_customers",
        "average_balance",
        ROW_NUMBER() OVER (ORDER BY "positive_customers" DESC, "month" ASC) AS "most_rank",
        ROW_NUMBER() OVER (ORDER BY "positive_customers" ASC, "month" DESC) AS "fewest_rank"
    FROM cte_month_stats
),
cte_most_month AS (
    SELECT * FROM cte_ranked_months WHERE "most_rank" = 1
),
cte_fewest_month AS (
    SELECT * FROM cte_ranked_months WHERE "fewest_rank" = 1
)
SELECT
    ABS(most."average_balance" - fewest."average_balance") AS "difference_in_average_month_end_balance"
FROM
    cte_most_month AS most,
    cte_fewest_month AS fewest;