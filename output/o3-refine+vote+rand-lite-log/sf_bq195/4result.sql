WITH valid_tx AS (
    SELECT
        "hash",
        "from_address",
        "to_address",
        "value",
        "receipt_effective_gas_price",
        "receipt_gas_used"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE
        "receipt_status" = 1
        AND "block_timestamp" < 1630454400000000   -- 2021‑09‑01 00:00:00 UTC
        AND NOT EXISTS (
            SELECT 1
            FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
            WHERE "transaction_hash" = TRANSACTIONS."hash"
              AND "call_type" IS NOT NULL
              AND LOWER("call_type") <> 'call'
        )
),
flows AS (
    /* incoming value */
    SELECT
        "to_address"            AS address,
        "value"                 AS amount
    FROM valid_tx
    WHERE "to_address" IS NOT NULL

    UNION ALL

    /* outgoing value plus gas fee paid by sender */
    SELECT
        "from_address"                                              AS address,
        -( "value"
         + ("receipt_effective_gas_price" * "receipt_gas_used") )   AS amount
    FROM valid_tx
)
SELECT
    address,
    SUM(amount) AS balance
FROM flows
GROUP BY address
ORDER BY balance DESC NULLS LAST, address
LIMIT 10;