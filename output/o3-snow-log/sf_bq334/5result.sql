WITH merged_io AS (
    /* 1.  merge INPUTS and OUTPUTS but keep only OUTPUT rows */
    SELECT 
        /* convert micro-second epoch to timestamp then truncate to the year */
        DATE_TRUNC('year', TO_TIMESTAMP("block_timestamp" / 1e6))                       AS "year_ts",
        /* cast to numeric for aggregation */
        CAST("value" AS FLOAT)                                                          AS "value"
    FROM (
        /* tag rows so we can filter after the UNION ALL */
        SELECT 'OUTPUT' AS "src", "block_timestamp", "value"
        FROM   CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
        
        UNION ALL
        
        SELECT 'INPUT'  AS "src", "block_timestamp", "value"
        FROM   CRYPTO.CRYPTO_BITCOIN."INPUTS"
    )
    WHERE "src" = 'OUTPUT'          -- keep only OUTPUT rows
),
merged_yearly AS (
    SELECT 
        YEAR("year_ts")                                AS "year",
        AVG("value")                                   AS "merged_outputs_avg"
    FROM   merged_io
    GROUP  BY "year"
),
tx_yearly AS (
    /* 2.  yearly average taken directly from TRANSACTIONS.output_value */
    SELECT
        YEAR(DATE_TRUNC('year', TO_TIMESTAMP("block_timestamp" / 1e6))) AS "year",
        AVG(CAST("output_value" AS FLOAT))                               AS "tx_outputs_avg"
    FROM   CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE  "output_value" IS NOT NULL
    GROUP  BY "year"
)
SELECT
    m."year",
    /* 3.  difference between the two methods */
    m."merged_outputs_avg" - t."tx_outputs_avg"       AS "difference"
FROM       merged_yearly  m
INNER JOIN tx_yearly      t
        ON m."year" = t."year"
ORDER BY    m."year";