WITH "UNION_TXS" AS (

    /* all OUTPUT rows, one record per address */
    SELECT
        addr.value::string                           AS "ADDRESS",
        TO_TIMESTAMP("block_timestamp" / 1000000)    AS "TS",
        "value"::FLOAT                               AS "TX_VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
         ,LATERAL FLATTEN( INPUT => "addresses") addr

    UNION ALL

    /* all INPUT rows, one record per address */
    SELECT
        addr.value::string                           AS "ADDRESS",
        TO_TIMESTAMP("block_timestamp" / 1000000)    AS "TS",
        "value"::FLOAT                               AS "TX_VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
         ,LATERAL FLATTEN( INPUT => "addresses") addr
),

/* transactions that happened in October‑2017 */
"OCT17_TXS" AS (
    SELECT *
    FROM  "UNION_TXS"
    WHERE "TS" >= '2017-10-01'::TIMESTAMP
      AND "TS" <  '2017-11-01'::TIMESTAMP
),

/* one row per address: last‑transaction moment and total value in Oct‑2017 */
"ADDR_STATS" AS (
    SELECT
        "ADDRESS",
        MAX("TS")                           AS "LAST_TS",
        SUM("TX_VALUE")                     AS "TOTAL_VALUE_OCT17"
    FROM "OCT17_TXS"
    GROUP BY "ADDRESS"
),

/* latest last‑transaction moment among all addresses */
"LATEST_TS" AS (
    SELECT MAX("LAST_TS") AS "MAX_LAST_TS"
    FROM   "ADDR_STATS"
),

/* addresses whose final October transaction equals that latest moment */
"CANDIDATES" AS (
    SELECT s.*
    FROM   "ADDR_STATS" s
           JOIN "LATEST_TS" l
             ON s."LAST_TS" = l."MAX_LAST_TS"
)

/* pick the address with the greatest total value (tie‑break by address) */
SELECT
    "ADDRESS",
    "LAST_TS"          AS "FINAL_TRANSACTION_TIMESTAMP",
    "TOTAL_VALUE_OCT17"
FROM   "CANDIDATES"
ORDER BY
    "TOTAL_VALUE_OCT17" DESC NULLS LAST,
    "ADDRESS"
LIMIT 1;