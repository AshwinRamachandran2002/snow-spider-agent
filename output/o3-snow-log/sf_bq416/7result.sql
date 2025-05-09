WITH usdt_transfers AS (
    SELECT
        "BLOCK_NUMBER",
        PARSE_JSON("ARGS")[0]::STRING                                        AS "source_address_hex",
        PARSE_JSON("ARGS")[1]::STRING                                        AS "destination_address_hex",
        TRY_TO_DECIMAL(PARSE_JSON("ARGS")[2]::STRING, 38, 0) / 1e6           AS "usdt_amount"
    FROM  "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
    WHERE "ADDRESS"     = '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9'      -- USDT contract on Arbitrum
      AND "EVENT_HASH"  = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'  -- Transfer event
)
SELECT
    "BLOCK_NUMBER",
    "source_address_hex",
    "destination_address_hex",
    "usdt_amount"
FROM   usdt_transfers
ORDER BY "usdt_amount" DESC NULLS LAST
LIMIT 3;