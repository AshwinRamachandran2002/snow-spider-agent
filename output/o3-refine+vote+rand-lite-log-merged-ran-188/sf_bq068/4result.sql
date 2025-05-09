WITH
/*-------------------------------------------------
  credits  :   all outputs in period 2014‑03‑01 → 2014‑04‑01
--------------------------------------------------*/
credits AS (
    SELECT
        FLATTENED.VALUE::STRING                AS "ADDRESS",
        o."type"                               AS "ADDRESS_TYPE",
        SUM(o."value")                         AS "AMOUNT"          -- positive
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"  o,
         LATERAL FLATTEN( INPUT => o."addresses" ) FLATTENED
    WHERE o."block_timestamp" >= 1393632000000000      -- 2014‑03‑01 00:00:00 UTC
      AND o."block_timestamp" <  1396310400000000      -- 2014‑04‑01 00:00:00 UTC
    GROUP BY 1,2
),
/*-------------------------------------------------
  debits   :   all inputs in the same period
--------------------------------------------------*/
debits AS (
    SELECT
        FLATTENED.VALUE::STRING                AS "ADDRESS",
        i."type"                               AS "ADDRESS_TYPE",
        -SUM(i."value")                        AS "AMOUNT"          -- negative
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"   i,
         LATERAL FLATTEN( INPUT => i."addresses" ) FLATTENED
    WHERE i."block_timestamp" >= 1393632000000000
      AND i."block_timestamp" <  1396310400000000
    GROUP BY 1,2
),
/*-------------------------------------------------
  running balance per address (credits – debits)
--------------------------------------------------*/
balances AS (
    SELECT
        "ADDRESS",
        "ADDRESS_TYPE",
        SUM("AMOUNT")                          AS "BALANCE"
    FROM (
        SELECT * FROM credits
        UNION ALL
        SELECT * FROM debits
    )
    GROUP BY 1,2
)
/*-------------------------------------------------
  max / min balance within each address type
--------------------------------------------------*/
SELECT
    "ADDRESS_TYPE",
    MAX("BALANCE") AS "MAX_FINAL_BALANCE",
    MIN("BALANCE") AS "MIN_FINAL_BALANCE"
FROM balances
GROUP BY "ADDRESS_TYPE"
ORDER BY "ADDRESS_TYPE";