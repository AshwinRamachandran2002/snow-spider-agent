WITH btc_oct17_tx AS (
    /* all input-address transactions in Oct‑2017 */
    SELECT
        ("addresses")[0]::string                              AS "address",
        "value"                                               AS "amount",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))    AS "tx_date"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
    WHERE "block_timestamp" BETWEEN 1506816000000000            /* 2017‑10‑01 00:00:00 UTC */
                               AND     1509494399000000          /* 2017‑10‑31 23:59:59 UTC */
          AND "addresses" IS NOT NULL

    UNION ALL

    /* all output-address transactions in Oct‑2017 */
    SELECT
        ("addresses")[0]::string                              AS "address",
        "value"                                               AS "amount",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))    AS "tx_date"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    WHERE "block_timestamp" BETWEEN 1506816000000000
                               AND     1509494399000000
          AND "addresses" IS NOT NULL
),

addr_stats AS (
    /* per‑address statistics within October 2017 */
    SELECT
        "address",
        MAX("tx_date")                     AS "last_tx_date",
        SUM("amount")                      AS "total_value_oct17"
    FROM btc_oct17_tx
    GROUP BY "address"
),

latest_date AS (
    /* the latest October date on which any address transacted */
    SELECT MAX("last_tx_date") AS "max_last_date"
    FROM addr_stats
),

candidates AS (
    /* addresses whose final October tx occurred on that latest date */
    SELECT  a.*
    FROM    addr_stats  a
    JOIN    latest_date d
           ON a."last_tx_date" = d."max_last_date"
)

SELECT
    "address",
    "last_tx_date",
    "total_value_oct17"
FROM candidates
ORDER BY "total_value_oct17" DESC NULLS LAST, "address"
LIMIT 1;