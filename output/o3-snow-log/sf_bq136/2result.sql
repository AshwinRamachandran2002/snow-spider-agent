WITH
-- 1.  Build a unified list of outgoing edges (regular tx + contract transitions)
edges AS (
    SELECT
        LOWER("sender")               AS from_addr,
        LOWER("to_addr")              AS to_addr,
        "id"                          AS tx_id,
        "block_timestamp"             AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL

    UNION ALL

    SELECT
        LOWER("addr")                 AS from_addr,
        LOWER("recipient")            AS to_addr,
        "transaction_id"              AS tx_id,
        "block_timestamp"             AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),
-- 2.  Count outgoing txs for every address (to filter busy wallets)
outgoing_cnt AS (
    SELECT from_addr, COUNT(*) AS cnt
    FROM edges
    GROUP BY from_addr
),
-- 3.  Find 2-hop (source → intermediate → destination) paths
paths AS (
    SELECT
        e1.from_addr                                   AS source_addr,
        e1.to_addr                                     AS intermediate_addr,
        e1.tx_id                                       AS tx1_id,
        e1.ts                                          AS ts1,
        e2.tx_id                                       AS tx2_id,
        e2.ts                                          AS ts2
    FROM edges e1
    JOIN edges e2
          ON  e1.to_addr       = e2.from_addr          -- hop 1 -> hop 2
         AND e2.ts            > e1.ts                 -- chronological order
    JOIN outgoing_cnt oc
          ON  oc.from_addr     = e1.to_addr
         AND oc.cnt           <= 50                   -- filter high-activity wallets
    WHERE e1.from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'  -- source
      AND e2.to_addr  = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'   -- destination
)
-- 4.  Format required output
SELECT DISTINCT
       source_addr
       || ' --(tx ' || SUBSTR(tx1_id,1,5) || '..)--> '
       || intermediate_addr
       || ' --(tx ' || SUBSTR(tx2_id,1,5) || '..)--> '
       || 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'        AS path
FROM   paths
ORDER BY path;