WITH logs_2023 AS (
    /* keep every log row that belongs to year 2023 */
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000)  AS ts      -- convert µ‑seconds epoch to timestamp
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
),
monthly AS (
    /* aggregate raw‑row count for each (year, month) */
    SELECT
        EXTRACT(YEAR  FROM ts)           AS yr,
        EXTRACT(MONTH FROM ts)           AS mo,
        COUNT(*)                         AS tx_cnt            -- do NOT deduplicate tx hashes
    FROM logs_2023
    GROUP BY yr, mo
)
SELECT
    yr                                    AS "YEAR",
    mo                                    AS "MONTH",
    tx_cnt                                AS "MONTHLY_TRANSACTION_COUNT",
    ROUND(
        tx_cnt
        / (DAY(LAST_DAY(TO_DATE(TO_VARCHAR(yr)||'-'||LPAD(mo,2,'0')||'-01'))) * 86400),
        4
    )                                     AS "TRANSACTIONS_PER_SECOND"
FROM monthly
ORDER BY "MONTHLY_TRANSACTION_COUNT" DESC NULLS LAST, "YEAR", "MONTH";