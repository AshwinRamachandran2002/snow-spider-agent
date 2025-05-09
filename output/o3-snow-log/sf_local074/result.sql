/*==================================================================
   Monthly closing balances (including months with no activity)
==================================================================*/
WITH date_bounds AS (                -- overall first & last txn month
    SELECT  DATE_TRUNC('month', MIN(TO_DATE("txn_date", 'YYYY-MM-DD'))) AS min_month ,
            DATE_TRUNC('month', MAX(TO_DATE("txn_date", 'YYYY-MM-DD'))) AS max_month
    FROM    BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

month_series AS (                    -- list of every month in the range
    SELECT  DATEADD( month
                   , SEQ4()                              /* 0,1,2 …      */
                   , db.min_month )      AS month_start
    FROM    date_bounds db
    JOIN    TABLE(GENERATOR(ROWCOUNT => 1200))          /* ~100-yrs cap */
            ON 1 = 1
    WHERE   DATEADD( month , SEQ4() , db.min_month ) <= db.max_month
),

customers AS (                       -- every distinct customer
    SELECT DISTINCT "customer_id"
    FROM   BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

cust_months AS (                     -- Cartesian product customer × month
    SELECT  c."customer_id",
            m.month_start
    FROM    customers   c
    CROSS   JOIN month_series m
),

monthly_activity AS (                -- net monthly movement per customer
    SELECT  "customer_id",
            DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))   AS month_start,
            SUM(
                CASE LOWER("txn_type")
                     WHEN 'deposit'    THEN  "txn_amount"
                     WHEN 'withdrawal' THEN -1 * "txn_amount"
                     ELSE 0
                END
            ) AS net_monthly_change
    FROM    BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP   BY "customer_id", month_start
),

activity_filled AS (                 -- insert zeros where no activity
    SELECT  cm."customer_id",
            cm.month_start,
            COALESCE(ma.net_monthly_change, 0) AS net_monthly_change
    FROM    cust_months        cm
    LEFT    JOIN monthly_activity ma
           ON cm."customer_id" = ma."customer_id"
          AND cm.month_start   = ma.month_start
),

running_balances AS (                -- cumulative closing balance
    SELECT  "customer_id",
            month_start,
            net_monthly_change,
            SUM(net_monthly_change) OVER (PARTITION BY "customer_id"
                                           ORDER BY month_start
                                           ROWS BETWEEN UNBOUNDED PRECEDING
                                                    AND CURRENT ROW) AS closing_balance
    FROM    activity_filled
)

SELECT  "customer_id",
        TO_CHAR(month_start, 'YYYY-MM')  AS "month_year",
        net_monthly_change               AS "monthly_change",
        closing_balance                  AS "cumulative_balance"
FROM    running_balances
ORDER BY "customer_id", month_start;