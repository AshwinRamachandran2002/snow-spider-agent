WITH
/* 1. Credits (positive amounts from outputs) */
credits AS (
    SELECT
        o."type"                 AS "address_type",
        f.value::STRING          AS "address",
        SUM(o."value")           AS "credit_sats"
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o,
         LATERAL FLATTEN(INPUT => o."addresses") f
    WHERE o."block_timestamp" >= 1393632000000000   -- 2014‑03‑01 00:00:00 UTC
      AND o."block_timestamp" <  1396310400000000   -- 2014‑04‑01 00:00:00 UTC
    GROUP BY o."type", f.value
),
/* 2. Debits (positive amounts to be subtracted, taken from inputs) */
debits AS (
    SELECT
        i."type"                 AS "address_type",
        f.value::STRING          AS "address",
        SUM(i."value")           AS "debit_sats"
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS" i,
         LATERAL FLATTEN(INPUT => i."addresses") f
    WHERE i."block_timestamp" >= 1393632000000000
      AND i."block_timestamp" <  1396310400000000
    GROUP BY i."type", f.value
),
/* 3. Net balance per address = credits − debits */
balances AS (
    SELECT
        COALESCE(c."address", d."address")         AS "address",
        COALESCE(c."address_type", d."address_type") AS "address_type",
        COALESCE(c."credit_sats", 0)
          - COALESCE(d."debit_sats",  0)           AS "final_balance_sats"
    FROM credits c
    FULL JOIN debits d
           ON c."address"      = d."address"
          AND c."address_type" = d."address_type"
)
/* 4. Maximum and minimum final balances per address type */
SELECT
    "address_type",
    CAST(ROUND(MAX("final_balance_sats"), 4) AS NUMBER(38,4)) AS "max_final_balance_satoshis",
    CAST(ROUND(MIN("final_balance_sats"), 4) AS NUMBER(38,4)) AS "min_final_balance_satoshis"
FROM balances
GROUP BY "address_type"
ORDER BY "address_type";