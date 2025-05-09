/* -----------------------------------------------------------
   Calculate the previous-month total (non-negative) BTC balance
   for all users, per calendar month.
   ----------------------------------------------------------- */
WITH month_net AS (          -- 1. net quantity per member per month
    SELECT
        "member_id",
        TO_CHAR(TO_DATE("txn_date",'DD-MM-YYYY'),'MM-YYYY')          AS "month_yyyy",
        SUM(
            CASE 
                WHEN UPPER("txn_type") = 'BUY'  THEN  "quantity"
                WHEN UPPER("txn_type") = 'SELL' THEN -1 * "quantity"
                ELSE 0
            END
        )                                                          AS "net_qty_month"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_TRANSACTIONS"
    GROUP BY
        "member_id",
        TO_CHAR(TO_DATE("txn_date",'DD-MM-YYYY'),'MM-YYYY')
),

member_bal AS (               -- 2. running balance per member (EOM)
    SELECT
        "member_id",
        "month_yyyy",
        SUM("net_qty_month") OVER (
            PARTITION BY "member_id"
            ORDER BY TO_DATE('01-'||"month_yyyy",'DD-MM-YYYY')
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                         AS "balance_eom"
    FROM month_net
),

member_bal_clean AS (         -- 3. clamp negatives to zero
    SELECT
        "member_id",
        "month_yyyy",
        CASE WHEN "balance_eom" < 0 THEN 0 ELSE "balance_eom" END  AS "balance_eom_no_negative"
    FROM member_bal
),

total_bal AS (                -- 4. total balance across all users each month
    SELECT
        "month_yyyy",
        SUM("balance_eom_no_negative")                            AS "total_balance_eom_all_users"
    FROM member_bal_clean
    GROUP BY "month_yyyy"
),

prev_month_totals AS (        -- 5. previous-month totals (exclude very first month)
    SELECT
        "month_yyyy",
        LAG("total_balance_eom_all_users") OVER (
            ORDER BY TO_DATE('01-'||"month_yyyy",'DD-MM-YYYY')
        )                                                         AS "total_balance_prev_month"
    FROM total_bal
)

-- 6. final output: month & previous-month total, sorted ascending
SELECT
    "month_yyyy",
    "total_balance_prev_month"
FROM prev_month_totals
WHERE "total_balance_prev_month" IS NOT NULL      -- drop first month (baseline only)
ORDER BY TO_DATE('01-'||"month_yyyy",'DD-MM-YYYY') ASC;