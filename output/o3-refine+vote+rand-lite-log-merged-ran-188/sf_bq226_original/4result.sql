WITH transfers AS (
    SELECT
        LOWER(CAST(PARSE_JSON("ARGS")[0] AS STRING)) AS sender
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."DECODED_EVENTS"
    WHERE
        "BLOCK_TIMESTAMP" >= 1672531200000000     -- >= 2023‑01‑01 00:00:00 UTC (µs)
        AND "EVENT_HASH" = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef' -- Transfer
),
sender_counts AS (
    SELECT
        sender,
        COUNT(*) AS tx_cnt
    FROM transfers
    WHERE sender IS NOT NULL
    GROUP BY sender
)
SELECT
    CONCAT('https://cronoscan.com/address/', sender) AS "SENDER_URL"
FROM sender_counts
ORDER BY
    tx_cnt DESC NULLS LAST,
    sender
LIMIT 1;