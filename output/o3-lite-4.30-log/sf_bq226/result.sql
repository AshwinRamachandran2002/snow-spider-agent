SELECT
    CONCAT(
        'https://cronoscan.com/address/',
        SUBSTR(PARSE_JSON("ARGS")[0]::STRING, 3)
    ) AS "sender_cronoscan_url",
    COUNT(*) AS "tx_cnt"
FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
WHERE "EVENT_SIGNATURE" = 'Transfer(address,address,uint256)'
  AND "BLOCK_TIMESTAMP" >= 1672531200000000     -- since 2023‑01‑01 (µs)
  AND "BLOCK_NUMBER"  >= 4096                  -- blocks “larger than 4096 bytes”
  AND PARSE_JSON("ARGS")[1] IS NOT NULL         -- non‑null ‘to’ address
GROUP BY "sender_cronoscan_url"
ORDER BY "tx_cnt" DESC NULLS LAST, "sender_cronoscan_url"
LIMIT 1;