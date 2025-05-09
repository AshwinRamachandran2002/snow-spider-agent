WITH monthly_balances AS (          -- 1. month-end balance for every customer
    SELECT
        "customer_id",
        substr("txn_date",1,7)               AS "month_yr",          -- YYYY-MM
        SUM(CASE WHEN "txn_type"='deposit'                          -- + deposits
                 THEN  "txn_amount"
                 ELSE - "txn_amount" END)     AS "balance"          -- – withdrawals
    FROM   "customer_transactions"
    WHERE  "txn_date" LIKE '2020-%'                                 -- only 2020
    GROUP  BY "customer_id", "month_yr"
),

month_stats AS (                   -- 2. customers-positive count & avg balance
    SELECT
        "month_yr",
        SUM( CASE WHEN "balance" > 0 THEN 1 ELSE 0 END ) AS "positive_custs",
        AVG("balance")                                   AS "avg_balance"
    FROM   monthly_balances
    GROUP  BY "month_yr"
),

bounds AS (                        -- 3. highest / lowest positive-customer counts
    SELECT
        MAX("positive_custs") AS max_pos,
        MIN("positive_custs") AS min_pos
    FROM   month_stats
),

high_low AS (                      -- 4. keep only the two required months
    SELECT
        "month_yr",
        "positive_custs",
        "avg_balance",
        CASE 
            WHEN "positive_custs" = (SELECT max_pos FROM bounds) THEN 'highest'
            ELSE 'lowest'
        END AS flag
    FROM   month_stats
    WHERE  "positive_custs" IN (SELECT max_pos FROM bounds
                                UNION
                                SELECT min_pos FROM bounds)
)

-- 5. final side-by-side report with the difference in averages
SELECT
    MAX(CASE WHEN flag='highest' THEN "month_yr"       END) AS highest_month,
    MAX(CASE WHEN flag='highest' THEN "positive_custs" END) AS highest_positive_customers,
    MAX(CASE WHEN flag='highest' THEN "avg_balance"    END) AS highest_month_avg_balance,

    MAX(CASE WHEN flag='lowest'  THEN "month_yr"       END) AS lowest_month,
    MAX(CASE WHEN flag='lowest'  THEN "positive_custs" END) AS lowest_positive_customers,
    MAX(CASE WHEN flag='lowest'  THEN "avg_balance"    END) AS lowest_month_avg_balance,

    MAX(CASE WHEN flag='highest' THEN "avg_balance" END) -
    MAX(CASE WHEN flag='lowest'  THEN "avg_balance" END)   AS difference_between_averages
FROM   high_low;