WITH combined AS (   /* every Bitcoin input + output in Oct‑2017 */
    SELECT
        f.value::STRING        AS "address",
        o."value"              AS "value_btc",
        o."block_timestamp"    AS "ts"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS" AS o,
         LATERAL FLATTEN (INPUT => o."addresses") AS f
    WHERE o."block_timestamp" BETWEEN 1506816000000000     /* 2017‑10‑01 00:00:00 */
                                  AND 1509494399999999     /* 2017‑10‑31 23:59:59.999999 */

    UNION ALL

    SELECT
        f.value::STRING        AS "address",
        i."value"              AS "value_btc",
        i."block_timestamp"    AS "ts"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS" AS i,
         LATERAL FLATTEN (INPUT => i."addresses") AS f
    WHERE i."block_timestamp" BETWEEN 1506816000000000
                                  AND 1509494399999999
),
per_addr AS (                     /* metrics per address */
    SELECT
        "address",
        MAX("ts")            AS "last_ts",
        SUM("value_btc")     AS "total_value_oct"
    FROM combined
    GROUP BY "address"
),
max_ts AS (                       /* latest timestamp in the month */
    SELECT MAX("last_ts") AS "latest_ts"
    FROM   per_addr
),
finalists AS (                    /* addresses whose final tx = latest_ts */
    SELECT p.*
    FROM   per_addr AS p
    JOIN   max_ts   AS m
      ON   p."last_ts" = m."latest_ts"
)
SELECT
    "address",
    TO_CHAR(TO_TIMESTAMP_NTZ("last_ts" / 1000000), 'YYYY-MM-DD HH24:MI:SS')  AS "last_transaction_date",
    TO_VARCHAR(ROUND("total_value_oct", 4))                                   AS "total_oct_2017_value_btc"
FROM   finalists
ORDER  BY "total_value_oct" DESC NULLS LAST
LIMIT 1;