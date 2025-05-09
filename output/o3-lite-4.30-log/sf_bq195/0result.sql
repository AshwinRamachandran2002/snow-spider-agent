WITH allowed_tx AS (
    SELECT DISTINCT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        t."gas_price",
        t."receipt_gas_used"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" t
    JOIN "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"        tr
          ON tr."transaction_hash" = t."hash"
    WHERE t."block_timestamp" < 1630454400000000          -- before 2021‑09‑01 (µs)
      AND t."receipt_status" = 1                          -- successful tx
      AND tr."status"      = 1                            -- successful trace
      AND (tr."call_type" IS NULL OR tr."call_type" = 'call')
),
credits AS (   -- ETH received (value only)
    SELECT 
        a."to_address"                 AS "address",
        SUM(a."value")                 AS "credit_wei"
    FROM allowed_tx a
    WHERE a."to_address" IS NOT NULL
    GROUP BY a."to_address"
),
debits AS (    -- ETH spent (value + gas)
    SELECT 
        a."from_address"                                       AS "address",
        SUM(a."value" + a."gas_price" * a."receipt_gas_used")  AS "debit_wei"
    FROM allowed_tx a
    WHERE a."from_address" IS NOT NULL
    GROUP BY a."from_address"
),
balances AS (
    SELECT 
        COALESCE(c."address", d."address")        AS "address",
        COALESCE(c."credit_wei", 0) 
        - COALESCE(d."debit_wei", 0)              AS "net_balance_wei"
    FROM credits c
    FULL JOIN debits d
           ON c."address" = d."address"
)
SELECT 
    "address",
    TO_DECIMAL("net_balance_wei" / 1000000000000000000, 38, 4) AS "balance_ether"
FROM   balances
ORDER  BY "net_balance_wei" DESC NULLS LAST
LIMIT 10;