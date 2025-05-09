WITH monthly_balances AS (
    SELECT
        "customer_id",
        TO_CHAR(TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY-MM') AS "year_month",
        SUM(
            CASE
                WHEN "txn_type" = 'deposit' THEN "txn_amount"
                WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ) AS "net_transaction_amount"
    FROM
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    WHERE
        EXTRACT(YEAR FROM TO_DATE("txn_date", 'YYYY-MM-DD')) = 2020
    GROUP BY
        "customer_id",
        TO_CHAR(TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY-MM')
),
positive_counts AS (
    SELECT
        "year_month",
        COUNT(DISTINCT CASE WHEN "net_transaction_amount" > 0 THEN "customer_id" END) AS "positive_balance_customers"
    FROM
        monthly_balances
    GROUP BY
        "year_month"
),
ranked_positive_counts AS (
    SELECT
        "year_month",
        "positive_balance_customers",
        RANK() OVER (ORDER BY "positive_balance_customers" DESC NULLS LAST) AS "rank_desc",
        RANK() OVER (ORDER BY "positive_balance_customers" ASC NULLS LAST) AS "rank_asc"
    FROM
        positive_counts
),
target_months AS (
    SELECT "year_month" FROM ranked_positive_counts WHERE "rank_desc" = 1
    UNION
    SELECT "year_month" FROM ranked_positive_counts WHERE "rank_asc" = 1
),
averages AS (
    SELECT
        "year_month",
        AVG("net_transaction_amount") AS "average_balance"
    FROM
        monthly_balances
    WHERE
        "year_month" IN (SELECT "year_month" FROM target_months)
        AND "net_transaction_amount" <> 0
    GROUP BY
        "year_month"
)
SELECT
    ROUND(MAX("average_balance") - MIN("average_balance"), 4) AS "Difference_between_averages"
FROM
    averages;