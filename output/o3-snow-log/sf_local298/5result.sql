/* ---------------------------------------------------------------
   For every calendar month, return the total balance that existed 
   on the 1-st of that month (i.e. each customer’s previous month-end
   balance), replacing any negative customer balances with zero.  
   The very first chronological month is kept only as a baseline and
   is excluded from the final result set.
---------------------------------------------------------------- */
WITH txn_base AS (  -- re-format the date and keep required columns
    SELECT 
        "customer_id",
        SUBSTR("txn_date",1,7)                       AS "txn_month",      -- YYYY-MM
        LOWER("txn_type")                            AS "txn_type",
        "txn_amount"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

monthly_net AS (     -- net movement per customer per month
    SELECT
        "customer_id",
        "txn_month",
        SUM( CASE 
                 WHEN "txn_type" LIKE '%deposit%'   THEN  "txn_amount"
                 WHEN "txn_type" LIKE '%withdraw%'  THEN -1 * "txn_amount"
                 ELSE 0
             END )                                  AS "monthly_net_amount"
    FROM txn_base
    GROUP BY "customer_id","txn_month"
),

month_end_bal AS (   -- running month-end balance for every customer
    SELECT
        "customer_id",
        "txn_month",
        SUM("monthly_net_amount") 
            OVER (PARTITION BY "customer_id"
                  ORDER BY "txn_month")             AS "month_end_balance"
    FROM monthly_net
),

opening_bal AS (     -- balance on the 1-st (previous month-end) – capped at 0
    SELECT
        "customer_id",
        "txn_month",
        GREATEST(0,
                 LAG("month_end_balance") 
                     OVER (PARTITION BY "customer_id"
                           ORDER BY "txn_month")
        )                                            AS "opening_balance"
    FROM month_end_bal
),

total_opening AS (   -- sum of (non-negative) opening balances across customers
    SELECT
        "txn_month"                                  AS "month",
        SUM( COALESCE("opening_balance",0) )         AS "total_opening_balance"
    FROM opening_bal
    GROUP BY "txn_month"
),

ranked_months AS (   -- remove the very first chronological month
    SELECT
        "month",
        "total_opening_balance",
        ROW_NUMBER() OVER (ORDER BY "month") AS "rn"
    FROM total_opening
)

SELECT
    "month",
    "total_opening_balance"
FROM ranked_months
WHERE "rn" > 1                 -- exclude first (baseline) month
ORDER BY "month";