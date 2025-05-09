WITH monthly AS (         -- 1. net deposits-withdrawals by month
  SELECT
      customer_id,
      strftime('%Y-%m-01', txn_date)          AS month_start,
      SUM(CASE
              WHEN txn_type = 'deposit'    THEN  txn_amount
              WHEN txn_type = 'withdrawal' THEN -txn_amount
          END)                               AS monthly_net
  FROM customer_transactions
  GROUP BY customer_id,
           strftime('%Y-%m-01', txn_date)
),

closing AS (              -- 2. running closing balance per customer
  SELECT
      customer_id,
      month_start,
      SUM(monthly_net) OVER (
          PARTITION BY customer_id
          ORDER BY     month_start
      ) AS closing_balance
  FROM monthly
),

growth AS (               -- 3. growth rate for the latest month
  SELECT
      c_cur.customer_id,
      CASE
        WHEN c_prev.closing_balance IS NULL
             OR c_prev.closing_balance = 0
        THEN c_cur.closing_balance * 100.0
        ELSE (c_cur.closing_balance - c_prev.closing_balance)
               * 100.0 / ABS(c_prev.closing_balance)
      END AS growth_rate
  FROM closing AS c_cur
  LEFT JOIN closing AS c_prev
         ON c_prev.customer_id = c_cur.customer_id
        AND c_prev.month_start = (
             SELECT MAX(month_start)
             FROM closing
             WHERE customer_id = c_cur.customer_id
               AND month_start < c_cur.month_start
         )
  WHERE c_cur.month_start = (
        SELECT MAX(month_start)
        FROM closing
        WHERE customer_id = c_cur.customer_id
      )
)

-- 4. percentage of customers whose latest growth > 5 %
SELECT
  ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
              / COUNT(*)
      , 4)  AS pct_customers_gt_5_percent
FROM growth;