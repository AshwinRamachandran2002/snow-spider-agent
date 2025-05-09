SELECT
    "BLOCK_NUMBER"                                                         AS block_number,
    PARSE_JSON("ARGS")[0]::STRING                                          AS from_address,
    PARSE_JSON("ARGS")[1]::STRING                                          AS to_address,
    ROUND(TRY_TO_DECIMAL(PARSE_JSON("ARGS")[2]::STRING) / 1e6, 4)          AS amount_usdt
FROM "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
WHERE "ADDRESS"    = '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9'   -- USDT contract on Arbitrum
  AND "EVENT_HASH" = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef' -- Transfer
  AND TRY_TO_DECIMAL(PARSE_JSON("ARGS")[2]::STRING) IS NOT NULL
ORDER BY amount_usdt DESC NULLS LAST, "BLOCK_NUMBER" DESC
LIMIT 3;