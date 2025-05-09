/*---------------------------------------------------------------
  1.  Sign every transaction (+ for deposits, – for withdrawals)
  2.  Create a month-start bucket and work out each month’s net
  3.  Cumulatively sum the nets to get a monthly closing balance
  4.  Derive the growth rate for every month
  5.  Keep the most-recent month per customer and flag growth > 5 %
  6.  Return the percentage of customers whose most-recent month
      shows a growth rate larger than 5 %
----------------------------------------------------------------*/
WITH txns AS (   -- sign every transaction
    SELECT
        "customer_id",
        TO_DATE("txn_date")                                                   AS txn_date,
        CASE 
            WHEN LOWER("txn_type") = 'deposit'      THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'   THEN - "txn_amount"
            ELSE - "txn_amount"                     -- treat anything not 'deposit' as withdrawal
        END                                                                 AS signed_amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
monthly_net AS (  -- net amount per customer & month (first day of month)
    SELECT
        "customer_id",
        DATE_TRUNC('month', txn_date)                                         AS month_start,
        SUM(signed_amt)                                                       AS monthly_net
    FROM txns
    GROUP BY "customer_id", DATE_TRUNC('month', txn_date)
),
closing_bal AS (  -- cumulative closing balance
    SELECT
        "customer_id",
        month_start,
        monthly_net,
        SUM(monthly_net) OVER (PARTITION BY "customer_id" 
                               ORDER BY month_start)                         AS closing_balance
    FROM monthly_net
),
growth_calc AS (  -- growth versus prior month
    SELECT
        "customer_id",
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY "customer_id" 
                                   ORDER BY month_start)                     AS prev_balance
    FROM closing_bal
),
most_recent AS (  -- retain most-recent month per customer
    SELECT
        "customer_id",
        month_start,
        closing_balance,
        prev_balance,
        CASE
            WHEN prev_balance IS NULL            THEN NULL                     -- no prior month
            WHEN prev_balance = 0                THEN closing_balance * 100
            ELSE (closing_balance - prev_balance) / prev_balance * 100
        END                                                                   AS growth_rate,
        ROW_NUMBER() OVER (PARTITION BY "customer_id" 
                           ORDER BY month_start DESC)                        AS rn
    FROM growth_calc
)
SELECT
    ROUND(
        SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) * 100.0
        / COUNT(DISTINCT "customer_id"), 
        4
    )  AS pct_customers_growth_gt_5
FROM most_recent
WHERE rn = 1;