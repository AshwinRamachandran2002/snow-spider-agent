WITH tx_filtered AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        /* fee in Wei = gas_used * effective_gas_price (fallback to gas_price) */
        COALESCE(t."receipt_gas_used" * t."receipt_effective_gas_price",
                 t."receipt_gas_used" * t."gas_price",
                 0)                                    AS "fee"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    /* keep successful txs prior to 2021-09-01 */
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < 1630454400000000            -- 2021-09-01 in µs
      /* keep only txs whose traces have no call_type or call_type = 'call',
         and trace itself succeeded                                         */
      AND EXISTS (
            SELECT 1
            FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
            WHERE tr."transaction_hash" = t."hash"
              AND tr."status" = 1
              AND (tr."call_type" IS NULL OR tr."call_type" = 'call')
      )
),
received AS (          -- all incoming native-ETH transfers
    SELECT
        t."to_address"        AS "address",
        SUM(t."value")        AS "received"
    FROM tx_filtered t
    WHERE t."to_address" IS NOT NULL
    GROUP BY t."to_address"
),
sent AS (               -- all outgoing native-ETH + gas fees
    SELECT
        t."from_address"                AS "address",
        SUM(t."value" + t."fee")        AS "sent"
    FROM tx_filtered t
    WHERE t."from_address" IS NOT NULL
    GROUP BY t."from_address"
),
balances AS (           -- net balance = incoming − (outgoing+fees)
    SELECT
        COALESCE(r."address", s."address")                                     AS "address",
        COALESCE(r."received", 0) - COALESCE(s."sent", 0)                      AS "balance"
    FROM received r
    FULL OUTER JOIN sent s
           ON r."address" = s."address"
)
SELECT
    "address",
    "balance"
FROM balances
ORDER BY "balance" DESC NULLS LAST
LIMIT 10;