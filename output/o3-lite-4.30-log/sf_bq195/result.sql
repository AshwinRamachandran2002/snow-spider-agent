WITH valid_traces AS (   -- successful, top‑level traces
    SELECT DISTINCT "transaction_hash"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE "status" = 1
      AND ( "call_type" IS NULL OR "call_type" = 'call' )
),
valid_txs AS (           -- successful transactions before 1‑Sep‑2021 that appear in valid traces
    SELECT
        tx."hash",
        tx."from_address",
        tx."to_address",
        tx."value",
        COALESCE(tx."receipt_effective_gas_price", tx."gas_price") * tx."receipt_gas_used" AS "fee"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" tx
    WHERE tx."receipt_status" = 1
      AND tx."block_timestamp" < 1630454400000000        -- 2021‑09‑01 00:00:00 UTC (µs)
      AND tx."hash" IN (SELECT "transaction_hash" FROM valid_traces)
),
debits AS (              -- Wei spent (value + fee)
    SELECT
        "from_address" AS "address",
        SUM("value" + "fee") AS "debits_wei"
    FROM valid_txs
    GROUP BY "from_address"
),
credits AS (             -- Wei received (value)
    SELECT
        "to_address" AS "address",
        SUM("value") AS "credits_wei"
    FROM valid_txs
    GROUP BY "to_address"
),
balances AS (            -- net balance = credits − debits
    SELECT
        COALESCE(c."address", d."address") AS "address",
        COALESCE(c."credits_wei", 0) - COALESCE(d."debits_wei", 0) AS "balance_wei"
    FROM credits c
    FULL OUTER JOIN debits d
        ON c."address" = d."address"
)
SELECT
    "address",
    ROUND("balance_wei" / 1000000000000000000, 4) AS "balance_ether"
FROM balances
ORDER BY "balance_ether" DESC NULLS LAST, "address"
LIMIT 10;