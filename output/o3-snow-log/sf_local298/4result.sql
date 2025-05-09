WITH month_nets AS (   -- 1. monthly net movement per customer
    SELECT 
        "customer_id",
        TO_DATE(SUBSTR("txn_date",1,7) || '-01')           AS "month_start",
        SUM( CASE 
                 WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
                 WHEN LOWER("txn_type") = 'withdrawal'  THEN -1 * "txn_amount"
                 ELSE 0
             END )                                        AS "net_amount"
    FROM   BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
    GROUP  BY "customer_id", TO_DATE(SUBSTR("txn_date",1,7) || '-01')
),

cust_bal AS (          -- 2. cumulative balance per customer, negatives floored to 0
    SELECT
        "customer_id",
        "month_start",
        GREATEST( 
            SUM("net_amount") OVER (
                PARTITION BY "customer_id"
                ORDER BY     "month_start"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            0
        )                                                  AS "balance"
    FROM month_nets
),

month_tot AS (         -- 3. total balance across all customers for each month
    SELECT 
        "month_start",
        SUM("balance") AS "total_balance"
    FROM   cust_bal
    GROUP  BY "month_start"
),

result AS (            -- 4. previous-month total balance for every month (excludes first)
    SELECT
        curr."month_start"                 AS "month_start",
        prev."total_balance"               AS "previous_month_total_balance"
    FROM   month_tot curr
    JOIN   month_tot prev
           ON prev."month_start" = DATEADD(MONTH, -1, curr."month_start")
)

-- 5. final ordered output
SELECT 
    "month_start",
    "previous_month_total_balance"
FROM   result
ORDER  BY "month_start" ASC;