WITH txs AS (   -- collect every BTC input & output together
    SELECT  
        TO_DATE( TO_TIMESTAMP("block_timestamp" / 1e6) )                AS "tx_date",
        "value"                                                         AS "tx_value",
        addr.value::STRING                                              AS "address"
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS , 
           LATERAL FLATTEN( input => "addresses" ) AS addr

    UNION ALL

    SELECT  
        TO_DATE( TO_TIMESTAMP("block_timestamp" / 1e6) )                AS "tx_date",
        "value"                                                         AS "tx_value",
        addr.value::STRING                                              AS "address"
    FROM   CRYPTO.CRYPTO_BITCOIN.INPUTS , 
           LATERAL FLATTEN( input => "addresses" ) AS addr
),

oct17 AS (   -- keep only October‑2017 transactions
    SELECT *
    FROM   txs
    WHERE  "tx_date" BETWEEN '2017-10-01' AND '2017-10-31'
),

address_stats AS (   -- final date and total value per address
    SELECT
        "address",
        MAX("tx_date")                        AS "last_tx_date",
        SUM("tx_value")                       AS "total_value_oct17"
    FROM   oct17
    GROUP  BY "address"
),

latest_date AS (      -- the latest “last date” in October‑2017
    SELECT MAX("last_tx_date") AS "latest_last_date"
    FROM   address_stats
),

candidates AS (       -- addresses whose final tx occurred on that latest date
    SELECT a.*
    FROM   address_stats  a
    JOIN   latest_date    l
           ON a."last_tx_date" = l."latest_last_date"
)

-- pick the one with the largest total value (ties decided by address)
SELECT
    "address",
    "last_tx_date",
    "total_value_oct17"
FROM   candidates
ORDER  BY "total_value_oct17" DESC NULLS LAST,
          "address"
LIMIT  1;