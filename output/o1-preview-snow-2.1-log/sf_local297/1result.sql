WITH current_balances AS (
    SELECT "customer_id", SUM("txn_amount") AS "current_balance"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    WHERE TO_DATE("txn_date", 'YYYY-MM-DD') <= '2020-03-31'
    GROUP BY "customer_id"
),
previous_balances AS (
    SELECT "customer_id", SUM("txn_amount") AS "previous_balance"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    WHERE TO_DATE("txn_date", 'YYYY-MM-DD') <= '2020-02-29'
    GROUP BY "customer_id"
),
growth_rates AS (
    SELECT 
        cb."customer_id",
        cb."current_balance",
        COALESCE(pb."previous_balance", 0) AS "previous_balance",
        CASE
            WHEN COALESCE(pb."previous_balance", 0) = 0 THEN cb."current_balance" * 100
            ELSE ((cb."current_balance" - pb."previous_balance") / pb."previous_balance") * 100
        END AS "growth_rate"
    FROM current_balances cb
    LEFT JOIN previous_balances pb ON cb."customer_id" = pb."customer_id"
)
SELECT 
    ROUND((COUNT(CASE WHEN "growth_rate" > 5 THEN 1 END) * 100.0) / COUNT(*), 4) AS "Percentage_of_users_with_growth_rate_over_5_percent"
FROM growth_rates;