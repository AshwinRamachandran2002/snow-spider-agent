WITH monthly AS (
    SELECT
        YEAR(TO_TIMESTAMP("block_timestamp" / 1e6))   AS "year",
        MONTH(TO_TIMESTAMP("block_timestamp" / 1e6))  AS "month",
        COUNT(*)                                      AS "monthly_transaction_count"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    -- 2023-01-01 00:00:00 UTC  to  2023-12-31 23:59:59 UTC  (microseconds)
    WHERE "block_timestamp" BETWEEN 1672531200000000
                               AND     1704067199000000
    GROUP BY 1, 2
)

SELECT
    m."monthly_transaction_count",
    ROUND(
        m."monthly_transaction_count" /
        DATEDIFF(
            'second',
            DATE_FROM_PARTS(m."year", m."month", 1),          -- first day of month
            DATEADD('month', 1, DATE_FROM_PARTS(m."year", m."month", 1))  -- first day next month
        ),
        4
    ) AS "transactions_per_second",
    m."year",
    m."month"
FROM monthly m
ORDER BY m."monthly_transaction_count" DESC NULLS LAST;