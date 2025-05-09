/* ---------------------------------------------------------------
   Daily balances ➜ customer-monthly peaks ➜ portfolio monthly sum
   ---------------------------------------------------------------*/
WITH signed_txns AS (   -- +deposit, −otherwise
    SELECT
        "customer_id",
        TO_DATE("txn_date")                     AS "txn_dt",
        CASE 
            WHEN LOWER("txn_type") = 'deposit' 
                 THEN  "txn_amount"
            ELSE -1 * "txn_amount"
        END                                     AS "signed_amt"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

running_bal AS (        -- cumulative balance on the actual txn days
    SELECT
        "customer_id",
        "txn_dt",
        SUM("signed_amt") 
            OVER (PARTITION BY "customer_id"
                  ORDER BY "txn_dt"
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)      AS "cum_bal"
    FROM signed_txns
),

date_bounds AS (        -- earliest & latest txn date per customer
    SELECT
        "customer_id",
        MIN("txn_dt")    AS "min_dt",
        MAX("txn_dt")    AS "max_dt"
    FROM signed_txns
    GROUP BY "customer_id"
),

calendar AS (           -- generate every calendar day per customer
    SELECT
        b."customer_id",
        DATEADD('day', seq4(), b."min_dt")      AS "cal_dt"
    FROM date_bounds b,
         TABLE(GENERATOR(ROWCOUNT => 5000)) g   -- sufficiently large span
    WHERE DATEADD('day', seq4(), b."min_dt") <= b."max_dt"
),

daily AS (              -- join txn-day balances to every calendar date
    SELECT
        c."customer_id",
        c."cal_dt"                             AS "daily_dt",
        r."cum_bal"
    FROM calendar        c
    LEFT JOIN running_bal r
           ON  c."customer_id" = r."customer_id"
           AND c."cal_dt"     = r."txn_dt"
),

daily_bal_capped AS (   -- carry-forward + cap negatives at 0
    SELECT
        "customer_id",
        "daily_dt",
        GREATEST(
            0,
            COALESCE(
                LAST_VALUE("cum_bal") IGNORE NULLS
                    OVER (PARTITION BY "customer_id"
                          ORDER BY "daily_dt"
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
                0)
        )                                   AS "daily_balance"
    FROM daily
),

monthly_customer_peak AS (   -- highest daily balance each month per customer
    SELECT
        "customer_id",
        TO_CHAR("daily_dt", 'YYYY-MM')      AS "month_id",
        MAX("daily_balance")                AS "max_daily_balance"
    FROM daily_bal_capped
    GROUP BY "customer_id", TO_CHAR("daily_dt", 'YYYY-MM')
)

SELECT
    "month_id",
    SUM("max_daily_balance")                AS "monthly_total_max_balance"
FROM monthly_customer_peak
GROUP BY "month_id"
ORDER BY "month_id";