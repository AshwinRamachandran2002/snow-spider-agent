WITH tx_union AS (

    /* ---------- regular ZIL transactions ---------- */
    SELECT
        "sender"        AS from_addr ,
        "to_addr"       AS to_addr  ,
        "id"            AS tx_id    ,
        "block_timestamp" AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL               -- keep only value-transfers

    UNION ALL

    /* ---------- contract transitions (internal transfers etc.) ---------- */
    SELECT
        "addr"          AS from_addr ,
        "recipient"     AS to_addr  ,
        "transaction_id" AS tx_id   ,
        "block_timestamp" AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "accepted" = FALSE                   -- transition executed on-chain
      AND "recipient" IS NOT NULL
      AND ( "amount" IS NULL OR "amount" <> 0 ) -- skip zero-value noise
),

/* ---------- outgoing-tx count per address (to drop very busy wallets) ---------- */
outgoing AS (
    SELECT
        from_addr,
        COUNT(*) AS out_cnt
    FROM tx_union
    GROUP BY from_addr
),

/* ---------- all 2-hop paths source -> intermediate -> destination ---------- */
paths AS (
    SELECT
        t1.from_addr        AS source_addr,
        t1.to_addr          AS intermediate_addr,
        t2.to_addr          AS dest_addr,
        t1.tx_id            AS tx1_id,
        t2.tx_id            AS tx2_id
    FROM tx_union  t1
    JOIN tx_union  t2
          ON  t1.to_addr = t2.from_addr        -- hop 2 starts where hop 1 ended
         AND t1.ts      < t2.ts                -- chronological order
    JOIN outgoing  o
          ON o.from_addr = t1.to_addr
         AND o.out_cnt  <= 50                  -- filter out high-activity wallets
    WHERE t1.from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND t2.to_addr   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)

/* ---------- final formatted result ---------- */
SELECT DISTINCT
       CONCAT(
              'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
              ' --(tx ', SUBSTR(tx1_id,1,5) ,'..)--> ',
              intermediate_addr,
              ' --(tx ', SUBSTR(tx2_id,1,5) ,'..)--> ',
              'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
             )  AS path_description
FROM paths
ORDER BY path_description;