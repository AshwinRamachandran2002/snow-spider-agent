/* ------------------------------------------------------------
   1.  Net movement (+ deposits / – withdrawals & purchases)
   2.  Build a complete daily calendar per customer
   3.  Derive running daily balances (carry-forward & zero-floor)
   4.  Take each customer’s highest balance per month
   5.  Sum those highs across all customers to obtain
       the organisation-wide monthly total
------------------------------------------------------------ */
WITH daily_net AS (                          -- step-1
    SELECT
        "customer_id",
        TO_DATE("txn_date")                               AS "txn_date",
        SUM(
            CASE
                WHEN LOWER("txn_type") = 'deposit'                          THEN  "txn_amount"
                WHEN LOWER("txn_type") IN ('withdrawal','withdraw','purchase')
                                                                              THEN - "txn_amount"
                ELSE 0
            END
        )                                                 AS "net_amount"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date")
),
limits AS (                               -- first / last dates for each customer
    SELECT
        "customer_id",
        MIN("txn_date")                                     AS "min_date",
        MAX("txn_date")                                     AS "max_date",
        DATEDIFF('day', MIN("txn_date"), MAX("txn_date"))   AS "span_days"
    FROM daily_net
    GROUP BY "customer_id"
),
seq AS (                                  -- a long enough integer sequence
    SELECT SEQ4() AS "d"
    FROM TABLE(GENERATOR(ROWCOUNT => 20000))
),
calendar AS (                             -- step-2 : full calendar per customer
    SELECT
        l."customer_id",
        DATEADD('day', s."d", l."min_date") AS "calendar_date"
    FROM limits l
    JOIN seq   s  ON s."d" <= l."span_days"
),
balances AS (                             -- step-3 : running daily balances
    SELECT
        c."customer_id",
        c."calendar_date",
        GREATEST(
            SUM(COALESCE(d."net_amount",0)) OVER (
                PARTITION BY c."customer_id"
                ORDER BY      c."calendar_date"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
        0) AS "daily_balance"
    FROM calendar c
    LEFT JOIN daily_net d
           ON d."customer_id" = c."customer_id"
          AND d."txn_date"    = c."calendar_date"
),
month_max AS (                            -- step-4 : customer’s peak per month
    SELECT
        "customer_id",
        TO_CHAR("calendar_date",'YYYY-MM')  AS "month",
        MAX("daily_balance")                AS "max_daily_balance"
    FROM balances
    GROUP BY "customer_id", TO_CHAR("calendar_date",'YYYY-MM')
)
SELECT                                      -- step-5 : org-wide monthly totals
    "month",
    SUM("max_daily_balance") AS "monthly_total_highest_balance"
FROM month_max
GROUP BY "month"
ORDER BY "month";