WITH monthly AS (
    /* 1. Net deposits (+) and withdrawals (‑) per customer per month‑start */
    SELECT
        "customer_id",
        substr("txn_date",1,7) || '-01'     AS "month_start",
        SUM(CASE
                WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                ELSE 0
            END)                            AS "monthly_net"
    FROM "customer_transactions"
    WHERE "txn_type" IN ('deposit','withdrawal')
    GROUP BY "customer_id", substr("txn_date",1,7)
),
closing AS (
    /* 2. Running balance at the end of every month */
    SELECT
        a."customer_id",
        a."month_start",
        (SELECT SUM(b."monthly_net")
           FROM monthly b
           WHERE b."customer_id" = a."customer_id"
             AND b."month_start" <= a."month_start") AS "closing_balance"
    FROM monthly a
),
latest AS (
    /* 3. Latest month’s balance and the immediately‑previous month’s balance */
    SELECT
        c1."customer_id",
        c1."closing_balance"                             AS "latest_balance",
        (SELECT c0."closing_balance"
           FROM closing c0
           WHERE c0."customer_id" = c1."customer_id"
             AND c0."month_start" = (
                    SELECT MAX("month_start")
                    FROM closing
                    WHERE "customer_id" = c1."customer_id"
                      AND "month_start" < c1."month_start")) AS "prev_balance"
    FROM closing c1
    WHERE c1."month_start" = (
          SELECT MAX("month_start")
          FROM closing c2
          WHERE c2."customer_id" = c1."customer_id")
),
growth AS (
    /* 4. Growth rate (%) from previous to latest month */
    SELECT
        "customer_id",
        CASE
            WHEN "prev_balance" IS NULL THEN NULL
            WHEN "prev_balance" = 0     THEN "latest_balance" * 100.0
            ELSE ("latest_balance" - "prev_balance") * 100.0
                 / ABS("prev_balance")
        END AS "growth_rate"
    FROM latest
)
/* 5. Percentage of customers whose most‑recent growth rate > 5 % */
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN "growth_rate" > 5 THEN 1 ELSE 0 END)
        / COUNT(*)
    , 2) AS "pct_customers_growth_gt_5"
FROM growth;