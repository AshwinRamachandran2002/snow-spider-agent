WITH logs_2023 AS (
    SELECT
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)           AS "ts"      -- convert µs → seconds
    FROM
        "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE
        YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) = 2023          -- keep year‑2023 only
),
month_agg AS (
    SELECT
        YEAR("ts")                                         AS "year",
        MONTH("ts")                                        AS "month",
        COUNT(*)                                           AS "monthly_transaction_count",
        DAY(LAST_DAY("ts"))                                AS "days_in_month"        -- 28/29/30/31
    FROM logs_2023
    GROUP BY
        YEAR("ts"),
        MONTH("ts"),
        DAY(LAST_DAY("ts"))
)
SELECT
    "year",
    "month",
    "monthly_transaction_count",
    ROUND("monthly_transaction_count" / ("days_in_month" * 86400.0), 4) AS "transactions_per_second"
FROM
    month_agg
ORDER BY
    "monthly_transaction_count" DESC NULLS LAST,
    "month"                     DESC;