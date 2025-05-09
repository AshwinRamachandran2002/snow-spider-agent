WITH 
-- Timestamp for 1 September 2021 00:00:00 UTC (micro‑seconds)
"cutoff" AS (
    SELECT 1630454400000000 AS "ts"
),

/* -----------------------------------------------------------------
   1. Successful user‑level transactions (exclude those containing
      internal calls of type DELEGATECALL, CALLCODE or STATICCALL)
------------------------------------------------------------------*/
"valid_tx" AS (
    SELECT t.*
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t, "cutoff"
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < "cutoff"."ts"
      AND NOT EXISTS (
              SELECT 1
              FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
              WHERE tr."transaction_hash" = t."hash"
                AND tr."call_type" IN ('delegatecall','callcode','staticcall')
          )
),

/* -----------------------------------------------------------------
   2. Address that sent the largest number of such transactions
------------------------------------------------------------------*/
"top_sender" AS (
    SELECT  "from_address"            AS "addr",
            COUNT(*)                  AS "tx_cnt"
    FROM    "valid_tx"
    GROUP BY "from_address"
    ORDER BY "tx_cnt" DESC NULLS LAST
    LIMIT 1
),

/* -----------------------------------------------------------------
   3. Net ETH moved via traces (includes miner rewards, internal
      transfers; excludes unwanted call types)
------------------------------------------------------------------*/
"trace_delta" AS (
    SELECT
        SUM(
            CASE
                WHEN tr."to_address"   = ts."addr" THEN  tr."value"
                WHEN tr."from_address" = ts."addr" THEN -tr."value"
                ELSE 0
            END
        ) AS "wei_delta"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES tr
           JOIN "top_sender" ts
             ON  tr."to_address"   = ts."addr"
             OR  tr."from_address" = ts."addr"
           JOIN "cutoff"
     WHERE  tr."block_timestamp" <  "cutoff"."ts"
       AND (tr."call_type" IS NULL
            OR tr."call_type" NOT IN ('delegatecall','callcode','staticcall'))
       AND tr."status" = 1
),

/* -----------------------------------------------------------------
   4. Total gas fees paid by the address
------------------------------------------------------------------*/
"gas_fees" AS (
    SELECT
        COALESCE(
            SUM(
                t."receipt_gas_used"
              * COALESCE(t."receipt_effective_gas_price", t."gas_price")
            ),
            0
        ) AS "wei_fees"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
           JOIN "top_sender" ts
             ON t."from_address" = ts."addr"
           JOIN "cutoff"
    WHERE  t."block_timestamp" <  "cutoff"."ts"
      AND  t."receipt_status"   = 1
)

/* -----------------------------------------------------------------
   5. Final balance (Wei → Ether)
------------------------------------------------------------------*/
SELECT
       ts."addr"                                          AS "ETH_ADDRESS",
       (td."wei_delta" - gf."wei_fees") / 1e18            AS "FINAL_BALANCE_ETH"
FROM   "top_sender"   ts
       CROSS JOIN "trace_delta" td
       CROSS JOIN "gas_fees"   gf;