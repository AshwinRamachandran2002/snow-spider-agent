-- For every calendar month calculate the total customer balance 
-- from the previous month (negative running balances floored to zero).
-- The first month only provides the baseline, so it is excluded
-- from the final report.

SELECT
       month_start            AS reporting_month,
       previous_total_balance AS total_balance_previous_month
FROM (
        /* Step-5: pull the prior month’s total balance	*/
        SELECT
               month_start,
               LAG(total_balance) OVER (ORDER BY month_start) AS previous_total_balance
        FROM (
                 /* Step-4: aggregate the zero-floored balances for each month */
                 SELECT
                        month_start,
                        SUM(adjusted_balance) AS total_balance
                 FROM (
                          /* Step-3: zero-floor each customer’s running balance */
                          SELECT
                                 customer_id,
                                 month_start,
                                 CASE
                                     WHEN running_balance < 0 THEN 0
                                     ELSE running_balance
                                 END AS adjusted_balance
                          FROM (
                                   /* Step-2: derive the running balance per customer */
                                   SELECT
                                          customer_id,
                                          month_start,
                                          SUM(net_monthly)
                                          OVER (PARTITION BY customer_id
                                                ORDER BY month_start) AS running_balance
                                   FROM (
                                            /* Step-1: net movement per customer per month */
                                            SELECT
                                                   customer_id,
                                                   substr(txn_date,1,7) || '-01' AS month_start,
                                                   SUM(CASE
                                                           WHEN txn_type = 'deposit'
                                                           THEN  txn_amount
                                                           ELSE -txn_amount
                                                       END) AS net_monthly
                                            FROM   customer_transactions
                                            GROUP  BY customer_id,
                                                      month_start
                                         )
                                )
                       )
                 GROUP BY month_start
              )
     )
WHERE previous_total_balance IS NOT NULL          -- drop the very first month
ORDER BY reporting_month;