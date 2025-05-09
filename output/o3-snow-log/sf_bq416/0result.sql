/*--------------------------------------------------------------------------
  Top-3 largest USDT transfers observed on Arbitrum One
  (USDT contract: 0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9,
   Transfer event hash: 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef).
  Raw value is scaled by 1,000,000 to express the amount in normal USDT units.
---------------------------------------------------------------------------*/
WITH transfers AS (
  SELECT
      de."BLOCK_NUMBER"                                           AS "block_number",
      TRY_PARSE_JSON(de."ARGS")[0]::STRING                        AS "from_address",
      TRY_PARSE_JSON(de."ARGS")[1]::STRING                        AS "to_address",
      (TRY_PARSE_JSON(de."ARGS")[2]::NUMBER) / 1000000            AS "usdt_amount"
  FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."DECODED_EVENTS" de
  WHERE de."EVENT_HASH" = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
    AND LOWER(de."ADDRESS") = '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9'    -- USDT on Arbitrum
)
SELECT
    "block_number",
    "from_address",
    "to_address",
    "usdt_amount"
FROM transfers
ORDER BY "usdt_amount" DESC NULLS LAST
LIMIT 3;