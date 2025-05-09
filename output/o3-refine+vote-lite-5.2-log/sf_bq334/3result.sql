WITH
/* yearly average of output values obtained from the merged INPUTS/OUTPUTS
   (after the merge we keep only rows that originally came from OUTPUTS) */
avg_outputs AS (
    SELECT
        DATE_TRUNC('year',
                   TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
        )                                                      AS "year",
        AVG("value")                                           AS "avg_value_outputs"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    GROUP BY 1
),
/* yearly average of output values recorded in the TRANSACTIONS table */
avg_tx AS (
    SELECT
        DATE_TRUNC('year',
                   TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
        )                                                      AS "year",
        AVG("output_value")                                    AS "avg_value_tx"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP BY 1
)
/* difference between the two methods for years common to both */
SELECT
    o."year",
    o."avg_value_outputs" - t."avg_value_tx" AS "difference_outputs_minus_tx"
FROM avg_outputs o
JOIN avg_tx     t
  ON o."year" = t."year"
ORDER BY o."year";