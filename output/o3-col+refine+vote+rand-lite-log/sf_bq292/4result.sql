/*  -------------------------------------------------------------------------------------------------
    Monthly CoinJoin share (Tx count, UTXO count and volume) in the Bitcoin network
    –  CoinJoin definition  :  Tx has >2 outputs  AND  at least two outputs share the same value
    –  Period               :  blocks whose timestamps  ≥ 1-Jul-2023   ( 1688169600000000 µs )
    –  Data source          :  CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS  (plus a lateral flatten on “outputs”)
---------------------------------------------------------------------------------------------------*/
WITH base_tx AS (               --  limit to the period we analyse and keep the fields we need
    SELECT
        "hash",
        TO_TIMESTAMP("block_timestamp"/1e6)                               AS ts,
        DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp"/1e6))          AS month,
        "input_count",
        "output_count",
        "input_value",
        "output_value",
        "outputs"
    FROM  CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000      -- 1-Jul-2023 00:00:00 UTC in µs
),

/* -------------------------------------------------------------
   Detect CoinJoin transactions (same-value outputs, >2 outputs)
--------------------------------------------------------------*/
coinjoin_hashes AS (
    SELECT
        b."hash"
    FROM   base_tx AS b,
           LATERAL FLATTEN ( INPUT => b."outputs" ) f           -- explode outputs array
    GROUP BY
        b."hash",
        b."output_count"
    HAVING
        b."output_count" > 2                                   -- more than 2 outputs
        AND COUNT(DISTINCT f.value:"value"::NUMBER)  <  b."output_count"  -- at least one duplicate value
),

/* -------------------------------------------------------------
   Aggregate network-wide and CoinJoin-only statistics per month
--------------------------------------------------------------*/
stats AS (
    SELECT
        bt.month,

        /* network totals ---------------------------------------------------*/
        COUNT(*)                                AS total_tx,
        SUM(bt."input_count")                   AS total_inputs,      -- UTXOs spent
        SUM(bt."output_count")                  AS total_outputs,     -- UTXOs created
        SUM(bt."input_value")                   AS total_volume_sat,  -- satoshis

        /* CoinJoin totals ---------------------------------------------------*/
        COUNT(            CASE WHEN cj."hash" IS NOT NULL THEN 1 END)                AS cj_tx,
        SUM( bt."input_count"  * (cj."hash" IS NOT NULL)::INT )                      AS cj_inputs,
        SUM( bt."output_count" * (cj."hash" IS NOT NULL)::INT )                      AS cj_outputs,
        SUM( bt."input_value"  * (cj."hash" IS NOT NULL)::INT )                      AS cj_volume_sat

    FROM            base_tx        AS bt
    LEFT JOIN       coinjoin_hashes AS cj   ON bt."hash" = cj."hash"
    GROUP BY        bt.month
)

/* -------------------------------------------------------------
   Final percentages
--------------------------------------------------------------*/
SELECT
    month,

    /* 1) % of transactions that are CoinJoins --------------------------------*/
    ROUND( cj_tx * 100.0 / NULLIF(total_tx,0), 4 )                AS pct_coinjoin_transactions,

    /* 2) % of UTXOs involved in CoinJoins ------------------------------------*/
    ROUND( (cj_inputs + cj_outputs) * 100.0
           / NULLIF( total_inputs + total_outputs , 0 ), 4 )      AS pct_coinjoin_utxos,

    /* 3) % of transaction volume in CoinJoins -------------------------------*/
    ROUND( cj_volume_sat * 100.0 / NULLIF(total_volume_sat,0), 4) AS pct_coinjoin_volume

FROM   stats
ORDER BY month;