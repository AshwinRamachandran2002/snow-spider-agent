/*  Annual difference between two ways of averaging Bitcoin outputs
    1) “Merged” view  : INPUTS ∪ OUTPUTS  ► keep only real OUTPUT rows ► avg(value)
    2) Transactions   :                       avg(output_value)
    Result  =  (1) – (2)   for years that exist in both series               */

WITH merged_io AS (   -- merge tables, tag origin
    SELECT  "block_timestamp",
            "value",
            'output' AS "record_type"
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS

    UNION ALL

    SELECT  "block_timestamp",
            "value",
            'input'  AS "record_type"
    FROM    CRYPTO.CRYPTO_BITCOIN.INPUTS
),

-- keep only OUTPUT rows from the merged set and compute yearly average
yearly_merged_outputs AS (
    SELECT  YEAR( TO_TIMESTAMP_NTZ( "block_timestamp" / 1e6) )   AS "year",
            AVG( "value" )                                       AS "avg_output_value"
    FROM    merged_io
    WHERE   "record_type" = 'output'
    GROUP BY "year"
),

-- yearly average taken directly from Transactions table
yearly_tx_outputs AS (
    SELECT  YEAR( TO_TIMESTAMP_NTZ( "block_timestamp" / 1e6) )   AS "year",
            AVG( "output_value" )                                AS "avg_tx_output_value"
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY "year"
)

SELECT  m."year",
        ROUND( m."avg_output_value" - t."avg_tx_output_value", 4)  AS "difference"
FROM    yearly_merged_outputs   AS m
JOIN    yearly_tx_outputs       AS t   ON m."year" = t."year"
ORDER BY m."year";