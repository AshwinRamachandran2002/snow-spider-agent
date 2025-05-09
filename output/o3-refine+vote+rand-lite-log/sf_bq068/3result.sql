WITH date_bounds AS (
    /* 2014‑03‑01 00:00:00 → 1393632000s
       2014‑04‑01 00:00:00 → 1396310400s                                    */
    SELECT
        1393632000000000 :: NUMBER AS start_ts,
        1396310400000000 :: NUMBER AS end_ts
),
/* + credits (outputs) */
outputs AS (
    SELECT
        o."type",
        f.value::STRING                               AS address,
        o."value"                                     AS amount            -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o,
         LATERAL FLATTEN ( INPUT => o."addresses" ) f,
         date_bounds d
    WHERE o."block_timestamp" >= d.start_ts
      AND o."block_timestamp" <  d.end_ts
),
/* – debits (inputs) */
inputs AS (
    SELECT
        i."type",
        f.value::STRING                               AS address,
       -i."value"                                     AS amount            -- debit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"  i,
         LATERAL FLATTEN ( INPUT => i."addresses" ) f,
         date_bounds d
    WHERE i."block_timestamp" >= d.start_ts
      AND i."block_timestamp" <  d.end_ts
),
/* combined ledger lines */
ledger AS (
    SELECT * FROM outputs
    UNION ALL
    SELECT * FROM inputs
),
/* running balance per address */
balances AS (
    SELECT
        "type",
        address,
        SUM(amount) AS balance
    FROM ledger
    GROUP BY "type", address
)
/* final max / min balance per address type */
SELECT
    "type",
    MAX(balance) AS max_final_balance,
    MIN(balance) AS min_final_balance
FROM balances
GROUP BY "type"
ORDER BY "type";