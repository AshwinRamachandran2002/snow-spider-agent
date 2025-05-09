/*  Max & Min net balance change for Ethereum Classic addresses on 14-Oct-2016 (UTC) */

WITH
/*------------------------------------------------------------------
  1. All successful (status = 1) top-level transactions of the day
------------------------------------------------------------------*/
filtered_tx AS (
    SELECT
        "from_address",
        "to_address",
        "value",
        "gas_price",
        "receipt_gas_used",
        "block_number"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
    WHERE "block_timestamp"
          BETWEEN 1476403200000000        -- 2016-10-14 00:00:00 UTC
              AND 1476489599999999        -- 2016-10-14 23:59:59 UTC
      AND "receipt_status" = 1            -- only successful tx
),

/*------------------------------------------------------------------
  2. Credits (funds received)
------------------------------------------------------------------*/
credits AS (
    SELECT
        "to_address"        AS address,
        SUM("value")        AS credits
    FROM filtered_tx
    WHERE "to_address" IS NOT NULL
    GROUP BY "to_address"
),

/*------------------------------------------------------------------
  3. Debits (funds sent)
------------------------------------------------------------------*/
debits AS (
    SELECT
        "from_address"      AS address,
        SUM("value")        AS debits
    FROM filtered_tx
    WHERE "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/*------------------------------------------------------------------
  4. Gas paid by transaction senders
------------------------------------------------------------------*/
gas_paid AS (
    SELECT
        "from_address"                          AS address,
        SUM("gas_price" * "receipt_gas_used")   AS gas_paid
    FROM filtered_tx
    WHERE "from_address" IS NOT NULL
    GROUP BY "from_address"
),

/*------------------------------------------------------------------
  5. Gas earned by block miners
------------------------------------------------------------------*/
miner_map AS (
    SELECT
        "number"        AS block_number,
        "miner"         AS miner_addr
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS
    WHERE "timestamp"
          BETWEEN 1476403200000000 AND 1476489599999999
),
gas_earned AS (
    SELECT
        m.miner_addr                             AS address,
        SUM(f."gas_price" * f."receipt_gas_used") AS gas_earned
    FROM filtered_tx f
    JOIN miner_map  m
      ON f."block_number" = m.block_number
    GROUP BY m.miner_addr
),

/*------------------------------------------------------------------
  6. Union of every address that appears in any component
------------------------------------------------------------------*/
all_addresses AS (
    SELECT address FROM credits
    UNION
    SELECT address FROM debits
    UNION
    SELECT address FROM gas_paid
    UNION
    SELECT address FROM gas_earned
),

/*------------------------------------------------------------------
  7. Net balance change per address
------------------------------------------------------------------*/
net_changes AS (
    SELECT
        a.address,
        COALESCE(c.credits    ,0) AS credits,
        COALESCE(d.debits     ,0) AS debits,
        COALESCE(gp.gas_paid  ,0) AS gas_paid,
        COALESCE(ge.gas_earned,0) AS gas_earned,
        /* net = credits − debits − gas_paid + gas_earned */
        COALESCE(c.credits,0)
      - COALESCE(d.debits ,0)
      - COALESCE(gp.gas_paid ,0)
      + COALESCE(ge.gas_earned,0)     AS net_change
    FROM all_addresses a
    LEFT JOIN credits    c  ON a.address = c.address
    LEFT JOIN debits     d  ON a.address = d.address
    LEFT JOIN gas_paid   gp ON a.address = gp.address
    LEFT JOIN gas_earned ge ON a.address = ge.address
)

/*------------------------------------------------------------------
  8. Final max / min net balance change for the day
------------------------------------------------------------------*/
SELECT
    MAX(net_change) AS max_net_change,
    MIN(net_change) AS min_net_change
FROM net_changes;