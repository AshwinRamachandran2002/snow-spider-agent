WITH combined AS (
    SELECT
        'output'                                                  AS "src",
        TO_NUMBER("value")                                        AS "value",
        "block_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"

    UNION ALL

    SELECT
        'input'                                                   AS "src",
        TO_NUMBER("value")                                        AS "value",
        "block_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

-- yearly average derived from the merged input/output set, keeping only output records
outputs_avg AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000))      AS "year",
        AVG("value")                                                      AS "merged_output_avg"
    FROM combined
    WHERE "src" = 'output'
    GROUP BY "year"
),

-- yearly average taken directly from the transactions table
tx_avg AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000))      AS "year",
        AVG(TO_NUMBER("output_value"))                                    AS "tx_output_avg"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP BY "year"
)

-- final difference (only years present in both data sets)
SELECT
    o."year",
    o."merged_output_avg",
    t."tx_output_avg",
    o."merged_output_avg" - t."tx_output_avg"                            AS "difference"
FROM outputs_avg o
JOIN tx_avg    t USING ("year")
ORDER BY o."year";