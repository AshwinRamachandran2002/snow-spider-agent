WITH
-- 1. October-2017 Bitcoin outputs (explode address array)
outputs_oct AS (
    SELECT
        TRIM(f.value::STRING)                         AS "addr",
        o."block_timestamp"                           AS "ts",
        o."value"::FLOAT                              AS "val"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"  o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE o."block_timestamp"
          BETWEEN 1506816000000000 AND 1509494399000000   -- 2017-10-01 .. 2017-10-31
),
-- 2. October-2017 Bitcoin inputs (explode address array)
inputs_oct AS (
    SELECT
        TRIM(f.value::STRING)                         AS "addr",
        i."block_timestamp"                           AS "ts",
        i."value"::FLOAT                              AS "val"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"   i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE i."block_timestamp"
          BETWEEN 1506816000000000 AND 1509494399000000
),
-- 3. Union of all October transactions
all_oct AS (
    SELECT * FROM outputs_oct
    UNION ALL
    SELECT * FROM inputs_oct
),
-- 4. Last-October timestamp per address
last_per_addr AS (
    SELECT
        "addr",
        MAX("ts")         AS "last_ts_oct"
    FROM all_oct
    GROUP BY "addr"
),
-- 5. Overall latest October timestamp
latest_ts AS (
    SELECT MAX("last_ts_oct") AS "max_ts"
    FROM   last_per_addr
),
-- 6. Addresses whose final October tx happened exactly at that latest timestamp
tie_addrs AS (
    SELECT l."addr"
    FROM   last_per_addr l
           JOIN latest_ts t ON l."last_ts_oct" = t."max_ts"
),
-- 7. For those tied addresses, sum their October transaction values
sums AS (
    SELECT
        a."addr",
        SUM(a."val")      AS "total_oct_value",
        MAX(a."ts")       AS "last_ts_oct"
    FROM   all_oct a
           JOIN tie_addrs t ON a."addr" = t."addr"
    GROUP  BY a."addr"
)
-- 8. Pick the address with the highest total value (breaks the tie)
SELECT
    "addr",
    "total_oct_value",
    "last_ts_oct"
FROM   sums
ORDER  BY "total_oct_value" DESC NULLS LAST
LIMIT 1;