WITH monthly_nets AS (
    SELECT
        customer_id,
        substr(txn_date, 1, 7) || '-01'                         AS month_start,
        SUM(
            CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END
        )                                                      AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, month_start
),
running_balance AS (
    SELECT
        customer_id,
        month_start,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        )                                                      AS closing_balance
    FROM monthly_nets
),
ranked_months AS (
    SELECT
        customer_id,
        month_start,
        closing_balance,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY month_start DESC
        )                                                      AS rn
    FROM running_balance
),
most_recent AS (
    SELECT customer_id, closing_balance
    FROM ranked_months
    WHERE rn = 1
),
prior_month AS (
    SELECT customer_id, closing_balance
    FROM ranked_months
    WHERE rn = 2
),
growth_calc AS (
    SELECT
        mr.customer_id,
        CASE
            WHEN pm.closing_balance IS NULL
                OR pm.closing_balance = 0
            THEN mr.closing_balance * 100.0
            ELSE (mr.closing_balance - pm.closing_balance)
                 * 100.0 / ABS(pm.closing_balance)
        END                                                   AS growth_rate
    FROM most_recent mr
    LEFT JOIN prior_month pm
        ON mr.customer_id = pm.customer_id
)
SELECT
    printf('%.4f',
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
              / COUNT(*)
    )                                                         AS percentage_of_customers_with_growth_rate_gt_5
FROM growth_calc;