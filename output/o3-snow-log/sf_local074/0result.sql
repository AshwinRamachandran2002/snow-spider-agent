/*--------------------------------------------------------------
  Monthly closing balances, changes and cumulative balances
  for every customer – months with no activity are still shown
--------------------------------------------------------------*/
WITH txn AS (   /* 1.  signed daily transactions               */
    SELECT
        "customer_id",
        TO_DATE("txn_date")                             AS txn_dt,
        CASE                                            /* deposits = +, withdrawals = - */
            WHEN LOWER("txn_type") = 'deposit' THEN  "txn_amount"
            ELSE                                         -"txn_amount"
        END                                             AS amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

/* 2. date range for the whole data set (truncated to month)   */
date_limits AS (
    SELECT
        DATE_TRUNC('month', MIN(txn_dt)) AS min_month ,
        DATE_TRUNC('month', MAX(txn_dt)) AS max_month
    FROM txn
),

/* 3. month calendar covering the full period                  */
calendar_months AS (
    SELECT
        DATEADD(
            month
          , SEQ4()
          , (SELECT min_month FROM date_limits)
        )                   AS month_start
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1200)   -- large enough upper-bound
    )
    WHERE month_start <= (SELECT max_month FROM date_limits)
),

/* 4. every customer × every calendar month (even if idle)     */
customer_months AS (
    SELECT  c."customer_id", m.month_start
    FROM   (SELECT DISTINCT "customer_id" FROM txn)      c
    CROSS  JOIN calendar_months                          m
),

/* 5. monthly net movement per customer                       */
monthly_moves AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', txn_dt)   AS month_start,
        SUM(amount)                   AS monthly_change
    FROM txn
    GROUP BY "customer_id", month_start
),

/* 6. bring together full month grid + actual moves            */
filled_moves AS (
    SELECT
        cm."customer_id",
        cm.month_start,
        COALESCE(mv.monthly_change, 0) AS monthly_change
    FROM customer_months   cm
    LEFT JOIN monthly_moves mv
           ON  cm."customer_id" = mv."customer_id"
           AND cm.month_start   = mv.month_start
),

/* 7. cumulative running balance (closing balance)             */
balances AS (
    SELECT
        "customer_id",
        month_start,
        monthly_change,
        SUM(monthly_change) OVER (
            PARTITION BY "customer_id"
            ORDER BY       month_start
        ) AS closing_balance
    FROM filled_moves
)

/* 8. final presentation                                       */
SELECT
    "customer_id"                                 AS customer_id,
    TO_CHAR(month_start, 'YYYY-MM')               AS month,
    monthly_change                                AS monthly_net_change,
    closing_balance                               AS month_end_balance
FROM balances
ORDER BY
    "customer_id",
    month_start;