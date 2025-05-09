/*  Monthly Coin-Join footprint in the Bitcoin network (since 1-Jul-2023)
    – Coin-Join definition:
        • more than 2 outputs
        • total "output_value" ≤ "input_value"
        • ≥ 1 duplicate output amount ( ≥2 identical “value” fields )
    – Metrics delivered per month (UTC):
        1. pct_tx_coinjoin     – Coin-Join tx share of total tx count
        2. pct_utxos_coinjoin  – Coin-Join-touched UTXOs (inputs+outputs) share
        3. pct_volume_coinjoin – Coin-Join share of total input value
*/
WITH
/*-------------- parameters ----------------*/
params AS (
    SELECT 1688169600000000::NUMBER AS start_ts   -- 2023-07-01 00:00:00 UTC (µs)
),

/*-------------- transactions that have ≥2 identical-value outputs ------------*/
cj_dup AS (
    SELECT
        t."hash"
    FROM  CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS  t,
          LATERAL FLATTEN( INPUT => t."outputs") o                -- each output object
    ,     params
    WHERE t."block_timestamp" >= params.start_ts
    GROUP BY t."hash"
    HAVING COUNT(*) > COUNT(DISTINCT (o.value:"value")::STRING)   -- duplicates exist
),

/*-------------- bring all needed transaction data & flag Coin-Join ------------*/
base AS (
    SELECT
        t."hash",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(t."block_timestamp" / 1e6)
        )                                   AS tx_month,
        t."input_count",
        t."output_count",
        (t."input_count"  + t."output_count")           AS utxo_cnt,     -- UTXOs touched
        t."input_value",
        t."output_value",
        CASE
            WHEN   t."output_count" > 2
               AND t."output_value" <= t."input_value"
               AND cj."hash" IS NOT NULL
            THEN 1
        END                                AS is_cj
    FROM  CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS  t
    LEFT JOIN cj_dup cj  ON cj."hash" = t."hash"
    ,     params
    WHERE t."block_timestamp" >= params.start_ts
),

/*-------------- aggregate monthly totals & Coin-Join subsets ------------------*/
agg AS (
    SELECT
        tx_month,
        COUNT(*)                                           AS total_tx,
        SUM(utxo_cnt)                                      AS total_utxos,
        SUM("input_value")                                 AS total_volume,
        SUM(CASE WHEN is_cj = 1 THEN 1            END)     AS cj_tx,
        SUM(CASE WHEN is_cj = 1 THEN utxo_cnt     END)     AS cj_utxos,
        SUM(CASE WHEN is_cj = 1 THEN "input_value" END)    AS cj_volume
    FROM   base
    GROUP  BY tx_month
)

/*-------------- final monthly percentages ------------------------------------*/
SELECT
    tx_month                              AS "month_utc",
    ROUND( cj_tx    * 100.0 / NULLIF(total_tx   ,0), 4)  AS pct_tx_coinjoin,
    ROUND( cj_utxos * 100.0 / NULLIF(total_utxos,0), 4)  AS pct_utxos_coinjoin,
    ROUND( cj_volume* 100.0 / NULLIF(total_volume,0), 4) AS pct_volume_coinjoin
FROM   agg
ORDER  BY tx_month;