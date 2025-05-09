/* Annual difference in Bitcoin output-value averages  
   – Method 1:  “Merged” INPUTS ∪ OUTPUTS table, but restricted to OUTPUT records  
   – Method 2:  Directly from TRANSACTIONS."output_value"  
   Result: years present in BOTH methods, with (avg_out ‑ avg_tx) difference            */

WITH merged_io AS (               -- step-1  merge INPUTS and OUTPUTS, tag the source
    SELECT
        "block_timestamp",
        "value"      ::FLOAT        AS "value",
        'outputs'    AS src
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS

    UNION ALL

    SELECT
        "block_timestamp",
        NULL         ::FLOAT        AS "value",   -- inputs have no output-value
        'inputs'     AS src
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),

outs AS (                         -- step-2  yearly averages from OUTPUT records only
    SELECT
        DATE_TRUNC('year', TO_TIMESTAMP("block_timestamp" / 1000000))  AS yr,
        AVG("value")                                                   AS avg_out
    FROM merged_io
    WHERE src = 'outputs'
    GROUP BY 1
),

txs AS (                          -- step-3  yearly averages from TRANSACTIONS
    SELECT
        DATE_TRUNC('year', TO_TIMESTAMP("block_timestamp" / 1000000))  AS yr,
        AVG("output_value") ::FLOAT                                    AS avg_tx
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY 1
)

-- step-4  intersecting years & compute difference
SELECT
    o.yr                                           AS "year",
    o.avg_out                                      AS "avg_outputs_value",
    t.avg_tx                                       AS "avg_tx_output_value",
    o.avg_out - t.avg_tx                           AS "difference"
FROM outs o
JOIN txs  t
  ON o.yr = t.yr
ORDER BY o.yr;