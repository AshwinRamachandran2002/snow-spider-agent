/* -----------------------------------------------------------
   Monthly totals of summed customer maximum 30-day average
   balances (excluding each customer’s first active month)
   -----------------------------------------------------------*/
WITH txn AS (  --------------------------------------------------
     /* 1.  Signed amount per transaction                      */
     SELECT
            "customer_id",
            TO_DATE("txn_date",'YYYY-MM-DD')                    AS "txn_dt",
            CASE WHEN "txn_type" = 'deposit'
                 THEN  "txn_amount"
                 ELSE -1 * "txn_amount"
            END                                                 AS "signed_amt"
     FROM   "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
), daily_change AS ( -------------------------------------------
     /* 2.  Net movement per customer per day                  */
     SELECT
            "customer_id",
            "txn_dt",
            SUM("signed_amt")                                   AS "daily_change"
     FROM   txn
     GROUP  BY "customer_id","txn_dt"
), running_bal AS ( --------------------------------------------
     /* 3.  Daily running balance                              */
     SELECT
            "customer_id",
            "txn_dt",
            SUM("daily_change") OVER (PARTITION BY "customer_id"
                                       ORDER BY "txn_dt"
                                       ROWS BETWEEN UNBOUNDED PRECEDING
                                            AND CURRENT ROW)    AS "running_balance"
     FROM   daily_change
), roll_30d AS ( -----------------------------------------------
     /* 4.  30-day rolling average using calendar-day range    */
     SELECT
            "customer_id",
            "txn_dt",
            AVG("running_balance") OVER (
                 PARTITION BY "customer_id"
                 ORDER BY "txn_dt"
                 RANGE BETWEEN INTERVAL '29 day' PRECEDING AND CURRENT ROW
            )                                                   AS "avg_bal_30d",
            MIN("txn_dt") OVER (PARTITION BY "customer_id")     AS "first_txn_dt"
     FROM   running_bal
), roll_30d_valid AS ( -----------------------------------------
     /* 5.  Keep rows at least 30 calendar days after first txn,
            force negatives to zero                            */
     SELECT
            "customer_id",
            "txn_dt",
            GREATEST("avg_bal_30d",0)                           AS "avg_bal_30d_pos"
     FROM   roll_30d
     WHERE  DATEDIFF('day',"first_txn_dt","txn_dt") >= 29
), monthly_max AS ( --------------------------------------------
     /* 6.  Maximum 30-day average balance per customer/month  */
     SELECT
            "customer_id",
            TO_CHAR("txn_dt",'YYYY-MM')                         AS "year_month",
            MAX("avg_bal_30d_pos")                              AS "max_avg_bal_30d"
     FROM   roll_30d_valid
     GROUP  BY "customer_id", TO_CHAR("txn_dt",'YYYY-MM')
), first_month AS ( --------------------------------------------
     /* 7.  Baseline (first) month per customer                */
     SELECT
            "customer_id",
            MIN("year_month")                                   AS "baseline_month"
     FROM   monthly_max
     GROUP  BY "customer_id"
)
-- 8.  Final result                                           
SELECT
       m."year_month",
       SUM(m."max_avg_bal_30d")                                 AS "total_max_avg_bal_30d"
FROM   monthly_max m
JOIN   first_month f
  ON   m."customer_id" = f."customer_id"
WHERE  m."year_month" <> f."baseline_month"
GROUP  BY m."year_month"
ORDER  BY m."year_month";