WITH date_filtered AS (   -- all successful ETC transactions on 14‑Oct‑2016 (UTC)
    SELECT
        "block_number",
        "from_address",
        "to_address",
        COALESCE("value",0)          AS "value",
        COALESCE("gas_price",0)      AS "gas_price",
        COALESCE("receipt_gas_used",0) AS "gas_used"
    FROM   CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS"
    WHERE  "block_timestamp" >= 1476403200000000        -- 2016‑10‑14 00:00:00 UTC
       AND "block_timestamp" <  1476489600000000        -- 2016‑10‑15 00:00:00 UTC
       AND "receipt_status" = 1                         -- only successful txs
),
credits AS (          -- funds received
    SELECT "to_address"   AS "address",
           SUM("value")   AS "in_val"
    FROM   date_filtered
    GROUP  BY "to_address"
),
debits AS (           -- funds sent  +  fees paid
    SELECT "from_address"                                       AS "address",
           SUM("value" + "gas_price" * "gas_used")              AS "out_val"
    FROM   date_filtered
    GROUP  BY "from_address"
),
miner_fees AS (       -- fees earned by miners
    SELECT  b."miner"                                         AS "address",
            SUM(df."gas_price" * df."gas_used")               AS "fee_income"
    FROM    date_filtered df
    JOIN    CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS" b
           ON df."block_number" = b."number"
    GROUP   BY b."miner"
),
net AS (              -- net balance change per address
    SELECT
        COALESCE(c."address", d."address", m."address")                        AS "address",
        COALESCE(c."in_val",0)
      - COALESCE(d."out_val",0)
      + COALESCE(m."fee_income",0)                                             AS "net_change"
    FROM credits      c
    FULL JOIN debits  d ON c."address" = d."address"
    FULL JOIN miner_fees m ON COALESCE(c."address", d."address") = m."address"
)
SELECT
    MAX("net_change") AS "max_net_change",
    MIN("net_change") AS "min_net_change"
FROM   net;