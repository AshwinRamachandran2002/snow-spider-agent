/* Annual difference between
   1) “merged input/output” method (but keeping only the OUTPUT records)
   2) direct TRANSACTIONS table method
   for Bitcoin.                                               */

WITH merged_io AS (          -- merge INPUTS & OUTPUTS, mark their origin
    SELECT  "block_timestamp",
            "value",
            'OUTPUTS'                AS "source"
    FROM    CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    
    UNION ALL
    
    SELECT  "block_timestamp",
            "value",
            'INPUTS'                 AS "source"
    FROM    CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

outputs_yearly AS (          -- yearly average using only OUTPUT records
    SELECT  DATE_TRUNC(
                'year',
                TO_TIMESTAMP("block_timestamp" / 1e6)
            )                               AS "year",
            AVG("value")                    AS "avg_output_value"
    FROM    merged_io
    WHERE   "source" = 'OUTPUTS'            -- keep outputs only
    GROUP BY 1
),

tx_yearly AS (               -- yearly average from TRANSACTIONS table
    SELECT  DATE_TRUNC(
                'year',
                TO_TIMESTAMP("block_timestamp" / 1e6)
            )                               AS "year",
            AVG("output_value")             AS "avg_tx_output_value"
    FROM    CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE   "output_value" IS NOT NULL
    GROUP BY 1
)

SELECT  o."year",
        o."avg_output_value" - t."avg_tx_output_value"  AS "avg_difference"
FROM    outputs_yearly  o
JOIN    tx_yearly       t   ON o."year" = t."year"      -- years present in both
ORDER BY o."year";