WITH monthly AS (
    SELECT
        EXTRACT(year  FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        EXTRACT(month FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "month",
        COUNT(*)                                                      AS "monthly_tx_count"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY
        EXTRACT(year  FROM TO_TIMESTAMP("block_timestamp" / 1000000)),
        EXTRACT(month FROM TO_TIMESTAMP("block_timestamp" / 1000000))
)
SELECT
    "year",
    "month",
    "monthly_tx_count",
    ROUND(
        "monthly_tx_count" * 1.0 /
        DATEDIFF(
            'second',
            DATE_FROM_PARTS("year", "month", 1),
            DATEADD(month, 1, DATE_FROM_PARTS("year", "month", 1))
        ),
        4
    ) AS "tx_per_second"
FROM monthly
ORDER BY "monthly_tx_count" DESC NULLS LAST;