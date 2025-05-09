WITH monthly_agg AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "month_start",
        COUNT(*)                                                        AS "monthly_tx_count"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY "month_start"
)
SELECT
    EXTRACT(year   FROM "month_start")                                         AS "year",
    EXTRACT(month  FROM "month_start")                                         AS "month",
    "monthly_tx_count",
    ROUND(
        "monthly_tx_count" /
        NULLIF(
            DATEDIFF(
                'second',
                "month_start",
                DATEADD('month', 1, "month_start")
            ),
            0
        ),
        4
    )                                                                          AS "tx_per_sec"
FROM monthly_agg
ORDER BY "monthly_tx_count" DESC NULLS LAST;