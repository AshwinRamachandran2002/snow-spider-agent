WITH etctxs AS (   -- all successful external transactions on 14 Oct 2016
    SELECT  t."hash",
            t."from_address"                                                          AS sender,
            COALESCE(t."to_address", t."receipt_contract_address")                    AS receiver,
            t."value"                                                                 AS val,
            t."gas_price" * t."receipt_gas_used"                                      AS gas_fee,
            b."miner"                                                                 AS miner
    FROM   CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS  t
           JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS  b
                 ON  t."block_hash" = b."hash"
    WHERE  t."receipt_status" = 1                      -- successful only
      AND  TO_DATE(TO_TIMESTAMP(t."block_timestamp" / 1000000)) = '2016-10-14'
),
entries AS (       -- three balance‑change rows per transaction
    SELECT sender              AS address ,       -(val + gas_fee)            AS delta  FROM etctxs
    UNION ALL
    SELECT receiver            AS address ,        val                        AS delta  FROM etctxs WHERE receiver IS NOT NULL
    UNION ALL
    SELECT miner               AS address ,        gas_fee                    AS delta  FROM etctxs
),
agg AS (
    SELECT   address , SUM(delta) AS net_change
    FROM     entries
    GROUP BY address
)
SELECT  MAX(net_change) AS max_net_change ,
        MIN(net_change) AS min_net_change
FROM    agg;