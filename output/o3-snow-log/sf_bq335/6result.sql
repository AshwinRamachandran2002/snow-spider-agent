WITH union_txs AS (                        -- combine every bitcoin input & output
    SELECT
        "block_timestamp"      AS blk_ts ,
        "value"                AS btc_value ,
        "addresses"            AS addrs_var
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS

    UNION ALL

    SELECT
        "block_timestamp"      AS blk_ts ,
        "value"                AS btc_value ,
        "addresses"            AS addrs_var
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),

oct_txs AS (                               -- keep only October-2017 rows and explode address arrays
    SELECT
        DATE( TO_TIMESTAMP( blk_ts / 1000000 ) )                      AS tx_date ,
        btc_value ,
        addr.value::STRING                                            AS btc_address
    FROM   union_txs ,
           LATERAL FLATTEN( INPUT => addrs_var )  AS addr
    WHERE  DATE( TO_TIMESTAMP( blk_ts / 1000000 ) )
           BETWEEN '2017-10-01' AND '2017-10-31'
),

last_tx_per_addr AS (                      -- each address’ final tx-date in Oct-2017
    SELECT
        btc_address ,
        MAX( tx_date )  AS last_tx_date
    FROM   oct_txs
    GROUP BY btc_address
),

overall_latest_date AS (                   -- latest such date across all addresses
    SELECT MAX( last_tx_date ) AS latest_date
    FROM   last_tx_per_addr
),

latest_day_addresses AS (                  -- addresses whose final tx happens on that latest date
    SELECT l.btc_address
    FROM   last_tx_per_addr  l
    JOIN   overall_latest_date o
           ON l.last_tx_date = o.latest_date
),

value_sum AS (                             -- total Oct-2017 value for those addresses
    SELECT
        btc_address ,
        SUM( btc_value ) AS total_oct_value
    FROM   oct_txs
    WHERE  btc_address IN ( SELECT btc_address FROM latest_day_addresses )
    GROUP BY btc_address
)

SELECT
    btc_address                                     AS "BITCOIN_ADDRESS" ,
    total_oct_value                                 AS "TOTAL_OCT_2017_VALUE_BTC" ,
    ( SELECT latest_date FROM overall_latest_date ) AS "LATEST_TX_DATE"
FROM   value_sum
ORDER  BY total_oct_value DESC NULLS LAST
LIMIT  1;