/* Top-3 largest USDT “Transfer” events on Arbitrum (6-decimals) */

WITH transfers AS (
    SELECT
           "BLOCK_NUMBER"                                                      AS "block_number",
           PARSE_JSON("ARGS")[0]::STRING                                       AS "from_address_hex",
           PARSE_JSON("ARGS")[1]::STRING                                       AS "to_address_hex",
           TRY_TO_DECIMAL( PARSE_JSON("ARGS")[2]::STRING ,38,0 ) / 1e6         AS "usdt_amount"
    FROM   "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."DECODED_EVENTS"
    WHERE  "EVENT_HASH" = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'  -- Transfer event
      AND  LOWER("ADDRESS") = '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9'                      -- USDT contract on Arbitrum
      AND  TRY_TO_DECIMAL( PARSE_JSON("ARGS")[2]::STRING ,38,0 ) IS NOT NULL                    -- ensure numeric value
)
SELECT *
FROM   transfers
ORDER  BY "usdt_amount" DESC NULLS LAST
LIMIT  3;