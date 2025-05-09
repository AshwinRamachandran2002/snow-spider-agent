WITH usdt_transfers AS (
    SELECT
        "BLOCK_NUMBER",
        GET(PARSE_JSON("ARGS"), 0)::STRING                                         AS "FROM_ADDRESS",
        GET(PARSE_JSON("ARGS"), 1)::STRING                                         AS "TO_ADDRESS",
        (GET(PARSE_JSON("ARGS"), 2)::NUMBER) / 1000000                             AS "USDT_AMOUNT"
    FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
    WHERE LOWER("ADDRESS") = '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9'         -- USDT contract (6‑decimals) on Arbitrum
      AND "EVENT_HASH"   = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'  -- Transfer event
      AND NOT "REMOVED"
)
SELECT
    "BLOCK_NUMBER",
    "FROM_ADDRESS",
    "TO_ADDRESS",
    "USDT_AMOUNT"
FROM usdt_transfers
ORDER BY
    "USDT_AMOUNT" DESC NULLS LAST,
    "BLOCK_NUMBER" DESC
LIMIT 3;