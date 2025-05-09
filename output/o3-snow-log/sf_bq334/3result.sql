WITH merged_io AS (          -- 1) merge INPUTS & OUTPUTS tables
    SELECT 
        "block_timestamp",
        "value",
        'output' AS "record_type"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    
    UNION ALL
    
    SELECT 
        "block_timestamp",
        "value",
        'input'  AS "record_type"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

output_yearly AS (           -- 2) keep only OUTPUT records & get yearly averages
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG(CAST("value" AS FLOAT))                                  AS "avg_output_value"
    FROM merged_io
    WHERE "record_type" = 'output'
      AND "block_timestamp" IS NOT NULL
      AND "value" IS NOT NULL
    GROUP BY "year"
),

tx_yearly AS (               -- 3) yearly averages from TRANSACTIONS table
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG(CAST("output_value" AS FLOAT))                           AS "avg_tx_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE "block_timestamp" IS NOT NULL
      AND "output_value" IS NOT NULL
    GROUP BY "year"
)

-- 4) difference (merged-outputs avg − transactions avg), only for common years
SELECT
    o."year",
    o."avg_output_value" - t."avg_tx_output_value" AS "difference_output_minus_tx"
FROM output_yearly o
JOIN tx_yearly   t
  ON o."year" = t."year"
ORDER BY o."year" ASC;