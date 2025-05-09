WITH positive_balances AS (
    SELECT "customer_id", "month", MAX("running_balance") AS "month_end_balance"
    FROM (
        SELECT 
            "customer_id", 
            SUBSTRING("txn_date", 1, 7) AS "month", 
            "txn_date",
            SUM("txn_amount") OVER (
                PARTITION BY "customer_id" 
                ORDER BY "txn_date" 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS "running_balance"
        FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
        WHERE "txn_date" LIKE '2020%'
    ) AS sub
    GROUP BY "customer_id", "month"
    HAVING MAX("running_balance") > 0
),
month_counts AS (
    SELECT "month", COUNT(DISTINCT "customer_id") AS "num_customers"
    FROM positive_balances
    GROUP BY "month"
),
most_customers_month AS (
    SELECT "month" FROM month_counts
    ORDER BY "num_customers" DESC NULLS LAST
    LIMIT 1
),
fewest_customers_month AS (
    SELECT "month" FROM month_counts
    ORDER BY "num_customers" ASC NULLS LAST
    LIMIT 1
),
average_balances AS (
    SELECT "month", AVG("month_end_balance") AS "average_balance"
    FROM positive_balances
    WHERE "month" IN (
        (SELECT "month" FROM most_customers_month),
        (SELECT "month" FROM fewest_customers_month)
    )
    GROUP BY "month"
)
SELECT ROUND(ABS(
    MAX(CASE WHEN "month" = (SELECT "month" FROM most_customers_month) THEN "average_balance" END) -
    MAX(CASE WHEN "month" = (SELECT "month" FROM fewest_customers_month) THEN "average_balance" END)
), 4) AS "Difference_in_Average_Month_End_Balance"
FROM average_balances;