/* -----------------------------------------------------------
   For every calendar month, return the **total balance that
   existed on the 1-st day of that month** (i.e. the cumulative
   balance at the end of the previous month).  
   Any negative running balance is floored to 0, and the very
   first month is used only to seed the calculation and therefore
   is excluded from the final output.
------------------------------------------------------------*/

WITH month_net AS (   -- 1. net cash-flow per month
    SELECT
        TO_CHAR( TO_DATE("txn_date",'YYYY-MM-DD'), 'YYYY-MM')                   AS year_month,
        SUM( CASE
                 WHEN LOWER("txn_type") LIKE '%deposit%'   THEN  "txn_amount"
                 WHEN LOWER("txn_type") LIKE '%withdraw%'  THEN -1*"txn_amount"
                 ELSE 0
            END )                                                              AS net_amount
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY TO_CHAR( TO_DATE("txn_date",'YYYY-MM-DD'), 'YYYY-MM')
),

month_cumulative AS ( -- 2. running book balance, negatives floored to 0
    SELECT
        year_month,
        GREATEST(
            SUM(net_amount)
              OVER (ORDER BY year_month
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
            0)                                                                 AS cumulative_balance
    FROM month_net
),

previous_month_balance AS ( -- 3. balance as of the 1-st (lag of cumulative)
    SELECT
        year_month,
        LAG(cumulative_balance) OVER (ORDER BY year_month)                     AS prev_month_balance
    FROM month_cumulative
)

SELECT
    year_month,
    prev_month_balance                                                         AS total_balance_previous_month
FROM previous_month_balance
WHERE prev_month_balance IS NOT NULL                -- drops the very first month
ORDER BY year_month ASC;