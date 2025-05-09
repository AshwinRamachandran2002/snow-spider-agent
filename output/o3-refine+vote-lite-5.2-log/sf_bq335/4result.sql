WITH tx_addresses AS (
    /*  October‑2017 Bitcoin OUTPUTS  */
    SELECT
        addr.value::STRING              AS "ADDRESS",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "TX_DATE",
        "value"                         AS "AMOUNT"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS o,
         LATERAL FLATTEN(input => o."addresses") addr
    WHERE TO_CHAR(TO_TIMESTAMP(o."block_timestamp" / 1000000), 'YYYY-MM') = '2017-10'

    UNION ALL

    /*  October‑2017 Bitcoin INPUTS  */
    SELECT
        addr.value::STRING              AS "ADDRESS",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "TX_DATE",
        "value"                         AS "AMOUNT"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS i,
         LATERAL FLATTEN(input => i."addresses") addr
    WHERE TO_CHAR(TO_TIMESTAMP(i."block_timestamp" / 1000000), 'YYYY-MM') = '2017-10'
),

addr_stats AS (   /*  last‑transaction date and total value per address  */
    SELECT
        "ADDRESS",
        MAX("TX_DATE")         AS "LAST_DATE",
        SUM("AMOUNT")          AS "TOTAL_VALUE"
    FROM tx_addresses
    GROUP BY "ADDRESS"
),

latest_day_addrs AS (   /*  addresses whose final tx is on the very latest day in Oct‑2017  */
    SELECT *
    FROM   addr_stats
    WHERE  "LAST_DATE" = (SELECT MAX("LAST_DATE") FROM addr_stats)
)

SELECT
    "ADDRESS",
    "LAST_DATE",
    "TOTAL_VALUE"
FROM latest_day_addrs
ORDER BY "TOTAL_VALUE" DESC NULLS LAST
LIMIT 1;