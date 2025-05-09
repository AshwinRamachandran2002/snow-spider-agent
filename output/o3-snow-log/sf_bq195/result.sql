WITH txs AS (
    SELECT
        "from_address"                       AS address,
        -1 * ( "value"
               + COALESCE("receipt_effective_gas_price","gas_price") * "receipt_gas_used"
             )                              AS amount
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  "block_timestamp" < 1630454400000000          -- before 2021-09-01
      AND  "receipt_status" = 1
      AND  "from_address" IS NOT NULL
      AND  "to_address"   IS NOT NULL

    UNION ALL

    SELECT
        "to_address"                         AS address,
        "value"                              AS amount
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  "block_timestamp" < 1630454400000000
      AND  "receipt_status" = 1
      AND  "to_address" IS NOT NULL
      AND  "from_address" IS NOT NULL
),
trs AS (
    SELECT
        "from_address"                       AS address,
        -1 * "value"                         AS amount
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "block_timestamp" < 1630454400000000
      AND  "status" = 1
      AND  ( "call_type" IS NULL OR LOWER("call_type") = 'call' )
      AND  "from_address" IS NOT NULL
      AND  "to_address" IS NOT NULL

    UNION ALL

    SELECT
        "to_address"                         AS address,
        "value"                              AS amount
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "block_timestamp" < 1630454400000000
      AND  "status" = 1
      AND  ( "call_type" IS NULL OR LOWER("call_type") = 'call' )
      AND  "to_address" IS NOT NULL
      AND  "from_address" IS NOT NULL
),
all_flows AS (
    SELECT * FROM txs
    UNION ALL
    SELECT * FROM trs
)
SELECT
    address,
    SUM(amount) AS balance
FROM   all_flows
GROUP  BY address
ORDER  BY balance DESC NULLS LAST
LIMIT  10;