WITH txs AS (   -- all bitcoin transactions (inputs + outputs) in Oct-2017, exploded by address
    SELECT  
        f.value::string                     AS "address",
        i."transaction_hash"                AS "tx_hash",
        i."value"::NUMBER                   AS "tx_value",
        TO_DATE( TO_TIMESTAMP(i."block_timestamp" / 1000000) )  AS "tx_date"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS i,
         LATERAL FLATTEN ( input => i."addresses" ) f
    WHERE TO_DATE( TO_TIMESTAMP(i."block_timestamp" / 1000000) )
          BETWEEN '2017-10-01' AND '2017-10-31'

    UNION ALL

    SELECT  
        f.value::string                     AS "address",
        o."transaction_hash"                AS "tx_hash",
        o."value"::NUMBER                   AS "tx_value",
        TO_DATE( TO_TIMESTAMP(o."block_timestamp" / 1000000) )  AS "tx_date"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS o,
         LATERAL FLATTEN ( input => o."addresses" ) f
    WHERE TO_DATE( TO_TIMESTAMP(o."block_timestamp" / 1000000) )
          BETWEEN '2017-10-01' AND '2017-10-31'
),

addr_stats AS (  -- per-address stats within the month
    SELECT
        "address",
        MAX("tx_date")            AS "last_date",
        SUM("tx_value")           AS "total_value"
    FROM txs
    GROUP BY "address"
),

max_last_date AS (   -- latest final-transaction date among all addresses
    SELECT MAX("last_date") AS "latest_oct_date"
    FROM addr_stats
)

SELECT   a."address"
FROM     addr_stats a
JOIN     max_last_date m
       ON a."last_date" = m."latest_oct_date"
ORDER BY a."total_value" DESC NULLS LAST     -- tie-breaker: highest total value
LIMIT 1;