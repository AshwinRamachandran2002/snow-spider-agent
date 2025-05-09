/*  Address whose last Bitcoin transaction in Oct‑2017 is on the very latest
    day of that month and, among those addresses, has the largest total value   */
WITH october_tx AS (   -- every input or output occurring during Oct‑2017
    SELECT
        f.value::STRING                        AS "address",
        o."value"::NUMBER                      AS "tx_value",
        o."block_timestamp"                    AS "ts"
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS  o,
           LATERAL FLATTEN(input => o."addresses") f
    WHERE  o."block_timestamp"
           BETWEEN 1506816000000000              -- 2017‑10‑01 00:00:00 UTC
               AND 1509494399000000              -- 2017‑10‑31 23:59:59 UTC

    UNION ALL

    SELECT
        f.value::STRING                        AS "address",
        i."value"::NUMBER                      AS "tx_value",
        i."block_timestamp"                    AS "ts"
    FROM   CRYPTO.CRYPTO_BITCOIN.INPUTS   i,
           LATERAL FLATTEN(input => i."addresses") f
    WHERE  i."block_timestamp"
           BETWEEN 1506816000000000
               AND 1509494399000000
),
per_addr AS (          -- last‑transaction date & total value per address
    SELECT
        "address",
        MAX(DATE_TRUNC('day', TO_TIMESTAMP("ts"/1e6))) AS "final_tx_date",
        SUM("tx_value")                                AS "oct_total_value"
    FROM   october_tx
    GROUP  BY "address"
),
latest_day AS (        -- the latest calendar date in Oct‑2017 with activity
    SELECT MAX("final_tx_date") AS "max_date"
    FROM   per_addr
),
ranked AS (            -- among addresses on that day, rank by total value
    SELECT
        p.*,
        ROW_NUMBER() OVER (ORDER BY p."oct_total_value" DESC) AS "rn"
    FROM   per_addr      p
    JOIN   latest_day    d
          ON p."final_tx_date" = d."max_date"
)
SELECT
    "address",
    "final_tx_date",
    "oct_total_value"
FROM   ranked
WHERE  "rn" = 1;