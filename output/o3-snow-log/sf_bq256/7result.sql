WITH
/*-------------------------------------------------------
  constant cut-off timestamp : 2021-09-01 00:00:00 UTC
-------------------------------------------------------*/
params AS (
    SELECT 1630454400000000::NUMBER AS ts          -- micro-seconds
),
/*-------------------------------------------------------
  address with the most successful transactions
-------------------------------------------------------*/
top_sender AS (
    SELECT
        "from_address"  AS address
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS, params
    WHERE "block_timestamp" < params.ts
      AND "receipt_status" = 1
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
/*-------------------------------------------------------
  external outgoing transfers  +  gas fees
-------------------------------------------------------*/
ext_out AS (
    SELECT
        SUM("value")                                                 AS wei_out,
        SUM("receipt_gas_used" * COALESCE("receipt_effective_gas_price", "gas_price"))  AS gas_fee
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t, params, top_sender
    WHERE t."block_timestamp" < params.ts
      AND t."from_address"   = top_sender.address
      AND t."receipt_status" = 1
),
/*-------------------------------------------------------
  external incoming transfers
-------------------------------------------------------*/
ext_in AS (
    SELECT SUM("value") AS wei_in
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t, params, top_sender
    WHERE t."block_timestamp" < params.ts
      AND t."to_address"     = top_sender.address
      AND t."receipt_status" = 1
),
/*-------------------------------------------------------
  internal outgoing transfers  (exclude delegatecall / callcode / staticcall)
-------------------------------------------------------*/
int_out AS (
    SELECT SUM("value") AS wei_int_out
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr, params, top_sender
    WHERE tr."block_timestamp" < params.ts
      AND tr."from_address" = top_sender.address
      AND tr."status"       = 1
      AND tr."trace_type"   = 'call'
      AND (tr."call_type" IS NULL
           OR tr."call_type" NOT IN ('delegatecall','callcode','staticcall'))
),
/*-------------------------------------------------------
  internal incoming transfers  (same exclusions)
-------------------------------------------------------*/
int_in AS (
    SELECT SUM("value") AS wei_int_in
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr, params, top_sender
    WHERE tr."block_timestamp" < params.ts
      AND tr."to_address"   = top_sender.address
      AND tr."status"       = 1
      AND tr."trace_type"   = 'call'
      AND (tr."call_type" IS NULL
           OR tr."call_type" NOT IN ('delegatecall','callcode','staticcall'))
),
/*-------------------------------------------------------
  mining rewards credited to the address (trace_type = reward)
-------------------------------------------------------*/
rewards_in AS (
    SELECT SUM("value") AS wei_rewards
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr, params, top_sender
    WHERE tr."block_timestamp" < params.ts
      AND tr."trace_type" = 'reward'
      AND tr."to_address" = top_sender.address
)
/*-------------------------------------------------------
  final balance in Ether
-------------------------------------------------------*/
SELECT
    top_sender.address                                        AS "ETH_ADDRESS",
    ( COALESCE(wei_in,0)
    + COALESCE(wei_int_in,0)
    + COALESCE(wei_rewards,0)
    - COALESCE(wei_out,0)
    - COALESCE(wei_int_out,0)
    - COALESCE(gas_fee,0) ) / 1e18                           AS "FINAL_BALANCE_ETHER"
FROM top_sender
LEFT JOIN ext_out    ON TRUE
LEFT JOIN ext_in     ON TRUE
LEFT JOIN int_out    ON TRUE
LEFT JOIN int_in     ON TRUE
LEFT JOIN rewards_in ON TRUE;