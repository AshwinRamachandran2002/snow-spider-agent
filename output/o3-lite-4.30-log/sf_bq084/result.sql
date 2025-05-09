SELECT
    "year",
    "month",
    "monthly_transaction_count",
    ROUND("monthly_transaction_count" / "seconds_in_month", 4) AS "transactions_per_second"
FROM (
    SELECT
        DATE_PART('year',  TO_TIMESTAMP("block_timestamp" / 1e6)) AS "year",
        DATE_PART('month', TO_TIMESTAMP("block_timestamp" / 1e6)) AS "month",
        COUNT(*)                                                  AS "monthly_transaction_count",
        DATEDIFF(
            'second',
            DATE_TRUNC('month', TO_TIMESTAMP(MIN("block_timestamp") / 1e6)),
            DATE_TRUNC('month', TO_TIMESTAMP(MIN("block_timestamp") / 1e6)) + INTERVAL '1 month'
        )                                                         AS "seconds_in_month"
    FROM
        GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE
        DATE_PART('year', TO_TIMESTAMP("block_timestamp" / 1e6)) = 2023
    GROUP BY
        "year",
        "month"
) t
ORDER BY
    "monthly_transaction_count" DESC NULLS LAST,
    "month";