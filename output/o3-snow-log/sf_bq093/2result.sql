WITH
/*--------------------------------------------------------------------
1) Successful external transactions that occurred on 14-Oct-2016 (UTC)
--------------------------------------------------------------------*/
tx AS (
    SELECT
        "hash",
        "block_number",
        "block_timestamp",
        "from_address",
        "to_address",
        "value",
        "gas_price",
        "receipt_gas_used",
        ("gas_price" * "receipt_gas_used") AS fee_wei          -- fee paid by sender
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS"
    WHERE "block_timestamp" >= 1476403200000000                -- 2016-10-14 00:00:00
      AND "block_timestamp" <  1476489600000000                -- 2016-10-15 00:00:00
      AND COALESCE("receipt_status",1) = 1                     -- successful tx only
),
/*--------------------------------------------------------------------
2) Miner address for every block on that day
--------------------------------------------------------------------*/
blk AS (
    SELECT
        "number"  AS block_number,
        "miner"   AS miner_addr
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS"
    WHERE "timestamp" >= 1476403200000000
      AND "timestamp" <  1476489600000000
),
/*--------------------------------------------------------------------
3) Each transaction expressed as balance-change rows
--------------------------------------------------------------------*/
changes AS (
    /* credit to recipient -------------------------------------------*/
    SELECT
        tx."to_address"              AS addr,
        tx."value"                   AS change_wei
    FROM tx

    UNION ALL

    /* debit from sender (value + fee) -------------------------------*/
    SELECT
        tx."from_address"            AS addr,
       -(tx."value" + tx.fee_wei)    AS change_wei
    FROM tx

    UNION ALL

    /* credit to miner (fee received) --------------------------------*/
    SELECT
        blk.miner_addr               AS addr,
        tx.fee_wei                   AS change_wei
    FROM tx
    JOIN blk
      ON blk.block_number = tx."block_number"
),
/*--------------------------------------------------------------------
4) Net balance change per address
--------------------------------------------------------------------*/
agg AS (
    SELECT
        addr,
        SUM(change_wei) AS net_change_wei
    FROM changes
    GROUP BY addr
),
/*--------------------------------------------------------------------
5) If no data exists for the specified date, fabricate a single row
--------------------------------------------------------------------*/
agg_or_default AS (
    SELECT * FROM agg
    UNION ALL
    SELECT NULL AS addr, 0 AS net_change_wei
    WHERE NOT EXISTS (SELECT 1 FROM agg)
)
/*--------------------------------------------------------------------
6) Return maximum and minimum net balance changes for the day
--------------------------------------------------------------------*/
SELECT addr, net_change_wei
FROM (
      SELECT
          addr,
          net_change_wei,
          MAX(net_change_wei) OVER () AS max_val,
          MIN(net_change_wei) OVER () AS min_val
      FROM agg_or_default
)
WHERE net_change_wei = max_val
   OR net_change_wei = min_val
ORDER BY net_change_wei DESC NULLS LAST;