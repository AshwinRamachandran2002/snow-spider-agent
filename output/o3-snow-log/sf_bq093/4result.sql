/*  Maximum and minimum net balance changes (in wei) for ETC addresses on
    14-Oct-2016 (UTC)                                                     */
WITH tx_day AS (       -- successful external transactions on 2016-10-14
    SELECT  "hash",
            "block_number",
            "from_address",
            "to_address",
            COALESCE("value",0)                              AS val,
            COALESCE("gas_price",0) * COALESCE("receipt_gas_used",0) AS fee
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
    WHERE   "receipt_status" = 1
      AND   "block_timestamp" >= 1476403200000000     -- 2016-10-14 00:00 UTC
      AND   "block_timestamp" <  1476489600000000     -- 2016-10-15 00:00 UTC
),
balance_flows AS (      -- sender, receiver, miner flows
    SELECT  t."from_address"       AS address,
            -(val + fee)           AS change
    FROM    tx_day t
    WHERE   t."from_address" IS NOT NULL

    UNION ALL
    SELECT  t."to_address"         AS address,
            val                    AS change
    FROM    tx_day t
    WHERE   t."to_address" IS NOT NULL

    UNION ALL
    SELECT  b."miner"              AS address,
            fee                    AS change
    FROM    tx_day t
    JOIN    CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS b
           ON b."number" = t."block_number"
    WHERE   b."miner" IS NOT NULL
),
net_changes AS (        -- net change per address
    SELECT  address,
            SUM(change) AS net_change
    FROM    balance_flows
    GROUP BY address
)
SELECT  MAX(net_change) AS max_net_change_wei,
        MIN(net_change) AS min_net_change_wei
FROM    net_changes;