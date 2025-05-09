WITH txn AS (   /* 1. cast dates and sign the amounts */
    SELECT 
        "customer_id",
        TO_DATE("txn_date",'YYYY-MM-DD')           AS txn_dt,
        CASE 
            WHEN LOWER("txn_type") = 'deposit'     THEN "txn_amount"
            ELSE -1 * "txn_amount"
        END                                        AS signed_amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
), monthly_net AS (   /* 2. net amount for the first day of each month */
    SELECT
        "customer_id",
        DATE_TRUNC('month', txn_dt)                AS month_start,
        SUM(signed_amt)                            AS net_amount
    FROM txn
    GROUP BY "customer_id", DATE_TRUNC('month', txn_dt)
), closing_bal AS (   /* 3. cumulative closing balance per month */
    SELECT
        "customer_id",
        month_start,
        net_amount,
        SUM(net_amount) OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start
        )                                          AS closing_balance
    FROM monthly_net
), latest_bal AS (   /* 4. bring in previous month’s balance */
    SELECT
        "customer_id",
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start
        )                                          AS prev_balance
    FROM closing_bal
), latest_growth AS (  /* 5. compute growth rate & flag most-recent month */
    SELECT
        "customer_id",
        month_start,
        closing_balance,
        prev_balance,
        CASE 
            WHEN prev_balance IS NULL OR prev_balance = 0 
                 THEN closing_balance * 100            /* special rule */
            ELSE ( (closing_balance - prev_balance) / prev_balance ) * 100
        END                                          AS growth_rate,
        ROW_NUMBER() OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start DESC
        )                                           AS rn                /* rn = 1 → most recent */
    FROM latest_bal
)
SELECT 
    ROUND(
        100.0 * SUM( CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END ) 
        / COUNT(*)
    , 2)                                            AS pct_customers_growth_gt_5
FROM latest_growth
WHERE rn = 1;       /* only evaluate each customer’s most-recent month */