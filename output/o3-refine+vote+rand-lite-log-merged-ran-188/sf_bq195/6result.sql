WITH valid_tx AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        t."receipt_gas_used",
        COALESCE(t."receipt_effective_gas_price", t."gas_price") AS "gas_price_eff"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    WHERE
        t."receipt_status" = 1
        AND t."block_timestamp" < 1630454400000000           -- before 2021‑09‑01 (µs)
        AND NOT EXISTS (                                    -- exclude unwanted call types
            SELECT 1
            FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
            WHERE tr."transaction_hash" = t."hash"
              AND tr."call_type" IS NOT NULL
              AND tr."call_type" <> 'call'
        )
),
address_flows AS (
    SELECT
        "from_address"  AS "address",
        -1 * ("value" + ("receipt_gas_used" * "gas_price_eff")) AS "net_amount"
    FROM valid_tx

    UNION ALL

    SELECT
        "to_address"    AS "address",
        "value"                                         AS "net_amount"
    FROM valid_tx
    WHERE "to_address" IS NOT NULL                     -- ignore contract-creation (null receiver)
)
SELECT
    "address",
    SUM("net_amount") AS "balance"
FROM address_flows
GROUP BY "address"
ORDER BY "balance" DESC NULLS LAST
LIMIT 10;