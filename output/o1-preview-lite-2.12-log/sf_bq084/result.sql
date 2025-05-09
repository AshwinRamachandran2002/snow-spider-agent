WITH monthly_transactions AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP(FLOOR("block_timestamp" / 1e6))) AS "Year",
        EXTRACT(MONTH FROM TO_TIMESTAMP(FLOOR("block_timestamp" / 1e6))) AS "Month_num",
        COUNT(*) AS "Monthly_Transaction_Count"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(FLOOR("block_timestamp" / 1e6))) = 2023
    GROUP BY "Year", "Month_num"
)
SELECT
    "Year",
    "Month_num",
    TO_CHAR(DATE_FROM_PARTS("Year", "Month_num", 1), 'Mon') AS "Month",
    "Monthly_Transaction_Count",
    ROUND(
        "Monthly_Transaction_Count" / DATEDIFF(
            'second',
            DATE_TRUNC('month', DATE_FROM_PARTS("Year", "Month_num", 1)),
            DATE_TRUNC('month', DATEADD('month', 1, DATE_FROM_PARTS("Year", "Month_num", 1)))
        ),
        4
    ) AS "Computed_Transactions_Per_Second"
FROM monthly_transactions
ORDER BY "Monthly_Transaction_Count" DESC NULLS LAST;