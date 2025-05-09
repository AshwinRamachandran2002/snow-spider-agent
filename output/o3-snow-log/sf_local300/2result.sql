/*-----------------------------------------------------------
Build daily running balances (no negatives), pick monthly
max per customer, then sum across customers per month.
-----------------------------------------------------------*/

WITH ------------------------------------------------------- 
/* 1.  Daily net movement per customer & transaction date   */
daily_net AS (
    SELECT
        "customer_id",
        TO_DATE("txn_date")                    AS "txn_dt",
        SUM(
            CASE 
                WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                ELSE                               - "txn_amount"
            END
        )                                     AS "net_amt"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date")
), --------------------------------------------------------
/* 2.  Determine each customer’s overall date span          */
cust_span AS (
    SELECT
        "customer_id",
        MIN("txn_dt")  AS "start_dt",
        MAX("txn_dt")  AS "end_dt"
    FROM daily_net
    GROUP BY "customer_id"
), --------------------------------------------------------
/* 3.  Pre-build a constant set of integers (0 … 9,999)     */
numbers AS (
    SELECT seq4() AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 10000))   -- 27+ years coverage
), --------------------------------------------------------
/* 4.  Generate a complete calendar spine per customer      */
spine AS (
    SELECT
        c."customer_id",
        DATEADD(day, n.n, c."start_dt") AS "txn_dt"
    FROM cust_span  c
    JOIN numbers    n
      ON n.n <= DATEDIFF(day, c."start_dt", c."end_dt")
), --------------------------------------------------------
/* 5.  Attach daily net amounts (0 if no activity)          */
daily_bal AS (
    SELECT
        s."customer_id",
        s."txn_dt",
        COALESCE(d."net_amt", 0) AS "net_amt"
    FROM spine s
    LEFT JOIN daily_net d
           ON  d."customer_id" = s."customer_id"
           AND d."txn_dt"      = s."txn_dt"
), --------------------------------------------------------
/* 6.  Running balance & clip negatives to zero             */
clipped_bal AS (
    SELECT
        "customer_id",
        "txn_dt",
        CASE 
            WHEN running_bal < 0 THEN 0 
            ELSE running_bal 
        END AS "daily_balance"
    FROM (
        SELECT
            "customer_id",
            "txn_dt",
            SUM("net_amt") OVER (
                PARTITION BY "customer_id"
                ORDER BY     "txn_dt"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_bal
        FROM daily_bal
    )
), --------------------------------------------------------
/* 7.  Customer-level maximum balance per calendar month    */
cust_month_max AS (
    SELECT
        "customer_id",
        TO_CHAR("txn_dt", 'YYYY-MM') AS "month_tag",
        MAX("daily_balance")         AS "max_daily_balance"
    FROM clipped_bal
    GROUP BY "customer_id", TO_CHAR("txn_dt", 'YYYY-MM')
) ---------------------------------------------------------
/* 8.  Sum those maxima across all customers per month      */
SELECT
    "month_tag",
    SUM("max_daily_balance") AS "total_monthly_max_balance"
FROM cust_month_max
GROUP BY "month_tag"
ORDER BY "month_tag";