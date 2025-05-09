WITH txn AS (
    /* 1.  Sign every transaction (+ for deposits, – for withdrawals)
          and move it to the first day of its month                        */
    SELECT
        customer_id,
        date(txn_date,'start of month')        AS month_start,
        CASE WHEN txn_type = 'deposit'     THEN  txn_amount
             WHEN txn_type = 'withdrawal'  THEN -txn_amount
             ELSE 0 END                     AS signed_amt
    FROM   customer_transactions
),

monthly_net AS (
    /* 2.  Net amount per customer‑month                                     */
    SELECT
        customer_id,
        month_start,
        SUM(signed_amt)                      AS net_amt
    FROM   txn
    GROUP  BY customer_id, month_start
),

closing_bal AS (
    /* 3.  Cumulative (closing) balance per month                            */
    SELECT
        customer_id,
        month_start,
        net_amt,
        SUM(net_amt) OVER (PARTITION BY customer_id
                           ORDER BY month_start) AS closing_balance
    FROM   monthly_net
),

growth_calc AS (
    /* 4.  Bring in previous month’s balance and compute growth rate         */
    SELECT
        customer_id,
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY customer_id
                                   ORDER BY month_start) AS prev_balance
    FROM   closing_bal
),

most_recent AS (
    /* 5.  Keep only each customer’s most recent month                       */
    SELECT
        customer_id,
        /* If previous balance is NULL treat it as 0 (no prior month)        */
        COALESCE(prev_balance,0)                         AS prev_balance,
        closing_balance,
        CASE
             WHEN COALESCE(prev_balance,0) = 0
                  THEN closing_balance * 100.0
             ELSE (closing_balance - prev_balance)
                  * 100.0 / prev_balance
        END                                             AS growth_rate,
        ROW_NUMBER() OVER (PARTITION BY customer_id
                           ORDER BY month_start DESC)   AS rn
    FROM   growth_calc
)

SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
        / COUNT(*)
    ,4) AS pct_customers_growth_gt_5
FROM   most_recent
WHERE  rn = 1;