WITH month_calendar AS (          -- all calendar months present in the data
    SELECT DISTINCT substr("txn_date",1,7) AS month_year
    FROM "customer_transactions"
),
customer_list AS (                -- every customer in the ledger
    SELECT DISTINCT "customer_id"
    FROM "customer_transactions"
),
customer_months AS (              -- full customer‑month grid
    SELECT cl."customer_id",
           mc."month_year"
    FROM customer_list  cl
    CROSS JOIN month_calendar mc
),
movements AS (                    -- net monthly movement (deposits – withdrawals)
    SELECT "customer_id",
           substr("txn_date",1,7) AS month_year,
           SUM(
               CASE
                   WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                   WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                   ELSE 0
               END
           ) AS net_movement
    FROM "customer_transactions"
    GROUP BY "customer_id",
             substr("txn_date",1,7)
)
SELECT  cm."customer_id",
        cm."month_year",
        COALESCE(mv.net_movement,0)                                      AS monthly_change,
        SUM(COALESCE(mv.net_movement,0))
            OVER (PARTITION BY cm."customer_id"
                  ORDER BY cm."month_year")                              AS cumulative_balance
FROM    customer_months cm
LEFT JOIN movements mv
       ON cm."customer_id" = mv."customer_id"
      AND cm."month_year"  = mv."month_year"
ORDER BY cm."customer_id",
         cm."month_year";