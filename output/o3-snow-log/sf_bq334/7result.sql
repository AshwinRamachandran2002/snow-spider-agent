WITH unified_io AS (   -- merge Inputs & Outputs, keep a flag telling where a row came from
    SELECT
        "block_timestamp",
        CAST("value" AS DOUBLE)     AS "value_sats",
        'output'                    AS "io_flag"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    UNION ALL
    SELECT
        "block_timestamp",
        CAST("value" AS DOUBLE)     AS "value_sats",
        'input'                     AS "io_flag"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),

-- yearly average taken from the merged table but only for *output* rows
merged_yearly AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp"/1000000))  AS "year",
        AVG("value_sats")                                           AS "avg_output_value"
    FROM unified_io
    WHERE "io_flag" = 'output'
      AND "value_sats" IS NOT NULL
    GROUP BY "year"
),

-- yearly average taken directly from the transactions table
tx_yearly AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp"/1000000))  AS "year",
        AVG(CAST("output_value" AS DOUBLE))                         AS "avg_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "output_value" IS NOT NULL
    GROUP BY "year"
)

-- final comparison: only years present in *both* methods
SELECT
    m."year",
    m."avg_output_value" - t."avg_output_value"      AS "difference_merged_minus_tx"
FROM merged_yearly  m
JOIN tx_yearly      t
  ON m."year" = t."year"
ORDER BY m."year" ASC NULLS LAST;