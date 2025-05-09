/* Monthly transaction counts and transactions-per-second for 2023 */
WITH monthly AS (
    SELECT
        EXTRACT(year  FROM TO_TIMESTAMP("block_timestamp" / 1000000))      AS "YEAR",
        EXTRACT(month FROM TO_TIMESTAMP("block_timestamp" / 1000000))      AS "MONTH",
        COUNT(*)                                                           AS "MONTHLY_TRANSACTION_COUNT"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
    GROUP BY 1,2
),
seconds_calc AS (
    SELECT
        m.*,
        /* start of the month as a DATE */
        DATE_TRUNC('month',
                   TO_DATE(TO_CHAR("YEAR") || '-' || LPAD("MONTH",2,'0') || '-01')
        )                                             AS month_start
    FROM monthly m
)
SELECT
    "YEAR",
    "MONTH",
    "MONTHLY_TRANSACTION_COUNT",
    ROUND(
        "MONTHLY_TRANSACTION_COUNT" /
        DATEDIFF(
            'second',
            month_start,
            DATEADD('month', 1, month_start)          /* first day of next month */
        ),
        4
    )                                                 AS "TRANSACTIONS_PER_SECOND"
FROM seconds_calc
ORDER BY "MONTHLY_TRANSACTION_COUNT" DESC NULLS LAST;