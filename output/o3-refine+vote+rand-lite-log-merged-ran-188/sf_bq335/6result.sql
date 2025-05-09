WITH "txs" AS (
    /*  all Bitcoin transactions (inputs + outputs) that occurred in October 2017  */
    SELECT
        ("value")::NUMBER                               AS "value",
        ("addresses")[0]::STRING                        AS "address",
        "block_timestamp"                               AS "ts"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    WHERE "block_timestamp" >= 1506816000000000        -- 2017‑10‑01 00:00:00 UTC
      AND "block_timestamp" <  1509494400000000        -- 2017‑11‑01 00:00:00 UTC

    UNION ALL

    SELECT
        ("value")::NUMBER                               AS "value",
        ("addresses")[0]::STRING                        AS "address",
        "block_timestamp"                               AS "ts"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
    WHERE "block_timestamp" >= 1506816000000000
      AND "block_timestamp" <  1509494400000000
),

/*  per‑address stats inside October 2017  */
"per_addr" AS (
    SELECT
        "address",
        MAX("ts")            AS "last_ts",      -- last (latest) transaction time in month
        SUM("value")         AS "total_value"   -- total value (inputs + outputs) in month
    FROM "txs"
    GROUP BY "address"
),

/*  latest date (micro‑seconds) any address transacted in the month  */
"max_last" AS (
    SELECT MAX("last_ts") AS "max_ts"
    FROM "per_addr"
)

/*  address with that latest date and largest value sum  */
SELECT
    p."address"
FROM "per_addr" p
JOIN "max_last" m
      ON p."last_ts" = m."max_ts"
ORDER BY p."total_value" DESC NULLS LAST, p."address"
LIMIT 1;