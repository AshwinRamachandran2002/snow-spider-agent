/* monthly closing balance, including months with no activity */
WITH RECURSIVE
-----------------------------------------------------------------
/* 1. find each customer’s first and last transaction month     */
customer_range AS (
    SELECT
        "customer_id",
        date(substr(MIN("txn_date"),1,7) || '-01')  AS start_month,
        date(substr(MAX("txn_date"),1,7) || '-01')  AS end_month
    FROM   "customer_transactions"
    GROUP  BY "customer_id"
),
-----------------------------------------------------------------
/* 2. build a month‑by‑month calendar for every customer        */
months(customer_id, month_start) AS (
    /* anchor row */
    SELECT customer_id, start_month
    FROM   customer_range
    UNION ALL
    /* add one month until the customer’s end_month is reached  */
    SELECT  m.customer_id,
            date(m.month_start,'+1 month')
    FROM    months m
    JOIN    customer_range cr
           ON cr.customer_id = m.customer_id
    WHERE   date(m.month_start,'+1 month') <= cr.end_month
),
-----------------------------------------------------------------
/* 3. net change (+deposit, –withdrawal) per customer per month */
monthly_change AS (
    SELECT
        "customer_id",
        date(substr("txn_date",1,7) || '-01')     AS month_start,
        SUM( CASE
                WHEN lower("txn_type") = 'deposit'     THEN  txn_amount
                WHEN lower("txn_type") = 'withdrawal'  THEN -txn_amount
                ELSE 0
             END )                               AS monthly_change
    FROM   "customer_transactions"
    GROUP  BY "customer_id", month_start
)
-----------------------------------------------------------------
/* 4. merge calendar with changes and compute running balance   */
SELECT
    m.customer_id,
    strftime('%Y-%m', m.month_start)                               AS month_year,
    date(m.month_start,'start of month','+1 month','-1 day')       AS month_end_date,
    COALESCE(mc.monthly_change,0)                                  AS monthly_change,
    SUM(COALESCE(mc.monthly_change,0))
        OVER (PARTITION BY m.customer_id
              ORDER BY m.month_start)                              AS closing_balance
FROM        months           AS m
LEFT JOIN   monthly_change   AS mc
       ON   m.customer_id = mc.customer_id
      AND   m.month_start  = mc.month_start
ORDER BY    m.customer_id, m.month_start;