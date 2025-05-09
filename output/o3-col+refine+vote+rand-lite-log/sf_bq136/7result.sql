WITH
/*------------------------------------------------------------
1)  Count every outgoing regular tx or contract transition
    for each address and keep only “low-activity” wallets
------------------------------------------------------------*/
outgoing AS (
    SELECT "sender" AS addr              -- regular transactions
    FROM  CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    UNION ALL
    SELECT "addr"   AS addr              -- contract transitions
    FROM  CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
),
out_cnt AS (
    SELECT addr , COUNT(*) AS cnt
    FROM   outgoing
    GROUP  BY addr
),
small_addr AS (                          -- ≤ 50 outgoing events
    SELECT addr
    FROM   out_cnt
    WHERE  cnt <= 50
),

/*------------------------------------------------------------
2)  First-hop edges  (source  ➜  intermediate)
------------------------------------------------------------*/
first_hop AS (
    SELECT                               -- regular tx from the source
        "to_addr"         AS mid ,
        "id"              AS src_tx ,
        "block_timestamp" AS ts1
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "sender"  = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  "success" = TRUE
    UNION ALL                           -- contract transitions from the source
    SELECT
        "recipient"      AS mid ,
        "transaction_id" AS src_tx ,
        "block_timestamp" AS ts1
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "addr"        = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  "block_number" IS NOT NULL
),

/*------------------------------------------------------------
3)  Second-hop edges  (intermediate  ➜  destination)
------------------------------------------------------------*/
second_hop AS (
    SELECT                               -- regular tx to destination
        "sender"          AS mid ,
        "id"              AS dst_tx ,
        "block_timestamp" AS ts2
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "to_addr" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND  "success" = TRUE
    UNION ALL                           -- contract transitions to destination
    SELECT
        "addr"           AS mid ,
        "transaction_id" AS dst_tx ,
        "block_timestamp" AS ts2
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "recipient"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND  "block_number" IS NOT NULL
),

/*------------------------------------------------------------
4)  Assemble 2-hop paths, enforce chronological order & filters
------------------------------------------------------------*/
paths AS (
    SELECT
        f.ts1,
        'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' ||
        ' --(tx ' || SUBSTR(f.src_tx,1,5) || '..)--> ' ||
        f.mid ||
        ' --(tx ' || SUBSTR(s.dst_tx,1,5) || '..)--> ' ||
        'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'  AS path
    FROM   first_hop  f
    JOIN   second_hop s   ON f.mid = s.mid      AND f.ts1 < s.ts2
    JOIN   small_addr sa  ON sa.addr = f.mid    -- keep only low-activity mids
)

/*------------------------------------------------------------
5)  Final output ordered by the first-hop timestamp
------------------------------------------------------------*/
SELECT path
FROM   paths
ORDER  BY ts1;