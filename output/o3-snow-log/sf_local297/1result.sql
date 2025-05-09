/*------------------------------------------------------------------
Purpose  :   
  1.  Aggregate every customer’s deposits (+) and withdrawals (–) to a
      single net figure for the first day of each month.
  2.  Build cumulative (closing) balances month-by-month.
  3.  Find the most-recent month per customer, work out its growth
      versus the immediately-prior month (special rule when the prior
      balance is 0).
  4.  Return the % of customers whose latest-month growth rate > 5 %.
------------------------------------------------------------------*/
WITH txn AS (   -- sign every transaction
    SELECT
        "customer_id",
        TO_DATE("txn_date",'YYYY-MM-DD')               AS txn_dt,
        CASE
            WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
            ELSE 0
        END                                           AS signed_amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

monthly_net AS (      -- net amount per (cust, month)
    SELECT
        "customer_id",
        DATE_TRUNC('month', txn_dt)   AS month_start,
        SUM(signed_amt)              AS net_amt
    FROM txn
    GROUP BY "customer_id", month_start
),

closing_balances AS ( -- cumulative closing balance per month
    SELECT
        "customer_id",
        month_start,
        SUM(net_amt) OVER (
            PARTITION BY "customer_id"
            ORDER BY     month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                               AS closing_bal
    FROM monthly_net
),

latest_vs_prior AS (  -- isolate latest month & its prior balance
    SELECT
        "customer_id",
        month_start                      AS current_month,
        closing_bal                      AS current_bal,
        LAG(closing_bal) OVER (
            PARTITION BY "customer_id"
            ORDER BY     month_start
        )                                AS prior_bal,
        ROW_NUMBER() OVER (
            PARTITION BY "customer_id"
            ORDER BY     month_start DESC
        )                                AS rn_desc
    FROM closing_balances
),

growth_calc AS (      -- compute growth rate for the latest month only
    SELECT
        "customer_id",
        current_month,
        current_bal,
        COALESCE(prior_bal,0)            AS prior_bal,
        CASE
            WHEN COALESCE(prior_bal,0) = 0
                 THEN current_bal * 100
            ELSE ((current_bal - prior_bal) / prior_bal) * 100
        END                              AS growth_rate_pct
    FROM latest_vs_prior
    WHERE rn_desc = 1                    -- keep most-recent month
)

SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate_pct > 5 THEN 1 ELSE 0 END)
              / COUNT(*)
        ,4
    ) AS pct_customers_growth_gt_5
FROM growth_calc;