WITH
-- timestamp for 2021‑09‑01 00:00:00 UTC in micro‑seconds
"cutoff" AS (
    SELECT 1630454400000000::NUMBER AS "ts"
),

/* 1. Ether that leaves senders as gas fees (negative balance)           */
"tx_fees" AS (
    SELECT
        "from_address"                                       AS "address",
        -1 * ( COALESCE("receipt_effective_gas_price","gas_price")     -- Wei
               * "receipt_gas_used")                        AS "delta"
    FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS" t
         JOIN "cutoff" c
           ON t."block_timestamp" < c."ts"
    WHERE t."receipt_status" = 1
      AND t."from_address"      IS NOT NULL
),

/* 2. All successful value‑moving calls (external + internal)            */
"trace_transfers" AS (
    SELECT
        "from_address" AS "addr_from",
        COALESCE("to_address",'')  AS "addr_to",
        "value"::NUMBER            AS "value_wei"
    FROM CRYPTO.CRYPTO_ETHEREUM."TRACES" tr
         JOIN "cutoff" c
           ON tr."block_timestamp" < c."ts"
    WHERE tr."status" = 1
      AND (tr."call_type" IS NULL OR tr."call_type" = 'call')
      AND tr."value" IS NOT NULL
),

/* 3. Split traces into debits (‑value) and credits (+value)             */
"value_deltas" AS (
    SELECT "addr_from"                     AS "address", - "value_wei" AS "delta"
      FROM "trace_transfers"
     WHERE "addr_from" <> ''
    UNION ALL
    SELECT "addr_to"                       AS "address",   "value_wei" AS "delta"
      FROM "trace_transfers"
     WHERE "addr_to"   <> ''
),

/* 4. Combine gas‑fee debits and value movements                         */
"all_deltas" AS (
    SELECT * FROM "tx_fees"
    UNION ALL
    SELECT * FROM "value_deltas"
)

/* 5. Aggregate to get net balance per address and return top‑10         */
SELECT
    "address",
    SUM("delta") AS "balance_wei"
FROM "all_deltas"
GROUP BY "address"
ORDER BY "balance_wei" DESC NULLS LAST, "address"
LIMIT 10;