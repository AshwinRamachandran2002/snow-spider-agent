/* --------------------------------------------------------------
   Calculate company-wide monthly totals of customers’ highest
   daily balances, where negative balances are floored to zero.
---------------------------------------------------------------- */
WITH txn_span AS (                           -- 1) earliest & latest dates per customer
    SELECT  "customer_id",
            MIN( TO_DATE("txn_date") ) AS "min_dt",
            MAX( TO_DATE("txn_date") ) AS "max_dt"
    FROM    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"
),
calendar AS (                                -- 2) generate every calendar day in span
    SELECT  s."customer_id",
            DATEADD(day, seq4(), s."min_dt") AS "dt"
    FROM    txn_span  s,
            TABLE(GENERATOR(ROWCOUNT => 4000))     -- sufficient for ~11 years
    WHERE   DATEADD(day, seq4(), s."min_dt") <= s."max_dt"
),
daily_delta AS (                             -- 3) net movement (deposit – withdrawal) per customer-day
    SELECT  "customer_id",
            TO_DATE("txn_date")                      AS "txn_dt",
            SUM(
                CASE
                    WHEN LOWER("txn_type") = 'deposit'    THEN  "txn_amount"
                    WHEN LOWER("txn_type") = 'withdrawal' THEN - "txn_amount"
                    ELSE 0
                END
            ) AS "daily_delta"
    FROM    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date")
),
balances AS (                                -- 4) running balance with negatives floored to 0
    SELECT  c."customer_id",
            c."dt",
            GREATEST(
                0,
                SUM( COALESCE(d."daily_delta", 0) )
                OVER (PARTITION BY c."customer_id"
                      ORDER BY      c."dt"
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            ) AS "daily_balance"
    FROM    calendar     c
    LEFT JOIN daily_delta d
           ON c."customer_id" = d."customer_id"
          AND c."dt"         = d."txn_dt"
),
monthly_max AS (                             -- 5) each customer’s highest daily balance per month
    SELECT  "customer_id",
            TO_CHAR("dt", 'YYYY-MM') AS "month",
            MAX("daily_balance")     AS "max_daily_balance_in_month"
    FROM    balances
    GROUP BY "customer_id", TO_CHAR("dt", 'YYYY-MM')
)
-- 6) company-wide total of those maxima per month
SELECT  "month",
        SUM("max_daily_balance_in_month") AS "total_max_balances_all_customers"
FROM    monthly_max
GROUP BY "month"
ORDER BY "month";