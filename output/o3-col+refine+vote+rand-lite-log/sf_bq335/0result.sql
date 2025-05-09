WITH all_oct17_tx AS (   -- every in-/out transfer that happened in Oct-2017
    /* INPUT side */
    SELECT
        f.value::STRING                 AS "address",
        i."block_timestamp"             AS "ts",
        i."value"                       AS "sats"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS  i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE i."block_timestamp"
          BETWEEN 1506816000000000     -- 2017-10-01 00:00:00 UTC
              AND 1509494399999999     -- 2017-10-31 23:59:59 UTC

    UNION ALL

    /* OUTPUT side */
    SELECT
        f.value::STRING                 AS "address",
        o."block_timestamp"             AS "ts",
        o."value"                       AS "sats"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE o."block_timestamp"
          BETWEEN 1506816000000000
              AND 1509494399999999
),
per_address AS (          -- most-recent tx time & total value per address
    SELECT
        "address",
        MAX("ts")                AS "last_ts_oct2017",
        SUM("sats")              AS "total_value_oct2017"
    FROM all_oct17_tx
    GROUP BY "address"
),
global_latest AS (        -- very latest timestamp reached by any address
    SELECT MAX("last_ts_oct2017") AS "max_last_ts"
    FROM   per_address
)
SELECT
    p."address",
    TO_TIMESTAMP(p."last_ts_oct2017"/1e6) AS "final_tx_datetime",
    p."total_value_oct2017"
FROM per_address  p
JOIN global_latest g
  ON p."last_ts_oct2017" = g."max_last_ts"
ORDER BY p."total_value_oct2017" DESC NULLS LAST
LIMIT 1;