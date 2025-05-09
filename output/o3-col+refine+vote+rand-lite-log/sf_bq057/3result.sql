WITH base_tx AS (   -- all Bitcoin tx mined in 2021
    SELECT 
        "hash"                                      AS tx_hash ,
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6),'YYYY-MM')  AS month_str ,
        TO_NUMBER(TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6),'MM'))        AS month ,
        "input_count",
        "output_count",
        "input_value",
        "output_value"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE "block_timestamp" >= 1609459200000000      -- 2021-01-01
      AND "block_timestamp" <  1640995200000000      -- 2022-01-01
),
dup_tx AS (         -- tx that own ≥2 identical-value outputs
    SELECT "transaction_hash"
    FROM   CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    WHERE  "transaction_hash" IN (SELECT tx_hash FROM base_tx)
    GROUP  BY "transaction_hash", "value"
    HAVING COUNT(*) > 1
),
coinjoin AS (       -- CoinJoin definition
    SELECT b.*
    FROM   base_tx b
    JOIN   dup_tx d            ON d."transaction_hash" = b.tx_hash
    WHERE  b."output_count" > 2
      AND  b."output_value" <= b."input_value"
),
agg_all AS (        -- monthly totals (all tx)
    SELECT month_str,
           month,
           COUNT(*)                AS total_tx,
           SUM("input_count")      AS total_inputs,
           SUM("output_count")     AS total_outputs,
           SUM("output_value")     AS total_volume
    FROM   base_tx
    GROUP  BY month_str, month
),
agg_cj AS (         -- monthly totals (CoinJoin tx)
    SELECT month_str,
           month,
           COUNT(*)                AS cj_tx,
           SUM("input_count")      AS cj_inputs,
           SUM("output_count")     AS cj_outputs,
           SUM("output_value")     AS cj_volume
    FROM   coinjoin
    GROUP  BY month_str, month
),
combined AS (       -- join the two monthly aggregates
    SELECT  a.month,
            a.total_tx,
            a.total_inputs,
            a.total_outputs,
            a.total_volume,
            COALESCE(c.cj_tx,0)      AS cj_tx,
            COALESCE(c.cj_inputs,0)  AS cj_inputs,
            COALESCE(c.cj_outputs,0) AS cj_outputs,
            COALESCE(c.cj_volume,0)  AS cj_volume
    FROM agg_all a
    LEFT JOIN agg_cj c USING (month)
)
SELECT 
       month                                           AS "month_2021",
       ROUND( cj_tx       *100.0 / NULLIF(total_tx,0)        , 1)  AS "pct_tx_coinjoin",
       ROUND( ( (cj_inputs*100.0/NULLIF(total_inputs,0)) 
              + (cj_outputs*100.0/NULLIF(total_outputs,0)) ) / 2 , 1)  AS "pct_utxo_coinjoin",
       ROUND( cj_volume   *100.0 / NULLIF(total_volume,0)    , 1)  AS "pct_volume_coinjoin"
FROM   combined
ORDER  BY "pct_volume_coinjoin" DESC NULLS LAST
LIMIT  1;