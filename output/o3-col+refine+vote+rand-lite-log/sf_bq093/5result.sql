/*  Maximum and minimum net balance changes (in wei) for all Ethereum Classic
    addresses on 2016-10-14 UTC.  Net change = value received
    – (value + gas) sent + gas fees earned by miners.                       */

WITH date_blocks AS (               -- ETC blocks produced on 2016-10-14
    SELECT  "number"       AS "block_number",
            "miner"
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS"
    WHERE   "timestamp" >= 1476403200000000        -- 2016-10-14 00:00:00 UTC
      AND   "timestamp" <  1476489600000000        -- 2016-10-15 00:00:00 UTC
),
tx AS (                              -- successful top-level transactions that
    SELECT  t."from_address",
            t."to_address",
            t."value",
            COALESCE(t."gas_price",0) * COALESCE(t."receipt_gas_used",0)
                  AS "gas_fee",
            t."block_number"
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS" t
    JOIN    date_blocks b
           ON t."block_number" = b."block_number"
    WHERE   t."receipt_status" = 1
),
addr_changes AS (                    -- three legs of value movement
    /* 1) credits to receivers */
    SELECT  "to_address"                     AS addr,
            SUM("value")                    AS change
    FROM    tx
    WHERE   "to_address" IS NOT NULL
    GROUP  BY "to_address"

    UNION ALL
    /* 2) debits from senders (value + gas) */
    SELECT  "from_address"                   AS addr,
            SUM(-( "value" + "gas_fee"))    AS change
    FROM    tx
    WHERE   "from_address" IS NOT NULL
    GROUP  BY "from_address"

    UNION ALL
    /* 3) gas fees credited to miners */
    SELECT  b."miner"                        AS addr,
            SUM(t."gas_fee")                AS change
    FROM    tx t
    JOIN    date_blocks b
           ON t."block_number" = b."block_number"
    GROUP  BY b."miner"
),
net_per_addr AS (                    -- aggregate to net balance per address
    SELECT  addr,
            SUM(change) AS net_change
    FROM    addr_changes
    GROUP  BY addr
)
SELECT
    MAX(net_change) AS max_net_change,
    MIN(net_change) AS min_net_change
FROM   net_per_addr;