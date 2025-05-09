/* ----------------------------------------------------------
   Monthly portfolio totals of customers’ maximum 30-day
   average balances (baseline month excluded)
-----------------------------------------------------------*/
WITH daily_net AS (                          -- daily net movement
    SELECT
        "customer_id",
        TO_DATE("txn_date")                                    AS "txn_dt",
        SUM( CASE WHEN "txn_type" = 'deposit'
                  THEN  "txn_amount"
                  ELSE -1 * "txn_amount"
             END )                                             AS "net_amt"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date")
), running_bal AS (                         -- running balance
    SELECT
        "customer_id",
        "txn_dt",
        SUM("net_amt")
            OVER (PARTITION BY "customer_id"
                  ORDER BY "txn_dt"
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "running_balance"
    FROM daily_net
), bal30 AS (                               -- 30-day rolling avg (negatives floored to 0)
    SELECT
        "customer_id",
        "txn_dt",
        GREATEST(
            AVG("running_balance")
                OVER (PARTITION BY "customer_id"
                      ORDER BY "txn_dt"
                      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW),
            0
        )                                                     AS "avg_bal_30d"
    FROM running_bal
), cust_month_max AS (                       -- maximum 30-day average per month/customer
    SELECT
        "customer_id",
        TO_CHAR("txn_dt", 'YYYY-MM')          AS "cal_month",
        MAX("avg_bal_30d")                    AS "max_30d_avg_bal"
    FROM bal30
    GROUP BY "customer_id", TO_CHAR("txn_dt", 'YYYY-MM')
), baseline AS (                             -- first (baseline) month per customer
    SELECT
        "customer_id",
        MIN(TO_CHAR(TO_DATE("txn_date"), 'YYYY-MM')) AS "first_month"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"
), filtered AS (                             -- exclude baseline month
    SELECT  c.*
    FROM    cust_month_max c
    JOIN    baseline      b  ON c."customer_id" = b."customer_id"
    WHERE   c."cal_month" <> b."first_month"
)
SELECT
    "cal_month",
    SUM("max_30d_avg_bal")  AS "sum_max_30d_avg_bal"
FROM filtered
GROUP BY "cal_month"
ORDER BY "cal_month";