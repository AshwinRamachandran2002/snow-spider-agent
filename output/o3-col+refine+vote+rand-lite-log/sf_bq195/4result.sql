/* Top-10 Ethereum addresses by net balance (received − (sent + gas fee))
   considering only successful transactions whose traces have
   call_type IS NULL OR 'call', before 1-Sep-2021 (UTC)            */

WITH
-- 1. Transactions that satisfy all required filters
eligible_tx AS (
    SELECT DISTINCT
           t."hash",
           t."from_address",
           t."to_address",
           t."value",                      -- wei transferred
           t."receipt_effective_gas_price",-- wei per gas
           t."receipt_gas_used"            -- gas units
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN   CRYPTO.CRYPTO_ETHEREUM.TRACES        tr
           ON tr."transaction_hash" = t."hash"
    WHERE  t."block_timestamp" < 1630454400000000            -- before 2021-09-01
      AND  t."receipt_status" = 1                            -- successful tx
      AND  tr."status"       = 1                            -- successful trace
      AND (tr."call_type" IS NULL OR tr."call_type" = 'call')
),

-- 2. Total amount (value + gas fee) sent per address
sent AS (
    SELECT
        "from_address"                         AS "addr",
        SUM( "value"
           + "receipt_effective_gas_price" * "receipt_gas_used"
        )                                      AS "sent_total"
    FROM   eligible_tx
    GROUP  BY "from_address"
),

-- 3. Total value received per address
received AS (
    SELECT
        "to_address"   AS "addr",
        SUM("value")   AS "recv_total"
    FROM   eligible_tx
    GROUP  BY "to_address"
)

-- 4. Net balance = received − (sent + gas fee)
SELECT
    COALESCE(r."addr", s."addr")                   AS "address",
    COALESCE(r."recv_total", 0) -
    COALESCE(s."sent_total", 0)                    AS "net_balance"
FROM   received r
FULL  JOIN sent s
       ON r."addr" = s."addr"
ORDER  BY "net_balance" DESC NULLS LAST
LIMIT 10;