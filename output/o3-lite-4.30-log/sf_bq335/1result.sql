WITH oct_transactions AS (                             -- all address‑side txns in Oct‑2017
    SELECT
        f.value::STRING   AS "address",
        o."block_timestamp"        AS "ts",
        o."value"                  AS "btc_value"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS" o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE o."block_timestamp" >= 1506816000000000         -- 2017‑10‑01 00:00:00 UTC
      AND o."block_timestamp" <  1509494400000000         -- 2017‑11‑01 00:00:00 UTC

    UNION ALL

    SELECT
        f.value::STRING   AS "address",
        i."block_timestamp"        AS "ts",
        i."value"                  AS "btc_value"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS" i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE i."block_timestamp" >= 1506816000000000
      AND i."block_timestamp" <  1509494400000000
),

address_aggregates AS (                                -- last ts & total value per address
    SELECT
        "address",
        MAX("ts")                   AS "last_ts",
        SUM("btc_value")            AS "total_btc_oct17"
    FROM oct_transactions
    GROUP BY "address"
),

latest_timestamp AS (                                  -- latest ts that occurred in Oct‑17
    SELECT MAX("last_ts") AS "max_ts"
    FROM address_aggregates
),

candidates AS (                                        -- addresses with that latest ts
    SELECT aa.*
    FROM address_aggregates aa
    JOIN latest_timestamp lt
      ON aa."last_ts" = lt."max_ts"
)

SELECT
    "address",
    TO_DATE( TO_TIMESTAMP("last_ts", 6) )                          AS "last_transaction_date",
    ROUND("total_btc_oct17", 4)                                    AS "total_oct_2017_value_btc"
FROM candidates
ORDER BY "total_oct_2017_value_btc" DESC, "address"
LIMIT 1;