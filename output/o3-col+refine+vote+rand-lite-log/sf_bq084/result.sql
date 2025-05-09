WITH per_month AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(FLOOR("block_timestamp" / 1000000)))        AS "month_start",
        COUNT(*)                                                                     AS "monthly_transaction_count",
        DATEDIFF(
            'second',
            DATE_TRUNC('month', TO_TIMESTAMP(FLOOR("block_timestamp" / 1000000))),
            DATEADD('month', 1,
                    DATE_TRUNC('month', TO_TIMESTAMP(FLOOR("block_timestamp" / 1000000))))
        )                                                                            AS "seconds_in_month"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS"
    WHERE YEAR(TO_TIMESTAMP(FLOOR("block_timestamp" / 1000000))) = 2023
    GROUP BY 1
)

SELECT
    DATE_PART('year',  "month_start")                    AS "year",
    DATE_PART('month', "month_start")                    AS "month",
    "monthly_transaction_count",
    ROUND("monthly_transaction_count" / "seconds_in_month", 6) AS "tx_per_second"
FROM per_month
ORDER BY "monthly_transaction_count" DESC NULLS LAST;