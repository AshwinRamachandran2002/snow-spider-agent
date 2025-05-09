/* 2‑hop paths (Zilliqa) :  source ──> intermediate ──> destination           */
WITH tx_edges AS (   /* outgoing transfers: regular TXs + contract transitions */
    SELECT
        "id"                               AS tx_id,
        LEFT("id",5)                       AS tx_short,
        "sender"                           AS sender,
        "to_addr"                          AS recipient,
        "block_timestamp"                  AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "success" = TRUE
      AND  "sender"      IS NOT NULL
      AND  "to_addr"     IS NOT NULL

    UNION ALL

    SELECT
        "transaction_id"                   AS tx_id,
        LEFT("transaction_id",5)           AS tx_short,
        "addr"                             AS sender,
        "recipient"                        AS recipient,
        "block_timestamp"                  AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "addr"      IS NOT NULL
      AND  "recipient" IS NOT NULL
),

/* outgoing‑tx count for each address                                          */
outgoing_counts AS (
    SELECT sender , COUNT(*) AS out_cnt
    FROM   tx_edges
    GROUP  BY sender
),

/* 2‑hop, chronological, intermediate address with ≤ 50 outgoing txs           */
paths AS (
    SELECT
        fe1.sender                AS source_addr,
        fe1.recipient             AS intermediate_addr,
        fe2.recipient             AS dest_addr,
        fe1.tx_short              AS tx1_short,
        fe2.tx_short              AS tx2_short
    FROM   tx_edges  fe1
    JOIN   tx_edges  fe2
           ON  fe1.recipient   = fe2.sender
          AND fe1.ts          < fe2.ts                 -- chronological
    JOIN   outgoing_counts oc                            -- activity filter
           ON  oc.sender = fe1.recipient
          AND oc.out_cnt <= 50
    WHERE  fe1.sender      = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  fe2.recipient   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)

/* final formatted output                                                      */
SELECT DISTINCT
       CONCAT(
           source_addr,
           ' --(tx ', tx1_short, '..)--> ',
           intermediate_addr,
           ' --(tx ', tx2_short, '..)--> ',
           dest_addr
       ) AS "2_HOP_PATH"
FROM   paths;