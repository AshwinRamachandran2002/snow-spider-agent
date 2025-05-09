WITH transfers AS (
    SELECT
        LOWER((PARSE_JSON("ARGS")[0])::STRING) AS "from_address",
        LOWER((PARSE_JSON("ARGS")[1])::STRING) AS "to_address"
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."DECODED_EVENTS"
    WHERE "EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
      AND "BLOCK_TIMESTAMP" >= 1672531200000000      -- 2023‑01‑01 00:00:00 UTC (µs)
      AND PARSE_JSON("ARGS")[1] IS NOT NULL          -- non‑null recipient
)
SELECT
    'https://cronoscan.com/address/' || "from_address" AS "sender_url"
FROM (
    SELECT
        "from_address",
        COUNT(*) AS "tx_count"
    FROM transfers
    GROUP BY "from_address"
    ORDER BY "tx_count" DESC NULLS LAST, "from_address"
    LIMIT 1
);