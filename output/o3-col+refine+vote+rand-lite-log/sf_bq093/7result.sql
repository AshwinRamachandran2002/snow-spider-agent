/*  Net-balance extremes for all Ethereum-Classic addresses on
    14-Oct-2016 (UTC), incorporating
      • credits  = incoming “value”
      • debits   = outgoing “value” + gas-fee paid
      • miner revenue = gas-fee earned per block                       */

WITH tx AS (
    SELECT  "from_address",
            "to_address",
            "value",
            "gas_price",
            "receipt_gas_used",
            "block_number"
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
    WHERE   "receipt_status" = 1
      AND   CAST( TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE ) = '2016-10-14'
), ------------------------------------------------------
senders AS (          -- out-flows (negative)
    SELECT  "from_address"               AS "address",
            SUM( - "value"
                 - ("gas_price" * "receipt_gas_used") )  AS "net_change"
    FROM    tx
    GROUP BY  "from_address"
), ------------------------------------------------------
receivers AS (        -- in-flows (positive)
    SELECT  "to_address"                 AS "address",
            SUM( "value" )               AS "net_change"
    FROM    tx
    GROUP BY  "to_address"
), ------------------------------------------------------
block_fees AS (       -- total gas fee per block
    SELECT  "block_number",
            SUM( "gas_price" * "receipt_gas_used" ) AS "block_fee"
    FROM    tx
    GROUP BY "block_number"
), ------------------------------------------------------
miners AS (           -- miners’ fee revenue
    SELECT  b."miner"                     AS "address",
            SUM( f."block_fee" )          AS "net_change"
    FROM    block_fees            f
    JOIN    CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS  b
           ON b."number" = f."block_number"
    WHERE   CAST( TO_TIMESTAMP_NTZ(b."timestamp" / 1000000) AS DATE ) = '2016-10-14'
    GROUP BY b."miner"
), ------------------------------------------------------
all_changes AS (      -- combine everything
    SELECT * FROM senders
    UNION ALL
    SELECT * FROM receivers
    UNION ALL
    SELECT * FROM miners
)
SELECT  MAX("net_change") AS "max_positive_change",
        MIN("net_change") AS "max_negative_change"
FROM    all_changes;