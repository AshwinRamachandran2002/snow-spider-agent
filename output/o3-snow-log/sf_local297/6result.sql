/*-------------------------------------------------------------
  1.  Sign every transaction (deposit = +, withdrawal = -)
  2.  Aggregate these signed values to a monthly net amount
      (keyed to the first day of every month)
  3.  Build a running (cumulative) closing balance per customer
  4.  For every customer keep only the most-recent month,
      work out that month’s growth rate vs the immediately
      prior month (special rule when prior balance = 0)
  5.  Return the % of customers whose latest-month growth
      is greater than 5 %
-------------------------------------------------------------*/
WITH signed_txn AS (
    SELECT
        "customer_id",
        TO_DATE("txn_date")                                       AS txn_dte,
        CASE
            WHEN LOWER("txn_type") = 'deposit'    THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal' THEN - "txn_amount"
            ELSE 0
        END                                                      AS signed_amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
monthly_net AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', txn_dte)                              AS month_start,
        SUM(signed_amt)                                           AS net_amt
    FROM signed_txn
    GROUP BY "customer_id", month_start
),
running_balance AS (
    SELECT
        "customer_id",
        month_start,
        net_amt,
        /* cumulative closing balance */
        SUM(net_amt) OVER (PARTITION BY "customer_id"
                           ORDER BY month_start)                 AS closing_bal
    FROM monthly_net
),
balance_with_lag AS (
    SELECT
        "customer_id",
        month_start,
        closing_bal,
        LAG(closing_bal) OVER (PARTITION BY "customer_id"
                               ORDER BY month_start)             AS prev_bal
    FROM running_balance
),
latest_month AS (
    SELECT
        "customer_id",
        month_start,
        closing_bal,
        COALESCE(prev_bal,0)                                     AS prev_bal,
        CASE
            WHEN COALESCE(prev_bal,0) = 0
                 THEN closing_bal * 100
            ELSE ( (closing_bal - prev_bal) / prev_bal ) * 100
        END                                                      AS growth_rate
    FROM balance_with_lag
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "customer_id"
                               ORDER BY month_start DESC) = 1
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
        / COUNT(*)
    , 4)                                                         AS pct_customers_growth_gt_5
FROM latest_month;