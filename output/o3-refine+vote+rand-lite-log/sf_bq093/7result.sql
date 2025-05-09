/*  Maximum & minimum net balance changes for all Ethereum Classic
    addresses on 14‑Oct‑2016 (UTC), including value transfers and
    gas‑fee flows (senders pay, miners receive).                                       */

WITH day_bounds AS (      -- 14‑Oct‑2016 in micro‑seconds
    SELECT
        1476403200000000::NUMBER AS ts_start,     -- 2016‑10‑14 00:00:00
        1476489599999999::NUMBER AS ts_end        -- 2016‑10‑14 23:59:59.999999
),
/* ------------------------------------------------------------------ */
day_blocks AS (           -- blocks mined that day
    SELECT  "hash",
            "miner"
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS , day_bounds
    WHERE   "timestamp" BETWEEN ts_start AND ts_end
),
/* ------------------------------------------------------------------ */
day_txs AS (              -- external txs contained in those blocks
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        COALESCE(t."gas_price",0)          AS gas_price,
        COALESCE(t."receipt_gas_used",0)   AS gas_used,
        COALESCE(t."gas_price",0)
        * COALESCE(t."receipt_gas_used",0) AS gas_fee,
        t."block_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS t
    JOIN   day_blocks  b
           ON t."block_hash" = b."hash"
    WHERE  t."receipt_status" = 1
           OR t."receipt_status" IS NULL      -- very early txs have NULL
),
/* ------------------------------------------------------------------ */
contributions AS (        -- cash‑flows per party / tx
    /* sender pays (value + gas) */
    SELECT  "from_address"                      AS address,
            -( COALESCE("value",0) + gas_fee )  AS net_change
    FROM    day_txs

    UNION ALL
    /* receiver gets value */
    SELECT  "to_address"                        AS address,
            COALESCE("value",0)                 AS net_change
    FROM    day_txs
    WHERE   "to_address" IS NOT NULL

    UNION ALL
    /* miner gets gas fee */
    SELECT  b."miner"                           AS address,
            gas_fee                             AS net_change
    FROM    day_txs tx
    JOIN    day_blocks b
           ON tx."block_hash" = b."hash"
),
/* ------------------------------------------------------------------ */
address_changes AS (      -- net change per address
    SELECT  address,
            SUM(net_change) AS net_change
    FROM    contributions
    GROUP  BY address
),
/* if no transactions occurred that day, provide a default 0 row
   so the query still returns a result set                                       */
address_changes_w_default AS (
    SELECT  address,
            net_change
    FROM    address_changes

    UNION ALL
    SELECT  'NO_DATA'   AS address,
            0           AS net_change
    WHERE  NOT EXISTS ( SELECT 1 FROM address_changes )
),
/* ------------------------------------------------------------------ */
max_row AS (              -- greatest positive change
    SELECT  address, net_change
    FROM (
        SELECT address,
               net_change,
               ROW_NUMBER() OVER (ORDER BY net_change DESC) AS rn
        FROM   address_changes_w_default
    )
    WHERE rn = 1
),
min_row AS (              -- greatest negative change
    SELECT  address, net_change
    FROM (
        SELECT address,
               net_change,
               ROW_NUMBER() OVER (ORDER BY net_change ASC) AS rn
        FROM   address_changes_w_default
    )
    WHERE rn = 1
)
/* ------------------------------------------------------------------ */
SELECT 'MAX' AS extreme_type, address, net_change FROM max_row
UNION ALL
SELECT 'MIN' AS extreme_type, address, net_change FROM min_row;