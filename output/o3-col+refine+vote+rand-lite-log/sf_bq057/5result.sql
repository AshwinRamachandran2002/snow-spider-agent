WITH tx_2021 AS (   -- all Bitcoin transactions in 2021
    SELECT *
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE "block_timestamp" BETWEEN 1609459200000000    -- 2021-01-01
                              AND 1640995200000000      -- 2022-01-01
),

/* hashes that have at least two outputs of identical value */
equal_out AS (
    SELECT DISTINCT t."hash"
    FROM tx_2021 t,
         LATERAL FLATTEN( INPUT => t."outputs") f
    GROUP BY t."hash",
             f.value:"value"::NUMBER
    HAVING COUNT(*) >= 2
),

/* tag every transaction as CoinJoin (is_cj = 1/0) */
flagged AS (
    SELECT
        t."hash",
        t."block_timestamp",
        t."input_count",
        t."output_count",
        t."input_value",
        t."output_value",
        CASE
            WHEN t."output_count" > 2
             AND t."output_value" <= t."input_value"
             AND eo."hash" IS NOT NULL
            THEN 1 ELSE 0
        END AS "is_cj"
    FROM tx_2021 t
    LEFT JOIN equal_out eo USING ("hash")
),

/* monthly aggregates */
monthly AS (
    SELECT
        TO_NUMBER( TO_CHAR( TO_TIMESTAMP("block_timestamp"/1e6), 'MM') ) AS "month",
        COUNT(*)                                                    AS "tx_total",
        SUM("is_cj")                                                 AS "tx_cj",
        SUM("input_count")                                           AS "utxo_in_total",
        SUM(CASE WHEN "is_cj"=1 THEN "input_count"  END)            AS "utxo_in_cj",
        SUM("output_count")                                          AS "utxo_out_total",
        SUM(CASE WHEN "is_cj"=1 THEN "output_count" END)            AS "utxo_out_cj",
        SUM("output_value")                                          AS "btc_vol_total",
        SUM(CASE WHEN "is_cj"=1 THEN "output_value" END)            AS "btc_vol_cj"
    FROM flagged
    GROUP BY 1
),

/* convert to percentage metrics (rounded to 1 dp) */
percentages AS (
    SELECT
        "month",
        ROUND( "tx_cj"      *100.0/NULLIF("tx_total",        0), 1) AS "pct_tx",
        ROUND( (   "utxo_in_cj"*100.0/NULLIF("utxo_in_total", 0)
                 + "utxo_out_cj"*100.0/NULLIF("utxo_out_total",0)
               )/2 , 1)                                             AS "pct_utxo",
        ROUND( "btc_vol_cj"*100.0/NULLIF("btc_vol_total",    0), 1) AS "pct_volume"
    FROM monthly
)

SELECT
    "month",          -- month number with the highest CoinJoin volume share
    "pct_tx",         -- % of all transactions that were CoinJoin
    "pct_utxo",       -- % of UTXOs involved in CoinJoin (average in/out)
    "pct_volume"      -- % of total BTC volume in CoinJoin transactions
FROM percentages
ORDER BY "pct_volume" DESC NULLS LAST
LIMIT 1;