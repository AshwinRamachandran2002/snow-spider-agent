WITH period AS (
    /* 2014‑03‑01 00:00:00 UTC  →  2014‑04‑01 00:00:00 UTC (micro‑seconds) */
    SELECT 
        1393632000000000::NUMBER AS ts_start ,   
        1396310400000000::NUMBER AS ts_end
),
ledger AS (
    /* credits (Outputs) */
    SELECT
        o."type",
        f.value::STRING                    AS "address",
        o."value"::NUMBER                  AS amount          -- positive
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o
         ,LATERAL FLATTEN(input => o."addresses") f
         ,period p
    WHERE o."block_timestamp" BETWEEN p.ts_start AND p.ts_end

    UNION ALL

    /* debits (Inputs) – sign is negative */
    SELECT
        i."type",
        f.value::STRING                    AS "address",
        - i."value"::NUMBER                AS amount          -- negative
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS" i
         ,LATERAL FLATTEN(input => i."addresses") f
         ,period p
    WHERE i."block_timestamp" BETWEEN p.ts_start AND p.ts_end
),
balances AS (
    SELECT
        "type",
        "address",
        SUM(amount) AS final_balance
    FROM ledger
    GROUP BY "type", "address"
)
SELECT
    "type",
    MAX(final_balance) AS max_final_balance,
    MIN(final_balance) AS min_final_balance
FROM balances
GROUP BY "type";