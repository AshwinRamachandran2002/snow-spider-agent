WITH outs AS (   -- credits
    SELECT
        COALESCE(o."type", 'unknown')                                AS "address_type",
        COALESCE(f.value::string, CONCAT(o."transaction_hash",':',o."index")) AS "address",
        o."value"                                                    AS "amount_satoshis"
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS o,
         LATERAL FLATTEN(input => o."addresses", outer => TRUE) f
    WHERE o."block_timestamp" >= 1393632000000000   -- 2014‑03‑01
      AND o."block_timestamp" <  1396310400000000   -- 2014‑04‑01
), ins AS (       -- debits (negative)
    SELECT
        COALESCE(i."type", 'unknown')                                AS "address_type",
        COALESCE(f.value::string, CONCAT(i."transaction_hash",':',i."index")) AS "address",
       -1 * i."value"                                                AS "amount_satoshis"
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS i,
         LATERAL FLATTEN(input => i."addresses", outer => TRUE) f
    WHERE i."block_timestamp" >= 1393632000000000
      AND i."block_timestamp" <  1396310400000000
), io AS (        -- combined I/O
    SELECT * FROM outs
    UNION ALL
    SELECT * FROM ins
), addr_bal AS (  -- final balance per address
    SELECT
        "address_type",
        "address",
        SUM("amount_satoshis") AS "final_balance_satoshis"
    FROM io
    GROUP BY "address_type","address"
), type_extremes AS (  -- max & min per address type
    SELECT
        "address_type",
        ROUND(MAX("final_balance_satoshis"),4) AS "max_final_balance_satoshis",
        ROUND(MIN("final_balance_satoshis"),4) AS "min_final_balance_satoshis"
    FROM addr_bal
    GROUP BY "address_type"
)
SELECT
    "address_type",
    "max_final_balance_satoshis",
    "min_final_balance_satoshis"
FROM type_extremes
ORDER BY "address_type";