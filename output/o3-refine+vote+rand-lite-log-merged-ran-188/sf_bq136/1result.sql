WITH edges AS (   -- every confirmed “edge” (regular tx or transition)
    /* regular ZIL transactions */
    SELECT
        "sender"                       AS from_addr ,
        "to_addr"                      AS to_addr  ,
        "id"                           AS tx_id    ,
        "block_timestamp"              AS blk_ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL

    UNION ALL

    /* contract transitions (function calls / payments)            */
    /* they are already included in a block, hence on-chain         */
    SELECT
        "addr"                         AS from_addr ,
        "recipient"                    AS to_addr  ,
        "transaction_id"               AS tx_id    ,
        "block_timestamp"              AS blk_ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),

/* how busy is every address as a **sender** (via either edge type) ? */
busy AS (
    SELECT   from_addr ,
             COUNT(*)  AS outgoing_cnt
    FROM     edges
    GROUP BY from_addr
    HAVING   COUNT(*) > 50          -- regarded as “too busy” (exchanges / hubs)
),

/* first hop:  SOURCE  ->  INTERMEDIATE  */
first_hop AS (
    SELECT *
    FROM   edges
    WHERE  from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  to_addr   IS NOT NULL
)

/* --------------------------------------------------------------- */
SELECT
    CONCAT(
        f.from_addr,
        ' --(tx ', SUBSTR(f.tx_id ,1,5) , '..)--> ',
        f.to_addr ,
        ' --(tx ', SUBSTR(s.tx_id ,1,5) , '..)--> ',
        s.to_addr
    )                                            AS path
FROM          first_hop            f
JOIN          edges                s
        ON    s.from_addr = f.to_addr                           -- INTERMEDIATE ↦
        AND   s.to_addr   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
        AND   s.blk_ts    > f.blk_ts                            -- chronological
LEFT JOIN     busy                 b   ON b.from_addr = f.to_addr
WHERE         b.from_addr IS NULL                               -- keep ≤ 50 tx senders
ORDER BY      f.blk_ts , s.blk_ts
;