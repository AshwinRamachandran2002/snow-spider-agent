WITH txs AS (  -- Bitcoin transactions from Jul‑2023 onward
    SELECT
        "hash"               AS tx_hash,
        "block_timestamp"    AS blk_ts
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" >= 1688169600000000        -- 2023‑07‑01 00:00:00 UTC in µs
),

in_agg AS (      -- aggregate all inputs per transaction
    SELECT
        "transaction_hash"            AS tx_hash,
        SUM("value")                  AS in_value,
        COUNT(*)                      AS in_cnt
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
    WHERE "transaction_hash" IN (SELECT tx_hash FROM txs)
    GROUP BY "transaction_hash"
),

out_agg AS (     -- aggregate all outputs per transaction
    SELECT
        "transaction_hash"            AS tx_hash,
        SUM("value")                  AS out_value,
        COUNT(*)                      AS out_cnt,
        COUNT(DISTINCT "value")       AS distinct_out_vals
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    WHERE "transaction_hash" IN (SELECT tx_hash FROM txs)
    GROUP BY "transaction_hash"
),

tx_stats AS (    -- combine inputs, outputs, and derive CoinJoin flag
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(t.blk_ts/1e6)
        )                              AS month,
        i.in_value,
        i.in_cnt,
        o.out_value,
        o.out_cnt,
        CASE
            WHEN  o.out_cnt > 2                          -- > 2 outputs
               AND o.out_value <= i.in_value             -- output ≤ input value
               AND o.distinct_out_vals < o.out_cnt       -- ≥ 1 duplicate output value
            THEN 1 ELSE 0
        END                             AS is_coinjoin
    FROM txs t
    JOIN in_agg i  ON t.tx_hash = i.tx_hash
    JOIN out_agg o ON t.tx_hash = o.tx_hash
)

SELECT
    month,
    ROUND(100 * SUM(is_coinjoin)::FLOAT / COUNT(*), 4)                                    AS pct_coinjoin_transactions,
    ROUND(
        100 * SUM(CASE WHEN is_coinjoin = 1 THEN in_cnt + out_cnt ELSE 0 END)::FLOAT
        / SUM(in_cnt + out_cnt), 4
    )                                                                                     AS pct_utxos_in_coinjoins,
    ROUND(
        100 * SUM(CASE WHEN is_coinjoin = 1 THEN in_value ELSE 0 END)::FLOAT
        / SUM(in_value), 4
    )                                                                                     AS pct_volume_in_coinjoins
FROM tx_stats
GROUP BY month
ORDER BY month;