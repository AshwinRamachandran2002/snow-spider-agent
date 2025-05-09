WITH "txs" AS (
    /* combine inputs */
    SELECT
        f.value::STRING                                                AS "address",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))             AS "tx_date",
        "value"                                                        AS "amount"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS i,
         LATERAL FLATTEN(input => i."addresses") f

    UNION ALL

    /* combine outputs */
    SELECT
        f.value::STRING                                                AS "address",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))             AS "tx_date",
        "value"                                                        AS "amount"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS o,
         LATERAL FLATTEN(input => o."addresses") f
),
/* keep only transactions in October 2017 */
"oct17" AS (
    SELECT *
    FROM "txs"
    WHERE "tx_date" BETWEEN '2017-10-01' AND '2017-10-31'
),
/* per‑address stats: last tx date in Oct‑2017 and total amount that month */
"addr_stats" AS (
    SELECT
        "address",
        MAX("tx_date")                        AS "last_tx_date",
        SUM("amount")                         AS "total_amount"
    FROM "oct17"
    GROUP BY "address"
),
/* latest day in Oct‑2017 on which any address transacted */
"latest_date" AS (
    SELECT MAX("last_tx_date") AS "global_last_date"
    FROM "addr_stats"
),
/* addresses whose final Oct‑2017 tx happened on that latest day */
"candidates" AS (
    SELECT a.*
    FROM "addr_stats" a
    JOIN "latest_date" l
      ON a."last_tx_date" = l."global_last_date"
)
/* pick address with highest total amount (tie‑broken deterministically by address) */
SELECT "address"
FROM "candidates"
ORDER BY "total_amount" DESC NULLS LAST, "address"
LIMIT 1;