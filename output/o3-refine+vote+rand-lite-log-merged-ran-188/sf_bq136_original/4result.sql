WITH edges AS (   /* combine regular transactions and contract transitions */
    SELECT
        "sender"           AS sender,
        "to_addr"          AS recipient,
        "id"               AS tx_id,
        "block_timestamp"  AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "success" = TRUE
      AND  "to_addr" IS NOT NULL

    UNION ALL

    SELECT
        "addr"             AS sender,
        "recipient"        AS recipient,
        "transaction_id"   AS tx_id,
        "block_timestamp"  AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "recipient" IS NOT NULL
      AND  ("accepted" IS NULL OR "accepted" = TRUE)      -- confirmed/on‑chain
),

/* count how many transfers each address initiates */
out_counts AS (
    SELECT sender, COUNT(*) AS outgoing_cnt
    FROM   edges
    GROUP  BY sender
),

/* 2‑hop chains that keep activity filter on the intermediate */
paths AS (
    SELECT
        e1.sender      AS source,
        e1.recipient   AS intermediate,
        e2.recipient   AS destination,
        e1.tx_id       AS tx1,
        e2.tx_id       AS tx2
    FROM   edges e1
    JOIN   edges e2
           ON  e1.recipient = e2.sender
          AND  e1.ts        < e2.ts              -- chronological order
    JOIN   out_counts c
           ON  c.sender = e1.recipient
          AND c.outgoing_cnt <= 50               -- low‑activity intermediate
    WHERE  e1.sender    = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  e2.recipient = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND  e1.recipient <> e2.recipient          -- non‑trivial intermediate
)

/* present result */
SELECT DISTINCT
       source
       || ' --(tx ' || SUBSTR(tx1, 1, 5) || ')--> '
       || intermediate
       || ' --(tx ' || SUBSTR(tx2, 1, 5) || ')--> '
       || destination          AS "2_HOP_PATH"
FROM   paths
ORDER BY "2_HOP_PATH";