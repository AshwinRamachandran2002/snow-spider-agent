WITH movements AS (       -- all confirmed transfers (regular TX + contract transition)
    SELECT 
        "sender"         AS from_addr,
        "to_addr"        AS to_addr,
        "id"             AS txid,
        "block_timestamp" AS ts
    FROM  CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL
    
    UNION ALL
    
    SELECT 
        "addr"           AS from_addr,
        "recipient"      AS to_addr,
        "transaction_id" AS txid,
        "block_timestamp" AS ts
    FROM  CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),                                                          -- how busy is each sender?
outgoing_counts AS (
    SELECT from_addr, COUNT(*) AS cnt
    FROM   movements
    GROUP  BY from_addr
),                                                          -- 2-hop paths that satisfy all rules
paths AS (
    SELECT
        m1.txid  AS tx1,
        m1.ts    AS ts1,
        m2.txid  AS tx2,
        m2.ts    AS ts2,
        m1.from_addr                  AS src,
        m1.to_addr                    AS inter,
        m2.to_addr                    AS dst
    FROM   movements m1
    JOIN   movements m2
           ON m1.to_addr   = m2.from_addr      -- hop 1 -> hop 2
          AND m1.ts        < m2.ts             -- chronological order
    JOIN   outgoing_counts oc                  -- filter “busy” intermediates
           ON oc.from_addr = m1.to_addr
          AND oc.cnt      <= 50
    WHERE  m1.from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'  -- source
      AND  m2.to_addr   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'  -- destination
      AND  m1.to_addr  <> m1.from_addr        -- intermediate ≠ source
      AND  m1.to_addr  <> m2.to_addr          -- intermediate ≠ destination
)
SELECT  src || ' --(tx ' || SUBSTR(tx1,1,5) || ')--> ' 
        || inter || ' --(tx ' || SUBSTR(tx2,1,5) || ')--> ' 
        || dst   AS "PATH"
FROM    paths
ORDER BY ts1, ts2;