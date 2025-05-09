WITH
/* 1 : micro-seconds timestamp for 2021-09-01 00:00:00 UTC */
cutoff AS (
    SELECT 1630454400000000 AS ts
),

/* 2 : transactions whose root call is delegatecall / callcode / staticcall */
ignore_tx AS (
    SELECT DISTINCT "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  LOWER("call_type") IN ('delegatecall','callcode','staticcall')
      AND ( "trace_address" IS NULL OR "trace_address" IN ('', '0') )
),

/* 3 : all successful transactions before the cutoff, excluding the above */
valid_tx AS (
    SELECT *
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN   cutoff c
      ON   t."block_timestamp" < c.ts
    WHERE  t."receipt_status" = 1
      AND  t."hash" NOT IN ( SELECT "transaction_hash" FROM ignore_tx )
),

/* 4 : address that sent the highest number of such transactions */
top_addr AS (
    SELECT  "from_address" AS address,
            COUNT(*)       AS tx_cnt
    FROM    valid_tx
    GROUP BY "from_address"
    ORDER BY tx_cnt DESC NULLS LAST
    LIMIT 1
),

/* 5 : aggregate outgoing value and gas fees */
outgoing AS (
    SELECT  SUM(COALESCE("value",0))                                                AS out_val,
            SUM(COALESCE("receipt_gas_used",0) *
                COALESCE("receipt_effective_gas_price", "gas_price", 0))            AS gas_fee
    FROM   valid_tx v
    JOIN   top_addr a
      ON   v."from_address" = a.address
),

/* 6 : aggregate incoming value */
incoming AS (
    SELECT  SUM(COALESCE("value",0)) AS in_val
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN    cutoff c
      ON    t."block_timestamp" < c.ts
    JOIN    top_addr a
      ON    t."to_address" = a.address
    WHERE   t."receipt_status" = 1
),

/* 7 : mining rewards credited to the address */
rewards AS (
    SELECT  SUM(COALESCE("value",0)) AS reward_val
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN    cutoff c
      ON    tr."block_timestamp" < c.ts
    JOIN    top_addr a
      ON    tr."to_address" = a.address
    WHERE   tr."trace_type" = 'reward'
)

/* 8 : final balance in Ether */
SELECT
    a.address,
    ( COALESCE(i.in_val,0)
    + COALESCE(r.reward_val,0)
    - COALESCE(o.out_val,0)
    - COALESCE(o.gas_fee,0) ) / 1e18     AS final_balance_ether
FROM  top_addr a
LEFT JOIN outgoing o ON 1=1
LEFT JOIN incoming i ON 1=1
LEFT JOIN rewards  r ON 1=1;