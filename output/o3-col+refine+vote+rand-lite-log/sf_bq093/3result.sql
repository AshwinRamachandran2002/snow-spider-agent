/*  Maximum & minimum net balance changes for ETC addresses on 14-Oct-2016  */
WITH day_bounds AS (
    SELECT
        TO_TIMESTAMP_NTZ('2016-10-14') AS day_start ,
        TO_TIMESTAMP_NTZ('2016-10-15') AS day_end
),
/* ---------- filter successful external transactions for the date ---------- */
tx_filtered AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        t."gas_price",
        t."receipt_gas_used",
        t."block_number",
        (t."gas_price" * t."receipt_gas_used")           AS fee
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS" t
    JOIN day_bounds d
          ON  d.day_start <= TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6)
          AND TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6) < d.day_end
    WHERE t."receipt_status" = 1          -- only successful txns
),
/* ---------------------- out-flow (value + fee paid) ----------------------- */
outflow AS (
    SELECT
        "from_address"               AS address,
        SUM( COALESCE("value",0) + COALESCE(fee,0) )  AS out_amt
    FROM tx_filtered
    GROUP BY "from_address"
),
/* -------------------------- in-flow (value recv) -------------------------- */
inflow AS (
    SELECT
        "to_address"                 AS address,
        SUM( COALESCE("value",0) )   AS in_amt
    FROM tx_filtered
    GROUP BY "to_address"
),
/* ------- miner rewards: aggregate fees of blocks they produced ------------ */
miner_fee AS (
    SELECT
        b."miner"                    AS address,
        SUM( COALESCE(tf.fee,0) )    AS in_amt
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS" b
    JOIN day_bounds d
          ON  d.day_start <= TO_TIMESTAMP_NTZ(b."timestamp" / 1e6)
          AND TO_TIMESTAMP_NTZ(b."timestamp" / 1e6) < d.day_end
    LEFT JOIN tx_filtered tf
           ON tf."block_number" = b."number"
    GROUP BY b."miner"
),
/* --------------------- combine to net balance change ---------------------- */
balances AS (
    SELECT
        COALESCE(i.address, o.address, m.address)                    AS address,
        COALESCE(i.in_amt,0) + COALESCE(m.in_amt,0)                  AS total_inflow,
        COALESCE(o.out_amt,0)                                        AS total_outflow,
        COALESCE(i.in_amt,0) + COALESCE(m.in_amt,0) - COALESCE(o.out_amt,0)  AS net_change
    FROM outflow o
    FULL OUTER JOIN inflow    i ON i.address = o.address
    FULL OUTER JOIN miner_fee m ON COALESCE(i.address, o.address) = m.address
)
/* ---------------------- return required extremes -------------------------- */
SELECT
    MAX(net_change) AS "max_net_change",
    MIN(net_change) AS "min_net_change"
FROM balances;