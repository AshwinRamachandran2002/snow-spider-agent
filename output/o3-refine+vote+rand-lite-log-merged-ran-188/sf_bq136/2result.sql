WITH edges AS (          -- all confirmed outgoing edges (regular txs + transitions)
    SELECT  
        "sender"           AS "from_addr",
        "to_addr"          AS "to_addr",
        "id"               AS "tx_id",
        "block_timestamp"  AS "ts"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "success" = TRUE
      AND  "to_addr" IS NOT NULL
    
    UNION ALL
    
    SELECT  
        "addr"             AS "from_addr",
        "recipient"        AS "to_addr",
        "transaction_id"   AS "tx_id",
        "block_timestamp"  AS "ts"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "recipient" IS NOT NULL
),                                                      
intermediate_stats AS (   -- outgoing-tx counts for every potential intermediate
    SELECT  "from_addr" AS "intermediate",
            COUNT(*)    AS "outgoing_cnt"
    FROM    edges
    GROUP BY "from_addr"
),                                                      
valid_intermediates AS (  -- keep only “small” wallets (≤ 50 outgoings)
    SELECT  "intermediate"
    FROM    intermediate_stats
    WHERE   "outgoing_cnt" <= 50
),                                                      
paths AS (                -- 2-hop, chronological, via valid intermediates
    SELECT
        e1."from_addr"                     AS "source",
        e1."to_addr"                       AS "intermediate",
        e1."tx_id"                         AS "tx1",
        e2."tx_id"                         AS "tx2"
    FROM   edges            e1
    JOIN   valid_intermediates v
           ON  e1."to_addr" = v."intermediate"
    JOIN   edges            e2
           ON  e2."from_addr" = v."intermediate"
           AND e2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
    WHERE  e1."from_addr"   = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  e1."ts" < e2."ts"                -- chronological order
)
SELECT DISTINCT
       "source"
       || ' --(tx ' || SUBSTR("tx1",1,5) || '..)--> '
       || "intermediate"
       || ' --(tx ' || SUBSTR("tx2",1,5) || '..)--> '
       || 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'    AS "2_hop_path"
FROM   paths
ORDER BY "2_hop_path";