WITH all_tx AS (   -- combine every INPUTS & OUTPUTS row
    SELECT "block_timestamp","value","addresses"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
    UNION ALL
    SELECT "block_timestamp","value","addresses"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
),
oct_tx AS (        -- keep only October‑2017 transactions and explode address arrays
    SELECT
        f.value::STRING          AS address,
        a."block_timestamp"      AS ts_micro,
        a."value"::FLOAT         AS value_sats
    FROM all_tx a,
         LATERAL FLATTEN(input => a."addresses") f
    WHERE a."block_timestamp" BETWEEN 1506816000000000        -- 2017‑10‑01 00:00:00
                                 AND     1509494399999999      -- 2017‑10‑31 23:59:59.999999
),
addr_stats AS (    -- last‑transaction time & total value per address
    SELECT
        address,
        MAX(ts_micro)            AS last_ts_micro,
        SUM(value_sats)          AS total_sats
    FROM oct_tx
    GROUP BY address
),
max_last AS (      -- latest last‑transaction timestamp observed in Oct‑2017
    SELECT MAX(last_ts_micro) AS latest_ts FROM addr_stats
),
winner AS (        -- addresses with that latest timestamp; pick highest total value
    SELECT *
    FROM addr_stats
    JOIN max_last ON addr_stats.last_ts_micro = max_last.latest_ts
    ORDER BY total_sats DESC
    LIMIT 1
)
SELECT
    address                                                    AS "address",
    TO_DATE(TO_TIMESTAMP_NTZ(last_ts_micro/1000000))           AS "last_transaction_date",
    ROUND(total_sats/100000000,4)                              AS "total_oct_2017_value_btc"
FROM winner;