WITH month_counts AS (
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "month_start",
        COUNT(*)                                                       AS "monthly_log_rows"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE DATE_PART('YEAR', TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY 1
),
month_seconds AS (
    SELECT
        mc."month_start",
        COALESCE(
            DATEDIFF('second',
                     mc."month_start",
                     LEAD(mc."month_start") OVER (ORDER BY mc."month_start")),
            DATEDIFF('second', mc."month_start", DATE_FROM_PARTS(2024, 1, 1))   -- handles Dec-2023
        ) AS "seconds_in_month"
    FROM month_counts mc
)
SELECT
    DATE_PART('YEAR',  mc."month_start")                                         AS "year",
    DATE_PART('MONTH', mc."month_start")                                         AS "month",
    mc."monthly_log_rows"                                                        AS "monthly_transaction_count",
    ROUND(mc."monthly_log_rows" * 1.0 / ms."seconds_in_month", 4)                AS "transactions_per_second"
FROM month_counts  mc
JOIN month_seconds ms
  ON mc."month_start" = ms."month_start"
ORDER BY "monthly_transaction_count" DESC NULLS LAST;