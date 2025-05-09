WITH filtered_tx AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        t."gas_price",
        t."receipt_gas_used",
        t."block_number",
        /* gas fee in Wei */
        (t."gas_price" * t."receipt_gas_used") AS "fee"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS t
    /* keep only successful txs that landed on 14‑Oct‑2016 (UTC) */
    WHERE t."receipt_status" = 1
      AND DATE_TRUNC(
              'day',
              TO_TIMESTAMP( FLOOR(t."block_timestamp" / 1000000) )   -- micro‑seconds → seconds
          ) = '2016-10-14'
),
tx_with_miner AS (
    SELECT
        f.*,
        b."miner"
    FROM filtered_tx f
    JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS b
      ON b."number" = f."block_number"          -- miner that receives the fees
),
deltas AS (
    /* sender: value sent + fee paid (negative) */
    SELECT
        "from_address" AS "address",
        -("value" + "fee") AS "delta"
    FROM tx_with_miner
    UNION ALL
    /* recipient: value received (positive) */
    SELECT
        "to_address"   AS "address",
        "value"        AS "delta"
    FROM tx_with_miner
    UNION ALL
    /* miner: receives the fee (positive) */
    SELECT
        "miner"        AS "address",
        "fee"          AS "delta"
    FROM tx_with_miner
)
SELECT
    MAX(net_change) AS "MAX_NET_CHANGE",
    MIN(net_change) AS "MIN_NET_CHANGE"
FROM (
    SELECT
        "address",
        SUM("delta") AS net_change
    FROM deltas
    WHERE "address" IS NOT NULL
    GROUP BY "address"
);