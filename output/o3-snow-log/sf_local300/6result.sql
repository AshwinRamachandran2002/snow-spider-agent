/* -----------------------------------------------------------
   1) Build signed transactions (+ deposits, – withdrawals)
   2) Derive running balance per-customer per-txn-day
   3) Create a calendar of EVERY day between first & last txn
   4) Carry running balance forward to non-txn days
   5) Clip negatives to zero → daily balances
   6) Per month, take each customer’s MAX daily balance
   7) Sum those customer-maxima → monthly total peak balance
------------------------------------------------------------*/
WITH txns AS (   -- step-1
    SELECT
        "customer_id",
        TO_DATE("txn_date")                                          AS "txn_dt",
        CASE 
            WHEN LOWER("txn_type") = 'deposit'
                 THEN  "txn_amount"
                 ELSE -1 * "txn_amount"
        END                                                          AS "signed_amt"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

running AS (     -- step-2
    SELECT
        "customer_id",
        "txn_dt",
        SUM("signed_amt") OVER (
                PARTITION BY "customer_id"
                ORDER BY       "txn_dt"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                           AS "run_bal"
    FROM txns
),

bounds AS (      -- first / last transaction dates
    SELECT
        "customer_id",
        MIN("txn_dt")                                               AS "start_dt",
        MAX("txn_dt")                                               AS "end_dt"
    FROM running
    GROUP BY "customer_id"
),

calendar AS (    -- step-3 : dense calendar rows
    SELECT
        b."customer_id",
        DATEADD(day, seq4(), b."start_dt")                          AS "cal_dt"
    FROM bounds b,
         TABLE(GENERATOR(ROWCOUNT => 5000))  -- long enough horizon
    WHERE DATEADD(day, seq4(), b."start_dt") <= b."end_dt"
),

joined AS (      -- align calendar with any txn-day balances
    SELECT
        c."customer_id",
        c."cal_dt",
        r."run_bal"
    FROM calendar c
    LEFT JOIN running r
           ON  r."customer_id" = c."customer_id"
          AND r."txn_dt"      = c."cal_dt"
),

filled AS (      -- step-4 : forward-fill balance
    SELECT
        "customer_id",
        "cal_dt",
        COALESCE(
            LAST_VALUE("run_bal") IGNORE NULLS
              OVER (PARTITION BY "customer_id"
                    ORDER BY      "cal_dt"),
            0
        )                                                           AS "daily_bal"
    FROM joined
),

clipped AS (     -- step-5 : zero-floor
    SELECT
        "customer_id",
        "cal_dt",
        CASE WHEN "daily_bal" < 0 THEN 0 ELSE "daily_bal" END       AS "daily_bal_nonneg"
    FROM filled
),

monthly_peak AS ( -- step-6
    SELECT
        "customer_id",
        TO_CHAR("cal_dt", 'YYYY-MM')                                AS "month_id",
        MAX("daily_bal_nonneg")                                     AS "peak_bal"
    FROM clipped
    GROUP BY
        "customer_id",
        TO_CHAR("cal_dt", 'YYYY-MM')
),

monthly_total_peak AS ( -- step-7
    SELECT
        "month_id",
        SUM("peak_bal")                                             AS "total_peak_balance"
    FROM monthly_peak
    GROUP BY "month_id"
)

SELECT
    "month_id",
    "total_peak_balance"
FROM monthly_total_peak
ORDER BY "month_id";