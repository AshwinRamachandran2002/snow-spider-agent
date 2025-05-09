WITH merged_io AS (   -- combine inputs & outputs, tagging each row
    SELECT 'OUTPUT' AS "src", "block_number", "value"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    UNION ALL
    SELECT 'INPUT'  AS "src", "block_number", "value"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),

merged_avg AS (       -- yearly avg for *only* the OUTPUT rows
    SELECT
        EXTRACT(year FROM b."timestamp_month")         AS "year",
        AVG(m."value")                                 AS "avg_merged_outputs"
    FROM merged_io                        m
    JOIN CRYPTO.CRYPTO_BITCOIN.BLOCKS     b
          ON m."block_number" = b."number"
    WHERE m."src" = 'OUTPUT'
    GROUP BY 1
),

tx_avg AS (           -- yearly avg using transactions table
    SELECT
        EXTRACT(year FROM "block_timestamp_month")     AS "year",
        AVG("output_value")                            AS "avg_tx_outputs"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY 1
)

SELECT
    m."year",
    m."avg_merged_outputs" - t."avg_tx_outputs"        AS "merged_minus_tx_avg"
FROM merged_avg m
JOIN tx_avg     t USING ("year")
ORDER BY m."year";