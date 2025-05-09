/* 2‑hop paths  (source ➜ intermediate ➜ destination)  on Zilliqa */
WITH
/* ------------------------------------------------------------------ */
/* 1.  addresses that have 50 or fewer outgoing operations            */
/* ------------------------------------------------------------------ */
tx_cnt AS (
    SELECT "sender" AS "address", COUNT(*) AS "c"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "success" = TRUE               -- on‑chain / successful
    GROUP  BY "sender"
),
tr_cnt AS (
    SELECT "addr" AS "address", COUNT(*) AS "c"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    GROUP  BY "addr"
),
low_activity AS (
    SELECT COALESCE(t."address", r."address")        AS "address",
           COALESCE(t."c",0) + COALESCE(r."c",0)     AS "total_out"
    FROM   tx_cnt t
    FULL  JOIN tr_cnt r
           ON t."address" = r."address"
    WHERE  COALESCE(t."c",0) + COALESCE(r."c",0) <= 50
),

/* ------------------------------------------------------------------ */
/* 2.  first hop :  source  ➜  intermediate                          */
/* ------------------------------------------------------------------ */
first_hop AS (
    /* regular transactions */
    SELECT  "id"               AS "tx_id",
            "to_addr"          AS "mid",
            "block_timestamp"  AS "ts"
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE   "sender"  = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND   "success" = TRUE
      AND   "to_addr" IS NOT NULL

    UNION ALL

    /* contract transitions */
    SELECT  "transaction_id"   AS "tx_id",
            "recipient"        AS "mid",
            "block_timestamp"  AS "ts"
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE   "addr"      = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND   "recipient" IS NOT NULL
),
first_hop_filtered AS (
    SELECT *
    FROM   first_hop
    WHERE  "mid" IN (SELECT "address" FROM low_activity)
),

/* ------------------------------------------------------------------ */
/* 3.  second hop :  intermediate  ➜  destination                     */
/* ------------------------------------------------------------------ */
second_hop AS (
    /* regular transactions */
    SELECT  "id"               AS "tx_id",
            "sender"           AS "mid",
            "block_timestamp"  AS "ts"
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE   "to_addr"  = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND   "success"  = TRUE

    UNION ALL

    /* contract transitions */
    SELECT  "transaction_id"   AS "tx_id",
            "addr"             AS "mid",
            "block_timestamp"  AS "ts"
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE   "recipient" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),
second_hop_filtered AS (
    SELECT *
    FROM   second_hop
    WHERE  "mid" IN (SELECT "address" FROM low_activity)
)

/* ------------------------------------------------------------------ */
/* 4.  assemble and output paths                                      */
/* ------------------------------------------------------------------ */
SELECT DISTINCT
       'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
       || ' --(tx ' || SUBSTR(f."tx_id", 1, 5) || '...)--> '
       || f."mid"
       || ' --(tx ' || SUBSTR(s."tx_id", 1, 5) || '...)--> '
       || 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'   AS "transaction_path"
FROM   first_hop_filtered f
JOIN   second_hop_filtered s
  ON   f."mid" = s."mid"
 AND   f."ts"  < s."ts"          -- ensure chronological order
ORDER  BY "transaction_path";